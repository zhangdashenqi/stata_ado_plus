* 1.8.3 TC 11 jun 2013 (bug fix for robust/cluster option when combined with orig and hat options)
* 1.8.2 TC 27 apr 2010 (added TSS to returned results)
* 1.8.1 TC 28 jan 2009
* Author: Thomas Cornelissen, University College London, UK
* Incorporates the grouping algorithm of Robert Creecy (original author), Lars Vilhuber (current author), Amine Ouazad (Stata port)
program define felsdvreg, eclass
version 9

syntax varlist(min=1) [if] [in], Ivar(varname) Jvar(varname) Feff(name) Peff(name) xb(name) Res(name) Mover(name) mnum(name) pobs(name) Group(name) [robust CLuster(varname) noadji noadjj cons takegroup NORMalize NOIsily CHOLsolve mem NOCOMPress hat(varlist) orig(varlist) feffse(name) grouponly ftest]
set more off

if wordcount("`varlist'")==1 & "`cons'"!="cons"{
	di in red "If you specify no explicit regressorr you must add the option 'cons'."
	exit(322)
	}

if "`takegroup'"=="takegroup" {
	confirm variable `group'
	}

if "`hat'"!="" | "`orig'"!="" {
if wordcount("`hat'")!=wordcount("`orig'"){
	di in red "Number of variables in option hat unequal to number in option orig."
	exit(322)
	}
}

timer clear
timer on 20
tempvar itemp jtemp jtemp2 miss sample n firmnum feffgbar f p pf gmax jmin moverp firm mnumcat cltemp
tempvar indid unitid /*Grouping*/
tempfile tempgroupfile tempdatafile /*Grouping*/

marksample touse
set varabbrev off

if "`grouponly'"=="grouponly" {
	felsdv_group `varlist' if `touse', i(`ivar') j(`jvar') g(`group') m(`mover')
	di in yellow "Note: You specified 'grouponly'. Only the group variable was modified and saved."
	di "      No estimates were produced."
	}
else {


*1. Selecting sample and checking for collinearity
*At this stage, collinearity between explicit regressors only is checked
timer on 1
qui egen `miss'=rowmiss(`varlist' `ivar' `jvar')
qui gen `sample'=0
qui replace `sample'=1 if `touse' & `miss'==0

capture drop `feff'
capture drop `feffse'
capture drop `peff'
capture drop `xb'
capture drop `res'
capture drop `mover'
capture drop `mnum'
capture drop `pobs'
if "`takegroup'"!="takegroup" {
	capture drop `group'
	}

tokenize "`varlist'"
local depvar "`1'"
_rmdcoll `varlist' if `sample'==1
local varlist `depvar' `r(varlist)'
tokenize "`varlist'"
local depvar "`1'"
mac shift
local indepvar "`*'"

if "`takegroup'"!="takegroup" {
	qui gen `group'=.
	}

qui gen `mover'=.
qui gen `n'=_n if `sample'==1
timer off 1

if "`nocompress'"!="nocompress" {
*2. Preserve dataset and compress data
timer on 2
preserve
qui keep if `sample'==1
qui keep `ivar' `jvar' `varlist' `orig' `sample' `n' `group' `cluster'
*Compressing data set. Use option 'nocompress' to avoid compressing
qui compress
timer off 2
}
else {
*2. Preserve dataset
timer on 2
preserve
qui keep if `sample'==1
qui keep `ivar' `jvar' `varlist' `orig' `sample' `n' `group' `cluster'
timer off 2
}



*3. Fit restricted models
*Fit restricted model without firm effects
if "`ftest'"=="ftest" {
	qui xtreg `varlist', i(`ivar') fe
	local rss_restf=`e(rss)'
	}

* Without both effects
timer on 3
qui reg `varlist'
mat b=e(b)
mat V=e(V)
local obs=e(N)
local rss_rest=`e(rss)'
local tss=`e(rss)'+`e(mss)'
ereturn clear
if "`cons'"!="cons" {
	mat b=b[1,1..colsof(b)-1]
	mat V=V[1..rowsof(V)-1,1..colsof(V)-1]
	}
ereturn post b V, obs(`obs')
ereturn scalar rss_rest=`rss_rest'
ereturn scalar tss=`tss'
if "`ftest'"=="ftest" {
	ereturn scalar rss_restf=`rss_restf'
	}
timer off 3

*4. Generate smooth firm and person ids
timer on 4
qui egen `itemp'=group(`ivar') if `sample'==1
qui egen `jtemp2'=group(`jvar') if `sample'==1
timer off 4

*5. Sort
timer on 5
sort `itemp' `jtemp2'
timer off 5

*6. Determine stayers and movers
timer on 6
qui by `itemp': gen byte `p'=1 if _n==1
qui by `itemp': gen `pobs'=_N
qui by `itemp' `jtemp2': gen `pf'=1 if _n==1
qui sum `pf'
if "`noisily'"=="noisily" {
	di in yellow _newline "Unique worker-firm combinations: " r(N)  _newline 
	}
by `itemp': egen `firmnum'=sum(`pf')
if "`noisily'"=="noisily" {
	 di "Number of firms workers are employed in:"
	label variable `firmnum' "Number of firms"
	tab `firmnum' if `p'==1
	}
gen `mover'=(`firmnum'>1)
label variable `mover' "Mover"
label variable `pobs' "Obs. per person"
if "`noisily'"=="noisily" {
	di  _newline "Number of movers (0=Stayer, 1=Mover):"
	tab `mover' if `p'==1
	di  _newline "Number of observations per person:"
	tab `pobs' if `p'==1
	}
qui bysort `jtemp2': egen `mnum'=sum(`mover')
qui bysort `jtemp2': gen `f'=1 if _n==1
if "`noisily'"=="noisily" {
	di _newline "Number of movers per firm:"
	qui gen `mnumcat'=0 if `mnum'==0
	qui replace `mnumcat'=1 if `mnum'>0 & `mnum'<=5
	qui replace `mnumcat'=2 if `mnum'>5 & `mnum'<=10
	qui replace `mnumcat'=3 if `mnum'>10 & `mnum'<=20
	qui replace `mnumcat'=4 if `mnum'>20 & `mnum'<=30
	qui replace `mnumcat'=5 if `mnum'>30 & `mnum'<=50
	qui replace `mnumcat'=6 if `mnum'>50 & `mnum'<=100
	qui replace `mnumcat'=7 if `mnum'>100
	label define `mnumcat' 0 "      0" 1 " 1-  5" 2 " 6- 10" 3 "11- 20" 4 "21- 30" 5 "31- 50" 6 "51- 100" 7 ">100"
	label values `mnumcat' `mnumcat'
	label variable `mnumcat' "Movers per firm"
	tab `mnumcat' if `f'==1
	}
