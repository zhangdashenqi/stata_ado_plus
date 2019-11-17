*! tspred -- predict for time series regressions        STB-24: sts7.6
*! version 1.1.0     Sean Becketti     February 1995
program define tspred
	version 3.1
	if "$S_E_cmd"!="tsfit" { error 301 }
	local varlist "req new max(1)"
	local if "opt pre"
	local in "opt pre"
	local options "Error(str) Normal Residual RMse(real 0)"
	local options "`options' SImulate Steps(str) Variance(real 0)"
	parse "`*'"
	quietly {  
	local type : type `varlist'
	drop `varlist'
	local ifsiml = "`simulat'"!="" | "`normal'"!="" | "`error'"!="" | `rmse'!=0 | `varianc'!=0
	if `ifsiml' & "`steps'"!="" { exit 198 }
	if "`steps'"=="" { local steps 0 }
	else {
		_subchar "," " " "`steps'" 
		parse "$S_1", parse(" ")
		local i "`*'"
		local nsteps : word count `i'
		local j 0
		while `j'<`nsteps' {
			local j = `j' + 1
			local step`j' ``j''
			if `step`j''<0 { exit 198 }
		}
		local steps `step`nsteps''
	}
/*
	Set up error vector for simulation.
*/
	if `ifsiml' {
		if "`error'"!="" & ("`normal'"!="" | `rmse'!=0 | `variance'!=0) { exit 198 }
		if `rmse' & `varianc' { exit 198 }
		if min(`rmse',`varianc')<0 { exit 198 }
		if "`error'"!="" { conf v `error' } /* user-supplied errors */
		else {
			local se = max(`rmse',sqrt(`varianc'))
			if `se'==0 { local se = S_E_rmse }
			tempvar error
			gen double `error' = `se' * invnorm(uniform()) `if' `in'
		}
		local simerr "+ `error'"
	}

/*
	Initialize the prediction with the actual.
*/
	tempvar yhat
	local j = 0
	while `j'<`steps' {
		local j = `j' + 1
		tempvar yhat`j'
	}
/*
	Figure out what the first and last observations in the forecast are.
*/
	tempvar touse
	mark `touse' `if' `in'
	_partset "$S_E_depv $S_E_x0" "$S_E_vl"
	markout `touse' $S_3
	_crcnuse `touse'
	local first $S_3
        if $S_E_nx0 > 0 {
                local v : word $S_E_nx0 of $S_E_x0
                _opnum `v'
		local l : word 2 of $S_2
	        replace `touse' = 0 if _n < max(`first',1+`l')
	        _crcnuse `touse'
        }
	if $S_2 { /* there are gaps in the prediction range */
		noi di in re "there are missing observations in the prediction range"
		exit 198
	}
	local N $S_1
	local first $S_3
	local last $S_4
	local in "in `first'/`last'"
	local notin "(_n<`first') | (_n>`last')"
/*
	Construct macros that contain the appropriate inner product of the 
	coefficients on the lagged y's with either the lagged y's or
	forecasts of the "lagged" y's.

	For an ordinary forecast (fixed terminal date of history), we have

	yhat[t] = a0 + a1 yhat[t-1] + a2 yhat[t-2] + ... + ap yhat[t-p]

	
	For a k-step ahead forecast (moving terminal date of history), we have

	yhat[t|t-k] = a + a1 yhat[t-1|t-k] + ... a{k-1} yhat[t-k+1|t-k]

		      + ak y[t-k] + ... + ap y[t-p]
*/
	parse "$S_E_vl", parse(" ")
	local plus	/* no leading plus sign */
	local i = 0
	while `i'<$S_E_nx0 {
		local i = `i' + 1
                local bname : word `i' of $S_E_x0
                local b = _coef[`bname']
		local ii = `i' + 1
		local v "``ii''"
		local ylag "`ylag'`plus'((`b')*`v')"
/*
	Determine lag.  No error checking.  We depend on tsfit to work.
*/
		_opnum `v'
		local l : word 2 of $S_2
		local yvar `yhat'
		local yhlag "`yhlag'`plus'((`b')*`yvar'[_n-`l'])"
		local j 0
		while `j'<`steps' {
			local j = `j' + 1
			local k = `j'-`l'
			local yvar `v'
			if `k'>0 { local yvar "`yhat`k''[_n-`l']" }
			local yhlag`j' "`yhlag`j''`plus'((`b')*`yvar')"
		}
		local plus +	/* Now we need the plus */
	}
/*
	Calculate the static prediction excluding the part depending on the
	lagged y's.  This code is captured because we temporarily change
	the stored estimates.
*/
	capture {
		tempvar K
		if $S_E_nx0 == $S_E_K { generate `type' `K' = 0 `in' }
		else {
			tempname model b V
			mat def `b' = get(_b)
			mat def `V' = get(VCE)
			local j = $S_E_nx0 + 1
			mat def `b' = `b'[1,`j'...]
			mat def `V' = `V'[`j'...,`j'...]
			est h `model'
			mat post `b' `V'
			predict `type' `K' `in'
			est u `model'
		}
	}
/*
	The 1-step-ahead prediction is just the static prediction.
*/
 	if `steps'>0 { predict `type' `yhat1' `in' }
/* 
	Now calculate the part of the fit that depends on lags of y.
*/
	gen `type' `yhat' = $S_E_depv
	if "`ylag'"!="" {	/* There are lagged dependent variables */
/*
	Obsolete.  This line was used to remove static forecasts of lagged
	y's in the initial version of tspred, before we matrix posted the 
	submodel.	SRB 2/8/95

		replace `K' = `K' - (`ylag') `simerr'
*/
		replace `yhat' = `K' + (`yhlag') `in'
		local j 1
		while `j'<`steps' {
			local j = `j' + 1
			gen `type' `yhat`j'' = .
			replace `yhat`j'' = `K' + (`yhlag`j'') `in'
		}
	}
	else { 		/* This is a static regression */
		drop `yhat'
		rename `K' `yhat'
		local j 1
		while `j'<`steps' {
			local j = `j' + 1
			gen `type' `yhat`j'' = `yhat'
		}
	}
	if ("`residua'"!="") {				/* Residuals  */
		replace `yhat' = $S_E_depv - `yhat'
		local j 0
		while `j'<`steps' {
			local j = `j' + 1
			replace `yhat`j'' = $S_E_depv - `yhat`j''
		}
	}
	if `steps'==0 { 
		rename `yhat' `varlist' 
		replace `varlist' = . if `notin'
	}
	else if `steps'==1 { 
		rename `yhat1' `varlist' 
		replace `varlist' = . if `notin'
	}
	else {
		local i 0
		local k = cond(`nsteps'>1,`nsteps',`steps')
		while `i'<`k' {
			local i = `i' + 1
			local j `i'
			if (`nsteps'>1) { local j `step`i'' }
			replace `yhat`j'' = . if `notin'
			if `j'==1 { rename `yhat1' P.`varlist' }
			else rename `yhat`j'' P`j'.`varlist'

		}
	}
	}  /* quietly */
end
