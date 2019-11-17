*! Version 1.0 - 29 January 2001  STB-60 sg162
*! -spatdiag- Diagnostic tests for spatial dependence in OLS regression        
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define program                                                           
*  ----------------------------------------------------------------------------

program define spatdiag, rclass
version 7.0




*  ----------------------------------------------------------------------------
*  2. Define syntax                                                            
*  ----------------------------------------------------------------------------

syntax, Weights(string)




*  ----------------------------------------------------------------------------
*  3. Check conditions for running the tests and syntax                        
*  ----------------------------------------------------------------------------

if "`e(cmd)'"!="regress" {
	di as err "This command can be used only after -regress-"
	exit
}

capture qui matrix list `weights'
if _rc==111 {
	di as err "Matrix `weights' does not exist"
	exit
}

local ROWNAME : rownames(`weights')
local COLNAME : colnames(`weights')
local WTYPE : word 1 of `ROWNAME'
local WBINA : word 2 of `ROWNAME'
local WSTAN : word 3 of `ROWNAME'
local LOW1 : word 1 of `COLNAME'
local LOW2 : word 2 of `COLNAME'
local LOWER "`LOW1'.`LOW2'"
local UPP1 : word 3 of `COLNAME'
local UPP2 : word 4 of `COLNAME'
local UPPER "`UPP1'.`UPP2'"
if "`WTYPE'"!="SWMImpo" & "`WTYPE'"!="SWMDist" {
	di as err "Matrix `weights' has not been created by -spatwmat-."
	di as err "To run -spatdiag-, create weights matrix with -spatwmat-"
	exit
}

local DIM=rowsof(`weights')
if `DIM'!=e(N) {
	di as err "Matrix `weights' is `DIM'x`DIM', " _c
	di as err "regression has been carried out on `e(N)' obs."
	di as err "To run -spatdiag- weights matrix dimension must equal N. of obs"
	exit
}




*  ----------------------------------------------------------------------------
*  4. Define basic quantities                                                  
*  ----------------------------------------------------------------------------

/* Display labels */
if "`WTYPE'"=="SWMImpo" & "`WBINA'"=="Yes" {
	local LBLTYPE "Imported (binary)"
}
if "`WTYPE'"=="SWMImpo" & "`WBINA'"=="No" {
	local LBLTYPE "Imported (non-binary)"
}
if "`WTYPE'"=="SWMDist" & "`WBINA'"=="Yes" {
	local LBLTYPE "Distance-based (binary)"
	local LBLBAND "`LOWER' < d <= `UPPER'"
}
if "`WTYPE'"=="SWMDist" & "`WBINA'"=="No" {
	local LBLTYPE "Distance-based (inverse distance)"
	local LBLBAND "`LOWER' < d <= `UPPER'"
}

/* Weights matrix */
local W="`weights'"

/* Name of dependent variable */
local YVAR=e(depvar)

/* List of regressors */
tempname BETA
matrix `BETA'=e(b)
matrix `BETA'=`BETA''
local TEMP1 : rownames(`BETA')
local TEMP2 : word count `TEMP1'
local TEMP2=`TEMP2'-1
local i=1
while `i'<=`TEMP2' {
	local TEMP3 : word `i' of `TEMP1'
	local XVAR "`XVAR'`TEMP3' "
	local i=`i'+1
}

/* N. of cases */
local N=e(N)

/* Degrees of freedom */
local DF=e(df_r)

/* N. of regressors */
local NX=e(df_m)
local K=`NX'+1

/* Residual sum of squares */
local RSS=e(rss)

/* Error variance */ 
local ERRVAR=`RSS'/`N'

/* Residuals */
tempvar TEMP
predict `TEMP', r
tempname e
mkmat `TEMP', matrix(`e')

/* Matrix of explanatory variables */
preserve
tempvar ONE
qui gen `ONE'=1
tempname X
mkmat `XVAR' `ONE', matrix(`X')
restore

/* Cross-product matrix of explanatory variables */
tempname CPX
matrix `CPX'=`X''*`X'

/* Matrix for storing results */
tempname RESULTS
matrix `RESULTS'=J(5,3,0)
matrix rownames `RESULTS'=Moran LMerr RLMerr LMlag RLMlag
matrix colnames `RESULTS'=stat df p-value




*  ----------------------------------------------------------------------------
*  5. Moran's I test (error)                                                   
*  ----------------------------------------------------------------------------

/* Observed value */
tempname ONECOL ONEROW TEMP
matrix `ONECOL'=J(`N',1,1)
matrix `ONEROW'=J(1,`N',1)
matrix `TEMP'=`ONEROW'*`W'*`ONECOL'
local S0=`TEMP'[1,1]
tempname TEMP
matrix `TEMP'=`e''*`W'*`e'
local eWe=`TEMP'[1,1]
local I=(`N'/`S0')*`eWe'/`RSS'

/* Expected value */
tempname A a
matrix `A'=syminv(`CPX')
matrix `A'=`A'*`X''*`W'*`X'
scalar `a'=trace(`A')
local EI=-(`N'*`a')/(`DF'*`N')

/* Variance and standard error */
local S1=0
local i=1
while `i'<=`N' {
	local j=1
	while `j'<=`N' {
		local S1=`S1'+(`W'[`i',`j']+`W'[`j',`i'])^2
		local j=`j'+1
	}
	local i=`i'+1
}
local S1=`S1'/2
tempname WW B b AA aa
matrix `WW'=(`W'+`W'')*(`W'+`W'')
matrix `B'=syminv(`CPX')
matrix `B'=`B'*`X''*`WW'*`X'
scalar `b'=trace(`B')
matrix `AA'=`A'*`A'
scalar `aa'=trace(`AA')
local VI=( (`N'*`N') / ((`N'*`N')*(`DF')*(`DF'+2)) )   /*
    */   *( `S1' + 2*`aa' - `b' - 2*(`a'*`a')/`DF' )
local SEI=sqrt(`VI')    

/* Statistic */
local MI=(`I'-`EI')/`SEI'

/* Store results */
matrix `RESULTS'[1,1]=`MI'
matrix `RESULTS'[1,2]=1
matrix `RESULTS'[1,3]=2*(1-normprob(`MI'))
local L1="Moran's I"




