*! diagreg2 V1.0 25nov2011
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage: http://emadstat.110mb.com/stata.htm

program define diagreg2 , eclass byable(onecall)
version 10.1
syntax [anything] [if] [in] , Model(string) ///
 [ NOCONStant NOCONEXOG Level(cilevel) dn kc(real 0) kf(real 0) HETcov(str) *]
tempvar E E2 U U2 X0 Yh Yhb Ev Ue Lambdav Lambda Time YY Yb YYv YYm Wio Wi Yho Hat DF
tempvar wald SSE SST weit EE Ea Ea1 Es Es1 DW WS DX_ DY_ LE DE LEo SBB SRho DE Yho2
tempvar Yt e pcs1 pcs2 pcs3 pcs4 estd LDE DF1 Eo Zhout Zhin Yhat1 Lambdav0 Lambda0
tempvar Yh2 LYh2 E3 E4 LnE2 absE time LE XQ ht res DumE EDumE
tempname X Y Z M2 XgXg Xg M1 W1 W2 W1W Lambda Vec Yi Sig2 E Cov B b h mh Elast
tempname Wio Wi Ew Omega hjm Wald We vy1 v XmB YmB XYmB B mfxe mfxlin mfxlog
tempname Bv1 Bv lamp1 lamp2 lamp M W b1 v1 q lmhs b2 v2 Beta P Pm IPhi Phi J D
tempname estd s sqrtdinv corr corr3 corr4 mpc2 mpc3 mpc4 uinv q1 q2 uinv2 Hat
tempname Wi1 hjm Z0 Z1 xq Eo E1 EE1 Sw Sn nw S11 S12 WY Xgw Eg Sig2n XYmK n vh
marksample touse
cap count if `touse'
qui gen `X0'=1 if `touse'
local N = r(N)
qui gen `Time'=_n if `touse'
qui tsset `Time'
local sthlp diagreg2
if "`model'"!="" {
if !inlist("`model'", "2sls", "liml", "kclass", "fuller", "gmm", "melo") {
di 
di as err " {bf:model( )} {cmd:must be} {bf:model({it: 2sls, liml, melo, kclass, fuller, gmm})}"
exit
 }
 }
if "`hetcov'"!="" {
if !inlist("`hetcov'", "white", "nwest", "bart", "trunc", "parzen", "quad") {
if !inlist("`hetcov'", "tukeyn", "tukeym", "dan", "tent") {
di 
di as err "{bf:hetcov()} {cmd:must be} {bf:({it:bart, dan, nwest, parzen, quad, tent, trunc, tukeym, tukeyn, white})}"
exit
 }
 }
 }
if !inlist("`model'", "kclass") & "`kc'"=="" {
di
di as err " {bf:kc({it:#})} {cmd:Theil k-Class works only with:} {bf:model({it:kclass})}"
exit
 }
if !inlist("`model'", "fuller") & "`kf'"=="" {
di
di as err " {bf:kf({it:#})} {cmd:Fuller k-Class works only with:} {bf:model({it:fuller})}"
exit
 }
if inlist("`model'", "gmm") & "`hetcov'"=="" {
di
di as err " {bf:hetcov( )} {cmd:must be combined with:} {bf:model({it:gmm})}"
exit
 }
if !inlist("`model'", "gmm") & "`hetcov'"!="" {
di
di as err " {bf:hetcov( )} {cmd:works only with:} {bf:model({it:gmm})}"
exit
 }
gettoken yvar 0 : 0
gettoken p 0 : 0, parse(" (") quotes
while `"`p'"' != "(" {
 local exog `"`exog' `p'"'
 gettoken p 0 : 0, parse(" (") quotes
 }
gettoken q 0 : 0, parse(" =") quotes
while `"`q'"' != "=" {
 local endog `"`endog' `q'"'
 gettoken q 0 : 0, parse(" =") quotes
 }
gettoken r 0 : 0, parse(" )") quotes
while `"`r'"' != ")" {
 local inst `"`inst' `r'"'
 gettoken r 0 : 0, parse(" )") quotes
 } 
 tsunab exog : `exog'
 tokenize `exog'
 local exog `*'
 tsunab endog : `endog'
 tokenize `endog'
 local endog `*'
 tsunab inst : `inst'
 tokenize `inst'
