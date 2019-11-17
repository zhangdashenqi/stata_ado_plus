*! Version 1.1.0  Marcelo Moreira and Brian Poi  (SJ3-1: st0033)
* Estimated IV regression by 2sls or liml
* Created 20020811 by Brian Poi
* Modified 20030312 by Brian Poi
* Changelog at end of file
* syntax depvar exog (endog = instruments) [if] [in], 
*  [nocons noinstcons liml 2sls level(integer 95)]

program define condivreg, eclass

	version 7.0

	if replay() {
		if "`e(cmd)'" ~= "condivreg" {
			error 301
		}
		myprint
		exit
	}
 
	/* First get the list of variables.	*/
	/* The following chunk of code was ruthlessly stolen from ivreg.ado. */
	local n 0
	gettoken lhs 0 : 0, parse(" ,[") match(paren)
	IsStop `lhs'
	if `s(stop)' { error 198 }
	while `s(stop)'==0 {
		if "`paren'"=="(" {
			local n = `n' + 1
			gettoken p lhs : lhs, parse(" =")
			while "`p'"!="=" {
				local end`n' `end`n'' `p'
				gettoken p lhs : lhs, parse(" =")
			}
			tsunab end`n' : `end`n''
			tsunab rinst : `lhs'
			}
		else {
			local exog `exog' `lhs'
		}
		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
	}
	local 0 `"`lhs' `0'"'

	tsunab exog : `exog'
	tokenize `exog'
	local ry1 "`1'"
	local 1 " "
	local rexog `*'
	loc ry2 "`end1'"
	syntax [if] [in], [nocons noinstcons liml 2sls level(integer $S_level)]

	marksample touse
	markout `touse' `ry1' `ry2' `rexog' `rinst'
	
        _rmdcoll `ry1' `rexog' if `touse', `cons'
        loc rexog `"`r(varlist)'"'	

	/* Some syntax checking.	*/
	if ("`liml'" ~= "" & "`2sls'" ~= "") {
		di as error "Only one of liml or 2sls is allowed."
		exit 198
	}
	if ("`liml'" ~= "") {
		local est_type "liml"
	}
	else {
		local est_type "2sls"
	}

	quietly{   
		/* Compute the 2sls and liml results.	*/
		tempname beta var rmse rss mss rsquared adjrsq fstat xpx
		if "`est_type'" == "2sls" {
			my2sls `ry1' `ry2' "`rexog'" "`rinst'" "`cons'" /*
				*/ "`instcons'" `touse'  
		}
		else {
			myliml `ry1' `ry2' "`rexog'" "`rinst'" "`cons'" /*
				*/ "`instcons'" `touse'
		}
		mat `beta' = r(beta)
		mat `var' = r(var)
		if "`instcons'" == "" {
				mat colnames `beta' = `ry2' `rexog' _cons
			mat rownames `var' = `ry2' `rexog' _cons
			mat colnames `var' = `ry2' `rexog' _cons
		}
		else {
			mat colnames `beta' = `ry2' `rexog'
			mat rownames `var' = `ry2' `rexog'
			mat colnames `var' = `ry2' `rexog'
		}
		sca `rss' = r(rss)
		/* Compute the general stuff that goes along. */
		tempvar junk
		gen double `junk' = `ry1'^2 if `touse'
		su `junk', meanonly
		loc capn = r(N)
		sca `mss' = r(sum) - `rss'
		if ("`cons'" == "") {
			su `ry1' if `touse', meanonly
			sca `mss' = `mss' - r(sum)^2 / `capn'
		}
		loc dfm : word count `rexog' `ry2'
		loc dfr = `capn' - `dfm'
		if ("`cons'" == "") {
			loc c = 1
			loc dfr = `dfr' - 1
		}
		else {
			loc c = 0
		}
		sca `rmse' = sqrt(`rss'/`dfr')
		sca `rsquared' = `mss' / (`mss' + `rss')
		sca `adjrsq' = 1 - (1-`rsquared')*(`capn'-`c')/ /*
				*/ (`capn'-`c'-`dfm')
		/* F statistic for 2SLS/Wald for LIML. */
		if "`cons'" ~= "" {
			sca `fstat' = .
		}
		else {
			tempname c dif vinv
			mat `c' = J(1, (`dfm' + 1), 0)
			su `ry1' if `touse', meanonly
			mat `c'[1, (`dfm'+1)] = r(mean) 
			mat `dif' = `beta' - `c'
			mat `vinv' = inv(`var')
			mat `fstat' = `dif'*`vinv'*`dif''
			sca `fstat' = trace(`fstat')
			if "`est_type'" == "2sls" {
				sca `fstat' = `fstat' / `dfm'
			}
		}
		/* Get the first-stage stats.	*/
		tempname f1 r21 r2_a1 df_m1 df_r1
		if "`instcons'" == "" {
			reg `ry2' `rexog' `rinst'
		}
		else {
			reg `ry2' `rexog' `rinst', nocons
		}
		sca `f1' = e(F)
		sca `r21' = e(r2)
		sca `r2_a1' = e(r2_a)
		sca `df_m1' = e(df_m)
		sca `df_r1' = e(df_r)

		/* Post results.  Use two different syntaxes of 2sls and liml
		   so that we get t-stat for 2sls and z-stat for liml.     */
		if "`est_type'" == "2sls" {
			est post `beta' `var', esample(`touse') /*
				*/ depname("`ry1'") obs(`capn') dof(`dfr')
		}
		else {
			est post `beta' `var', esample(`touse') /*
				*/ depname("`ry1'") obs(`capn')
		} 
		est local depvar "`ry1'"
		est scalar df_m = `dfm'
		est scalar df_r = `dfr'
		if "`est_type'" == "2sls" {
			est scalar F = `fstat'
		}
		else {
			est scalar wald = `fstat'
		}
		est scalar r2 = `rsquared'
		est scalar r2_a = `adjrsq'
		est scalar rmse = `rmse'
		est scalar mss = `mss'
		est scalar rss = `rss'
		est scalar F_first = `f1'
		est scalar df_m_first = `df_m1'
		est scalar df_r_first = `df_r1'
		est scalar r2_first = `r21'
		est scalar r2_a_first = `r2_a1'
		est local exog "`rexog'"
		est local inst "`rinst'"
		est local insts "`rexog' `rinst'"
		est local instd "`ry2'"
		if "`est_type'" == "2sls" {
			est local model "2sls"
		}
		else {
			est local model "liml"
		}
		if "`instcons'" == "" {
			est local instcons "yes"
		}
		else {
			est local instcons "no"
		}
		if "`cons'" == "" {
			est local cons "yes"
		}
		else {
			est local cons "no"
		}
		est local cmd "condivreg"

	} /* End of quietly block.	*/

	myprint

