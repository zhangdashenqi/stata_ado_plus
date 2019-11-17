*! version 1.0.1 PR 26Jul2001.  (TSJ-1: st0001)
program define frac_s3b, rclass
/* calc basis functions for cubic spline derivatives.
   updated to agree with lambda notation in survspl paper. 
   no functional changes.
*/
version 6
syntax varlist(max=1), K(str) [ BKnots(string) Name(string) Second ]
local x `varlist'
if "`bknots'"!="" {
	local bk: word count `bknots'
	if `bk'!=2 {
		di in red "invalid bknots(), must specify 2 boundary knots"
		exit 198
	}
}
if "`name'"!="" {
	if length("`name'")>6 {
		di in red "name() must be at most 6 characters"
		exit 198
	}
}
else local name=substr("`x'",1,6)
local nk: word count `k'
quietly {
/*
	Generate interior knots
*/
	count if `x'!=.
	local nobs=r(N)
	sort `x'
	if "`bknots'"!="" {
		local k0: word 1 of `bknots'
		confirm num `k0'
		local kN: word 2 of `bknots'
		confirm num `kN'
	}
	else {
		local k0=`x'[1] 
		local kN=`x'[`nobs']
	}
/*
	Calc derivative basis functions.
*/
	local names
	local j `nk'
	while `j' > 0 {
		local j1=`j'+1
		local kj: word `j' of `k'
		* now using lambda notation of Royston & Parmar (2001)
		local lambdaj=(`kN'-`kj')/(`kN'-`k0')
		cap drop `name'`j'
		if "`second'"=="" {	/* first derivative */
			gen double `name'`j'=3*(`x'>`kj')*(`x'-`kj')^2 /*
			 */ -3*`lambdaj'*(`x'>`k0')*(`x'-`k0')^2 /*
			 */ -3*(1-`lambdaj')*(`x'>`kN')*(`x'-`kN')^2
		}
		else {			/* second derivative */
			gen double `name'`j'=6*(`x'>`kj')*(`x'-`kj') /*
			 */ -6*`lambdaj'*(`x'>`k0')*(`x'-`k0') /*
			 */ -6*(1-`lambdaj')*(`x'>`kN')*(`x'-`kN')
		}
		lab var `name'`j' "deriv basis function for knot `kj'"
		local names `name'`j' `names' 
		local j=`j'-1
	}
}
return local names `names'
end
