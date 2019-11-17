*! xtregbem V1.0 15/05/2012
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage:               http://emadstat.110mb.com/stata.htm
*! WebPage at IDEAS:      http://ideas.repec.org/f/psh494.html
*! WebPage at EconPapers: http://econpapers.repec.org/RAS/psh494.htm

program define xtregbem, eclass 
version 11.0
syntax varlist [if] [in] , id(str) it(str) [Weights(str) WVar(str) ///
 LMHet RIDge(str) KR(real 0) coll diag tolog level(passthru) MFX(str) ///
 NOCONStant PREDict(str) resid(str) DN vce(passthru) iter(int 100)]
tempvar `varlist'
gettoken yvar xvar : varlist
_fv_check_depvar `yvar'
qui marksample touse
qui markout `touse' `varlist' , strok
markout `touse' `varlist' `wvar' , strok
local both : list yvar & xvar
if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS and RHS Variables}"
di as res " LHS: `yvar'"
di as res " RHS: `xvar'"
 exit
 }
if "`xvar'"=="" {
di as err "  {bf:Independent Variable(s) must be combined with Dependent Variable}"
 exit
 }
if "`weights'"!="" {
if !inlist("`weights'", "yh", "abse", "e2", "le2", "yh2", "x", "xi", "x2", "xi2") {
di
di as err " {bf:weights( )} {cmd:works only with:} {bf:yh, yh2, abse, e2, le2, x, xi, x2, xi2}"
 di in smcl _c "{cmd: see:} {help `sthlp'##06:Weighted Variable Type Options}"
 di in gr _c " (xtregbem Help):"
 exit
 }
 }
if inlist("`weights'", "x", "xi", "x2", "xi2") & "`wvar'"=="" {
di
di as err " {bf:wvar( )} {cmd:must be combined with:} {bf:weights(x, xi, x2, xi2)}"
exit
 }
 if "`mfx'"!="" {
if !inlist("`mfx'", "lin", "log") {
di 
di as err " {bf:mfx( )} {cmd:must be} {bf:mfx({it:lin})} {cmd:for Linear Model, or} {bf:mfx({it:log})} {cmd:for Log-Log Model}"
 exit
 }
 }
 if inlist("`mfx'", "log") {
 if "`tolog'"=="" {
di 
di as err " {bf:tolog} {cmd:must be combined with} {bf:mfx(log)}"
 exit
 }
 } 
if "`ridge'"!="" {
if !inlist("`ridge'", "orr", "grr1", "grr2", "grr3") {
di 
di as err " {bf:ridge( )} {cmd:must be} {bf:ridge({it:orr, grr1, grr2, grr3})}"
di in smcl _c "{cmd: see:} {help `sthlp'##04:Ridge Options}"
di in gr _c " (xtregbem Help):"
 exit
 }	
 }
