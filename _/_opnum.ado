*! version 6.0.0	23dec1998	(www.stata.com/users/becketti/tslib)
*! _opnum -- extract operators and associated numbers from varname
/*
	_opnum varname

	numbers are extracted from names of the form X.xxx and X#[#[]].xxx where
	the X's are operators.

	examples:	input	output
			-----	------
			  x	  0
			 L_x	  1 "L 1"
			L27_x	  1 "L 27"
			LD_x	  2 "L 1" "D 1"
			L3D2_x	  2 "L 3" "D 2"
			Z5_x	  1 "Z 5"  /* we allow unknown operators */

*/
program define _opnum
	version 3.1
	local v "`1'"
	cap conf variable `v'
	if _rc {
		cap conf new variable `v'
		if _rc { exit 198 }
	}
/*
	This is a legal variable name.  If we can't interpret the number,
	return 0.
*/
	local dot = index("`v'","_")
	global S_2
	local i 1
	local j 1
	local more = `dot'>1
	while `more' {
		local op = substr("`v'",`i',1)
		local i = `i' + 1
		local isnum 1
		while `isnum' {
			local n = substr("`v'",`i',1)
			cap conf integer number `n'
			if _rc { local isnum 0 }
			else { 
				local i = `i' + 1
				local num "`num'`n'"
			}
		}
		local j = `j' + 1
		if "`num'"=="" { local num 1 }
		global S_`j' "`op' `num'"
		local num
		local more = `i'<`dot'
	}
	global S_1 = `j'-1
end

