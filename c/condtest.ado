*! Version 1.0   Marcelo Moreira and Brian Poi    (SJ3-1: st0033)
* Computes conditional LR tests as described in Moreira (2002)
* Created 20020811 by Brian Poi 
* Modified 20030107 by Brian Poi

* Usage: condtest , [beta(real 0) reps(integer 200) level(integer 95)]

program define condtest, rclass

	version 7.0

	if "`e(cmd)'" ~= "condivreg" {
		di as error "last estimates not found."
		exit 301
	}
	tempname results
	estimates hold `results', copy restore

	syntax [, Beta(real 0) reps(integer 200) level(integer 95)]

	if (`level' < 1 | `level' > 99) {
		di as error "level() must be an integer between 1 and 99."
		exit 198
	}
	if (`reps' < 1) {
		di as error "reps() must be a positive integer."
	}

	/* End of syntax checking.	*/

	quietly{
		tempname touse
		gen `touse' = e(sample)
		loc ry1 `e(depvar)'
		loc ry2 `e(instd)'
		/* Take care of constant term in main eq. if specified  */
		tempvar one
		gen `one' = 1
		if ("`e(cons)'" == "yes") {
			loc exog "`e(exog)' `one'"
		}
		else {
			loc exog "`e(exog)'"
		}
		loc instcons "`e(instcons)'"
		loc rinst "`e(inst)'"

		/* Regress raw y1, y2 on exog.	*/
		tempvar y1 y2
		if ("`exog'" ~= "") {
			foreach v in y1 y2 {
				reg `r`v'' `exog' if `touse', nocons
				predict double ``v'' if `touse', residuals
			}
		}
		else {
			gen double `y1' = `ry1' if `touse'
			gen double `y2' = `ry2' if `touse'
		}
		/* Regress instruments on exog.	*/
		loc inst = ""
		loc n = 1
		foreach v in `rinst' {
			tempvar inst`n'
			if ("`exog'" ~= "") {
				reg `v' `exog' if `touse', nocons
				predict double `inst`n'' if `touse', residuals
			}
			else {
				gen double `inst`n'' = `v' if `touse'
			}
			loc inst "`inst' `inst`n''"
		}
		/* Set up a and b vectors.	*/
		tempname a b aprime bprime
		mat `a' = (`beta'\1)
		mat `b' = (1\(-1*`beta'))
		mat `aprime' = `a''		/* Macro parser chokes 	*/
		mat `bprime' = `b''		/* otherwise.		*/

		/* Compute Omega.	*/
		tempname mzy1 mzy2 n k omega
		if "`instcons'" == "yes" {
			reg `y1' `inst' if `touse'
		}
		else {
			reg `y1' `inst' if `touse', nocons
		}
		predict `mzy1' if `touse', residuals
		if "`instcons'" == "yes" {
			reg `y2' `inst' if `touse'
		}
		else {
			reg `y2' `inst' if `touse', nocons
		}
		predict `mzy2' if `touse', residuals
		mat accum `omega' = `mzy1' `mzy2', noconstant
		count if `touse'
		loc n = r(N)
		loc k : word count `inst'
		if ("`instcons'" == "yes") {
			loc k = `k' + 1	
		}
		mat `omega' = `omega' / (`n'-`k')
		tempname oia
		mat `oia' = inv(`omega')*`a'
		/* Compute scalars b'*O*b and a'*O^-1*a	*/
		tempname bob aoia
		matrix `bob' = `bprime'*`omega'*`b'
		scalar `bob' = trace(`bob')
		matrix `aoia' = `aprime'*inv(`omega')*`a'
		scalar `aoia' = trace(`aoia')

		/* Compute sbar and tbar.	*/
		tempname cross zpz sqrtzpzi zpy sbar tbar
		if ("`instcons'" == "yes") {
			mat accum `cross' = `inst' `one' `y1' `y2' /*
				*/ if `touse', noconstant
		}
		else {
			mat accum `cross' = `inst' `y1' `y2' /*
				*/ if `touse', noconstant
		}
		mat `zpz' = `cross'[1..`k', 1..`k']
		mat `zpy' = `cross'[1..`k', (`k'+1)...]
		mat_inv_sqrt `zpz' `sqrtzpzi'
		mat `sbar' = `sqrtzpzi'*`zpy'*`b'/sqrt(`bob')
		mat `tbar' = `sqrtzpzi'*`zpy'*`oia'/sqrt(`aoia')

		/* Test statistics	*/
		tempname ar lm lr wald
		calcstat1 `sbar' `tbar' `ar' `lm'
		calcstat2 `sbar' `tbar' `aoia' `bob' `beta' `omega' `lr' `wald'
		return scalar ar = `ar'
		return scalar lm = `lm'
		return scalar lr = `lr'
		return scalar wald = `wald'

		/* Now we need to get critical values for LR and Wald.  */
		/* Under the null, sbar has a N(0, I(k)) distribution.  */
		preserve
		tempname random
		tempvar lrvals waldvals lrtmp waldtmp
		drop _all
		set obs `reps'
		matrix `random' = J(`k', 1, 0)
		gen double `lrvals' = 0
		gen double `waldvals' = 0
		forv i = 1/`reps' {
			/* Get a random vector for sbar.  */
			forv j = 1/`k' {
				mat `random'[`j', 1] = invnorm(uniform())
			}
			/* Compute LR and Wald statistics.	*/
			calcstat2 `random' `tbar' `aoia' `bob' `beta' /*
				*/ `omega' `lrtmp' `waldtmp'
			replace `lrvals' = `lrtmp' in `i'
			replace `waldvals' = `waldtmp' in `i'
		}
		tempname lrcrit waldcrit
		_pctile `lrvals', p(`level')
		scalar `lrcrit' = r(r1)
		return scalar lrcrit = `lrcrit'
		_pctile `waldvals', p(`level')
		scalar `waldcrit' = r(r1)
		return scalar waldcrit = `waldcrit'
		restore

		/* Do the critical values for AR stat.		*/
		/* This is just Chi-squared(#inst).		*/
		tempname arcv lmcv
		if "`instcons'" == "yes"{
			sca `arcv' = invchi2tail((`k'-1), (1-`level'/100))
		}
		else {
			sca `arcv' = invchi2tail(`k', (1-`level'/100))
		}
		return scalar arcrit = `arcv'

		/* Critical value for LM stat.			*/
		/* This is just Chi-squared(1).			*/
		sca `lmcv' = invchi2tail(1, (1-`level'/100))
		return scalar lmcrit = `lmcv'
		return scalar beta = `beta'
	}

	DispResults `beta' `ar' `arcv' `lr' `lrcrit' `lm' `lmcv' /*
		*/ `wald' `waldcrit' `level' "`ry2'" `reps'

