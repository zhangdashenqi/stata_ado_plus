program define spmstarxt1_lf
version 10.0
args lnf XB Rho1 Sigma
tempvar A rYW1
gen double `rYW1'=`Rho1'*w1y_$ML_y1
scalar p1 = `Rho1'
matrix p1W1 = p1*W1
matrix IpW = I_n - p1W1
qui gen double `A' = ln(det(IpW))/$nobs if _n == 1
scalar A = `A'
qui replace `lnf'= A + ln(normalden($ML_y1-`rYW1'-`XB', 0, `Sigma'))
end
