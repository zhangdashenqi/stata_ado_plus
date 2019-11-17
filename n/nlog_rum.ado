*! version 1.0  18dec2001   (SJ2-3: st0017)
/* by Florian Heiss: heiss@econ.uni-maannheim.de */
/* based on nlogit, version 7.0.7 */

program define nlog_rum
	version 7.0
	local i 1
	while `i' <= ($nlog_l + $nlog_t) {
		local clist `clist' c`i'
		local i = `i' + 1
	}
	args todo b lnf g negH `clist' 
						/* main eqs */

	tempvar beta 
	mleval `beta' = `b', eq(1)

						/* taus */
	local i 1
	local k = 2
	while `i' <= $nlog_l - 1 {
		tempvar tau`i'
		qui gen double `tau`i'' = 0 
		local j 1
		while `j' <= $nlog_T[1,`i'] {
			tempvar tau`i'`j' 
			mleval `tau`i'`j'' = `b', eq(`k') 
			local n = (`i'+1)*2
			qui replace `tau`i'' = `tau`i'`j'' /*
			*/ if  ${ML_y`n'} == `j'  
			local k = `k' + 1
			local j = `j' + 1
		}
		local i = `i' + 1
	}
	local bylist$nlog_l $nlog_id 
	local i =$nlog_l -1
	while `i' > 0 {
		local j = `i' + 1
		local n = `j' * 2
		local bylist`i' `bylist`j'' ${ML_y`n'}
		local i = `i' - 1
	}

	tempvar tau$nlog_l
	qui gen `tau$nlog_l' = 1

						/* level 1 */
	tempvar I1 p1
	qui bysort `bylist1': gen double `I1' = sum(exp(`beta'/`tau1'))
	qui by `bylist1': replace `I1' = `I1'[_N]
	qui gen double `p1' = exp(`beta'/`tau1')/`I1'
	qui replace `I1' = ln(`I1')
  						/* rest levels */
	local i 2 
	while `i' <= $nlog_l {
		tempvar I`i' p`i'
		local j = `i' - 1
		qui gen double `p`i'' = exp(`tau`j'' / `tau`i'' * `I`j'')
		tempvar tmp
		qui gen double `tmp' = 0
		qui bysort `bylist`j'' : replace `tmp' = `p`i'' if _n == 1 
		qui by `bylist`i'': gen double `I`i'' = sum(`tmp')	
		qui by `bylist`i'' : replace `I`i'' = `I`i''[_N]
		qui replace `p`i'' = `p`i''/`I`i''	
		qui replace `I`i'' = ln(`I`i'')
		local i = `i' + 1
	}

						/* ln(p) = sum(ln(p`i')) */
	local i 1
	tempvar lnp
	qui gen double `lnp' = 0
	while `i' <= $nlog_l {
		qui replace `lnp' = `lnp' + ln(`p`i'')  
		local i = `i' + 1
	}	
	qui replace `lnp' = 0 if $ML_y1 == 0
	
	mlsum `lnf' =  `lnp'
	if `todo' == 0 | `lnf' == . { exit }



end	

exit