*  ----------------------------------------------------------------------------
*  6. Lagrange multiplier test (error)                                         
*  ----------------------------------------------------------------------------

/* Statistic */
tempname WW ww
matrix `WW'=`W''*`W'+`W'*`W'
scalar `ww'=trace(`WW')
local LMERR=((`eWe'/`ERRVAR')^2) / `ww'

/* Store results */
matrix `RESULTS'[2,1]=`LMERR'
matrix `RESULTS'[2,2]=1
matrix `RESULTS'[2,3]=chiprob(1,`LMERR')
local L2="Lagrange multiplier"




*  ----------------------------------------------------------------------------
*  7. Lagrange multiplier test (lag)                                           
*  ----------------------------------------------------------------------------

/* Statistic */
tempname Y YLAG
mkmat `YVAR', matrix(`Y')
matrix `YLAG'=`W'*`Y'

tempname TEMP
matrix `TEMP'=`e''*`YLAG'
local eWy=`TEMP'[1,1]

tempname WXb
matrix `WXb'=`W'*`X'*`BETA'

tempname I M
matrix `I'=I(`N')
matrix `M'=syminv(`CPX')
matrix `M'=`I'-`X'*`M'*`X''

tempname TEMP
matrix `TEMP'=`WXb''*`M'*`WXb'
local WMW=`TEMP'[1,1]

local LMLAG=((`eWy'/`ERRVAR')^2) / (`WMW'/`ERRVAR' + `ww') 

/* Store results */
matrix `RESULTS'[4,1]=`LMLAG'
matrix `RESULTS'[4,2]=1
matrix `RESULTS'[4,3]=chiprob(1,`LMLAG')
local L4="Lagrange multiplier"




