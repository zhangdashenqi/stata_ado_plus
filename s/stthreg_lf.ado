
capture program drop stthreg_lf
program define stthreg_lf
version 9.0

args lnf lny0 m $lf_time_input

tempvar d v t f
quietly gen double `t' = $time_combination
quietly gen `f' = $ML_y2	
quietly gen double `d'=-(`m')/exp(`lny0')

quietly gen double `v'=exp(-2*(`lny0'))
quietly replace `lnf'=                                                   ///
        `f'*(-.5*(ln(2*_pi*`v'*(`t'^3))+(`d'*`t'-1)^2/(`v'*`t')))         ///
        +(1-`f')*ln(norm((1-`d'*`t')/sqrt(`v'*`t'))-                      ///
        exp(2*`d'/`v')*norm(-(1+`d'*`t')/sqrt(`v'*`t')))
end

