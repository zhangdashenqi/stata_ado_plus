*! filldate -- fill in missing values in date variables         STB-24: sts7.6
*! version 1.0     Sean Becketti     January 1995
*
*	filldate assumes the data are already in time order.
*	filldate can only handle annual, quarterly, and monthly data.
*
program define filldate
quietly {
        version 3.1
        local options "Begin(str) Datevars(str) Period(str)"
        parse "`*'"
        local order "$S_SORT"
        if "`datevar'"!="" {
        	parse "`datevar'", parse(" ,")
                local d
        	while "`1'"!="" {
        		if "`1'"!="," { local d "`d' `1'" }
        		mac shift
        	}
        	local dvars "`d'"
        }
        else {          /* datevars not specified, look for global values */
                datevars
                local i 1
                while "${S_`i'}"!="" {
                        local dvars "`dvars' ${S_`i'}"
                        local i = `i' + 1
                }
        }
        local nd : word count `dvars'
        if `nd'==0 { exit }             /* no date variables to fill */
        local new 0
        cap conf v `dvars'
        if _rc {                /* no date vars, use start date to create */
                local new 1
                cap conf ex `begin'
                if _rc { exit }
        	parse "`begin'", parse(" ,")
                local b
        	while "`1'"!="" {
        		if "`1'"!="," { local b "`b' `1'" }
        		mac shift
        	}
        	local begin "`b'"
                local nb : word count `begin'
                if `nd'!=`nb' {
                        di in re "filldate: mismatch between datevars and start values"
                        exit 98
                }
        }
        if "`period'"!="" {
        	parse "`period'", parse(" ,")
                local p
        	while "`1'"!="" {
        		if "`1'"!="," { local p "`p' `1'" }
        		mac shift
        	}
        	local period "`p'"
        }
        else {          /* period not specified, search for global value */
                period
                local period $S_1
        }
        if `period'==1 {                /* annual */
                if `nd'!=1 {
                        di in re "filldate: mismatch between period and datevars"
                        exit 98
                }
                local y : word 1 of `dvars'
                if `new' { gen int `y' = `begin' + _n - 1 }
                else if `y'[1]==. { replace `y' = `begin' + _n - 1 }
                else { replace `y' = 1 + `y'[_n-1] if `y'==. in 2/l }
        }
        else if `period'==4 {           /* quarterly */
                if `nd'!=2 {
                        di in re "filldate: mismatch between period and datevars"
                        exit 98
                }
                local y : word 1 of `dvars'
                local q : word 2 of `dvars'
                if `new' { 
                        parse "`begin'", parse(" ")
                        gen int `y' = `1' in f
                        gen int `q' = `2' in f
                }
                else if `y'[1]==. { 
                        parse "`begin'", parse(" ")
                        replace `y' = `1' in f
                        replace `q' = `2' in f
                }
                replace `q' = cond(`q'[_n-1]==4,1,1+`q'[_n-1]) if `q'==. in 2/l
                replace `y' = cond(`q'[_n-1]==4,1,0) + `y'[_n-1] if `y'==. in 2/l
        }
        else if `period'==12 {           /* monthly */
                if `nd'!=2 {
                        di in re "filldate: mismatch between period and datevars"
                        exit 98
                }
                local y : word 1 of `dvars'
                local m : word 2 of `dvars'
                if `new' { 
                        parse "`begin'", parse(" ")
                        gen int `y' = `1' in f
                        gen int `m' = `2' in f
                }
                else if `y'[1]==. { 
                        parse "`begin'", parse(" ")
                        replace `y' = `1' in f
                        replace `m' = `2' in f
                }
                replace `m' = cond(`m'[_n-1]==12,1,1+`m'[_n-1]) if `m'==. in 2/l
                replace `y' = cond(`m'[_n-1]==12,1,0) + `y'[_n-1] if `y'==. in 2/l
        }
        else { exit }           /* don't handle other frequencies yet */
}       /* end quietly */
end
