*! version 1.1.0 PR 25jan2007
program define splinegen, rclass sortpreserve
version 8
gettoken v 0 : 0, parse(" ,")
unab v : `v', max(1)
local done 0
gettoken nxt : 0, parse(" ,")
while ("`nxt'" != "" & "`nxt'" != ",") & !`done' {
	cap confirm number `nxt'
	if !_rc {
		local knots "`knots' `nxt'"
		gettoken nxt 0 : 0, parse(" ,")
		gettoken nxt   : 0, parse(" ,")
	}
	else 	local done 1
}
if "`knots'"=="" local options "DF(int 0) UNIQUE KFig(int 6)"
syntax [if] [in] [, `options' Orthog Basis(string) ///
 DEGree(int 3) BKnots(string) restrict(string) ]
if "`bknots'"!="" {
	local bk: word count `bknots'
	if `bk'!=2 {
		di as err "invalid bknots(), must specify 2 boundary knots"
		exit 198
	}
}
if "`basis'"!="" local name `basis'
else local name `v'
if `degree'>3 | `degree'<0 | `degree'==2 {
	di as err "degree must be either 0, 1, or 3."
	exit 198
}
if `degree'==0 local lt "<" // allows knots at min for deg 0
else local lt "<="
marksample touse
markout `touse' `v'
/*
	restrict() is same as in the Stata 10 version of fracgen, to generate
	basis functions for all obs but knots in generatation sample.

	-restrict()- becomes part of touse for calculation purposes;
	only for restricting the subset of the data used with transformation
	is the original touse used.
*/
if "`restrict'"!="" {
	tempvar touse_user
	qui gen byte `touse_user' = `touse'
	frac_restrict `touse' `restrict'
}
else	local touse_user `touse'
quietly {
	tempvar x
	gen double `x' = `v' if `touse_user'
	// Calcs of knots restricted to `touse' subset, includes `restrict()' if applied
	gsort -`touse' `x'
	if "`unique'"!="" {
		tempvar xold
		gen double `xold'=`x'
		bysort `x': replace `x'=. if _n!=1
		sort `x'
		count if `touse' & !missing(`x')
		local nobs=r(N)
	}
	else {
		count if `touse'
		local nobs=r(N)
	}
/*
	Generate interior knots
*/
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
	local klast `kN'
	if "`knots'"=="" {
		if `df'==0 local nk = (`degree'==0)+int((`nobs')^.25)
		else local nk=`df'-(`degree'!=0)
		if `nk'!=1 local s s
		noi di as text "[`nk' knot`s' to be used]"
		local j `nk' 
		while `j' > 0 {
			local k`j'=`x'[int((`j'*`nobs'/(`nk'+1))+.5)]
			if `k`j''==`klast'|`k`j''`lt'`k0' {
				noisily di as text "[knot at `k`j'' ignored]"
				local i `j'
				while `i'<`nk' {
					local i2=`i'+1
					local k`i' `k`i2''
					local ++i
				}
				local --nk
			}
			else {
				if "`kfig'"!="" {
					// Trim calculated knots to kfig sig fig
					local k`j': display %`kfig'.0g `k`j''
					local k`j'=trim("`k`j''")
				}
				local knots `k`j'' `knots'
				local klast `k`j''
			}
			local --j
		}
		if "`unique'"!="" replace `x'=`xold'
	}
	else {
		tokenize `knots'
		local nk 0
		while "`1'"!="" {
			if `1'`lt'`k0' | `1'>=`kN' noi di as txt "[knot at `1' ignored]"
			else {
				local ++nk
				local k`nk' `1' 
			}
			mac shift
		}
		if `nk'!=1 local s s
		noi di as txt "[`nk' knot`s' to be used]"
	}
/*
	Create basis variables
*/
	local j `nk'
	while `j' > 0 {
		local vn `name'_
		cap drop `vn'`j'
		if "`orthog'"=="" {
			local n `vn'`j'
		}
		else {
			tempvar cov`j'
			local n `cov`j''
		}
		if `degree'==0 {
			// care needed for missing x
			gen byte `n'=(`x'>`k`j'') if !missing(`x')
			local low: word 1 of `k`j''
			lab var `n' "`v'>`low'"
		}
		else if `degree'==1 {
			// is correct for missing x
			gen double `n'=(`x'>`k`j'')*(`x'-`k`j'')
		}
		else if `degree'==3 {
			// now using lambda notation of Royston & Parmar (2001)
			local lambdaj=(`kN'-`k`j'')/(`kN'-`k0')
			gen double `n'=(`x'>`k`j'')*(`x'-`k`j'')^3 ///
			 -`lambdaj'*(`x'>`k0')*(`x'-`k0')^3 ///
			 -(1-`lambdaj')*(`x'>`kN')*(`x'-`kN')^3
		}
		local covars "`n' `covars'"
		local --j
	}
	if "`orthog'"=="" & `degree'!= 0 {
		if "`v'"!="`name'" {
			cap gen double `name'_0=`x'
			if _rc {
				drop `name'_0
				gen double `name'_0=`x'
			}
			local covars "`name'_0 `covars'"
		}
		else local covars "`name' `covars'"
	}
	else if "`orthog'"!="" {
		local nk1=`nk'+(`degree'!=0)
		local vn `name'_
		if `degree'!=0 { 
			cap drop `vn'`nk1'
			local xvar `x'
		}
/*
	If the matrix Q is fed in thru q() option, we use its inverse to 
	compute the transformed (orthogonalised) basis functions.
	Otherwise, compute them from scratch using orthog.ado.

	{p 4 8 2}
	{cmd:q(}{it:matrixname}{cmd:)} specifies that a matrix
	called {it:matrixname} will be used to create orthogonalized
	basis functions from {it:varname}. The inverse of {it:matrixname} is used
	to compute the transformed (orthogonalized) basis functions.
	The default with the {cmd:orthog} option is to compute the
	orthogonalized basis functions. by using {help orthog}.
*/
		* Call first covariate name_0.
		orthog `xvar' `covars', gen(`vn'*)
		local covars "`name'_0"
		cap drop `name'_0
		rename `vn'1 `name'_0
		lab var `name'_0 "standardized `v'"
		forvalues j=2/`nk1' {
			local jm=`j'-1
			local vnew `vn'`jm'
			local vold `vn'`j'
			rename `vold' `vnew'
			local covars "`covars' `vnew'"
			lab var `vnew' "orthogonalized basis `jm'"
			cap drop `cov`jm''
/*
	label basis vectors with chars corresponding to knot positions
*/
			if `jm'>1 cap char `vnew'[fp] `k`jm''
			else cap char `name'[fp] "linear"
		}
	}
}
global S_1 `covars'
global S_2 `nk'
global S_3 `knots'
return local names `covars'
return scalar nk=`nk'
return local knots `knots'
return local bknots `k0' `kN'
end

*! version 1.0.0  18jan2007
program frac_restrict
	version 9.2
	capture syntax varlist [if/]
	if c(rc) {
		di as err "invalid restrict() option"
		exit 198
	}
	gettoken touse restrict : varlist
	if `:list sizeof restrict' > 1 {
		di as err "invalid restrict() option"
		exit 103
	}
	if "`restrict'" == "" {
		local restrict (`if')
	}
	else {
		markout `touse' `restrict'
		if "`if'" != "" {
			local restrict (`restrict' & (`if'))
		}
	}
	replace `touse' = 0 if !`restrict'
	quietly count if `touse'
	if r(N) == 0 {
		error 2000
	}
end
exit
