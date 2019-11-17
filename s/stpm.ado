*! version 1.0.4 PR 04Dec2001.  (TSJ-2: st0001.1)
program define stpm, eclass
version 6
if trim(`"`0'"')=="" {
	if "`e(cmd2)'"!="stpm" { error 301 }
	ml display
	di in gr "Deviance = " %9.3f in ye e(dev)
	exit
}
st_is 2 analysis
syntax [varlist(default=none)] [if] [in], SCale(string) [ BKnots(string) /*
 */ DF(int 0) Index(string) Knots(string) LBASis(string) LEft(varname) ML(string) /*
 */ OBASis(string) PREfix(string) SBASis(string) STratify(varlist) SUff(string) /*
 */ EBASis(string) Unique SPline(varlist) OFFset(varname) noCONStant THeta(string) /*
 */ noLOg ]

* key st chars

local id: char _dta[st_id]
local wt: char _dta[st_wt]      /* type of weight */
if "`wt'"!="" {
	di in red "weights not supported"
	exit 198
}
local time _t
local dead _d
if `df'>0 & "`spline'"!="" {
	di in gr "[df() ignored since spline() specified]"
}
if "`stratif'"!="" {
	local nstrat: word count `stratif'
}
local Scale `scale'
local scale=lower("`scale'")
local l=length("`scale'")
if "`scale'"==substr("hazard",1,`l') {
	local scale 0/* ln cumulative hazard scale */
}
else if "`scale'"==substr("normal",1,`l') {
	local scale 1/* cumulative Normal scale */
}
else if "`scale'"==substr("odds",1,`l') {
	local scale 2/* log odds scale */
}
else {
	di in red "invalid scale(`Scale')"
	exit 198
}
if "`scale'"!="2" & "`theta'"!="" {
	di in gr "[theta ignored, only applies to scale(odds)]"
	local theta
}
local th_est 0
if "`theta'"!="" {
	if lower(substr("`theta'",1,3))=="est" {
		local th_est 1
	}
	else {
		confirm num `theta'
	}
}
global S_H=("`scale'"=="0")
global S_L=("`scale'"=="2")
/*
	If sbasis is specified, then the spline basis is provided in it and
	knots and boundary knots are not needed. The model dimension (df) is
	derived from sbasis. obasis() is needed too if df>1.
*/
local hasbas=("`sbasis'"!="")
if `hasbas' {
	if `df'>1 | "`knots'"!="" | "`bknots'"!="" {
		di in red "df(), knots() and bknots() invalid with sbasis()"
		exit 198
	}
	local df: word count `sbasis'
	if `df'>1 {
		local obdf: word count `obasis'
		if (`df'-`obdf')!=1 {
			noi di in red "invalid obasis()"
			exit 198
		}
	}
}
else {
	if "`knots'"!="" {
		if `df'>0 {
			di in red "cannot specify both df() and knots()"
			exit 198
		}
		local knots=trim("`knots'")
		local kf=lower(substr("`knots'",1,1))
		if "`kf'"=="%" | "`kf'"=="u" | "`kf'"=="l" {
			local knots=substr("`knots'",2,.)
			if "`kf'"=="%" {
				local pct `knots'
				local nk: word count `knots'
			}
			else if "`kf'"=="u" {     /* U[a,b] knots distribution */
				tokenize `knots'
				confirm integer number `1'
				confirm number `2'
				confirm number `3'
				local nk `1'
				local a=`2'/100
				local b=`3'/100
				local pct
				local i 1
				while `i'<=`nk' {
					local P=100*(`a'+(`b'-`a')*uniform())
					frac_ddp `P' 2
					local pct `pct' `r(ddp)'
					local i=`i'+1
				}
				listsort "`pct'"
				local pct `s(list)'
				}
				else if "`kf'"=="l" {     /* convenience log transformation */
				local nk: word count `knots'
				tokenize `knots'
				local knots
				local i 1
				while `i'<=`nk' {
					local knot=ln(``i'')
					noisily confirm number `knot'
					frac_ddp `knot' 6
					local knots `knots' `r(ddp)'
					local i=`i'+1
				}
			}
		}
		else {
			local nk: word count `knots'
		}
		local df=1+`nk'
	}
	else if (`df'<1 | `df'>6) & "`spline'"=="" {
		di in red "option df(#) required, # must be between 1 and 6"
		exit 198
	}
}
if "`suff'"=="" { local suff _np }
if "`prefix'"=="" { local prefix "I__" }
quietly {
	marksample touse
	markout `touse' `varlist' `left' `stratif' `offset' `spline'
	replace `touse'=0 if _st==0   /* exclude obs excluded by -stset- */
	tempvar S Sadj Z Zhat t dZdy lnt0 lint
	gen double `t'=ln(`time') if `touse'
	if "`left'"!="" {
		confirm var `left'
		count if `touse'==1 & `left'!=. & `left'>`time'
		if r(N)>0 {
			noi di in red "`left'>`time' in some observations"
			exit 198
		}
	}
	count if `touse'
	local nobs=r(N)
	local d dead(`dead')
	tempname coef dev dof
	sum _t0 if `touse'
	if r(max)>0 {/* late entry */
		if "`left'"!="" {
			noi di in red "cannot have both interval censoring and late entry"
			exit 198
		}
		gen double `lnt0'=cond(_t0>0, ln(_t0), .) if `touse'
		local late 1
	}
	else local late 0
	stcox `varlist' if `touse', basechazard(`S') /* basesurv fails with late entry */
	replace `S'=exp(-`S')
	predict double `Sadj' if `touse', hr
	replace `Sadj'=`S'^`Sadj' if `touse'
	if $S_H {
		local fname "log cumulative hazard"
		gen double `Z'=ln(-ln(`Sadj'))
	}
	else if $S_L {
		local fname "log odds of failure"
		gen double `Z'=ln((1-`Sadj')/`Sadj')
	}
	else {
		local fname "Normal quantile"
		gen double `Z'=invnorm((`nobs'*(1-`Sadj')-3/8)/(`nobs'+1/4))
	}
	if "`offset'"!="" {
		replace `Z'=`Z'-`offset'
		global S_offset `offset'
	}
	else global S_offset
	if `hasbas' | "`spline'"!="" {
		local v `sbasis'
		if `df'>1 { local o `obasis' }
		else local o
	}
	else {
		cap drop `prefix'b`index'*
		if `df'==1 {
			local v `prefix'b`index'_0
			gen double `v'=`t'
		}
		else {
			local kk
			if "`bknots'"!="" {
				local k0: word 1 of `bknots'
				local kN: word 2 of `bknots'
				conf num `k0'
				conf num `kN'
				if "`k0'"=="" | "`kN'"=="" | `k0'>=`kN' {
					noi di in red "invalid bknots()"
					exit 198
				}
			}
			else {
				sum `t' if `dead'==1, meanonly
				local k0=r(min)
				local kN=r(max)
			}
			if "`knots'"!="" & "`pct'"=="" {
				tokenize `knots'
				local i 1
				while "``i''"!="" {
					local kk `kk' ``i''
					local i=`i'+1
				}
			}
			else {
				if "`pct'"=="" {
					if      `df'==2 { local pct 50 }
					else if `df'==3 { local pct 33 67 }
					else if `df'==4 { local pct 25 50 75 }
					else if `df'==5 { local pct 20 40 60 80 }
					else if `df'==6 { local pct 17 33 50 67 83 }
				}
				if "`unique'"!="" {
					tempvar tun
					sort `time'
					gen double `tun'=`t'
					by `time': replace `tun'=. if _n>1
					local tuse `tun'
				}
				else local tuse `t'
				listsort "`pct'"
				local pct `s(list)'
				_pctile `tuse' if `dead'==1, p(`pct')
				local nq: word count `pct'
				local i 1
				while `i'<=`nq' {
					local k=r(r`i')
					local kk `kk' `k'
					local i=`i'+1
				}
				if "`unique'"!="" { drop `tun' }
			}
			* Non-orthogonal basis functions
			frac_spl `t' `kk', name(`prefix'b`index') deg(3) bknots(`k0' `kN')
			local k `r(knots)'
			local v `r(names)'
			cap drop `prefix'c`index'*
			* First-derivative basis functions
			frac_s3b `t', k(`k') bknots(`k0' `kN') name(`prefix'c`index')
			local o `r(names)'
		}
	}
	tempname init xbinit
	if "`spline'"=="" {
		local spvars `v'
	}
	if "`varlist'"!="" {
		_rmcoll `varlist' if `touse'
		local vl `r(varlist)'
	}
	else local vl
	if "`varlist'"!="`vl'" {
		noi di in gr "[Note: collinearity detected, variable(s) removed from model]"

	}
	regress `Z' `spvars' `vl' if `dead'==1, `constan'
	matrix `coef'=e(b)
	if "`spline'"=="" {
		if "`stratif'"!="" {
			local j 1
			while `j'<=`df' {
				local bin 0
				local i 2
				while `i'<=`nstrat' {
					local bin "`bin',0"
					local i=`i'+1
				}
				local b=`coef'[1,`j']   /* spline coefficient */
				local bin `bin',`b'
				if `j'==1 { local sinit `bin' }
				else local sinit `sinit',`bin'
				local j=`j'+1
			}
			matrix `init'=(`sinit')
			if "`vl'"!="" {
				local x1: word 1 of `vl'
				matrix `xbinit'=`coef'[1,"`x1'"...]
			}
			else matrix `xbinit'=`coef'[1,"_cons"]
			matrix `init'=`init',`xbinit'
		}
		else matrix `init'=`coef'
	}
	else {	/* spline function given from outside */
		matrix `init'=`coef'
		local v: word 1 of `spline'/* fitted spline */
		local o: word 2 of `spline'/* first deriv */
	}
	if "`theta'"!="" & `th_est'==1 {      /* initial value for ln(theta) is 0 */
		matrix `init'=`init',0
	}
