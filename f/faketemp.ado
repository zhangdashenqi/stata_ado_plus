*! faketemp -- create "temporary" variables that can accept operators   STB17: ip5
*! version 1.0.0     Craig S. Hakkio     November 1, 1993
program define faketemp   /* faketemp places name in S_1 */
        version 3.1
        local N `1'
        if "`N'"=="" { local N 1 }
        capture confirm integer number `N'
        if _rc { error 98 }
        if `N' < 1 { error 98 }
        local NAMELEN 4         /* allow space for operators */
        local USED 110
        
        local k = 0
        while `k' < `N' {
                local k = `k' + 1
		local name
                local rc `USED'
                while `rc'==`USED' {
                        local i = 0
                        while `i' < `NAMELEN' {
                        	local j = 1 + int(26*uniform())
                        	local letter = substr("abcdefghijklmnopqrstuvwxyz",`j',1)
                        	if uniform() > 0.5 {
                        		local letter2 = upper("`letter'") 
                        	}
                        	else {
                        		local letter2 = "`letter'"
                        	}
                        	local name = "`name'" + "`letter2'"
                        	local i = `i' + 1
                        }
                        capture confirm new variable `name'
                        local rc = _rc
                }
                global S_`k' = "`name'"
        }
end
