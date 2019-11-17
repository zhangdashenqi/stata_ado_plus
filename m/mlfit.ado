*! Criteria for assessing ML model fit, by A. Tobias & M.J. Campbell
*! version 1.1.12, 15 May 1998  STB-45 sg90

cap program drop mlfit
program define mlfit
	version 1.1
	local comd="$S_E_cmd"

	if ("`comd'"=="logistic" | "`comd'"=="poisson") {
    	        local n = $S_E_nobs
		local ll  = $S_E_ll    
		local ll2  = -2*`ll'
		local np = $S_E_mdf+1     
	} 
	else if ("`comd'"=="logit" | "`comd'"=="clogit" | "`comd'"=="mlogit") {
		     local n = _result(1)
	     	     local ll  = _result(2)    
		     local ll2  = -2*`ll'
	       	     local chi = _result(6)	
  	             if `chi'!=. {
			local np = _result(3)+1
	             } 
   	             else  local np = _result(3)     
	} 
	else if ("`comd'"=="glm") {
		     local n = $S_1
	             local ll  = (-$S_3)/2    
  		     local ll2  = -2*`ll'
	       	     local chi = $S_4
  	             if `chi'!=. {
			local np = ($S_1-$S_2)
	             } 
   	             else  local np = ($S_1-$S_2)-1
	} 
	else  {	
		display in red "ERROR: Last estimates not found" 
		display in red "Can only be used after glm, logit, clogit, mlogit, logistic or poisson command"
		exit
	} 

	local aic=`ll2'+2*`np'
	local sc=`ll2'+`np'*ln(`n')
	display
	display in green " Criteria for assessing " "`comd'" " model fit"
	display in green " Akaike's Information Criterion (AIC) and Schwarz's Criterion (SC)"
	display 
	display in green "------------------------------------------------------------------------------"
	display in green _col(2) "AIC" _col(16) "SC" _col(29) "| -2 Log Likelihood" _col(52) "Num.Parameters"
	display in green "----------------------------+-------------------------------------------------"
	display _col(2) `aic' _col(16) `sc' _col(29) in green "|" _col(32) in ye `ll2' _col(55) `np'
	display in green "------------------------------------------------------------------------------"

	mac def S_E_aic `aic'
	mac def S_E_sc `sc'
	mac def S_E_ll  `ll'
	mac def S_E_ll2 `ll2'
	mac def S_E_np  `np'
	mac def S_E_nobs `n'
end
