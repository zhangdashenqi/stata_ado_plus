/*********************************************************************************
** Stata Module rdlocrand
** Inference in Regression Discontinuity Designs under Local Randomization
** Authors: Matias D. Cattaneo, Rocio Titiunik and Gonzalo Vazquez-Bare
**********************************************************************************
** Command: rdwinselect (auxiliary command)
** Version: 0.01
** Last update: 18-Aug-2015
**********************************************************************************
** net install rdlocrand, from(http://www-personal.umich.edu/~cattaneo/software/rdlocrand/stata) replace
*********************************************************************************/
/* NOTES:
** score variable must be recentered at the cutoff
** before running this program:
preserve
keep if `inwindow' `if' `in'
******************************************************/

capture program drop rdwinselect_allcovs
program define rdwinselect_allcovs, rclass
	syntax varlist, treat(string) runvar(string) stat(string) [weights(string)]
	
	if "`weights'"!=""{
		local weight_opt "weights(`weights')"
	}
	
	local nvars: word count `varlist'
	local row = 1
	foreach var of varlist `varlist'{
		rdrandinf_model `var' `treat', stat(`stat') `weight_opt'
		return scalar stat_`row' = r(stat) 
		local ++row
	}
	
end
