*! Forward search regression. v.1.2, 11.06.2001 Stas Kolenikov
program define fsreg
   version 6
   #delimit ;
   syntax varlist(numeric min=2) [if] [in], 
      CLEAR [Dots SAVing(str) REPLACE ID(varname) Level(int $S_level) 
      RESiduals RSTUdent RSTAndard NRes(int 0) INITial(int 0) 
      OBS(numlist integer) LMD(passthru) WHICH MEDian]
   ;
   #delimit cr

   if ("`residua'"~="") + ("`rstuden'"~="") + ("`rstanda'"~="") >1 {
      di in red "cannot specify more than one type of residuals"
      exit 198
   }
   local restype `residua'`rstuden'`rstanda'

   if ("`restype'"=="" & `nres'!=0) | ("`restype'"=="" & "`obs'"~="") {
      di in red "what sort of residuals?"
      exit 198
   }

   if `nres'~=0 & "`obs'"~="" {
      di in red "cannot specify the residuals and observations together"
      exit 198
   }

   marksample touse
   if "`id'"=="" { 
      tempvar id
      qui g long `id'=_n
      qui compress `id'
   }
   confirm numeric var `id'
   qui keep if `touse'
   qui keep `varlist' `id'

   di in gre _n "   Forward search regression" _n

   * First piece: initial subset choice by robust regression
   * Second piece: forward inclusion with accumulating diagnostics
   * Third piece: nice graphs -- call to fsregrph

   * So, the first piece

   tempvar sm

   if "`dots'"~="" { di _n in gre "Choosing the initial subset " _c }
   Choice `varlist', gen(`sm') m(`initial') `lmd' `dots' `median'
   local m=r(m)

   if "`which'"~="" { 
     local i=1
     while `i'<=`m' {
       local iid = `id'[`i']
       local stlist `stlist' `iid'
       local i=`i'+1
     }
     di in gre _n "Started with observations: " in yel "`stlist'"
   }

   if "`obs'"~=""  { 
                     tokenize `obs'
                     local nres: word count `obs'
   }
   if "`nres'"~="" {
**** di in whi "`nres':"
     local k=1
     while `k'<=`nres' {
       if "`restype'"~="" { local id`k'=`id'[_N+1-`k'] }
       if "`obs'"~="" { local id`k'=``k'' }
       local resstr `resstr' _r`id`k''
****** di in whi "`resstr'"
       local k=`k'+1
     }
   }
   * some residuals or observations

   * done with the first stage. Now, cycling over the subsets

   tokenize `varlist'
   mac shift
   local k=1
   while "``k''"~="" {
     local tlist `tlist' _t`k'
     local k=`k'+1
   }
   local tlist `tlist' _t`k'
   * This is the list of the t-stats. Do not forget the constant !

   if "`saving'"=="" { 
     local saving FSRegData 
     local replace replace
   }
   label data "Forward search regression data"
   qui postfile FSREG _nobs _added `*' _cons `tlist' _sigma2 _scom2 _scom1 _scom05 _sco0 _sco05 _sco1 _sco2 _rstum _resoutm _skew _kurt `resstr' using `saving', `replace' every(20)
** di in whi `"POSTFILE was: FSREG _nobs _added `*' _cons `tlist' _sigma2 _scom2 _scom1 _scom05 _sco0 _sco05 _sco1 _sco2 _rstum _resoutm _skew _kurt `resstr' using `saving', `replace' "'

   * number of observations; which observation added; the list of regressors;
   * the list of the t-statistics for the regressors; the MSE;
   * the scores for the Box-Cox transformation

** set trace on
** set more off

   * the main cycle
   if "`dots'"~="" { di in gre "Adding observations starting from " in yel `m' }
   tempvar res aux eh rstud fit
   tempname eb eV
   tokenize `varlist' _cons
   mac shift
   * to get rid of the depvar
   while `m'<=_N {
      qui {
         local m1=`m'+1

         * the main regression
         reg `varlist' if `sm'
         local betas
         local tstats
         mat `eb'=e(b)
         mat `eV'=e(V)
         local k=1
         while "``k''"~="" {
           local thisb=_b[``k'']
           local betas `betas' (`thisb')
           local thist=_b[``k'']/sqrt(`eV'[`k',`k'])
           local tstats `tstats' (`thist')
           local k=`k'+1
         }
         local s2=e(rmse)^2
         estimates hold `eh'

         * now, regression with the auxiliary variables
         * we need: _scom2 _scom1 _scom05 _sco0 _sco05 _sco1 _sco2

         cap RegBC `varlist' if `sm', l(-2)
         local scom2=r(tscore)
         cap RegBC `varlist' if `sm', l(-1)
         local scom1=r(tscore)
         cap RegBC `varlist' if `sm', l(-0.5)
         local scom05=r(tscore)
         cap RegBC `varlist' if `sm', l(0)
         local sco0=r(tscore)
         cap RegBC `varlist' if `sm', l(0.5)
         local sco05=r(tscore)
         cap RegBC `varlist' if `sm', l(1)
         local sco1=r(tscore)
         cap RegBC `varlist' if `sm', l(2)
         local sco2=r(tscore)
         local scolist (`scom2') (`scom1') (`scom05') (`sco0') (`sco05') (`sco1') (`sco2')

         * the next step: the least residuals
         estimates unhold `eh'
         cap drop `res'
         predict `res', res
         qui sum `res' , d
         local skew = r(skewness)
         local kurt = r(kurtosis)
         replace `res'=abs(`res')
         sort `res'
         local resmin=`res'[`m1']
         cap drop `rstud'
         predict `rstud', rstu, if e(sample)
         replace `rstud'=abs(`rstud')
         sort `rstud'
         local rstumax=`rstud'[`m']
         if "`nres'"~="" {
            local j=1
            local resstr

            if "`residua'"~="" {
              while `j'<=`nres' {
                sum `res' if `id'==`id`j'', meanonly
                local thisr=r(mean)
                local resstr `resstr' (`thisr')
                local j=`j'+1
              } 
            }
            * if simple residuals

            if "`rstuden'"~="" {
              cap drop `rstud'
              predict `rstud', rstu
              while `j'<=`nres' {
                sum `rstud' if `id'==`id`j'', meanonly
                local thisr=abs(r(mean))
                local resstr `resstr' (`thisr')
                local j=`j'+1
              } 
            }
            if "`rstanda'"~="" {
              cap drop `rstud'
              predict `rstud', rsta
              * mind the abuse of `rstud' variable!!!
              while `j'<=`nres' {
                sum `rstud' if `id'==`id`j'', meanonly
                local thisr=abs(r(mean))
                local resstr `resstr' (`thisr')
                local j=`j'+1
              } 
            }
            * if studentized residuals
         }

********
*        di in whi _n "Old sm"
***      sort `id'
*        noi li `id' `res' `sm'
********

         if _N~=`m' { count if `sm'==1 in 1/`m1' }
               else { count }
******** di in whi r(N) " of " `m'
         if r(N)==`m' & `m'!=_N {
               sort `sm' in 1/`m1'
               local added=`id'[1]
         }
         else { local added=-9999 }
         * hard to tell what was added
         if `m'<_N { replace `sm'= (_n<=`m1') }

********
*        di in whi _n "New sm (added: `added' ?)"
***      sort `id'
*        noi li `id' `res' `sm'
********


******** di in whi `"POST: FSREG `m' (`added') `betas' `tstats' (`s2') `scolist' `resstr' "'
         post FSREG `m' (`added') `betas' `tstats' (`s2') `scolist' (`rstumax') (`resmin') (`skew') (`kurt') `resstr' 

      }
      * end of quietly
      if "`dots'"~="" { di in gre "." _c }
      local m=`m1'
   }
   * end of the iteration
   postclose FSREG
   * done with the second stage. Now, graphing the stuff

   qui use `saving', clear
   char _dta[fsreg] "Forward search regression data"
   char _dta[start]  "`stlist'"
   if "`residua'"~="" { char _dta[res]   "simple" }
   if "`rstuden'"~="" { char _dta[res]   "studentized" }
   if "`rstanda'"~="" { char _dta[res]   "standardized" }
   local k=1
   while "``k''"~="" {
     lab var ``k'' "Coeff. of ``k''"
     lab var _t`k' "t-statistic of ``k''"
     local k=`k'+1
   }
   tokenize `varlist'
   char _dta[depvar] "`1'"
   mac shift
   char _dta[fsregl] "`*'"
   * add some stuff about the residuals!!!
   if "`nres'"~="" {
      local j=1
      while `j'<=`nres' {
         lab var _r`id`j'' "Residual in obs. no. `id`j''"
         local j=`j'+1
      }
   }

   NiceLab
   qui save, replace

   fsregrph, score

   di _n in gre "Use " in whi "fsregrph" in gre " now to produce other nice graphs."
end

pro def Choice, rclass
    syntax varlist, GEN(str) M(int) [LMD(int -1) DOTS MEDIAN]
    quietly {
     if `m'==0 {
       local m: word count `varlist'
       local m=max(20,`m',_N/10)
     }
     if `lmd'==-1 {
       * robust regression initialization
       rreg `varlist'
       tempvar res
       predict `res', r
       replace `res'=abs(`res')
       sort `res'
*       noi di "..."
     }
     else {
       * random search for the least median deviation regression
       local md=1e12
       local i=1
       tempvar seed res indic obs
       g `seed' = .
       g long `indic' = .
       g long `obs' = _n
       while `i'<=`lmd' {
         if "`median'"~="" { local median q }
         `median'reg `varlist' in 1/`m'
         cap drop `res'
         predict `res' if e(sample)
         replace `res' = abs(`res')
         sort `res' `seed'
         local med = `res'[int(`m'/2)]
         if `med'<`md' { replace `indic' = e(sample) }
         local i=`i'+1
         if "`dots'"~="" & mod(`i',50)==0 { noi di in gre "." _c }
         replace `seed' = uniform()
         sort `seed'
       }
       gsort -`indic' `obs'
       noi di
     }
     * sorted so that the first observations are to enter the set
     g long `gen'=_n<=`m'
     compress `gen'
     * noi tab `indic' `gen'
     return scalar m=`m'
    }
    * end of quietly
end

pro def RegBC, rclass
   syntax varlist [if], Lambda(real)

   marksample touse
   tokenize `varlist'
   qui {
     tempvar z w
     means `1'
     local mg=r(mean_g)
     if `lambda'==0 {  
        g `z'=`mg'*log(`1') 
        g `w'=`z'*(.5*log(`1')-log(`mg'))
     }
     else { 
        g `z'=(`1'^`lambda'-1)/(`lambda'*`mg'^(`lambda'-1))
        g `w'=(`1'^`lambda'*log(`1')-(`1'^`lambda'-1)*(1/`lambda'+log(`mg')) )/(`lambda'*`mg'^(`lambda'-1))
     }
     mac shift
   }

     reg `z' `w' `*' if `touse'
*    if _rc==2000 { 
*       di in red "Error 2000 encountered!"
*       noi sum `z' `w' 
*       di in whi `mg'
*    }
     tempname eb eV
     mat `eb'=e(b)
     mat `eV'=e(V)
     local t=`eb'[1,1]/sqrt(`eV'[1,1])