local inst `*'
local options "Level(cilevel)"
local allinst `"`exog' `inst'"'
local xvar `"`endog' `exog'"'
local exogex : list inst-exog
local endog `endog'
local kendog : word count `endog'
scalar kendog=`kendog'
local exog `exog'
local kexog : word count `exog'
scalar kexog=`kexog'
local exogex `exogex'
local kexogex : word count `exogex'
local inst `inst'
local kinst : word count `inst'
scalar kinst=`kinst'
local kx=kendog+kexog
local rhsx=kexog+1
markout `touse' `yvar' `endog' `inst' `exog' `allinst' `xvar' `exogex'
scalar ky=1
 local both : list yvar & exog
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS and RHS Variables}"
di as res " LHS: `yvar'"
di as res " RHS: `exog'"
 exit
 }
 local both : list yvar & endog
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS and Endogenous Variables}"
di as res " LHS  : `yvar'"
di as res " Endog: `endog'"
 exit
 }
 local both : list yvar & inst
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both LHS and Instrumental Variables}"
di as res " LHS : `yvar'"
di as res " Inst: `inst'"
 exit
 }
 local both : list endog & inst
 if "`both'" != "" {
di
di as err " {bf:{cmd:`both'} included in both Endogenous and Instrumental Variables}"
di as res " Endog: `endog'"
di as res " Inst : `inst'"
 exit
 }
 local both : list endog & exog
 foreach x of local both {
di
di as err " {bf:{cmd:`x'} included in both Endogenous and Exogenous Variables}"
di as res " Endog: `endog'"
di as res " Exog : `exog'"
 exit
 }
 _rmdcoll `varlist' `endog' `exog' `wgt' if `touse', `noconstant'
if "`endog'"=="" {
di as err " {bf:Endogenous Variable(s) must be specified}"
 exit
 } 
local yvar `yvar'
mkmat `yvar' if `touse' , matrix(`Yi')
mkmat `yvar' `endog' if `touse' , matrix(`Y')
if "`model'"!="" {
if "`noconstant'"!="" {
qui cap mkmat `exog' if `touse' , matrix(`Xg')
qui cap mkmat `exog' `exogex' `X0' if `touse' , matrix(`X')
qui cap mkmat `endog' `exog' if `touse' , matrix(`Z')
local instrhs `"`inst' `X0'"'
local DF=`N'-`kx'
 } 
else if  "`noconexog'"!="" {
qui cap mkmat `exog' if `touse' , matrix(`Xg')
qui cap mkmat `exog' `exogex' if `touse' , matrix(`X')
qui cap mkmat `endog' `exog' if `touse' , matrix(`Z')
local instrhs `"`inst'"'
local DF=`N'-`kx'
 }
 else { 
qui cap mkmat `exog' `X0' if `touse' , matrix(`Xg')
qui cap mkmat `exog' `exogex' `X0' if `touse' , matrix(`X')
qui cap mkmat `endog' `exog' `X0' if `touse' , matrix(`Z')
local instrhs `"`inst' `X0'"'
local DF=`N'-`kx'-1
 }
 }
 local dfs =`kinst'-`rhsx'
if "`exogex'" == "`inst'" {
local exogex 0
scalar kexogex=0
 } 
 local in=`N'/(`N'-`kx')
 if "`dn'"!="" {
 local DF=`N'
 local in=1
 }
if `kinst' < `kx' {
 di
 di as err " " "`model'" "{bf: cannot be Estimated} {cmd:Equation }" "`yvar'" "{cmd: is Underidentified}" 
scalar kexogex=0
di _dup(60) "-" 
di as txt "{bf:** Y  = LHS Dependent Variable}
di as txt "   " ky " : " "`yvar'"
di as txt "{bf:** Yi = RHS Endogenous Variables}
di as txt "   " kendog " : " "`endog'"
di as txt "{bf:** Xi = RHS Included Exogenous Variables}"
di as txt "   " kexog " : " "`exog'"
di as txt "{bf:** Xj = RHS Excluded Exogenous Variables}"
di as txt "   " `kexogex' " : " "`exogex'"
di as txt "{bf:** Z  = Overall Exogenous Variables}"
di as txt "   " `kinst' " : "  "`inst'"
di as txt "{bf: Model is Under Identification:}"
di as txt _col(7) "Z(" `kinst' ")" " < Yi + Xi (" `kx' ")
di as txt "* since: Z < Yi + Xi : it is recommended to use (OLS)"
di _dup(60) "-"
exit
 }
matrix `Wi'=J(`N',1,1)
qui gen `Wi'=1 if `touse'
qui gen `weit' = 1 if `touse'
mkmat `Wi' if `touse' , matrix(`Wi')
matrix `Wi'=diag(`Wi')
matrix `WY'=`Wi'*`Y'
matrix `M1'=I(`N')
 if "`exog'" != "" {
matrix `M1'=I(`N')-`Wi'*`Xg'*inv(`Xg''*`Wi''*`Wi'*`Xg')*`Xg''*`Wi''
 }
