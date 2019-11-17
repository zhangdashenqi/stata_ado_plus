*! version 6.0.2  08aug2000
program define logitem, eclass
	version 6.0
	local options `"Level(integer $S_level) noOR"'
	if replay() {
		if `"`e(cmd)'"'~=`"logitem"' { 
			error 301
		}
		syntax [, `options']
	}
	else { 
		syntax varlist  [if] [in] , sens(string) spec(string) [ /*
		*/ `options' noLOG ITErate(integer 16000) /*
		*/ LTOLerance(real 0) TOLerance(real 1e-6)]

		marksample touse
		qui cap assert `sens'>=0 & `sens'<=1 if `touse'
		if _rc {
			di in red "invalid values for sens(`sens'). " /*
			*/ "Values must between 0 and 1"
			exit 198
		}
		qui cap assert `spec'>=0 & `spec'<=1 if `touse'
 		if _rc {
			di in red "invalid values for sens(`sens'). " /*
			*/ "Values must between 0 and 1"
			exit 198
		}
		local ltol= `ltolerance'
		local tol= `tolerance'
		
		if "`ltol'"~=""  {
			if `ltol' > 0.003 {
				noi di in red /*
				*/ "Converge value must be less than 1e-3"
				exit 198
			}
		}
		if  "`tol'"~="" {
			if `tol' > 0.003 {
				noi di in red /*
				*/ "Converge value must be less than 1e-3"
				exit 198
			}
		}
		if `"`log'"'~="" {
			local log="qui"
		}
		/* get starting wts values */
		`log' di _n in gr "Fitting full model:"
		qui logit `varlist' if `touse' 
		`log' di in gr "Iteration 0:   log likelihood = " /*
		 */ in ye %12.6f e(ll) 
		tempname ll0
		scalar `ll0'=e(ll)
		local depvar=e(depvar)
		tempvar wts
		qui gen double `wts'=.
		local wtype="iw"
		if `"`robust'"' ~="" {
			local wtype = "pw"
		}
		EXPstep `wts' `depvar' `touse' `sens' `spec'
		MAXstep `varlist' if `touse' [`wtype' = `wts'], depvar(`depvar')
		local i 1
		local conv = 0
		local noconv = 0
		tempname myB2
		while `conv' == 0 {
			*sum `wts'
			EXPstep `wts' `depvar' `touse' `sens' `spec'
			MAXstep `varlist' if `touse' [`wtype' =`wts'], /*
			*/ depvar(`depvar')
			/* invert matrix to check for concavity */
			tempname inmat ll myB1
			mat `inmat'=syminv(e(V))
			mat `myB1'=(e(b))
			local concave =""
			if _rc {
				local concave = "(not concave)" 
			}
			tempvar p p0 llt
			qui predict double `p' if `touse' , p
			qui gen double `p0' = 1-`p' if `touse'
			qui gen double `llt' = /*
			*/ log((`p'*`sens' + `p0'*(1-`spec'))^`depvar')  /*
			*/ + log((`p'*(1-`sens') + `p0'*`spec')^(1-`depvar'))
			qui replace  `llt'= sum(`llt') if `touse'
			scalar `ll' = `llt'[_N]
			`log' di in gr "Iteration `i':   log likelihood = " /*
		 	*/ in ye %12.6f `ll' "  " `concave'
			*/ _col(16) "log likelihood = " in ye /*
			*/ %10.0g `ll' "  " `concave'
			if `i' > 2 {
				if reldif(`ll`i'',`ll') < `ltol' {
					local conv=1
				}
				if mreldif(`myB1' ,`myB2') < `tol' {
					local conv=1
				}
			}	
			if `i'==`iterate' {
					local conv=1
					local noconv=1
			}
			mat `myB2'=`myB1'
			local i=`i' + 1
			local ll`i'=`ll'
			drop `p' `p0' `llt'
		}
		tempname I B N
		scalar `N' = `e(N)'
		mat `I' = e(V)
		mat `B' = e(b)
		ADJVar `wts' `touse' `I' 
        	tempvar sample
        	qui gen byte `sample' = e(sample)
      	 	qui est post  `B' `I', esample(`sample') noclear
		est scalar N = `N'
		est scalar ll_0 = `ll0'
		est scalar ll = `ll'
		est scalar df_m = `e(df_m)'
		est scalar chi2 = - 2*(`ll' - `ll0')
		est scalar r2_p = chiprob(e(df_m), - 2*(`ll' - `ll0'))

		est local wtype `"`weight'"'
		est local wexp	`"`exp'"'
		est local cmd "logitem"
		est local predict   "logite_p"
	}
	if `level'<10 | `level'>99 {
		local level 95
	}
	if `"`or'"'=="" {
		local or = "or"
		local eform = "eform(Odds Ratio)"
	}
 	di _n in gr "logistic regression when outcome is uncertain"
	if `noconv'==1 {
		di in blue "convergence not achieved" /*
 		*/ _col(51) in gr "Number of obs" _col(67) "= " /*
		*/ in ye %10.0g e(N)
 		local cfmt=cond(e(chi2)<1e+7,"%10.2f","%10.3e")
		di in gr "(stopped after `iterate' iterations)" /*
		*/ _col(51) in gr "`e(chi2type)' chi2(" in ye "`e(df_m)'" /*
		*/ in gr ")" _col(67) "= " in ye `cfmt' e(chi2)
	}	
	else {
 		di _col(51) in gr "Number of obs" _col(67) "= " /*
		*/ in ye %10.0g e(N)
 		local cfmt=cond(e(chi2)<1e+7,"%10.2f","%10.3e")
		di _col(51) in gr "`e(chi2type)' chi2(" in ye "`e(df_m)'" /*
		*/ in gr ")" _col(67) "= " in ye `cfmt' e(chi2)
	}
 	di in gr "Log likelihood = " in ye %10.0g e(ll) /*
	*/ _col(51) in gr "Prob > chi2" _col(67) "= " in ye %10.4f e(r2_p)
	est display, `eform' 
