*! tsreg -- front end for time series regression
*! version 1.0.0     Sean Becketti     September 1993           STB-15: sts4
program define tsreg
	version 3.1
	if (substr("`1'",1,1)=="," | "`*'"=="") { 
		if "$S_E_cmd"~="tsfit" { 
			error 301
		}
	        local options "Current(str) Lags(str) LEvel(integer $S_level) noMult noOutput noRegress noSample Static(str) noTest"
	        if "`*'"=="" {
                        local add ", $S_E_curr $S_E_lags $S_E_stat"
                }
                else { local add "$S_E_curr $S_E_lags $S_E_stat" }
		parse "`*' `add'"
                cap conf v $S_E_ivl
                if _rc {
                        noi di in re "data must be in memory to replay tsreg"
                        error 98
                }
                local varlist "$S_E_ivl"
                local if "$S_E_if"
                local in "$S_E_in"
                local weight "$S_E_wgt"
                local exp "$S_E_exp"
                local constan "$S_E_cons"
	}
	else { 
        	local varlist "req ex"
        	local if "opt pre"
        	local in "opt pre"
        	local weight "aweight fweight"
        	local options "noCOnstant Current(str) Lags(str) LEvel(integer $S_level) noMult noOutput noRegress REPLACE noSAmple Static(str) noTest *"
        	parse "`*'"
        }
	if ("`output'"!="") {
		local sample "nosample"
		local regress "noregress"
		local mult "nomult"
		local test "notest"
	}
/*
	Format the current(), lags(), and static() options conveniently.
*/
	if "`replace'"=="" { preserve }
	if ("`current'"!="") {
		_parsevl `current'
		local current "$S_1"
		local c "c(`current')"
	}
	if ("`lags'"!="") {local l "l(`lags')"}
	if ("`static'"!="") {
		_parsevl `static'
		local static "$S_1"
		local s "s(`static')"
	}
        if "`regress'"!="" { local q "quietly" }
	`q' tsfit  `varlist' `if' `in' [`weight'`exp'], `c' `l' `s' `sample' `constan' `options'
        if ("`sample'"=="") & ("`regress'"!="") {
	        findsmpl `varlist' `if' `in' [`weight'`exp']
        }
	if ("`mult'"=="") { tsmult }
	if ("`test'"=="") { regdiag, time }
end
