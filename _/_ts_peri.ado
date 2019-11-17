*! _ts_peri -- utility to obtain periodicity of data
*! version 1.0.0     Sean Becketti     September 1993           STB-15: sts4
*  revised to store the results in S_D_peri rather than S_period
program define _ts_peri /* #  or  word   or  # word  */
	version 3.1
	if "`*'"=="" {
		if "$S_D_peri"=="" {
			mac def S_1 1
			mac def S_2 "annual"
		}
		else {
			parse "$S_D_peri", parse(" ")
			mac def S_1 `1'
			mac def S_2 `2'
		}
		exit
	}
	if "`2'"!="" {
		if ("`3'"!="") { error 198 }
		local numb `1'
		local wrd `2'
	}
	else {
		capture confirm integer number `1'
		if _rc==0 {
			local numb `1'
			if `1'==1 { local wrd annual }
			else if `1'==2 { local wrd semiannual }
			else if `1'==4 { local wrd quarterly }
			else if `1'==12 { local wrd monthly }
			else if `1'==52 { local wrd weekly }
			else if `1'==365 { local wrd daily }
			else local wrd "p`1'"
		}
		else {
			local l=length("`1'")
			if "`1'"==substr("annual",1,`l') { 
				local wrd "annual"
				local numb 1
			}
			else if "`1'"==substr("semiannual",1,`l') {
				local wrd "semiannual"
				local numb 2
			}
			else if "`1'"==substr("quarterly",1,`l') {
				local wrd "quarterly"
				local numb 4
			}
			else if "`1'"==substr("monthly",1,`l') {
				local wrd "monthly"
				local numb 12
			}
			else if "`1'"==substr("weekly",1,`l') {
				local wrd "weekly"
				local numb 52
			}
			else if "`1'"==substr("daily",1,`l') {
				local wrd "daily"
				local numb 365
			}
			else {
				di in red "period `1' unrecognized"
				exit 198
			}
		}
	}
	mac def S_1 `numb'
	mac def S_2 `wrd'
end
