*! chow -- Chow test for stability of regression coefficients
*! version 1.0.0     Sean Becketti     November 1993

cap program drop chow
program define chow
version 6
quietly {
	local varlist "req ex"
	local if "opt pre"
	local in "opt pre"
	local weight "aweight fweight"
	local options "noCOnstant CHow(str) CUrrent(str) Detail Exclude(str) Lags(str)"
        local options "`options' Preserve REGress REStrict(str) noSAmple Static(str)"
        local options "`options' Time(str) Vartest"
	parse "`*'"
/*
	Handle the time series options.
*/
        if "`sample'"!="" { local ifsmpl 0 }
        else { local ifsmpl 1 }
	if ("`current'"!="") {
		_parsevl `current'
		local current "$S_1"
		local c "current(`current')"
	}
	if ("`lags'"!="") {
		local l "lags(`lags')"
		parse "`lags'", parse(" ,")
	}
	if ("`static'"!="") {
		_parsevl `static'
		local static "$S_1"
		local s "static(`static')"
	}
	if "`regress'"!="" { 
		local regress 1
		local noi "noisily"
	}
	else { local regress 0 }
        if "`time'"!="" {
                tempvar t
                gen long `t' = 0
                cap conf n `time'
                if !_rc {
                        if `time'==0 { 
				local tfac "log(`t')" 
				local tlab "log(t)"
			}
			else if `time'==1 { 
				local tfac "`t'" 
				local tlab t
			}
			else if `time'==-1 { 
				local tfac "(1/`t')" 
				local tlab "(1/t)" 
			}
			else if `time'<0 { 
				local p = abs(`time')
				local tfac "(1/(`t'^`p'))"
				local tlab "(1/(t^`p'))"
			}
			else { 
				local tfac "(`t'^`time')" 
				local tlab "(t^`time')" 
			}
                }
                else {
                        _inlist "`time'" "exp ln log"
                        if $S_1==2 { 
				local tfac "log(`t')" 
				local tlab "log(t)" 
			}
                        else if $S_1 { 
				local tfac "`time'(`t')" 
				local tlab "`time'(`t')" 
			}
                        else {
                                di in re "illegal option: time(`time')"
                                exit 98
                        }
		}
                local time 1
        }
        else { local time 0 }
/*
	Run the pooled regression to create any needed lags.  Store
	the restricted SER.  Process the "if" and "in" conditions.
*/
	if "`preserv'"!="" { preserve }
	tsfit `varlist' `if' `in' `weight', `constan' `c' `l' `s' nosample
        local K "$S_E_K"
	local depv "$S_E_depv"
	parse "$S_E_vl", parse(" ")
	mac shift
	local rhsvars "`*'"
	local rrmse $S_E_rmse
	tempvar touse
	mark `touse' `if' `in'
	markout `touse' $S_E_vl
        _crcnuse `touse'
        local T $S_1
        local gaps $S_2
        local in "in $S_3/$S_4"
        local if
        if `gaps' { 
                local if "if `touse'" 
                local addif "& `touse'"
        }
/*
	Divide the variables into restricted variables (rvars) 
	and unrestricted variables (uvars).
*/
        local uvars "`rhsvars'"
	if "`restric'"!="" {
		_parsevl `restric'
		local rin "$S_1"
                local restric
                while "`rin'"!="" {
			parse "`rin'", parse(" ")
                        local r `1'
                        mac shift
                        local rin "`*'"
                        _inlist "`r'" "`varlist'"
                        local i $S_1
                        if `i' {
	                        _ts_pars `varlist', `c' `l' `s'
                                local j = 4 + `i'
                                local rout "${S_`j'}"
                        }
                        _inlist "`r'" "`current' `static'"
                        if $S_1 { local rout "`r' `rout'" }
                        local restric "`restric' `rout'"
                }
		_partset "`restric'" "`rhsvars'"
		local rvars "$S_1 $S_2"
		local uvars "$S_3"
	}
	local nuvars : word count `uvars'
/*
	Parse the excluded variables in preparation for compiling the 
	test lists.
*/
	if "`exclude'"!="" {
		_parsevl `exclude'
		local exin "$S_1"
                local exclude
                while "`exin'"!="" {
			parse "`exin'", parse(" ")
                        local x `1'
                        mac shift
                        local exin "`*'"
                        _inlist "`x'" "`varlist'"
                        local i $S_1
                        if `i' {
	                        _ts_pars `varlist', `c' `l' `s'
                                local j = 4 + `i'
                                local exout "${S_`j'}"
                        }
                        _inlist "`x'" "`current' `static'"
                        if $S_1 { local exout "`x' `exout'" }
                        local exclude "`exclude' `exout'"
                }
	}
