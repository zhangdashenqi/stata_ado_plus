
program define robivreg, eclass
version 10.0
	local n 0
	gettoken lhs 0 : 0, parse(" ,[") match(paren)
	IsStop `lhs'
	if `s(stop)' { 
		error 198 
	}  
	while `s(stop)'==0 {
		if "`paren'"=="(" {
			local n = `n' + 1
			if `n'>1 {
				capture noi error 198
di as error `"syntax is "(all instrumented variables = instrument variables)""'
				exit 198
			}
			gettoken p lhs : lhs, parse(" =")
			while "`p'"!="=" {
				if "`p'"=="" {
					capture noi error 198
di as error `"syntax is "(all instrumented variables = instrument variables)""'
di as error `"the equal sign "=" is required"'
					exit 198
				}
				local end`n' `end`n'' `p'
				gettoken p lhs : lhs, parse(" =")
			}
			tsunab end`n' : `end`n''
			tsunab exog`n' : `lhs'
		}
		else {
			local exog `exog' `lhs'
		}
		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
	}
	local 0 `"`lhs' `0'"'

	tsunab exog : `exog'
	tokenize `exog'
	local lhs "`1'"
	local 1 " "
	local exog `*'
	
	// Eliminate vars from `exog1' that are in `exog'
	Subtract inst : "`exog1'" "`exog'"
	
	// `lhs' contains depvar, 
	// `exog' contains RHS exogenous variables, 
	// `end1' contains RHS endogenous variables, and
	// `inst' contains the additional instruments

	// Now parse the remaining syntax

local dv `lhs'
local expl `exog'
local endog `end1'
syntax [anything(name=0)] [if] [in], [Generate(string) test first raw robust cluster(varname) graph label(varlist) nreps(real 50) NODots cutoff(real 0.99) mcd]

tempvar out touse weight weight2 res resi c ca d ivreg2 rho psi u res res0 xhat w mad u0 res00 tempmad tempu
tempname a b b0 weight20 c c2 id id2 COV coefS A V c d mu


mark `touse' `if' `in'

if `cutoff'>0.999|`cutoff'<0.01 {
di in r "The cut-off value should be within the interval [0.01,0.999]"
exit 198
}

qui count if `touse'
local N=r(N)
local detS=1e25


local detS0=0
local detS=1e+25
gen `weight20'=0
gen `b0'=0
qui reg `dv' `expl' `inst' `endog'

	foreach var of local expl {
		cap assert `var' == 0 | `var' == 1 if e(sample)
		if _rc==0 {
		unab dummex: `dummex' `var'
		}
	}

	foreach var of varlist `inst' {
		cap assert `var' == 0 | `var' == 1 if e(sample)
		if _rc==0 {
		unab dumminst: `dumminst' `var'
		}
	}

local inst: list inst -dumminst
local expl: list expl -dummex
local ndum: word count `dummex' `dumminst'

capture qui drop `a' `b'
capture qui drop `res'*
capture qui drop `c'
capture qui drop `d'


if "`cluster'"!=""&"`raw'"!="" {
di in r "The -cluster- option is not available for the raw estimator"
error 198
exit
}

if "`first'"!=""&"`raw'"!="" {
di in r "The -first- option is not available for the raw estimator"
error 198
exit
}
capture qui {



if "`dumminst'"!=""& "`dummex'"==""{

foreach var of varlist `dv' `expl' `inst' `endog' {

capture rreg `var' `dumminst' if `touse'

if e(r2)!=. {
tempvar res`var'
predict `res`var'', res
local finvar "`finvar' `res`var''"
}

}

qui hadimvo2 `finvar'  if `touse', gen(`c' `d')
if "`mcd'"=="" {
smultiv `finvar'  if `touse' & `c'==0, nreps(1) gen(`a' `b')
}

else {
mcd `finvar' if `c'==0&`touse'==1, outlier
rename Robust_distance `b'
rename MCD_outlier `a'
}


}

if "`dummex'"!=""&"`dumminst'"=="" {

foreach var of varlist `dv' `expl' `inst' `endog' {
capture rreg `var' `dummex' if `touse'
if e(r2)!=. {
tempvar res`var'
predict `res`var'', res
local finvar "`finvar' `res`var''"
}
}

