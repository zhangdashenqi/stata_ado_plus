
program define indirect, rclass
version 8.0 
syntax varlist(min=4 max=5)  , [ fixed random eform tabl trta(string) trtb(string) eff(string) ] 

quietly save tempFile_for_indirect1, replace

set more off
/*
 	 di "Starting program: "  
 	 di "metan data is |`data'|"	 
	 di "trials is |`trials'|"
	 di "Random or Fixed is |`rore'|"
	 di "effect is |`eff'|"
	 di "table is |`tabl'|"
	 di "eform is |`efrm'|"
	 di "treatment A is |`trta'"
	 di "treatment B is |`trtb'"
	 di "order variable is |`order'"
*/
tokenize "`varlist'"
local y `1'
if "`5'"!=""{
	local lci `2'
	local uci `3'
	local trials `4'
	local order `5'
	local data `y' `lci' `uci'
}
else{
	local se `2'
	local trials `3'
	local order `4'
	local data `y' `se'
}
if "`fixed'"!=""{
	local rore "fixed"
}
else{
	local rore "random"
}
if "`tabl'"==""{
	local tabl "notable"
}
if "`eff'"!=""{
	local eff "`eff'"
}
if "`eform'"!=""{
	local efrm "eform"
}
local display_precision = 10^(-3)
qui sum `order'
local from_ord = r(min)
local to_ord = r(max)

/* di "metan overall:" */

/* performing the inital meta-analysis */
qui drop if `order' != 0
metan `data', `rore' nograph label(namevar=`trials') effect(`eff') `tabl' `efrm'

local stat0 = $S_1
local SE0 = $S_2
local SE_exp0 = (exp($S_4) - exp($S_3))/(2*1.96)
if "`efrm'" == "eform" {
   local stat0 = log($S_1)
   local SE_exp0 = $S_2
   local SE0 = (log($S_4) - log($S_3)) / (2*1.96)
   }
local var0 = `SE0'^2
local trtA0 = `trta'[1]
local trtB0 = `trtb'[1]

di in white "Meta-Analysis: comparing treatments  `trtA0'  and  `trtB0'"
di in white "Exponential Statistic `eff' = " round(exp(`stat0'),`display_precision')
di in white "Log statistic ln(`eff') = " round(`stat0',`display_precision') ///
              " and standard error = " round(`SE0',`display_precision') ///
              "(var = " round(`var0',`display_precision') ")"
local w0 = 1/`var0'

/* -----------------------------------------------------------------
   Loop - do the meta-analysis and the indirect comparison	*/

local i
forvalues i = 1/`to_ord' {
	use tempFile_for_indirect1, clear
	qui drop if `order' != `i'			 
	/*-------------------------------------------------------*/
	/*        first metanalaysis of the second group         */
	metan `data', `rore' nograph label(namevar=`trials') effect(`eff') `tabl' `efrm'

	local stat1 = $S_1
	local SE1 = $S_2
	local SE_exp1 = (exp($S_4) - exp($S_3))/(2*1.96)
	if "`efrm'" == "eform" {
	   local stat1 = log($S_1)
	   local SE_exp1 = $S_2
	   local SE1 = (log($S_4) - log($S_3)) / (2*1.96)
	   }
	local var1 = `SE1'^2
	local trtA1 = `trta'[1]
	local trtB1 = `trtb'[1]
	di in white "-----------------------------------------"	
	di in white "Meta-Analysis: comparing treatments `trtA1'  and  `trtB1'"
	di in white "Exponential Statistic `eff'= " round(exp(`stat1'),`display_precision')
	di in white "Log statistic ln(`eff') = " round(`stat1',`display_precision') ///
        	      " and standard error = " round(`SE1',`display_precision') ///
	              " (var = " round(`var1',`display_precision') ")"
		local w1 = 1/`var1'
	/*---------------------------------------------------------*/
	/*             Indirect Comparison                         */
	di in white "-----------------------------------------"
	di in white "-----------------------------------------"
	di in white "Indirect comparison: `trtA0' vs `trtA1'"
	if "`trtB0'" != "`trtB1'" {
		di in white "PROBLEM PROBLEM PROBLEM PROBLEM PROBLEM"
		di in white "The second treatments `trtB0' and `trtB1' do not match"
		}
	local var0 = `var0' + `var1'
	local SE0 = sqrt(`var0')
	local stat0 = `stat0' - `stat1'
	local trtB0 = "`trtA1'"
	local ll_exp = round(exp(`stat0' - 1.96*`SE0'),`display_precision')
	local ul_exp = round(exp(`stat0' + 1.96*`SE0'),`display_precision')
	di in white "Exponential Statistic `eff' =" round(exp(`stat0'),`display_precision') ///
	   " with CI [ " round(`ll_exp',`display_precision') ///
	            ", " round(`ul_exp',`display_precision') "] "
	di in white "Log statistic ln(`eff') = " round(`stat0',`display_precision') ///
        	      " and standard error =  " round(`SE0',`display_precision') ///
	              " (var = " round(`var0',`display_precision') ")"
	local ll = round(`stat0' - 1.96*`SE0',`display_precision')
	local ul = round(`stat0' + 1.96*`SE0',`display_precision')
	di in white "Confidence Interval: ["		     ///
		     round(`ll',`display_precision') ///
		", " round(`ul',`display_precision') "] "
	  		
	local Chisq_B = ((`stat0')*(`stat0') * `w0' * `w1')/(`w0'+`w1')
	local pChisq = round( chi2tail(1,`Chisq_B'),`display_precision') 
	local Chisq_B = round( `Chisq_B' ,`display_precision') 

	di in white "Heterogeneity statistic ChiSquared: =" ///
		 `Chisq_B' %4.3f ", p-value: = " `pChisq'  %4.3f

	/* prepare the 0-variables for the next cycle	*/
	local w0 = 1/`var0'

}

  use tempFile_for_indirect1, clear

end
