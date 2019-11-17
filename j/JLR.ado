program define JLR , rclass
version 8

 if e(cmd) != "johans"{
     dis in red "JLR must be used after" in g  " johans "  in r "command"
 }

mat A = e(TEVL)               /*the matrix store the eigenvalue vector*/
local r = rowsof(A)
local lamda = A[`r',1]       /*lamda min in eq(5) of Sarno&Taylor,1998,P311*/
local T = `e(tmax)' - `e(tmin)' + 1
local jlr = -`T'*ln(1 - `lamda')
local pvalue = 1 - chi2(1,`jlr')

return scalar lamda = `lamda'
return scalar T = `T'
return scalar JLR = `jlr'
return scalar pvalue = `pvalue'

dis in g _n " Johansen LR test for panle unit root: "      in g "          T = "  in y `T'
dis in g      "     H0: at least one series is unit root"
dis in g      "     H1: all serires are stationary" _n
dis in y      "     JLR     = " in y `jlr'
dis in y      "     P-value = " in y `pvalue'    in g "              note: for large sample, T>100" _n
dis in g      "  The 5% critical values for small sample given by Taylor(1998) are:" 
dis in g      "  ______________________________________________________"
dis in smcl in g  "  T=50       T=75       T=100       T=200       T=300 "  
dis in g      "  ______________________________________________________"
dis in smcl in g  "  4.5816     4.1472     3.9966      3.9324      3.9018" 
dis in g      "  ______________________________________________________"

end
exit
