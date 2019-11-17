*! lag -- construct lags of existing variable taking account of CS units.
*! version 3.0.0     Sean Becketti     September 1994.     STB-21: sts7.4
*	Revision history: April 1991, original version
*			  March 1994, extended syntax, incorporated _addop
*			  Sept  1994, added csunits
program define lag
	version 3.1
	capture confirm integer number `1'
	if _rc==0 { 
		local flags `1'         /* Front LAGS */
	        if `flags'==0 { exit } 
		mac shift
	}

	local varlist "req ex min(1)"
	local options "Lags(str) noSOrt Suffix(str)"
	parse "`*'"

	local cross = "$S_X_unit"!=""
	local time = "$S_D_date"!=""
	local sort = "`sort'"==""
	local order : sortedby			/* Save sort order */
	local resort = "`order'"!=""
	if `sort' {
		if `cross' & (!`time') { 
			noi di in re "Can't determine sort order: csunits defined but not datevars"
			exit 198
		}
		if `cross' | `time' { sort $S_X_unit $S_D_date }
	}
	else { local cross 0 }		/* Unset the cross-section flag */

        local vars: word count `varlist'        /* How many variables? */

        local sfx = "`suffix'"!=""              /* Are there suffixes? */
        if `sfx' { 
		_subchar "," " " "`suffix'"
		local suffix "$S_1"
		local sfxs: word count `suffix'
	}
	else { local sfxs 0 }
        if `sfx' & (`sfxs'<`vars') { exit 198 }

                                       /* How were the lags specified? */
        if ("`flags'"!="") & ("`lags'"!="") { exit 198 }
        if ("`lags'"!="") {     /* lags() option used */
		_subchar "," " " "`lags'"
		local lags "$S_1"
		local nlags: word count `lags'
        }
        else {
                if ("`flags'"!="") { local lags "`flags'" }
                else { local lags 1 }
                local nlags 1
        }

        local i 0
        while (`i'<`vars') {
                local i = `i' + 1
                local vname: word `i' of `varlist'
	        local type : type `vname'
                if `sfx' { local v: word `i' of `suffix' }
                else { local v `vname' }
                if (`i'<=`nlags') { local orgl: word `i' of `lags' }
        	if (`orgl'<0) {                    /* lag or lead? */
                        local l = abs(`orgl')
                        local L "F"
                        local lead 1
                }
                else {
			local l `orgl'
                        local L "L"
                        local lead 0
                }
                local j 0
	        while (`j'<`l') { 
                        local j = `j' + 1
                        local k = cond(`lead',-`j',`j')
                        _addop `v' `L'
                        local v "$S_1"
        		capture confirm var `v'
        		if _rc==0 { 
        			di in bl "(note:  `v' replaced)"
        			drop `v'
        		}
        		qui gen `type' `v' = `vname'[_n-`k']
			if `cross' { 
				if `lead' { local crossif "_n-`k'>_N" }
				else      { local crossif "_n-`k'< 1" }
pause				qui by  $S_X_unit: replace `v' = . if `crossif'
				qui by  $S_X_unit: replace `v' = . if `crossif'
			}
                        local end = index("`v'",".") - 1
                        local prefix = substr("`v'",1,`end')
        		label var `v' "`prefix'`vname'"
		}
	}
	if `resort' { sort `order' }
end
