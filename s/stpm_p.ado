*! version 1.2.1 PR 29Aug2001.  (TSJ-1: st0001)
program define stpm_p
version 6
if e(nomodel)==1 {
	di in red "prediction not available, no parameters were estimated"
	exit 198
}
gettoken varn 0 : 0, parse(" ,[")
gettoken nxt : 0, parse(" ,[(")
if !(`"`nxt'"'=="" | `"`nxt'"'=="if" | `"`nxt'"'=="in" | `"`nxt'"'==",") {
	local typ `varn'
	gettoken varn 0 : 0, parse(" ,[")
}
confirm new var `varn'
syntax [if] [in] [, At(string) CUMHazard CUMOdds Density Hazard Normal Survival /*
 */ Time(string) XB STDP CEntile(string) DZdy Zero TOL(real .001) SPline TVc(varname) /*
 */ noCONStant noOFFset ]
/* concatenate switch (mutually incompatible) options */
if "`centile'"!="" { local type centile }
else if "`tvc'"!="" { local type tvc }
else local type "`cumhaza'`cumodds'`density'`hazard'`normal'`surviva'`spline'`dzdy'`xb'"
local theta=e(theta)
if "`stdp'"!="" {
	if "`type'"=="density"|"`type'"=="hazard"|"`type'"=="survival"|"`type'"=="dzdy" {
		di in red "standard errors not available for `type'"
		exit 198
	}
	tempvar se
}
if "`type'"==""  {
	di in gr "(option xb assumed)"
	local type xb
}
if "`type'"=="xb" & "`time'"!="" {
	di in red "time() inapplicable"
	exit 198
}
if "`type'"=="tvc" {
	if "`at'"!="" {
		di in red "at() inapplicable with tvc()"
		exit 198
	}
	cap local btvc=[xb]_b[`tvc']
	if _rc {
		di in red "`tvc' not in time-fixed part of model"
		exit 198
	}
}
if "`time'"=="" {
	local time _t
}
else {
	cap confirm var `time'
	if _rc {
		cap confirm num `time'
		if _rc {
			di in red "invalid time()"
			exit 198
		}
	}
}
local df=e(df)
if `df'>1 {
	local bknots `e(bknots)'
	local k0: word 1 of `bknots'
	local kN: word 2 of `bknots'
	local knots `e(knots)'
}
local cscale `e(cscale)'
if e(scale)==0 {
	local scale h
}
else if e(scale)==1 {
	local scale n
}
else if e(scale)==2 {
	local scale o
}
tempvar XB
tempname coef b tmp
matrix `coef'=e(b)				/* entire coefficient matrix */
matrix `b'=`coef'[1,"xb:"]			/* eqn for covariates */
local xvars `e(fvl)'				/* names of covariates */
local nx=colsof(`b')				/* no. of covariates inc. cons */
quietly if "`type'"=="centile" {
	tempvar esample t0 s0 d0 maxerr
	tempname gp p
	scalar `p'=1-`centile'/100	/* point in distribution fn not survival fn */
	if e(scale)==0 {
		scalar `gp'=ln(-ln(`p'))
	}
	else if e(scale)==1 {
		scalar `gp'=-invnorm(`p')
	}
	else if e(scale)==2 {
		scalar `gp'=ln(1/`p'-1)
	}
	local left `e(left)'
	if "`left'"!="" { local left left(`left') }
	if "`at'"!="" { local AT at(`at') }
	gen byte `esample'=1 if e(sample)
	* Save model estimates
	estimates hold `tmp'
	stpm `xvars' if `esample', df(1) scale(`scale') `left' index(2) theta(`theta')
	* Linear predictor on transformed cum distribution scale
	predict double `XB' `if' `in', `AT' `zero'
	* Find `t0' = first guess at t for given centile
	_predict double `s0' `if' `in', equation(s0)
	gen double `t0'=exp((`gp'-`XB')/`s0')
	drop `XB' `s0' `esample' `e(sbasis)'
	* Restore model
	estimates unhold `tmp'
	* Predict fitted spline `s0' and first derivative `d0' at guess `t0'
	predict double `s0' `if' `in', time(`t0') `AT' `zero' `cscale'
	predict double `d0' `if' `in', time(`t0') `AT' `zero' dzdy
	* Iterate to solution
	local done 0
	while !`done' {
		* Update estimate of time
		replace `t0'=exp(ln(`t0')-(`s0'-`gp')/`d0')
		* Update estimate of transformed centile and check prediction
		drop `s0' `d0'
		predict `s0' `if' `in', time(`t0') `AT' `zero' `cscale'
		* Max absolute error
		gen double `maxerr'=abs(`s0'-`gp')
		sum `maxerr'
		if r(max)<`tol' { local done 1 }
		else {
			predict double `d0' `if' `in', time(`t0') `AT' `zero' dzdy
		}
		drop `maxerr'
	}
	if "`stdp'"=="" {
		gen `typ' `varn'=`t0'
		label var `varn' "`centile' centile"
	}
	else {
/*
	Unfortunately, need time (t0) to compute standard error.
	Results in wasted computation of t0 but can't be avoided
	with "predict <>, stdp" design.
*/
		predict double `d0' `if' `in', time(`t0') `AT' `zero' dzdy
		tempvar lnt0
		gen double `lnt0'=ln(`t0')
		if `df'>1 {
			cap drop I__d0*
			frac_spl `lnt0' `knots', name(I__d0) deg(3) bknots(`k0' `kN')
			local v `r(names)'
		}
		else local v `lnt0'
		Gense `se' "`v'" "`zero'" "`at'" `"`if'"' `"`in'"'
		gen `typ' `varn'=`se'/abs(`d0')
		label var `varn' "S.E. of `centile' centile"
		drop `v'
	}
	exit
}
local nat 0
if "`at'"!="" {
	tokenize `at'
	while "`1'"!="" {
		unab 1: `1'
		cap confirm var `2'
		if _rc {
			cap confirm num `2'
			if _rc {
				di in red "invalid at(... `1' `2' ...)"
				exit 198
			}
		}
		local nat=`nat'+1
		local atvar`nat' `1'
		local atval`nat' `2'
		mac shift 2
	}
}
/*
	Compute index. First check if model has a constant.
*/
tempname cons
cap scalar `cons'=`b'[1,`nx']
if _rc!=0 {
	local hascons 0
	scalar `cons'=0
}
else local hascons 1
if "`at'`zero'"=="" {
	qui _predict double `XB' `if' `in', equation(xb)
}
else {
	qui gen double `XB'=`cons' `if' `in'	/* cons */
}
if `hascons' & "`constan'"=="noconstant" {
	qui replace `XB'=`XB'-`cons'
}
if "`e(offset)'"!="" & "`offset'"!="nooffset" {
	qui replace `XB'=`XB'+`e(offset)'
}
if "`at'`zero'"!="" {
/*
	Calc linear predictor allowing for at and zero.
	Note inefficiency (for clarity) if zero!="" and at=="" ,
	since then XB is not altered but j loops anyway.
*/
	local j 1
	while `j'<`nx' {		/* nx could be 0, then no looping */
		local changed 0
		local covar: word `j' of `xvars'
		local xval `covar'
		if "`at'"!="" {
			local k 1
			while `k'<=`nat' & !`changed' {
				if "`covar'"=="`atvar`k''" {
					local xval `atval`k''
					local changed 1
				}
				local k=`k'+1
			}
		}
		if `changed' | (!`changed' & "`zero'"=="") {
			qui replace `XB'=`XB'+`xval'*`b'[1,`j']
		}
		local j=`j'+1
	}
}
if "`type'"=="xb" {
	if "`stdp'"=="" {
		qui gen `typ' `varn'=`XB'
		label var `varn' "Linear prediction"
	}
	else {
		Gense `se' "" "`zero'" "`at'" `"`if'"' `"`in'"'
		qui gen `typ' `varn'=`se'
		label var `varn' "S.E. of linear predictor"
	}
	exit
}
/*
	Time-dependent quantities.
	Compute spline basis variable(s), names stored in `v'.
*/
tempvar lnt
tempname c
qui gen double `lnt'=ln(`time') `if' `in'
if `df'>1 {
	cap drop I__d0*
	qui frac_spl `lnt' `knots', name(I__d0) deg(3) bknots(`k0' `kN')
	local v `r(names)'
}
else {
	local v `lnt'
}
/*
	Time-varying coefficient or SE for variable `tvc'.
*/
if "`type'"=="tvc" {
	* check if `tvc' has a time-varying coefficient
	* (interaction with lnt, at least)
	cap matrix `c'=`coef'[1,"s0:`tvc'"]
	local hastvc=(_rc==0)
	if "`stdp'"=="" {
		* This could have been done in Genstvc via _predict.
		tempvar tmp
		qui gen double `tmp'=[xb]_b[`tvc'] `if' `in'
		if `hastvc' {
			local i 0
			while `i'<`df' {
				local i1=`i'+1
				local svar: word `i1' of `v'
				matrix `c'=`coef'[1,"s`i':`tvc'"]
				qui replace `tmp'=`tmp'+`c'[1,1]*`svar'
				local i `i1'
			}
		}
		gen `typ' `varn'=`tmp'
		lab var `varn' "TVC(`tvc')"
	}
	else {
		if `hastvc' {
			Genstvc `tvc' `se' "`v'" `"`if'"' `"`in'"'
			qui gen `typ' `varn'=`se'
		}
		else qui gen `typ' `varn'=[xb]_se[`tvc'] `if' `in'
		lab var `varn' "S.E. of TVC(`tvc')"
	}
	drop `v'
	exit
}
/*
	Calc fitted spline, allowing for stratification.
	First, compute spline coefficients (names in string coefn).
*/
tempvar Zhat
local i 0
while `i'<`df' {
	matrix `c'=`coef'[1,"s`i':"]		/* eqn for spline coeff i, 0=lin */
	local cn: colnames(`c')
	local nc=colsof(`c')			/* 1 + # strat vars */
	tempvar coef`i'
	qui gen double `coef`i''=`c'[1,`nc']	/* baseline coefficient */
	local j 1
	while `j'<`nc' {
		local changed 0
		local cnj: word `j' of `cn'
		local xval `cnj'
		if "`at'"!="" {
			local k 1
			while `k'<=`nat' & !`changed' {
				if "`cnj'"=="`atvar`k''" {
					local xval `atval`k''
					local changed 1
				}
				local k=`k'+1
			}
		}
		if `changed' | (!`changed' & "`zero'"=="") {
			qui replace `coef`i''=`coef`i''+`c'[1,`j']*`xval'
		}
		local j=`j'+1
	}
	local i=`i'+1
}
if "`type'"=="cumhazard" | "`type'"=="cumodds" | "`type'"=="normal" | "`type'"=="spline" {
	if "`type'"=="spline" {
		local varnlab "spline function"
	}
	else if "`type'"=="cumhazard" {
		local varnlab "log cumulative hazard function"
	}
	else if "`type'"=="cumodds" {
		if `theta'==1 {
			local varnlab "log cumulative odds function"
		}
		else {
			local varnlab "transformed survival function (theta = `theta')"
		}
	}
	else if "`type'"=="normal" {
		local varnlab "Normal deviate function"
	}
	if "`stdp'"!="" {
		if "`type'"!="`cscale'" & "`type'"!="spline" {
			noi di in red "standard errors not available with this combination of options"
			exit 198
		}
		Gense `se' "`v'" "`zero'" "`at'" `"`if'"' `"`in'"'
		gen `typ' `varn'=`se'
		lab var `varn' "S.E. of `varnlab'"
		drop `v'
		exit
	}
}
qui gen double `Zhat'=`XB' if `lnt'!=.
local i 0
while `i'<`df' {
	local i1=`i'+1
	local svar: word `i1' of `v'
	qui replace `Zhat'=`Zhat'+`coef`i''*`svar'
	local i `i1'
}
if "`type'"=="cumhazard" | "`type'"=="cumodds" | "`type'"=="normal" | "`type'"=="spline" {
	if "`type'"=="spline" {
		local expr `Zhat'
	}
	else if "`type'"=="cumhazard" {
		if e(scale)==0 {
			local expr `Zhat'
		}
		else if e(scale)==1 {
			local expr ln(-ln(normprob(-`Zhat')))
		}
		else if e(scale)==2 {
			local expr -ln(`theta')+ln(ln(1+exp(`theta'*`Zhat')))
		}
	}
	else if "`type'"=="cumodds" {
		if e(scale)==0 {
			local expr ln(exp(exp(`Zhat'))-1)
		}
		else if e(scale)==1 {
			local expr ln(1/normprob(-`Zhat')-1)
		}
		else if e(scale)==2 {
			if `theta'==1 {
				local expr `Zhat'
			}
			else {
				local expr ln((1+exp(`theta'*`Zhat'))^(1/`theta')-1)
			}
		}
	}
	else if "`type'"=="normal" {
		if e(scale)==0 {
			local expr -invnorm(exp(-exp(`Zhat')))
		}
		else if e(scale)==1 {
			local expr `Zhat'
		}
		else if e(scale)==2 {
			if `theta'==1 {
				local expr -invnorm(1/(1+exp(`Zhat')))
			}
			else {
				local expr -invnorm((1+exp(`theta'*`Zhat'))^(-1/`theta'))
			}
		}
	}
	gen `typ' `varn'=(`expr')
	lab var `varn' "Predicted `varnlab'"
	drop `v'
	exit
}
* Compute dZdy via first derivatives of basis functions
if `df'>1 {
	cap drop I__e0*
	frac_s3b `lnt', k(`knots') bknots(`k0' `kN') name(I__e0)
	local o `r(names)'
}
tempvar dZdy
local i 0
while `i'<`df' {
	if `i'==0 {
		qui gen double `dZdy'=`coef`i''
	}
	else {
		local ovar: word `i' of `o'
		qui replace `dZdy'=`dZdy'+`coef`i''*`ovar'
	}
	local i=`i'+1
}
if `df'>1 { drop `o' }
if "`dzdy'"!="" {
	gen `typ' `varn'=`dZdy'
	lab var `varn' "Spline first derivative"
	exit
}
if e(scale)==0 {
	local surv exp(-exp(`Zhat'))
	local haz `dZdy'*exp(`Zhat'-`lnt')
	local dens (`haz')*(`surv')
}
else if e(scale)==1 {
	local surv normprob(-`Zhat')
	local dens `dZdy'*normd(`Zhat')/`time'
	local haz (`dens')/(`surv')
}
else if e(scale)==2 {
	local surv (1+exp(`theta'*`Zhat'))^(-1/`theta')
	local dens `dZdy'*exp(`theta'*`Zhat'-`lnt')*(`surv')^(1+`theta')
	local haz (`dens')/(`surv')
}
if "`type'"=="hazard" {
	gen `typ' `varn'=(`haz')
	lab var `varn' "Predicted hazard function"
}
else if "`type'"=="survival" {
	gen `typ' `varn'=(`surv')
	lab var `varn' "Predicted survival function"
}
else if "`type'"=="density" {
	gen `typ' `varn'=(`dens')
	lab var `varn' "Predicted density function"
}
end

program define Gense
/*
	Collapse equations for predicting SE.
	If sbasis is null then calculations are for index, otherwise spline.
*/
args se sbasis zero at if in
local nat 0
if "`at'"!="" {
	tokenize `at'
	while "`1'"!="" {
		unab 1: `1'
		local nat=`nat'+1
		local atvar`nat' `1'
		local atval`nat' `2'
		mac shift 2
	}
}
tempname btmp Vtmp
matrix `btmp'=e(b)
matrix `Vtmp'=e(V)
local ncovar: word count `e(fvl)'
local coefn
if "`sbasis'"!="" {	/* spline + index */
	local df=e(df)
	local stratif `e(strat)'
	local nstrat: word count `stratif'
	if "`stratif'"=="" {
		local coefn `sbasis'
	}
	else {
		local j 1
		while `j'<=`df' {
			local basis: word `j' of `sbasis'
			local i 1
			while `i'<=`nstrat' {
				local changed 0
				local x: word `i' of `stratif'
				local xval `x'
				if "`at'"!="" {
					local k 1
					while `k'<=`nat' & !`changed' {
						if "`basis'"=="`atvar`k''" {
							local xval `atval`k''
							local changed 1
						}
						local k=`k'+1
					}
				}
				if !`changed' & "`zero'"!="" {
					local xval 0
				}
				tempvar v`j'`i'
				gen double `v`j'`i''=`xval'*`basis' `if' `in'
				local coefn `coefn' `v`j'`i''
				local i=`i'+1
			}
			local coefn `coefn' `basis'
			local j=`j'+1
		}
	}
}
else {		/* index only */
	matrix `btmp'=`btmp'[1,"xb:"]
	matrix `Vtmp'=`Vtmp'["xb:","xb:"]
}
* Deal with at & zero in index
if "`at'`zero'"=="" {
	local coefn `coefn' `e(fvl)'
}
else {
	local j 1
	while `j'<=`ncovar' {	/* ncovar could be 0, then no looping */
		local changed 0
		local covar: word `j' of `e(fvl)'
		if "`at'"!="" {
			local k 1
			while `k'<=`nat' & !`changed' {
				if "`covar'"=="`atvar`k''" {
					local xval `atval`k''
					local changed 1
				}
				local k=`k'+1
			}
		}
		if !`changed' & "`zero'"!="" {
			local xval 0
			local changed 1
		}
		if `changed' {
			tempvar v`j'
			gen double `v`j''=`xval' `if' `in'
			local coefn `coefn' `v`j''
		}
		else local coefn `coefn' `covar'
		local j=`j'+1
	}
}
local coefn `coefn' _cons
matrix colnames `btmp'=`coefn'
matrix colnames `btmp'=_:
matrix colnames `Vtmp'=`coefn'
matrix colnames `Vtmp'=_:
matrix rownames `Vtmp'=`coefn'
matrix rownames `Vtmp'=_:
tempname tmp
estimates hold `tmp'
estimates post `btmp' `Vtmp'
_predict double `se' `if' `in', stdp
estimates unhold `tmp'
end

program define Genstvc
/*
	Compute SE of time-varying coefficient for covariate `tvc'.

	For model with spline degree m (i.e. df=m+1), and `tvc' = z1, this is SE of
	beta_z1   + gamma_11*x + gamma_21*v_1(x) +...+ gamma_m+1,1*v_m(x), i.e.
	[xb]_b[z1]+[s0]_b[z1]*x+[s1]_b[z1]*v_1(x)+...+[sm]_b[z1]*v_m(x).

	Done by creating coeff and VCE matrix and posting them, then _predict, stdp.
*/
args tvc se sbasis if in
tempname btmp Vtmp c
matrix `btmp'=e(b)
matrix `Vtmp'=e(V)
local df=e(df)
* Create equation for TVC via "interactions of basis functions with 1".
* Build required coefficient matrix and VCE matrix "manually" (ugh).
local B
local V
local j 1
while `j'<=`df' {
	* extract relevant coefficient from overall coeff matrix
	local j1=`j'-1
	matrix `c'=`btmp'[1,"s`j1':`tvc'"]
	local cc=`c'[1,1]
	local B `B' `cc'

	* loop to extract j'th row of VC matrix into Vrow.
	local Vrow
	local k 1
	while `k'<=`df' {
		local k1=`k'-1
		matrix `c'=`Vtmp'["s`j1':`tvc'", "s`k1':`tvc'"]
		local cc=`c'[1,1]
		local Vrow `Vrow' `cc'
		local k=`k'+1
	}
	matrix `c'=`Vtmp'["s`j1':`tvc'", "xb:`tvc'"]
	local cc=`c'[1,1]
	local Vrow `Vrow' `cc'

	* update VCE matrix (string form)
	local V `V' `Vrow' \

	local j=`j'+1
}
* term for constant (relevant coefficient is [xb]_b[`tvc'])
matrix `c'=`btmp'[1,"xb:`tvc'"]
local cc=`c'[1,1]
local B `B' `cc'

* loop to extract [xb] row of VC matrix into Vrow.
local Vrow
local k 1
while `k'<=`df' {
	local k1=`k'-1
	matrix `c'=`Vtmp'["xb:`tvc'", "s`k1':`tvc'"]
	local cc=`c'[1,1]
	local Vrow `Vrow' `cc'
	local k=`k'+1
}
matrix `c'=`Vtmp'["xb:`tvc'", "xb:`tvc'"]
local cc=`c'[1,1]
local Vrow `Vrow' `cc'

* update VCE matrix (string form)
local V `V' `Vrow'

* Assign and post
matrix input `btmp'=(`B')
matrix input `Vtmp'=(`V')

local vn `sbasis' _cons
matrix colnames `btmp'=`vn'
matrix colnames `btmp'=_:
matrix colnames `Vtmp'=`vn'
matrix colnames `Vtmp'=_:
matrix rownames `Vtmp'=`vn'
matrix rownames `Vtmp'=_:

tempname tmp
estimates hold `tmp'
estimates post `btmp' `Vtmp'
_predict double `se' `if' `in', stdp
estimates unhold `tmp'
end
