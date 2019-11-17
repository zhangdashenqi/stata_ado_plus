*! version 1.0.0  02/02/93  STB-13: dm13.1
program define replstr
	version 3.0
	local old "`1'"
	local new "`2'"
	local n "`3'"
	if "`3'"=="" { error 198 }
	mac shift 
	mac shift
	mac shift 
	local varlist "req ex max(1)"
	local if "opt"
	local in "opt"
	parse "`*'"

	if "`n'"=="." { local n 100 }
	confirm integer number `n'
	if `n'==0 { exit }

	if "`old'"=="" { error 198 }

	tempvar res col rcol
	quietly { 
		local type : type `varlist'
		local lnew = length("`new'")
		local lold = length("`old'")
		if `lnew'>`lold' {
			local d=min(real( /* 
				*/ substr("`type'",4,.))+(`lnew'-`lold')*`n', /*
				*/ 80 )
			local type "str`d'"
		}
		gen `type' `res'=`varlist' `if' `in'
		gen byte `col'=1
		gen byte `rcol'=.
		local i=1
		while `i'<=`n' {
			replace `rcol'=index(substr(`res',`col',.),"`old'")
			replace `rcol'=`rcol'+`col'-1 if `rcol'
			capture assert `rcol'==0 
			if _rc {
				replace `res'=substr(`res',1,`rcol'-1) + /*
					*/ "`new'" + /*
					*/ substr(`res',`rcol'+`lold',.) /*
					*/ if `rcol'
				replace `col'=`rcol'+`lnew'+1 if `rcol'
			}
			else	local i=`n'
			local i=`i'+1
		}
		drop `col' `rcol'
		compress `res'
		local type : type `res'
		minlen `type' `varlist'
		replace `varlist'=`res' `if' `in'
		drop `res'
	}
end
