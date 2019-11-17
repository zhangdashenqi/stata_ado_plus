*! Version 0.1 July 19, 2019
*! Clickable list of the post from theZenofStata
*! By zhangdashenqi @ theZenofStata
*! Email: zhangqingjun3@qq.com
*! GitHub: https://github.com/zhangdashenqi
*! WeChat Subscription Account: Stata之禅


cap program drop chars
program def chars
	gettoken _STR 0 : 0
	local LEN  = strlen("`_STR'")
	mat REST = (. \ . \ . \ . \ . \ .)
	preserve
		qui webuse set "https://raw.githubusercontent.com/zhangdashenqi/"
		webuse "Stata-Graph/master/do/CHAR.dta"

		forvalues i = 1/`LEN'{
			local _CHAR = substr("`_STR'", `i', 1)
			local POS = real(substr(tobytes("`_CHAR'"), 3, 3))
			if      inrange(`POS', 48, 57)  local BASE = `POS' - 47 + 26
			else if inrange(`POS', 65, 90)  local BASE = `POS' - 64
			else if inrange(`POS', 97, 122) local BASE = `POS' - 96
			else local BASE = 37
			
			local POS_H = `BASE' * 6
			local POS_L = `POS_H' - 5

			mkmat v1-v14 in `POS_L'/`POS_H', mat(STR)
			mat_capp REST : REST STR
		}
		
		local NUM = colsof(REST)
		forvalues i = 1/6{
			forvalues j = 1/`NUM'{
				if      REST[`i', `j'] == 0  dis " " _c
				else if REST[`i', `j'] == 1  dis "/" _c
				else if REST[`i', `j'] == 2  dis "\" _c
				else if REST[`i', `j'] == 3  dis "_" _c
				else if REST[`i', `j'] == 4  dis "|" _c
				else if REST[`i', `j'] == 5  dis ")" _c
				else if REST[`i', `j'] == 6  dis "<" _c
				else if REST[`i', `j'] == 7  dis "'" _c
				else if REST[`i', `j'] == 8  dis "." _c
				else if REST[`i', `j'] == 9  dis "(" _c
				else if REST[`i', `j'] == 10 dis "V" _c
				else if REST[`i', `j'] == 11 dis ">" _c
				else if REST[`i', `j'] == 12 dis "`" _c
				else if REST[`i', `j'] == 13 dis "," _c
				else if REST[`i', `j'] == .  dis ""  _c
			}
			dis ""
		}
	restore
end