/*
	Use betas as initial values for ml
*/
	global S_dead `dead'
	global S_df `df'
	global S_sbasis `v'
	global S_obasis `o'
	global S_left ""
	global S_sb_t0 ""
	if "`left'"!="" {
		cap drop ML_ic
/*
	ML_ic:  -1 for interval censored obs (_d=1) with left boundary 0
				+1 for interval censored obs (_d=1) with left boundary >0

				 0 for point event-time or right-censored observation

*/
		gen byte ML_ic=0 if `touse'
		replace  ML_ic=1 if reldif(`left',`time')>5e-7 & `left'!=. & ML_ic!=.
		local intlate "(ML_ic==1 & _d==0)"
		replace  ML_ic=0 if `intlate' & `left'==0 /* treat as right-censored */
		count if `intlate'
		if r(N)>0 {
/*
	Conflict between interval- and right-censoring (left>0, _d=0).
	Such observations are treated as right-censored with late entry at `left'.

	However, DON'T change _t0 itself since that would conflict with original -stset-.

*/
			noi di in bl "[Note: " r(N) " non-zero left() observations /*
			 */ " for which _d=0 treated as late entry]"
			if `late'==0 {
				gen double `lnt0'=ln(`left') if `intlate'
				local late 1
			}
			else {
				replace `lnt0'=ln(`left') if `intlate'
			}
			replace ML_ic=0 if `intlate'
		}
		replace ML_ic=-1 if ML_ic==1 & `left'==0
/*
	Check if any genuine interval censored obs remain
*/
		count if abs(ML_ic)==1
		if r(N)>0 {
			if "`lbasis'"=="" {
				gen double `lint'=ln(`left') if ML_ic==1
				cap drop `prefix'b`index'l*
				if `df'==1 {
					local v0 `prefix'b`index'l_0
					gen double `v0'=`lint'
					global S_left `v0'
				}
				else {
					frac_spl `lint' `k', name(`prefix'b`index'l) /*
					 */ deg(3) bknots(`k0' `kN')
					global S_left `r(names)'
				}
				drop `lint'
			}
			else global S_left `lbasis'
		}
	}
	if `late' {
/*
	Note that dealing with late entry must following dealing with interval censoring,

	since interval censoring with _d=0 actually means late entry.
*/
		if "`ebasis'"=="" {
			cap drop `prefix'b`index't*
			if `df'==1 {
				local v0 `prefix'b`index't_0
				gen double `v0'=`lnt0'
				global S_sb_t0 `v0'
			}
			else {
				frac_spl `lnt0' `k', name(`prefix'b`index't) /*

				 */ deg(3) bknots(`k0' `kN')
				global S_sb_t0 `r(names)'
			}
		}
		else global S_sb_t0 `ebasis'
	}
	local nomodel 0
	if "`varlist'"=="" & "`constan'"=="noconstant" {
		local xbeq
		if "`spline'"!="" & `th_est'==0 {
			local nomodel 1	 /* no params to estimate */

		}
	}
	else {
		local xbeq "(xb:`varlist', `constan')"
	}
	local speq
	if "`spline'"=="" {
/*
	Define one equation per spline term in `t'
*/
		global S_spline 0
		local speq (s0:`time'=`stratif')
		local i 1
		while `i'<`df' {
			local speq `speq' (s`i':`stratif')
			local i=`i'+1
		}
	}
	else {
		global S_spline 1
	}
	if "`theta'"=="" {
		global S_theta ""
	}
	else {
		if `th_est' {
			global S_theta .
			local thetaeq (lntheta:)
		}
		else global S_theta `theta'
	}
	if `nomodel' {
/*
	Compute likelihood only, no estimation needed.
*/
		tempvar ll xb
		gen double `ll'=0 if `touse'
		gen double `xb'=0 if `touse'
		mlsurvlf `ll' `xb'
		sum `ll' if `touse', meanonly
		scalar `dev'=-2*r(sum)
		scalar `dof'=0
	}
	else {
		ml model lf mlsurvlf `speq' `xbeq' `thetaeq' if `touse'

/*
	Initial values
*/
		ml init `init', copy
		ml query
		noisily ml maximize, `ml' `log' noout
		capture test [xb]
		if !_rc {
			est scalar chi2 = r(chi2)
			est scalar p = r(p)
			est scalar df_m = r(df)
		}
		scalar `dev'=-2*e(ll)
		scalar `dof'=e(k)
		if "`left'"!="" { drop ML_ic }
		cap drop _ML*
		noisily ml display	/* !! PR bug fix */
	}
} /* end of quietly */
di in gr "Deviance = " %9.3f in ye `dev' in gr " (" in ye `nobs' in gr " observations.)"
if `scale'==0 {
	local cscale cumhazard
}
else if `scale'==1 {
	local cscale normal
}
else if `scale'==2 {
	local cscale cumodds
}
est scalar df=`df'
est scalar dev=`dev'
est scalar aic=`dev'+2*`dof'
est scalar n=`nobs'
est scalar k=`dof'
est scalar ll=-`dev'/2
est scalar scale=`scale'
est scalar nomodel=`nomodel'
if "`theta'"!="" {
	if `th_est' { est scalar theta=exp([lntheta]_b[_cons]) }
	else est scalar theta=`theta'
}
else est scalar theta=1
est local cscale `cscale'
est local knots `kk'
est local bknots `k0' `kN'
est local pct `pct'
est local fvl `vl'
est local strat `stratif'
est local left `left'
est local sbasis `v'
est local obasis `o'
est local lbasis $S_left
est local ebasis $S_sb_t0
est local offset `offset'
est local predict "stpm_p"
est local cmd2 stpm
end

*! version 1.0.0 PR 16Feb2001.
program define listsort, sclass
version 6
gettoken p 0 : 0, parse(" ,")
if `"`p'"'=="" {
	exit
}
sret clear
syntax , [ Reverse Lexicographic ]
local lex="`lexicog'"!=""
if "`reverse'"!="" { local comp < }
else local comp >
local np: word count `p'
local i 1
while `i'<=`np' {
	local p`i': word `i' of `p'
	if !`lex' { confirm number `p`i'' }
	local i=`i'+1
}
* Apply shell sort (Kernighan & Ritchie p 58)
local gap=int(`np'/2)
while `gap'>0 {
	local i `gap'
	while `i'<`np' {
		local j=`i'-`gap'
		while `j'>=0 {
			local j1=`j'+1
			local j2=`j'+`gap'+1
			if `lex' { local swap=(`"`p`j1''"' `comp' `"`p`j2''"') }

			else local swap=(`p`j1'' `comp' `p`j2'')

			if `swap' {
				local temp `p`j1''
				local p`j1' `p`j2''
				local p`j2' `temp'
			}
			local j=`j'-`gap'
		}
		local i=`i'+1
	}
	local gap=int(`gap'/2)
}
local p
local i 1
while `i'<=`np' {
	sret local i`i' `p`i''
	local p `p' `p`i''
	local i=`i'+1
}
sret local list `p'
end
