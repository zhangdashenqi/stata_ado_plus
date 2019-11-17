*! version 1.0  18dec2001    (SJ2-3: st0017)
/* by Florian Heiss: heiss@econ.uni-maannheim.de */
/* based on nlogit, version 7.0.7 */

program define nlogitrum_p, sort
	version 7
	
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

	local k = e(levels)
	forvalues i = 1/`k' {
        	local myopts `myopts' p`i' condp`i' iv`i' 
	}
	local myopts `myopts' pb xb condpb ivb

                /* Step 2:
                        call _pred_se, exit if done,
                        else collect what was returned.
                */

        _pred_se `"`myopts'"' `0'
        if `s(done)' { exit }
        local vtyp `s(typ)'
        local varn `s(varn)'
        local 0 `"`s(rest)'"'

                /* Step 3:
                        Parse your syntax.
                */

	syntax [if] [in] [, `myopts']

                /* Step 4:
                        Concatenate switch options together
                */

	forvalues i = 1/`k' {
			local args `args'`p`i''`condp`i''`iv`i'' 
	}
	local args `args'`pb'`xb'`condpb'`ivb'
		/* Step 5:
                        quickly process default case if you can
                        Do not forget -nooffset- option.
                */

					/* calculation */
	marksample touse
	ChkDta `e(level`k')' `e(group)' `touse'

					/* main eqs */
	tempvar beta
	_predict double `beta' if `touse', equation(#1)



					/* taus */
	tempname b
	mat `b' = e(b)
*	local j = `k' + 1
	local j = 2
	local t = `k' - 1
	forvalues i = 1/`t' {
		tempvar tau`i'
		qui gen double `tau`i'' = 0 
		local a = `k' - `i' 
		qui tab `e(level`a')'
		local r = r(r)
		forvalues x = 1/`r' {
			qui replace `tau`i'' = [#`j']_b[_cons]  /*
			*/ if `e(level`a')' == `x'
			local j = `j' + 1
		} 	
	}
	local bylist`k' `e(group)'
	local i = `k' - 1
	while `i' > 0 {
		local j = `i' + 1
		local l = `k' - `i'
		local bylist`i' `bylist`j'' `e(level`l')'
		local i = `i' -1
	}


	tempvar tau`k'
	qui gen `tau`k'' = 1

						/* level 1 */
	tempvar I1 P1
	qui bysort `bylist1': gen double `I1' = sum(exp(`beta'/`tau1'))
	qui by `bylist1': replace `I1' = `I1'[_N]
	qui gen double `P1' = exp(`beta'/`tau1')/`I1'
	qui replace `I1' = ln(`I1')
  						/* rest levels */
	local i 2 
	while `i' <= `k' {
		tempvar I`i' P`i'
		local j = `i' - 1
		qui gen double `P`i'' = exp(`tau`j'' / `tau`i'' * `I`j'')
		tempvar tmp
		qui gen double `tmp' = 0
		qui bysort `bylist`j'' : replace `tmp' = `P`i'' if _n == 1 
		qui by `bylist`i'': gen double `I`i'' = sum(`tmp')	
		qui by `bylist`i'' : replace `I`i'' = `I`i''[_N]
		qui replace `P`i'' = `P`i''/`I`i''	
		qui replace `I`i'' = ln(`I`i'')
		local i = `i' + 1
	}


	if `"`args'"' == "" | (`"`args'"' == "`pb'") | `"`args'"' == "`p`k''" {
		if `"`args'"' == "" {
			di as txt "(option pb assumed; Pr(`e(level`k')'))
		}
		qui gen `vtyp' `varn' = 1 if `touse'
		forvalues i = 1/`k' {
			qui replace `varn' = `varn'*`P`i'' if `touse'
		}	
		label var `varn' "Pr(`e(depvar)')"
	}
	else {
		forvalues i = 2/`k' {
			local l = `k' - `i' + 1
			if `"`args'"' == "`p`l''" {
				qui gen `vtyp' `varn' = 1 if `touse'
				forvalues j = `i'/`k' {
				qui replace `varn'= `varn'*`P`j'' if `touse' 
				}
				label var `varn' "Pr(`e(level`l')')"
			}
		}

		if `"`args'"' == "`xb'"  {
			qui gen `vtyp' `varn' = `beta' if `touse'
			label var `varn' /*
			*/"linear prediction"
		}
		if `"`args'"' == "`condp`k''" | `"`args'"' == "`condpb'" {
			qui gen `vtyp' `varn' = `P1' if `touse'
			label var `varn' /*
			*/ "Pr(bottom alternative | alternative is available after all earlier choices)"
		}
		if `"`args'"' == "`iv`k''" | `"`args'"' == "`ivb'" {
			qui gen `vtyp' `varn' = `I1' if `touse'
			label var `varn' /*
			*/ "inclusive value for the bottom-level alternatives"
		}
		forvalues i = 2/`k' {
			local l = `k' - `i' + 1
			if `"`args'"' == "`condp`l''" {
				qui gen `vtyp' `varn' = `P`i'' if `touse'
				if `l' == 1 {
					label var `varn' /*
					*/"Pr(each first-level alternative)"
				}
				else label var `varn' /*
				*/ "Pr(level `l' alternative | alternative is available after earlier choices)"
			}
			if `"`args'"' == "`iv`l''" {
				if `i' == `k' { 
					dis as err "invalid option"
					exit 198
				}
				qui gen `vtyp' `varn' = `I`i'' if `touse'
				label var `varn' /*
			*/ "inclusive value for the level `l' alternatives"
			}
		}
	}
end 

program define ChkDta
        args dep group touse
        qui tab `dep' if `touse'
        local r  r(r)
        tempvar junk
        qui bysort `group': gen `junk' = _N
        cap by `group': assert `junk'[1] == `r' if `touse'
        if _rc {
                dis as err "unbalanced data"
                exit 459
        }
end