*  ----------------------------------------------------------------------------
*  8. Robust Lagrange multiplier test (error)                                  
*  ----------------------------------------------------------------------------

/* Statistic */
local RJ=1/(`ww'+`WMW'/`ERRVAR')
local RLMERR=(`eWe'/`ERRVAR' - `ww'*`RJ'*(`eWy'/`ERRVAR'))^2 /   /*
        */   (`ww' - `ww'*`ww'*`RJ')

/* Store results */
matrix `RESULTS'[3,1]=`RLMERR'
matrix `RESULTS'[3,2]=1
matrix `RESULTS'[3,3]=chiprob(1,`RLMERR')
local L3="Robust Lagrange multiplier"




*  ----------------------------------------------------------------------------
*  9. Robust Lagrange multiplier test (lag)                                    
*  ----------------------------------------------------------------------------

/* Statistic */
local RLMLAG=(`eWy'/`ERRVAR' - `eWe'/`ERRVAR')^2 / ((1/`RJ')-`ww')

/* Store results */
matrix `RESULTS'[5,1]=`RLMLAG'
matrix `RESULTS'[5,2]=1
matrix `RESULTS'[5,3]=chiprob(1,`RLMLAG')
local L5="Robust Lagrange multiplier"




*  ----------------------------------------------------------------------------
*  10. Display results                                                         
*  ----------------------------------------------------------------------------

di _newline
di as txt "{title:Diagnostic tests for spatial dependence in OLS regression}"
di _newline
local LEN=length("`YVAR'")
local LEN=`LEN'+3
di as txt "Fitted model"
di as txt "{hline 60}"
di "{p 0 `LEN' 24}" as res "`YVAR'" as txt " = " _c
local NX : word count `XVAR'
local i=1
while `i'<=`NX' {
	local X : word `i' of `XVAR'
	if `i'<`NX' {
		di as res "`X'" _c
		di as txt " + " _c
	}
	if `i'==`NX' {
		di as res "`X'"
	}
	local i=`i'+1
}
di "{p_end}"
di as txt "{hline 60}"
di ""
di as txt "Weights matrix"
di as txt "{hline 60}"
di as txt "Name: " as res "`W'"
di as txt "Type: " as res "`LBLTYPE'"
if "`WTYPE'"=="SWMDist" {
	di as txt "Distance band: " as res "`LBLBAND'"
}
di as txt "Row-standardized: " as res "`WSTAN'"
di as txt "{hline 60}"
di ""
di as txt "Diagnostics"
di as txt "{hline 31}{c TT}{hline 28}"
di as txt _col(1) "Test" _col(32) "{c |}" _col(35) "Statistic" _col(48) "df"  /*
     */   _col(53) "p-value"
di as txt "{hline 31}{c +}{hline 28}"
di as txt "Spatial error:" _col(32) "{c |}"
local i=1
while `i'<=3 {
	di as txt "  `L`i''" _col(32) "{c |}"       /*
   */ as res _col(35) %8.3f `RESULTS'[`i',1]   /*
   */        _col(48) %2.0f `RESULTS'[`i',2]   /*
   */        _col(54) %5.3f `RESULTS'[`i',3]
	local i=`i'+1
}
di as txt _col(32) "{c |}"
di as txt "Spatial lag:" _col(32) "{c |}"
local i=4
while `i'<=5 {
	di as txt "  `L`i''" _col(32) "{c |}"       /*
   */ as res _col(35) %8.3f `RESULTS'[`i',1]   /*
   */        _col(48) %2.0f `RESULTS'[`i',2]   /*
   */        _col(54) %5.3f `RESULTS'[`i',3]
	local i=`i'+1
}
di as txt "{hline 31}{c BT}{hline 28}"
di _newline




*  ----------------------------------------------------------------------------
*  11. Return estimates                                                        
*  ----------------------------------------------------------------------------

return matrix stats `RESULTS'




*  ----------------------------------------------------------------------------
*  12. End program                                                             
*  ----------------------------------------------------------------------------

capture matrix drop Z
capture matrix drop C
end



