
capture program drop xtqls
program define xtqls /*Program for fitting method of*/
version 9.0                /*quasi-least squares (QLS) that makes use of*/
                         /*Stata's xtgee command.*/


tempname touse corr

/*The syntax for xtqls.ado is as below. It is similar to that for xtgee.*/

/*The options that must be supplied in the syntax below are:    */
/*    id = name of subject (or cluster) id variable             */
/*  time = name of variable that contains times                 */
/*  corr = name of correlation structure                        */
/* family = family that is specified in xtgee. Please note      */
/*         that xtqls.ado uses canonical link functions.        */

/*The following correlation structures are allowable with xtqls:*/
/*     exc    = equicorrelated (exchangeable) structure         */
/*     AR 1   = first-order autoregressive structure            */
/*     Markov = Markov correlation structure                    */
/*     sta 1  = tri-diagonal                                    */

/*Note that if the AR 1 structure is specified, then xtqls      */
/*will treat all observations as though they are equally        */
/*spaced in time. Using xtqls with the AR 1 structure is then   */
/*equivalent to using xtgee with the AR 1 structure and the     */
/*option force.                                                 */

/*The following families are allowable with xtqls:              */
/*    gau    = Gaussian                                         */
/*    bin 1  = Bernoulli                                        */
/*    poi    = Poisson                                          */

/*xtqls also requires that you specify whether you prefer model */
/*based or sandwich type robust estimates of the estimates      */
/*of the covariance matrix of the regression parameter.         */
/*For model based, specify vce(model). For sandwich type        */
/*estimates, specify vce(robust).                               */

/*Note that xtqls utilizes the canonical link function for each family.*/

syntax varlist(ts) [if] [in] [iw fw pw], /*
*/ i(varname) t(varname) c(string) f(string) vce(string)

preserve /*Will return original data set.*/


quietly {  /*Start quietly command.*/

tokenize `varlist'  /*Parse the variable list.*/
local dep `1'      /*Name of dependent variable is first.*/
macro shif
local covariates `*'  /*Covariates are the remainder.*/


set type double   /*set all variables to be doubles*/


/*Next, define temporary variables and temporary names.*/
tempname equicorr w iter this  big temp y bnew newa  newb one oldb  gamma check temp1 /*Define temporary matrices etc.*/                       
tempvar big id time z xtbeta huij uij p tempid temptime id2  t2

/*If correlation structure is AR 1 we will replace the temporary time variable*/
/* with a variable that takes value 1,2,3, etc. This means that xtqls.ado     */
/* will treat the outcome variable as though it is equally spaced in time.    */
/* This is equivalent to using the force command with the AR 1 structure, as  */
/* an option in xtgee. */



/*First, obtain starting values for betahat*/
/*We will do this using GEE (via xtgee command in Stata), with the identity working*/
/*correlation structure.*/

     xtgee `dep' `covariates', corr(Ind) i(`i') family(`f')
    matrix `bnew' = get(_b)  /*starting values*/
    predict `p' if e(sample) /*obtain predicted values for estimation sample*/
    keep if `p'~=.  /*Just keep estimation sample.*/

qui sort `i'    /*Replace id so that it takes values 1,2,...*/
qui by `i': gen `id2'= 1 if _n==1
replace `id2' = sum(`id2')
replace `i' = `id2'

   /*Save largest number of observations for a subject in scalar `big'.*/
                 qui sort `i' `t'
                 qui by `i': gen `big'=_N
                 summ `big'
                 scalar `big' = _result(6)  /*this is the largest number of obs per subject*/

   /*If the structure is not Markov, then replace the timing variable*/
   /*with time = 1,2,3....*/

       if "`c'"~="Markov" {
                             qui sort `i' `t'
                             qui by `i': gen `t2' = _n
                           } /*End if structure is not Markov.*/

local w = 1       /*need to use global macros to mark iterations*/
local iter = 1


/*Next, start iterative procedure to update estimates of the correlation */
/*and the regression parameters in stage one of QLS.                     */


/*NOTE:  We will say that the procedure failed to converge if xtqls
         does not converge in less than 40 iterations   */

while `w' > .000000000001 & `iter' < 40  {     /*start "while w"*/


/*Drop temporary variables, if necessary.*/
capture drop `z' 
capture drop `xtbeta'
capture drop `uij'
capture drop `huij'

matrix score double `xtbeta' = `bnew'  /*create variable xij'beta.*/


 /*Create z = (yij - uij)/sqrt(h(uij))*/
 /*evaluated at uij=xij'beta.*/
 /*Or, zi = Ai^(-1/2)(Yi-Ui), evaluated at uij = xij'beta*/

       if "`f'"=="gau" {
                        gen double `z' = `dep' - `xtbeta'
                        gen double `huij' = 1
                        }

     if "`f'"=="poi"  {
                       gen double `uij' = exp(`xtbeta')
                       gen double `huij' = sqrt(`uij')
                       gen double `z' = (`dep' - `uij')/`huij'
                       }

   if "`f'"=="bin 1"  {
                gen double `uij' = exp(`xtbeta')/(1 + exp(`xtbeta'))
                       gen double `huij' = sqrt(`uij'*(1-`uij'))
                       gen double `z' = (`dep' - `uij')/`huij'
                        }




/*Update estimate of correlation parameter*/
if "`c'"=="AR 1" {
                       ar1xtqls `z' `t2' `i'
                       }



