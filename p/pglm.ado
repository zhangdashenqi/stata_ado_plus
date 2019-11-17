*! 1.0.0 Anirban Basu 18Oct 2005
program define pglm, eclass
	version 8.0

	if replay() {
		syntax [, Level(integer $S_level)]

		if `level' < 10 | `level' > 99 {
			di as err "level() must be between 10 and 99 inclusive"
			exit 198
		}
		
		if "`e(cmd)'" != "pglm" { 
			exit 301 
		}
		if _by() { 
			exit 190 
		} 
	
		
		if "e(varfunc)" == "Quadratic" {
			noi di in gr _n _n "Extended GEE with Quadratic Variance Function" /*
			*/	in gr _col(50) "No of obs	=	" in ye e(N)
			noi di in smcl in gr "Optimization: "   in ye "Fisher's Scoring"  /*
			*/	in gr _col(50) "Residual df	=	" in ye e(df)

			noi di in smcl in gr _n "Variance:     " in ye "(theta1*mu + theta2*mu^2)"
		}
		else {
			noi di in gr _n _n "Extended GEE with Power Variance Function" /*
			*/	in gr _col(50) "No of obs	=	" in ye e(N)
			noi di in smcl in gr "Optimization: "   in ye "Fisher's Scoring"  /*
			*/	in gr _col(50) "Residual df	=	" in ye e(df)

			noi di in smcl in gr _n "Variance:     " in ye "(theta1*mu^theta2)"
		}
		noi di in smcl in gr "Link:	    " in ye "(mu^lambda - 1)/lambda"
		noi di in smcl in gr "Std Errors:   " in ye "Robust" _n
		
		noi Display, level(`level') 
		exit
		
	}

	syntax [varlist(min=2)] [if] [in] [fweight pweight iweight aweight /]/*
		*/  [,INITLambda(real 0) power(real 99) CONVergence (real 0.0001)   /*
		*/  Level(integer $S_level) ITERation(integer 500) CLuster(varname)  /*
		*/  FAMily(string) VF(string)] 


gettoken (local) y_var (local) xlist : varlist	
marksample touse

qui count if `touse'
	if r(N) == 0 {
		error 2000
	}
local nobs = r(N)

if `level' < 10 | `level' > 99 {
	di as err "level() must be between 10 and 99 inclusive"
	exit 198
}

quietly {

******************Get Initial Values****************************
tempname lmd the1 the2

if "`vf'" =="q" { 	/* IF QUADRATIC VARIANCE IS REQUESTED */
	if `initlambda' != . & `initlambda' !=0 {
		glm `y_var' `xlist' `if' `in' , family(gamma) link(power `initlambda')
		tempvar pred yhat lnerr2 lnyhat2 new
		predict `pred' if `touse',xb
		gen double `yhat' = (`pred')^(1/`initlambda') if `touse'
		gen double `new' =  (`pred'-1)/(`initlambda') if `touse'
		reg `new' `xlist' if `touse'
		mat po=e(b)
		tempvar mu xb
		gen double `xb'= `pred' if `touse'
		gen double `mu'= `yhat' if `touse'
		scalar `lmd' = `initlambda'
	}
	else {
		glm `y_var' `xlist' if `touse', family(gamma) link(log)
		mat po=e(b)
		tempvar pred yhat lnerr2 lnyhat2 
		predict `pred' if `touse',xb
		gen double `yhat' = exp(`pred') if `touse'
		tempvar mu xb
		gen double `xb'= `pred' if `touse'
		gen double `mu'= `yhat' if `touse'
		scalar `lmd' = 0.1
	}
	tempvar yhat2 err2
	gen double `yhat2' = `yhat'^2 if `touse'
	gen double `err2' = ((`y_var'-`yhat')^2) if `touse'
	reg `err2'  `yhat' `yhat2' if `touse', nocons
	scalar `the1' =_b[`yhat']
	scalar `the2' = _b[`yhat2']


}
else if "`vf'" != "" { 	/* IF UNIDENTIFIED VARIANCE IS REQUESTED */
	di as error "Unidentified Variance function"
	exit 198
}
else {		   	/* IF POWER VARIANCE IS REQUESTED */

	if `initlambda' != . & `initlambda' !=0 {
		glm `y_var' `xlist' if `touse', family(gamma) link(power `initlambda')
		tempvar pred yhat lnerr2 lnyhat2 new
		predict `pred' if `touse',xb
		gen double `yhat' = (`pred')^(1/`initlambda') if `touse'
		gen double `new' =  (`pred'-1)/(`initlambda') if `touse'
		reg `new' `xlist' if `touse'
		mat po=e(b)
		tempvar mu xb
		gen double `xb'= `pred' if `touse'
		gen double `mu'= `yhat' if `touse'
		scalar `lmd' = `initlambda'
	}
	else {
		glm `y_var' `xlist' if `touse', family(gamma) link(log)
		mat po=e(b)
		tempvar pred yhat lnerr2 lnyhat2
		predict `pred' if `touse',xb
		gen double `yhat' = exp(`pred') if `touse'
		tempvar mu xb
		gen double `xb'= `pred' if `touse'
		gen double `mu'= `yhat' if `touse'
		scalar `lmd' = 0.1
	}
	gen double `lnerr2' = ln((`y_var'-`yhat')^2) if `touse'
	gen double `lnyhat2' = ln(`yhat') if `touse'
	reg `lnerr2' `lnyhat2' if `touse'
	scalar `the1' = exp(_b[_cons])
	scalar `the2'=_b[`lnyhat2']

} /* end of vf clause */


