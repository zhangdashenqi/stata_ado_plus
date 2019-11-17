*!version 1.0.4  01may2006
program define tobcm, rclass

	version 7.0

	syntax , [Pbs bsfile(string) reps(integer 250)]

	if "`e(cmd)'" != "tobit" {
		di as err "tobcm only works after tobit"
		exit 198
	}	
	if e(llopt) != 0 | "`e(ulopt)'" != "" {
		di as err "tobcm only works with lower limit of zero "/*
			*/ "and no upper limit is specified"
		exit 198
	}	

	if "`e(version)'" == "" {
		local tobvers = 1
	}
	else {
		local tobvers = 2
	}

	if `"`bsfile'"' != "" {
		confirm new file `"`bsfile'.dta"'
	}
	
	tempvar touse q xb xbs ep lam bi ei m1 m2 
	tempvar one 

	tempname s b tob1
	tempname mpm ipm mpg gpg w cm cm_s pval

	qui gen byte `touse'    = (e(sample)==1)
	local depvar  "`e(depvar)'"

	qui predict double `xb' if `touse', xb
	qui gen double `ep' = `depvar' - `xb' if `touse'

	if `tobvers' < 2 {
		scalar `s' = _b[_se]
	}	
	else {
		scalar `s' = _b[sigma:_cons]
	}
	mat `b' = e(b)

	qui gen byte `q' = (`depvar' > 0) if `touse'
	qui gen double `xbs' = `xb'/`s' if `touse'


	qui gen double `lam' = normden(`xbs') / norm(-`xbs') if `touse'
	qui gen double `bi' = .5*`q'*(((`ep'/`s')^2-1)/`s'^2) /*
		*/ + .5*(1-`q')*`xb'*(`lam'/`s'^3) if `touse'
	qui gen double `ei' = (`q'*`ep' - (1-`q')*`s'*`lam')/`s'^2 if `touse'


/* Make Gradient Variables */

	if `tobvers' < 2 {
		local gvars : colnames `b'
		local cnt 1
	
		foreach var of local gvars {
			if "`var'" != "_cons" & "`var'" != "_se" {
				tempvar g`cnt' 
				qui gen double `g`cnt'' = `var'*`ei' if `touse'
			}
			else {
				if "`var'" == "_cons" {
					tempvar g`cnt' 
					qui gen double `g`cnt'' = `ei' if `touse'
				}
				if "`var'" == "_se" {
					tempvar g`cnt' 
					qui gen double `g`cnt'' = `bi' if `touse'
				}
			}

			local gvars2 "`gvars2' `g`cnt'' "
			local cnt = `cnt' + 1
		}
	}	
	else {
		local gvars : colnames `b'
		local geqs  : coleq `b'
		local cnt 1
	
		foreach var of local gvars {
			local eq : word `cnt' of `geqs'

			if "`var'" != "_cons" & "`eq'" != "sigma" {
				tempvar g`cnt' 
				qui gen double `g`cnt'' = `var'*`ei' if `touse'
			}
			else {
				if "`var'" == "_cons" & "`eq'" != "sigma" {
					tempvar g`cnt' 
					qui gen double `g`cnt'' = `ei' 	/*
						*/ if `touse'
				}
				if "`var'" == "_cons" & "`eq'" == "sigma" {
					tempvar g`cnt' 
					qui gen double `g`cnt'' = `bi'	/*
						*/ if `touse'
				}
			}

			local gvars2 "`gvars2' `g`cnt'' "
			local cnt = `cnt' + 1
		}
	}

	local cnt = `cnt' - 1

/* Make Moment variables */
	
	qui gen double `m1' = `q'*`ep'^3 - (1-`q')*(`s'^3)*`lam'*(2+`xbs'^2)
	qui gen double `m2' = `q'*(`ep'^4-3*`s'^4) + /*
		*/ (1-`q')*(`s'^4)*`lam'*`xbs'*(3+`xbs'^2)


	est hold `tob1', restore

	qui gen double `one' = 1

	qui reg `one' `m1' `m2' `gvars2' if `touse', nocons
	qui scalar `cm_s' = e(N) - e(rss)
	est unhold `tob1'
	
	scalar `pval' = chi2tail(2,`cm_s')
	
	if "`pbs'" != "" {
		if "`bsfile'" == "" {
			tempfile pfile 
		}
		else{
			local pfile `"`bsfile'"'
		}	
		tempname cmt yt pname cval10 cval5 cval1 orig b0 
		
		mat `b0' = e(b)

		est hold `orig', copy restore
		
		postfile `pname' cm using `pfile'
		forvalues r=1(1)`reps' {
			_tobsimdta `yt' if `touse', bmat(`b0') 		/*
				*/ tobvers(`tobvers')
			local xvars "`r(xvars)'"
			local ncon "`r(nocons)'"
			capture qui version 8.0: tobit `yt' `xvars' 	/*
				*/ if `touse' , ll(0) `ncon'
/* only _rc==0 are saved, this means that number of obs in bsfile can differ
 * from number of reps specified.  
 */
			if _rc == 0 {
				qui tobcm 
				qui post `pname' (r(cm))
			}	
			qui drop `yt'
		}
		postclose `pname'
		qui preserve
		qui use `pfile', clear
		qui sum cm, detail
		scalar `cval10' = r(p90)
		scalar `cval5' = r(p95)
		scalar `cval1' = r(p99)
		qui restore	
		est unhold `orig'



		di
		di as txt "Conditional moment test against the "/*
			*/ "null of normal errors"
		di
		di as txt "{col 20}critical values"
		di as txt "{col 5}CM{col 15}%10{col 25}%5{col 35}%1"
		di as res %9.5g `cm_s' "{col 13}" %6.5f `cval10' /*
			*/ _col(22) `cval5' _col(32) `cval1' 

		ret scalar cm = `cm_s'
		ret scalar cval10 = `cval10'
		ret scalar cval5 = `cval5'
		ret scalar cval1 = `cval1'
		ret scalar asympval = `pval'
		exit
	}


	ret scalar cm = `cm_s'
	ret scalar  p = `pval'

	di
	di as txt "Conditional moment test against the "/*
		*/ "null of normal errors"
	di
	di as txt "{col 5}CM{col 13}Prob > chi2"
	di as res %9.5g `cm_s' "{col 15}" %6.5f `pval'

end	
