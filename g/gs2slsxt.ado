*! gs2slsxt V1.0 15dec2011
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage: http://emadstat.110mb.com/stata.htm
 
program define gs2slsxt, eclass 
 version 10.1
if replay() {
if "`e(cmd)'"!="gs2slsxt" {
 error 301
 }
 Display `0'
 }
 else {
 Estimate `0'
 }
 end 

program define Estimate, eclass sortpreserve
version 10.1
syntax varlist [if] [in] [aw fw iw pw] , id(str) [WMFile(str) WMat(str) EIGw(str) ///
 Model(str) ORDer(int 1) aux(str) ec2sls vce(passthru) nosa stand small ///
 BE FE RE MLE gmm(int 1) level(passthru) NOCONStant *] 
 tempvar `varlist'
 gettoken yvar xvar : varlist
 marksample touse
 markout `touse' 
 tempvar X0 panel tm idv itv X
 tempname VarY1 X0 WSPGLS X XB Bx
 local sthlp gs2slsxt
 mlopts mlopts, `options'
 gettoken yvar xvar : varlist
_fv_check_depvar `yvar'
 if "`weight'" != "" {
 local wgt "[`weight'`exp']"
 if "`weight'" == "pweight" {
 local awgt "[aw`exp']"
 }
 else local awgt "`wgt'"
 }
 if "`log'" != "" {
 local qui quietly
 }

if "`model'"!="" {
if !inlist("`model'", "gs2sls", "gs2slsar", "spgls") {
di
di as err "{bf:model()}{cmd:must be:} {bf:spgls}, {bf:gs2sls}, {bf:gs2slsar}"
di in smcl _c "{cmd: see:} {help `sthlp'##02:Options}"
di in gr _c " (gs2slsxt Help):"
 exit
 }
 }
 if "`xvar'"=="" {
di as err "  {bf:Independent Variable(s) must be combined with Dependent Variable}"
 exit
 }
 if "`wmfile'"!="" & "`wmat'"=="" {
di as err " {bf:wmfile( )} {cmd:and} {bf:wmat( )} {cmd:must be combined}"
 exit
 }
 if "`wmat'"!="" & "`wmfile'"=="" {
di as err " {bf:wmat( )} {cmd:and} {bf:wmfile( )} {cmd:must be combined}"
 exit
 }
 if inlist("`model'", "gs2sls") & "`wmfile'"=="" & "`wmat'"=="" & "`eigw'"=="" {
di
di as err " {bf:wmfile, wmat, eigw} {cmd:must be combined with} {bf:model({it:`model'})}"
exit
 }
 if "`wmfile'"!="" & "`wmat'"!="" & "`eigw'"=="" {
di
di as err " {bf:wmfile} {cmd:and} {bf:wmat} {cmd:and} {bf:eigw} {cmd:must be combined}"
exit
 }

local useconxt `fe' `re' `be'
if inlist("`model'", "gs2sls", "gs2slsar") & "`useconxt'"!="" & "`noconstant'"!="" {
di
di as err " {bf:noconstant} {cmd:cannot be combined with (fe, re, bf) in} {bf:model({it:xtivreg})}"
exit
 }

 local both : list xvar & aux
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both RHS and Auxiliary Variables}"
di as res " RHS:`xvar'"
di as res " AUX: `aux'"
 exit
 }
 local both : list yvar & xvar
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS & RHS Variables}"
di as res " LHS: `yvar'"
di as res " RHS:`xvar'"
 exit
 } 
marksample touse
qui cap drop Time
tempvar Time
qui gen `Time'=_n if `touse'
local S = `id'
local T = _N/`id'
local NT = `S'*`T'
scalar S = `S'
scalar T = `T'
scalar NT = `NT'
qui cap drop `idv'
qui cap drop `itv'
qui gen `idv'=0 if `touse'
qui gen `itv'=0 if `touse'
qui forvalues i = 1/`id' {
qui summ `Time' if `touse' , meanonly
local min=int(`T'*`i'-`T'+1)
local max=int(`T'*`i')
 replace `idv'= `i' in `min'/`max'
 replace `itv'= `Time'-`min'+1 in `min'/`max'
 }
 qui summ `idv'
 scalar Tidv=r(max)
 qui summ `itv'
 scalar Titv=r(max)
 if `NT' != Titv*Tidv {
 di 
 di as err " Time           = " Titv
 di as err " Cross Sections = " Tidv
 di as err " Number of obs  = " `NT'
 di as res " Product of (Time x Cross Sections) must be Equal Sample Size"
 di as err " {bf:id(`S')} {cmd:Wrong Number, Check Correct Number Units of Cross Sections.}"
 exit
 }

 if "`wmat'"!="" & "`wmfile'"!="" {
scalar Dim = NT
local MSize= Dim
qui set matsize `MSize'
tempname _WB
 if "`wmfile'"!="" {
 preserve
qui use `"`wmfile'"', clear
 if "`drop'"!="" {
local NDROP : word count `drop'
 unab VLIST : _all
qui gen RDROP=0 
local i=1
 while `i'<=`NDROP' {
local D : word `i' of `drop'
local VAR : word `D' of `VLIST'
local CDLIST "`CDLIST'`VAR' "
qui replace RDROP=1 in `D'
local i=`i'+1
 }
qui drop `CDLIST'
qui drop if RDROP
qui drop RDROP
 }
 unab VLIST : _all
local NVAR : word count `VLIST'
local SUM=0
local i=1
 while `i'<=`NVAR' {
local VAR : word `i' of `VLIST'
qui capture assert `VAR'==0 | `VAR'==1
 if _rc!=0 {
local SUM=`SUM'+1
 }
local i=`i'+1
 }
qui egen ROWSUM=rowtotal(_all)
qui count if ROWSUM==0
local NN=r(N)
qui drop ROWSUM
qui mkmat _all , matrix(`_WB')
 restore
local NROW=rowsof(`_WB')
local NCOL=colsof(`_WB')
 if `NROW'!=`NCOL' {
di
di as err " {bf:Weight Matrix is not Square}"
 exit
 }
local N=`NROW'
matrix `wmat'=`_WB'
matrix `WSPGLS'=`wmat'
 }
 if "`stand'" == "" {
 preserve
qui drop _all
qui cap drop `eigw'*
 tempname eVec D WW eigwB _WBcs 
qui svmat `_WB'
qui egen ROWSUM=rowtotal(`_WB'*) 
qui for varlist `_WB'* : replace X=X if ROWSUM!=0
qui mkmat `_WB'* , matrix(`_WB')
qui mkmat `_WB'* , matrix(`_WBcs')
matrix `_WB'=`_WB'#I(`T')
matrix symeigen `eVec' `eigw'=`_WB'
matrix `eigwB'=`eigw''
matrix `wmat'=`_WB'
matrix `eigw'=`eigwB'
restore
di
di _dup(78) "{bf:{err:=}}"
di as res "Binary (0/1) Weight Matrix: `NT'x`NT' Eigenvalue: `NT'x1 ID=`S' T=`T' (Non Normalized)"
di _dup(78) "{bf:{err:=}}"
qui cap drop `eigw'*
qui svmat `eigwB' , name(`eigw')
qui rename `eigw'1 `eigw'
qui mkmat `eigw' , matrix(`eigw')
qui label variable `eigw' `"Eigenvalues Variable"'
 }
 else {
 preserve
qui drop _all
tempname eigwS _WS WS eVec D WW eigwB _WBcs 
qui cap drop `eigw'*
qui svmat `_WB'
qui egen ROWSUM0=rowtotal(`_WB'*) 
qui for varlist `_WB'* : replace X=X if ROWSUM0!=0
qui mkmat `_WB'* , matrix(`_WS')
qui svmat `_WS'
qui egen ROWSUM=rowtotal(`_WS'*) 
qui for varlist `_WS'* : replace X=X/ROWSUM if ROWSUM!=0
qui mkmat `_WS'* , matrix(_WS)
qui replace ROWSUM=sqrt(1/ROWSUM)
qui mkmat ROWSUM , matrix(`D')
matrix `D'=diag(`D')
matrix `WS'=`D'*`_WS'*`D'
matrix `WSPGLS'=`WS'
matrix `WS'=`WS'#I(`T')
matrix `_WB'=_WS#I(`T')
matrix `_WB'=`wmat'#I(`T')
matrix symeigen `eVec' `eigw'=`WS'
matrix `eigwS'=`eigw''
matrix `wmat'=`WS'
matrix `eigw'=`eigwS'
restore
di
di _dup(78) "{bf:{err:=}}"
di as res "Standardized Weight Matrix: `NT'x`NT' Eigenvalue: `NT'x1 ID=`S' T=`T' (Normalized)"
di _dup(78) "{bf:{err:=}}"
qui cap drop `eigw'*
qui svmat `eigwS' , name(`eigw')
qui rename `eigw'1 `eigw'
qui mkmat `eigw' , matrix(`eigw')
qui label variable `eigw' `"Eigenvalues Variable"'
 }
 }
 if "`wmat'" == "" {
 tempname wmat eigw _WB _WS
scalar Dim = `id'*`T'
local MSize= Dim
qui set matsize `MSize'
 matrix `wmat'=I(NT)
 matrix `_WB'=I(NT)
 matrix `_WS'=I(NT)
 matrix `eigw'=J(NT,1,1)
qui cap drop `eigw'*
qui svmat `eigw' , name(`eigw')
qui rename `eigw'1 `eigw'
 }
