*! spmstarxt V1.0 03jan2012
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage: http://emadstat.110mb.com/stata.htm
 
program define spmstarxt, eclass 
 version 10.1
if replay() {
if "`e(cmd)'"!="spmstarxt" {
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
syntax varlist [if] [in] [aw fw iw pw] , id(str) [WMFile(str) WMat(str) ///
EIGw(str) aux(str) vce(passthru) ROBust noLOG iter(int 50) level(passthru) ///
tech(str) NOCONStant stand NWmat(str) PREDict(str) RESid(str) *] 
 tempvar `varlist'
 gettoken yvar xvar : varlist
 marksample touse
 markout `touse' 
 tempvar X0 panel tm idv itv X
 tempname X0 X XB Bx 
 local sthlp spmstarxt
 mlopts mlopts, `options'
 local cns `s(constraints)'
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
 if "`xvar'"=="" {
di as err "  {bf:Independent Variable(s) must be combined with Dependent Variable}"
 exit
 }
 if "`wmfile'"!="" & "`wmat'"=="" {
di as err " {bf:wmfile( )} {cmd:and} {bf:wmat( )} {cmd:must be combined}"
 exit
 }
 if "`wmat'"!="" & "`eigw'"=="" {
di as err " {bf:wmat( )} {cmd:and} {bf:eigw( )} {cmd:must be combined}"
 exit
 }
 if "`wmat'"=="" & "`eigw'"!="" {
di as err " {bf:wmat( )} {cmd:and} {bf:eigw( )} {cmd:must be combined}"
 exit
 }
 if "`wmat'"!="" & "`wmfile'"=="" {
di as err " {bf:wmat( )} {cmd:and} {bf:wmfile( )} {cmd:must be combined}"
 exit
 }
 if "`nwmat'"!="" {
if !inlist("`nwmat'", "1", "2", "3", "4") {
di 
di as err " {bf:nwmat(#)} {cmd:number must be 1, 2, 3, or 4.}"
di
exit
 } 
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
matrix W`i'=`wmat'
 }
 }
 }

qui cap drop `Yh_ML'
qui cap drop `Ue_ML'
tempvar Yh_ML Ue_ML
tempname BetaSP Ue_Diag Yh_Diag
qui xtset `idv' `itv'
qui cap confirm numeric var `eigw'
qui cap summ `eigw'
qui sum `yvar' if `touse' 
local kaux : word count `aux'
scalar kaux=`kaux'
local SPXvar `xvar' `aux'
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
global nobs = _N
mat I_n = I(NT)
qui regress `yvar' `SPXvar' if `touse' `wgt' , `noconstant'
tempname Bo Y
matrix `Bo'=e(b)
local rmse=e(rmse)
mkmat `yvar' if `touse' , matrix(`Y')
qui forv i=1/$spat_kx {
local var : word `i' of `SPXvar'
local COLNAME "`COLNAME'`yvar':`var' " 
 }
 
if  "`nwmat'"=="1" {
local MName1 "Spatial Panel Model"
local MName "mSTAR Spatial Panel Lag Normel Model (1)"
tempname SL1
matrix `SL1' = W1*`Y'
qui cap drop w1y_`yvar'
svmat `SL1', name(w1y_`yvar')
rename w1y_`yvar'1 w1y_`yvar'
 tempname olsin ols
 matrix `olsin'=`Bo',0,`rmse'