matrix `M2'=I(`N')-`Wi'*`X'*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''
matrix `W1'=`WY''*`M1'*`WY'
matrix `W2'=`WY''*`M2'*`WY'
matrix `W1W'=`W1'*inv(`W2')
matrix eigenvalues `Lambda' `Vec' = `W1W'
matrix `Lambda' =`Lambda''
svmat `Lambda' , name(`Lambdav')
rename `Lambdav'1 `Lambda'
qui summ `Lambda' if `touse'
scalar kliml=r(min)
di
yxregeq `yvar' `xvar'
 if inlist("`model'", "2sls")  {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Two Stage Least Squares (2SLS)}}"
di _dup(78) "{bf:{err:=}}"
 if "`weights'"!="" { 
di as txt _col(3) "{bf:* " "`wtitle'" " *}"
 }
matrix `Omega'=`Wi''*`Wi'*`X'*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''*`Wi'
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
 }
 if inlist("`model'", "liml") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Limited-Information Maximum Likelihood (LIML)}}"
di _dup(78) "{bf:{err:=}}"
di as txt "{bf: K - Class (LIML) Value  =} " as res %9.5f kliml
matrix `Omega'=`Wi''*`Wi'*`X'*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''*`Wi'
matrix `Omega'=(I(`N')-kliml*(I(`N')-`Omega'))
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
 }
 if inlist("`model'", "kclass") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Theil k-Class (LIML)}}"
di _dup(78) "{bf:{err:=}}"
local kc =`kc'
di as txt "{bf: K - Class Value  =} " as res %9.5f `kc'
matrix `Omega'=`Wi'*(I(`N')-`kc'*(I(`N')-`Wi'*`X' ///
*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''))*`Wi'
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
 }
 if inlist("`model'", "fuller") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Fuller k-Class (LIML)}}"
di _dup(78) "{bf:{err:=}}"
local kfc =kliml-(`kf'/(`N'-`kinst'))
di as txt "{bf:  LIML-Class Value}" _col(27) " = " as res %9.5f kliml
di as txt "{bf: Alpha-Class Value}" _col(27) " = " as res %9.5f `kf'
di as txt "{bf:     K-Class Fuller Value}" _col(27) " = " as res %9.5f `kfc'
matrix `Omega'=`Wi'*(I(`N')-`kfc'*(I(`N')-`Wi'*`X' ///
*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''))*`Wi'
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
 }
 if inlist("`model'", "melo") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Minimum Expected Loss (MELO)}}"
di _dup(78) "{bf:{err:=}}"
scalar kyi=kendog
scalar kzi=kyi+`kx'
scalar kmelo=1-`kx'/(`N'-kzi-2)
di as txt "{bf: K - Class (MELO) Value  =} " as res %9.5f kmelo
matrix `Omega'=`Wi'*(I(`N')-kmelo*(I(`N')-`Wi'*`X' ///
*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''))*`Wi'
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
 }
 if inlist("`model'", "gmm") & inlist("`hetcov'", "white") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (White Method)}}"
