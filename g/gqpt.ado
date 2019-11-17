* !gqpt.ado version 1.01 December/1999 (STB-55: sg140)
* Manuel G Scotto
* Gumbel Probability Plot
program define gqpt
version 6
local varlist "req ex min(1) max(1)"
local if "opt"
local in "opt"
parse "`*'"
parse "`varlist'", parse (" ")
local X `1'
preserve
if ("`if'"!="") {
        qui keep `if'
}
if ("`in'"!="") {
        qui keep `in'
}
sort `X'
gen pi=_n/(_N+1) 
gen y=-log(-log(pi)) 
qui regress y `X' 
local delta=1/_coef[`X'] in 1
local lambda=-`delta'*_coef[_cons] 
label var `X' "x_(i:n)"
label var y "-ln(-ln(pi))"
set textsize 125
graph y `X'
local an=log(log(_N))
local bn=(log(_N)+log(log(2)))/(log(log(_N))-log(log(2)))
local q=(`X'[_N]-`X'[_N/2+1])/(`X'[_N/2+1]-`X'[1])
local w=`an'*(`q'-`bn')
display
display in green _col(1) "Variable | " _col(13) "Delta" _col(28) "Lambda" _col(40) "Q" _col(55) "W"
display in green "---------------------------------------------------------------"
display in green _col(1) "`X'" _col(10) "|" _col(13) in yellow `delta' _col(28) in yellow `lambda' _col(40) in yellow `q' _col(55) in yellow `w'  
display in green "---------------------------------------------------------------"
display
display in green "-----------------------------------------------------"
display in green "Values corresponding to the usual significance levels"
display in green "-----------------------------------------------------"
display in green _col(7) "alpha" _col(20) "b" _col(35) "a"
display in yellow _col(7) ".050" _col(17) "-1.561334" _col(32) "3.161461"
display in yellow _col(7) ".025" _col(17) "-1.719620" _col(32) "3.841321"
display in yellow _col(7) ".010" _col(17) "-1.893530" _col(32) "4.740459"
display in yellow _col(7) ".001" _col(17) "-2.222951" _col(32) "7.010001"
mac def S_1 `q'
mac def S_2 `w'
mac def S_3 `delta'
mac def S_4 `lambda'
end

