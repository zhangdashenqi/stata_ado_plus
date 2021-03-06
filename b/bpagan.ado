* bpagan V1.0 cloned from bgtest.ado  C F Baum/Vince Wiggins 9919 (STB-55: sg137)

program define bpagan, rclass
	syntax varlist(ts min=1 numeric)  [if] [in]
	version 6.0
	if "`e(cmd)'" ~= "regress" {
		error 301
	}
    tempname res res2 ravg regest
     
	marksample touse
	if "`sample'" == "" { qui replace `touse' = 0 if !e(sample) }

					/* fetch residuals */
	qui predict `res' if `touse' , res
	qui gen `res2' = `res'*`res'
	summ `res2', meanonly
	qui gen `ravg' = 1.0/r(mean)*`res2'
	
					/* regress scaled squared residuals on regressorlist */
	estimates hold `regest'
	qui regress `ravg'  `varlist' if `touse'
	return scalar N = e(N)	
	return scalar bpagan = 0.5*e(mss)
	return scalar df = e(df_m)
	return scalar p  = chiprob(return(df),return(bpagan))
	estimates unhold `regest'
	
	di " "
	di in gr "Breusch-Pagan LM statistic: "   /*
		*/ in ye %9.0g return(bpagan) in gr /* 
		*/ in gr "  Chi-sq(" %2.0f in ye return(df)  /*
		*/ ")  P-value = " in ye %6.0g return(p)
	di " "
end
	
exit