di _dup(78) "{bf:{err:=}}"
matrix `Omega'=`Wi''*`Wi'*`X'*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''*`Wi'
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
matrix `E'=`Yi'-`Z'*`B'
matrix `We'=(diag(`E')*diag(`E'))'
matrix `Omega'=`X'*inv(`X''*`We'*`X')*`X''
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
matrix `E'=`Yi'-`Z'*`B'
matrix `We'=(diag(`E')*diag(`E'))'
matrix `E'=`Yi'-`Z'*`B'
 }
if inlist("`hetcov'", "bart") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Bartlett Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(2/9)
local Li=`i'/(1+`L')
local kw=1-`Li'
}
if inlist("`hetcov'", "dan") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Daniell Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(2/9)
local Li=`i'/(1+`L')
local kw=sin(_pi*`Li')/(_pi*`Li')
 }
if inlist("`hetcov'", "nwest") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Newey-West Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=1
local Li=`i'/(1+`L')
local kw=1-`Li'
 }
if inlist("`hetcov'", "parzen") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Parzen Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(2/9)
local Li=`i'/(1+`L')
local kw=1-`Li'
 if (`Li' < 0.05) { 
local kw=1-6*`Li'^2+6*`Li'^3
 else { 
local kw=2*(1-`Li')^2
 }
 }
 if (`Li' < 0.5) { 
local kw=1-6*`Li'^2+6*`Li'^3
 else { 
local kw=2*(1-`Li')^3
 }
 }
 }
if inlist("`hetcov'", "quad") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Quadratic Spectral Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(2/25)
local Li=`i'/(1+`L')
local kw=(25/(12*_pi^2*`Li'^2))*(sin(6*_pi*`Li'/5)/(6*_pi*`Li'/5)-sin(6*_pi*`Li'/5+_pi/2))
}
if inlist("`hetcov'", "tent") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Tent Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(2/9)
local Li=`i'/(1+`L')
local kw=2*(1-cos(`Li'*`Li'))/(`Li'^2)
 }
if inlist("`hetcov'", "trunc") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Truncated Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(1/4)
local Li=`i'/(1+`L')
local kw=1-`Li'
 }
if inlist("`hetcov'", "tukeym") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Tukey-Hamming Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(1/4)
local Li=`i'/(1+`L')
local kw=0.54+0.46*cos(_pi*`Li')
 }
if inlist("`hetcov'", "tukeyn") {
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* Generalized Method of Moments (GMM) - (Tukey-Hanning Method)}}"
di _dup(78) "{bf:{err:=}}"
local i=1
local L=4*(`N'/100)^(1/4)
local Li=`i'/(1+`L')
local kw=(1+sin((_pi*`Li')+_pi/2))/2
 }
if inlist("`model'", "gmm") & !inlist("`hetcov'", "white") {
qui gen `Z0' = 1 if `touse'
qui replace `Z0' = 0 in 1
qui foreach var of local xvar {
qui gen `xq'`var' = `var'[_n-1] if `touse'
qui replace `xq'`var' = 0 in 1
 }
if "`noconstant'"!="" {
qui mkmat `xq'* if `touse' ,matrix(`M')
 }
if "`noconstant'"=="" {
qui mkmat `xq'* `Z0' if `touse' ,matrix(`M')
 }
if "`noconexog'"!="" {
qui mkmat `xq'* if `touse' ,matrix(`M')
 }
matrix `Omega'=`Wi''*`Wi'*`X'*inv(`X''*`Wi''*`Wi'*`X')*`X''*`Wi''*`Wi'
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
matrix `E'=`Yi'-`Z'*`B'
svmat `E' , name(`Eg')
rename `Eg'1 `Eg'
qui gen `E1'=`Eg'[_n-1] if `touse'
qui gen `EE1'=`E1'*`Eg' if `touse'
qui replace `EE1' = 0 if `EE1'==.
mkmat `EE1' if `touse' , matrix(`EE1')
matrix `We'=(diag(`E')*diag(`E'))'
matrix `Sw'=`Z''*`We'*`Z'
matrix `We'=diag(`EE1')
matrix `S11'=`Z''*`We'*`M'
matrix `S12'=`M''*`We'*`Z'
matrix `Sn'=(`S11'+`S12')*`kw'
matrix `nw'=(`Sw'+`Sn')*`in'
matrix `nw'=`nw'*`in'
matrix `Omega'=`X'*inv(`X''*`X')*`X''
matrix `B'=inv(`Z''*`Omega'*`Z')*`Z''*`Omega'*`Yi'
matrix `Omega'= `X'*inv(`X''*`X')*`X''
matrix `Cov'=inv(`Z''*`Omega'*`Z')*`nw'*inv(`Z''*`Omega'*`Z')
matrix `E'=`Yi'-`Z'*`B'
 }