*     di in whi "Lambda = " `lambda' "; t-score = " `t' "; geom. mean = " `mg'
*     sum `z' `w'
   return scalar tscore= `t'
end

pro def NiceLab

   lab var _nobs "Number of observations"
   lab var _added "The observation added at this step"
   qui mvdecode _added , mv(-9999)
   lab var _sigma2 "MSE residuals squared"
   lab var _scom2 "Score test for lambda=-2"
   lab var _scom1 "Score test for lambda=-1"
   lab var _scom05 "Score test for lambda=-0.5"
   lab var _sco0 "Score test for lambda=0"
   lab var _sco05 "Score test for lambda=0.5"
   lab var _sco1 "Score test for lambda=1"
   lab var _sco2 "Score test for lambda=2"
   lab var _rstum "Largest studentized residual in subset"
   lab var _resoutm "Smallest residual out of subset"
   lab var _kurt "Residual kurtosis"
   lab var _skew "Residual skewness"

   qui {
      g str2 _labm2="-2"
      replace _labm2="." in 2/-2

      g str2 _labm1="-1"
      replace _labm1="." in 2/-2

      g str4 _labm05="-0.5"
      replace _labm05="." in 2/-2

      g str1 _lab0="0"
      replace _lab0="." in 2/-2

      g str1 _lab2="2"
      replace _lab2="." in 2/-2

      g str1 _lab1="1"
      replace _lab1="." in 2/-2

      g str3 _lab05="0.5"
      replace _lab05="." in 2/-2

      unab labl : _lab*
      tokenize `labl'
      while "`1'"~="" {
          lab var `1' "Labels for graphs"
          mac shift
      }
   }
end