if "`c'"=="Markov" {
                           mark02xtqls `z' `t' `i'
                         }


if "`c'"=="sta 1" {
                           tri06xtqls `z' `t2' `i'
                         }


if "`c'"=="exc" {
                          equi04xtqls `z' `t2' `i'
                        }


/*Scalar `newa' is the stage one estimate of alpha.*/
scalar `newa' = r(alpha)


/*Next, update the estimated regression coefficients.*/

/*First, set up fixed correlation structure for xtgee procedure.*/

qui sort `i' `t'

/*equicorrelated*/

if "`c'"=="exc"  {

matrix `equicorr' = (1 - scalar(`newa'))*I(`big')  + J(`big',`big',scalar(`newa'))
                       }


/* AR(1)  */

if "`c'"=="AR 1"  {  /*start if "`c'"=="AR 1"*/

matrix `equicorr' = I(`big')


local k = 1
local big = scalar(`big')


while `k' < `big' { /*Start k loop*/

local j = `k' + 1

while `j' <= `big' { /*Start j loop*/


                  matrix `equicorr'[`k',`j'] = scalar(`newa')^(`j' - `k')
                  matrix `equicorr'[`j',`k'] = scalar(`newa')^(`j' - `k')

                  local j = `j' + 1
                              } /*End j loop.*/

               local k = `k' + 1
                 } /*End k loop*/

                     }  /*end if "`c'"=="AR 1" */


/* Tridiagonal */

if "`c'"=="sta 1"  {  /*start if "`c'"=="sta 1"*/

matrix `equicorr' = I(`big')


local k = 1
local big = scalar(`big')

while `k' < `big' { /*Start k loop*/

local j = `k' + 1


                  matrix `equicorr'[`k',`j'] = scalar(`newa')
                  matrix `equicorr'[`j',`k'] = scalar(`newa')


               local k = `k' + 1
                 } /*End k loop*/

                     }  /*end if "`c'"=="sta 1" */



/* Markov */

if "`c'"=="Markov"  {  /*start if "`c'"=="Markov"*/

setup_markov2 `i' `t' scalar(`newa') /*Construct matrix `equicorr' at scalar newa.*/

matrix `equicorr' = r(equicorr)
 
                     }  /*end if "`c'"=="Markov" */



/*Next, use xtgee procedure to update estimate of regression parameter*/
/*at fixed correlation matrix that is evaluated at current estimate of*/
/*the correlation parameter.*/


if "`c'"=="Markov" {
xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t') family(`f')
                    }

if "`c'"~="Markov" {
xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t2') family(`f')
                    }

matrix `oldb' = get(_b)      /*Get adjustments for regression coefficients*/


/*Next, obtain difference between old and new regression coefficients.*/
/*Check whether congergence has occured in stage one.*/

matrix `gamma' = `bnew' - `oldb'

matrix `check' = `gamma'*`gamma''  /*stop process when w is approx. zero*/

local w = `check'[1,1]

matrix `bnew' = `oldb'


local iter = `iter' + 1


        }      /*end "while w"*/


/*After convergence in stage one of procedure,*/
/*need to obtain final estimates of the regression*/
/*and the correlation parameters in stage two of the procedure.*/



if "`c'" == "AR 1" {
              scalar `newa' = 2*scalar(`newa')/(1 + scalar(`newa')^2)
                       }



