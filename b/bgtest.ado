* bgtest V1.01 C F Baum/Vince Wiggins 9821 (STB-55: sg136)

program define bgtest, rclass
	syntax [if] [in] [,Lags(integer 1)] 
	version 6.0
	if "`e(cmd)'" ~= "regress" {
		error 301
	}
	if `lags'<1 | `lags' > 0.25*e(N) {
		dis in red "Error: lags must be positive and <25% of N."
		error 198
	}
	 tempname b res regest
	 				/* get regressorlist from previous regression */
     mat `b' = e(b)
     local varlist : colnames `b'
     local varlist : subinstr local varlist "_cons" "", word count(local hascons)
     
	marksample touse
	if "`sample'" == "" { qui replace `touse' = 0 if !e(sample) }

					/* get time variables */
	_ts timevar, sort
	markout `touse' `timevar'

					/* fetch residuals */
	qui predict `res' if `touse' , res

	tsreport if `touse',  report
	return scalar N_gaps = r(N_gaps)
	return scalar N = e(N) - r(N_gaps)
	return scalar k = e(N) - e(df_r)
	
					/* regress resids on lagged resids to order `lags' and regressorlist */
	if !`hascons' { local cons "noconstant" }
	estimates hold `regest'
	qui regress `res' l(1/`lags').`res' `varlist', `cons'

	return scalar bg = e(N)*e(r2)
	return scalar df = `lags'
	return scalar p  = chiprob(`lags',return(bg))
	estimates unhold `regest'
	
	di in gr "Breusch-Godfrey LM statistic: "   /*
		*/ in ye %9.0g return(bg) in gr /* 
		*/ in gr "  Chi-sq(" %2.0f return(df)  ")  P-value = " in ye %6.0g return(p)
end
	
exit