if inlist("`ridge'", "grr1", "grr2", "grr3") & `kr'>0 {
di 
di as err " {bf:kr(#)} {cmd:must be not combined with:} {bf:ridge({it:grr1, grr2, grr3})}"
exit
 }
tempvar _X _Y absE Bw D DE DF1 DW DX_ DY_ E e dcs TimeN
tempvar EE Eo Es Ev Ew Hat ht idv itv LE LEo LYh2 P Q SBB Sig2 SSE
tempvar SST Time tm U U2 Ue wald weit Wi Wio WS X X0 eigw Bo
tempvar Xb XB Xo XQ Yb Yh Yh2 Yhb Yho Yho2 Yt YY YYm YYv Yh_ML Ue_ML Z
tempvar absE Bw D DE DF DF1 DW E e E2 E3 E4 Ea Ea1 EE Eo Es Es1 
tempvar Ev Ew Hat ht LDE LE LEo LnE2 LYh2 P Q SBB Sig2 SRho SSE
tempvar Time tm U U2 Ue uiv wald weit Wi Wio X X0
tempvar Xb XB Yb Yh Yh2 Yhat1 Yhb Yho Yho2 Yt YY Z Yhr VN
tempname A AIC B b B1 b1 B12 B1b B1t b2 BB2 Beta Bm BOLS BOLS1 Bt Bv Bv1 Bx Cov 
tempname Cov1 Cov2s CovC D den DF dfab Dim DVE DVNE Dx E E1 EE1 Eg Eo Eom eVec 
tempname Ew F f1 f13 f13d FPE gam gam2 GCV Go GoRY HQ IDRmk In IPhi J K kb kbd 
tempname kbm Ko Koi Kr kx kxd L LAIC lf llf lmhs lmiab lmiabp Ls LSC M M1 
tempname M2 mfxe mfxlin mfxlog mh N n NC NC1 NC2 NE NEB Nmiss Nn NT NT1 NT2 nw 
tempname olsin Om Om1 Om2 Omega Omm Omm1 Omm2 P Phi Pm q Q q1 q2 Qr Qrq  
tempname Rice rid Rmk RX RY s SC sd Shibata Sig2 Sig21 Sig2b Sig2n Sig2o
tempname Sig2o1 Sig2u Sig2w sigox SLS Sn sqN SSE SSEo SST1 SST2 Sw Ue Ue_ML 
tempname v2 VaL VaL1 VaL21 VaLv1 Vec vh VM VN VP VQ Vs W W1 W2 Wald waldm We Wi 
tempname v V v1 V1 V1s Wi1 Wio WMTD WS WW WY X X0 XB Xfe Xg XMB Xo xq Xre
tempname Xx XYMB Y Yfe Yh Yh_ML YMB YMB1 Yre YYm YYv Z Z0 Z1 Zo Zr Zz

gettoken yvar xvar : varlist
qui xtset `id' `it'
local idv "`r(panelvar)'"
local itv "`r(timevar)'"
scalar `NC'=r(imax)
scalar `NT'= r(tmax)
scalar `NC1'=r(imin)
scalar `NC2'=r(imax)
scalar `NT1'=r(tmin)
scalar `NT2'=r(tmax)
mkmat `idv' if `touse' , matrix(idv)
mkmat `itv' if `touse' , matrix(itv)
mata: idv= st_matrix("idv")
mata: itv= st_matrix("itv")
qui cap count if `touse'
scalar N = r(N)
local  N = N
qui gen `TimeN'=_n
qui gen `Time'=_n if `touse'
qui tsset `TimeN'

 if "`tolog'"!="" {
di _dup(45) "-"
di as err " {cmd:** Data Have been Transformed to Log Form **}"
di as txt " {cmd:** `varlist'} "
di _dup(45) "-"
qui foreach var of local varlist {
tempvar xyind`var'
qui gen `xyind`var''=`var' 
qui replace `var'=ln(`var') 
qui replace `var'=1 if `var'==0
qui replace `var'=0 if `var'==.
 }
 }
 if "`coll'"=="" {
_rmcoll `xvar' if `touse' , `noconstant' `coll' forcedrop
local xvar "`r(varlist)'"
 }
qui gen `X0'=1 if `touse' 
qui mkmat `X0' if `touse' , matrix(`X0')
mkmat `yvar' if `touse' , matrix(`Y')
qui tabulate `idv' if `touse' , generate(`dcs')
mkmat `dcs'* if `touse' , matrix(`D')
matrix `P'=`D'*invsym(`D''*`D')*`D''
matrix `Q'=I(`N')-`P'
matrix `Xo'=J(`NT',1,1)
matrix `D'=I(`NC')#`Xo'