qui cap macro drop spat_*
qui cap drop spat_*
mlopts mlopts, `options'
tempname WS1 WS2 WS3 WS4 
matrix `WS1'= `wmat'
matrix `WS2'= `wmat'*`wmat'
matrix `WS3'= `wmat'*`wmat'*`wmat'
matrix `WS4'= `wmat'*`wmat'*`wmat'*`wmat'

qui cap drop w1x_*
qui cap drop w2x_*
qui cap drop w1y_*
qui cap drop w2y_*

tempname xyvar
mkmat `yvar' if `touse' , matrix(`xyvar')
qui forvalues i = 1/2 {
qui cap drop w`i'y_*
tempname w`i'y_`yvar'
matrix `w`i'y_`yvar'' = `WS`i''*`xyvar'
svmat  `w`i'y_`yvar'' , name(w`i'y_`yvar')
rename  w`i'y_`yvar'1 w`i'y_`yvar'
label variable w`i'y_`yvar' `"AR(`i') `yvar' Spatial Lag"'
 }

if "`order'"!="" {
qui forvalues i = 1/`order' {
qui foreach var of local xvar {
qui cap drop w`i'x_`var'
tempname w`i'x_`var'
mkmat `var' if `touse' , matrix(`xyvar')
matrix `w`i'x_`var'' = `WS`i''*`xyvar'
svmat `w`i'x_`var'' , name(w`i'x_`var')
rename w`i'x_`var'1 w`i'x_`var'
label variable w`i'x_`var' `"AR(`i') `var' Spatial Lag"'
 }
 }
 }

 if "`order'"=="1" {
local zvar w1x_* `aux'
qui cap drop w2x_*
qui cap drop w3x_*
qui cap drop w4x_*
 }
 if "`order'"=="2" {
local zvar w1x_* w2x_* `aux'
qui cap drop w3x_*
qui cap drop w4x_*
 }
 if "`order'"=="3" {
local zvar w1x_* w2x_* w3x_* `aux'
qui cap drop w4x_*
 }
 if "`order'"=="4" {
local zvar w1x_* w2x_* w3x_* w4x_* `aux'
 }

 if "`nwmat'"!="" {
qui forval i=`nwmat'/`nwmat' {
tempvar eigw`i'
 if "`nwmat'"=="`i'" {
gen `eigw`i''=`eigw'
qui sum `eigw`i''
local LOWER`i'=1/r(min)
local UPPER`i'=1/r(max)
scalar minEig`i'=`LOWER`i''
scalar maxEig`i'=`UPPER`i''
matrix mstar_W`i'=`wmat'
 }
 }
 }

if "`model'"!="" {
qui cap drop `Yh_ML'
qui cap drop `Ue_ML'
tempvar Yh_ML Ue_ML
tempname BetaSP Ue_Diag Yh_Diag
qui xtset `idv' `itv'
qui cap confirm numeric var `eigw'
qui cap summ `eigw'
qui sum `yvar' if `touse' 
local minyvar=r(min)
if `minyvar'==0 { 
di _dup(53) "-"
di "{cmd:***} {bf:{err: Truncated Dependent Variable - {cmd:`model'} Model}} {cmd:***}"
di _dup(53) "-"
 }

local kaux : word count `aux'
scalar kaux=`kaux'
if inlist("`model'", "spgls") {
local SPXvar `xvar' `aux'
 }
if inlist("`model'", "gs2sls", "gs2slsar") {
unab wyxs: w1y_`yvar'
local SPXvar `wyxs' `xvar' `aux'
 }
local K : word count `SPXvar'
scalar kx=`K'
scalar kb=kx+1
scalar kzero=1
 if "`noconstant'"!="" {
scalar kb=kx
scalar kzero=0
 }
 scalar df1=kx
 scalar df2=NT-kb
 global spat_kx=kx
 scalar df_m=$spat_kx
 ereturn scalar df_m=df_m
qui gen `X0'=1 if `touse' 
qui mkmat `X0' if `touse' , matrix(`X0')
if "`noconstant'"!="" {
 mkmat `SPXvar' if `touse' , matrix(`X')
 }
else {
 mkmat `SPXvar' `X0' if `touse' , matrix(`X')
 }

if inlist("`model'", "spgls") {
qui cap drop Time
tempvar Time
qui gen `Time'=_n  if `touse'
scalar NT= _N
scalar S=`id'
scalar T=NT/S
matrix WSPGLS=`WSPGLS'
qui xtset `idv' `itv'
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Spatial Panel Autoregressive Generalized Least Squares (SPGLS)}}"
di _dup(78) "{bf:{err:=}}"
yxregeq `yvar' `SPXvar'
gs2slsxt1 `yvar' `SPXvar' if `touse' `wgt' , gmm(`gmm') `noconstant' `vce' `robust' aux(`aux')
scalar llf=e(ll)
matrix `BetaSP'=e(b)
matrix `Bx'=`BetaSP'[1,1..kb]
matrix `VarY1'= e(V)
scalar S2y=`VarY1'[1,1]
matrix `XB' =`X'*`BetaSP''
svmat `XB' , name(`Yh_ML')
qui rename `Yh_ML'1 `Yh_ML'
qui gen `Ue_ML' =`yvar'-`Yh_ML' if `touse' 
scalar aic= 2*kb-2*llf
scalar sc =kb*log(e(N))-2*llf
qui cap matrix drop WSPGLS
 } 

if inlist("`model'", "gs2slsar") {
qui cap drop Time
tempvar Time
qui gen `Time'=_n  if `touse'
scalar NT= _N
scalar S=`id'
scalar T=NT/S
matrix WSPGLS=`WSPGLS'
qui xtset `idv' `itv'
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Spatial Panel Autoregressive 2SLS (GS2SLSAR)}}"
di _dup(78) "{bf:{err:=}}"
yxregeq `yvar' `SPXvar'
gs2slsxt2 `yvar' `xvar' if `touse' , gmm(`gmm') ///
`small' `vce' `nosa' `be' `fe' `re' `ec2sls' `sa' `coll' order('order') aux(`aux')
scalar llf=e(ll)
mat `BetaSP'=e(b)
matrix `VarY1'= e(V)
scalar S2y=`VarY1'[1,1]
qui test _b[w1y_`yvar'] =0
scalar Rho=_b[w1y_`yvar']
di 
if "`small'"!="" {
di as txt "Rho Value = " %7.4f as res Rho as txt _col(34) "F Test =" %9.3f as res r(F) as txt _col(54) "P-Value > F(" r(df) ", " r(df_r) ")" _col(74) %5.3f as res r(p)
 }
 else {
di as txt "Rho Value = " %7.4f as res Rho as txt _col(31) "Wald Test =" %9.3f as res r(chi2) as txt _col(54) "P-Value > Chi2(1)" _col(74) %5.3f as res r(p)
 }
qui cap matrix drop WSPGLS
 }