matrix `Yh'=`Z'*`B'
matrix `E'=`Yi'-`Z'*`B'
matrix `We'=(diag(`E')*diag(`E'))'
matrix `hjm'=(`E''*(`X'*inv(`X''*`We'*`X')*`X'')*`E')
local lmihj=`hjm'[1,1]
local dfgmm=`kinst'-`kx'
local lmihjp= chiprob(`dfgmm', abs(`lmihj'))
qui svmat `E' , names(`E')
qui rename `E'1 `E'
qui svmat `Yh' , names(`Yh')
qui rename `Yh'1 `Yh'
matrix `SSE'=`E''*`E'
local SSEo=`SSE'[1,1]
matrix `Ew'=`Wi'*`Yi'-`Wi'*`Z'*`B'
matrix `Sig2n'=(`Ew''*`Ew')/`N'
local Sig2n=`Sig2n'[1,1]
matrix `Sig2'=(`Ew''*`Ew')/`DF'
local Sig=sqrt(`Sig2'[1,1])
matrix `Cov'=`Sig2'*inv(`Z''*`Omega'*`Z')
if inlist("`model'", "gmm") & inlist("`hetcov'", "white") {
matrix `Cov'=inv(`Z''*`Omega'*`Z')
 }
if inlist("`model'", "gmm") & !inlist("`hetcov'", "white") {
matrix `Cov'=inv(`Z''*`Omega'*`Z')*`nw'*inv(`Z''*`Omega'*`Z')
 }