end

/* Computes AR and LM statistics.	*/
prog def calcstat1

	args sbar tbar ar lm
	tempname sbarp tbarp

	mat `sbarp' = `sbar''
	mat `tbarp' = `tbar''   
	mat `ar' = `sbarp'*`sbar'
	sca `ar' = trace(`ar')
	mat `lm' = (trace(`sbarp'*`tbar')^2) / trace(`tbarp'*`tbar')
	sca `lm' = trace(`lm')

end 

/* Computes LR and Wald statistics.	*/
prog def calcstat2

	args sbar tbar aoia bob beta omega lr wald
	tempname sbarp tbarp

	mat `sbarp' = `sbar''
	mat `tbarp' = `tbar''      
	tempname ss st tt
	mat `ss' = `sbarp'*`sbar'
	sca `ss' = trace(`ss')
	mat `tt' = `tbarp'*`tbar'
	sca `tt' = trace(`tt')
	mat `st' = `sbarp'*`tbar'
	sca `st' = trace(`st')
	sca `lr' = 0.5*(`ss' - `tt' + sqrt((`ss' + `tt')^2 - /*
		*/ 4*(`ss'*`tt' - (`st')^2)))   
                       
	/* Wald is a fscking mess.   */
	tempname c d denom y2nzy2 y2nzy2i y2nzy1 middle num dp /*
		*/ b2sls b2slsp dif difp
	sca `denom' = (`omega'[1,1] - 2*`omega'[1,2]*`beta' + /*
		*/ `omega'[2,2]*`beta'^2)
	sca `num' = (`omega'[1,1]*`omega'[2,2] - `omega'[1,2]^2) 
	mat `c' = ( (`omega'[1,1] - `omega'[1,2]*`beta')/`denom' \ /*
		*/ `beta'*`num'/`denom' )
	mat `d' = ( (`omega'[1,2] - `omega'[2,2]*`beta')/`denom' \ /*
		*/ `num'/`denom')
	mat `dp' = `d''
	mat `middle' = ( `bob'*`sbarp'*`sbar', /*
		*/ (sqrt(`bob')*sqrt(`aoia')*`sbarp'*`tbar') \ /*
		*/ (sqrt(`bob')*sqrt(`aoia')*`sbarp'*`tbar'), /*
		*/ `aoia'*`tbarp'*`tbar' )
	mat `y2nzy2' = `dp'*`middle'*`d'
	mat `y2nzy1' = `dp'*`middle'*`c'
	mat `y2nzy2i' = inv(`y2nzy2')
	mat `b2sls' = (1 \ (-1*`y2nzy2i'*`y2nzy1'))
	mat `b2slsp' = `b2sls''
	mat `denom' = `b2slsp'*`omega'*`b2sls'
	sca `denom' = trace(`denom')
	sca `b2sls' = -1*`b2sls'[2, 1]
	sca `dif' = `b2sls' - `beta'
	mat `wald' = `dif'^2*`y2nzy2'/`denom'
	sca `wald' = trace(`wald')

end

prog def DispResults

	args beta ar arcrit lr lrcrit lm lmcrit wald waldcrit level bname reps

	di
	di as text "Size-adjusted tests based on"
	di as text "Moreira's (2002) conditional approach." 
	di
	di as text "H0: b[`bname'] = " as result  %-9.4f `beta'
	di
	di as text "Critical values based on " `reps' " simulations."
	di as text "{hline 78}"
	di as text "Statistic" _col(37) "Value" _col(53) `level' "% C.V." /*
		*/ _col(67) "Asy. C.V.*"
	di as text "{hline 78}"
	di as text "Anderson-Rubin" as result _col(30) %12.4f `ar' /*
		*/ _col(49) %12.4f `arcrit'      
	di as text "Likelihood Ratio" as result _col(30) %12.4f `lr' /*
		*/ _col(49) %12.4f `lrcrit' _col(65) %12.4f /*
		*/ invchi2tail(1, 1-`level'/100)
	di as text "Lagrange Multiplier (Score)" as result _col(30) /*
		*/ %12.4f `lm' _col(49) %12.4f `lmcrit'      
	di as text "Wald" as result _col(30) %12.4f `wald' _col(49) /*
		*/ %12.4f `waldcrit' _col(65) %12.4f /*
		*/ invchi2tail(1, 1-`level'/100)      
	di as text "{hline 78}"
	di as text /*
	  */ "*Asy. C.V. denotes the usual asymptotic chi-square-one critical"
	di as text /*
	  */ " values for the Wald and likelihood ratio test statistics." 
	di as text "{hline 78}"

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
