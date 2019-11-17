*! r2reg3 V3.0 28oct2011
*! Emad Abd Elmessih Shehata
*! Assistant Professor
*! Agricultural Research Center - Agricultural Economics Research Institute - Egypt
*! Email: emadstat@hotmail.com
*! WebPage: http://emadstat.110mb.com/stata.htm

program define r2reg3 , rclass
version 10
tempvar E`var' Yb_Y`var' Sig2 YMAT R4S SYY
tempname Ybv Yb Yv E`var' Yb_Y`var' Sig2 Omega YM RS1 RS2 RS3 RS4 RS5
tempname Y Ev E W Omega IMn Dt YMAT Mat1 Mat2 Mat3 R2Mat Trm RSQ
tempname SSE1 SSE2 SSE3 SSE4 MSS1 MSS2 MSS3 MSS4 SST1 SST2 SST3 SST4
marksample touse
 {
preserve
scalar N=e(N)
scalar K=e(k)
scalar Q=e(k_eq)
scalar DFF=(Q*N-K)/(K-Q)
scalar DFChi=(K-Q)
local N=e(N)
local K=e(k)
local Q=e(k_eq)
local DF1=K-Q
local DF2=Q*N
local DFChi=(K-Q)
mat `Omega'= e(Sigma)
local varlist `e(depvar)'
foreach var of local varlist {
qui predict `E'`var' if `touse' , equation(`var') res
qui summarize `var' if `touse'
qui gen `Yb_Y'`var' = `var' - `r(mean)' if `touse'
 }
mkmat `E'`var'* if `touse' , matrix(`E')
mkmat `e(depvar)' if `touse' , matrix(`Y')
mkmat `Yb_Y'`var'*   if `touse'  , matrix(`Yb')
svmat `Y' , name(`YMAT')
matrix `Ybv'=vec(`Yb')
matrix `Yv'=vec(`Y')
matrix `Ev'=vec(`E')
matrix `W'=inv(`Omega')#I(N)
matrix `Sig2'=det(`Omega')
scalar Sig2=`Sig2'[1,1]
matrix `SSE1'=det(`E''*`E')
matrix `SSE2'=`Ev''*`W'*`Ev'
matrix `SSE3'=`Ev''*`Ev'
matrix `SST1'=det(`Yb''*`Yb')
matrix `SST2'=`Ybv''*`W'*`Ybv'
matrix `SST3'=`Ybv''*`Ybv'
scalar v=1/N
matrix `IMn'=J(N,N,v)
matrix `Dt'=I(N)-`IMn'
forvalues i =1/`Q' {
scalar R2_`i'=e(r2_`i')
 }
qui egen `SYY' = varprod(`Yb_Y'`var'*) if `touse'
qui sum `SYY' if `touse' , meanonly
scalar SY=r(mean)
matrix `Trm'=trace(inv(`Omega'))*SY
scalar R5=1-(Q/`Trm'[1,1])
qui gen double `R4S' = . if `touse'
scalar R4 = 0
forvalues i =1/`Q' {
mkmat `YMAT'`i' if `touse' , matrix(`YM')
matrix `Mat1'=`YM''*`Dt'*`YM'
matrix `Mat2'=`Yv''*I(`Q')#`Dt'*`Yv'
scalar `Mat3'=`Mat1'[1,1]/`Mat2'[1,1]
matrix `R2Mat'=R2_`i'*`Mat3'
scalar R4`i'=`R2Mat'[1,1]
qui replace `R4S' = R4`i' if `touse'
qui sum `R4S' if `touse' , meanonly
qui replace  `R4S' = r(mean) if `touse'
scalar R4 = R4 + r(mean)
 }
forvalues i = 1/3 {
matrix `MSS`i''=`SST`i''-`SSE`i''
matrix R`i'=1-(`SSE`i''*inv(`SST`i''))
scalar R`i'=R`i'[1,1]
 }
forvalues i = 1/5 {
scalar ADR`i'=1-(1-R`i')*((Q*N-Q)/(Q*N-K))
scalar F`i'=R`i'/(1-R`i')*DFF
scalar Chi`i'= -N*(log(1-R`i'))
scalar PChi`i'= chiprob(DFChi, Chi`i')
scalar  PF`i'= fprob(`DF1',`DF2', F`i')
 }
scalar LSig2=log(Sig2)
scalar LLF=-(N*Q/2)*(1+log(2*_pi))-(N/2*abs(LSig2))
restore
 }
di as txt "{bf:{err:========================================================}}"
di as txt "{bf:{err:* Overall System R2 - Adjusted R2 - F Test - Chi2 Test *}}"
di as txt "{bf:{err:========================================================}}"
mat `RS1'=R1,ADR1,F1,PF1,Chi1,PChi1
mat `RS2'=R2,ADR2,F2,PF2,Chi2,PChi2
mat `RS3'=R3,ADR3,F3,PF3,Chi3,PChi3
mat `RS4'=R4,ADR4,F4,PF4,Chi4,PChi4
mat `RS5'=R5,ADR5,F5,PF5,Chi5,PChi5
mat `RSQ'=`RS1' \ `RS2' \ `RS3' \ `RS4' \ `RS5'
mat rownames `RSQ' = Berndt McElroy Judge Dhrymes Greene
mat colnames `RSQ' = R2 Adj_R2 F "P-Value" Chi2 "P-Value"
matlist `RSQ', twidth(8) border(all) lines(columns) rowtitle(Name) format(%8.4f)
di as txt "  Number of Parameters         =" as res _col(35) %10.0f K
di as txt "  Number of Equations          =" as res _col(35) %10.0f Q
di as txt "  Degrees of Freedom F-Test    =" as res _col(39) "(" K-Q ", " Q*N ")"
di as txt "  Degrees of Freedom Chi2-Test =" as res _col(35) %10.0f DFChi
di as txt "  Log Determinant of Sigma     =" as res _col(35) %10.4f LSig2
di as txt "  Log Likelihood Function      =" as res _col(35) %10.4f LLF
return scalar f_df1 = `DF1'
return scalar f_df2 = `DF2'
return scalar chi_df = DFChi
return scalar k=`K'
return scalar k_eq=`Q'
return scalar N=`N'
return scalar lsig2=LSig2
return scalar llf=LLF
return scalar chi_g = Chi5
return scalar chi_d = Chi4
return scalar chi_b = Chi3
return scalar chi_j = Chi2
return scalar chi_m = Chi1
return scalar f_g = F5
return scalar f_d = F4
return scalar f_b = F3
return scalar f_j = F2
return scalar f_m = F1
return scalar r2a_g = ADR5
return scalar r2a_d = ADR4
return scalar r2a_b = ADR3
return scalar r2a_j = ADR2
return scalar r2a_m = ADR1
return scalar r2_g = R5
return scalar r2_d = R4
return scalar r2_b = R3
return scalar r2_j = R2
return scalar r2_m = R1
end