qui summ `yvar' if `touse' 
local Yb=r(mean)
qui gen `YYm'=(`yvar'-`Yb')^2 if `touse' 
qui summ `YYm' if `touse' 
qui scalar SSTm = r(sum)
qui gen `YYv'=(`yvar')^2 if `touse' 
qui summ `YYv' if `touse' 
local SSTv = r(sum)
qui summ `weit' if `touse' 
qui local Wib = r(mean)
qui gen `Wi1'=sqrt(`weit'/`Wib') if `touse' 
mkmat `Wi1' if `touse' , matrix(`Wi1')
qui gen `Wio'=(`Wi1')^2 if `touse' 
mkmat `Wio' if `touse' , matrix(`Wio')
matrix `P'  =diag(`Wi1')
matrix `Pm' =diag(`Wio')
matrix `IPhi'=`P''*`P'
matrix `Phi'=inv(`P''*`P')
matrix `J'= J(`N',1,1)
matrix `D'=(`J'*`J''*`IPhi')/`N'
matrix `SSE'=`E''*`IPhi'*`E'
matrix `SST'=(`Yi'-`D'*`Yi')'*`IPhi'*(`Yi'-`D'*`Yi')
local r2c=1-`SSE'[1,1]/`SST'[1,1]
matrix `SST'=(`Yi''*`Yi')
local r2u=1-`SSE'[1,1]/`SST'[1,1]
local llf=-(`N'/2)*log(2*_pi*`SSE'[1,1]/`N')-(`N'/2)
matrix `Beta'= `B''
local N = `N'
local DOF =`DF'
matrix `B' = `B''
 if "`model'"!="" {
 if "`noconstant'"!="" {
 matrix colnames `Cov' = `endog' `exog'
 matrix rownames `Cov' = `endog' `exog'
 matrix colnames `B'   = `endog' `exog'
 }
else if "`noconexog'"!="" {
 matrix colnames `Cov' = `endog' `exog'
 matrix rownames `Cov' = `endog' `exog'
 matrix colnames `B'   = `endog' `exog'
 }
else { 
 matrix colnames `Cov' = `endog' `exog' _cons
 matrix rownames `Cov' = `endog' `exog' _cons
 matrix colnames `B'   = `endog' `exog' _cons
 }
 }
di as txt _col(3) "Number of Obs"  _col(19) " = " %10.0f as res `N'
if `r2c'>0 {
ereturn post `B' `Cov' , dep(`yvar') obs(`N') dof(`DOF')
qui test `xvar'
local f=r(F)
local fp=r(p)
local r2u_a=1-((1-`r2u')*(`N'-1)/(`DF'))
local r2c_a=1-((1-`r2c')*(`N'-1)/(`DF'))
local fp= fprob(`kx', `DF', `f')
matrix `Wald'=`f'*`kx'
local wald=`Wald'[1,1]
local waldp=chiprob(`kx', abs(`wald'))
di as txt _col(3) "Wald Test" _col(19) " = " %10.4f as res `wald' _col(41) as txt "P-Value > Chi2(" as res `kx' ")" _col(65) " = " %10.4f as res `waldp'
di as txt _col(3) "F Test" _col(19) " = " %10.4f as res `f' _col(41) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(65) " = " %10.4f as res `fp'
di as txt _col(3) "R-squared" _col(19) " = " %10.4f as res `r2c' as txt _col(41) "Raw R2" _col(65) " = " %10.4f as res `r2u'
ereturn scalar r2c =`r2c'
ereturn scalar r2c_a=`r2c_a'
ereturn scalar f =`f'
ereturn scalar fp=`fp'
ereturn scalar wald =`f'
ereturn scalar waldp=`waldp'
di as txt _col(3) "R-squared Adj" _col(19) " = " %10.4f as res `r2c_a' as txt _col(41) "Raw R2 Adj" _col(65) " = " %10.4f as res `r2u_a'
di as txt _col(3) "Root MSE (Sigma)" _col(19) " = " %10.4f as res `Sig' as txt _col(41) "Log Likelihood Function" _col(65) " = " %10.4f as res `llf'
ereturn scalar r2u =`r2u'
ereturn scalar r2u_a=`r2u_a'
 }
if `r2c' < 0 {
 qui foreach var of local endog {
 qui regress `var' `inst' if `touse' , `noconstant'
 qui predict `Yhat1'`var' if `touse' 
 }
 qui regress `yvar' `Yhat1'* `exog'  if `touse' , `noconstant'
 local ssr=e(mss)
local r2cc =(`ssr'/`SSE'[1,1]*`DF')/(`ssr'/`SSE'[1,1]*`DF'+`DF')
local r2cc_a=1-((1-`r2cc')*(`N'-1)/(`DF'))
local fc=`r2cc'/(1-`r2cc')*(`DF')/(`kx')
local r2c_a=1-((1-`r2c')*(`N'-1)/(`DF'))
local r2u_a=1-((1-`r2u')*(`N'-1)/(`DF'))
local fpc= fprob(`kx', `DF', `fc')
di as txt _col(3) "F Test" _col(19) " = " %10.4f as res `fc' _col(41) as txt "P-Value > F(" as res `kx' " , " `DF' ")" _col(65) " = " %10.4f as res `fpc'
di as txt _col(3) "R2 (-)" _col(19) " = " %10.4f as res `r2c' as txt _col(41) "Adj R2 (-)" _col(65) " = " %10.4f as res `r2c_a'
di as txt _col(3) "Corrected R2" _col(19) " = " %10.4f as res `r2cc' as txt _col(41) "Raw R2" _col(65) " = " %10.4f as res `r2u'
ereturn post `B' `Cov' , dep(`yvar') obs(`N') dof(`DOF')
ereturn scalar r2c =`r2c'
ereturn scalar r2c_a=`r2c_a'
ereturn scalar f =`fc'
ereturn scalar fp=`fpc'
ereturn scalar r2cc=`r2cc'
ereturn scalar r2cc_a =`r2cc_a'
di as txt _col(3) "Corrected R2 Adj" _col(19) " = " %10.4f as res `r2cc_a' as txt _col(41) "Raw R2 Adj" _col(65) " = " %10.4f as res `r2u_a'
di as txt _col(3) "Root MSE (Sigma)" _col(19) " = " %10.4f as res `Sig' as txt _col(41) "Log Likelihood Function" _col(65) " = " %10.4f as res `llf'
ereturn scalar r2u =`r2u'
ereturn scalar r2u_a=`r2u_a'
ereturn scalar sig=`Sig'
 } 
ereturn display
matrix `b2'=e(b)
matrix `v2'=e(V)
if inlist("`model'", "gmm") {
local dfgmm=`kinst'-`kx'
di as txt " Hansen Over Identification J Test =" _col(36) %10.5f as res `lmihj' _col(50) as txt "P-Value > Chi2(" `dfgmm' ")" _col(70) as res %5.4f as res `lmihjp'
ereturn scalar lmihj = `lmihj'
ereturn scalar lmihjp = `lmihjp'
 }
