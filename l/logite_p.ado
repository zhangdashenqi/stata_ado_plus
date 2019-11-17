*! version 6.0.0  02sep1998
program define logite_p
	version 6

		/* Step 1:
			place command-unique options in local myopts
			Note that standard options are
			LR:
				Index XB Cooksd Hat 
				REsiduals RSTAndard RSTUdent
				STDF STDP STDR noOFFset
			SE:
				Index XB STDP noOFFset
		*/
	local myopts /*
	*/ "DBeta DEviance DX2 DDeviance Hat Number Pr Residuals RStandard"


		/* Step 2:
			call _propts, exit if done, 
			else collect what was returned.
		*/
	_pred_se "`myopts'" `0'
	if `s(done)' { exit }
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'


		/* Step 3:
			Parse your syntax.
		*/
	syntax [if] [in] [, `myopts' noOFFset]


		/* Step 4:
			Concatenate switch options together
		*/
	local type /*
	*/"`dbeta'`devianc'`dx2'`ddevian'`hat'`number'`pr'`residua'`rstanda'"
	/*         1234567       1234567       123456      1234567  1234567*/

		/* Step 5:
			quickly process default case if you can 
			Do not forget -nooffset- option.
		*/
	if "`type'"=="" | "`type'"=="pr" {
		if "`type'"=="" {
			di in gr "(option p assumed; Pr(`e(depvar)'))"
		}
		_predict `vtyp' `varn' `if' `in', `offset'
		qui replace `varn'=exp(`varn')/(1+exp(`varn'))
		label var `varn' "Pr(`e(depvar)')"
		exit
	}


		/* Step 6:
			mark sample (this is not e(sample)).
		*/
	marksample touse


		/* Step 7:
			handle options that take argument one at a time.
			Comment if restricted to e(sample).
			Be careful in coding that number of missing values
			created is shown.
			Do all intermediate calculations in double.
		*/


		/* Step 8:
			handle switch options that can be used in-sample or 
			out-of-sample one at a time.
			Be careful in coding that number of missing values
			created is shown.
			Do all intermediate calculations in double.
		*/

		/* Step 9:
			handle switch options that can be used in-sample only.
			Same comments as for step 8.
		*/
	qui replace `touse'=0 if !e(sample)

	if "`type'"=="rstandard" {
		tempvar resid hat
		qui predict double `resid' if `touse', resid `offset'
		qui predict double `hat' if `touse', hat `offset'
		gen `vtyp' `varn' = `resid'/sqrt(1-`hat') if `touse'
		label var `varn' "standardized Pearson residual"
		exit
	}
	
	if "`type'"=="dbeta" {
		tempvar resid hat 
		qui predict double `resid' if `touse', resid `offset'
		qui predict double `hat' if `touse', hat `offset'
		gen `vtyp' `varn' = `resid'^2*`hat'/(1-`hat')^2
		label var `varn' "Pregibon's dbeta"
		exit
	}

	if "`type'"=="dx2" {
		tempvar rstd
		qui predict double `rstd' if `touse', rstandard `offset'
		gen `vtyp' `varn' = `rstd'^2
		label var `varn' "H-L dX^2"
		exit
	}

	if "`type'"=="ddeviance" {
		tempvar dev hat 
		qui predict double `dev', deviance `offset'
		qui predict double `hat', hat `offset'
		gen `vtyp' `varn' = `dev'^2/(1-`hat')
		label var `varn' "H-L dD"
		exit
	}


		/* 
			For the remaining cases, we need the model 
			variables
		*/
	
	GetRhs rhs

		/*
			below we distinguish carefully between e(sample) 
			and `touse' because e(sample) may be a superset 
			of `touse'
		*/
	tempvar keep
	qui gen byte `keep' = e(sample)
	sort `keep' `rhs'

	if "`type'"=="number" { 
		tempvar n
		qui {
			by `keep' `rhs': gen long `n' = 1 if _n==1 & `keep'
			replace `n' = sum(`n')
		}
		gen `vtyp' `varn' = `n' if `n'>0 & `touse'
		label var `varn' "covariate pattern"
		exit
	}

		/*
			remaining types require we know the weights, 
			if any.
		*/
	* if `"`e(wtype)'"' != "" {
	*	if `"`e(wtype)'"' != "fweight" {
	*		di in red `"not possible with `e(wtype)'s"'
			di in red `"not possible"'
			exit 135
	*	}
		tempvar w
		qui {
			gen double `w' `e(wexp)'
			compress `w'
		}
		local lab "weighted "
	}
	else	local w 1

		/*
			remaining types require we know 
				p = probability of success
				m = # in covariate pattern
				y = # of successes within covariate pattern
		*/
	tempvar p m y
	quietly {
		_predict double `p' if `keep', `offset'
		qui replace `p'=exp(`p')/(1+exp(`p'))
		by `keep' `rhs': gen long `m'=cond(_n==_N,sum(`w'),.)
		by `keep' `rhs': gen long `y'=cond(_n==_N, /*
			*/ sum((`e(depvar)'!=0 & `e(depvar)'!=.)*`w'), .)
	}

	if "`type'"=="deviance" {
		tempvar s
		quietly {
			gen double `s' = sqrt(				/*
				*/ 2*(					/*
				*/ `y'*ln(`y'/(`m'*`p')) + 		/*
				*/ (`m'-`y')*ln((`m'-`y')/(`m'*(1-`p')))/*
				*/ )					/*
				*/ )
			replace `s'=-`s' if `y'-`m'*`p'<0
			replace `s'=-sqrt(2*`m'*abs(ln(1-`p'))) if `y'==0
			replace `s'= sqrt(2*`m'*abs(ln(`p'))) if `y'==`m'
			by `keep' `rhs': replace `s' = cond(`keep',`s'[_N],.)
		}
		gen `vtyp' `varn' = `s' if `touse'
		label var `varn' `"`lab'deviance residual"'
		exit
	}

	if "`type'"=="hat" {
		tempvar s
		quietly {
			_predict double `s' if `keep', stdp `offset'
			qui replace `s'=exp(`s')/(1+exp(`s'))
			replace `s' = `m'*`p'*(1-`p')*`s'*`s' if `keep'
			by `keep' `rhs': replace `s' = cond(`keep',`s'[_N],.)
		}
		gen `vtyp' `varn' = `s' if `touse'
		label var `varn' `"`lab'leverage"'
		exit
	}

	if "`type'"=="residuals" {
		tempvar s
		quietly {
			gen double `s' = (`y'-`m'*`p')/sqrt(`m'*`p'*(1-`p'))
			by `keep' `rhs': replace `s' = cond(`keep',`s'[_N],.)
		}
		gen `vtyp' `varn' = `s' if `touse'
		label var `varn' `"`lab'Pearson residual"'
		exit
	}

			/* Step 10.
				Issue r(198), syntax error.
				The user specified more than one option
			*/
	error 198
end


program define GetRhs /* name */ 
	args where
	tempname b 
	mat `b' = get(_b)
	local rhs : colnames `b'
	mat drop `b'
	local n : word count `rhs'
	tokenize `rhs'
	if "``n''"=="_cons" {
		local `n'
	}
	c_local `where' "`*'"
end
exit
