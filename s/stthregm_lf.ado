
capture program drop stthregm_lf
program define stthregm_lf
version 9.0

args lnf lny0 m lgtp 

tempvar y0 t p f
 
quietly gen double `y0'=exp(`lny0')
quietly gen double `t' = $time_combination
quietly gen `f' = $ML_y2	
quietly gen double `p'=exp(`lgtp')/(1+exp(`lgtp'))
quietly replace `lnf'= /*
     */ `f'*(`lny0'-0.5*ln(2*_pi*(`t'^3))-0.5*(`y0'+`m'*`t')^2/`t'+ln(`p')) /*
     */ +(1-`f')*ln(`p'*(normal((`m'*`t'+`y0')/sqrt(`t'))- /*
     */ exp(-2*`y0'*`m')*normal((`m'*`t'-`y0')/sqrt(`t')))+(1-`p'))





end