if "`model'" == "gs2sls" {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Spatial Panel 2SLS Model (GS2SLS)}}"
di _dup(78) "{bf:{err:=}}"
yxregeq `yvar' `SPXvar'
qui xtset `idv' `itv'
xtivreg `yvar' `xvar' `aux' (w1y_`yvar' = `xvar' `zvar')  if `touse' , `small' ///
`vce' `nosa' `be' `fe' `re' `noconstant' `ec2sls' `sa' `coll'
scalar llf=e(ll)
mat `BetaSP'=e(b)
qui test _b[w1y_`yvar'] =0
scalar Rho=_b[w1y_`yvar']
di 
if "`small'"!="" {
di as txt "Rho Value = " %7.4f as res Rho as txt _col(34) "F Test =" %9.3f as res r(F) as txt _col(54) "P-Value > F(" r(df) ", " r(df_r) ")" _col(74) %5.3f as res r(p)
 }
 else {
di as txt "Rho Value = " %7.4f as res Rho as txt _col(31) "Wald Test =" %9.3f as res r(chi2) as txt _col(54) "P-Value > Chi2(1)" _col(74) %5.3f as res r(p)
 }
 }

if inlist("`model'", "gs2sls", "gs2slsar") {
matrix `Bx'=`BetaSP'[1,1..kb]
qui predict `Yh_ML' if `touse' , xb
qui gen `Ue_ML' =`yvar'-`Yh_ML' if `touse' 
 }

if inlist("`model'", "gs2sls", "gs2slsar") {
scalar S=`id'
scalar T=`T'
scalar NT=T*S
tempname SSE
tempvar SSE
qui gen `SSE'=(`yvar'-`Yh_ML') if `touse' 
mkmat `SSE' if `touse' , matrix(`SSE')
matrix `SSE'=`SSE''*`SSE'
if llf == . {
scalar llf=-(`NT'/2)*log(2*_pi*`SSE'[1,1]/`NT')-(`NT'/2)
 }
scalar aic= 2*kb-2*llf
scalar sc=kb*log(e(N))-2*llf
if "`re'"!="" {
scalar aic= 2*kb-2*llf
scalar sc=kb*log(e(N))-2*llf
 }
if "`fe'"!="" {
scalar aic= 2*kb-2*llf
scalar sc=kb*log(e(N))-2*llf
 }
if "`be'"!="" {
scalar aic= 2*kb-2*llf
scalar sc=kb*log(e(N))-2*llf
 }
 }
 
if "`model'"!="" {
qui cap drop NObs
tempvar NObs
qui gen `NObs' = _n if `touse' 
mkmat `Ue_ML' if `touse' , matrix(`Ue_Diag')
mkmat `Yh_ML' if `touse' , matrix(`Yh_Diag')
qui summ `Yh_ML'
local NUM=r(Var)
qui summ `yvar'
local DEN=r(Var)
qui correlate `Yh_ML' `yvar' if `touse'
scalar r2h=r(rho)*r(rho)
scalar R20_=r2h
scalar r2h_a=1-((1-r2h)*(e(N)-1)/(e(N)-kx-1))
scalar r2v=`NUM'/`DEN'
scalar r2v_a=1-((1-r2v)*(e(N)-1)/(e(N)-kx-1))
scalar fth=r2h/(1-r2h)*(e(N)-kb)/(kb)
scalar ftv=r2v/(1-r2v)*(e(N)-kb)/(kb)
scalar fthp=fprob(df1, df2, fth)
scalar ftvp=fprob(df1, df2, ftv)
ereturn scalar df1=df1
ereturn scalar df2=df2
ereturn scalar r2h=r2h
ereturn scalar r2v=r2v
ereturn scalar r2h_a=r2h_a
ereturn scalar r2v_a=r2v_a
ereturn scalar fth=fth
ereturn scalar ftv=ftv
ereturn scalar fhp=fthp
ereturn scalar fvp=ftvp
 }

tempvar  Ue Ue2 Ue2S Yhe
tempname Ue Ue2 Ue2S Yhe Y E
tempname zWz WZ0 eWe CPX A xAx xAx2 wWw1 B xBx wWw2 WY eWy WXb IN M xMx wMw
 svmat `Ue_Diag' , name(`Ue')
 svmat `Yh_Diag' , name(`Yhe')
 rename `Ue'1 `Ue'
 rename `Yhe'1 `Yhe'
qui gen `Ue2'=`Ue'*`Ue' if `touse'
qui summ `Ue2' if `touse'
scalar SSE =r(sum)
scalar NT=e(N)
scalar Sig2=SSE/NT
 mkmat `Ue' if `touse' , matrix(`E')
 mkmat `yvar' if `touse' , matrix(`Y')
 }
 
tempname SSE
tempvar SSE
qui gen `SSE'=(`yvar'-`Yh_ML') 
mkmat `SSE' , matrix(`SSE')
matrix `SSE'=`SSE''*`SSE'
scalar Sig=sqrt(`SSE'[1,1]/df2)
ereturn local depvar "`yvar'"
ereturn local wmat `wmat'
ereturn local cmd "gs2slsxt"
qui cap drop spat_*
if inlist("`model'", "spgls", "gs2sls", "gs2slsar") {

di as txt "R2h =" %7.4f as res r2h as txt " - R2h Adj.=" as res %7.4f r2h_a as txt "  F-Test = " %8.3f as res fth as txt "   P-Value > F("df1 ", " df2 ")" %5.3f as res _col(74) fthp
if r2v < 1 {
di as txt "R2v =" %7.4f as res r2v as txt " - R2v Adj.=" as res %7.4f r2v_a as txt "  F-Test = " %8.3f as res ftv as txt "   P-Value > F("df1 ", " df2 ")" %5.3f as res _col(74) ftvp
 }
di as txt "LLF =" as res %10.3f llf _col(20) as txt "AIC =" as res %9.3f aic _col(38) as txt "SC =" as res %9.3f sc _col(54) as txt "Root MSE =" as res %8.4f Sig
 }

qui cap drop mstar_*
qui cap drop spat_YW*
qui cap matrix drop spat_ols
qui cap matrix drop w1y_`yvar'
qui cap matrix drop w2y_`yvar'
qui cap matrix drop `yvar'
qui cap drop Yh_ML Ue_ML
qui forvalues i = 1/4 {
qui foreach var of local SPXvar {
qui cap matrix drop `var'
qui cap matrix drop w`i'x_`var'
 }
} 
end

program define gs2slsxt1 , eclass 
 version 10.1