local kx : word count `xvar'
if "`noconstant'"!="" {
qui mkmat `xvar' if `touse' , matrix(`X')
scalar `kb'=`kx'
scalar `DF'=`N'-`kx'-`NC'
qui mean `xvar' if `touse' 
 }
 else { 
qui mkmat `xvar' `X0' if `touse' , matrix(`X')
scalar `kb'=`kx'+1
scalar `DF'=`N'-`kx'-`NC'
qui mean `xvar' `X0' if `touse' 
 }

matrix `XMB'=e(b)
qui mean `yvar' if `touse' 
matrix `Yb'=e(b)'
if "`dn'"!="" {
scalar `DF'=`N'
 }
qui cap drop `Time'
qui gen `Time'=_n if `touse' 
qui tsset `Time'
matrix `Wi'=J(N,1,1)
qui gen `Wi'=1 if `touse' 
qui gen `weit' = 1 if `touse' 
if "`wvar'"!="" { 
qui replace `Wi' = (`wvar')^0.5 if `touse' 
 }
if "`weights'"!="" {
qui cap drop `Wi'
qui regress `yvar' `xvar' if `touse' , `noconstant'
qui predict `Yho' if `touse' 
qui predict `Eo'  if `touse' , resid
qui regress `Yho' `xvar' if `touse' , `noconstant'
qui predict `Wi' if `touse' 
if inlist("`weights'", "yh") {
qui replace `Wi' = 1/(abs(`Wi'))^0.5 if `touse' 
local wtitle "Weighted Regression Type: (Yh)    -   Variable: Yh Predicted Value"
 }
if inlist("`weights'", "abse") {
local wtitle "Weighted Regression Type: (absE)  -   Variable: abs(E) Residual Absolute Value"
qui replace `Wi' = 1/(abs(`Eo'))^0.5 if `touse' 
 }
if inlist("`weights'", "e2") {
local wtitle "Weighted Regression Type: (E2)    -   Variable: E^2 Residual Squared"
qui replace `Wi' = 1/(`Eo'^2)^0.5 if `touse'
 }
if inlist("`weights'", "le2") {
local wtitle "Weighted Regression Type: (lE2)   -   Variable: log(E^2) Log Residual Squared"
qui replace `Wi' = 1/(log((`Eo')^2))^0.5 if `touse' 
 }
if inlist("`weights'", "yh2") {
qui cap drop `Wi'
local wtitle "Weighted Regression Type: (Yh2)   -   Variable: Yh^2 Predicted Value Squared"
qui gen `Yho2' = `Yho'^2 if `touse' 
qui regress `Yho2' `xvar' if `touse' , `noconstant'
qui predict `Wi' if `touse' , xb 
qui replace `Wi' = 1/(abs(`Wi'))^0.5 if `touse' 
 } 
if inlist("`weights'", "x") {
local wtitle "Weighted Regression Type: (X)     -   Variable: (`wvar')"
qui replace `Wi' = (`wvar')^0.5 if `touse' 
 } 
if inlist("`weights'", "xi") {
local wtitle "Weighted Regression Type: (Xi)    -   Variable: (1/`wvar')"
qui replace `Wi' = 1/(`wvar')^0.5 if `touse' 
 } 
if inlist("`weights'", "x2") {
local wtitle "Weighted Regression Type: (X2)    -   Variable: (`wvar')^2"
qui replace `Wi' = (`wvar')^2 if `touse' 
 } 
if inlist("`weights'", "xi2") {
local wtitle "Weighted Regression Type: (Xi2)   -   Variable: (1/`wvar')^2"
qui replace `Wi' = 1/(`wvar')^2 if `touse' 
 }
qui replace `weit' =`Wi'^2 if `touse' 
 }
qui summ `weit' if `touse' 
mkmat `Wi' if `touse' , matrix(`Wi')
matrix `Wi'=diag(`Wi')
matrix `Omega'=`Wi''*`Wi'
matrix `Xx'=`X''*`Omega'*`X'
matrix `Zz'=I(`kb')*0
scalar `Kr'=0
if "`ridge'"!="" {
scalar `Kr'=`kr'
qui summ `yvar' if `touse'
qui gen `_Y'`yvar' = `yvar' - `r(mean)' if `touse'
qui foreach var of local xvar {
qui summ `var' if `touse'
qui gen `_X'`var' = `var' - `r(mean)' if `touse'
 }
