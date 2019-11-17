*! -splag_ll- Auxiliary program for -spatreg-                                  
*! Version 1.0 - 29 January 2001                                               
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define program                                                           
*  ----------------------------------------------------------------------------

program define splag_ll
version 7.0

args lnf theta1 rho sigma
tempvar R1 R2
qui gen double `R1'=`rho'*EIGS1
qui gen double `R2'=`rho'*yLAG1
qui replace `lnf'=ln(1-`R1')-0.5*ln(2*_pi)-0.5*ln(`sigma'^2)-         /*
             */   (0.5/(`sigma'^2))*(($ML_y1-`R2'-`theta1')^2)
end
