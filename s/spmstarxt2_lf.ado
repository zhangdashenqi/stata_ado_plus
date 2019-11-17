program define spmstarxt2_lf
version 10.0
args lnf XB Rho1 Rho2 Sigma
tempvar A rYW1 rYW2
gen double `rYW1'=`Rho1'*w1y_$ML_y1
gen double `rYW2'=`Rho2'*w2y_$ML_y1
scalar p1 = `Rho1'
scalar p2 = `Rho2'
matrix p1W1 = p1*W1
matrix p2W2 = p2*W2
matrix IpW = I_n - p1W1 - p2W2
qui gen double `A' = ln(det(IpW))/$nobs if _n == 1
scalar A = `A'
qui replace `lnf'= A + ln(normalden($ML_y1-`rYW1'-`rYW2'-`XB', 0, `Sigma'))
end