*********************Set Initial Values ************************
mat ancparm = ( `lmd' \ `the1' \ `the2' )
mat rowname ancparm = lambda:_cons theta1:_cons theta2:_cons
mat bo = po' \ ancparm
mat try=po

local xn_ = colsof(try)
matrix drop try
local xn_1 = `xn_' + 1
local xn_2 = `xn_' + 2
local xn_3 = `xn_' + 3


tempvar  one_
quietly gen double `one_'=1 if `touse'

local pctdev=100
mat G = J(`xn_3', 1, 0)
mat V = J(`xn_3', `xn_3', 0)


******************INITIALIZE TEMP VARIABLES*********************

tempvar  var dmudlam dmudthe1 dmudthe2 dvdlam dvdthe1 dvdthe2 glam gthe1 gthe2 /*
*/	gbl  gt1l gt1t1 gt1t2 stddev glam2 g2the1 g2the2

gen double `var'=0 if `touse'
gen double `stddev'=0 if `touse'
gen double `dmudlam'=0 if `touse'
gen double `dmudthe1'=0 if `touse'
gen double `dmudthe2'=0 if `touse'
gen double `dvdlam'=0 if `touse'
gen double `dvdthe1'=0 if `touse'
gen double `dvdthe2'=0 if `touse'
gen double `glam'=0 if `touse'
gen double `gthe1'=0 if `touse'
gen double `gthe2'=0 if `touse'
gen double `gbl'=0 if `touse'
gen double `gt1l'=0 if `touse'
gen double `gt1t1'=0 if `touse'
gen double `gt1t2'=0 if `touse'


forvalues i=1(1)`xn_' {
	tempvar dmud`i' dvd`i' gb`i' g2b`i' gt1b`i' 
	gen double `dmud`i''= 0 if `touse'
	gen double `dvd`i''=0 if `touse'
	gen double `gb`i''=0 if `touse'
	gen double `gt1b`i''=0 if `touse'
}

forvalues i=1(1)`xn_' {
 	tempvar egb`i'
 	gen double `egb`i''= 0 if `touse'
}



tempvar sumv w  

if "`weight'" != "" {

	if ("`weight'" == "fweight" |"`weight'" == "iweight") {
		gen double `w'=`exp' if `touse'
	}
	else if ("`weight'" == "pweight" ) {	
	egen `sumv'=sum(`exp') if `touse'
	gen double `w'=`exp'/`sumv' if `touse'
	}
	else if ("`weight'" == "aweight") {	
	egen `sumv'=mean(`exp') if `touse'
	gen double `w'=`exp'/`sumv' if `touse'
	}

}
else {
gen double `w'=1 if `touse'
}




