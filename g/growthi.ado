*! growthi -- immediate form of growth command
*! version 1.0.0     Sean Becketti     May 1994
*
*  "growthi old_exp new_exp, options"   calculates growth rate going from
*                                       old_exp to new_exp
*
program define growthi
	version 3.1
/*
        Store the expressions, then see if we can evaluate them.   
        Watch out for the comma.
*/
        global S_1 = .
	local oldexp "`1'"
        mac shift
        tempname old
        cap scalar `old' = `oldexp'
        local rc = _rc
        if `rc' {
                di in ye "`oldexp' " in re "... is not a legal expression"
                exit `rc'
        }
        local newexp "`1'"
        mac shift
        local rmndr "`*'"
        local i = index("`newexp'",",") 
        if `i' {      /* comma is in 2nd expression */
                local comma = substr("`newexp'",`i',.)
                local i = `i' - 1
                local newexp = substr("`newexp'",1,`i')
                local rmndr "`comma' `rmndr'"
        }
        tempname new
        cap scalar `new' = `newexp'
        local rc = _rc
        if `rc' {
                di in ye "`newexp' " in re "... is not a legal expression"
                exit `rc'
        }
	local options "noAnnual LAg(int 1) Log Percent PERIod(str)"
	parse "`rmndr'"

	_ts_peri `period'		/* obtain # of periods per "year" */
	local period=cond("`annual'"!="",1,$S_1)
        local lag=cond("`annual'"="",1,`lag')

	local f100=cond("`percent'"!="",100,1)
	local pwr=`period'/`lag'

	tempname growth
	quietly { 
		if ("`log'"!="") {
			scalar `growth'=`f100'*`pwr'*(ln(`new')-ln(`old'))
		}
		else {
			scalar `growth' = `f100'*((`new'/`old')^`pwr'-1)
		}
	}
        global S_1 = `growth'
	global S_2 = `lag'
	global S_3 = `old'
	global S_4 = `new'
	global S_5
        di in ye = `growth'
end