if "`c'"=="Markov" {
                          marktwoxtqls `dep' `t' `i' scalar(`newa')
                          scalar `newa' = r(alpha)     

                          }

if "`c'"=="sta 1" {
                          tritwo06xtqls `dep' `t2' `i' scalar(`newa')
                          scalar `newa' = r(alpha)

                          }


if "`c'"=="exc" {
                         equitwoxtqls `dep' `t2' `i' scalar(`newa')
                         scalar `newa' = r(alpha)

                         }




qui sort `i' `t'


if "`c'"=="exc"   {

matrix `equicorr' = (1 - scalar(`newa'))*I(`big')  + J(`big',`big',scalar(`newa'))
                       }



if "`c'"=="AR 1"  {  /*start if "`c'"=="AR 1"*/

matrix `equicorr' = I(`big')


local k = 1
local big = scalar(`big')


while `k' < `big' { /*Start k loop*/

local j = `k' + 1

while `j' <= `big' { /*Start j loop*/


                  matrix `equicorr'[`k',`j'] = scalar(`newa')^(`j' - `k')
                  matrix `equicorr'[`j',`k'] = scalar(`newa')^(`j' - `k')

                  local j = `j' + 1
                              } /*End j loop.*/

               local k = `k' + 1
                 } /*End k loop*/

                     }  /*end if "`c'"=="AR 1" */



if "`c'"=="sta 1"  {  /*start if "`c'"=="sta 1"*/

matrix `equicorr' = I(`big')


local k = 1
local big = scalar(`big')

while `k' < `big' { /*Start k loop*/

local j = `k' + 1


                  matrix `equicorr'[`k',`j'] = scalar(`newa')
                  matrix `equicorr'[`j',`k'] = scalar(`newa')


               local k = `k' + 1
                 } /*End k loop*/

                     }  /*end if "`c'"=="sta 1" */




/* Markov */

if "`c'"=="Markov"  {  /*start if "`c'"=="Markov"*/

setup_markov2 `i' `t' scalar(`newa')

matrix `equicorr' = r(equicorr)

 
                     }  /*end if "`c'"=="Markov" */


          }    /*End quietly command.*/


 if "`vce'"=="robust"  & "`c'"=="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t') f(`f') robust
                      }

 if "`vce'"=="model" & "`c'"=="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t') f(`f')
                      }

 if "`vce'"=="jack" & "`c'"=="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t') f(`f') vce(jack) 
                      }

 if "`vce'"=="boot" & "`c'"=="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t') f(`f') vce(boot) 
                      }


 if "`vce'"=="robust"  & "`c'"~="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t2') f(`f') robust
                      }

 if "`vce'"=="model" & "`c'"~="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t2') f(`f') 
                      }

 if "`vce'"=="jack" & "`c'"~="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t2') f(`f') vce(jack) 
                      }

 if "`vce'"=="boot" & "`c'"~="Markov" {
noi xtgee `dep' `covariates', corr(fixed `equicorr') i(`i') t(`t2') f(`f') vce(boot)
                      }

end

program define ar1xtqls, rclass
version 9.0   /*Returns scalar r(alpha) = stage one estimate*/
             /*for AR(1) structure.*/

set type double


local varlist "req ex"
parse "`*'"
tempvar z zlag t id a b c d alpha

preserve  /*Will return to previous data set.*/

qui gen double `z'=`1'
qui gen double `t' = `2'
qui gen double `id' = `3'

keep if `z'~=.  /*Will not use records with missing z values.*/

sort `id' `t' 
by `id': gen double `zlag' = `z'[_n-1] if _n>1
         

         quietly{
         gen double `a' = sum(`z'^2 + `zlag'^2)
         replace `a'=`a'[_N]
         gen double `b'=sum(`z'*`zlag')
         replace `b'=`b'[_N]
         gen double `c'= sum((`z'-`zlag')^2)
         replace `c'=`c'[_N]
         gen double `d'=sum( (`z' + `zlag')^2)
         replace `d'=`d'[_N]
         gen double `alpha' = (`a' - sqrt(`c'*`d'))/(2*`b')
         }
         return scalar alpha = `alpha'[_N]


         end


                 /*Program to estimate correlation parameters*/
program define mark02xtqls, rclass      /*when we are using QLS and Markov*/ 
                          /*working correlation structure*/
                          /*Program uses a*/
version 9.0               /*method of bisection.*/

set type double

                        
tempvar z t c h ni         
quietly{          /*start quietly*/

gen double `z' = `1'    /*first argument is z'=(z11,z12,....)*/   
gen double `t' = `2'    /*2nd argument is t'=(t11,t12,....)*/
gen double `c' = `3'    /*3rd argument is id*/

tempname a b m fa fm anew
scalar `a' = .00001  /*Starting values for lower value, higher value, midpoint.*/
scalar `b' = .999999999
scalar `m' = (scalar(`a') + scalar(`b'))/2

