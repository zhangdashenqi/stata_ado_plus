*! 1.1.0  07dec98  Jeroen Weesie/ICS
program define varcond, rclass
	version 6.0
	
	syntax varlist [if] [in] [aw fw iw] [, Cond(str) cons Display Format(str)]

	* scratch
   tempvar touse
   tempname A Vec Val

	* code for handling constant
	if "`cons'" != "cons" { 
		local nocons "nocons" 
	} 
	else local cns "+cons"

	* selection of rows of implied matrix
	marksample touse
       
	* spectral decomposition of A = X'*Diag(W)*X, with X the matrix of variables  	
	quiet matrix acc `A' = `varlist' if `touse' [`weight'`exp'], `nocons'
	quiet mat symeigen `Vec' `Val' = `A' 
	local nA colsof(`A')

	* condition number of X is the square root of the condition number of X'X    
	return scalar cond = sqrt(`Val'[1,1]/`Val'[1,`nA'])
	return matrix eigenval `Val'

	* output
	if "`cond'" == "" | "`display'" != "" {
		if "`format'" == "" { 
			local format "%10.2g" 
		}
		quiet count if `touse' > 0
		di in gr "condition number of data [" in ye r(N) in gr /*
			*/ " obs, " in ye colsof(`A') in gr " vars`cns'] = "  /*
			*/ in ye `format' return(cond)
	}
	if "`cond'" != "" { 
		scalar `cond' = return(cond) 
	}
end
