program define spmstarxt3_lf
version 10.0
args lnf XB Rho1 Rho2 Rho3 Sigma
tempvar A rYW1 rYW2 rYW3
gen double `rYW1'=`Rho1'*w1y_$ML_y1
gen double `rYW2'=`Rho2'*w2y_$ML_y1
gen double `rYW3'=`Rho3'*w3y_$ML_y1
scalar p1 = `Rho1'
scalar p2 = `Rho2'
scalar p3 = `Rho3'
matrix p1W1 = p1*W1
matrix p2W2 = p2*W2
matrix p3W3 = p3*W3
matrix IpW = I_n - p1W1 - p2W2- p3W3
qui gen double `A' = ln(det(IpW))/$nobs if _n == 1
scalar A = `A'
qui replace `lnf'= A + ln(normalden($ML_y1-`rYW1'-`rYW2'-`rYW3'-`XB', 0, `Sigma'))
end