local diff=1
local count = 1
while `diff'>.00000000001 {
                    scalar `anew' = scalar(`a')
                       sort `c' `t'
                    fmark02xtqls `c' `t' `z' scalar(`anew')
                    scalar `fa' = r(frho)  /*get value of f at lower limit*/
                    scalar `anew' = scalar(`m')
                    fmark02xtqls `c' `t' `z' scalar(`anew')
                    scalar `fm' = r(frho)  /*get value of f at midpoint*/
        if scalar(`fa')*scalar(`fm')>0 {
                                    scalar `a' =scalar(`m')
                                    }
        if scalar(`fa')*scalar(`fm')<0 {
                                    scalar `b'=scalar(`m')
                                    }
        local diff = abs(scalar(`a')  - scalar(`b'))                         
        local `a' = scalar(`a')
        local `b' = scalar(`b')
        local count = `count' + 1
        scalar `m' = (scalar(`a') + scalar(`b'))/2
                            } /*end while statement*/

return scalar alpha =scalar(`m')

}  /*end quietly*/
end
capture program drop fmark02xtqls
program define fmark02xtqls, rclass
version 9.0

set type double
tempvar id t z eij zlag frho
tempname anew
gen `id' = `1'
gen `t' = `2'
gen `z' = `3'
scalar `anew' = `4'
qui sort `id' `t'
qui by `id': gen double `eij' = `t' - `t'[_n-1] if _n>1
qui by `id': gen double `zlag' = `z'*`z'[_n-1] if _n>1
qui by `id': gen double `frho'= /*
*/ 2*`eij'*scalar(`anew')^(2*`eij'-1)*(`z'^2 - 2*scalar(`anew')^`eij'*`zlag' /*
*/ + `z'[_n-1]^2)/(1 - scalar(`anew')^(2*`eij'))^2 - /*
*/ 2*`eij'*scalar(`anew')^(`eij'-1)*`zlag'/(1 - scalar(`anew')^(2*`eij'))
replace `frho'=sum(`frho')
return scalar frho = `frho'[_N]
end


capture drop tri06xtqls        /*Program to estimate correlation parameters*/
program define tri06xtqls, rclass   /*when we are using QLS and tridiagonal*/ 
                          /*working correlation structure*/
                          /*STAGE ONE ESTIMATE*/

version 9.0           /*Define version number*/
                        
tempvar z t c h ni     /*Define temporary variables.*/    
tempname lower a b m  anew fa fm     /*Define temporary names.*/

quietly{          /*start quietly- supresses output*/

gen double `z' = `1'    /*first argument is z'=(z11,z12,....)*/
                              /* (Pearson residuals) */

gen double `t' = `2'    /*2nd argument is t'=(t11,t12,....)*/
                              /* (timings)  */

gen double `c' = `3'    /*3rd argument is id*/
                            /* subject ID */


sort `c' `t'    /*sort id and time*/
                /*let's get limits for feasible region*/
by `c' : gen `ni'=_N if `c'~=. /*create temporary variable ni*/
                               /*which equals the number of records*/
                               /*per subject, if the id variable is*/
                               /*not missing*/

summ `ni'
scalar `lower' = _result(6)  /*scalar `lower' = _result(6), which*/
                           /*equals the largest value of `ni'*/
                           /*`lower' = max(ni), where ni = # of*/
                           /*observations for subject i*/

capture drop `ni'          /*drop temporary variable ni*/

scalar `a' = -1/(2*sin((`lower'-1)/(`lower' + 1)*_pi/2)) + 0.000001
              /*Define lower value of feasible region for alpha*/
              /*Note that we added a small number to the lower value.*/

scalar `b' = 1/(2*sin((`lower'-1)/(`lower' + 1)*_pi/2)) - 0.000001
              /*Define upper value of feasible region for alpha*/
              /*Note that we subtracted a small number from the upper value.*/

scalar `m' = (scalar(`a') + scalar(`b'))/2  /*Set up midpoint, prior to programming bisection method*/

local diff=1    /*set up starting difference*/

while `diff'>.00001 {/*Use bisection until `diff' < 0.000001*/
                    scalar `anew' = scalar(`a')  /*let `anew' = lower value of interval*/
                    sort `c' `t'      /*sort id and time*/
                ftri06xtqls `c' `t' `z' scalar(`anew') /*obtain value of frho at lower limit*/
                    scalar `fa' = r(frho) /*`fa' = value of f at lower limit*/
                    scalar `anew' = scalar(`m') /*let `anew' = midpoint*/
                    ftri06xtqls `c' `t' `z' scalar(`anew') /*sort id and time*/
                    scalar `fm' = r(frho)  /*get value of f at midpoint*/

        if `fa'*`fm'>0 {
        scalar `a' =scalar(`m')
                   }  /*if `fa'*`fm'>0, let a = midpoint*/

        if `fa'*`fm'<0 {
        scalar `b'=scalar(`m')
                    }  /*if `fa'*`fm'<0, let b = midpoint*/

        local diff = abs(scalar(`a')  - scalar(`b')) /*obtain difference between a and b*/

        noi di `diff'  /*display difference, to check convergence*/

        scalar `m' = (scalar(`a') + scalar(`b'))/2 /*redefine midpoint*/

        }   /*end `while' statement*/ 

      return  scalar alpha =scalar(`m')   /*Define stage one estimate, newa*/
        }            /*end quietly statement*/
end


program define ftri06xtqls, rclass       /*program to calculate f(rho), for qls*/
version 9.0                      /*stage one tridiagonal function*/

tempvar c t z hij n         /*Define temporary variables.*/
tempname anew k sum

gen double `c' = `1'  /*Generate temporary id variable = 1st argument*/
gen double `t' = `2'  /*Generate temporary time variable = 2nd argument*/
gen double `z' = `3'  /*Generate temporary Pearson residual variable = */
                                                         /* 3rd argument*/

scalar `anew' = `4'  /*Fourth argument is scalar anew.*/

scalar `k' = 0

scalar `sum' = 0 /*Start with value of zero for sum, which is value*/
                /*of sum to be added to, to obtain value of function*/
                /*to be minimized.*/
quietly { 

tempvar tempid e yij  jj ni   /*declare temporary variable names*/
tempname f eij temp zij x v xp y  temp    /*declare temporary matrix, scalar names*/

sort `c' `t'               /*create temporary ids that take value 1,2...m*/
by `c': gen `tempid' = 1 if _n==1

summ `tempid'
local count = _result(1) /*local macro count = number of subjects*/


replace `tempid' = sum(`tempid')


local i = 1                 /*Set up local variable that will be used*/
                             /*to loop through all subjects.*/


while `i' <= `count' {    /*Next, cycle through all subjects.*/
    mkmat `z' if `tempid'==`i', matrix(`zij') /*create matrix of Pearson*/
                           /*residuals for subject i*/

    local w = rowsof(`zij') /*local macro w = row dimension of matrix `zij'*/             
    matrix R`i' = I(`w')   /*Set up matrix R`i' = identity matrix*/
                            /*with same row dimension as `zij'*/

          /*Next, contstruct `w' by `w' tridiagonal matrix at*/
          /*current estimate of alpha.*/
    local j = 2         /*Next, loop from 2 to `w'*/
             while `j' <= `w' {
                                local jmone = `j' - 1
                                matrix R`i'[`jmone',`j'] = scalar(`anew')
                                matrix R`i'[`j',`jmone'] = scalar(`anew')
                                local j = `j' + 1
                             } /*end loop to obtain tri-diagonal structure*/



     /*Set up matrix diff`i' = derivative matrix*/
    matrix diff`i' = J(`w',`w',0) /*set up `w' by `w' matrix of zeros*/   

    local j = 2         /*Next, loop from 2 to `w'*/
             while `j' <= `w' {
                                local jmone = `j' - 1
                                matrix diff`i'[`jmone',`j'] = 1
                                matrix diff`i'[`j',`jmone'] = 1
                                local j = `j' + 1
                             } /*end loop to obtain derivative matrix*/


    /*Next, obtain z'*diff(Rinv,alpha)*z */

     matrix `temp' = -`zij''*syminv(R`i')*diff`i'*syminv(R`i')*`zij'
     scalar `temp' = `temp'[1,1]

     scalar `sum' = scalar(`sum') + scalar(`temp')

     pause: just obtained scalar sum for subject `i'

      /*Next, move on to next subject.*/

      local i = `i' + 1

                   }  /*End the loop.*/

    return scalar frho = scalar(`sum')  /*Assign value of sum to frho.*/

                    } /*End the quietly loop.*/
end

capture program drop equi04xtqls /*edited March 2004*/
program define equi04xtqls, rclass  /*Program to fit stage one of QLS, for*/
                      /* equicorrelated structure.*/
version 9.0

preserve

tempvar z id time total id2  
tempname r1 r2 a b
qui gen double `z'=`1'  /*w1 variable*/
qui gen double `time' = `2' /*time variable*/
qui gen double `id' = `3' /*id variable*/


sort `id' `time'
qui by `id': gen `id2' = 1 if _n==1
replace `id2' = sum(`id2')
drop `id'
rename `id2' `id'

/*We will obtain the stage one estimate*/
/* using the method of bisection for each group*/

sort `id' `time'
qui by `id': gen `total'=_N
 /*The limits for etimate are determined by max. no. of observations per*/
 /*subject.*/
qui summ `total'
global temp1 = _result(6)

 tempname a b m tnew fa fm ftau  ntau

scalar `a' = -1/($temp1 - 1) + .001 /*lower limit for estimate*/
scalar `b' = .99999 /*upper limit*/
scalar `m' = (scalar(`a') + scalar(`b'))/2
local diff=1
while `diff'>.00000001{
                    scalar `tnew' = scalar(`a')
                    sort  `id' `time'
                    f04xtqls  `z' `id' `time'  scalar(`tnew')
                    scalar `fa' = r(ftau)  /*get value of f at lower limit*/
                    scalar `tnew' = scalar(`m')
                    sort `id' `time'
                    f04xtqls `z' `id' `time' scalar(`tnew')
                    scalar `fm' = r(ftau)  /*get value of f at midpoint*/
                    if scalar(`fa')*scalar(`fm')>0 { 
                                             scalar `a' =scalar(`m') 
                                                }
                    if scalar(`fa')*scalar(`fm')<0 { 
                                               scalar `b'=scalar(`m')
                                               }
                    local diff = abs(scalar(`a')  - scalar(`b'))                         
                    scalar `m' = (scalar(`a') + scalar(`b'))/2 
                      }
                    scalar `ntau' = scalar(`m')
                    return scalar alpha = scalar(`ntau')
end  /*end program*/

capture program drop f04xtqls
program define f04xtqls, rclass   
    /*program to calculate f(rho), for qls*/
version 9.0                /*equicorrelated structure*/

tempvar c t id zij z temp1 tempa tempb tempc time clust2 la lb lc
tempname tnew

set type double

gen double `z' = `1'      /*z values*/
gen double `id' = `2'  /*cluster values*/
gen double `time' = `3'    /*level a of association*/
scalar `tnew' = `4'
scalar k = 0
quietly { 

tempvar tempid e yij  jj ni zone temp /*declare temporary variable names*/
tempname f eij temp zij x v xp y    /*declare temporary matrix, scalar names*/
tempname ni agone agtwo zsquare  temp

scalar `agone' = 0
scalar `agtwo' = 0

sort  `id' `time'

gen double `zsquare'=`z'^2
replace `zsquare'=sum(`zsquare')
scalar `agone' = `zsquare'[_N]

gen `zone' = .

local i=1  /*first cluster within group*/

qui sort `id'
qui by `id': gen `temp'=1 if _n==1
summ `temp'

local ncl =_result(1)

while `i'<= `ncl' { /*move within clusters in groups*/

summ `z' if `id'==`i'
scalar `ni' = _result(2)

replace `zone' = .
replace `zone' = `z' if `id'==`i'

replace `zone'= sum(`zone')


scalar `temp' = (`zone'[_N])^2*(1 + scalar(`tnew')^2*(scalar(`ni')-1))/*
*//(1 + scalar(`tnew')*(scalar(`ni')-1))^2


scalar `agtwo' = scalar(`agtwo') + scalar(`temp')

local i = `i' + 1  
                          } /*End closing brace*/

return scalar ftau = scalar(`agone') - scalar(`agtwo')
                           } /*End quietly.*/