local initopt init(`olsin', copy) search(on) `log' `mlopts' 
 matrix `ols'=`olsin'[1,1..$spat_kx+2]
ml model lf spmstarxt1_lf (`yvar': `yvar' = `SPXvar' , `noconstant') ///
 (Rho1:) (Sigma:) if `touse' `wgt' , `robust' `vce' `log' `mlopts' coll ///
 `contin' `diparm' `initopt' maximize iter(`iter') tech(`tech') title(`MName')
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Multiparametric Spatio Temporal AutoRegressive Regression}}"
di as txt "{bf:{err:* (m-STAR) Spatial Panel Lag Model (1 Weight Matrix)}}"
di _dup(78) "{bf:{err:=}}"
yxregeq `yvar' `SPXvar' 
matrix `BetaSP'=e(b)
scalar rRo=[Rho1]_b[_cons]
qui test [Rho1]_cons
local COLNAME " `COLNAME'`yvar':_cons  Rho1:_cons Sigma:_cons"
 }

if "`nwmat'"=="2" {
local MName "mSTAR Spatial Panel Lag Normel Model (2)"
qui forvalues i=1/2 {
tempname SL`i'
qui cap drop w`i'y_`yvar'
matrix `SL`i'' = W`i'*`Y'
svmat `SL`i'' , name(w`i'y_`yvar')
rename w`i'y_`yvar'1 w`i'y_`yvar'
 }
 tempname olsin ols
 matrix `olsin'=`Bo',0,0,`rmse'
local initopt init(`olsin', copy) search(on) `nolog' `mlopts' 
 matrix `ols'=`olsin'[1,1..$spat_kx+2]
ml model lf spmstarxt2_lf (`yvar': `yvar' = `SPXvar' , `noconstant') ///
(Rho1:) (Rho2:) (Sigma:) if `touse' `wgt' , `robust' `vce' `log' `mlopts' coll ///
`contin' `diparm' `initopt' maximize iter(`iter') tech(`tech') title(`MName')
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Multiparametric Spatio Temporal AutoRegressive Regression}}"
di as txt "{bf:{err:* (m-STAR) Spatial Panel Lag Model (2 Weight Matrixes)}}"
di _dup(78) "{bf:{err:=}}"
yxregeq `yvar' `SPXvar'
matrix `BetaSP'=e(b)
scalar rRo=[Rho1]_b[_cons]+[Rho2]_b[_cons]
qui test [Rho1]_cons [Rho2]_cons
local COLNAME " `COLNAME'`yvar':_cons Rho1:_cons Rho2:_cons Sigma:_cons"
 }

if "`nwmat'"=="3" {
local MName "mSTAR Spatial Panel Lag Normel Model (3)"
qui forvalues i=1/3 {
tempname SL`i'
qui cap drop w`i'y_`yvar'
matrix `SL`i'' = W`i'*`Y'
svmat `SL`i'' , name(w`i'y_`yvar')
rename w`i'y_`yvar'1 w`i'y_`yvar'
 }
 tempname olsin ols
 matrix `olsin'=`Bo',0,0,0,`rmse'
local initopt init(`olsin', copy) search(on) `nolog' `mlopts' 
 matrix `ols'=`olsin'[1,1..$spat_kx+2]
ml model lf spmstarxt3_lf (`yvar': `yvar' = `SPXvar' , `noconstant') ///
(Rho1:) (Rho2:) (Rho3:) (Sigma:) if `touse' `wgt' , `robust' `vce' `log' `mlopts' ///
coll `contin' `diparm' `initopt' maximize iter(`iter') tech(`tech') title(`MName')
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Multiparametric Spatio Temporal AutoRegressive Regression}}"
di as txt "{bf:{err:* (m-STAR) Spatial Panel Lag Model (3 Weight Matrixes)}}"
di _dup(78) "{bf:{err:=}}"
yxregeq `yvar' `SPXvar'
matrix `BetaSP'=e(b)
scalar rRo=[Rho1]_b[_cons]+[Rho2]_b[_cons]+[Rho3]_b[_cons]
qui test [Rho1]_cons [Rho2]_cons [Rho3]_cons
local COLNAME " `COLNAME'`yvar':_cons Rho1:_cons Rho2:_cons Rho3:_cons Sigma:_cons"
 }

if "`nwmat'"=="4" {
local MName "mSTAR Spatial Panel Lag Normel Model (4)"
qui forvalues i=1/4 {
tempname SL`i'
qui cap drop w`i'y_`yvar'
matrix `SL`i'' = W`i'*`Y'
svmat `SL`i'' , name(w`i'y_`yvar')
rename w`i'y_`yvar'1 w`i'y_`yvar'
 }
 tempname olsin ols
 matrix `olsin'=`Bo',0,0,0,0,`rmse'
local initopt init(`olsin', copy) search(on) `nolog' `mlopts' 
 matrix `ols'=`olsin'[1,1..$spat_kx+2]
ml model lf spmstarxt4_lf (`yvar': `yvar' = `SPXvar' , `noconstant') ///
(Rho1:) (Rho2:) (Rho3:) (Rho4:) (Sigma:) if `touse' `wgt' , `robust' `vce' coll ///
`log' `mlopts' `contin' `diparm' `initopt' maximize iter(`iter') ///
 tech(`tech') title(`MName')
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Multiparametric Spatio Temporal AutoRegressive Regression}}"
di as txt "{bf:{err:* (m-STAR) Spatial Panel Lag Model (4 Weight Matrixes)}}"
di _dup(78) "{bf:{err:=}}"
yxregeq `yvar' `SPXvar'
matrix `BetaSP'=e(b)
scalar rRo=[Rho1]_b[_cons]+[Rho2]_b[_cons]+[Rho3]_b[_cons]+[Rho4]_b[_cons]
qui test [Rho1]_cons [Rho2]_cons [Rho3]_cons [Rho4]_cons
local COLNAME " `COLNAME'`yvar':_cons Rho1:_cons Rho2:_cons Rho3:_cons Rho4:_cons Sigma:_cons"
 }
scalar waldm=e(chi2)
scalar waldmp=e(p)
scalar waldm_df=e(df_m)
scalar waldr=r(chi2)
scalar waldrp=r(p)
scalar waldr_df=r(df)
ereturn repost b=`BetaSP' , rename
matrix `BetaSP'=e(b)
matrix `Bx'=`BetaSP'[1,1..kb]
qui predict `Yh_ML' if `touse' , xb
qui predict `Ue_ML' if `touse' , `res'
scalar llf=e(ll)
scalar aic= 2*kb-2*llf
scalar sc =kb*log(e(N))-2*llf

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
 Display, `level' `robust'
tempname XXZ XB IRW In Yh_ML Bx Ue_Diag Yh_Diag
qui cap drop `Z0'
tempvar Z0
qui gen `Z0' = 1 
 if "`noconstant'"!="" {
 matrix `Bx'=`BetaSP'[1, 1..kx]
 mkmat `SPXvar' , matrix(`XXZ')
 }
 else if "`noconstant'"=="" {
 matrix `Bx'=`BetaSP'[1, 1..kb]
 mkmat `SPXvar' `Z0' , matrix(`XXZ')
 }
matrix `In'=I(_N)
matrix `XB'=`XXZ'*`Bx''
matrix `IRW' = inv(`In'-rRo*`wmat')
matrix `Yh_ML'=`IRW'*`XB'
qui cap drop `Yh_ML'
qui cap drop `Ue_ML'
svmat `Yh_ML' , name(`Yh_ML')
qui rename `Yh_ML'1 `Yh_ML'
qui gen `Ue_ML' =`yvar'-`Yh_ML' 
 if "`predict'"!= "" {
qui cap drop `predict'
qui gen `predict'=`Yh_ML' 
 label variable `predict' `"Yh - Prediction"'
 }
 if  "`resid'"!= "" {
qui cap drop `resid'
qui gen `resid' = `Ue_ML' 
label variable `resid' `"U - Residual"'
 }
qui forvalues i = 1/4 {
qui cap matrix drop p`i'W`i'
 }
qui cap matrix drop ols
qui cap matrix drop w1y_`yvar'
qui cap matrix drop `yvar'
qui cap drop Yh_ML Ue_ML
qui forvalues i = 1/4 {
qui foreach var of local SPXvar {
qui cap matrix drop `var'
 }
 } 
end

program define Display
version 10.0
 syntax, [Level(int $S_level) robust]
di as res "`e(title)'" as txt _col(54) "Number of obs =" _col(72) as res %7.0f `e(N)' 
 if "`robust'"=="" {
di as res _col(27) "Model LR Test =" _col(41) as res %9.3f waldm as txt _col(54) "P-Value > Chi2("as res waldm_df as txt")" _col(74) as res %5.3f waldmp
 }
 else  if "`robust'"!="" {
di as res _col(25) "Model Wald Test =" _col(41) as res %9.3f waldm as txt _col(54) "P-Value > Chi2("as res waldm_df as txt")" _col(74) as res %5.3f waldmp
 } 
di as txt "R2h =" %7.4f as res r2h as txt " - R2h Adj.=" as res %7.4f r2h_a as txt "  F-Test =" %9.3f as res fth as txt "   P-Value > F("df1 ", " df2 ")" %5.3f as res _col(74) fthp
if e(r2v) < 1 {
di as txt "R2v =" %7.4f as res r2v as txt " - R2v Adj.=" as res %7.4f r2v_a as txt "  F-Test =" %9.3f as res ftv as txt "   P-Value > F("df1 ", " df2 ")" %5.3f as res _col(74) ftvp
 }
di as txt "LLF =" as res %10.3f llf _col(20) as txt "AIC =" as res %9.3f aic _col(38) as txt "SC =" as res %10.3f sc

if inlist("`e(title)'", "mSTAR Spatial Panel Lag Normel Model (1)") {
ml display, level(`level') neq(1) noheader diparm(Rho1, label("Rho1")) ///
   diparm(Sigma, label("Sigma"))
local PARM1 "Rho1"
di as txt "Wald Test [`PARM1'=0]:" _col(35) %9.4f as res waldr as txt _col(52) "P-Value > Chi2(1)" as res _col(70) %5.4f waldrp
di as txt "Acceptable Range for Rho1: " as res %6.4f minEig1 " < Rho1 < " %6.4f maxEig1 
 }

if inlist("`e(title)'" ,"mSTAR Spatial Panel Lag Normel Model (2)") {
ml display, level(`level') neq(1) noheader diparm(Rho1, label("Rho1")) ///
 diparm(Rho2, label("Rho2")) diparm(Sigma, label("Sigma"))
local PARM2 "Rho1+Rho2"
di as txt "Wald Test [`PARM2'=0]:" _col(35) %9.4f as res waldr as txt _col(52) "P-Value > Chi2(2)" as res _col(70) %5.4f waldrp
di as txt "Acceptable Range for Rho1: " as res %6.4f minEig1 " < Rho1 < " %6.4f maxEig1 
di as txt "Acceptable Range for Rho2: " as res %6.4f minEig2 " < Rho2 < " %6.4f maxEig2 
 }

if inlist("`e(title)'" ,"mSTAR Spatial Panel Lag Normel Model (3)") {
ml display, level(`level') neq(1) noheader diparm(Rho1, label("Rho1")) ///
 diparm(Rho2, label("Rho2")) diparm(Rho3, label("Rho3")) diparm(Sigma, label("Sigma"))
local PARM3 "Rho1+Rho2+Rho3"
di as txt "Wald Test [`PARM3'=0]:" _col(35) %9.4f as res waldr as txt _col(52) "P-Value > Chi2(3)" as res _col(70) %5.4f waldrp
di as txt "Acceptable Range for Rho1: " as res %6.4f minEig1 " < Rho1 < " %6.4f maxEig1 
di as txt "Acceptable Range for Rho2: " as res %6.4f minEig2 " < Rho2 < " %6.4f maxEig2 
di as txt "Acceptable Range for Rho3: " as res %6.4f minEig3 " < Rho3 < " %6.4f maxEig3
 }

if inlist("`e(title)'" ,"mSTAR Spatial Panel Lag Normel Model (4)") {
ml display, level(`level') neq(1) noheader diparm(Rho1, label("Rho1")) ///
 diparm(Rho2, label("Rho2")) diparm(Rho3, label("Rho3")) ///
 diparm(Rho4, label("Rho4")) diparm(Sigma, label("Sigma"))
local PARM4 "Rho1+Rho2+Rho3+Rho4"
di as txt "Wald Test [`PARM4'=0]:" _col(35) %9.4f as res waldr as txt _col(52) "P-Value > Chi2(4)" as res _col(70) %5.4f waldrp
di as txt "Acceptable Range for Rho1: " as res %6.4f minEig1 " < Rho1 < " %6.4f maxEig1 
di as txt "Acceptable Range for Rho2: " as res %6.4f minEig2 " < Rho2 < " %6.4f maxEig2 
di as txt "Acceptable Range for Rho3: " as res %6.4f minEig3 " < Rho3 < " %6.4f maxEig3
di as txt "Acceptable Range for Rho4: " as res %6.4f minEig4 " < Rho4 < " %6.4f maxEig4
 }
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