/*
	Parse the Chow conditions.  "Zi" is the dummy variable for the 
        i-th Chow condition.  "Zij" is the interaction of Zi and the j-th
        unrestricted variable.
*/
	if "`chow'"=="" {
		di in re "No subsamples specified"
		exit 98
	}
	parse "`chow'", parse(",")
	local i 0
	while "`1'"!="" {
		if "`1'"!="," {
			local i = `i' + 1
			if `i'==1 { local z0 "`1'" }
			else if `i'==2 { local z0 "(`z0') | (`1')" }
			else { local z0 "`z0' | (`1')" }
			local z`i' "`1'"	/* the i-th condition */
			tempvar Z`i'    
			gen byte `Z`i'' = `1'
			lab var `Z`i'' "Z`i': =1, if `1'"
                        if `time' {
                                _crcnuse `Z`i''
                                replace `t' = cond(_n<$S_3,0,_n-${S_3}+1) `in'
				drop `Z`i''
                                gen double `Z`i'' = cond(`t',`tfac',0) `in'
                                lab var `Z`i'' "Z`i': = `tlab', if `1'"
                        }
			if "`constan'"=="" { local Z`i'v "`Z`i''" }
			local j 0
			while `j'<`nuvars' {
				local j = `j' + 1
				tempvar Z`i'`j'
				local v : word `j' of `uvars'
				local t : type `v'
				if `time' { local t double }
				gen `t' `Z`i'`j'' = `Z`i'' * `v'
				lab var `Z`i'`j'' "Z`i' * `v'"
				local Z`i'v "`Z`i'v' `Z`i'`j''"
				_inlist "`v'" "`exclude'"
				if !$S_1 {
					local tZ`i'v "`Z`i'v' `Z`i'`j''"
				}
			}
                        local Zvars "`Zvars' `Z`i'v'"
                        local tZvars "`tZvars' `tZ`i'v'"
		}
		mac shift
	}
	local Z0v "`Zvars'"
	local tZ0v "`tZvars'"
	tempvar Z0
	gen byte `Z0' = `z0'
	local nchow `i'
/*
        Run the Chow regression.
*/
        if `ifsmpl' { noi findsmpl `touse' }
        `noi' regress `depv' `rvars' `uvars' `Zvars' `if' `in' `weight', `constan'
	local urmse = _result(9)
	tempvar resid
	predict double `resid' `if' `in', resid
	local x = round(`rrmse',.0001)
        noi di _new in gr "RMSE of   restricted equation = " in ye = `x'
        if "`noi'"=="" { 
		local x = round(`urmse',.0001)
		noi di      in gr "RMSE of unrestricted equation = " in ye = `x'
	}
        else { 
                local i 0
                while `i'<`nchow' {
                        local i = `i' + 1
                        local vname "`Z`i''"
                        local lbl: var l `Z`i''
                        noi di _new in ye "`Z`i''" in gr ": " in ye "`lbl'" 
                        local j 0
                        while `j'<`nuvars' {
				local j = `j' + 1
				local vname "`Z`i'`j''"
				local lbl : var l `Z`i'`j''
				local lbl = "`lbl'"+substr("             ",1,13-length("`lbl'"))
                                if mod(`j',2) & `j'<`nuvars' { local cont "_continue" }
                                else { local cont }
                                noi di _skip(5) in ye "`Z`i'`j''" in gr ": " in ye "`lbl'" `cont'
                        }
                }
	}
/*
	Test the null Chow hypotheses.
*/
	local i -1
	local lim = cond(`nchow'>1 & ("`detail'"!=""),`nchow',0)
	while `i' < `lim' {
		local i = `i' + 1 
		test `tZ`i'v'
		local mdf`i' = _result(3)
		local rdf`i' = _result(5)
                local F`i' = _result(6)
		noi di _new in gr "H0: coefficients unchanged when " in ye "`z`i''"
                if `ifsmpl' { 
			findsmpl if (`z`i'') `addif' `in'
			noi di _skip(4) in gr "(" in ye "$S_1" in gr "-" in ye "$S_2" in gr ",  " in ye "$S_5" in gr " obs)"
		}
		local F = round(`F`i'',.01)
		local Fstr "F(`mdf`i'',`rdf`i'')"
		local skip = 8 - length("`Fstr")
		local p`i' = fprob(`mdf`i'',`rdf`i'',`F`i'')
		local p = round(`p`i'',.01)
		noi di _skip(`skip') in gr "`Fstr' = " in ye "`F'"
		noi di _skip(4) in gr "Prob > F = " in ye "`p'"
		if "`vartest'"!="" {
	                sum `resid' if ! (`z`i'') `addif' `in'
	                local T0 = _result(1)
	                local sd0 = sqrt(_result(4)*(`T0'-1)/(`T0'-`K'))
	                sum `resid' if (`z`i'') `addif' `in'
	                local T1 = _result(1)
	                local sd1 = sqrt(_result(4)*(`T1'-1)/(`T1'-`K'))
	                sdtesti `T0' . `sd0' `T1' . `sd1'
	                local prmse`i' = fprob($S_3, $S_5, $S_6)
	                local p = round(`prmse`i'',.01)
	                local rmse`i' `sd1'
			local x = round(`sd1',.0001)
	                noi di _new _skip(4) in gr "RMSE in subsample = " in ye "`x'"
			local x = round(`sd0',.0001)
	                noi di _skip(7) in gr "rest of sample = " in ye "`x'"
	                noi di _skip(14) in gr "P-value = " in ye "`p'"
		}
	}
        global S_1 `rrmse'
        global S_2 `urmse'
        local i -1
        while `i' < `lim' {
                local base = 2 + 6*`i'
                local i = `i' + 1
                local j = `base' + 1
                global S_`j' `mdf`i''
                local j = `j' + 1
                global S_`j' `rdf`i''
                local j = `j' + 1
                global S_`j' `F`i''
                local j = `j' + 1
                global S_`j' `p`i''
                local j = `j' + 1
                global S_`j' `rmse`i''
                local j = `j' + 1
                global S_`j' `prmse`i''
        }
}       /* end quietly */        
end
