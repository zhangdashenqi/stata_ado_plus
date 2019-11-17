*! cmp_ll 1.2.2 5 December 2007
*! David Roodman, Center for Global Development, Washington, DC, www.cgdev.org
*! Copyright David Roodman 2007. May be distributed free.

program define cmp_ll
	cap version 10  // unlike "version 9.2" this assures compatibility going forward without making cmp_lnf() think we're in 9.2 and avoid ghkfast().
	local num_scores = $cmp_d + $cmp_d * ($cmp_d + 1)/2
	forvalues l=1/`num_scores' {
		local scargs `scargs' sc`l'
	}
	args todo b lnf g negH `scargs'
	tempname t lnsig rc 
	tempvar theta
	tokenize $cmp_inds
	qui forvalues l=1/$cmp_d {
		mleval `theta' = `b', eq(`l')
		replace _cmp_e`l' = cond( ``l'' <= 2, ///
							${ML_y`l'} - `theta', ///        // continuous or left-censored
							cond(``l''==3, ///
								`theta' - ${ML_y`l'}, ///  // right-censored
								cond(${ML_y`l'}, ///
									`theta', ///    	   // probit, depvar <> 0
									-`theta' ///	   // probit, depvar =  0
								) ///
							) ///
						) if $ML_samp & ``l''
		drop `theta'
	}

	mat `lnsig' = J(1, $cmp_d, .)
	local l = $cmp_d
	forvalues j=1/$cmp_d {
		local ++l
		mleval `t' = `b', eq(`l') scalar
		mat `lnsig'[1, `j'] = `t'
	}

	if $cmp_d > 1 {
		tempname atanhrho
		mat `atanhrho' = J(1, $cmp_d*($cmp_d-1)/2, .)
		forvalues j=1/`=colsof(`atanhrho')' {
			local ++l
			mleval `t' = `b', eq(`l') scalar
			mat `atanhrho'[1,`j'] = `t'
		}
	}
	mata: st_numscalar(st_local("rc"), cmp_lnf("`lnsig'", "`atanhrho'"))
	if `rc' == . {
		scalar `lnf' = .
		exit
	}

	mlsum `lnf' = _cmp_lnfi
	if `todo' {
		tempname g_
		forvalues l=1/$cmp_d {
			mlvecsum `lnf' `t' = `sc`l'', eq(`l')
			mat `g_' = nullmat(`g_'), `t'
		}
		forvalues l=`=$cmp_d+1'/`num_scores' {
			mlsum `t' = `sc`l''
			mat `g_' = nullmat(`g_'), `t'
		}
		mat `g' = `g_'
	}
end