qui hadimvo2 `finvar'  if `touse', gen(`c' `d')
if "`mcd'"=="" {
smultiv `finvar'  if `touse' & `c'==0, nreps(1) gen(`a' `b')
}

else {
mcd `finvar' if `c'==0&`touse'==1, outlier
rename Robust_distance `b'
rename MCD_outlier `a'
}
}

if "`dummex'"!=""&"`dumminst'"!="" {

foreach var of varlist `dv' `expl' `inst' `endog' {
capture rreg `var' `dumminst' `dummex' if `touse'
if e(r2)!=. {
tempvar res`var'
predict `res`var'', res
local finvar "`finvar' `res`var''"
}
}

qui hadimvo2 `finvar'  if `touse', gen(`c' `d')
if "`mcd'"=="" {
smultiv `finvar'  if `touse' & `c'==0, nreps(1) gen(`a' `b')
}

else {
mcd `finvar' if `c'==0&`touse'==1, outlier
rename Robust_distance `b'
rename MCD_outlier `a'
}
}

if "`dummex'"==""&"`dumminst'"=="" {
capture qui hadimvo2 `expl' `endog' `inst' `dv' if `touse', gen(`c' `d')
if "`mcd'"=="" {
smultiv `expl' `endog' `inst' `dv'  if `touse' & `c'==0, nreps(1) gen(`a' `b')
}

else {
mcd `expl' `endog' `inst' `dv' if `c'==0&`touse'==1, outlier
rename Robust_distance `b'
rename MCD_outlier `a'
}
}


}

matrix `mu'=e(mu)

local v=colsof(`mu')

local c=`v'*(sqrt((1/9)*(2/`v'))*(1.546)+(1-(1/9)*(2/`v')))^3
local c=sqrt(`c')

capture drop `rho'
capture drop `psi'
capture drop `weight2'


qui gen `rho'=((`b'^2)/2-(`b'^4)/(2*`c'^2)+(`b'^6)/(6*(`c'^4)))*(abs(`b')<=`c')+((`c'^2)/6)*(abs(`b')>`c') if `touse'
qui gen `psi'=(6/(`c'^2))*(`b'*(1-(`b'/`c')^2)^2)*(abs(`b'<`c')) if `touse'
qui gen `weight2'=`psi'/`b' if `touse'


qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') [aweight=`weight2'] if `touse',   small `first'

local detS0=e(rmse)

if `detS0'<`detS' {
capture qui replace `weight20'=`weight2'
capture qui replace `b0'=`b'
local detS=`detS0'

}

di ""
qui replace `weight2'=`weight20'
qui replace `b'=`b0'
local c=sqrt(invchi2(`v',`cutoff'))
qui gen `c2'=`c'/`b'
qui replace `c2'=1 if `c2'>1&`b'!=.

qui gen `weight'=(`c2'==1) if `touse'


if "`raw'"=="" {

ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') [aweight=`weight'] if `touse',   small `first' `robust' cluster(`cluster')
tempname AA
est store `AA'
}


else {

qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') [aweight=`weight2'] if `touse',   small `robust' cluster(`cluster')
tempname AA
est store `AA'
matrix `coefS'=e(b)
matrix V=e(V)
ereturn post `coefS' V


qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') [aweight=`weight2'] if `touse',   small `robust' cluster(`cluster')
local dv=e(depvar)

capture qui predict `res', res

qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') if `touse', `robust' cluster(`cluster')
capture qui predict `res0', res


foreach var of varlist `endog' {
qui reg `var' `inst' `dumminst' `expl' `dummex' [aweight=`weight2'] if `touse'
capture qui predict `xhat'`var', xb
}

tempname b
foreach var of varlist `endog' {
qui reg `var' `inst' `dumminst' `expl' `dummex' if `touse'
capture qui predict `b'`xhat'`var' if `touse', xb
}

qui mm_ivtest `dv' `xhat'* `expl' `dummex' if `touse', wgt(`weight2') resiv(`res') resiv2(`res0') varlist2(`dv' `b'`xhat'* `expl' `dummex')

qui est restore `AA'
ereturn repost V=SCOV
ereturn display
}



if "`generate'"!="" {
	tokenize `"`generate'"'
	local nw: word count `generate'

	if `nw'==1 {  
		local marker `1'
		confirm new var `marker'
	}

	else {
	di in r "define one variable in option generate"
	exit 198
	}
	tempvar weight4
	gen `weight4'=1-round(`weight')
	rename `weight4' `marker'
	
}

if "`graph'"!="" {
	if "`label'"!=""{
	local lab="`label'"
	}
	else {
	local lab="`ord'"
	}
	
qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') [aweight=`weight2'] if `touse',   small
tempvar resg RD RD0
qui predict `resg' if `touse', res
qui rreg `resg'
qui replace `resg'=`resg'/e(rmse)

if "`mcd'"=="" {
capture qui smultiv `expl' `endog' `inst' if `touse', gen(`RD0' `RD')
}

else {
mcd `expl' `endog' `inst' if `weight'==1&`touse'==1, outlier
rename Robust_distance `RD'
rename MCD_outlier `RD0'
}


local k2=rowsof(r(S))

label var `resg' "Robust standardised residuals"
label var `RD' "Robust Mahalanobis distances"

local b=sqrt(invchi2(`k2',`cutoff'))

twoway (scatter `resg' `RD' if abs(`resg')<4&`RD'<sqrt(2)*`b') (scatter `resg' `RD' if abs(`resg')>=4|`RD'>=2*`b', mlabel(`lab') msymbol(circle_hollow)), xline(`b') yline(2.25) yline(-2.25) legend(off)

}

if "`test'"!="" {

qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') [aweight=`weight2'] if `touse',   small `first'
local dv=e(depvar)


capture qui predict `res', res

qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') if `touse'
capture qui predict `res0', res


foreach var of varlist `endog' {
qui reg `var' `inst' `dumminst' `expl' `dummex' [aweight=`weight2'] if `touse'
capture qui predict `xhat'`var', xb
}

tempname b
foreach var of varlist `endog' {
qui reg `var' `inst' `dumminst' `expl' `dummex' if `touse'
local df=e(df_m)+1
capture qui predict `b'`xhat'`var' if `touse', xb
}

