*! -spatreg- Estimates spatial lag and spatial error AR models                 
*! Version 1.0 - 29 January 2001                                               
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define main program                                                      
*  ----------------------------------------------------------------------------

program define spatreg, eclass
version 7.0

if replay() {
	if "`e(cmd)'"!="spatreg" {
		error 301
	}
	Display `0'
}
else {
	Estimate `0'
}

end




*  ----------------------------------------------------------------------------
*  2. Define Estimate program                                                  
*  ----------------------------------------------------------------------------

program define Estimate, eclass
version 7.0


/* Define sintax */
syntax varlist, Weights(string) Eigenval(string) Model(string)   /*
           */   [Nolog Robust Level(passthru)]


/* Drop variables */
capture qui drop yLAG* EIGS*
capture qui drop XLAG*


/* Check sintax */
local N=_N
capture qui matrix list `weights'
if _rc==111 {
	di as err "Matrix `weights' does not exist"
	exit
}

local RN : rownames(`weights')
local CN : colnames(`weights')
local WTYPE : word 1 of `RN'
local WBINA : word 2 of `RN'
local WSTAN : word 3 of `RN'
local LOW1 : word 1 of `CN'
local LOW2 : word 2 of `CN'
local LOWER "`LOW1'.`LOW2'"
local UPP1 : word 3 of `CN'
local UPP2 : word 4 of `CN'
local UPPER "`UPP1'.`UPP2'"
if "`WTYPE'"!="SWMImpo" & "`WTYPE'"!="SWMDist" {
	di as err "Matrix `weights' has not been created by -spatwmat-."
	di as err "To run -spatdiag-, create weights matrix with -spatwmat-"
	exit
}

local DIM=rowsof(`weights')
if `DIM'!=`N' {
	di as err "Matrix `weights' is `DIM'x`DIM', the dataset in use has `N' obs."
	di as err "To run -spatreg- weights matrix dimension must equal N. of obs"
	exit
}

capture qui matrix list `eigenval'
if _rc==111 {
	di as err "Matrix `eigenval' does not exist"
	exit
}

local DIM=rowsof(`eigenval')
if `DIM'!=`N' {
	di as err "Matrix `eigenval' is `DIM'x1, the dataset in use has `N' obs."
	di as err "To run -spatreg- eigenvalues matrix dimension must equal N. of obs"
	exit
}

if "`model'"!="lag" & "`model'"!="error" {
   di as err "Option model() accepts only the following arguments:"
   di as err "lag   : spatial lag model"
   di as err "error : spatial error model"
   exit
}


/* Define display labels */
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


/* Tokenize varlist */
tokenize `varlist'
local y="`1'"
mac shift
local X "`*'"
local NX : word count `X'


/* Create lagged variables and variable containing eigenvalues */
tempname W
matrix `W'=`weights'
tempname TEMP
mkmat `y', matrix(`TEMP')
matrix yLAG=`W'*`TEMP'
svmat double yLAG

if `NX'>0 {
   tempname TEMP
   mkmat `X', matrix(`TEMP')
   matrix XLAG=`W'*`TEMP'
   svmat double XLAG
}

