
program define permt2
	version 7
 	local grp "`1'"
 	local x "`2'"
 	tempvar sum
 	quietly {
 		if "$S_1"=="first" {
 			gen double `sum'=sum(`x')
 			scalar _TOTAL = `sum'[_N]
 			drop `sum'
 			summarize `grp'
 			scalar _GROUP1 = r(min)
 			count if `grp'== _GROUP1
 			scalar _TOTAL = (r(N)/_N)*_TOTAL
	 	}
 		gen double `sum'=sum((`grp'==_GROUP1)*`x')
 		global S_1 = `sum'[_N] - _TOTAL
 	}
end
