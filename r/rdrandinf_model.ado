/*******************************************************

* Auxiliary program to permute statistics

*!version 0.01 12-Feb-2016

Authors: Matias Cattaneo, Rocio Titiunik, Gonzalo Vazquez-Bare

**** NOTES

* score variable must be recentered at the cutoff
* before running this program:

preserve
keep if `inwindow' `if' `in'

******************************************************/


capture program drop rdrandinf_model
program define rdrandinf_model, rclass

	syntax varlist (min=2 max=2) [if] [in], stat(string) [runvar(string) endogtr(string) asy weights(string)]

	tokenize `varlist'
	local outvar "`1'"
	local treatment "`2'"
	
	qui {
		if "`stat'"=="ttest"{
			if "`weights'"==""{
				ttest `outvar' `if' `in', by(`treatment')
				ret scalar stat = r(mu_2)-r(mu_1)
			}
			else {
				reg `outvar' `treatment' `if' `in' [aw=`weights'], vce(hc2)
				ret scalar stat = _b[`treatment']
			}
			if "`asy'"!=""{
				if "`weights'"!=""{
					local weight_opt "[aw=`weights']"
				}
				reg `outvar' `treatment' `if' `in' `weight_opt', vce(hc2)
				ret scalar asy_pval = 2*normal(-abs(_b[`treatment']/_se[`treatment']))
			}
		}
		
		if "`stat'"=="ksmirnov"{
			ksmirnov `outvar' `if' `in', by(`treatment') exact
			return scalar stat = r(D)
			ret scalar asy_pval = r(p_exact)
		}
		
		if "`stat'"=="ranksum"{
			ranksum `outvar' `if' `in', by(`treatment')
			return scalar stat = r(z)
			ret scalar asy_pval = 2*normal(-abs(r(z)))
		}
		
		if "`stat'"=="all"{
			ranksum `outvar' `if' `in', by(`treatment')
			ret scalar stat3 = r(z)
			ksmirnov `outvar' `if' `in', by(`treatment')
			return scalar stat2 = r(D)
			if "`weights'"==""{
				ttest `outvar' `if' `in', by(`treatment')
				ret scalar stat1 = r(mu_2)-r(mu_1)
			}
			else {
				reg `outvar' `treatment' `if' `in' [aw=`weights'], vce(hc2)
				ret scalar stat1 = _b[`treatment']
			}
		}
		
		if "`stat'"=="ar"{
			if "`weights'"==""{
				ttest `outvar' `if' `in', by(`treatment')
				ret scalar stat = r(mu_2)-r(mu_1)
			}
			else {
				reg `outvar' `treatment' `if' `in' [aw=`weights'], vce(hc2)
				ret scalar stat = _b[`treatment']
			}
		}
		
		if "`stat'"=="wald"{
			if "`weights'"==""{
				ivregress 2sls `outvar' (`endogtr'=`treatment')
			}
			else {
				ivregress 2sls `outvar' (`endogtr'=`treatment') [aw=`weights']
			}
			ret scalar stat = _b[`endogtr']
		}
		
		capture drop _runpoly_*
	
	}

end