svmat double `eigenval', n(EIGS)
qui summ EIGS1
local LOWER=1/r(min)
local UPPER=1/r(max)


/* Compute diagnostics */
qui regress `y' `X'
qui spatdiag, w(`W')
tempname TEMP
matrix `TEMP'=r(stats)
local LMERR=`TEMP'[2,1]
local LMLAG=`TEMP'[4,1]


/* Produce starting values */
qui regress `y' `X'
matrix OLSb=e(b)
local OLSsig=e(rmse)
local i=1
while `i'<=(`NX'+1) {
	local VAL=OLSb[1,`i']
	local b0 "`b0'`VAL' "
	local i=`i'+1
}
local b0 "`b0'0 `OLSsig'"


/* Estimate spatial lag model */
if "`model'"=="lag" {
	ml model lf splag_ll (`y':`y'=`X') (rho:) (sigma:), `robust' `nolog'   /*
	    */   maximize continue init(`b0', copy)                            /*
	    */   title("Spatial lag model")

	tempvar YHAT
	qui predict `YHAT'
	qui replace `YHAT'=`YHAT'+yLAG1*[rho]_b[_cons]
	qui summ
	tempname yhat
	qui mkmat `YHAT', matrix(`yhat')

	tempvar RESIDS
	qui generate `RESIDS'=`y'-`YHAT'
	tempname e
	qui mkmat `RESIDS', matrix(`e')

   qui summ `YHAT'
   local NUM=r(Var)
   qui summ `y'
   local DEN=r(Var)
   local VARRAT=`NUM'/`DEN'
   qui correlate `YHAT' `y'
   local SQCORR=r(rho)*r(rho)
   
   local WALD=([rho]_b[_cons]/[rho]_se[_cons])^2

	est matrix yhat `yhat'
	est matrix resid `e'
	est local cmd "spatreg"
	est scalar df_m=1
	est scalar p=chiprob(1,e(chi2))
	est scalar minEigen=`LOWER'
	est scalar maxEigen=`UPPER'
	est scalar Wald=`WALD'
	est scalar LM=`LMLAG'
	est scalar varRatio=`VARRAT'
	est scalar sqCorr=`SQCORR'
}

/* Estimate spatial error model */
if "`model'"=="error" {
	local NAMES : colnames(OLSb)
	local i=1
	while `i'<=(`NX'+1) {
		local ITEM : word `i' of `NAMES'
		local MODEL "`MODEL'(`ITEM':) "
		local i=`i'+1
	}
   local MODEL "`MODEL'(lambda:) (sigma:)"
   
   global ARGS ""
	local i=1
	while `i'<=`NX' {
		global ARGS "$ARGS beta`i'"
		local i=`i'+1
	}
   global ARGS "$ARGS beta0 lambda sigma"

	ml model lf sperr_ll `MODEL', `robust' `nolog'   /*
	    */   maximize continue init(`b0', copy)      /*
	    */   title("Spatial error model")

	est local cmd "spatreg"
	est local depvar "`y'"
	est scalar df_m=1
	est scalar p=chiprob(1,e(chi2))
	est scalar k_eq=3
	est scalar k_dv=1

	tempname BETA
	matrix `BETA'=e(b)
	local i=1
	while `i'<=`NX' {
		local ITEM : word `i' of `NAMES'
		local COLNAME "`COLNAME'`y':`ITEM' "
		local i=`i'+1
	}
   local COLNAME "`COLNAME'`y':_cons lambda:_cons sigma:_cons"
   matrix  colnames `BETA'=`COLNAME'
   est repost b=`BETA',rename	

	tempvar YHAT
	qui predict `YHAT'
	tempname yhat
	qui mkmat `YHAT', matrix(`yhat')

	tempvar RESIDS
	qui generate `RESIDS'=`y'-`YHAT'
	tempname e
	qui mkmat `RESIDS', matrix(`e')

   qui summ `YHAT'
   local NUM=r(Var)
   qui summ `y'
   local DEN=r(Var)
   local VARRAT=`NUM'/`DEN'
   qui correlate `YHAT' `y'
   local SQCORR=r(rho)*r(rho)

   local WALD=([lambda]_b[_cons]/[lambda]_se[_cons])^2

	est matrix yhat `yhat'
	est matrix resid `e'
	est scalar minEigen=`LOWER'
	est scalar maxEigen=`UPPER'
	est scalar Wald=`WALD'
	est scalar LM=`LMERR'
	est scalar varRatio=`VARRAT'
	est scalar sqCorr=`SQCORR'
}


/* Display results */
di _newline
di as txt "Weights matrix"
di as txt " Name: " as res "`weights'"
di as txt " Type: " as res "`LBLTYPE'"
if "`WTYPE'"=="SWMDist" {
	di as txt " Distance band: " as res "`LBLBAND'"
}
di as txt " Row-standardized: " as res "`WSTAN'"
Display, `level' `robust'


/* Drop added objects */
capture qui drop yLAG* EIGS*
capture qui drop XLAG*
qui matrix drop yLAG
capture qui matrix drop XLAG
qui matrix drop OLSb
qui macro drop ARGS


/* End program */
end




*  ----------------------------------------------------------------------------
*  3. Define Display program                                                   
*  ----------------------------------------------------------------------------

program define Display
version 7.0


/* Define syntax */
syntax, [Level(int $S_level) robust]

/* Display results */
di _newline
di as txt "`e(title)'" _col(52) "Number of obs" _col(68) "=" as res %10.0f `e(N)'
di as txt _col(52) "Variance ratio" _col(68) "=" as res %10.3f `e(varRatio)'
di as txt _col(52) "Squared corr." _col(68) "=" as res %10.3f `e(sqCorr)'
di as txt "Log likelihood = " as res `e(ll)' as txt _col(52) "Sigma"   /*
     */   _col(68) "=" as res %10.2f [sigma]_b[_cons]
di ""
ml display, level(`level') neq(1) plus noheader
if "`e(title)'"=="Spatial lag model" {
_diparm rho, level(`level') label("rho")
local PARM "rho"
local P "Rho"
local TYPE "lag"
}
if "`e(title)'"=="Spatial error model" {
_diparm lambda, level(`level') label("lambda")
local PARM "lambda"
}
di as txt "{hline 13}{c BT}{hline 64}"
di as txt "Wald test of `PARM'=0:" _col(40) "chi2(1) = "   /*
*/ as res _col(50) %7.3f `e(Wald)' as txt " ("             /*
*/ as res %5.3f chiprob(1,`e(Wald)') as txt ")"
if "`robust'"=="" {
   di as txt "Likelihood ratio test of `PARM'=0:" _col(40) "chi2(1) = "   /*
   */ as res _col(50) %7.3f `e(chi2)' as txt " ("                         /*
   */ as res %5.3f chiprob(1,`e(chi2)') as txt ")"
}
di as txt "Lagrange multiplier test of `PARM'=0:" _col(40) "chi2(1) = "   /*
*/ as res _col(50) %7.3f `e(LM)' as txt " ("                              /*
*/ as res %5.3f chiprob(1,e(LM)) as txt ")"
di ""
di as txt "Acceptable range for `PARM': " as res %5.3f `e(minEigen)'   /*
   */   " < `PARM' < " %5.3f `e(maxEigen)'   
di _newline

/* End program */
end