syntax varlist [if] [in] [aw fw iw pw] , [gmm(int 1) NOCONStant vce(passthru) ROBust *]
 tempvar `varlist'
 gettoken yvar xvar : varlist
 marksample touse
preserve
 qui {
tempname matg h1 h1t h2 h2t h3 h3t HM1 HM1t HM2 HM2t HM3 HM3t HM4 HM4t HMY
tempname HMYt hy Z0 hyt mats matj wmat wmat1 mtr MQ0 MQ1 MW1 MWT1 MWT2 MWT21
tempname MW2 MW3 MW4 OMGINV Q0 Q1 P matt Q1UVEC UQVEC VCOV Q1VVEC
tempname VQVEC VVEC Q1WVEC WQVEC WVEC UVEC XB
tempvar ss2 u u2 RhoGM X0
qui matrix `wmat'=WSPGLS
qui matrix `mtr'=trace(`wmat''*`wmat')/_N
qui matrix `mats'=I(S)
qui matrix `matt'=I(T)
qui matrix `matj'=J(T,T,1/T)
qui matrix `wmat1'=`matt'#`wmat'
qui matrix `Q0'=(`matt'-`matj')#`mats'
qui matrix `Q1'=`matj'#`mats'
qui matrix `MW1'=`wmat''*`wmat'
qui matrix `MWT1'=trace(`MW1')/S
qui matrix `MWT21'=`MW1'*(`wmat'+`wmat'')
qui matrix `MWT2'=trace(`MWT21')/S
qui matrix `MW2'=`wmat'*`wmat'
qui matrix `MW3'=`MW1'*`MW1'
qui matrix `MW4'=`MW1'+`MW2'
qui matrix `MQ0'=trace(`MW3')/S
qui matrix `MQ1'=trace(`MW4')/S
qui cap matrix drop `MWT21' `MW1' `MW2' `MW3' `MW4'
qui regress `yvar' `xvar' if `touse' `wgt' , `noconstant' `vce' `robust'
tempvar res res2
qui predict `res' , resid
qui gen `res2'=`res'^2
scalar L=`gmm'
mkmat `res' , matrix(`UVEC')
qui matrix `VVEC'=`wmat1'*`UVEC'
qui matrix `WVEC'=`wmat1'*`VVEC'
qui matrix `UQVEC'=`Q0'*`UVEC'
qui matrix `VQVEC'=`Q0'*`VVEC'
qui matrix `WQVEC'=`Q0'*`WVEC'
qui matrix `Q1UVEC'=`Q1'*`UVEC'
qui matrix `Q1VVEC'=`Q1'*`VVEC'
qui matrix `Q1WVEC'=`Q1'*`WVEC'
tempvar US VS WS UQS VQS WQS UTS VTS WTS
qui svmat `UVEC', name(`US')
qui svmat `VVEC', name(`VS')
qui svmat `WVEC', name(`WS')
qui svmat `UQVEC', name(`UQS')
qui svmat `VQVEC', name(`VQS')
qui svmat `WQVEC', name(`WQS')
qui svmat `Q1UVEC' , name(`UTS')
qui svmat `Q1VVEC' , name(`VTS')
qui svmat `Q1WVEC' , name(`WTS')
qui cap matrix drop `wmat1' `VVEC' `UVEC' `WVEC'
qui cap matrix drop `UQVEC' `VQVEC' `WQVEC' `Q1UVEC' `Q1VVEC' `Q1WVEC'
rename `US'1 `US'
rename `VS'1 `VS'
rename `WS'1 `WS'
rename `UQS'1 `UQS'
rename `VQS'1 `VQS'
rename `WQS'1 `WQS'
rename `UTS'1 `UTS'
rename `VTS'1 `VTS'
rename `WTS'1 `WTS'
tempvar UQ2 VQ2 WQ2 UQVQ UQWQ VQWQ UQ12 VQ12 WQ12 UQ1VQ1 UQ1WQ1 VQ1WQ1
gen `UQ2'=`UQS'*`UQS'
gen `VQ2'=`VQS'*`VQS'
gen `WQ2'=`WQS'*`WQS'
gen `UQVQ'=`UQS'*`VQS'
gen `UQWQ'=`UQS'*`WQS'
gen `VQWQ'=`VQS'*`WQS'
gen `UQ12'=`UTS'*`UTS'
gen `VQ12'=`VTS'*`VTS'
gen `WQ12'=`WTS'*`WTS'
gen `UQ1VQ1'=`UTS'*`VTS'
gen `UQ1WQ1'=`UTS'*`WTS'
gen `VQ1WQ1'=`VTS'*`WTS'
mat `mtr'=trace(`wmat''*`wmat')/S
scalar T1=T/(T-1)
scalar T2=T
tempvar UQ2M VQ2M WQ2M UQVQM UQWQM VQWQM UQ12M VQ12M WQ12M UQ1VQ1M UQ1WQ1M VQ1WQ1M
egen `UQ2M' = mean(`UQ2')
egen `VQ2M' = mean(`VQ2')
egen `WQ2M' = mean(`WQ2')
egen `UQVQM' = mean(`UQVQ')
egen `UQWQM' = mean(`UQWQ')
egen `VQWQM' = mean(`VQWQ')
egen `UQ12M' = mean(`UQ12')
egen `VQ12M' = mean(`VQ12')
egen `WQ12M' = mean(`WQ12')
egen `UQ1VQ1M' = mean(`UQ1VQ1')
egen `UQ1WQ1M' = mean(`UQ1WQ1')
egen `VQ1WQ1M' = mean(`VQ1WQ1')
scalar SUQ2M=`UQ2M'*T1
scalar SVQ2M=`VQ2M'*T1
scalar SWQ2M=`WQ2M'*T1
scalar SUQVQM=`UQVQM'*T1
scalar SUQWQM=`UQWQM'*T1
scalar SVQWQM=`VQWQM'*T1
scalar SUQ12M=`UQ12M'*T2
scalar SVQ12M=`VQ12M'*T2
scalar SWQ12M=`WQ12M'*T2
scalar SUQ1VQ1M=`UQ1VQ1M'*T2
scalar SUQ1WQ1M=`UQ1WQ1M'*T2
scalar SVQ1WQ1M=`VQ1WQ1M'*T2 
tempvar h11 h12 h13 h21 h22 h23 h31 h32 h33 hy1 hy2 hy3
gen `h11'=2*SUQVQM
gen `h12'=-SVQ2M
gen `h13'=1
gen `h21'=2*SVQWQM
gen `h22'=-SWQ2M
gen `h23'=trace(`mtr')
gen `h31'=(SVQ2M+SUQWQM)
gen `h32'=-SVQWQM
gen `h33'=0
gen `hy1'=SUQ2M
gen `hy2'=SVQ2M
gen `hy3'=SUQVQM
collapse `h11' `h12' `h13' `hy1' `h21' `h22' `h23' `hy2' `h31' `h32' `h33' `hy3'
mkmat `h11' `h21' `h31', matrix(`h1t')
mkmat `h12' `h22' `h32', matrix(`h2t')
mkmat `h13' `h23' `h33', matrix(`h3t')
mkmat `hy1' `hy2' `hy3', matrix(`hyt')
qui matrix `h1'=`h1t''
qui matrix `h2'=`h2t''
qui matrix `h3'=`h3t''
qui matrix `hy'=`hyt''
qui set obs 3
tempvar V1 V2 V3 Z
svmat `h1' , name(`V1')
svmat `h2' , name(`V2')
svmat `h3' , name(`V3')
svmat `hy' , name(`Z')
rename `V1'1 `V1'
rename `V2'1 `V2'
rename `V3'1 `V3'
rename `Z'1 `Z'
qui nl (`Z'=`V1'*{Rho} +`V2'*{Rho}^2 +`V3'*{Sigma2}) , init(Rho 0 Sigma2 1) nolog
tempvar Rho
qui gen `Rho'=_b[/Rho]
scalar RHOH=_b[/Rho]
scalar SIGV=_b[/Sigma2]
scalar SIG1=SUQ12M-(2*SUQ1VQ1M*RHOH)-(-1*SVQ12M*(RHOH^2))
scalar VAR1= ((SIGV^2)/(T-1))^0.5
scalar VAR2 = (SIG1^2)^0.5

if L == 1 {
scalar RHOGM=RHOH
scalar SIGVV=SIGV
scalar SIG11=SIG1
tempvar RhoGM
gen `RhoGM'=RHOH
 }

if L == 2 {
scalar VAR11=S*((1*(SIGV^2)/(S*(T-1))))
scalar VAR22=S*((1*(SIGV^2)/(S*(T-1))))
scalar VAR33=S*((1*(SIGV^2)/(S*(T-1))))
scalar VAR44=S*((1*(SIG1^2)/S))
scalar VAR55=S*((1*(SIG1^2)/S))
scalar VAR66=S*((1*(SIG1^2)/S))
scalar VAR12 = 0
scalar VAR23 = 0
scalar VAR45 = 0
scalar VAR56 = 0
 }

if L == 3 {
scalar VAR11 = S*((2*(SIGV^2)/(S*(T-1))))
scalar VAR22 = S*((2*(SIGV^2)/(S*(T-1)))*trace(`MQ0'))
scalar VAR33 = S*((1*(SIGV^2)/(S*(T-1)))*trace(`MQ1'))
scalar VAR44 = S*((2*(SIG1^2)/S))
scalar VAR55 = S*((2*(SIG1^2)/S)*trace(`MQ0'))
scalar VAR66 = S*((1*(SIG1^2)/S)*trace(`MQ1'))
scalar VAR12 = S*(2*(SIGV^2)/(S*(T-1)))*trace(`MWT1')
scalar VAR23 = S*(1*(SIGV^2)/(S*(T-1)))*trace(`MWT2')
scalar VAR45 = S*(2*(SIG1^2)/S)*trace(`MWT1')
scalar VAR56 = S*(1*(SIG1^2)/S)*trace(`MWT2')
 }

if L > 1 {
qui matrix `VCOV'=I(6)
qui matrix `VCOV'[1,1]=VAR11
qui matrix `VCOV'[1,2]=VAR12
qui matrix `VCOV'[2,1]=VAR12
qui matrix `VCOV'[2,2]=VAR22
qui matrix `VCOV'[2,3]=VAR23
qui matrix `VCOV'[3,2]=VAR23
qui matrix `VCOV'[3,3]=VAR33
qui matrix `VCOV'[4,4]=VAR44
qui matrix `VCOV'[4,5]=VAR45
qui matrix `VCOV'[5,4]=VAR45
qui matrix `VCOV'[5,5]=VAR55
qui matrix `VCOV'[5,6]=VAR56
qui matrix `VCOV'[6,5]=VAR56
qui matrix `VCOV'[6,6]=VAR66
qui matrix `VCOV'=inv(`VCOV')
qui matrix `P' = (cholesky(`VCOV'))'
scalar P11 = `P'[1,1]
scalar P12 = `P'[1,2]
scalar P21 = `P'[2,1]
scalar P22 = `P'[2,2]
scalar P23 = `P'[2,3]
scalar P32 = `P'[3,2]
scalar P33 = `P'[3,3]
scalar P44 = `P'[4,4]
scalar P45 = `P'[4,5]
scalar P54 = `P'[5,4]
scalar P55 = `P'[5,5]
scalar P56 = `P'[5,6]
scalar P65 = `P'[6,5]
scalar P66 = `P'[6,6]
tempvar HM11 HM21 HM31 HM41 HM51 HM61
tempvar HM12 HM22 HM32 HM42 HM52 HM62
tempvar HM13 HM23 HM33 HM43 HM53 HM63
tempvar HM14 HM24 HM34 HM44 HM54 HM64
tempvar HMY1 HMY2 HMY3 HMY4 HMY5 HMY6
gen `HM11' = 2*SUQVQM*P11+2*SVQWQM*P12
gen `HM12' = -SVQ2M*P11-SWQ2M*P12
gen `HM13' = 1*P11+trace(`mtr')*P12
gen `HM14' = 0
gen `HMY1' = SUQ2M*P11+SVQ2M*P12
gen `HM21' = 2*SUQVQM*P21+2*SVQWQM*P22+(SVQ2M+SUQWQM)*P23
gen `HM22' = -SVQ2M*P21-SWQ2M*P22-SVQWQM*P23
gen `HM23' = 1*P21+trace(`mtr')*P22
gen `HM24' = 0
gen `HMY2' = SUQ2M*P21+SVQ2M*P22+SUQVQM*P23
gen `HM31' = 2*SVQWQM*P32+(SVQ2M+SUQWQM)*P33
gen `HM32' = -SWQ2M*P32-SVQWQM*P33
gen `HM33' = trace(`mtr')*P32
gen `HM34' = 0
gen `HMY3' = SVQ2M*P32+SUQVQM*P33
gen `HM41' = 2*SUQ1VQ1M*P44+2*SVQ1WQ1M*P45
gen `HM42' = -SVQ12M*P44-SWQ12M*P45
gen `HM43' = 0
gen `HM44' = 1*P44+trace(`mtr')*P45
gen `HMY4' = SUQ12M*P44+SVQ12M*P45
gen `HM51' = 2*SUQ1VQ1M*P54+2*SVQ1WQ1M*P55+(SVQ12M+SUQ1WQ1M)*P56
gen `HM52' = -SVQ12M*P54-SWQ12M*P55-SVQ1WQ1M*P56
gen `HM53' = 0
gen `HM54' = 1*P54+trace(`mtr')*P55
gen `HMY5' = SUQ12M*P54+SVQ12M*P55+SUQ1VQ1M*P56
gen `HM61' = 2*SVQ1WQ1M*P65+(SVQ12M+SUQ1WQ1M)*P66
gen `HM62' = -SWQ12M*P65-SVQ1WQ1M*P66
gen `HM63' = 0
gen `HM64' = trace(`mtr')*P65
gen `HMY6' = SVQ12M*P65+SUQ1VQ1M*P66

collapse `HM11' `HM12' `HM13' `HM14' `HMY1' `HM21' `HM22' `HM23' `HM24' `HMY2' ///
`HM31' `HM32' `HM33' `HM34' `HMY3' `HM41' `HM42' `HM43' `HM44' `HMY4' `HM51' ///
`HM52' `HM53' `HM54' `HMY5' `HM61' `HM62' `HM63' `HM64' `HMY6'
mkmat `HM11' `HM21' `HM31' `HM41' `HM51' `HM61', matrix(`HM1t')
mkmat `HM12' `HM22' `HM32' `HM42' `HM52' `HM62', matrix(`HM2t')
mkmat `HM13' `HM23' `HM33' `HM43' `HM53' `HM63', matrix(`HM3t')
mkmat `HM14' `HM24' `HM34' `HM44' `HM54' `HM64', matrix(`HM4t')
mkmat `HMY1' `HMY2' `HMY3' `HMY4' `HMY5' `HMY6', matrix(`HMYt')
qui matrix `HM1'=`HM1t''
qui matrix `HM2'=`HM2t''
qui matrix `HM3'=`HM3t''
qui matrix `HM4'=`HM4t''
qui matrix `HMY'=`HMYt''
qui set obs 6
tempvar V1 V2 V3 V4 Z
svmat `HM1' , name(`V1')
svmat `HM2' , name(`V2')
svmat `HM3' , name(`V3')
svmat `HM4' , name(`V4')
svmat `HMY' , name(`Z')
rename `V1'1 `V1'
rename `V2'1 `V2'
rename `V3'1 `V3'
rename `V4'1 `V4'
rename `Z'1 `Z'
qui nl (`Z'=`V1'*{Rho}+`V2'*{Rho}^2+`V3'*{sigv}+`V4'*{sig1}), init(Rho 0 sigv 1 sig1 1) nolog
tempvar RhoGM
gen `RhoGM'=_b[/Rho]
scalar RHOGM=_b[/Rho]
scalar SIGVV=_b[/sigv]
scalar SIG11=_b[/sig1]
 }

scalar RhoGM=`RhoGM'
qui matrix `matg'=`matt'#(`mats'-RhoGM*`wmat')
qui matrix `OMGINV' = (1/(SIGVV^0.5))*`Q0' + (1/(SIG11^0.5))*`Q1'
restore 

preserve
mkmat `yvar', matrix(`yvar')
qui matrix `yvar'=`matg'*`yvar'
qui matrix `yvar'=`OMGINV'*`yvar'
qui cap drop `yvar'
svmat `yvar', name(`yvar')
qui rename `yvar'1 `yvar'
gen `X0'=1
mkmat `X0' , matrix(`X0')
qui matrix `X0'=`matg'*`X0'
qui matrix `X0'=`OMGINV'*`X0'
svmat `X0' , name(`X0')
qui rename `X0'1 _Cons

foreach var of local xvar {
mkmat `var' , matrix(`var')
qui matrix `var'=`matg'*`var'
qui matrix `var'=`OMGINV'*`var'
qui cap drop `var'
svmat `var' , name(`var')
qui rename `var'1 `var'
 } 
 }

local `xvar' `var'*
if L==1 {
di as txt _col(3) "{bf:* Initial GMM Model: 1 }"
 }
if L==2 {
di as txt _col(3) "{bf:* Partial Weighted GMM Model: 2 }"
 }
if L==3 {
di as txt _col(3) "{bf:* Full Weighted GMM Model: 3 }"
 }
 if "`noconstant'"!=""  { 
regress `yvar' `xvar' if `touse' `wgt' , noconstant depname(`yvar') `vce' `robust'
 }
 else {
regress `yvar' `xvar' _Cons if `touse' `wgt' , noconstant depname(`yvar') `vce' `robust'
 }
restore
qui cap drop V1 V2 V3 V4 Vy
qui cap drop V1 V2 V3 Z _merge
end

program define gs2slsxt2 , eclass 
 version 10.1
syntax varlist [if] [in] , [gmm(int 1) small nosa be fe re ec2sls sa ///
 coll vce(passthru) aux(str) ORDer(int 1) *]
 tempvar `varlist'
 gettoken yvar xvar : varlist
 marksample touse
preserve
 qui {
tempname matg h1 h1t h2 h2t h3 h3t HM1 HM1t HM2 HM2t HM3 HM3t HM4 HM4t HMY
tempname HMYt hy Z0 hyt mats matj wmat wmat1 mtr MQ0 MQ1 MW1 MWT1 MWT2 MWT21
tempname MW2 MW3 MW4 OMGINV Q0 Q1 P matt Q1UVEC UQVEC VCOV Q1VVEC
tempname VQVEC VVEC Q1WVEC WQVEC WVEC UVEC XB Bx BetaSP WS1 WS2 WS3 WS4
tempvar ss2 u u2 RhoGM res res2 E E2 SSE Yh Ys Yh_ML Y Ue_ML
qui matrix `wmat'=WSPGLS
qui matrix `mtr'=trace(`wmat''*`wmat')/_N
qui matrix `mats'=I(S)
qui matrix `matt'=I(T)
qui matrix `matj'=J(T,T,1/T)
qui matrix `wmat1'=`matt'#`wmat'
qui matrix `Q0'=(`matt'-`matj')#`mats'
qui matrix `Q1'=`matj'#`mats'
qui matrix `MW1'=`wmat''*`wmat'
qui matrix `MWT1'=trace(`MW1')/S
qui matrix `MWT21'=`MW1'*(`wmat'+`wmat'')
qui matrix `MWT2'=trace(`MWT21')/S
qui matrix `MW2'=`wmat'*`wmat'
qui matrix `MW3'=`MW1'*`MW1'
qui matrix `MW4'=`MW1'+`MW2'
qui matrix `MQ0'=trace(`MW3')/S
qui matrix `MQ1'=trace(`MW4')/S
qui cap matrix drop `MWT21' `MW1' `MW2' `MW3' `MW4'
qui cap drop w1y_`yvar'
 mkmat `yvar' , matrix(`yvar')
 matrix w1y_`yvar' = `wmat1'*`yvar'
 svmat w1y_`yvar' , name(w1y_`yvar')
 rename w1y_`yvar'1 w1y_`yvar'
matrix `WS1'= `wmat1'
matrix `WS2'= `wmat1'*`wmat1'
matrix `WS3'= `wmat1'*`wmat1'*`wmat1'
matrix `WS4'= `wmat1'*`wmat1'*`wmat1'*`wmat1'
if "`order'"!="" {
qui forvalues i = 1/`order' {
qui foreach var of local xvar {
qui cap drop w`i'x_`var'
tempname w`i'x_`var'
mkmat `var' if `touse' , matrix(`var')
matrix `w`i'x_`var'' = `WS`i''*`var'
svmat `w`i'x_`var'' , name(w`i'x_`var')
rename w`i'x_`var'1 w`i'x_`var'
 }
 }
 }
 if "`order'"=="1" {
local zvar w1x_* `aux'
qui cap drop w2x_*
qui cap drop w3x_*
qui cap drop w4x_*
 }
 if "`order'"=="2" {
local zvar w1x_* w2x_* `aux'
qui cap drop w3x_*
qui cap drop w4x_*
 }
 if "`order'"=="3" {
local zvar w1x_* w2x_* w3x_* `aux'
qui cap drop w4x_*
 }
 if "`order'"=="4" {
local zvar w1x_* w2x_* w3x_* w4x_* `aux'
 }
 
qui xtivreg `yvar' `xvar' `aux' (w1y_`yvar' = `xvar' `zvar' ) if `touse' , `small' ///
`vce' `nosa' `be' `fe' `re' `ec2sls' `sa' `coll'
matrix `BetaSP'=e(b)
matrix `Bx'=`BetaSP'[1,1..kb]
qui predict `Yh_ML' if `touse' , xb
qui gen `res' =`yvar'-`Yh_ML' if `touse' 
qui gen `res2'=`res'^2
qui cap drop WY W1X_* W2X_*
scalar L=`gmm'
mkmat `res' , matrix(`UVEC')
qui matrix `VVEC'=`wmat1'*`UVEC'
qui matrix `WVEC'=`wmat1'*`VVEC'
qui matrix `UQVEC'=`Q0'*`UVEC'
qui matrix `VQVEC'=`Q0'*`VVEC'
qui matrix `WQVEC'=`Q0'*`WVEC'
qui matrix `Q1UVEC'=`Q1'*`UVEC'
qui matrix `Q1VVEC'=`Q1'*`VVEC'
qui matrix `Q1WVEC'=`Q1'*`WVEC'
tempvar US VS WS UQS VQS WQS UTS VTS WTS
qui svmat `UVEC', name(`US')
qui svmat `VVEC', name(`VS')
qui svmat `WVEC', name(`WS')
qui svmat `UQVEC', name(`UQS')
qui svmat `VQVEC', name(`VQS')
qui svmat `WQVEC', name(`WQS')
qui svmat `Q1UVEC' , name(`UTS')
qui svmat `Q1VVEC' , name(`VTS')
qui svmat `Q1WVEC' , name(`WTS')
qui cap matrix drop `VVEC' `UVEC' `WVEC'
qui cap matrix drop `UQVEC' `VQVEC' `WQVEC' `Q1UVEC' `Q1VVEC' `Q1WVEC'
rename `US'1 `US'
rename `VS'1 `VS'
rename `WS'1 `WS'
rename `UQS'1 `UQS'
rename `VQS'1 `VQS'
rename `WQS'1 `WQS'
rename `UTS'1 `UTS'
rename `VTS'1 `VTS'
rename `WTS'1 `WTS'
tempvar UQ2 VQ2 WQ2 UQVQ UQWQ VQWQ UQ12 VQ12 WQ12 UQ1VQ1 UQ1WQ1 VQ1WQ1
gen `UQ2'=`UQS'*`UQS'
gen `VQ2'=`VQS'*`VQS'
gen `WQ2'=`WQS'*`WQS'
gen `UQVQ'=`UQS'*`VQS'
gen `UQWQ'=`UQS'*`WQS'
gen `VQWQ'=`VQS'*`WQS'
gen `UQ12'=`UTS'*`UTS'
gen `VQ12'=`VTS'*`VTS'
gen `WQ12'=`WTS'*`WTS'
gen `UQ1VQ1'=`UTS'*`VTS'
gen `UQ1WQ1'=`UTS'*`WTS'
gen `VQ1WQ1'=`VTS'*`WTS'
mat `mtr'=trace(`wmat''*`wmat')/S
scalar T1=T/(T-1)
scalar T2=T
tempvar UQ2M VQ2M WQ2M UQVQM UQWQM VQWQM UQ12M VQ12M WQ12M UQ1VQ1M UQ1WQ1M VQ1WQ1M
egen `UQ2M' = mean(`UQ2')
egen `VQ2M' = mean(`VQ2')
egen `WQ2M' = mean(`WQ2')
egen `UQVQM' = mean(`UQVQ')
egen `UQWQM' = mean(`UQWQ')
egen `VQWQM' = mean(`VQWQ')
egen `UQ12M' = mean(`UQ12')
egen `VQ12M' = mean(`VQ12')
egen `WQ12M' = mean(`WQ12')
egen `UQ1VQ1M' = mean(`UQ1VQ1')
egen `UQ1WQ1M' = mean(`UQ1WQ1')
egen `VQ1WQ1M' = mean(`VQ1WQ1')
scalar SUQ2M=`UQ2M'*T1
scalar SVQ2M=`VQ2M'*T1
scalar SWQ2M=`WQ2M'*T1
scalar SUQVQM=`UQVQM'*T1
scalar SUQWQM=`UQWQM'*T1
scalar SVQWQM=`VQWQM'*T1
scalar SUQ12M=`UQ12M'*T2
scalar SVQ12M=`VQ12M'*T2
scalar SWQ12M=`WQ12M'*T2
scalar SUQ1VQ1M=`UQ1VQ1M'*T2
scalar SUQ1WQ1M=`UQ1WQ1M'*T2
scalar SVQ1WQ1M=`VQ1WQ1M'*T2 
tempvar h11 h12 h13 h21 h22 h23 h31 h32 h33 hy1 hy2 hy3
gen `h11'=2*SUQVQM
gen `h12'=-SVQ2M
gen `h13'=1
gen `h21'=2*SVQWQM
gen `h22'=-SWQ2M
gen `h23'=trace(`mtr')
gen `h31'=(SVQ2M+SUQWQM)
gen `h32'=-SVQWQM
gen `h33'=0
gen `hy1'=SUQ2M
gen `hy2'=SVQ2M
gen `hy3'=SUQVQM
collapse `h11' `h12' `h13' `hy1' `h21' `h22' `h23' `hy2' `h31' `h32' `h33' `hy3'
mkmat `h11' `h21' `h31', matrix(`h1t')
mkmat `h12' `h22' `h32', matrix(`h2t')
mkmat `h13' `h23' `h33', matrix(`h3t')
mkmat `hy1' `hy2' `hy3', matrix(`hyt')
qui matrix `h1'=`h1t''
qui matrix `h2'=`h2t''
qui matrix `h3'=`h3t''
qui matrix `hy'=`hyt''
qui set obs 3
tempvar V1 V2 V3 Z
svmat `h1' , name(`V1')
svmat `h2' , name(`V2')
svmat `h3' , name(`V3')
svmat `hy' , name(`Z')
rename `V1'1 `V1'
rename `V2'1 `V2'
rename `V3'1 `V3'
rename `Z'1 `Z'

qui nl (`Z'=`V1'*{Rho} +`V2'*{Rho}^2 +`V3'*{Sigma2}) , init(Rho 0.3 Sigma2 1) nolog
tempvar Rho
qui gen `Rho'=_b[/Rho]
scalar RHOH=_b[/Rho]
scalar SIGV=_b[/Sigma2]
scalar SIG1=SUQ12M-(2*SUQ1VQ1M*RHOH)-(-1*SVQ12M*(RHOH^2))
scalar VAR1= ((SIGV^2)/(T-1))^0.5
scalar VAR2 = (SIG1^2)^0.5
if L == 1 {
scalar RHOGM=RHOH
scalar SIGVV=SIGV
scalar SIG11=SIG1
tempvar RhoGM
gen `RhoGM'=RHOH
 }
if L == 2 {
scalar VAR11=S*((1*(SIGV^2)/(S*(T-1))))
scalar VAR22=S*((1*(SIGV^2)/(S*(T-1))))
scalar VAR33=S*((1*(SIGV^2)/(S*(T-1))))
scalar VAR44=S*((1*(SIG1^2)/S))
scalar VAR55=S*((1*(SIG1^2)/S))
scalar VAR66=S*((1*(SIG1^2)/S))
scalar VAR12 = 0
scalar VAR23 = 0
scalar VAR45 = 0
scalar VAR56 = 0
 }
if L == 3 {
scalar VAR11 = S*((2*(SIGV^2)/(S*(T-1))))
scalar VAR22 = S*((2*(SIGV^2)/(S*(T-1)))*trace(`MQ0'))
scalar VAR33 = S*((1*(SIGV^2)/(S*(T-1)))*trace(`MQ1'))
scalar VAR44 = S*((2*(SIG1^2)/S))
scalar VAR55 = S*((2*(SIG1^2)/S)*trace(`MQ0'))
scalar VAR66 = S*((1*(SIG1^2)/S)*trace(`MQ1'))
scalar VAR12 = S*(2*(SIGV^2)/(S*(T-1)))*trace(`MWT1')
scalar VAR23 = S*(1*(SIGV^2)/(S*(T-1)))*trace(`MWT2')
scalar VAR45 = S*(2*(SIG1^2)/S)*trace(`MWT1')
scalar VAR56 = S*(1*(SIG1^2)/S)*trace(`MWT2')
 }
if L > 1 {
qui matrix `VCOV'=I(6)
qui matrix `VCOV'[1,1]=VAR11
qui matrix `VCOV'[1,2]=VAR12
qui matrix `VCOV'[2,1]=VAR12
qui matrix `VCOV'[2,2]=VAR22
qui matrix `VCOV'[2,3]=VAR23
qui matrix `VCOV'[3,2]=VAR23
qui matrix `VCOV'[3,3]=VAR33
qui matrix `VCOV'[4,4]=VAR44
qui matrix `VCOV'[4,5]=VAR45
qui matrix `VCOV'[5,4]=VAR45
qui matrix `VCOV'[5,5]=VAR55
qui matrix `VCOV'[5,6]=VAR56
qui matrix `VCOV'[6,5]=VAR56
qui matrix `VCOV'[6,6]=VAR66
qui matrix `VCOV'=inv(`VCOV')
qui matrix `P' = (cholesky(`VCOV'))'
scalar P11 = `P'[1,1]
scalar P12 = `P'[1,2]
scalar P21 = `P'[2,1]
scalar P22 = `P'[2,2]
scalar P23 = `P'[2,3]
scalar P32 = `P'[3,2]
scalar P33 = `P'[3,3]
scalar P44 = `P'[4,4]
scalar P45 = `P'[4,5]
scalar P54 = `P'[5,4]
scalar P55 = `P'[5,5]
scalar P56 = `P'[5,6]
scalar P65 = `P'[6,5]
scalar P66 = `P'[6,6]
tempvar HM11 HM21 HM31 HM41 HM51 HM61
tempvar HM12 HM22 HM32 HM42 HM52 HM62
tempvar HM13 HM23 HM33 HM43 HM53 HM63
tempvar HM14 HM24 HM34 HM44 HM54 HM64
tempvar HMY1 HMY2 HMY3 HMY4 HMY5 HMY6
gen `HM11' = 2*SUQVQM*P11+2*SVQWQM*P12
gen `HM12' = -SVQ2M*P11-SWQ2M*P12
gen `HM13' = 1*P11+trace(`mtr')*P12
gen `HM14' = 0
gen `HMY1' = SUQ2M*P11+SVQ2M*P12
gen `HM21' = 2*SUQVQM*P21+2*SVQWQM*P22+(SVQ2M+SUQWQM)*P23
gen `HM22' = -SVQ2M*P21-SWQ2M*P22-SVQWQM*P23
gen `HM23' = 1*P21+trace(`mtr')*P22
gen `HM24' = 0
gen `HMY2' = SUQ2M*P21+SVQ2M*P22+SUQVQM*P23
gen `HM31' = 2*SVQWQM*P32+(SVQ2M+SUQWQM)*P33
gen `HM32' = -SWQ2M*P32-SVQWQM*P33
gen `HM33' = trace(`mtr')*P32
gen `HM34' = 0
gen `HMY3' = SVQ2M*P32+SUQVQM*P33
gen `HM41' = 2*SUQ1VQ1M*P44+2*SVQ1WQ1M*P45
gen `HM42' = -SVQ12M*P44-SWQ12M*P45
gen `HM43' = 0
gen `HM44' = 1*P44+trace(`mtr')*P45
gen `HMY4' = SUQ12M*P44+SVQ12M*P45
gen `HM51' = 2*SUQ1VQ1M*P54+2*SVQ1WQ1M*P55+(SVQ12M+SUQ1WQ1M)*P56
gen `HM52' = -SVQ12M*P54-SWQ12M*P55-SVQ1WQ1M*P56
gen `HM53' = 0
gen `HM54' = 1*P54+trace(`mtr')*P55
gen `HMY5' = SUQ12M*P54+SVQ12M*P55+SUQ1VQ1M*P56
gen `HM61' = 2*SVQ1WQ1M*P65+(SVQ12M+SUQ1WQ1M)*P66
gen `HM62' = -SWQ12M*P65-SVQ1WQ1M*P66
gen `HM63' = 0
gen `HM64' = trace(`mtr')*P65
gen `HMY6' = SVQ12M*P65+SUQ1VQ1M*P66
collapse `HM11' `HM12' `HM13' `HM14' `HMY1' `HM21' `HM22' `HM23' `HM24' `HMY2' ///
`HM31' `HM32' `HM33' `HM34' `HMY3' `HM41' `HM42' `HM43' `HM44' `HMY4' `HM51' ///
`HM52' `HM53' `HM54' `HMY5' `HM61' `HM62' `HM63' `HM64' `HMY6'
mkmat `HM11' `HM21' `HM31' `HM41' `HM51' `HM61', matrix(`HM1t')
mkmat `HM12' `HM22' `HM32' `HM42' `HM52' `HM62', matrix(`HM2t')
mkmat `HM13' `HM23' `HM33' `HM43' `HM53' `HM63', matrix(`HM3t')
mkmat `HM14' `HM24' `HM34' `HM44' `HM54' `HM64', matrix(`HM4t')
mkmat `HMY1' `HMY2' `HMY3' `HMY4' `HMY5' `HMY6', matrix(`HMYt')
qui matrix `HM1'=`HM1t''
qui matrix `HM2'=`HM2t''
qui matrix `HM3'=`HM3t''
qui matrix `HM4'=`HM4t''
qui matrix `HMY'=`HMYt''
qui set obs 6
tempvar V1 V2 V3 V4 Z
svmat `HM1' , name(`V1')
svmat `HM2' , name(`V2')
svmat `HM3' , name(`V3')
svmat `HM4' , name(`V4')
svmat `HMY' , name(`Z')
rename `V1'1 `V1'
rename `V2'1 `V2'
rename `V3'1 `V3'
rename `V4'1 `V4'
rename `Z'1 `Z'
qui nl (`Z'=`V1'*{Rho}+`V2'*{Rho}^2+`V3'*{sigv}+`V4'*{sig1}), init(Rho 0 sigv 1 sig1 1) nolog
tempvar RhoGM
gen `RhoGM'=_b[/Rho]
scalar RHOGM=_b[/Rho]
scalar SIGVV=_b[/sigv]
scalar SIG11=_b[/sig1]
 }
scalar RhoGM=`RhoGM'
qui matrix `matg'=`matt'#(`mats'-RhoGM*`wmat')
qui matrix `OMGINV' = (1/(SIGVV^0.5))*`Q0' + (1/(SIG11^0.5))*`Q1'
restore 
preserve
mkmat `yvar' , matrix(`yvar')
qui matrix `yvar'=`matg'*`yvar'
qui matrix `yvar'=`OMGINV'*`yvar'
qui cap drop `yvar' w1y_`yvar'
svmat `yvar', name(`yvar')
qui rename `yvar'1 `yvar'
qui matrix w1y_`yvar'=`wmat1'*`yvar'
svmat w1y_`yvar' , name(w1y_`yvar')
qui rename w1y_`yvar'1 w1y_`yvar'
foreach var of local xvar {
mkmat `var' , matrix(`var')
qui matrix `var'=`matg'*`var'
qui matrix `var'=`OMGINV'*`var'
qui cap drop `var'
svmat `var' , name(`var')
qui rename `var'1 `var'
 } 
local `xvar' `var'*
 }
if "`order'"!="" {
qui forvalues i = 1/`order' {
qui foreach var of local xvar {
qui cap drop w`i'x_`var'
tempname w`i'x_`var'
matrix `w`i'x_`var'' = `WS`i''*`var'
svmat `w`i'x_`var'' , name(w`i'x_`var')
rename w`i'x_`var'1 w`i'x_`var'
 }
 }
 }
 if "`order'"=="1" {
local zvar w1x_* `aux'
qui cap drop w2x_*
qui cap drop w3x_*
qui cap drop w4x_*
 }
 if "`order'"=="2" {
local zvar w1x_* w2x_* `aux'
qui cap drop w3x_*
qui cap drop w4x_*
 }
 if "`order'"=="3" {
local zvar w1x_* w2x_* w3x_* `aux'
qui cap drop w4x_*
 }
 if "`order'"=="4" {
local zvar w1x_* w2x_* w3x_* w4x_* `aux'
 }
if L==1 {
di as txt _col(3) "{bf:* Initial GMM Model: 1 }"
 }
if L==2 {
di as txt _col(3) "{bf:* Partial Weighted GMM Model: 2 }"
 }
if L==3 {
di as txt _col(3) "{bf:* Full Weighted GMM Model: 3 }"
 }
 xtivreg `yvar' `xvar' `aux' (w1y_`yvar' = `xvar' `zvar' ) if `touse' , ///
`small' `vce' `nosa' `be' `fe' `re' `ec2sls' `sa' 
restore
matrix `BetaSP'=e(b)
matrix `BetaSP'=`BetaSP'[1,1..kb]
qui cap drop V1 V2 V3 V4 Vy
qui cap drop V1 V2 V3 Z _merge
end

program define yxregeq
version 10.0
 syntax varlist 
tempvar `varlist'
 gettoken yvar xvar : varlist
local LEN=length("`yvar'")
local LEN=`LEN'+3
di "{p 2 `LEN' 5}" as res "{bf:`yvar'}" as txt " = " "
local NX : word count `xvar'
local i=1
 while `i'<=`NX' {
local X : word `i' of `xvar'
 if `i'<`NX' {
di " " as res " {bf:`X'}" _c
di as txt " + " _c
 }
 if `i'==`NX' {
di " " as res "{bf:`X'}"
 }
local i=`i'+1
 }
di "{p_end}"
di as txt "{hline 78}"
end

