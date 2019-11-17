*! Version 1.3.0  29jan2001 {([  STB-60 gr46
program define graphf, rclass sort
	version 7

	if "`e(cmd)'" == "" {
		error 301
	}

	syntax varlist(min=1) [, eq(str) cb(str) Level(int $S_level) * ]
	local graphopt `"`options'"'

	CBopt `cb'
	local cb `r(cb)'
	local nrep = r(nrep)

	tempname b V bc Vc s rnd R
	tempvar t touse vFx Fx lb ub

	gen byte `touse' = e(sample)
	mat `b' = e(b)
	mat `V' = e(V)

	* extract the varlist vareq of vars in equation eq

	local ceq : coleq `b'
	if "`eq'" != "" {
		local tmp : subinstr local ceq "`eq'" "", word all count(local nc)
		if `nc' == 0 {
			di as err "equation `eq' does not occur in the last model"
			exit 198
		}
	}
	else	local eq : word 1 of `ceq'
	if "`eq'" != "_" {
		local ineq " in `eq'"    /* used to label message */
	}
	local eq "`eq':"
	mat `bc' = `b'[1,"`eq'"]
	local vareq : colnames `bc'
	local vareq : subinstr local vareq "_cons" "", word all

	* verify/determine list of variables that form "the effect of x"

	gettoken x varlist : varlist
	local nf : word count `varlist'
	if `nf' == 0 {
		* determine varlist from b[eq]
		FunctOf "`x'" " `vareq'"
		local varlist `r(list)'
		local nf : word count `varlist'
		if `nf' == 0 {
			di as err "none of the indep variables`ineq' is a function of `x'"
			exit 498
		}
	}
	else {
		* check that specified variables are functions of x
		IsFunct "`x'" "`varlist'"
		ListDiff "`varlist'" "`vareq'"
		local varlist `r(common)'
		local nf : word count `varlist'
		if `nf' == 0 {
			di as err "none of the specified variables occurs in the model"
			exit 498
		}
		if "`r(diff)'" != "" {
			di as txt "dropped from specification: `r(diff)'"
		}
	}
	di as txt "function of `x'`ineq' : " as res "`varlist'"

	* =====================================================================
	* generate predictions Fx and vFx
	* =====================================================================

	quietly {
		* select one obs for each value of x, move these to front of data
		bys `x' (`touse') : replace `touse' = 0 if _n<_N & `touse'
		replace `touse' = -`touse'
		sort `touse' `x'
		count if `touse' == -1
		local Nx = r(N) /* number of distinct x-values */

		* compute Fx en vFx
		mat `bc' = J(1,`nf',0)
		mat `Vc' = J(`nf',`nf',0)
		gen `Fx' = 0
		label var `Fx' "F(`varlist')"
		gen `vFx' = 0 in 1/`Nx'
		tokenize `varlist'
		forv i = 1/`nf' {
			mat `bc'[1,`i'] = `b'[1, "`eq'``i''"]
			mat `Vc'[`i',`i'] = `V'["`eq'``i''", "`eq'``i''"]

			replace `Fx' = `Fx' + `bc'[1,`i']*``i''  in 1/`Nx'
			replace `vFx' = `vFx' + `Vc'[`i',`i']*(``i'')^2  in 1/`Nx'

			local imin1 = `i'-1
			forv j = 1/`imin1' {
				mat `Vc'[`i',`j'] = `V'["`eq'``i''", "`eq'``j''"]
				mat `Vc'[`j',`i'] = `V'["`eq'``j''", "`eq'``i''"]
				replace `vFx' = /*
				   */ `vFx' + 2*`Vc'[`i',`j']*(``i'')*(``j'') in 1/`Nx'
			}
		}
	} /* quietly */

	* =====================================================================
	* Graph with appropriate confidence band
	* =====================================================================

	if `level' < 10 | `level' > 99 {
		local level 99
	}
	*if `nf' == 1 & "`cb'" != "none" {
	*	di as txt "confidence band is not shown"
	*	local cb none
	*}
	local xn = abbrev("`x'",16)

	if "`cb'" == "none" {
		graph `Fx' `x' in 1/`Nx', twoway `graphopt' c(s) s(.) bor /*
		 */ t1(Total effect of `xn')
	}

	else if "`cb'" == "value" {        /* value-wise confidence band */
		scalar `s' = invnorm(.5 + `level'/200)
		qui gen `lb' = `Fx' - `s'*sqrt(`vFx') in 1/`Nx'
		qui gen `ub' = `Fx' + `s'*sqrt(`vFx') in 1/`Nx'

		graph `lb' `Fx' `ub' `x' in 1/`Nx', /*
		 */ twoway `graphopt' c(sss) s(i.i) border pen(232) /*
		 */ t1(Total effect of `xn' with `level'% value-wise confidence band)
	}

	else if "`cb'" == "envelope" {      /* envelope confidence band */
		mat `R' = cholesky(`Vc')
		mat `rnd' = J(1,`nf',0)
		qui gen `lb' = `Fx' in 1/`Nx'
		qui gen `ub' = `Fx' in 1/`Nx'
		* note that varlist is still tokenized
		forv i = 1/19 {
			forv j = 1/`nf' {
				mat `rnd'[1,`j'] = invnorm(uniform())
			}
			mat `rnd' = `bc' + `rnd' * `R''
			qui gen `t' = 0 in 1/`Nx'
			forv j = 1/`nf' {
				qui replace `t' = `t' + `rnd'[1,`j']*``j'' in 1/`Nx'
			}
			qui replace `lb' = min(`lb', `t') in 1/`Nx'
			qui replace `ub' = max(`ub', `t') in 1/`Nx'
			drop `t'
		}
		graph `lb' `Fx' `ub' `x' in 1/`Nx', /*
		 */ twoway `graphopt' c(sss) s(i.i) border pen(232) /*
		 */ t1(Total effect of `xn' with 95% Ripley confidence band)
	}

	else if "`cb'" == "bs" {           /* bootstrapped confidence band */
		quietly {
			* ensure that _N = max(nrep,Nx)
			if _N < max(`nrep',`Nx') {
				local Norg = _N
				expand =max(`nrep',`Nx')-_N+1  in l
				tempvar extraobs
				gen byte `extraobs' = _n > `Norg'
			}

			* put nrep drawings from (bc,Vc) in vars B`varlist
			tokenize `varlist'
			forv i = 1/`nf' {
				tempvar U`i'
				gen `U`i'' = invnorm(uniform())
				local Uvars `Uvars' `U`i''
			}
			mat `R' = cholesky(`Vc')
			forv i = 1/`nf' {
				tempvar B`i'
				gen `B`i'' = `bc'[1,`i']
				forv j = 1/`nf' {
					replace `B`i'' = `B`i'' + `R'[`i',`j'] * `U`j''
				}
			}
			drop `Uvars'

			* for selected x-values :
			*   (1) create bootstrap sample
			*   (2) store bootstrap statistics in (ub,lb)
			gen `t' = 0 in 1/`nrep'
			gen `lb' = .
			gen `ub' = .
			forv i = 1/`Nx' {
				replace `t' = 0
				forv j = 1/`nf' {
					replace `t' = `t' + `B`j'' * ``j''[`i'] in 1/`nrep'
				}
				* compute bias-corrected CI
				BSstat `t' `Fx'[`i'] `nrep' `level'
				replace `lb' = r(lb) in `i'
				replace `ub' = r(ub) in `i'
			}
			if "`extraobs'" != "" {
				drop if `extraobs'
			}
		}
		graph `lb' `Fx' `ub' `x' , /*
		 */ twoway `graphopt' c(sss) s(i.i) bor pen(232) /*
		 */ t1(Total effect of `xn' with `level'% bc/bs confidence band)
	}

	else {
		di as err "graphf: this should not happen"
		exit 9999
	}