qui gen `Zo'=0 if `touse'
if "`noconstant'"!="" {
qui mkmat `_X'* if `touse' , matrix(`Zr')
 }
 else {
qui mkmat `_X'* `Zo' if `touse' , matrix(`Zr')
 }
if inlist("`ridge'", "orr") {
local rtitle "{bf:Ordinary Ridge Regression}"
 }
if inlist("`ridge'", "grr1") {
local rtitle "{bf:Generalized Ridge Regression}"
if "`noconstant'"!="" {
qui tabstat `xvar' `wgt' if `touse' , statistics( sd ) save
 }
else {
qui tabstat `xvar' `X0' `wgt' if `touse' , statistics( sd ) save
 }
 matrix `sd'=r(StatTotal)
 scalar `sqN'=sqrt(`N'-1)
 matrix `WMTD'=diag(`sd')*`sqN'
 matrix `Beta'=invsym(`X''*`Omega'*`X')*`X''*`Omega'*`Y'
 matrix `BOLS'=`WMTD''*`Beta'
 matrix `BOLS'=`BOLS''*`BOLS'
 scalar `BOLS1'=`BOLS'[1,1]
 matrix `Sig2o'=`Y'-`X'*`Beta'
 matrix `Sig2o'=(`Sig2o''*`Sig2o')/`DF'
 scalar `Sig2o1'=`Sig2o'[1,1]
 scalar `Kr'=`kx'*`Sig2o1'/`BOLS1'
 }
if inlist("`ridge'", "grr2") {
local rtitle "{bf:Iterative Generalized Ridge Regression}"
if "`noconstant'"!="" {
qui tabstat `xvar' `wgt' if `touse' , statistics( sd ) save
 }
else {
qui tabstat `xvar' `X0' `wgt' if `touse' , statistics( sd ) save
 }
 matrix `sd'=r(StatTotal)
 scalar `sqN'=sqrt(`N'-1)
 matrix `WMTD'=diag(`sd')*`sqN'
 matrix `Beta'=invsym(`X''*`Omega'*`X')*`X''*`Omega'*`Y'
 matrix `BOLS'=`WMTD''*`Beta'
 matrix `BOLS'=`BOLS''*`BOLS'
 scalar `BOLS1'=`BOLS'[1,1]
 matrix `Sig2o'=`Y'-`X'*`Beta'
 matrix `Sig2o'=(`Sig2o''*`Sig2o')/`DF'
 scalar `Sig2o1'=`Sig2o'[1,1]
 scalar `Kr'=`kx'*`Sig2o1'/`BOLS1'
qui forvalue i=1/`iter' { 
scalar `Ko'=`Kr'
 matrix `rid'=I(`kb')*`Kr'
 matrix `Zz'=diag(vecdiag(`Zr''*`Zr'*`rid'))
 matrix `Beta'=invsym(`X''*`Omega'*`X'+`Zz')*`X''*`Omega'*`Y'
 matrix `BOLS'=`WMTD''*`Beta'
 matrix `BOLS'=`BOLS''*`BOLS'
 scalar `BOLS1'=`BOLS'[1,1]
 tempname K`i'
 scalar `K`i''=`kx'*`Sig2o1'/`BOLS1'
 scalar `Kr'=`K`i''
 scalar `Koi'=abs(`Kr'-`Ko')
 if (`Koi' <= 0.00001) {
 continue, break
 }
 }
 }
if inlist("`ridge'", "grr3") {
local rtitle "{bf:Adaptive Generalized Ridge Regression}"
qui corr `_X'* `_Y'`yvar' if `touse' 
 matrix `CovC'=r(C)
 matrix `RY' = `CovC'[`kb' ,1..`kx']
 matrix `RX' = `CovC'[1..`kx', 1..`kx']
 matrix symeigen `Vec' `VaL'=`RX'
 matrix `VaL1' =`VaL''
qui svmat `VaL1' , name(`VaL1')
qui rename `VaL1'1 `VaL1'
qui replace `VaL1'=1/`VaL1' 
 mkmat `VaL1' , matrix(`VaLv1')
 matrix `VaL21' =diag(`VaLv1')
 matrix `VaL21' = `VaL21'[1..`kx', 1..`kx']
 matrix `Go'=`Vec'*`VaL21'*`Vec''
 matrix `GoRY'=`Go'*`RY''
 matrix `SSE'=1-`RY'*`GoRY'
 matrix `Sig2'=`SSE'/`DF'
 matrix `Qr'=`GoRY''*`GoRY'-`Sig2'*trace(`Go')
 matrix `L'=`Vec''*`RY''
qui svmat `L' , name(`L')
qui rename `L'1 `L'
 scalar `Kr'=0
qui forvalue i=1/`iter' { 
 tempname Ko`i'
 scalar `Ko'=`Kr'
 scalar `Ko`i''=`Kr'
 matrix `rid'=I(`kx')
 matrix `rid'=vecdiag(`rid')*`Kr'
 matrix `f1'=`VaL1'+`rid''
qui cap drop `f1'
qui cap drop `f13' `f1'1
qui cap drop `f1'1
qui svmat `f1' , name(`f1')
qui rename `f1'1 `f1'
qui gen `f13'`i'=`f1'^3 if `touse' 
 mkmat `f13'`i' , matrix(`f13')
 matrix `f13d'=diag(`f13')
 matrix `f13' =`f13d'[1..`kx', 1..`kx']
 matrix `Rmk' =vecdiag(`f13')'
 matrix `IDRmk'=invsym(`f13')
 matrix `Ls'=`L''*`IDRmk'
 matrix `Ls'=(`Ls'*diag(`L'))'
qui cap drop `Ls' `lf'
qui svmat `Ls' , name(`Ls'`i')
qui rename `Ls'`i'1 `Ls'`i'
qui summ `Ls'`i' if `touse' 
 scalar `SLS'=r(sum)
qui gen `lf'`i'=`L'/`f1' if `touse' 
 mkmat `lf'`i' if `touse' , matrix(`lf'`i')
 matrix `lf'`i' =diag(`lf'`i')
 matrix `lf'`i' = `lf'`i'[1..`kx', 1..`kx']
 matrix `lf'`i' = vecdiag(`lf'`i')'
 matrix `F'=`lf'`i''*`lf'`i'-`Qr'
 matrix `K'`i'=`Ko`i''+(0.5*`F'/`SLS')
scalar `Kr'=`K'`i'[1,1]
scalar `Koi'=abs(`Kr'-`Ko')
 if (`Koi' <= 0.00001) {
 continue, break
 }
 }
 }