end
                              
capture drop marktwoxtqls          /*Program to obtain stage two estimate of */ 
                             /*the correlation parameter*/
program define marktwoxtqls, rclass      /*when we are using QLS and Markov*/ 
                          /*working correlation structure*/
                          /*Program uses a*/
version 9.0               /*method of bisection.*/
                        
                        
tempvar z t c h ni         
tempname  newa a b m fa fm anew

quietly{          /*start quietly*/

gen double `z' = `1'    /*first argument is z'=(z11,z12,....)*/   
gen double `t' = `2'    /*2nd argument is t'=(t11,t12,....)*/
gen double `c' = `3'    /*3rd argument is id*/
scalar `newa' = `4'    /*4th argument is scalar newa */

scalar `a' = .00001  /*Starting values for lower value, higher value, midpoint.*/
scalar `b' = .999999999
scalar `m' = (scalar(`a') + scalar(`b'))/2

local diff=1
while `diff'>.000000001 {
                     scalar `anew' = scalar(`a')
                       sort `c' `t'
                       fmtwo02xtqls `c' `t' `z' scalar(`anew') scalar(`newa')
                    scalar `fa' = r(frho)  /*get value of f at lower limit*/
                    scalar `anew' = scalar(`m')
                    fmtwo02xtqls `c' `t' `z'  scalar(`anew') scalar(`newa')
                    scalar `fm' = r(frho)  /*get value of f at midpoint*/
        if scalar(`fa')*scalar(`fm')>0 {
                         scalar `a' =scalar(`m')
                                   }
        if scalar(`fa')*scalar(`fm')<0 {
                         scalar `b'=scalar(`m')
                                   }
        local diff = abs(scalar(`a')  - scalar(`b'))
        scalar `m' = (scalar(`a') + scalar(`b'))/2
                          }

