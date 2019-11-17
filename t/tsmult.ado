*! tsmult -- calculate and display long-run multipliers
*! version 1.0.0     Sean Becketti     September 1993           STB-15: sts4
program define tsmult
	version 3.1
	mac def S_1
	if "$S_E_cmd"!="tsfit" { error 301 }
	quietly {
/*
	Is there anything to do?
*/
		local lastlag "$S_E_last"
		if ("`lastlag'"=="") { exit }
/*
	Display the table of p-values and multipliers.
*/
		noi di in gr _col(10) "|  Joint      Sum of" _col(44) "Long run"
		noi di in gr _col(10) "| p-value  coefficients  p-value   effect"
		noi di in gr "---------+-----------------------------------------"
		local ownsum=1
		local iS = 0
		local i = -1
		parse "$S_E_ivl", parse(" ")
		while (`i'<$S_E_nx) {
			local i = `i'+1
			local j = `i'+1
			local vname "``j''"
			local jointpv = .
			local sum = .
			local sumpv = .
			local lrmult = .
			if ("${S_E_x`i'}"!="") {
				qui test ${S_E_x`i'}
				local jointpv = fprob(_result(3),_result(5),_result(6))
				local testval = cond(`i'==0,1,0)
				qui testsum ${S_E_x`i'}, t(`testval')
				local sumpv = fprob($S_3,$S_5,$S_6)
				if (`i'==0) {
					local ownsum=1-$S_1
					local sum=`ownsum'
					local lrmult=1/`ownsum'
				}
				else {
					local sum=$S_1
					local lrmult = `sum'/`ownsum'
				}
				noi di in ye "`vname'" _col(10) in gr "|" _col(14) in ye %3.2f =`jointpv' _col(23) %7.3f =`sum' _col(36) %3.2f =`sumpv' _col(44) %7.3f =`lrmult'
			}
			local iS = `iS'+1
			local S`iS' "`vname'"
			local iS = `iS'+1
			local S`iS' = `jointpv'
			local iS = `iS'+1
			local S`iS' = `sum'
			local iS = `iS'+1
			local S`iS' = `sumpv'
			local iS = `iS'+1
			local S`iS' = `lrmult'
		}
		local jointpv = .
		if ("`lastlag'"!="") {
			qui test `lastlag'
			local jointpv = fprob(_result(3),_result(5),_result(6))
			noi di in ye "Last lag" _col(10) in gr "|" _col(14) in ye %3.2f =`jointpv'
		}
		local iS = `iS'+1
		local S`iS' "Last lag"
		local iS = `iS'+1
		local S`iS' = `jointpv'
		local jointpv = .
		parse "`lastlag'", parse(" ")
		mac shift
		if ("`*'"!="") {
			qui test `*'
			local jointpv = fprob(_result(3),_result(5),_result(6))
			noi di in ye " Xs only" _col(10) in gr "|" _col(14) in ye %3.2f =`jointpv'
		}
		noi di in gr "---------------------------------------------------"
		local iS = `iS'+1
		local S`iS' "Xs only"
		local iS = `iS'+1
		local S`iS' = `jointpv'
/*
	Store the table in numbered system macros
*/
		local i = 0
		while (`i'<`iS') {
			local i = `i'+1
			mac def S_`i' "`S`i''"
		}
	}  /* quietly */
end