end

prog def mat_inv_sqrt

	args in out
	tempname v vpri lam srlam

	loc k = rowsof(`in')
	mat symeigen `v' `lam' = `in'
	mat `vpri' = `v''
	/* Get sqrt(lam)     */
	mat `srlam' = diag(`lam')
	forv i = 1/`k' {
		mat `srlam'[`i', `i'] = 1/sqrt(`srlam'[`i', `i'])
	}
	mat `out' = `v'*`srlam'*`vpri'

end

program define my2sls, rclass

	args ry1 ry2 rexog rinst cons instcons touse

	quietly {
		tempname b2sls var2sls rss rssold
		tempvar y2hat
		if "`instcons'" == "" {
			reg `ry2' `rexog' `rinst' if `touse'
		}
		else {
			reg `ry2' `rexog' `rinst' if `touse', noconstant
		}
		predict double `y2hat' if `touse', xb
		reg `ry1' `y2hat' `rexog' if `touse', `cons'
		mat `b2sls' = e(b)
		mat `var2sls' = e(V)
		sca `rssold' = e(rss)
		tempvar resids hat
		replace `y2hat' = `ry2'
		predict double `resids' if `touse', residuals
		replace `resids' = `resids'^2
		su `resids', meanonly
		sca `rss' = r(sum)
		mat `var2sls' = `var2sls'*`rss'/`rssold'
		return scalar rss = `rss'
		return matrix beta `b2sls'
		return matrix var `var2sls'
	}

end

program define myliml, rclass

	args ry1 ry2 rexog rinst cons instcons touse

	quietly {
		/* LIML estimator.	*/
		/* Follows Davidson and MacKinnon (1993).	*/
		tempvar one
		gen double `one' = 1
		if "`instcons'" == "" {
			loc x2 `rinst' `one'
		}
		else {
			loc x2 `rinst'
		}
		if "`cons'" == "" {
			loc x1 `rexog' `one'
		}
		else {
			loc x1 `rexog'
		}

		tempname xpx x1px1 x1py1 y1py1
		mat accum `xpx' = `ry2' `x1' if `touse', noconstant
		mat `y1py1' = `xpx'[1, 1]

		/* Compute Y1'MxY1.	*/
		tempname y1mxy1
		loc k4 : word count "`ry2'"
		if `k4' ~= 1 {
			di as error /*
		 */ "Multiple endogenous RHS variables not implemented."
			exit 198
		}
		/* May be two ones here, but reg will catch it. */
		reg `ry2' `x1' `x2' if `touse', noconstant 
		tempvar y2resid
		predict double `y2resid' if `touse', residuals
		replace `y2resid' = `y2resid'^2
		summ `y2resid', meanonly
		sca `y1mxy1' = r(sum)

		/* Compute kappa.	*/
		/* First get Y'MxY.	*/
		tempvar y1h y2h y1hy2h
		tempname s11 s12 s22 ymxy ym1y
		reg `ry1' `x1' `x2' if `touse', noconstant
		predict double `y1h' if `touse', residuals
		reg `ry2' `x1' `x2' if `touse', noconstant
		predict double `y2h' if `touse', residuals
		gen double `y1hy2h' = `y1h'*`y2h' if `touse'
		replace `y1h' = `y1h'^2
		replace `y2h' = `y2h'^2
		summ `y1hy2h' if `touse', meanonly
		scalar `s12' = r(sum)
		summ `y1h' if `touse', meanonly
		scalar `s11' = r(sum)
		summ `y2h' if `touse', meanonly
		scalar `s22' = r(sum)
		mat `ymxy' = J(2,2,0)
		mat `ymxy'[1, 1] = `s11'
		mat `ymxy'[1, 2] = `s12'
		mat `ymxy'[2, 1] = `s12'
		mat `ymxy'[2, 2] = `s22'

		/* And Y'M1Y.	*/
		tempvar y1hh y2hh y1hhy2hh
		reg `ry1' `x1' if `touse', noconstant
		predict double `y1hh' if `touse', residuals
		reg `ry2' `x1' if `touse', noconstant
		predict double `y2hh' if `touse', residuals
		gen double `y1hhy2hh' = `y1hh'*`y2hh' if `touse'
		replace `y1hh' = `y1hh'^2
		replace `y2hh' = `y2hh'^2
		summ `y1hhy2hh' if `touse', meanonly
		scalar `s12' = r(sum)
		summ `y1hh' if `touse', meanonly
		scalar `s11' = r(sum)
		summ `y2hh' if `touse', meanonly
		scalar `s22' = r(sum)
		mat `ym1y' = J(2,2,0)
		mat `ym1y'[1, 1] = `s11'
		mat `ym1y'[1, 2] = `s12'
		mat `ym1y'[2, 1] = `s12'
		mat `ym1y'[2, 2] = `s22'

		/* Now form the matrix to get kappa from. */
		tempname ymxyih kmat vals vecs kappa
		mat_inv_sqrt `ymxy' `ymxyih'
		mat `kmat' = `ymxyih'*`ym1y'*`ymxyih'
		mat symeigen `vecs' `vals' = `kmat'
		loc junk = colsof(`vals')
		scalar `kappa' = `vals'[1, `junk'] 

		/* Now assemble the "X'X" matrix.	*/
		tempname xpxi xpy xpy1 xpy2 bliml varliml rss sighatsq
		mat `xpx'[1, 1] = `y1py1' - `kappa'*`y1mxy1'
		mat `xpxi' = syminv(`xpx')
		/* And the "X'y" matrix.	*/
		mat accum `xpy1' = `ry2' `ry1' if `touse', noconstant
		mat `xpy1' = `xpy1'[1, 2]
		mat `xpy1' = `xpy1' - `kappa'*`ymxy'[1, 2]
		mat accum `xpy2' = `x1' `ry1' if `touse', noconstant
		loc k1 : word count `x1'
		loc k2 = `k1' + 1
		mat `xpy2' = `xpy2'[1..`k1', `k2'...]
		mat `xpy' = `xpy1' \ `xpy2'
		mat `bliml' = (`xpxi'*`xpy')'

		/* Now compute sigma_squared to get the covariance matrix. */
		tempvar linpred residsq
		mat score `linpred' = `bliml' if `touse'
		gen double `residsq' = (`ry1' - `linpred')^2 if `touse'
		su `residsq' if `touse', meanonly
		sca `rss' = r(sum)
		sca `sighatsq' = r(sum) / r(N)
		mat `varliml' = `xpxi' * `sighatsq'

		return matrix beta `bliml'
		return matrix var `varliml'
		return scalar rss = `rss'
	}

end   

prog def myprint

	di
	if "`e(model)'" == "2sls" {
		di as text "Instrumental variables (2SLS) regression"
	}
	else {
		di as text "Instrumental variables (LIML) regression"
	}
	di
	di as text "First-stage results" _col(56) "Number of obs =" /*
		*/ as result %8.0f `e(N)'
	if "`e(model)'" == "2sls" {
		di as text "{hline 23}" _col(56) "F(" %3.0f `e(df_m)' "," /*
			*/ %6.0f `e(df_r)' ") =" as result %8.2f `e(F)'
		di as text "F(" %3.0f `e(df_m_first)' "," %6.0f /*
			*/ `e(df_r_first)' ") =" as result %8.2f /*
			*/ `e(F_first)' _col(56) as text /*
			*/ "Prob > F      =" as result %8.4f /*
			*/ Ftail(`e(df_m)', `e(df_r)', `e(F)')
	}
	else {
		di as text "{hline 23}" _col(56) "Wald chi2(" %2.0f /*
			*/ `e(df_m)' ") =" as result %8.2f `e(wald)'
		di as text "F(" %3.0f `e(df_m_first)' "," %6.0f /*
			*/ `e(df_r_first)' ") =" as result %8.2f /*
			*/ `e(F_first)' _col(56) as text "Prob > w      =" /* 
			*/ as result %8.4f chi2tail(`e(df_m)', `e(wald)')
	}   
	di as text "Prob > F      =" as result %8.4f /*
		*/ Ftail(`e(df_m_first)', `e(df_r_first)', `e(F_first)') /*
		*/ _col(56) as text "R-squared     =" as result %8.4f `e(r2)'
	di as text "R-squared     =" as result %8.4f `e(r2_first)' /*
		*/ _col(56) as text "Adj R-squared =" as result %8.4f `e(r2_a)'
	di as text "Adj R-squared =" as result %8.4f `e(r2_a_first)' /*
		*/ _col(56) as text "Root MSE      =" as result %8.3f `e(rmse)' 
	di
	est display
	di as text "Instrumented:  " _c
	Disp `e(instd)'
	di as text "Instruments:   " _c
	if "`e(instcons)'" == "yes" {
		Disp `e(insts)'
	}
	else {
		Disp `e(insts)' (No constant included)
	}
	di as text "{hline 78}"
	di as text "For hypothesis testing and confidence regions for"
	di as text "the parameter on " "`e(instd)'" /*
		*/ " use {cmd:condtest} and {cmd:condgraph}."   
	di as text "{hline 78}"

end

/* Lifted straight out of ivreg.ado.	*/
program define IsStop, sclass

	/* sic, must do tests one-at-a-time, * 0, may be very large */
	if `"`0'"' == "[" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else  sret local stop 0

end

/* More code borrowed from ivreg.ado.	*/
/* Changed -di in gr- to -di as text-.	*/
program define Disp

	local first ""
	local piece : piece 1 64 of `"`0'"'
	local i 1
	while "`piece'" != "" {
		di in gr "`first'`piece'"
		local first "               "
		local i = `i' + 1
		local piece : piece `i' 64 of `"`0'"'
	}
	if `i'==1 { di }
	
end

* Changelog:  20030312 : User noted I'm not handling collinear variables
*                        correctly.  Now I call _rmdcoll with depvar and
*                        exogenous vars.
