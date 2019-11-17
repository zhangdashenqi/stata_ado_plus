*! scenario -- generate a scenario                      STB-24: sts7.6
*! version 1.0     Sean Becketti     January 1995
program define scenario
quietly {
	version 3.1
	local varlist "req ex min(1)"
	local options "ACtion(str) AMount(str) Begin(str) Length(str)"
	parse "`*'"
	if !_N {
		di in re "scenario: no observations"
		exit 98
	}
        if "`begin'"=="" { 
		projdate
		local begin "$S_1"
	}
	date2obs `begin'
        local begin $S_1
        if (!`begin') { 
        	di in re "scenario: no projection date"
                exit 98
        }
        if (`begin'<1) | (`begin'>_N) {
                di in re "scenario: illegal projection date=`begin'"
                exit 98
        }
/*
        Parse scenario.  A scenario is a program for filling in the
        variable during the projection period.  Each instruction in the
        program is a triple: an action, an amount, and a length.
        The possible actions are:
                
                flat    -- leave the variable unchanged
                grow    -- change the variable a specified amount over
                           a specified period of time using linear 
                           interpolation to fill in intermediate periods.
		incr	-- increment a fixed amount each period.
                jump    -- immediately increment the variable 
                pchange -- grow at constant rate
                pgrow   -- like "grow", but use constant percentage growth
                           instead of linear interpolation.
                set     -- set the variable to an explicit value

        A length is a positive integer or a ".", which indicates the
        remainder of the program.  The scenario need not fill out the
        entire range of the variable.
*/
        local flat    0            /* Choose codes for the actions */
        local grow    1
	local incr    2
        local jump    3
	local pchange 4
        local pgrow   5
        local set     6
        tempname mx
	parse "`action'", parse(" ,")
	while "`1'"!="" {
		if "`1'"!="," { local a "`a' `1'" }
		mac shift
	}
	local action "`a'"
/*
        Store the coded actions in a program matrix.
*/
        local plen : word count `action'
        if `plen'==0 {
                di in re "scenario: no actions specified"
                error 98
        }
        tempname p
        mat def `p' = J(`plen',3,-99)
        parse "`action'", parse(" ")
        local i 0
        while `i'<`plen' {
                local i = `i' + 1
                if "``i''"=="flat"         { local code = `flat'    }
                else if "``i''"=="grow"    { local code = `grow'    }
                else if "``i''"=="incr"    { local code = `incr'    }
                else if "``i''"=="jump"    { local code = `jump'    }
                else if "``i''"=="pchange" { local code = `pchange' }
                else if "``i''"=="pgrow"   { local code = `pgrow'   }
                else if "``i''"=="set"     { local code = `set'     }
                else {
                        di in re "scenario: unrecognized action = ``i''"
                        exit 98
                }
                mat def `mx' = J(1,1,`code')
                mat substitute `p'[`i',1] = `mx'
        }
/*
        Store the amounts in the program matrix.
*/
	parse "`amount'", parse(" ,")
        local a
	while "`1'"!="" {
		if "`1'"!="," { local a "`a' `1'" }
		mac shift
	}
	local amount "`a'"
        local j : word count `amount'
        if `j'!=`plen' {
                di in re "scenario: number of amounts (`j') doesn't match number of actions (`plen')"
                exit 98
        }
	parse "`amount'", parse(" ,")
        local i 0
        while `i'<`plen' {
                local i = `i' + 1
		local a = ``i''
                cap conf number `a'
                if _rc {
                        di in re "scenario: amount is not a number = `a'"
                        exit 98
                }
                mat def `mx' = J(1,1,`a')
                mat substitute `p'[`i',2] = `mx'
        }
/*
        Store the lengths of each action in the program matrix.
        The dot (unlimited length) is stored as _N.
*/
        local dot = _N
	parse "`length'", parse(" ,")
        local a
	while "`1'"!="" {
		if "`1'"!="," { local a "`a' `1'" }
		mac shift
	}
	local length "`a'"
        local j : word count `length'
        if `j'!=`plen' {
                di in re "scenario: number of lengths (`j') doesn't match number of actions (`plen')"
                exit 98
        }
	parse "`length'", parse(" ,")
        local i 0
        while `i'<`plen' {
                local i = `i' + 1
		local a = ``i''
                if `a'==. { local a = `dot' }
                cap conf integer number `a'
                if _rc {
                        di in re "scenario: illegal length = `a'"
                        exit 98
                }
                if `a'<=0 {
                        di in re "scenario: illegal length = `a'"
                        exit 98
                }
                mat def `mx' = J(1,1,`a')
                mat substitute `p'[`i',3] = `mx'
        }
/*
        All parsing is finished.  Execute the program.
*/
        tempvar x
        tempname base
        parse "`varlist'", parse(" ")
        while "`1'"!="" {
                local v "`1'"
                mac shift
                local type : type `v'
                gen `type' `x' = `v'
                local i 0               /* instruction number */
                local l = `begin' - 1
                while (`i'<`plen') & (`l'<_N) {
                        local i = `i' + 1
                        local action = `p'[`i',1]
                        local amount = `p'[`i',2]
                        local length = `p'[`i',3]
                        local f = `l' + 1
                        scalar `base' = `x'[`f'-1]
                        local l = min(_N,`f'+`length'-1)
			local len = `l' - `f' + 1
                        if `action'==`flat' {
                                replace `x' = `base' in `f'/`l'
                        }
                        else if `action'==`grow' {
                                replace `x' = (`amount'/`len') + `x'[_n-1] in `f'/`l'
                        }
                        else if `action'==`incr' {
                                replace `x' = `amount' + `x'[_n-1] in `f'/`l'
                        }
                        else if `action'==`jump' {
                                scalar `base' = `base' + `amount'
                                replace `x' = `base' in `f'/`l'
                        }
                        else if `action'==`pchange' {
                                replace `x' = (1+`amount')*`x'[_n-1] in `f'/`l'
                        }
                        else if `action'==`pgrow' {
                                local R = ((`base'+`amount')/`base')^(1/`len')
                                replace `x' = (`R')*`x'[_n-1] in `f'/`l'
                        }
                        else if `action'==`set' {
                                replace `x' = `amount' in `f'/`l'
                        }
                        else {
                                di in re "scenario: program error, action code `action'"
                                exit 999
                        }
                }
                replace `v' = `x' in `begin'/l
                drop `x'

        }
}	/*	end quietly	*/
end