end
program def EXPstep, sclass
		args wts depvar touse sens spec
		tempvar y0 y1 yhat
		qui predict double `y1' if `touse', p
		qui gen double `y0'=1-`y1' if `touse'
		qui gen double /*
		*/ `yhat'=`y1'*`sens'/(`y1'*`sens' + `y0'*(1-`spec')) /*
		*/ if `touse' & `depvar'==1 
		qui replace `yhat'= /*
		*/ `y1'*(1-`sens')/(`y1'*(1-`sens') + `y0'*`spec') /*
		*/ if `touse' & `depvar'==0 
		qui replace `wts'=`yhat' if `touse'
end
prog def MAXstep, eclass 
	nobreak {
		syntax varlist [pweight iweight] [if], depvar(string)
		tempvar todrop wt 
		qui gen double `wt' `exp'
		local N=_N
		qui expand 2
		qui gen int `todrop'=cond(_n>`N',1,0)
		qui replace `depvar'=abs(`depvar'-1) if `todrop'
		qui replace `wt'=1-`wt' if `depvar'==0
		cap noi qui logit `varlist' `if' `in' [`weight'= `wt'], /*
				*/  nolog
		if _rc { 
			if _rc!=2000 & _rc!=2001 { exit _rc } 
			* if _rc==1 { exit 1 }
			logit `varlist' `if' `in' [`weight'`exp'], /*
				*/	`options' nocoef nolog
			/*NOTREACHED*/
			exit _rc
		}
		qui drop if `todrop'
	}
end
prog def ADJVar, eclass
	args wts touse I  
	tempvar p y d p0 t
	tempname B V XX
	qui predict double `p' if `touse' , p
	qui replace `p'=`p'*(1-`p') if `touse'
	qui gen double `y'=`wts'*(1-`wts') if `touse'	
	qui gen double `d'=`p'-`y' if `touse'	
	mat `V'=e(V)
	local col: colnames `V'
	local num: word count `col'
	tokenize `"`col'"'
	local `num' = ""
	local col  "`*'"
	qui mat accum  `XX'=`col' [iw=`d'] if `touse'
	qui mat `I'=syminv(`XX')
end
