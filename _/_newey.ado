*! version 1.0.0  30oct1996  STB-39 sg72
program define _newey
	version 5.0
	local varlist	"req min(3) max(3)"
	local weight	"aweight nopre"
	local options	"T(string) LAG(integer -1) FORCE"
	parse "`*'"
	
	tempname vo vr b

	mat `vo' = get(VCE)
	mat `b'  = get(_b)

	quietly {
		preserve
		parse "`varlist'", parse(" ")
		local grad  "`1'"
		local wt    "`2'"
		local touse "`3'"

		local indv : colnames(`b')
		local n : word count `indv'

		tempvar xb e
		predict double `xb', index
		predict double `e'
		local depv "$S_E_depv"
		
		if "$X_cmd" != "poisson" {
			replace `e' = (`depv' - `e')/sqrt(`wt')
		}
		else {
			if "$S_E_off" != "" {
				local arg "+ln($S_E_off)"
			}
			replace `e' = (`depv' - /*
				*/ exp(`e'`arg'))/sqrt(`wt')
		}
		

		local xlist
		local i 1
		while `i' < `n' {
			local x : word `i' of `indv'
			local xlist "`xlist' `x'"
			replace `x' = `x'*`grad'/sqrt(`wt')
			local i = `i'+1
		}
		local np = `n'
		tempvar xcons
		local x : word `n' of `indv'
		if "`x'"=="_cons" {
			gen double `xcons' = `grad'/sqrt(`wt')
			local `n' "`xcons'"
			local np = `np'-1
		}
		else    gen double `xcons' = `x'*`grad'/sqrt(`wt')
		local xlist "`xlist' `xcons'"

		tempvar wvar
		if "`exp'"=="" {
			gen byte `wvar'=1
			local weight "fweight"
			local wtexp "[`weight'=`wvar']"
		}
		else {
			gen double `wvar' = `exp'
			local wtexp "[`weight'=`wvar']"
		}

		if `lag' > 0 {
			xt_tis `t'
			local tvar "$S_1"
		}
		else {
			tempvar tvar
			gen long `tvar' = _n
		}

		checkt `tvar' `touse'
		count if `touse'
		global X_nobs = _result(1)
		global X_tdf = $X_nobs - `n'
		if $S_1==1 & `lag' > 0 & "`force'" == "" {
			noi di in red /*
	*/ "`tvar' is not regularly spaced -- use the force option to override"
			exit 198
		}

		summ `wvar' if `touse'
		if "`weight'" == "aweight" {
			replace `wvar' = `wvar'/_result(3) if `touse'
		}


		tempvar vt1 vt2
		gen double `vt1' = .
		gen double `vt2' = .
		tempname xtx tt tx s1 tp tx2 tt2 xtix tp2 tx3 xtiy tt3

		if "`weight'"=="aweight" {
			local ow "`wvar'"
		}
		else {
			local ow 1
		}

		local nx = `n'
		local xv "`xlist'"
		local j 0
		while `j' <= `lag' {
			capture mat drop `tt'
			capture mat drop `tt2'
			capture mat drop `tt3'
			local i 1
			while `i' <= `nx' {
				local x : word `i' of `xv'
				replace `vt1' = `x'[_n-`j']*`e'* /*
				*/ `e'[_n-`j']*`wvar'[_n-`j']* /*
				*/ `ow' if `touse'
				mat vecaccum `tx' = `vt1' `xv' /*
				*/ if `touse', nocons
				mat `tt' = `tt' \ `tx'

				local i = `i'+1
			}
			mat `tp' = `tt''
			mat `tt' = `tt' +  `tp'
			scalar `s1' = (1-`j'/(1+`lag'))
			mat `tt' = `tt' * `s1'
			if `j' > 0 {
				mat `xtx' = `xtx' + `tt'
			}
			else {
				scalar `s1' = 0.5
				mat `xtx' = `tt' * `s1'
			}
			local j = `j'+1
		}
		tempname xtxi v
		mat accum `xtxi' = `xv' if `touse' /*
			*/ `wtexp', nocons
		mat `xtxi' = syminv(`xtxi')
		mat `v' = `xtxi'*`xtx'
		mat `v' = `v'*`xtxi'
		if "$X_cmd" == "regress" {
			local factor = $X_nobs/$X_tdf
			local dofarg "dof($X_tdf)"
		}
		else    local factor = 1
		mat `v' = `v'*`factor'

		mat colnames `v' = `indv'
		mat rownames `v' = `indv'

		restore

		mat post `b' `v', `dofarg' obs($X_nobs) /*
		*/ depname(`depv')
		if `lag' == 0 {
			global S_E_vce "Robust"
		}
		else    global S_E_vce "Newey-West"
		
	}
end
	
	
program define checkt
        local tvar  "`1'"
        local touse "`2'"

        replace `touse'=. if `touse'==0
        global S_1 = 0
        sort `touse' `tvar'
        tempvar tt
        gen `tt' = `tvar'-`tvar'[_n-1] if `touse'!=.
        summ `tt'
        if _result(5) != _result(6) {
                global S_1 = 1
        }
        replace `touse'=0 if `touse'==.
        sort `touse' `tvar'
end

