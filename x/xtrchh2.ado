*!  version 2.0.0  01jul2003                         (SJ3-3:st0046)
program define xtrchh2, eclass byable(onecall)
        version 8.0
        if "`1'" == "" | "`1'" == "," {
                if "`e(cmd)'" != "xtrchh2" { 
			error 301 
		}
		if _by() { 
			error 190 
		}
                Display `0'
                exit
        }
	if _by() {
        	by `_byvars'`_byrc0': Estimate `0'
	}
        else {
        	Estimate `0'
        }
        
end

program define Estimate, eclass byable(recall) sortpreserve
        syntax [varlist] [if] [in] ///
                        [, I(varname) T(varname) noCONstant ///
			 OFFset(varname) Level(passthru) noBETAs] 
        xt_iis `i'
        local ivar "`s(ivar)'"

        xt_tis `t'
        local tvar "`s(tvar)'"


        if "`offset'" != "" {
                tempvar ovar
                confirm var `offset'
		local ostr "`offset'"
                gen double `ovar' = `offset'
                local oarg "offset(`ovar')"
        }

	// Parsing complete, mark sample now

	marksample touse
	markout `touse' `offset' `t' 
	markout `touse' `ivar', strok

        quietly {
		tokenize `varlist'
                local dep "`1'"
		local depname "`1'"
                mac shift
                local ind "`*'"
                noi _rmcoll `ind' if `touse', `constant'
                local ind "`r(varlist)'"
                local p : word count `ind'

		local rhs = `p'
		if "`constant'" == "" { 
			local rhs = `rhs'+1 
		}

                tempvar t T
                sort `touse' `ivar' 
                by `touse' `ivar': gen int `t' = _n if `touse'
                by `touse' `ivar': gen int `T' = _N if `touse'

		count if `touse' 
		local nobso = r(N)

		by `touse' `ivar' : replace `touse' = 0 if `T'[_N] <= `rhs'
		replace `T' = . if `touse'==0

		count if `touse' 
		local nobs = r(N)

		if `nobs' < `nobso' {
			noi di in blue "Note: " in ye  `nobso'-`nobs' /*
				*/ in bl " obs. dropped (panels too small)"
		}

		tempvar g  
		egen `g' = group(`ivar') if `touse'
		summ `g' if `touse'
		local ng = r(max)     

                summarize `T' if `touse' & `ivar'~=`ivar'[_n-1], meanonly
                local ng = r(N)
                local g1 = r(min)
                local g2 = r(mean)
                local g3 = r(max)

		if "`oarg'" != "" {
			replace `ovar' = `dep'-`ovar'
			local dep "`ovar'"
		}
		tempname xtx b1 v1 bbar sig1 tmp vs bt
		reg `dep' `ind' if `touse' & `g'==1, `constant'
		mat `b1' = get(_b)
		mat `v1' = get(VCE)
		mat `vs' = syminv(`v1')
		mat `bt' = `vs' * `b1' '
		mat `sig1' = `b1' ' * `b1' 
		mat `bbar' = `b1'
		local i = 2
		while `i' <= `ng' {
			tempname b`i' v`i' 
			reg `dep' `ind' if `touse' & `g'==`i', `constant'
			mat `b`i'' = get(_b)
			mat `bbar' = `bbar' + `b`i''
			mat `tmp' = `b`i'' ' * `b`i''
			mat `sig1' = `sig1' + `tmp'
			mat `v`i'' = get(VCE)
			mat `tmp' = syminv(`v`i'')
			mat `vs' = `vs' + `tmp'
			mat `tmp' = `tmp' * `b`i'' '
			mat `bt' = `bt' + `tmp'
			local i = `i' + 1
		}
		mat `vs' = syminv(`vs')
		mat `bt' = `vs' * `bt'
		local ngg = 1/`ng'
		mat `bbar' = `bbar' * `ngg'
		tempname sig sig2 
		mat `sig2' = `bbar' ' * `bbar'
		mat `sig2' = `sig2' * `ng'
		mat `sig' = `sig1' - `sig2'
		local ngg = 1/(`ng'-1)
		mat `sig' = `sig' * `ngg'

		tempname den w1 bm tmp2
		mat `w1' = `sig' + `v1'
		mat `w1' = syminv(`w1')
		mat `den' = `w1'
		mat `bt' = `bt' '
		mat `tmp' = `b1' - `bt'
		mat `tmp2' = syminv(`v1')
		mat `bm' = `tmp' * `tmp2'
		mat `bm' = `bm' * `tmp''
		local i 2
		while `i' <= `ng' {
			tempname w`i'
			mat `w`i'' = `sig' + `v`i''
			mat `w`i'' = syminv(`w`i'')
			mat `den' = `den' + `w`i'' 
			mat `tmp' = `b`i'' - `bt'
			mat `tmp2' = syminv(`v`i'')
			mat `tmp2' = `tmp' * `tmp2'
			mat `tmp2' = `tmp2' * `tmp''
			mat `bm' = `bm' + `tmp2'
			local i = `i'+1
		}
		local k = colsof(`b1')
		local chival = `bm'[1,1]
		local df = `k'*(`ng'-1)
		local chiprob = chiprob(`df',`chival')

		tempname vce
		mat `den' = syminv(`den')
		mat `vce' = `den'

		local i 1
		while `i' <= `ng' {
			mat `w`i'' = `den' * `w`i''
			local i = `i'+1
		}

		mat drop `den'
		tempname beta
		mat `beta' = `w1' * `b1' '
		local i 2
		while `i' <= `ng' {
			mat `den' = `w`i'' * `b`i'' '
			mat `beta' = `beta' + `den'
			local i = `i'+1
		}

                // Now get the panel-specific betas
		ByGroups `ivar' `touse'
		loc groups `"`r(groups)'"'
		
		loc i = 1
		foreach gp of local groups {
			tempname ols_`i' ols_v_`i'
			qui regress `dep' `ind' ///
				if `touse' & `ivar'==`gp', `constant'
			mat `ols_`i'' = e(b)
			mat `ols_v_`i'' = e(V)
			loc i = `i' + 1
		}
		tempname siginv
		mat `siginv' = inv(`sig')
		forvalues i = 1/`ng' {
			tempname v_`i'_inv beta_`i'
			mat `v_`i'_inv' = inv(`ols_v_`i'')
			mat `beta_`i'' = inv(`siginv' + `v_`i'_inv'')* ///
				(`siginv'*`beta' + `v_`i'_inv'*(`ols_`i'')')
		}
		// Assemble var[b_i]
		tempname amat iminusa
		forvalues i = 1/`ng' {
			tempname varb_`i'
			mat `amat' = inv(`siginv' + `v_`i'_inv')*`siginv'
			mat `iminusa' = I(`k') - `amat'
			mat `varb_`i'' = `vce' + ///
				`iminusa'*(`ols_v_`i'' - `vce')*`iminusa''
		}

		mat `beta' = `beta''
		eret post `beta' `vce', obs(`nobs') depname(`depname') ///
			esample(`touse')
		eret mat Sigma `sig'
		capture test `ind', min `constant'
		if _rc == 0 {
			eret scalar chi2 = r(chi2)
			eret scalar df_m = r(df)
		}
		else {    
			eret scalar df_m = 0
		}
		eret scalar g_min  = `g1'
		eret scalar g_avg  = `g2'
		eret scalar g_max  = `g3'
		eret scalar N_g = `ng'
		eret scalar chi2_c = `chival'
		eret scalar df_chi2c = `df'
		eret local title "Swamy random-coefficients regression"
		eret local chi2type "Wald"
		eret local offset "`ostr'"
		eret local depvar "`depvar'"
		eret local ivar "`ivar'"
		eret local tvar "`tvar'"
		eret local predict "xtrc2_p"
		eret local cmd "xtrchh2"
		// Now return the panel-specific betas and vars.
		tempname junkb junkv
		forvalues i = 1/`ng' {
			mat `junkb' = (`beta_`i'')'
			mat `junkv' = `varb_`i''
			eret mat beta_`i' `junkb'
			eret mat V_`i' `junkv'
		}
	}
	Display, `level' `betas'