if "`family'" != "" & "`vf'" == "" {

	if substr(upper("`family'"),1,3) == "POW"  {
		if `power' == 99 {
			di as error "Please specify the value of power with power()"
			exit 198
		}
		mat bo[`xn_3',1]= `power'
	}
	else if substr(upper("`family'"),1,3) == "GAU"  {
		if `power' != 99 {
			noi di in ye "NOTE: power() option ignored"
		}

		mat bo[`xn_3',1]= 0
	}

	else if substr(upper("`family'"),1,3) == "POI"  {
		if `power' != 99 {
			noi di in ye "NOTE: power() option ignored"
		}

		mat bo[`xn_3',1]= 1
	}
	else if substr(upper("`family'"),1,3) == "GAM"  {
		if `power' != 99 {
			noi di in ye "NOTE: power() option ignored"
		}

		mat bo[`xn_3',1]= 2
	}
	else if substr(upper("`family'"),1,3) == "IGA"  {
		if `power' != 99 {
			noi di in ye "NOTE: power() option ignored"
		}

		mat bo[`xn_3',1]= 3
	}
	else {
	 di as error "Unrecognized family"
	 exit 198
	}
	
}

if "`family'" != "" & "`vf'" == "q" {

	if substr(upper("`family'"),1,3) == "POI"  {
		mat bo[`xn_3',1]= 0
	}
	else {
	 di as error "Family not allowed with quadratic variance function"
	exit 198
	}
}


if "`vf'" == "q" & `power' != 99 {

	di as error "Combination of vf(q) and power() not allowed"
	exit 198
}

********************** START OPTIMIZATION ************************

local counter_= 1
while (`pctdev' > `convergence' & `counter_' < `iteration' ) {


	if `counter_' > 1 {

		tempvar xb
		mat score `xb' = po if `touse'
		replace `mu' = exp((1/bo[`xn_1',1])*ln(`xb'*bo[`xn_1',1] + 1))  if `touse'
		replace `mu'=0 if ((`xb'*bo[`xn_1',1]+1) < = 0) & `touse'
	}


	/* Calcualate variance for each observation */

	if "`vf'" != "" {
		replace `var' = ((bo[`xn_2',1]*`mu') + (bo[`xn_3',1]*(`mu'^2))) if `touse'
	}
	else {
		replace `var' = (bo[`xn_2',1]*(`mu'^bo[`xn_3',1])) if `touse'
	}

	replace `stddev'=sqrt(`var') if `touse'


	/* Create vector of first derivatives */

	tokenize `xlist'
	forvalues i=1(1)`xn_' {
		local `xn_' "`one_'"
		replace `dmud`i''= (`mu'^(1-bo[`xn_1',1]))*``i''  if `touse'
	}

	replace `dmudlam'= (`mu'/bo[`xn_1',1])*((`xb'/`mu'^(bo[`xn_1',1]))-ln(`mu')) if `touse'
	replace `dmudthe1' = 0 if `touse'
	replace `dmudthe2' = 0 if `touse'

	tokenize `xlist'
	forvalues i=1(1)`xn_' {
		local `xn_' "`one_'"
		if "`vf'" != "" {
			replace `dvd`i''=(bo[`xn_2',1] + 2*bo[`xn_3',1]*`mu')*`dmud`i'' if `touse'
		}
		else {
			replace `dvd`i''=(bo[`xn_2',1]*bo[`xn_3',1]*(`mu'^(bo[`xn_3',1]-1)))*`dmud`i'' if `touse'
		}
	}

	if "`vf'" != "" {
		replace `dvdlam'= (bo[`xn_2',1] + 2*bo[`xn_3',1]*`mu')*`dmudlam' if `touse'
		replace `dvdthe1' = `mu' if `touse'
		replace `dvdthe2' = (`mu'^2) if `touse'
	}
	else {
		replace `dvdlam'= (bo[`xn_2',1]*bo[`xn_3',1]*(`mu'^(bo[`xn_3',1]-1)))*`dmudlam' if `touse'
		replace `dvdthe1' = (`mu'^bo[`xn_3',1]) if `touse'
		replace `dvdthe2' = `var'*ln(`mu') if `touse'
	}

	/* Create G vector */

	local gblist=""
	tokenize `xlist'
	forvalues i=1(1)`xn_' {
		local `xn_' "`one_'"
		replace `gb`i'' = ((`y_var' - `mu')*`dmud`i'')/(`var') if `touse'
		local gblist = "`gblist' `gb`i''" 
	}

	replace `glam' =  ((`y_var' - `mu')*`dmudlam')/(`var') if `touse'
	replace `gthe1' =  (((`y_var' - `mu')^2) - `var')*`dvdthe1'/(`var'^2) if `touse'
	replace `gthe2' =  (((`y_var' - `mu')^2) - `var')*`dvdthe2'/(`var'^2) if `touse'

	mat vecaccum G=`one_' `gblist' `glam' `gthe1' `gthe2' if `touse', nocons
	mat G=G/_N
	mat G=G'


	/* Create Expected Info matrix */
	/* Calculating E( - dg(b)/dparm) */

	local gblist=""
	tokenize `xlist'
	forvalues i=1(1)`xn_' {
 		local `xn_' "`one_'"
 		replace `egb`i'' = (`dmud`i'')/(`stddev') if `touse'
 		local gblist="`gblist' `egb`i'' "
	}


	replace `gbl' = (`dmudlam')/(`stddev') if `touse'

	mat accum V1= `gblist' `gbl' if `touse', nocons
	mat V1a = J(`xn_1',2,0) 
	mat V1b=V1,V1a


	/* Calculating E( - dg(theta21)/dparm) */

	local gblist=""
	tokenize `xlist'
	forvalues i=1(1)`xn_' {
		local `xn_' "`one_'"
		replace `gt1b`i'' = (`dvd`i'')/(`var') if `touse'
		local gblist="`gblist' `gt1b`i''" 
	}


	replace `gt1l' = (`dvdlam')/(`var') if `touse'
	replace `gt1t1' = (`dvdthe1')/(`var') if `touse'
	replace `gt1t2' = (`dvdthe2')/(`var') if `touse'

	mat accum V2= `gblist' `gt1l' `gt1t1' `gt1t2' if `touse', nocons
	mat V2a = V2[1..`xn_3', `xn_2'..`xn_3']
	mat V2b = V2a' 

	mat V=V1b\V2b
	mat V=V/_N

	matrix drop V1 V1a V1b V2a V2b
	macro drop `xb'


********** UPDATE PARAMETER VECTOR *********
if "`vf'" != "" {
	if "`family'" != "" & substr(upper("`family'"),1,3) == "POI" {

	mat bo[`xn_3',1]= 0
	mat G[`xn_3',1]= 0

	mat bnew=bo[1..`xn_2',.]
	mat gnew=G[1..`xn_2',.]
	mat vnew=V[1..`xn_2',1..`xn_2']
	mat pnew = inv(vnew)*gnew + bnew
	mat parm=bo
		local k=1
		while `k' <= `xn_2' { 
		mat parm[`k',1] = pnew[`k',1]
		local k=`k' +1
		}
 
	}

	else {

	mat extra=inv(V)
	mat parm = inv(V)*G + bo
	}

} /* End of first vf clause */
else  {

	if "`family'" != "" & substr(upper("`family'"),1,3) == "POW" {

	mat bo[`xn_3',1]= `power'
	mat G[`xn_3',1]= 0

	mat bnew=bo[1..`xn_2',.]
	mat gnew=G[1..`xn_2',.]
	mat vnew=V[1..`xn_2',1..`xn_2']
	mat pnew = inv(vnew)*gnew + bnew
	mat parm=bo
		local k=1
		while `k' <= `xn_2' { 
		mat parm[`k',1] = pnew[`k',1]
		local k=`k' +1
		}
	}

	else if "`family'" != "" & substr(upper("`family'"),1,3) == "GAU" {

	mat bo[`xn_3',1]= 0
	mat G[`xn_3',1]= 0

	mat bnew=bo[1..`xn_2',.]
	mat gnew=G[1..`xn_2',.]
	mat vnew=V[1..`xn_2',1..`xn_2']
	mat pnew = inv(vnew)*gnew + bnew
	mat parm=bo
		local k=1
		while `k' <= `xn_2' { 
		mat parm[`k',1] = pnew[`k',1]
		local k=`k' +1
		}
	}
	else if "`family'" != "" & substr(upper("`family'"),1,3) == "POI" {

	mat bo[`xn_3',1]= 1
	mat G[`xn_3',1]= 0

	mat bnew=bo[1..`xn_2',.]
	mat gnew=G[1..`xn_2',.]
	mat vnew=V[1..`xn_2',1..`xn_2']
	mat pnew = inv(vnew)*gnew + bnew
	mat parm=bo
		local k=1
		while `k' <= `xn_2' { 
		mat parm[`k',1] = pnew[`k',1]
		local k=`k' +1
		}
	}

	else if "`family'" != "" & substr(upper("`family'"),1,3) == "GAM" {

	mat bo[`xn_3',1]= 2
	mat G[`xn_3',1]= 0

	mat bnew=bo[1..`xn_2',.]
	mat gnew=G[1..`xn_2',.]
	mat vnew=V[1..`xn_2',1..`xn_2']
	mat pnew = inv(vnew)*gnew + bnew
	mat parm=bo
		local k=1
		while `k' <= `xn_2' { 
		mat parm[`k',1] = pnew[`k',1]
		local k=`k' +1
		}
	}

	else if "`family'" != "" & substr(upper("`family'"),1,3) == "IGA" {

	mat bo[`xn_3',1]= 3
	mat G[`xn_3',1]= 0

	mat bnew=bo[1..`xn_2',.]
	mat gnew=G[1..`xn_2',.]
	mat vnew=V[1..`xn_2',1..`xn_2']
	mat pnew = inv(vnew)*gnew + bnew
	mat parm=bo
		local k=1
		while `k' <= `xn_2' { 
		mat parm[`k',1] = pnew[`k',1]
		local k=`k' +1
		}
	}

	else {

	mat extra=inv(V)
	mat parm = inv(V)*G + bo
	}

} /* end of var caluse */


	mat dev = parm-bo
	mat den_ = dev'*inv(diag(bo))
	matewmf den_ pctdev, function(abs)
	matvsort pctdev pctdev, decrease
	local reldev = `pctdev'-pctdev[1,1]
	local pctdev = pctdev[1,1]

	if (`counter_' >1 & `reldev' > 0) | `counter_' ==1 {

		mat parm = dev + bo
		mat bo=parm
		mat po = bo[1..`xn_',1..1]'
		drop `xb'
 
		noi di in gr "Iter: " in ye `counter_' in gr " Max % Diff: " in ye `pctdev'  in gr  /*
		*/ " Rel Diff: " in ye `reldev'

		local counter_ = `counter_' +1
	}

	else {
	mat parm = (0.5*dev) + bo
	mat bo=parm
	mat po = bo[1..`xn_',1..1]'
	drop `xb'
	noi di in gr "Half step applied. Reset Max % Diff" 
	}


} /* End of iterations */

**************************** END OPTIMIZATION ***************************
*********** UPDATE PARAMETER FROM THE LAST ITERATION AND ****************
****************** CALCULATE FINAL VAR_COV MATRIX ***********************


if `counter_' >= `iteration' {
      di as error "Increase iteration number with iter()"
	exit 198
}


tempvar xb
mat score `xb' = po if `touse'
replace `mu' = exp((1/bo[`xn_1',1])*ln(`xb'*bo[`xn_1',1] + 1))  if `touse'
replace `mu'=0 if ((`xb'*bo[`xn_1',1]+1) < = 0) & `touse'
 

/* CREATE LOCAL XLIST */
local xlist_=""
local xlist2_=""
local eqlist_=""
local xname_=""
tokenize `xlist'
forvalues i=1(1)`xn_' {
	local `xn_' "`one_'"
	local xlist2_ "`xlist2_' `g2b`i'' "
	local xlist_ "`xlist_' `gb`i'' "
	local eqlist_ "`eqlist_' `y_var'"
}


tokenize `xlist'
local xn__1 = (`xn_' -1)
forvalues i=1(1)`xn__1' {
	local xname_ " `xname_' ``i''"
}
local xname_ " `xname_' _cons"


/* Calculate variance for each observation */

if "`vf'" != "" {
	replace `var' = ((bo[`xn_2',1]*`mu') + (bo[`xn_3',1]*(`mu'^2))) if `touse'
}
else {
	replace `var' = (bo[`xn_2',1]*(`mu'^bo[`xn_3',1])) if `touse'
}

replace `stddev'=sqrt(`var') if `touse'


/* Create vector of first derivatives */
tokenize `xlist'
forvalues i=1(1)`xn_' {
local `xn_' "`one_'"
	replace `dmud`i''= (`mu'^(1-bo[`xn_1',1]))*``i'' if `touse'
}

replace `dmudlam'= (`mu'/bo[`xn_1',1])*((`xb'/`mu'^(bo[`xn_1',1]))-ln(`mu')) if `touse'
replace `dmudthe1' = 0 if `touse'
replace `dmudthe2' = 0 if `touse'


tokenize `xlist'
forvalues i=1(1)`xn_' {
local `xn_' "`one_'"
if "`vf'" != "" {
	replace `dvd`i''=(bo[`xn_2',1] + 2*bo[`xn_3',1]*`mu')*`dmud`i'' if `touse'
}
else {
	replace `dvd`i''=(bo[`xn_2',1]*bo[`xn_3',1]*(`mu'^(bo[`xn_3',1]-1)))*`dmud`i'' if `touse'
}
}

if "`vf'" != "" {
	replace `dvdlam'= (bo[`xn_2',1] + 2*bo[`xn_3',1]*`mu')*`dmudlam' if `touse'
	replace `dvdthe1' = `mu' if `touse'
	replace `dvdthe2' = (`mu'^2) if `touse'
}
else {
	replace `dvdlam'= (bo[`xn_2',1]*bo[`xn_3',1]*(`mu'^(bo[`xn_3',1]-1)))*`dmudlam' if `touse'
	replace `dvdthe1' = (`mu'^bo[`xn_3',1]) if `touse'
	replace `dvdthe2' = `var'*ln(`mu') if `touse'
}


/* Create G vector */

local gblist ""
tokenize `xlist'
forvalues i=1(1)`xn_' {
local `xn_' "`one_'"
	replace `gb`i'' = ((`y_var' - `mu')*`dmud`i'')*`w'/(`var') if `touse'
	local gblist "`gblist' `gb`i''" 
}

replace `glam' =  ((`y_var' - `mu')*`dmudlam')*`w'/(`var') if `touse'
replace `gthe1' =  (((`y_var' - `mu')^2) - `var')*`dvdthe1'*`w'/(`var'^2) if `touse'
replace `gthe2' =  (((`y_var' - `mu')^2) - `var')*`dvdthe2'*`w'/(`var'^2) if `touse'


mat vecaccum G=`one_' `gblist' `glam' `gthe1' `gthe2' if `touse', nocons
mat G=G/_N
mat G=G'



/* Create Expected Info matrix */
/* Calculating E( - dg(b)/dparm) */

local gblist ""
tokenize `xlist'
forvalues i=1(1)`xn_' {
 	local `xn_' "`one_'"
 	replace `egb`i'' = (`dmud`i'')*sqrt(`w')/(`stddev') if `touse'
 	local gblist "`gblist' `egb`i'' "
}

replace `gbl' = (`dmudlam')*sqrt(`w')/(`stddev') if `touse'

mat accum V1= `gblist' `gbl' if `touse', nocons
mat V1a = J(`xn_1',2,0)
mat V1b=V1,V1a


/* Calculating E( - dg(theta21)/dparm) */

local gblist ""
tokenize `xlist'
forvalues i=1(1)`xn_' {
	local `xn_' "`one_'"
	replace `gt1b`i'' = (`dvd`i'')*sqrt(`w')/(`var') if `touse'
	local gblist "`gblist' `gt1b`i''" 
}

replace `gt1l' = (`dvdlam')*sqrt(`w')/(`var') if `touse'
replace `gt1t1' = (`dvdthe1')*sqrt(`w')/(`var') if `touse'
replace `gt1t2' = (`dvdthe2')*sqrt(`w')/(`var') if `touse'

mat accum V2= `gblist' `gt1l' `gt1t1' `gt1t2' if `touse', nocons
mat V2a = V2[1..`xn_3', `xn_2'..`xn_3']
mat V2b = V2a' 

mat V=V1b\V2b
mat V=V

matrix drop V1 V1a V1b V2a V2b

**************** CALCULATE ROBUST VARIANCE ****************************
if "`cluster'" !="" {

	sort `cluster'
	forvalues i=1(1)`xn_' {
		egen `g2b`i'' = sum(`gb`i'') if `touse', by(`cluster')
		by `cluster': replace `g2b`i''=0 if _n !=_N & `touse'
	}


	egen `glam2' = sum(`glam') if `touse', by(`cluster')
	by `cluster': replace `glam2'=0 if _n !=_N & `touse'
	egen `g2the1' = sum(`gthe1') if `touse', by(`cluster')
	by `cluster': replace `g2the1'=0 if _n !=_N & `touse'
	egen `g2the2' = sum(`gthe2') if `touse', by(`cluster')
	by `cluster': replace `g2the2'=0 if _n !=_N & `touse'


	qui tab `cluster'
	local M_=r(r)
	if "`family'" != "" {
		mat accum Gnew = `xlist2_' `glam2' `g2the1' if `touse', deviations nocons
		mat Vnew = V[1..`xn_2',1..`xn_2']
		mat Var =inv(Vnew'*syminv(Gnew/(_N-1))*Vnew)*_N
		mat V1a = J(`xn_2',1,0)
		mat V2a = J(1,`xn_3',0)
		mat Var = Var, V1a
		mat Var = Var \ V2a
		matrix drop V1a V2a Vnew
	}
	else {
		mat accum Gnew = `xlist2_' `glam2' `g2the1' `g2the2' if `touse', deviations nocons
		mat Var =inv(V'*syminv(Gnew/(`M_'-1))*V)*`M_'
	}
}
else {

	if "`family'" != "" {
		mat accum Gnew = `xlist_' `glam' `gthe1' if `touse', deviations nocons
		mat Vnew=V[1..`xn_2',1..`xn_2']
		mat Var =inv(Vnew'*syminv(Gnew/(_N-1))*Vnew)*_N
		mat V1a = J(`xn_2',1,0)
		mat V2a = J(1,`xn_3',0)
		mat Var = Var, V1a
	
		mat Var = Var \ V2a
		matrix drop V1a V2a Vnew
	}
	else {
		mat accum Gnew = `xlist_' `glam' `gthe1' `gthe2' if `touse', deviations nocons
		mat Var =inv(V'*syminv(Gnew/(_N-1))*V)*_N
	}
}



******************** DISPLAY RESULTS **********************************

mat parmt= parm'
mat colnames parmt = `xname_' _cons _cons _cons
mat coleq parmt = `eqlist_' lambda theta1 theta2
mat rownames Var = `xname_' _cons _cons _cons
mat colnames Var = `xname_' _cons _cons _cons
mat roweq Var = `eqlist_' lambda theta1 theta2
mat coleq Var = `eqlist_' lambda theta1 theta2

est clear
ereturn post parmt Var, depname("`y_var'") obs(`nobs')  esample(`touse')
ereturn local depvar "`y_var'"
ereturn local cmd "pglm"
ereturn local xlist "`xlist'"
ereturn local lambda=_b[lambda:_cons]
ereturn local theta1=_b[theta1:_cons]
ereturn local theta2=_b[theta2:_cons]
ereturn local lambda_se=_se[lambda:_cons]
ereturn local theta1_se=_se[theta1:_cons]
ereturn local theta2_se=_se[theta2:_cons]
ereturn local wttype "`weight'"

if "`vf'" != "" {
	ereturn local varfunc "Quadratic"
}
else {
	ereturn local varfunc "Power"
}
ereturn local clustervar "`cluster'"
ereturn local k= `xn_3'
ereturn local df= `nobs' - `xn_3'
est store pglm

} /* End for quietly */

/* Display Header */

if "`vf'" != "" {
	noi di in gr _n _n "Extended GEE with Quadratic Variance Function" /*
	*/	in gr _col(50) "No of obs	=	" in ye `nobs'
	noi di in smcl in gr "Optimization: "   in ye "Fisher's Scoring"  /*
	*/	in gr _col(50) "Residual df	=	" in ye `nobs' -`xn_3'
}

else {
	noi di in gr _n _n "Extended GEE with Power Variance Function" /*
	*/	in gr _col(50) "No of obs	=	" in ye `nobs'
	noi di in smcl in gr "Optimization: "   in ye "Fisher's Scoring"  /*
	*/	in gr _col(50) "Residual df	=	" in ye `nobs' -`xn_3'
}

if "`weight'" !="" {
	noi di in smcl in gr _n "[""`weight'""]     " in ye "`exp'"
}

if "`cluster'" !="" {
	noi di in smcl in gr _n "No. of Clusters (`cluster'): " in gr `M_'
}

if "`vf'" != "" {
	noi di in smcl in gr _n "Variance:     " in ye "(theta1*mu + theta2*mu^2)"
}
else {
	noi di in smcl in gr _n "Variance:     " in ye "(theta1*mu^theta2)"
}
noi di in smcl in gr "Link:	    " in ye "(mu^lambda - 1)/lambda"
noi di in smcl in gr "Std Errors:   " in ye "Robust" _n


Display, level(`level') 

matrix drop ancparm bo po parm V  
end


program define Display
	syntax [, Level(integer $S_level) ]

ereturn display,  level(`level')

end






