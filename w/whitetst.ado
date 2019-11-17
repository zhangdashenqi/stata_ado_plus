*! whitetst 1.2.0 CFB/NJC 11 Oct 1999 rev for _rmcoll  (STB-55: sg137)
* whitetst 1.1.0 CFB/NJC 2O Sept 1999
* whitetst V1.00   C F Baum/Nick Cox 9920
program define whitetst, rclass
	version 6.0
	syntax [if] [in] [, noSample ] 
	if "`e(cmd)'" != "regress" {
		error 301
	}
	tempname res res2 b one regest
	
	/* get regressorlist from previous regression */
        mat `b' = e(b)
        local rvarlst : colnames `b'
        local rvarlst : subinstr local rvarlst "_cons" "", word count(local hascons)
     
	marksample touse
	if "`sample'" == "" { qui replace `touse' = 0 if !e(sample) }

	/* fetch residuals and generate their squares */
	qui predict `res' if `touse', res
	qui gen `res2' = `res' * `res'

	gen `one' = 1
	local rlist "`one' `rvarlst'" 
	tokenize `rlist' 
	local nrvars : word count `rlist' 

	/* generate all products of pairs from `one' and `rvarlst' */ 
        local i = 1
        while `i' <= `nrvars' {
	        local j = `i' 
	        while `j' <= `nrvars' {
			tempvar prod 
                	gen `prod' = ``i'' * ``j''
			local plist "`plist' `prod'" 
                        local j = `j' + 1
	        }
        	local i = `i' + 1
        }
	
	estimates hold `regest'
	tokenize `plist'
	mac shift /* ignore first such variable */ 
	qui _rmcoll `*' ,noconstant
	local xmtx  `r(varlist)'
	
	/* regress resids on all product variables; 
	constant included since first ignored */
	qui regress `res2' `xmtx' 

	return scalar N = e(N)	
	return scalar white = e(N) * e(r2)
	return scalar df = e(df_m)
	return scalar p  = chiprob(return(df),return(white))
	
	estimates unhold `regest'
	
	di _n in g "White's general test statistic : "   /*
	*/ in y %9.0g return(white) /* 
	*/ in g "  Chi-sq(" %2.0f return(df)  ")  P-value = " /*
	*/ in y %6.0g return(p)
end