qui sum `mnum'

if r(mean)==0 {
	di in red "There are no movers in the sample. No firm effects can be identified."
	error 322
	}
timer off 6

*Group firms without movers under artificial firm IDs
timer on 7
qui replace `jtemp2'=0 if `mnum'==0
qui egen `jtemp'=group(`jtemp2') if `sample'==1
qui drop `jtemp2'
timer off 7

if "`takegroup'"!="takegroup" {
*8. Determine number of groups
	timer on 8
	qui drop `group'
*---------------------------GROUPING START
global ORIGAUTHOR     = "Robert Creecy"
global CURRENTAUTHOR  = "Lars Vilhuber, STATA port by Amine Ouazad"
global VERSION	    = "0.1"

quietly {

save "`tempdatafile'", replace

	keep if `mnum'>0
	keep `itemp' `jtemp'

	egen `indid'  = group(`itemp')
	egen `unitid' = group(`jtemp')

	keep `itemp' `jtemp'  `indid' `unitid' 

	***** Keeps only cells : we are working with cells, not observations
	duplicates drop  `indid' `unitid', force

	mata: groups( "`indid'","`unitid'","`group'")

	*** Drop new school and pupil indexes
	keep `itemp' `jtemp' `group'
	sort `itemp' `jtemp'
	save "`tempgroupfile'", replace

	*** Merge group information with main input data file

use "`tempdatafile'"

	
	sort `itemp' `jtemp'
	merge `itemp' `jtemp' using "`tempgroupfile'"
	drop _merge
	}

/* --------------------------------------------------------------------------- */

qui replace `group'=0 if `mnum'==0

if "`noisily'"=="noisily" {
	sort `group'
	qui gen `moverp'=`mover' if `p'==1
	sort `jtemp'
	qui by `jtemp': gen `firm'=1 if _n==1
	local last=0
	qui sum `firm'
	local firms=r(N)

if "`noisily'"=="noisily" {

	di _newline "Groups of firms connected by worker mobility:"
	di  _newline "             Person-years       Persons          Movers         Firms"
	table `group', c(N `itemp' N `p' sum `moverp' N `f') row
	}
qui sum `f'
local firms=r(N)
qui sum `f' if `group'==0
local nomov=r(N)
qui sum `group'
if "`noisily'"=="noisily" {
	if r(min)==0 {
		di _newline "Note: Group 0 in the table regroups firms without movers."
		di _newline "No firm effect in group 0 is identified."
		di `firms' "-" `nomov' "-" `r(max)' " = " `firms'-`nomov'-`r(max)' " firm effects are identified."
		di "(number of firms - number of firms without movers - number of groups excl. group 0)"  _newline
		}
	else {
		di _newline "Note: Each firm has at least 1 mover."
		di `firms' "-" `r(max)' " = " `firms'-`r(max)' " firm effects are identified."
		di "Computed as: number of firms - number of groups" _newline
		}
	}
}
*---------------------------GROUPING END
	timer off 8
	}
else {
	di in yellow "You chose not to run the grouping algorithm."
	di "The existing group variable will be used!"
	di "NOTE that existing group variable MUST group firms without movers as group 0!" _newline 
	}

*9. Sort, time-demean variables
timer on 9
sort `ivar' `jvar'
foreach y of any `varlist'{
qui by `ivar': egen `y'm=mean(`y')
quietly replace `y'=`y'-`y'm
drop `y'm
}
timer on 9

*Start Mata environment
mata: decompreg("`depvar'","`indepvar'","`itemp'","`jtemp'","`feff'","`peff'","`res'","`xb'","`normalize'","`mem'","`robust'","`cluster'","`cholsolve'","`hat'","`orig'")

*Restricted model without person effects
_estimates hold felsdvreg, copy
qui drop `jtemp'
qui egen `jtemp'=group(`jvar') if `sample'==1
qui replace `jtemp'=0 if `feff'==0

if "`ftest'"=="ftest" {
	qui xtreg `varlist', i(`jtemp') fe
	local rss_restp=`e(rss)'
	}
_estimates unhold felsdvreg
ereturn scalar F_f =(`e(rss_rest)'-`e(rss)')/`e(rss)'* `e(df_r)'/`e(numb_rest)' /* For F-test that all u_i equal zero*/

if "`ftest'"=="ftest" {
	ereturn scalar rss_restp=`rss_restp'
	ereturn scalar F_fp=(`e(rss_restp)'-`e(rss)')/`e(rss)'* `e(df_r)'/`e(numb_restp)' /* For F-test that all person effects equal zero*/
	ereturn scalar F_ff=(`e(rss_restf)'-`e(rss)')/`e(rss)'* `e(df_r)'/`e(numb_restf)' /* For F-test that all firm effects zero*/
	}

di in green _newline "N=" e(N)
if "`cons'"=="cons" {   
	qui sum `peff'
	mat b=e(b)
	mat b[1,colsof(b)]=r(mean)
	ereturn repost b=b
	mat V=e(V)
	if rowsof(V)>1 {
	mat V=V[1..rowsof(V)-1,.] \ J(1,colsof(V),0)
	mat V=V[.,1..colsof(V)-1] , J(rowsof(V),1,0)
	}
	else {
	mat V[1,1]=0
	}
	ereturn repost V=V
	qui replace `peff'=`peff'-r(mean)
	}

ereturn display
if "`cons'"=="cons" {   
	di "The regression constant is understood as descriptive statistic for the grand mean,"
	di "its standard error is not computed."
	}

