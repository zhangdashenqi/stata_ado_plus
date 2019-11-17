*! -sperr_ll- Auxiliary program for -spatreg-                                  
*! Version 1.0 - 29 January 2001                                               
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define program                                                           
*  ----------------------------------------------------------------------------

program define sperr_ll
version 7.0
args lnf $ARGS

tempvar L1 L2
qui gen double `L1'=`lambda'*EIGS1
qui gen double `L2'=`lambda'*yLAG1
local NX=colsof(OLSb)
local NX=`NX'-1
local NAMES : colnames(OLSb)
local i=1
while `i'<=`NX' {
	local VAR : word `i' of `NAMES'
	tempvar X`i'
	qui gen double `X`i''=`beta`i''*`VAR'
	local LIST1 "`LIST1'`X`i''-"
	local i=`i'+1
}
local i=1
while `i'<=`NX' {
	tempvar XX`i'
	qui gen double `XX`i''=`lambda'*`beta`i''*XLAG`i'
	local LIST2 "`LIST2'`XX`i''+"
	local i=`i'+1
}
qui replace `lnf'=ln(1-`L1')-0.5*ln(2*_pi)-0.5*ln(`sigma'^2)-    /*
             */   (0.5/(`sigma'^2))*((`e(depvar)'-`L2'-`LIST1'   /*
             */   `beta0'+`LIST2'`lambda'*`beta0')^2)

end


