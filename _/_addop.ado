*! _addop -- "op" a variable name, i.e., add an operator to the prefix
*! version 1.0.0     Sean Becketti     November 1993
/* 
	_addop is a generalization of _addl.  All programs using or defining
	operators (lag, dif, growth, etc.) should call _addop to compose
	the names of their output variables.
*/
program define _addop		/* _addop vname operator [nocheck] */
	version 3.1
	global S_1
	local name "`1'"
	local O "`2'"
	if "`O'"=="" { 
		global S_1 "`name'"
		exit 
	}
	if "`3'"=="" {
		cap conf v `name'
		local exvar = _rc
		cap conf new v `name'
		local newvar = _rc
		if (`exvar' & `newvar') {
			di in re "`name' is not a legal variable name"
			error 99
		}
	}
/*
	Add `O' taking account of previous `O's and other operators.
*/
	local j = index("`name'",".")
/*
	If there's no prefix yet or the first operator is not an `O', 
	just add `O' to the front.
*/
	if (!`j') {local newname = substr("`O'.`name'",1,8)}
	else if (substr("`name'",1,1)!="`O'") {local newname = substr("`O'`name'",1,8)}
/*
	If there's already an `O', then increment the lag by 1.
*/
	else {
		local last = `j'
		local i = 2
		while (`i'<`j') {
			local k = substr("`name'",`i',1)
			cap conf n `k'
			if (!_rc) {
				local nlag "`nlag'`k'"
				local i = `i' + 1
			}
			else {
				local last = `i'
				local i = `j'
			}
		}
		local nlag = cond("`nlag'"=="",2,`nlag'+1)
		local newname = "`O'`nlag'" + substr("`name'",`last',8)
	}
	global S_1 = substr("`newname'",1,8)
end