if "`hat'"!=""{
	di "RSS and standard errors are adjusted for 2SLS 2nd stage regression."
	local to=wordcount("`hat'")
	foreach i of numlist 1/`to'{
	di in yellow word("`hat'",`i') in green " is a 1st stage prediction from regression of " in yellow word("`orig'",`i') in green " on instruments."
	}
}


if "`hat'"==""{
di _newline "F-test that person and firm effects are equal to zero: F(`e(numb_rest)',`e(df_r)')=" round(`e(F_f)',.01) " Prob > F = " round(Ftail(`e(numb_rest)',`e(df_r)',`e(F_f)'),.001)
if "`ftest'"=="ftest" {
	di          "F-test that person effects are equal to zero:          F(`e(numb_restp)',`e(df_r)')=" round(`e(F_fp)',.01) " Prob > F = " round(Ftail(`e(numb_restp)',`e(df_r)',`e(F_fp)'),.0001)
	di          "F-test that firm effects are equal to zero:            F(`e(numb_restf)',`e(df_r)')=" round(`e(F_ff)',.01) " Prob > F = " round(Ftail(`e(numb_restf)',`e(df_r)',`e(F_ff)'),.0001)
	}
}

if `e(df_r)'<0 {
	di _newline "Degrees of freedom are negative, you have not sufficient observations!"
	di _newline "#firm effects + #person effects + #regressors exceeds sample size !!"
	}


qui correlate `depvar' `xb', covariance
local vary=r(Var_1)
local covxb=r(cov_12)
qui correlate `depvar' `peff', covariance
local covp=r(cov_12)
qui correlate `depvar' `feff', covariance
local covf=r(cov_12)
qui correlate `depvar' `res', covariance
local covr=r(cov_12)

if "`noisily'"=="noisily" {	
	di _newline "If the covariances are positive, the following may indicate the importance in explaining "
	di "the variance of `depvar':"
	di _newline "Cov(`depvar', `xb') / Var(`depvar'): " _column(50) `covxb'/`vary'
	di        "Cov(`depvar', `peff') / Var(`depvar'): " _column(50) `covp'/`vary'
	di        "Cov(`depvar', `feff') / Var(`depvar'): " _column(50) `covf'/`vary'
	di         "Cov(`depvar', `res') / Var(`depvar'): " _column(50) `covr'/`vary'
	}
timer off 20
} /* End of grouponly else*/
end

/* -------------------------------- MATA CODE  -----------------------------------------------------  */
mata:
void decompreg(string scalar depvar, string scalar indepvar, string scalar ivar, string scalar jvar, string scalar feffn, string scalar peffn,  string scalar resn,  string scalar xbn, string scalar normalize, string scalar mem, string scalar rob, string scalar clust, string scalar chol,string scalar hat,string scalar orig)
{

/* ------------------------------  Konstante generieren ------------------------------------------------------------*/


if (st_macroexpand("`"+"cons"+"'")=="cons") {
cons=J(st_nobs(),1,1)  /* Code zum Einbauen einer Konstante*/
st_store(.,st_addvar("byte","cons"),cons)
xindex=(st_varindex(tokens(indepvar)),st_varindex("cons"))
}
else
{
xindex=st_varindex(tokens(indepvar))
}
yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)

if (clust!="") {
clindex=st_varindex(clust)
}



/* ---------------------------  Generate system of normal equations  ----------------------------------------*/

y=X=id=jd=.                                  /*Ist notwendig, sonst error "X2 not found".*/
st_view(y,.,yindex)
st_view(X,.,xindex)
st_view(jd,.,jindex)
numj=colmax(jd)

/* 10. Compute Total Sum of Squares */
stata("timer on 10")
yy=cross(y,y)
st_numscalar("e(tss_w)",yy)

stata("timer off 10")

display("Memory requirement for moment matrices in GB:")
((cols(X)+numj)^2+cols(X)+numj)*8/1000000000

stata("timer on 11")
A=(quadcross(X,X),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))
B=(quadcross(X,y)\ J(numj,1,0))
if (clust!="" | rob=="robust") { /* Create matrix for clustered or robust standard errors already here to see if enough memory*/
display(" ")
display("Memory requirement for robust/clustered standard errors in GB:")
(sizeof(A))/1000000000
C=(J(cols(X),cols(X),0),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))
}
display (" ")

st_updata(1) /*Flag setzen dass Datensatz geändert wurde.*/
st_view(y,.,yindex,st_macroexpand("`"+"mover"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"mover"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"mover"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"mover"+"'"))
numj=colmax(jd)

PI=panelsetup(id,1)
stata("timer off 11")
/* 12. Filling in elements for movers */
stata("timer on 12")
for (i=1; i<=rows(PI);i++) {
/*for (i=1; i<=1;i++) {*/

xi=panelsubmatrix(X,i,PI)
yi=panelsubmatrix(y,i,PI)
ji=panelsubmatrix(jd,i,PI)
PJ=panelsetup(ji,1)
ji=uniqrows(ji)
fi=J(PJ[1,2]-PJ[1,1]+1,1,1)
for (j=2; j<=rows(PJ);j++) {
	fi=fi \ J(PJ[j,2]-PJ[j,1]+1,1,j)
	}
fi=designmatrix(fi)
fi=fi:-mean(fi,1)

ff=quadcross(fi,fi)
for (j=1; j<=cols(ff);j++) {
for (k=1; k<=rows(ff);k++) {
	A[cols(X)+ji[j],cols(X)+ji[k]]=A[cols(X)+ji[j],cols(X)+ji[k]]+ff[j,k]
	}
	}

xf=quadcross(xi,fi)
for (j=1; j<=rows(ji);j++) {
A[1..rows(xf),ji[j]+cols(X)]=A[1..rows(xf),ji[j]+cols(X)]+xf[.,j]
A[ji[j]+cols(X),1..rows(xf)]=A[ji[j]+cols(X),1..rows(xf)]+xf[.,j]'
}

fy=quadcross(fi,yi)
for (j=1; j<=rows(ji);j++) {
B[ji[j]+cols(X),1]=B[ji[j]+cols(X),1]+fy[j]
}
}
stata("timer off 12")

/* -----------------------  Determine unidentified firm effects  ---------------------------------------*/

/* 13. Take out unidentified firm effects */
stata("timer on 13")
group=.
group=st_data(.,(st_varindex(st_macroexpand("`"+"group"+"'")),jindex))
st_view(jd,.,jindex)
group=sort(group,(1,2))
GI=panelsetup(group,1)

for (j=rows(GI); j>=1;j--) {
	GI[j,1]=group[GI[j,1],2]
	}