matrix `rid'=I(`kb')*`Kr'
matrix `Zz'=diag(vecdiag((`Zr''*`Zr')*`rid'))
 }
di 
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Between-Effects Panel Data: Ridge and Weighted Regression}}"
di _dup(78) "{bf:{err:=}}"
matrix `Omega'=`Wi''*`P'*`Wi'
matrix `Beta'=invsym(`X''*`Omega'*`X'+`Zz')*`X''*`Omega'*`Y'
matrix `E'=`P'*(`Y'-`X'*`Beta')
if `NC' <= `kb' {
matrix `Sig2'=1
 }
if `NC' > `kb' {
matrix `Sig2'=`E''*`E'/(`NC'-`kb')
 }
matrix `E'=`Wi'*(`Y'-`X'*`Beta')
if "`ridge'"!="" & `kr' > 0 {
matrix `Cov'=`Sig2'*invsym(`Xx'+`Zz')*`Xx'*invsym(`Xx'+`Zz')
 }
 else {
matrix `Cov'=`Sig2'*invsym(`X''*`Omega'*`X')
 }

matrix `Bx' =`Beta'[1..`kx', 1..1]
matrix `Yh_ML'=`X'*`Beta'
matrix `Yh_ML'=`P'*`Yh_ML'
matrix `Ue_ML'=(`Y'-`Yh_ML')
qui svmat `Yh_ML' , name(`Yh_ML')
qui rename `Yh_ML'1 `Yh_ML'
qui svmat `Ue_ML' , name(`Ue_ML')
qui rename `Ue_ML'1 `Ue_ML'
if "`predict'"!="" | "`resid'"!="" {
mata: Yhxt= st_matrix("`Yh_ML'")
mata: Uext= st_matrix("`Ue_ML'")
 }
tempname SSEo Sigo r2bu r2bu_a r2raw r2raw_a f fp wald waldp
tempname r2v r2v_a fv fvp r2h r2h_a fh fhp SSTm SSE1 SST11 SST21 Rho
matrix `SSE'=`Ue_ML''*`Ue_ML'
scalar `SSEo'=`SSE'[1,1]
matrix `Sig2o'=(`Ue_ML''*`Ue_ML')/`DF'
scalar `Sigo'=sqrt(`Sig2o'[1,1])
qui summ `Yh_ML' if `touse' 
local NUM=r(Var)
qui summ `yvar' if `touse' 
local DEN=r(Var)
scalar `r2v'=`NUM'/`DEN'
scalar `r2v_a'=1-((1-`r2v')*(`N'-1)/`DF')
scalar `fv'=`r2v'/(1-`r2v')*(`N'-`kb')/(`kx')
scalar `fvp'=Ftail(`kx', `DF', `fv')
qui correlate `Yh_ML' `yvar' if `touse' 
scalar `r2h'=r(rho)*r(rho)
scalar `r2h_a'=1-((1-`r2h')*(`N'-1)/`DF')
scalar `fh'=`r2h'/(1-`r2h')*(`N'-`kb')/(`kx')
scalar `fhp'=Ftail(`kx', `DF', `fh')
matrix `SSE'=`Ue_ML''*`Ue_ML'
local Sig=`Sigo'
qui summ `yvar' if `touse' 
local Yb=r(mean)
qui gen `YYm'=(`yvar'-`Yb')^2 if `touse'
qui summ `YYm' if `touse'
qui scalar `SSTm' = r(sum)
qui gen `YYv'=(`yvar')^2 if `touse'
qui summ `YYv' if `touse'
local SSTv = r(sum)
qui summ `weit' if `touse' 
qui gen `Wi1'=sqrt(`weit'/r(mean)) if `touse'
mkmat `Wi1' if `touse' , matrix(`Wi1')
matrix `P' =diag(`Wi1')
qui gen `Wio'=`Wi1' if `touse' 
mkmat `Wio' if `touse' , matrix(`Wio')
matrix `Wio'=diag(`Wio')
matrix `Pm' =`Wio'
matrix `IPhi'=`P''*`P'
matrix `Phi'=invsym(`P''*`P')
matrix `J'= J(`N',1,1)
matrix `D'=(`J'*`J''*`IPhi')/`N'
matrix `SSE'=`Ue_ML''*`IPhi'*`Ue_ML'
matrix `SST1'=(`Y'-`D'*`Y')'*`IPhi'*(`Y'-`D'*`Y')
matrix `SST2'=(`Y''*`Y')
scalar `SSE1'=`SSE'[1,1]
scalar `SST11'=`SST1'[1,1]
scalar `SST21'=`SST2'[1,1]
scalar `r2bu'=1-`SSE1'/`SST11'
scalar `r2bu_a'=1-((1-`r2bu')*(`N'-1)/`DF')
scalar `r2raw'=1-`SSE1'/`SST21'
scalar `r2raw_a'=1-((1-`r2raw')*(`N'-1)/`DF')
scalar `f'=`r2bu'/(1-`r2bu')*(`N'-`kb')/`kx'
scalar `fp'= Ftail(`kx', `DF', `f')
scalar `wald'=`f'*`kx'
scalar `waldp'=chi2tail(`kx', abs(`wald'))
scalar `llf'=-(`N'/2)*log(2*_pi*`SSEo'/`N')-(`N'/2)
local Nof =`N'
local Dof =`DF'
matrix `B'=`Beta''
if "`noconstant'"!="" {
matrix colnames `Cov' = `xvar'
matrix rownames `Cov' = `xvar'
matrix colnames `B'   = `xvar'
 }
 else { 
matrix colnames `Cov' = `xvar' _cons
matrix rownames `Cov' = `xvar' _cons
matrix colnames `B'   = `xvar' _cons
 }
yxregeq `yvar' `xvar'
if "`weights'"!="" { 
di as txt _col(1) "{bf:* " "`wtitle'" " *}"
di _dup(78) "-"
 }
if "`ridge'"!="" {
di as txt _col(3) "{bf:Ridge k Value}" _col(21) "=" as res %10.5f `Kr' _col(37) "|" _col(41) "`rtitle'"
di _dup(78) "-"
 }
di as txt _col(3) "Sample Size" _col(21) "=" %12.0f as res `N' _col(37) "|" _col(41) as txt "Cross Sections Number" _col(65) "=" _col(73) %5.0f as res `NC'
ereturn post `B' `Cov' , dep(`yvar') obs(`Nof') dof(`Dof')
qui test `xvar'
scalar `f'=r(F)
scalar `fp'= Ftail(`kx', `DF', `f')
scalar `wald'=`f'*`kx'
scalar `waldp'=chi2tail(`kx', abs(`wald'))
di as txt _col(3) "Wald Test" _col(21) "=" %12.4f as res `wald' _col(37) "|" _col(41) as txt "P-Value > Chi2(" as res `kx' ")" _col(65) "=" %12.4f as res `waldp'
di as txt _col(3) "F-Test" _col(21) "=" %12.4f as res `f' _col(37) "|" _col(41) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(65) "=" %12.4f as res `fp'
di as txt _col(2) "(Buse 1973) R2" _col(21) "=" %12.4f as res `r2bu' _col(37) "|" as txt _col(41) "Raw Moments R2" _col(65) "=" %12.4f as res `r2raw'
ereturn scalar r2bu =`r2bu'
ereturn scalar r2bu_a=`r2bu_a'
ereturn scalar f =`f'
ereturn scalar fp=`fp'
ereturn scalar wald =`wald'
ereturn scalar waldp=`waldp'
di as txt _col(2) "(Buse 1973) R2 Adj" _col(21) "=" %12.4f as res `r2bu_a' _col(37) "|" as txt _col(41) "Raw Moments R2 Adj" _col(65) "=" %12.4f as res `r2raw_a'
di as txt _col(3) "Root MSE (Sigma)" _col(21) "=" %12.4f as res `Sigo' as txt _col(37) "|" _col(41) "Log Likelihood Function" _col(65) "=" %12.4f as res `llf'
di _dup(78) "-"
di as txt "- {cmd:R2h}=" %7.4f as res `r2h' _col(17) as txt "{cmd:R2h Adj}=" as res %7.4f `r2h_a' as txt _col(34) "{cmd:F-Test} =" %8.2f as res `fh' _col(51) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(72) %5.4f as res `fhp'
di as txt "- {cmd:R2v}=" %7.4f as res `r2v' _col(17) as txt "{cmd:R2v Adj}=" as res %7.4f `r2v_a' as txt _col(34) "{cmd:F-Test} =" %8.2f as res `fv' _col(51) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(72) %5.4f as res `fvp'
ereturn scalar r2raw =`r2raw'
ereturn scalar r2raw_a=`r2raw_a'
ereturn scalar llf =`llf'
ereturn scalar sig=`Sigo'
ereturn scalar r2h =`r2h'
ereturn scalar r2h_a=`r2h_a'
ereturn scalar r2v =`r2v'
ereturn scalar r2v_a=`r2v_a'
ereturn scalar fh =`fh'
ereturn scalar fv=`fv'
ereturn scalar fhp=`fhp'
ereturn scalar fvp=`fvp'
ereturn scalar Kr=`Kr'
ereturn scalar kb=`kb'
ereturn scalar kx=`kx'
ereturn scalar DF=`DF'
ereturn scalar Nn=_N
ereturn scalar NC=`NC'
ereturn scalar NT=`NT'
local llf=e(llf)
local kb=e(kb)
local kx=e(kx)
local DF=e(DF)
local N=e(Nn)
local NC=e(NC)
local NT=e(NT)
ereturn display
matrix `b'=e(b)
matrix `V'=e(V)

qui tsset `Time'
 local N=`N'
qui mkmat `X0' if `touse' , matrix(`X0')
matrix `SSE'=`Ue_ML''*`Ue_ML'
scalar `SSEo'=`SSE'[1,1]
scalar `Sig2o'=`SSEo'/`DF'
scalar `Sig2n'=`SSEo'/`N'

if "`diag'"!= "" {
di
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Panel Model Selection Diagnostic Criteria}}"
di _dup(78) "{bf:{err:=}}"
ereturn scalar llf=-(`N'/2)*ln(2*_pi*`SSEo'/`N')-(`N'/2)
scalar `kbm'=`kb'
ereturn scalar aic=(2*`kbm')-(2*e(llf))
ereturn scalar laic=ln(`SSEo'/`N')+2*`kbm'/`N'
ereturn scalar fpe=(`SSEo'/`DF')*(1+`kbm'/`N')
ereturn scalar sc=(`kbm'*ln(`N'))-(2*e(llf))
ereturn scalar lsc=ln(`SSEo'/`N')+`kbm'*ln(`N')/`N'
ereturn scalar hq=`SSEo'/`N'*ln(`N')^(2*`kbm'/`N')
ereturn scalar rice=`SSEo'/`N'/(1-2*`kbm'/`N')
ereturn scalar shibata=`SSEo'/`N'*(`N'+2*`kbm')/`N'
ereturn scalar gcv=`SSEo'/`N'*(1-`kbm'/`N')^(-2)
di
di as txt "- Log Likelihood Function       LLF" _col(50) " = " as res %10.4f e(llf)
di as txt "- Akaike Final Prediction Error AIC" _col(50) " = " as res %10.4f e(aic)
di as txt "- Schwartz Criterion            SC" _col(50)  " = " as res %10.4f e(sc)
di as txt "- Akaike Information Criterion  ln AIC" _col(50) " = " as res %10.4f e(laic)
di as txt "- Schwarz Criterion             ln SC" _col(50) " = " as res %10.4f e(lsc)
di as txt "- Amemiya Prediction Criterion  FPE" _col(50) " = " as res %10.4f e(fpe)
di as txt "- Hannan-Quinn Criterion        HQ" _col(50) " = " as res %10.4f e(hq)
di as txt "- Rice Criterion                Rice" _col(50) " = " as res %10.4f e(rice)
di as txt "- Shibata Criterion             Shibata" _col(50) " = " as res %10.4f e(shibata)
di as txt "- Craven-Wahba Generalized Cross Validation-GCV" _col(50) as res " = " as res %10.4f e(gcv)
di _dup(78) "-"
 }

if "`lmhet'"!= "" {
tempvar Yh Yh2 LYh2 E E2 E3 E4 LnE2 absE time LE ht U2
tempvar Sig2 SigLR SigLRs SigLM SigLMs SigW SigWs E E2 EE1 En cN cT Obs Egh
qui tsset `Time'
local idv `idv'
qui regress `yvar' `xvar' if `touse' , `noconstant'
qui predict `E' if `touse' , res
qui gen double `E2' = `E'^2 if `touse'
qui summ `E2' if `touse' , meanonly
local Sig2 = r(mean)
qui gen double `SigLR' = . if `touse'
qui gen double `SigLM' = . if `touse'
qui gen double `SigW'  = . if `touse'
local SigLRs = 0
local SigLMs = 0
local SigWs  = 0
qui levelsof `idv' if `touse' , local(levels)
qui foreach l of local levels {
 summ `E2' if `idv' == `l', meanonly
 replace `SigLM'= (r(mean)/`Sig2'-1)^2 if `idv' == `l'
 replace `SigLR'= ln(r(mean))*r(N) if `idv' == `l'
 replace `SigW' = (`Sig2'/r(mean)-1)^2 if `idv' == `l'
 summ `SigLM' if `idv' == `l', meanonly
local SigLMs =`SigLMs'+ r(mean)
 summ `SigLR' if `idv' == `l', meanonly
local SigLRs = `SigLRs' + r(mean)
 summ `SigW' if `idv' == `l', meanonly
local SigWs =`SigWs'+ r(mean)
 }
local dflm= `NC'-1
local dflr= `NC'-1
local dfw = `NC'
tempname lmhglr lmhglrp lmhglm lmhglmp lmhgw lmhgwp
scalar `lmhglr'=`N'*ln(`Sig2')- `SigLRs'
scalar `lmhglrp'= chi2tail(`dflr', abs(`lmhglr'))
scalar `lmhglm'=`NT'/2*(`SigLMs')
scalar `lmhglmp'= chi2tail(`dflm', abs(`lmhglm'))
scalar `lmhgw'=`NT'/2*(`SigWs')
scalar `lmhgwp'= chi2tail(`dfw', abs(`lmhgw'))
di
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Panel Groupwise Heteroscedasticity Tests}}"
di _dup(78) "{bf:{err:=}}"
di as txt _col(2) "{bf: Ho: Panel Homoscedasticity - Ha: Panel Groupwise Heteroscedasticity}"
di
di as txt "- Lagrange Multiplier LM Test" _col(35) "=" as res %9.4f `lmhglm' as txt _col(50) "P-Value > Chi2(" `dflm' ")" _col(70) %5.4f as res `lmhglmp'
di as txt "- Likelihood Ratio LR Test" _col(35) "=" as res %9.4f `lmhglr' _col(50) as txt "P-Value > Chi2(" `dflr' ")" _col(70) %5.4f as res `lmhglrp'
di as txt "- Wald Test" as res _col(35) "=" as res %9.4f `lmhgw' _col(50) as txt "P-Value > Chi2(" `dfw' ")" _col(70) %5.4f as res `lmhgwp'
di _dup(78) "-"
ereturn scalar lmhglr=`lmhglr'
ereturn scalar lmhglrp=`lmhglrp'
ereturn scalar lmhglm=`lmhglm'
ereturn scalar lmhglmp=`lmhglmp'
ereturn scalar lmhgw=`lmhgw'
ereturn scalar lmhgwp=`lmhgwp'
 }

if "`predict'"!= "" {
qui cap drop `predict'
mata: `predict'=Yhxt
getmata `predict' , force replace
label variable `predict' `"Yh - Prediction"'
 }
if "`resid'"!= "" {
qui cap drop `resid'
mata: `resid'=Uext
getmata `resid' , force replace
label variable `resid' `"U - Residual"'
 }

if "`tolog'"!="" {
qui foreach var of local varlist {
qui replace `var'= `xyind`var'' 
 }
 }

if inlist("`mfx'", "lin", "log") {
qui mean `xvar' if `touse' 
matrix `XMB'=e(b)'
qui summ `yvar' if `touse' 
scalar `YMB1'=r(mean)
matrix `YMB'=J(rowsof(`XMB'),1,`YMB1')
mata: X = st_matrix("`XMB'")
mata: Y = st_matrix("`YMB'")
if inlist("`mfx'", "lin") {
mata: `XYMB'=divide(X, Y)
mata: `XYMB'=st_matrix("`XYMB'",`XYMB')
matrix mfx =`Bx'
matrix mfxe=vecdiag(`Bx'*`XYMB'')'
matrix mfxlin =mfx,mfxe,`XMB'
matrix rownames mfxlin = `xvar'
matrix colnames mfxlin = Marginal_Effect(B) Elasticity(Es) Mean
matlist mfxlin , title({bf:* {bf:{err:Linear:}} Marginal Effect - Elasticity *}) twidth(12) border(all) lines(columns) rowtitle(Variable) format(%18.4f)
 }
if inlist("`mfx'", "log") {
mata: `XYMB'=divide(Y, X)
mata: `XYMB'=st_matrix("`XYMB'",`XYMB')
matrix mfxe=`Bx'
matrix mfx=vecdiag(`Bx'*`XYMB'')'
matrix mfxlog =mfxe,mfx,`XMB'
matrix rownames mfxlog = `xvar'
matrix colnames mfxlog = Elasticity(Es) Marginal_Effect(B) Mean
matlist mfxlog , title({bf:* {bf:{err:Log-Log:}} Elasticity - Marginal Effect *}) twidth(12) border(all) lines(columns) rowtitle(Variable) format(%18.4f)
 }
di as txt " Mean of Dependent Variable =" as res _col(30) %12.4f `YMB1' 
 }
qui cap drop `Time'
qui gen `Time'=_n
qui tsset `Time'
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