end

program define Display
	syntax [, Level(int $S_level) nobetas]

	_crcphdr
	eret di, level(`level')
	di in gr "Test of parameter constancy:    " ///
		"chi2(" in ye e(df_chi2c) in gr ") = " ///
		in ye %8.2f e(chi2_c) ///
		in gr _col(59) "Prob > chi2 = " ///
		in ye %6.4f chiprob(e(df_chi2c),e(chi2_c))
	if ("`betas'" != "nobetas") {
		di
		di _col(25) "Group-specific coefficients"
		di as text "{hline 78}"
		di as text _col(21) ///
"Coef.   Std. Err.      z    P>|z|     [" `level' "% Conf. Interval]"
		di as text "{hline 78}"
		tempname se pval cv junkb junkv
		sca `cv' = invnorm(1 - ((100-`level')/100)/2)
		mat `junkb' = e(beta_1)
		loc names : colnames `junkb'
		loc coefs : word count `names'
		loc numgrps = e(N_g)
		forvalues i = 1/`numgrps' {
			di as text %12s "Group `i'" " {c |} "  
			di as text "{hline 13}+{hline 64}"
			mat `junkb' = e(beta_`i')
			mat `junkv' = e(V_`i')
			forvalues j = 1/`coefs' {
				loc col = 17
				loc name : word `j' of `names'
				di as text ///
%12s abbrev("`name'",12) " {c |}" as result _col(`col') %9.7g `junkb'[1,`j'] _c
				loc col = `col' + 11
				sca `se' = sqrt(`junkv'[`j', `j'])
				if (`se' > 0 & `se' < .) {
					di as res _col(`col') %9.7g `se' ///
						"   " _c
					di as result %6.2f ///
						`junkb'[1, `j']/`se' ///
						"   " _continue
					sca `pval' = ///
					2*(1 - norm(abs(`junkb'[1, `j']/`se')))
					di as result %5.3f `pval' "    " _c
					di as result ///
%9.7g (`junkb'[1,`j'] - `cv'*`se') "   " _continue
					di as result ///
%9.7g (`junkb'[1,`j'] + `cv'*`se') _continue  
					di
				}
				else {
					di as text _col(36) ///
".        .       .            .           ."
				}
			}
			if (`i' < `numgrps') {
				di as text "{hline 13}+{hline 64}"
			}
			else {
				di as text "{hline 78}"
			}
		}
	}

end


program define ByGroups, sortpreserve rclass

	version 8.0
	args var touse

	preserve
	qui keep if `touse'
	qui keep `var'
	sort `var'
	tempvar one
	by `var' : gen `one' = (_n==1)
	qui keep if `one' == 1
	local groups ""
	forvalues i = 1/`=_N' {
		local next = `var'[`i']
		local groups "`groups' `next'" 
	}
	restore
	return local groups `"`groups'"'

end

exit