GI=sort(GI,(1))



numj=colmax(jd)
GI[rows(GI),2]=numj

for (j=rows(GI)-1; j>=1;j--) {
	GI[j,2]=GI[j+1,1]-1
	}

jtest=uniqrows(jd)

for (j=1; j<=rows(GI);j++) {
      for (i=cols(X)+GI[j,1]; i<=cols(X)+GI[j,2]-1;i++) {
	B[i-j+1]=B[i+1]
	A[.,i-j+1]=	A[.,i+1]
	A[i-j+1,.]=	A[i+1,.]
	}
}

A=A[1..rows(A)-rows(GI),1..cols(A)-rows(GI)]
B=B[1..rows(B)-rows(GI)]
jd=jd[1..rows(jd)-rows(GI)]
stata("timer off 13")


/* ------------------------ Solve -----------------------------------------------------------------------*/

if (mem=="mem") {
sizeof(A)
sizeof(B)
}

if (chol!="") {
	printf("Solving for beta, dimension: %f\n", rows(A))
	display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
	stata("timer on 14")
	beta=cholsolve(A,B)
	dropped=0
	stata("timer off 14")
	display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
}
else{
	printf("Computing generalized inverse, dimension: %f\n", rows(A))
	display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
	stata("timer on 14")
	o=cols(X)+1
	if (cols(A)>cols(X)+1) {
		for (j=cols(X)+2; j<=rows(A);j++) {
		o=o , j 
		}
	}
	_invsym(A,o)
	dropped=diag0cnt(A)
	beta=A*B
	stata("timer off 14")
	/*printf("  Collinear regressors dropped: %f\n", dropped)*/
	display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
}

for (j=1; j<=rows(GI);j++) {
	if (cols(X)+GI[j,1]<=rows(beta)){
		 beta=(beta[1..cols(X)+GI[j,1]-1] \ 0 \ beta[cols(X)+GI[j,1]..rows(beta)])
		 }
	else {
		beta=(beta[1..cols(X)+GI[j,1]-1] \ 0)
		}
	}