di
di _dup(78) "{bf:{err:=}}"
di as txt "{bf:{err:* 2SLS-IV Model Selection Diagnostic Criteria - `model' }}"
di _dup(78) "{bf:{err:=}}"
local llf=-(`N'/2)*log(2*_pi*`SSE'[1,1]/`N')-(`N'/2)
local AIC=`SSE'[1,1]/`N'*exp(2*`kx'/`N')
local LAIC=ln(`SSE'[1,1]/`N')+2*`kx'/`N'
local FPE=(`SSE'[1,1]/(`DF'))*(1+`kx'/`N')
local SC=`SSE'[1,1]/`N'*`N'^(`kx'/`N')
local LSC=ln(`SSE'[1,1]/`N')+`kx'*ln(`N')/`N'
local HQ=`SSE'[1,1]/`N'*ln(`N')^(2*`kx'/`N')
local Rice=`SSE'[1,1]/`N'/(1-2*`kx'/`N')
local Shibata=`SSE'[1,1]/`N'*(`N'+2*`kx')/`N'
local GCV=`SSE'[1,1]/`N'*(1-`kx'/`N')^(-2)
di as txt "- Log Likelihood Function       LLF" _col(49) as res "=" as res %12.4f `llf'
di as txt "- Akaike Final Prediction Error AIC" _col(49) as res "=" as res %12.4f `AIC'
di as txt "- Schwartz Criterion            SC" _col(49) as res "=" as res %12.4f `SC'
di as txt "- Akaike Information Criterion  ln AIC" _col(49) as res "=" as res %12.4f `LAIC'
di as txt "- Schwarz Criterion             ln SC" _col(49) as res "=" as res %12.4f `LSC'
di as txt "- Amemiya Prediction Criterion  FPE" _col(49) as res "=" as res %12.4f `FPE'
di as txt "- Hannan-Quinn Criterion        HQ" _col(49) as res "=" as res %12.4f `HQ'
di as txt "- Rice Criterion                Rice" _col(49) as res "=" as res %12.4f `Rice'
di as txt "- Shibata Criterion             Shibata" _col(49) as res "=" as res %12.4f `Shibata'
di as txt "- Craven-Wahba Generalized Cross Validation GCV" _col(49) as res "=" as res %12.4f `GCV'
di _dup(63) "-"
ereturn scalar aic = `AIC'
ereturn scalar laic = `LAIC'
ereturn scalar fpe = `FPE'
ereturn scalar sc = `SC'
ereturn scalar lsc = `LSC'
ereturn scalar hq = `HQ'
ereturn scalar rice = `Rice'
ereturn scalar shibata = `Shibata'
ereturn scalar gcv = `GCV'
ereturn scalar llf = `llf'
end

program define yxregeq
version 10.0
 syntax varlist 
tempvar `varlist'
gettoken yvar xvar : varlist
di as txt "{hline 60}"
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
end