end

* ===========================================================================
* subroutines
* ===========================================================================

/* FunctOf varname varlist
   returns in r(list) the vars in varlist that are a function of varname,
   i.e., vars that are constant given the value of varname, or, in other
   words,  vars[i] != vars[j] ==> varname[i] != varname[j]
*/
program define FunctOf, rclass
	args x list

	foreach v of local list {
		capt bys `x' : assert `v' == `v'[1] if e(sample)
		if !_rc {
			local fncfx "`fncfx' `v'"
		}
	}
	return local list `fncfx'
end


/* IsFunct varname varlist
   verifies that the vars in varlist are a function of varname.
*/
program define IsFunct
	args x varlist

	foreach v of local varlist {
		capt bys `x' : assert `v' == `v'[1] if e(sample)
		if _rc {
			di as err "`v' is not a function of `x'"
			exit 198
		}
	}
end


/* ListDiff list1 list2
   returns in r(common) [r(diff)] the words in list1 that occur
   [not occur] in list2.
*/
program define ListDiff, rclass
	args list1 list2

	foreach v of local list1 {
		local tmp : subinstr local list2 "`v'" "", word all count(local nc)
		if `nc' > 0 {
			local common `common' `v'
		}
		else	local diff `diff' `v'
	}
	return local common `common'
	return local diff   `diff'
end


/* CBopt
*/
program define CBopt, rclass
	args opt nr

	if "`opt'" == "" {
		return local cb none
		exit
	}

	local lopt = length("`opt'")
	if "`opt'" == substr("none",1,`lopt') {
		return local cb none
	}
	else if "`opt'" == substr("value",1,`lopt') {
		return local cb value
	}
	else if "`opt'" == substr("envelope",1,`lopt') {
		return local cb envelope
	}
	else if "`opt'" == "bs" {
		return local cb bs
		if `"`nr'"' == "" {
			return scalar nrep = 1000
		}
		else {
			confirm integer number `nr'
			return scalar nrep = `nr'
		}
	}
	else {
		di as err "graphf: invalid cb() option"
		exit 198
	}
end


/* copied and adapted from bstat : bias-corrected CIs
*/
program define BSstat, rclass
	args x obsx N level

	tempname bc1 bc2 eps z1 z2
	qui summarize `x' in 1/`N'
	local n = r(N)
	scalar `eps' = 1e-7 * max(sqrt(r(Var)), abs(`obsx'))
	qui count if `x' <= `obsx' + `eps' in 1/`N'
	if r(N) > 0 & r(N) < `n' {
		scalar `z1' = invnorm(r(N)/`n')
		scalar `z2' = invnorm((100 + `level')/200)

		local p1 = 100*normprob(2*`z1' - `z2')
		local p2 = 100*normprob(2*`z1' + `z2')

		_pctile `x' in 1/`N', p(`p1', `p2')

		ret scalar ub = r(r1)
		ret scalar lb = r(r2)
	}
end
exit
})]
