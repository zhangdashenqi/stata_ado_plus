*! version 6.0.0     23dec1988		(www.stata.com/users/becketti/tslib)
*! _addl -- "lag" a variable name, i.e., add an "L" to the prefix
program define _addl
	version 3.0
	local name "`1'"
	cap conf v `name'
	local exvar = _rc
	cap conf new v `name'
	local newvar = _rc
	if (`exvar' & `newvar') {
		di in re "`name' is not a legal variable name"
		error 99
	}
/*
	Add an L taking account of previous L's and other operators.
*/
	local j = index("`name'","_")
/*
	If there's no prefix yet or the first operator is not an L, 
	just add L to the front.
*/
	if (!`j') {local newname = substr("L_`name'",1,8)}
	else if (substr("`name'",1,1)!="L") {local newname = substr("L`name'",1,8)}
/*
	If there's already an L, then increment the lag by 1.
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
		local newname = "L`nlag'" + substr("`name'",`last',8)
	}
	mac def S_1 = substr("`newname'",1,8)
end
