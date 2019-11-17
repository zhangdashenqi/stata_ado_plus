*! _partset -- partition two sets into their intersection and complements
*! version 1.0.0     Sean Becketti     November 1993
*
*  HEY.  I name AinB and BinA backwards.  What a doof!
*
program define _partset	/* set_A set_B */
	version 3.1
	local A "`1'"
	local B "`2'"
	global S_1
	global S_2
	global S_3
	local nA : word count `A'
	local nB : word count `B'
/*
	Find the intersection of A and B (intsect) and the complement of
        B in A (BinA).
*/
	local i 0
	while `i'<`nB' {
		local i = `i' + 1
		local tok : word `i' of `B'
		_inlist "`tok'" "`A'"
		if $S_1 { local intsect "`intsect' `tok'" }
		else { local BinA "`BinA' `tok'" }
	}
/*
	Find the complement of A in B (AinB).
*/
	local i 0
	while `i'<`nA' {
		local i = `i' + 1
		local tok : word `i' of `A'
		_inlist "`tok'" "`B'"
		if !$S_1 { local AinB "`AinB' `tok'" }
	}
	global S_1 "`AinB'"
	global S_2 "`intsect'"
	global S_3 "`BinA'"
end