if "`cluster'"!="" {

qui reg `dv' `expl' `dummex' `endog' if `touse'
qui ivreg2 `dv' `expl' `dummex' (`endog'=`inst' `dumminst') if `touse'
matrix BB1=e(b)
local pp=colsof(BB1)

qui ivregress 2sls `dv' `expl' `dummex' (`endog'=`inst' `dumminst') [aweight=`weight2'] if `touse'
matrix BB2=e(b)
di ""
di ""
di in r "Test with clustered errors"
di "--------------------------"
noi di""

if "`nodots'"=="" {
noi di ""
nois _dots `i' 0, title(bootstrap replicates) reps(`nreps')
noi di ""
}

forvalues i=1(1)`nreps' {

preserve
bsample, cluster(`cluster')
tempvar ba bb

if "`mcd'"=="" {
capture qui smultiv `dv' `expl' `endog' `inst' if `weight'==1, gen(`ba' `bb') nreps(1)
}

else {
capture qui mcd `dv' `expl' `endog' `inst' if `weight'==1, outlier
rename Robust_distance `bb'
rename MCD_outlier `ba'
}

tempname mu 
tempvar rho psi weight2
matrix `mu'=e(mu)

local v=colsof(`mu')

local c=`v'*(sqrt((1/9)*(2/`v'))*(1.546)+(1-(1/9)*(2/`v')))^3
local c=sqrt(`c')

capture drop `rho'
capture drop `psi'
capture drop `weight2'


qui gen `rho'=((`bb'^2)/2-(`bb'^4)/(2*`c'^2)+(`bb'^6)/(6*(`c'^4)))*(abs(`bb')<=`c')+((`c'^2)/6)*(abs(`bb')>`c') if `touse'
qui gen `psi'=(6/(`c'^2))*(`bb'*(1-(`bb'/`c')^2)^2)*(abs(`bb'<`c')) if `touse'
qui gen `weight2'=`psi'/`bb' if `touse'

capture qui  _rmcollright (`dv' `expl' `dummex') (`endog') (`inst' `dumminst') [aweight=`weight2'] if `touse'
local lhs=r(block1)
local rhs1=r(block2)
local rhs2=r(block3)

qui ivregress 2sls `lhs' (`rhs1'=`rhs2') [aweight=`weight2'] if `touse'
matrix BBB2=e(b)

qui ivregress 2sls `lhs' (`rhs1'=`rhs2') if `touse'
matrix BBB1=e(b)

restore

if (colsof(BBB1)!=colsof(BBB2))|(colsof(BBB1)!=colsof(BB1)){
matrix BB1=(BB1)
matrix BB2=(BB2)
if "`nodots'"=="" {
nois _dots `i' 1
}
}

else {
matrix BB1=(BB1\BBB1)
matrix BB2=(BB2\BBB2)
if "`nodots'"=="" {
nois _dots `i' 0
}
}

}



matrix D=BB1-BB2
matrix D0=D[1,1...]
matrix D=D[2...,1...]
mata: D=st_matrix("D")
mata: D0=st_matrix("D0")
mata: W=D0*invsym((variance(D)))*D0'
mata: st_matrix("Wcl",W)
local Wstat_cl=Wcl[1,1]
local df0=colsof(D)
local p0=chi2(`df0',`Wstat_cl')
local p0=1-round(`p0',.001)

di ""
di in y ""
di "H0: Outliers do not distort 2SLS classical estimation"
di "-----------------------------------------------------"
di ""
display "chi2(" `df0' ")=" round(`Wstat_cl',0.01)
display "Prob > chi2 = " `p0'


qui estimates restore `AA'

ereturn scalar Wstat_cl=round(`Wstat_cl',0.01)
ereturn scalar Wstatp_cl=`p0'




}

else {
mm_ivtest `dv' `xhat'* `expl' `dummex' if `touse', wgt(`weight2') resiv(`res') resiv2(`res0') varlist2(`dv' `b'`xhat'* `expl' `dummex')
local Wstat=e(Wstat)
local pWstat=e(pWstat)

qui estimates restore `AA'
ereturn scalar Wstat=`Wstat'
ereturn scalar Wstatp=`pWstat'
}

}



end

program define mm_ivtest, eclass

version 10.0

if replay()& "`e(cmd)'"=="mm_ivtest" {
	ereturn  display
exit
}


syntax varlist [if] [in] , resiv(varlist) resiv2(varlist) wgt(varlist) varlist2(varlist)

tempvar rand yres touse finsamp u u0 w rho weight res stdres ru continuous tempconst tempes tempem tempu tempmad tempccx
tempname mad mad2 bestmad mrho scale eps maxit err v A B B1 B2 coefS  nvar1 ord A 
local nvar: word count `varlist'

gen `ord'=_n
/* includes constant implicitly by counting depvar */

mark `touse' `if' `in'
markout `touse' `varlist'
markout `touse' `resiv'
markout `touse' `resiv2'

qui count if `touse'

local dv: word 1 of `varlist'
local expl: list varlist - dv

capture qui  _rmcollright (`varlist')  [aweight=`wgt'] if `touse'
local varlist=r(block1)
local exexog: list varlist - dv

capture qui reg `dv' `exexog' [aweight=`wgt'] if `touse' 

matrix `B1'=e(b)

capture drop `u'
qui gen `u'=`resiv'

qui sum `u', detail

qui rreg `u'
local scale=e(rmse)

qui gen `tempes'=`u'*`scale'
qui gen `ru'=`u'

scalar `eps'=1e-20
scalar `maxit'=1000
scalar `nvar1'=`nvar'-1
local mad=`scale'

_rmcollright `varlist2' [aweight=`wgt'] if `touse'
capture qui reg `r(varlist)' if `touse'
gen `tempconst'=1
local N=e(N)

matrix `B2'=e(b)

