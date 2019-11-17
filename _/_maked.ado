*! version 1.0.0  10/28/92  hadimvo subroutine STB-11 smv6
program define _maked /* D touse r lhs rhs */
	version 3.0
	local D "`1'"
	local touse "`2'"
	local r "`3'"
	local u "`4'"
	local rhs "`5'"

	capture drop `D'
	reg `u' `rhs' if `touse' in 1/`r'
	predict `D' if `touse', hat
	replace `D'=`D'-1/_result(1)
	sort `D'			/* missing to end	*/
end