return scalar alpha =scalar(`m')
}  /*end quietly*/
end


capture program drop fmtwo02xtqls
program define fmtwo02xtqls, rclass
version 9.0
tempvar id t z eij zlag frho
tempname anew alpha
gen double `id' = `1'
gen double `t' = `2'
gen double `z' = `3'
scalar `anew' = `4'   /*stage two estimate*/
scalar `alpha' = `5'  /*stage one estimate*/
qui sort `id' `t'
qui by `id': gen `eij' = `t' - `t'[_n-1] if _n>1
qui by `id': gen `zlag' = scalar(`alpha')^`eij'
qui by `id': gen `frho'= /*
*/ ( 2*`eij'*`zlag'^2/scalar(`alpha') - /* 
*/ scalar(`anew')^`eij'*`eij'*(`zlag'/scalar(`alpha') + /*
*/ `zlag'^3/scalar(`alpha')) )/(1 - `zlag'^2)^2
replace `frho'=sum(`frho')
return scalar frho = `frho'[_N]
end


capture drop tritwo06xtqls          /*Program to estimate correlation parameters*/
program define tritwo06xtqls, rclass       /*when we are using QLS and tridiagonal*/ 
                              /*working correlation structure*/
                          /*STAGE TWO ESTIMATE*/

version 9.0           /*Define version number*/
                        
tempvar z t c h ni     /*Define temporary variables.*/    
tempname stageone a b m anew lower fa fm

quietly{          /*start quietly- supresses output*/

gen double `z' = `1'    /*first argument is z'=(z11,z12,....)*/
                              /* (Pearson residuals) */

gen double `t' = `2'    /*2nd argument is t'=(t11,t12,....)*/
                              /* (timings)  */

gen double `c' = `3'    /*3rd argument is id*/
                            /* subject ID */
scalar `stageone' = `4' /*stage one estimate for alpha*/

sort `c' `t'    /*sort id and time*/
                /*let's get limits for feasible region*/
by `c' : gen `ni'=_N if `c'~=. /*create temporary variable ni*/
                               /*which equals the number of records*/
                               /*per subject, if the id variable is*/
                               /*not missing*/

summ `ni'
scalar `lower' = _result(6)  /*scalar `lower' = _result(6), which*/
                           /*equals the largest value of `ni'*/
                           /*`lower' = max(ni), where ni = # of*/
                           /*observations for subject i*/

capture drop `ni'          /*drop temporary variable ni*/

scalar `a' = -1/(2*sin((`lower'-1)/(`lower' + 1)*_pi/2)) + 0.000001
              /*Define lower value of feasible region for alpha*/
              /*Note that we added a small number to the lower value.*/

scalar `b' = 1/(2*sin((`lower'-1)/(`lower' + 1)*_pi/2)) - 0.000001
              /*Define upper value of feasible region for alpha*/
              /*Note that we subtracted a small number from the upper value.*/

pause: list scalar a and scalar b- these are the upper and lower values of the feasible region

scalar `m' = (scalar(`a') + scalar(`b'))/2  /*Set up midpoint, prior to programming bisection method*/

local diff=1    /*set up starting difference*/

while `diff'>.00001 {/*Use bisection until `diff' < 0.000001*/
                    scalar `anew' = scalar(`a')  /*let anew = lower value of interval*/
                    sort `c' `t'      /*sort id and time*/
      ftritwo06xtqls `c' `t' `z' scalar(`anew') scalar(`stageone') /*obtain value of frho at lower limit*/
                    scalar `fa' = r(frho) /*fa = value of f at lower limit*/
                    scalar `anew' = scalar(`m') /*let anew = midpoint*/
      ftritwo06xtqls `c' `t' `z' scalar(`anew') scalar(`stageone') /*sort id and time*/
                    scalar `fm' = r(frho)  /*get value of f at midpoint*/

        if `fa'*`fm'>0 {
        scalar `a' =scalar(`m')
                   }  /*if fa*`fm'>0, let a = midpoint*/

        if `fa'*`fm'<0 {
        scalar `b'=scalar(`m')
                    }  /*if fa*fm<0, let b = midpoint*/

        local diff = abs(scalar(`a')  - scalar(`b')) /*obtain difference between a and b*/

        noi di `diff'  /*display difference, to check convergence*/

        scalar `m' = (scalar(`a') + scalar(`b'))/2 /*redefine midpoint*/

        }   /*end `while' statement*/ 

     return   scalar alpha =scalar(`m')   /*Define stage one estimate, newa*/
        }            /*end quietly statement*/
end


program define ftritwo06xtqls, rclass       /*program to calculate f(rho), for qls*/
version 9.0                 /*stage one tridiagonal function*/

tempvar c t z hij n         /*Define temporary variables.*/
tempname stageone anew stageone frho temp sum
gen double `c' = `1'  /*Generate temporary id variable = 1st argument*/
gen double `t' = `2'  /*Generate temporary time variable = 2nd argument*/
gen double `z' = `3'  /*Generate temporary Pearson residual variable = */
scalar `anew' = `4'   /*Value of alpha to evaluate function at.*/
scalar `stageone' = `5' /*Stage one estimate of alpha.*/


scalar k = 0

scalar `sum' = 0 /*Start with value of zero for sum, which is value*/
                /*of sum to be added to, to obtain value of function*/
                /*to be minimized.*/
quietly { 

tempvar tempid e yij  jj ni   /*declare temporary variable names*/
tempname f eij temp zij x v xp y    /*declare temporary matrix, scalar names*/

sort `c' `t'               /*create temporary ids that take value 1,2...m*/
by `c': gen `tempid' = 1 if _n==1
replace `tempid' = sum(`tempid')


local i = 1                 /*Set up local variable that will be used*/
                             /*to loop through all subjects.*/

tab `tempid'              /*Tabulate id variable.*/
local count = _result(2)   /*local macro count = number of distinct values*/
                           /*for id = number of subjects in the data set.*/

while `i' <= `count' {    /*Next, cycle through all subjects.*/
    mkmat `z' if `tempid'==`i', matrix(`zij') /*create matrix of Pearson*/
                           /*residuals for subject i*/

    local w = rowsof(`zij') /*local macro w = row dimension of matrix `zij'*/             
    matrix R`i' = I(`w')   /*Set up matrix R`i' = identity matrix*/
                            /*with same row dimension as `zij'*/

          /*Next, contstruct `w' by `w' tridiagonal matrix at*/
          /*stage one estimate of alpha.*/
    local j = 2         /*Next, loop from 2 to `w'*/
             while `j' <= `w' {
                                local jmone = `j' - 1
                                matrix R`i'[`jmone',`j'] = scalar(`stageone')
                                matrix R`i'[`j',`jmone'] = scalar(`stageone')
                                local j = `j' + 1
                             } /*end loop to obtain tri-diagonal structure*/



     /*Set up matrix diff`i' = derivative of tri-diagonal matrix*/
     /*evaluated at stage one estimate of alpha.*/

    matrix diff`i' = J(`w',`w',0) /*set up `w' by `w' matrix of zeros*/   

    local j = 2         /*Next, loop from 2 to `w'*/
             while `j' <= `w' {
                                local jmone = `j' - 1
                                matrix diff`i'[`jmone',`j'] = 1
                                matrix diff`i'[`j',`jmone'] = 1
                                local j = `j' + 1
                             } /*end loop to obtain derivative matrix*/


    /*Next, set up R(scalar(`anew')) = tri-diagonal matrix evaluated at*/
    /*the current value of anew.*/

    matrix RR`i' = I(`w')   /*Set up matrix R`i' = identity matrix*/
                            /*with same row dimension as `zij'*/

          /*Next, contstruct `w' by `w' tridiagonal matrix at*/
          /*stage one estimate of alpha.*/
    local j = 2         /*Next, loop from 2 to `w'*/
             while `j' <= `w' {
                                local jmone = `j' - 1
                                matrix RR`i'[`jmone',`j'] = scalar(`anew')
                                matrix RR`i'[`j',`jmone']  = scalar(`anew')
                                local j = `j' + 1
                             } /*end loop to obtain tri-diagonal structure*/


    /*Next, obtain trace(diff(Rinv,scalar(`stageone'))*R(anew)) */

     matrix `temp' = trace(syminv(R`i')*diff`i'*syminv(R`i')*RR`i')
     scalar `temp' = `temp'[1,1]

     scalar `sum' = scalar(`sum') + scalar(`temp')


      /*Next, move on to next subject.*/

      local i = `i' + 1

                   }  /*End the loop.*/

    return scalar frho = scalar(`sum')  /*Assign value of sum to frho.*/

                    } /*End the quietly loop.*/
end
                              
program define equitwoxtqls, rclass

version 9.0

/*file name = equitwoxtqls.ado*/
/*Given stage one estimates anew for equicorrelated structure,*/
/*this program returns the stage two estimate newa.*/


tempvar z id time na  id2 /*
*/  rhotop rhobot temp1 temp2 temp3 /*
*/ f1 f2  anew

tempname na anew

qui gen double `z' = `1' /*outcome variable*/
qui gen double `time' = `2' /*time of measurement*/
qui gen double `id' = `3' /*subject id*/
scalar `anew' = `4'


scalar `rhotop' = 0 /*give starting value for rhotop and `rhobot'*/
scalar `rhobot' = 0

qui sort `id' `time'
qui by `id': gen `id2' = 1 if _n==1
replace `id2' = sum(`id2')

qui summ `id2'
local mm = _result(6)   /*Get largest value of cluster id*/

sort `id2' `time' 

local i = 1  /*now cycle through all clusters*/
while `i' <= `mm' {


qui summ `time' if `id2'==`i'
scalar `na' = _result(2)

global na = scalar(`na')
if $na > 1 { /*cluster only contributes information if na > 1*/


scalar `temp1' = (scalar(scalar(`anew'))^2*(scalar(`na') - /*
*/ 1)*(scalar(`na') - 2) + /*
*/ 2*scalar(scalar(`anew'))*(scalar(`na') - 1))*scalar(`na')

scalar `temp2' = ( 1 + scalar(scalar(`anew'))*(scalar(`na') - 1))^2
scalar `f1' = scalar(`temp1')/scalar(`temp2')

scalar `temp1' = scalar(`na')*(scalar(`na')-1)*(scalar(`anew')^2*/*
*/(scalar(`na')-1) + 1)
scalar `f2' = scalar(`temp1')/scalar(`temp2')

scalar `rhotop' = scalar(`rhotop') + scalar(`f1')
scalar `rhobot' = scalar(`rhobot') + scalar(`f2')
                      } /*end condition on `na'*/

local i = `i' + 1
                      }   /*end condition on i*/

return scalar alpha = scalar(`rhotop')/scalar(`rhobot')


end

capture program drop setup_markov2
program define setup_markov2, rclass  /*Sets up a large matrix that is N by N*/
         /*and contains the Markov structures for individual subjects on*/
         /*the diagonal.*/
version 9.0                 /*be set prior to its execution.*/
tempvar group clust2 id2 time id3 
tempname alpha

preserve
quietly {  /*begin quietly*/

gen double `id2' = `1'  /*Read in id and time variables.*/
gen double `time' = `2'
scalar `alpha' = `3'

qui sort `time'
qui by `time': keep if _n==1

qui sort `time'

qui tab `time'
local num = _result(2)

matrix R=I(`num')  /*set up the intra-subject correlation matrix*/

mkmat  `time', matrix(time)

local a = 1
while `a'<= `num' {
local kstar = `a'+1
while `kstar'<=`num' {
matrix R[`a',`kstar']=scalar(`alpha')^(time[`kstar',1]-time[`a',1])
matrix R[`kstar',`a']=scalar(`alpha')^(time[`kstar',1]-time[`a',1])
local kstar=`kstar'+1 
                     }
local a = `a'+1
               }

return matrix equicorr = R

    } /*end quietly*/
end
                              


