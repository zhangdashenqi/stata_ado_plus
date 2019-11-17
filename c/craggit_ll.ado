program craggit_ll
version 9.2
args lnf x1b x2g sigma
quietly replace `lnf' = ln(1-normal(`x1b')) if $ML_y2 == 0
quietly replace `lnf' = -.5*ln(2*_pi)-ln(`sigma')-((($ML_y2-`x2g')	///
*($ML_y2-`x2g'))/(2*`sigma'*`sigma'))+ln(normal(`x1b'))-ln(normal(`x2g'/`sigma')) if $ML_y2>0
end