qui gen `tempem'=`resiv2'
capture drop `stdres'
qui gen `stdres'=`resiv2'/`mad' if `resiv2'!=.
qui gen `tempu'=`stdres'
qui gen `tempmad'=`scale'
qui matrix `coefS'=e(b)

local tempconsti="`tempconst'"
local tempesi="`tempes'"
local tempemi="`tempem'"
local tempui="`tempu'"
local tempmadi="`tempmad'"
mata: tstatb("`dv'","`exexog'","`tempconsti'","`tempesi'", "`tempemi'","`tempui'","`tempmadi'","`touse'")

tempname DIFFCOEF W
matrix `DIFFCOEF'=`B1'-`B2'
matrix DIFFCOEF=`DIFFCOEF'
matrix `W'=`DIFFCOEF'*inv(VARDIFF)*(`DIFFCOEF'')
local W=`W'[1,1]
ereturn scalar Wstat=`W'

local df=`nvar'

local p=chi2(`df',`W')
local p=1-round(`p',.001)
ereturn local pWstat=`p'
di""
di "H0: Outliers do not distort 2SLS classical estimation"
di "-----------------------------------------------------"
di ""
display "chi2(" `df' ")=" round(`W',0.01)
display "Prob > chi2 = " `p'
end

version 10.0
mata:
void tstatb(string scalar dv, string scalar exexog, string scalar tempconsti, string scalar tempesi, string scalar tempemi, string scalar tempui, string scalar tempmadi, string scalar touse)

{
st_view(X=.,.,tokens(dv),touse)
st_view(EX=.,.,tokens(exexog),touse)

st_view(ONE=.,.,tokens(tempconsti), touse)
st_view(u=.,.,tokens(tempui), touse)
st_view(sc=.,.,tokens(tempmadi), touse)
st_view(es=.,.,tokens(tempesi), touse)
st_view(em=.,.,tokens(tempemi), touse)

X=(X,EX)



s=sc[1,1]
n=rows(X)


X=(X,ONE)

k0=cols(X)
w=1

psi=w:*u:*2
dpsi=w:*2

rho0=(u:^2:/(2):*(1:-(u:^2:/(1.5468906^2)):+(u:^4/(3*1.5468906^4)))):*w:+(1:-w):*(1.5468906^2/6)
drho0=w:*u:*(1:-(u:/1.5468906):^2):^2
ddrho0=w:*(1:-u:^2:*(6/1.5468906^2:-5:*u:^2:/1.5468906^4))

X=X[.,(2..k0)]
k=cols(X)

h1=dpsi*J(1,k,1)  
h1=h1:*X
EdpsiXX=(1/n)*X'*h1
h1=ddrho0*J(1,k,1)
h1=h1:*X;
Eddrho0XX=(1/n)*X'*h1
EdpsiXem=(1/n)*(dpsi:*em)'*X
Eddrho0Xes=(1/n)*(ddrho0:*es)'*X
Edrho0es=(1/n)*drho0'*es

A=(-1/s)*(EdpsiXX,EdpsiXem',J(k,k,0)\J(1,k,0),Edrho0es,J(1,k,0)\J(k,k,0),Eddrho0Xes',Eddrho0XX)
iA=luinv(A)
h1=psi*J(1,k,1)
h0=drho0*J(1,k,1)
rho005=rho0:-0.5*J(n,1,1)

G2=(h1:*X,rho005,h0:*X)

h2=psi*J(1,k,1)  
G=X:*h2
B2=(1/n)*G2'*G2
B=(1/n)*G'*G
h3=invsym(EdpsiXX)
cov1=(1/n)*iA*B2*iA'
cov1s
cov1m=cov1[1..k,1..k]
cov1ms=cov1[1..k,k+2..cols(cov1)]
cov1s=cov1[k+2..cols(cov1),k+2..cols(cov1)]
cov1=cov1[1..k,1..k]
vardiff=cov1s+cov1m-2*cov1ms

st_matrix("VARDIFF",vardiff)
st_matrix("SCOV",cov1s)
st_matrix("MMCOV",cov1s)
st_matrix("MMCOVASYM",cov1)

st_matrix("cov1s",cov1s)
st_matrix("cov1m",cov1m)
st_matrix("cov1ms",cov1ms)
}

end

// Borrowed from hadimvo.ado	
program hadimvo2, rclass
	version 6, missing
	syntax varlist [if] [in], Generate(string) [ P(real .05) dummies(varlist)]

	tokenize `"`generat'"'
	if `"`3'"'!="" { error 198 }
	local marker `1'
	local Dvar `2'		/* may be null */
	confirm new var `marker' `Dvar'

	if (`p'>=1) { local p=`p'/100 }
	if (`p'<=0 | `p'>=1) { 
		noi di in red "p() invalid"
		exit 198
	}

	marksample touse
	tokenize `varlist'

	tempvar u new D D0 gen
	
	quietly gen `gen' = 0 if `touse'
	label var `gen' `"Hadi outlier (p=`p')"'

	* quietly { 
		gen `u'=uniform() if `touse'
	
		reg `u' `varlist' `dummies' if `touse'

		if e(N)==0 | e(N)>=. { noisily error 2001 }
		local N=e(N)

		local i 1
		while `"``i''"'!="" { 
			if _b[``i'']==0 { 
				noi di in blu /*
		      */ `"(note:  ``i'' dropped because of collinearity)"'
				local `i' " "
			}
			local i=`i'+1
		}
		tokenize `*'

		if 3*(`i'-1)+1 >= `N' { 		/* i-1 = k */
			noi di in red "sample size of " `N' /* 
			*/ " <= 3k+1 (k=" `i'-1 ", 3k+1=" 3*(`i'-1)+1 ")"
			exit 2001
		}

		noi di in gr _n "Beginning number of observations:  " /* 
			*/ in ye %12.0f `N'

		noi di in gr _col(15) "Initially accepted:  " _c

		_rmcollright (`varlist') (`dummies') if `touse'
		local varlist="`r(block1)'"
		tokenize `"`varlist'"'
		
		if `N'<100 {
		set seed 123
		smultiv  `varlist' if `touse', gen(`D0' `D') nreps(10000)
		}
		
		else {
		smultiv  `varlist' if `touse', gen(`D0' `D')
		}
		
		sort `D'			/* missing to end	*/

		_rmcollright `varlist' `dummies' if `touse'
		local varlist="`r(varlist)'"
		local k: word count `varlist'
		local r = `k'+1
		noi di /* init accepted */ in ye %12.0f `r'



/* Steps 2 and 3 */
		noi di in gr _col(14) "Expand to (n+k+1)/2:  " _c
		_maked `D' `touse' `r' `u' `"`varlist'"'
		while `r'<int((`N'+`k'+1)/2) {
			local r=`r'+1
			_maked `D' `touse' `r' `u' `"`varlist'"'
		}
		noi di in ye %12.0g `r'

/* step 4 */
		local msg `"Expand,  p = `p':  "'
		local len = 36 - length(`"`msg'"')
		noi di in gr _col(`len') `"`msg'"' _c
		local cf=( 1+2/(`N'-1-3*`k')+(`k'+1)/(`N'-`k') )^2
		_maked `D' `touse' `r' `u' `"`varlist'"'
		replace `D'=`D'/`cf'

		local chi2 = (invchi2(`k',0.99))
		while `D'[`r'+1]<`chi2' {
			if `N'==`r'+1 { 
				noi di in ye %12.0g `N'
				noi di in gr _col(15) "Outliers remaining:  " /*
					*/ in ye %12.0g 0
				ret scalar N = 0 
				if `"`Dvar'"'!="" {
					label var `D' `"Hadi distance (p=`p')"'
					rename `D' `Dvar'
				}
				rename `gen' `marker'
				exit
			}
			local r=`r'+1
			_maked `D' `touse' `r' `u' `"`varlist'"'
			replace `D'=`D'/`cf'
		}
		
		noi di in ye %12.0g `r'
		local r=`r'+1
		replace `gen'=1 if `touse' & `D'>=`chi2'
		count if `gen'==1
		noi di in gr _col(15) /*
		*/ "Outliers remaining:  " in ye %12.0g r(N)
		ret scalar N = r(N)
		if `"`Dvar'"'!="" {
			replace `D'=sqrt(`D')
		
			label var `D' `"Hadi distance (p=`p')"'
			rename `D' `Dvar'
		}
		rename `gen' `marker'
	*}

end

// Borrowed from hadimvo.ado	
program _maked /* D touse r lhs rhs */
	args D touse r u rhs

	capture drop `D'
	reg `u' `rhs' if `touse' in 1/`r'
	_predict `D' if `touse', hat
	replace `D'=(`r'-1)*(`D'-(1/`r'))
	sort `D'			/* missing to end	*/
end

// Borrowed from ivreg.ado	
program define IsStop, sclass

	if `"`0'"' == "[" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else {
		sret local stop 0
	}

end

// Borrowed from ivreg.ado	
program define Subtract   /* <cleaned> : <full> <dirt> */

	args        cleaned     /*  macro name to hold cleaned list
		*/  colon       /*  ":"
		*/  full        /*  list to be cleaned
		*/  dirt        /*  tokens to be cleaned from full */

	tokenize `dirt'
	local i 1
	while "``i''" != "" {
		local full : subinstr local full "``i''" "", word all
		local i = `i' + 1
	}

	tokenize `full'                 /* cleans up extra spaces */
	c_local `cleaned' `*'

end





exit
