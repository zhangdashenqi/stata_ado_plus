* durbinh V1.01  C F Baum/Vince Wiggins 9820  (STB-55: sg136)
*! version 1.0.3  11jan1999
program define durbinh, rclass
	syntax [if] [in] [, noDetail noSample ] 
	version 6.0
	if "`e(cmd)'" ~= "regress" {
		error 301
	}
	
	 tempname b matt vcv res regest
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
	
					/* regress resids on lagged resids and regressorlist */
	if !`hascons' { local cons "noconstant" }
	estimates hold `regest'
	qui regress `res' l.`res' `varlist', `cons'

	mat `matt'=e(b)
	return scalar dh = `matt'[1,1]
	mat `vcv'=e(V)
	return scalar se = sqrt(`vcv'[1,1])
	return scalar t = return(dh)/return(se)
	return scalar p = tprob(e(df_r), return(t))
	return scalar df_r = e(df_r)
	return scalar df = 1
	estimates unhold `regest'
	
	di in gr "Durbin-Watson h-statistic: "   /*
		*/ in ye %9.0g return(dh) in gr /* 
		*/ in gr "  t = " in ye %9.0g return(t) "  P-value = " in ye %6.0g return(p)
end
	
exit