st_matrix("b",beta[1..cols(X)]')
st_matrixcolstripe("b",(J(cols(X),1," "),(st_varname(xindex)')))
st_view(jd,.,st_macroexpand("`"+"jvar"+"'"))

/* Copy variables mover, group, mnum and pobs for joining to the data after restore */
stata( "sort "+"`"+"ivar"+"'"+" "+"`"+"jvar"+"'")
n_mov_group_index=st_varindex((st_macroexpand("`"+"n"+"'"),st_macroexpand("`"+"mover"+"'"),st_macroexpand("`"+"group"+"'"),st_macroexpand("`"+"mnum"+"'"),st_macroexpand("`"+"pobs"+"'"),st_macroexpand("`"+"itemp"+"'"),st_macroexpand("`"+"jtemp"+"'")))
n_mov_group=st_data(.,n_mov_group_index)

/*15. Restore dataset */
stata("timer on 15")
stata("restore")
stata("timer off 15")

/*16. Generate smooth firm and person IDs again */
stata("timer on 16")
stata( "sort "+"`"+"n"+"'")	
stata( "qui gen "+"`"+"itemp"+"'"+"=.")
stata( "qui gen "+"`"+"jtemp"+"'"+"=.")
stata( "qui gen "+"`"+"mnum"+"'"+"=.")
stata( "qui gen "+"`"+"pobs"+"'"+"=.")

/*Join Mover and Group to data */
n_mov_group=sort(n_mov_group,1)
st_store(.,(st_macroexpand("`"+"mover"+"'"),st_macroexpand("`"+"group"+"'"),st_macroexpand("`"+"mnum"+"'"),st_macroexpand("`"+"pobs"+"'"),st_macroexpand("`"+"itemp"+"'"),st_macroexpand("`"+"jtemp"+"'")),st_macroexpand("`"+"sample"+"'"),n_mov_group[.,(2,3,4,5,6,7)])
stata("timer off 16")


/*Predicting x'b and assigning firm effects */
stata("timer on 17")
if (st_macroexpand("`"+"cons"+"'")=="cons") {
cons=J(st_nobs(),1,1)  /* include constant */
st_store(.,st_addvar("byte","cons"),cons)
xindex=(st_varindex(tokens(indepvar)),st_varindex("cons"))
}
else
{
xindex=st_varindex(tokens(indepvar))
}

hatindex=st_varindex(tokens(hat))
origindex=st_varindex(tokens(orig))
xoindex=xindex

for (i=1; i<=cols(hatindex);i++) {
	_editvalue(xoindex,hatindex[i],origindex[i])
	}

yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)
gindex=st_varindex(st_macroexpand("`"+"group"+"'"))

stata( "sort "+"`"+"itemp"+"'")
st_view(y,.,yindex,st_macroexpand("`"+"sample"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"sample"+"'"))
st_view(Xo,.,xoindex,st_macroexpand("`"+"sample"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
numj=colmax(jd)
xb=feff=peff=res=J(rows(X),1,0)

for (i=1; i<=rows(X);i++) {
xb[i]=X[i,.]*beta[1..cols(X)]
feff[i]=beta[cols(X)+jd[i]]
}
if (hat!=""){
	xbo=reso=J(rows(X),1,0)
	for (i=1; i<=rows(X);i++) {
	xbo[i]=Xo[i,.]*beta[1..cols(X)]
	}
}

st_store(.,st_addvar("float",(feffn)),st_macroexpand("`"+"sample"+"'"),(feff))

/*Firmeneffekte normlisieren*/

if (normalize=="normalize") {
	feffindex=st_varindex(feffn)
	stata("qui egen "+"`"+"feffgbar"+"'"+" = mean("+"`"+"feff"+"'"+"), by("+"`"+"group"+"'"+")")
	stata("qui replace "+"`"+"feff"+"'"+" = "+"`"+"feff"+"'"+"-"+"`"+"feffgbar"+"'")
	feff=st_data(.,feffindex,st_macroexpand("`"+"sample"+"'"))
	}
stata("timer off 17")


/*18. Computing residuals and person effects */
stata("timer on 18")
PI=panelsetup(id,1)

for (i=1; i<=rows(X);i++) {
res[i]=y[i]-xb[i]-feff[i]
}


if (hat!=""){
for (i=1; i<=rows(X);i++) {
reso[i]=y[i]-xbo[i]-feff[i]
}
}


for (i=1; i<=rows(PI);i++) {
peff[PI[i,1]..PI[i,2],1]=J(PI[i,2]-PI[i,1]+1,1,mean(panelsubmatrix(res,i,PI),1))
}
res=res-peff


uu=cross(res,res)
st_numscalar("e(rss)",uu)
st_numscalar("e(r2_w)",1-uu/yy)

if (hat!=""){
reso=reso-peff
uu=cross(reso,reso)
st_numscalar("e(rss)",uu)
}

if (st_macroexpand("`"+"cons"+"'")=="cons") {	k=cols(X)-1
	}
else {  k=cols(X)
	}


dof=rows(X)-k-1-(cols(A)-cols(X))-(rows(PI)-1) + dropped
/*    N*   -  k  - const - (estimated firm effects) - N(-1) + #collinear regressors dropped*/
numbrest=(cols(A)-cols(X))+(rows(PI)-1) /* Number of restrictions if model is estimated with all person and firm effects = 0*/
numbrestp=rows(PI)-1
numbrestf=cols(A)-cols(X)


/*With cluster option, if panels i and j are considered going off to infinity, DoF is different*/

if (clust!="") {
if (st_macroexpand("`"+"adji"+"'")=="noadji") {
	dof=dof+(rows(PI)-1)
	}
if (st_macroexpand("`"+"adjj"+"'")=="noadjj") {
	dof=dof+(cols(A)-cols(X))
	}
}


st_numscalar("e(df_r)",dof)
st_numscalar("e(numb_rest)",numbrest)
st_numscalar("e(numb_restp)",numbrestp)
st_numscalar("e(numb_restf)",numbrestf)

sigmau=sqrt(uu/dof)
st_numscalar("e(sigma_u)",sigmau)
stata("timer off 18")

if (chol!="") {
	display("")
	display("Solving for covariance matrix")
	display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
	stata("timer on 19")
	_cholinv(A)
	stata("timer off 19")
	display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
}

if (hat==""){
st_store(.,st_addvar("float",(peffn,xbn,resn)),st_macroexpand("`"+"sample"+"'"),(peff,xb,res))
}
else{
st_store(.,st_addvar("float",(peffn,xbn,resn)),st_macroexpand("`"+"sample"+"'"),(peff,xb,reso))
}


/* +++++++++++++++++    START CLUSTERED STANDARD ERRORS +++++++++++++++++++++++++++ */
if (clust!="") {
display("")
stata("timer on 25")
stata( "sort "+"`"+"cluster"+"'")
stata( "qui egen "+"`"+"cltemp"+"'"+"=group("+"`"+"cluster"+"'"+") if "+st_macroexpand("`"+"sample"+"'")+"==1")

if (st_macroexpand("`"+"cons"+"'")=="cons") {
xindex=(st_varindex(tokens(indepvar)),st_varindex("cons"))
}
else
{
xindex=st_varindex(tokens(indepvar))
}
yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)
resindex=st_varindex(st_macroexpand("`"+"res"+"'"))
movindex=st_varindex(st_macroexpand("`"+"mover"+"'"))
clindex=st_varindex(st_macroexpand("`"+"cltemp"+"'"))

/*C=(J(cols(X),cols(X),0),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))*/

st_view(X,.,xindex,st_macroexpand("`"+"sample"+"'"))
st_view(res,.,resindex,st_macroexpand("`"+"sample"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
st_view(cl,.,clindex,st_macroexpand("`"+"sample"+"'"))
st_view(mover,.,movindex,st_macroexpand("`"+"sample"+"'"))

obs=rows(X)
PC=panelsetup(cl,1)
nocl=rows(PC)

printf("Computing clustered standard errors, clusters:  %f\n", nocl)
display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))

for (c=1; c<=rows(PC);c++) {      /*Start loop over Clusters*/
	if (c==1){
	stata("timer on 30")
	}
	if (c==2){
	stata("timer off 30")
	}

	idc=uniqrows(id[PC[c,1]..PC[c,2]])  /* Sorted vector of all person IDs in cluster */
	xic=J(1,cols(X),0)
	mc=0
	for (i=1; i<=rows(idc);i++) {    /*Start loop over Persons*/
		ident=id:==idc[i]
		xi=select(X,ident)
		xi=xi:-mean(xi,1)
		mi=select(mover,ident)
		resi=select(res,ident)
		cli=select(cl,ident)
		cident=cli:==c         /* Identification vector for all observations for peson i with respect to cluster c*/
	
		if (rows(xi)>1){ 
			xi=select(xi,cident)	
			}
		if (rows(resi)>1){
			resi=select(resi,cident)
			}

		xi=xi:*resi
		xic=xic+colsum(xi)

		mc=mc+mi[1,1]
		if (mi[1,1]==1) { /*Begin if mover*/
		ji=select(jd,ident)
		jiu=uniqrows(ji)
		fi=ji:==jiu[1]

		if (rows(jiu)>1){
		 for (j=2; j<=rows(jiu);j++) {
		  	 fi=fi,ji:==jiu[j]
			 }
		  }

		fi=fi:-mean(fi,1)

		if (rows(fi)>1){
			fi=select(fi,cident)
			}
		fi=fi:*resi
		fi=colsum(fi)
		jiu=jiu'

		if (mc==1){      					      /* If first mover in the cluster, create jdc and fic new */
			jdc=jiu
			fic=fi
			}   
		else {                                                 /* Otherwise .... */
			for (j=1; j<=cols(jiu);j++) {	 /* For all firms person was employed*/			
 			      ind=jdc:==jiu[j]
 	 		      if (sum(ind)>0) {                         /* add value of fi to fic if firm already in jdc/fic.... */
				ind=jdc:<=jiu[j]
				fic[sum(ind)]=fic[sum(ind)]+fi[j]
				}
			   else {                                      /* if firm not already there either append in the end....*/
					if (jiu[j]>jdc[cols(jdc)]) {
						jdc=jdc,jiu[j]
						fic=fic,fi[j]
						                     }
					else {					/* or insert it....*/
						ind=sum(jdc:<jiu[j])
						if (ind>0) {
							jdc=jdc[1..ind],jiu[j],jdc[ind+1..cols(jdc)]  /*...in the middle*/
							fic=fic[1..ind],fi[j],fic[ind+1..cols(fic)]
							}
						else {
							jdc=jiu[j],jdc[ind+1..cols(jdc)] /* ...or in the first place*/
							fic=fi[j],fic[ind+1..cols(fic)]
							}
						}				   
				   }  /* if firm not already there */
			   }  /* End for all firms person was employed*/			


			}
		

		} /*End if mover*/
		}  /*End loop over Persons*/

xx=quadcross(xic,xic)
C[1..cols(X),1..cols(X)]=C[1..cols(X),1..cols(X)]+xx

if (mc>0) { /* If there were movers in the cluster */
ff=quadcross(fic,fic)
xf=quadcross(xic,fic)

for (l=1; l<=cols(ff);l++) {
for (k=1; k<=rows(ff);k++) {
	C[cols(X)+jdc[l],cols(X)+jdc[k]]=C[cols(X)+jdc[l],cols(X)+jdc[k]]+ff[l,k]
	}
	}

for (l=1; l<=cols(jdc);l++) {
C[1..rows(xf),jdc[l]+cols(X)]=C[1..rows(xf),jdc[l]+cols(X)]+xf[.,l]
C[jdc[l]+cols(X),1..rows(xf)]=C[jdc[l]+cols(X),1..rows(xf)]+xf[.,l]'
}
} /*End if there were movers in cluster */

	}  /*End loop over Clusters*/
display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
} /*End if cluster option*/



/* +++++++++++++++++     END CLUSTERED STANDARD ERRORS +++++++++++++++++++++++++++ */
/* +++++++++++++++++    START ROBUST   STANDARD ERRORS +++++++++++++++++++++++++++ */
if (clust=="" & rob=="robust") {
display("")
display("Computing robust standard errors")
display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
stata("timer on 25")
stata( "sort "+"`"+"itemp"+"' "+"`"+"jtemp"+"' ")

if (st_macroexpand("`"+"cons"+"'")=="cons") {
xindex=(st_varindex(tokens(indepvar)),st_varindex("cons"))
}
else
{
xindex=st_varindex(tokens(indepvar))
}
yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)
resindex=st_varindex(st_macroexpand("`"+"res"+"'"))
movindex=st_varindex(st_macroexpand("`"+"mover"+"'"))

/*C=(J(cols(X),cols(X),0),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))*/

st_view(y,.,yindex,st_macroexpand("`"+"sample"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"sample"+"'"))
st_view(res,.,resindex,st_macroexpand("`"+"sample"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
PI=panelsetup(id,1)
obs=rows(X)
for (i=1; i<=rows(PI);i++) {      
xi=panelsubmatrix(X,i,PI)
ji=panelsubmatrix(jd,i,PI)
PJ=panelsetup(ji,1)
ji=uniqrows(ji)

xi=xi:-mean(xi,1)
for (p=1; p<=rows(PJ);p++) {    /* p which firm of the firms person i is observed in this refers to  */
for (j=PJ[p,1]; j<=PJ[p,2];j++) {   /* j counts at which observation of person i we are */
	C[1..cols(X),1..cols(X)]=C[1..cols(X),1..cols(X)]+quadcross(xi[j,.],xi[j,.])*res[PI[i,1]+j-1,1]^2
	}
	}
}

stata( "qui replace "+"`"+"mover"+"' =0 if "+"`"+"sample"+"' ==0")
movindex=st_varindex(st_macroexpand("`"+"mover"+"'"))
st_view(y,.,yindex,st_macroexpand("`"+"mover"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"mover"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"mover"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"mover"+"'"))
st_view(mover,.,movindex,st_macroexpand("`"+"sample"+"'"))
resm=select(res,mover)
stata( "qui replace "+"`"+"mover"+"' =. if "+"`"+"sample"+"' ==0")
PI=panelsetup(id,1)
for (i=1; i<=rows(PI);i++) {
xi=panelsubmatrix(X,i,PI)
ji=panelsubmatrix(jd,i,PI)
PJ=panelsetup(ji,1)
ji=uniqrows(ji)
fi=J(PJ[1,2]-PJ[1,1]+1,1,1)
for (j=2; j<=rows(PJ);j++) {
	fi=fi \ J(PJ[j,2]-PJ[j,1]+1,1,j)
	}
fi=designmatrix(fi)
fi=fi:-mean(fi,1)
xi=xi:-mean(xi,1)

for (p=1; p<=rows(PJ);p++) {    /* p which firm of the firms person i is observed in this refers to  */
for (j=PJ[p,1]; j<=PJ[p,2];j++) {   /* j counts at which observation of person i we are */
	ff=quadcross(fi[j,.],fi[j,.])*resm[PI[i,1]+j-1,1]^2
	for (l=1; l<=cols(ff);l++) {
	for (k=1; k<=rows(ff);k++) {
		C[cols(X)+ji[l],cols(X)+ji[k]]=C[cols(X)+ji[l],cols(X)+ji[k]]+ff[l,k]
		}
		}
	xf=quadcross(xi[j,.],fi[j,.])*resm[PI[i,1]+j-1,1]^2
	for (l=1; l<=rows(ji);l++) {
	C[1..rows(xf),ji[l]+cols(X)]=C[1..rows(xf),ji[l]+cols(X)]+xf[.,l]
	C[ji[l]+cols(X),1..rows(xf)]=C[ji[l]+cols(X),1..rows(xf)]+xf[.,l]'
		}
	}
	}
}
display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
} /* End if robust option*/
/* +++++++++++++++++    END ROBUST   STANDARD ERRORS +++++++++++++++++++++++++++ */

/* -------  Take out unidentified firm effects  of C for cluster and robust standard errors  ---------------------*/
if (clust!="" | rob=="robust") {
group=.
group=st_data(.,(st_varindex(st_macroexpand("`"+"group"+"'")),jindex),st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
group=sort(group,(1,2))
GI=panelsetup(group,1)

for (j=rows(GI); j>=1;j--) {
	GI[j,1]=group[GI[j,1],2]
	}

GI=sort(GI,(1))

numj=colmax(jd)
GI[rows(GI),2]=numj

for (j=rows(GI)-1; j>=1;j--) {
	GI[j,2]=GI[j+1,1]-1
	}


for (j=1; j<=rows(GI);j++) {
      for (i=cols(X)+GI[j,1]; i<=cols(X)+GI[j,2]-1;i++) {
	C[.,i-j+1]=	C[.,i+1]
	C[i-j+1,.]=	C[i+1,.]
	}
}

C=C[1..rows(C)-rows(GI),1..cols(C)-rows(GI)]    
								
S=quadcross(A,C)
R=quadcross(S',A)

stata("timer off 25")

if (clust=="" & rob=="robust") {  /* ROBUST */
R=(obs/dof)*R
st_global("e(vcetype)","Robust")
};
if (clust!="") {  /* CLUSTER */
R=(obs-1)/dof*nocl/(nocl-1)*R
st_global("e(vcetype)","Robust")
st_global("e(clustvar)",st_macroexpand("`"+"cluster"+"'"))
if (st_macroexpand("`"+"adji"+"'")=="noadji") {
	display("    Number of effects of panels i not counted into degrees of freedom adjustment")
	display("    of the clustered covariance matrix.")

	}
if (st_macroexpand("`"+"adjj"+"'")=="noadjj") {
	display("    Number of effects of panels j not counted into degrees of freedom adjustment.")
	display("    of the clustered covariance matrix.")
	}
if (st_macroexpand("`"+"adji"+"'")!="noadji" & st_macroexpand("`"+"adjj"+"'")!="noadjj" ) {
	display("  Full degrees of freedom adjustment (equal to xtreg option -dfadj-)")
	}
}
st_matrix("V",R[1..cols(X),1..cols(X)])
if (st_macroexpand("`"+"feffse"+"'")!="") {
sefeff=sqrt(diagonal(R[cols(X)+1..cols(R),cols(X)+1..cols(R)]))
}


} /* End Cluster or Robust */
/* +++++++++++++++++    END CLUSTERED AND ROBUST   STANDARD ERRORS +++++++++++++++++++++++++++ */
/*-------------------------------------------------------------------------------------------------*/
else
{
A=sigmau^2*A
st_matrix("V",A[1..cols(X),1..cols(X)]')
if (st_macroexpand("`"+"feffse"+"'")!="") {
	sefeff=sqrt(diagonal(A[cols(X)+1..cols(A),cols(X)+1..cols(A)]))
	}
}

if (st_macroexpand("`"+"feffse"+"'")!="") {
group=uniqrows(st_data(.,(st_varindex(st_macroexpand("`"+"group"+"'")),st_varindex(st_macroexpand("`"+"jtemp"+"'"))),st_macroexpand("`"+"sample"+"'")))
sel=group[.,1]
group=select(group,sel)
GG=panelsetup(group,1)
group=group[.,2]
sel=J(rows(group),1,1)
for (j=1; j<=rows(GG);j++) {
	sel[GG[j,1]]=0
	}
GG=.
group=select(group,sel)
sel=.
st_view(jd,.,(st_varindex(st_macroexpand("`"+"jtemp"+"'"))),st_macroexpand("`"+"sample"+"'"))
jdd=uniqrows(jd)
feffse=J(rows(jdd),1,.)
jdd=.
for (j=1; j<=rows(group);j++) {
	feffse[group[j]]=sefeff[j]
	}
for (j=1; j<=rows(group);j++) {
	feffse[group[j]]=sefeff[j]
	}
group=.
jdd=jd
for (j=1; j<=rows(jd);j++) {
	jdd[j]=feffse[jd[j]]
	}
st_store(.,st_addvar("float",st_macroexpand("`"+"feffse"+"'")),st_macroexpand("`"+"sample"+"'"),jdd)
}

st_matrixrowstripe("V",(J(cols(X),1," "),(st_varname(xindex)')))
st_matrixcolstripe("V",(J(cols(X),1," "),(st_varname(xindex)')))
stata("cap drop cons")
stata("ereturn repost b=b V=V")
}


void groups(string scalar individualid, string scalar unitid, string scalar groupvar) {

		real scalar ncells, npers, nfirm; 	/* Data size : number of distinct observations number of pupils number of schools */
		real matrix byp, byf; 			/* Dataset sorted by pupil/by school */
		real vector pg, fg, pindex, findex, ptraced, ftraced, ponstack, fonstack;
	
		/***** Stack for tracing elements */
		real vector m;				/* Stack of pupils/schools */
		real scalar mpoint;			/* Number of elements on the stack */
	
		real scalar nptraced, nftraced;	// Number of traced elements
		real scalar lasttenp, lasttenf;
		real scalar nextfirm;

		real vector mtype; 	/* Type of the element on top of the stack */
					 	/* Convention : 					 */
					 	/* 1 for a pupil					 */
					 	/* 2 for a school					 */
	
		real scalar g;	/* Current group */
	
		real scalar j;
	
		real matrix data;		/* A data view used to add group information after the algorithm completed */
	
		printf("Grouping algorithm for CG\n");
	
		/****** Core data : cells sorted by person/by firm */

		byp = st_data(., (individualid, unitid));
		printf("Sorting data by pupil id\n");
		byp = sort(byp,1);
	
		byf = st_data(., (individualid, unitid));
		printf("Sorting data by school id\n");
		byf = sort(byf,2);
		
		/****** Data size */
	
		ncells = rows(byf);		/* Number of distinct observations (duplicates drop has to be done beforehand) */
		npers  = byp[ncells,1];		/* Number of pupils										 */
		nfirm  = byf[ncells,2];		/* Number of schools										 */

		printf("Data size : %9.0g cells, %9.0g pupils, %9.0g firms\n", ncells, npers, nfirm);
	
		/****** Initializing the stack and p/ftraced */

		printf("Initializing the stack\n");
	
		ptraced  = J(npers, 1, 0);	// No pupil has been traced yet
		ftraced  = J(nfirm, 1, 0);	// No school has been traced yet

		ponstack = J(npers, 1, 0);	// No pupil has been on the stack yet
		fonstack = J(nfirm, 1, 0);	// No school has been on the stack yet
	
		m 	= J(npers+nfirm, 1, 0); // Empty stack
		mtype = J(npers+nfirm, 1, 0);	// Unknown type of the element on top of the stack
	
		printf("Initializing pg,fg\n");
	
		pg	= J(npers, 1, 0);
		fg	= J(nfirm, 1, 0);
	
		/****** Initializing pindex, findex */
	
		printf("Initializing the index arrays\n");
	
		pindex = J(npers, 1, 0);
		findex = J(nfirm, 1, 0);
	
		for ( j = 1 ; j <= ncells ; j++) {
			pindex[byp[j,1]] = j;
			findex[byf[j,2]] = j;
		}
	
		g = 1;   	// The first group is group 1
		
		check_data(byp, byf, ncells);
	
		/***** Puts the first firm in the stack */
	
		printf("Putting first school on the stack\n");
		nextfirm = 1;
		mpoint = 1;
		m[mpoint] = 1;
		mtype[mpoint] = 2;
		fonstack[1] = 1;
	
		printf("Starting to trace the stack\n");
		
		nptraced = 0;
		nftraced = 0;
		lasttenp = 0;
		lasttenf = 0;

		while (mpoint > 0) {
	
			if (trunc((nptraced/npers)*100.0) > lasttenp || trunc((nftraced/nfirm)*100.0) > lasttenf) {
				lasttenp = trunc((nptraced/npers)*100.0);
				lasttenf = trunc((nftraced/nfirm)*100.0);
	
				printf("Progress : %9.0g pct pupils traced, %9.0g pct firms traced\n",lasttenp,lasttenf);
			}
	
			if (g > 1) {
				printf("%9.0g\t", g);
			}
			trace_stack( byp, byf, pg, fg, m, mpoint, mtype, ponstack, fonstack, ptraced, ftraced, pindex,  findex,g, nptraced, nftraced);
			if (mpoint == 0) {
				g = g + 1;
				while (nextfirm < nfirm && fg[nextfirm] != 0) {
					nextfirm = nextfirm + 1;
				}
				if (fg[nextfirm] == 0) {
					mpoint = 1;
					m[mpoint] = nextfirm;
					mtype[mpoint] = 2;
					fonstack[nextfirm] = 1;
				}
			}
		}
	
		printf("Finished processing, adding group data\n");
	
		st_addvar("long", groupvar);
	
		st_view(data, . ,(individualid, unitid,groupvar));
	
		for (j = 1 ; j<=ncells; j++ ) {
			data[j,3] = pg[data[j,1]];
			if (pg[data[j,1]] != fg[data[j,2]]) {
				printf("Error in the output data.\n");
				printf("Observation %9.0g, Pupil %9.0g, School %9.0g, Group of pupil %9.0g, Group of school %j\n",
						j, data[j,1], data[j,2], pg[data[j,1]], fg[data[j,2]]);
				exit(1);
			}
		}
	
		printf("Finished adding groups.\n");
	
	}

	/*

	Name:			check_data()
	
	Purpose:	This function checks whether data is correctly sequenced.
	
	 */
	
	function check_data(real matrix byp, real matrix byf, real scalar ncells) {
		
		real scalar thispers, thisfirm;
	
		real scalar i;
	
		thispers = 1;
		thisfirm = 1;
	
		for ( i=1 ; i <= ncells ; i++ ) {
			if ( byp[i,1] != thispers ) {
				if ( byp[i,1] != thispers+1 ) {
					printf("Error : by pupil file not correctly sorted or missing sequence number\n");
					printf("Previous person : %9.0g , This person : %9.0g , Index in file %9.0g\n", thispers, byp[i,1], i);
					exit(1);
				}
				thispers = thispers + 1 ;
			}
	

			if ( byf[i,2] != thisfirm ) {
				if ( byf[i,2] != thisfirm + 1 ) {
					printf("Error : by school file not correctly sorted or missing sequence number\n");
					printf("Previous school : %9.0g , This school : %9.0g , Index in file %9.0g\n", thisfirm, byf[i,2], i);
					exit(1);
				}
				thisfirm = thisfirm + 1;
			}
		
		}
	
		printf("Data checked - By pupil and by school files correctly sorted and sequenced\n");
	}

	/*
	
	Name: 	trace_stack()
	
	Purpose:	Builds the connex component of the graph of the elements on the stack

	 */

	void trace_stack( real matrix byp, real matrix byf, real vector pg,  real vector fg, 
				real vector m, real scalar mpoint, real vector mtype,
				real vector ponstack, real vector fonstack,
				real vector ptraced,  real vector ftraced,
				real vector pindex,   real vector findex,
				real scalar g, real scalar nptraced, real scalar nftraced) {
	
		real scalar thispers, thisfirm, person, afirm, lower, upper;
	
		if (mtype[mpoint] == 2) { // the element on top of the stack is a firm
			thisfirm = m[mpoint];
			mpoint = mpoint - 1;
			fg[thisfirm] = g;
			ftraced[thisfirm] = 1;
			fonstack[thisfirm] = 0;
			if (thisfirm == 1) {
				lower = 1;
			} else {
				lower =  findex[thisfirm - 1] + 1;
			}
			upper = findex[thisfirm];
			for (person = lower ; person <= upper ; person ++) {
				thispers = byf[person, 1];
				pg[thispers] = g;
				if (ptraced[thispers] == 0 && ponstack[thispers] == 0) {
					nptraced = nptraced + 1;
					mpoint = mpoint + 1;
					m[mpoint] = thispers;
					mtype[mpoint] = 1;
					ponstack[thispers] = 1;
				}
			}
		} else if (mtype[mpoint] == 1) { // the element on top of the stack is a person
			//printf("A person\t");
			thispers = m[mpoint];
			mpoint = mpoint - 1;
			pg[thispers] = g;
			ptraced[thispers] = 1;
			ponstack[thispers] = 0;
			if (thispers == 1) {
				lower = 1;
			} else {
				lower = pindex[thispers - 1] +1;
			}
			upper = pindex[thispers];
			for (afirm = lower; afirm <= upper; afirm++) {
				thisfirm = byp[afirm, 2];
				fg[thisfirm] = g;
				if (ftraced[thisfirm] == 0 && fonstack[thisfirm] == 0) {
					nftraced = nftraced + 1;
					mpoint = mpoint + 1;
					m[mpoint] = thisfirm;
					mtype[mpoint] = 2;
					fonstack[thisfirm] = 1;
				}
			}
		} else {
			printf("Incorrect type, element number %9.0g of the stack, type %9.0g\n",mpoint,mtype[mpoint]);
		}
	
	}

end
