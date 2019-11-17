*! version 1.0  18dec2001    (SJ2-3: st0017)
/* by Florian Heiss: heiss@econ.uni-maannheim.de */
/* based on nlogit, version 7.0.7 */

program define nlogitdn, eclass sort 
* dummy nests

							/* BEGIN parse */
	gettoken dep 0 : 0, parse(" (")	/* dependent variable (0,1) */ 
	unab dep : `dep'
	confirm variable `dep'
	tempvar dep1
	qui gen `dep1' = `dep'	
	qui replace `dep1' = 1 if `dep1' != 0
	qui tab `dep1'
	if r(r) != 2 {
		dis as err "outcome does not vary in any group"
		exit 2000
	}
	gettoken first rest : 0, match(par) parse(" [,")
	global nlog_iv 0
	local k = 0
	while "`par'" == "(" {
		local k = `k' + 1
		gettoken level`k' second : first, parse(" =")
		confirm var `level`k''
		unab level`k' : `level`k''
		gettoken eq left : second, parse(" =")
		if "`eq'" == "=" {
			local second `left'
		}
		local 0 `second' 
		syntax varlist 
		local ind`k' `varlist'
		local inds `inds' `ind`k''	/* full independent variables */
		local levels `levels' `level`k''
		local 0 `rest'
		gettoken first rest : 0, match(par) parse(" [,")
	}
	syntax [if] [in] [fw iw], group(passthru) [noTRee noLABel CLOgit   /*
		*/ Level(passthru) MLOpts(passthru) noLOg  Robust  d1	   /*
		*/ IVConstraints(string) CONSTraints(string)		  /* 
		*/ technique(passthru) * ] 

						/* END parse */

	capture drop _pnl_* _pv_*
	local ps_const 500
	local modeldesc 
	local i 1 
	display _newline 
	while `i' < `k'{	/*loop over levels */
		local modeldesc `modeldesc' (`level`i''=`ind`i'')
		local upper = `i' + 1
		qui tab `level`i'' `level`upper'', matcell(freqs)
		local nnest = r(r)
		local nivp = r(c)
		/* generate nests */
		display as txt "generating " `nivp'-1 " dummy-level(s) with " `nnest' " nests each below `level`upper''"
		forvalues l = 1/`nnest' {local civp`l' 1} 
		local j 1 
		while `j' < `nivp' {	      /*loop over nests in level i+1*/
			local thislevel _pnl_`i'_`j'
			local thisx _pv_`i'_`j'
			egen `thislevel' = group(`level`i'')
			gen `thisx' = ( `thislevel' == 1 )
			constraint define `ps_const' `thisx' = 0
			if "`constraints'" ~= "" {local constraints `constraints', }
			local constraints `constraints' `ps_const'
			local ps_const = `ps_const' + 1
			local l 1 
			local labels  
			while `l' <= `nnest' {	      /*loop over nests in level i*/
				local thislabel _pn`i'`j'`l'
				local labels `labels' `l' `thislabel'
				if freqs[`l',`j'] > 0 {local civp`l' = `civp`l'' + 1}
				local thiseq : label (`level`upper'') `civp`l''
				if "`ivconstraints'" ~= "" {local ivconstraints `ivconstraints', }
				local ivconstraints `ivconstraints' `thislabel' = `thiseq'
				local civp`l' = `civp`l'' + 1
				local l = `l' + 1
			}
			capture label drop _lb`thislevel'
			label define _lb`thislevel' `labels'
			label values `thislevel' _lb`thislevel'
			local modeldesc `modeldesc' (`thislevel'=`thisx')
			local j = `j' + 1
		}
		local i = `i' + 1
	}
	local modeldesc `modeldesc' (`level`k''=`ind`k'')

nlogit `dep' `modeldesc' `if' `in' `fw' `iw', `group' `tree' `label' `clogit' `Level' `mlopts' `noLOg' `Robust' `d1' ivc(`ivconstraints') const(`constraints') `technique'

end
