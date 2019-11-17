*!Omar M.G. Keshk        orginial (SJ3-2: st0038)
* Revised October 2004 
* Version 2.1
* This version enables users to use most postestimation commands available in Stata 


program define cdsimeq, eclass
version 7.0
set more off
syntax varlist [if] [in] [, NOFirst NOSecond asis INStpre ESTimates_hold ]  

marksample touse 

if `"`asis'"'~= `""'{
	local asis = "asis"
	}

local ny = "in y"   
local nr = "in r"

	*  parse the equations in order to obtain exogenous
	
gettoken equ1 equ2 : 0, parse (" ) ") match(paren)          
/* taken from reg3 */

gettoken equ2 options: equ2 , parse (" ( ") match(paren)

Xtractequ1 `equ1'
Xtractequ2 `equ2'


	* establish that dichotomous variable is really dichotomous
		 capture tab `dichotomous_depvar'
		 	local rc = _rc
		 	if `rc' ~= 0{
		 		display `nr' "Dichotomous variable may have more than two unique values."
		 	}
		 	else{
		 	if (r(r))~= 2{
		 		display `nr' "Dichotomous variable has more than two unique values."
		 		exit
		 	}
		 		
* put all ivvar in one place 
local all_ivvar `continous_ivvar' `dichotomous_ivvar'


* get rid of duplicate ivs so that exogenous list does not
Getexoglist  "`all_ivvar'"
local exogenous_list `list'

	local continous_ivvar_count: word count `continous_ivvar'
	local dichotomous_ivvar_count: word count `dichotomous_ivvar'
	local number_of_exogenous: word count `exogenous_list'
	global number_of_exogenous = `number_of_exogenous' + 1 /* adding the constant */

tempvar samp1 samp2
qui gen `samp1' = `touse'  /* new */
qui gen `samp2' = `touse'  /* new  */

if `"`nofirst'"' == `""'{
	display _newline(1)
	display `ny' _col(25) "NOW THE FIRST STAGE REGRESSIONS" 
	}

	*creating continous instrument
	if "`nofirst'" ~= ""{
		qui regress `continous_depvar' `exogenous_list' if `touse'  
		}
		else{
		regress `continous_depvar' `exogenous_list' if `touse' 
		}
	if e(df_m) ~= `number_of_exogenous'{
			display _newline (2)
			display `nr' _col(10) "Variable(s) have been dropped during the OLS estimation.
			display `nr' _col(20)  "This is probably due to collinearity."
			display `nr' _col(14) "CHECK IDENTIFICATION (I.E., EXCLUSION CRITERIA)"
			display `nr' _col(24) "Estimation cannot continue."
			qui capture drop I_`continous_depvar' I_`dichotomous_depvar' 
			exit 
		}
			
	/*get  matrix of cofficients from first stage continous variable equation */
	matrix pie_1 = e(b) 
	
	/* get predict continous instrument */
	
	qui predict double I_`continous_depvar' if `touse'  
	qui label var I_`continous_depvar' "Continous predicted variable from first stage OLS" 

	/* get residuals for use in sigmma12,  in Amemiya 1978 (1200) this is v1_t */
	tempvar v1_t  
	qui predict double `v1_t' if `touse' , resid   
	qui label var `v1_t' "Residuals from first stage OLS squared"

	/* generate sigmma11 (i.e., the residual sum of squares divided by degrees of freedom 
	   for calculation of c & d */
	  
	qui scalar sigma_11 = e(rss)/e(df_r)
	estimates scalar sigma_11 = sigma_11
	qui scalar F = `e(F)'
	estimates scalar F = e(F)
	qui scalar r2 = e(r2)
	estimates scalar r2 = e(r2)
	qui scalar adj_r = e(r2_a)
	estimates scalar adj_r = e(r2_a)
	
	
	*creating dichotomous instrument
	if `"`nofirst'"' ~= ""{
		qui probit `dichotomous_depvar' `exogenous_list' if `touse'  , `asis' 
		}
		else{
		probit `dichotomous_depvar' `exogenous_list' if `touse'  , `asis'
		}
	if e(df_m) ~= `number_of_exogenous' /*& "`cluster'"== ""*/{
			display _newline (2)
			display `nr' _col(10) "Variable(s) have been dropped during the Probit estimation.
			display `nr' _col(20)  "This is probably due to collinearity."
			display `nr' _col(14) "CHECK IDENTIFICATION (I.E., EXCLUSION CRITERIA)"
			display `nr' _col(24) "Estimation cannot continue."
			qui capture drop I_`continous_depvar' I_`dichotomous_depvar' 
			exit 
		}


		
	/* get matrix of coefficients */
	matrix define pie_2 = e(b)
	matrix V_o = e(V)  /* that is a  an oh */
	qui predict double I_`dichotomous_depvar'  if `touse' , xb   /* dichotomous linear perdictor */
	qui label var I_`dichotomous_depvar' "Dichotomous first stage instrumental variable. Linear Index used not probabilities."
	tempvar pie_2_hat_f
	qui gen double `pie_2_hat_f' = normd(I_`dichotomous_depvar')
	qui label var `pie_2_hat_f' "This is the dichotomous linear predictor evaluated using normd, the standard density"
	local total = e(N)   
	estimates scalar Probit_N = `total' 
	

	
	tempvar a_sigma_12
	qui gen double `a_sigma_12' = (`dichotomous_depvar'*`v1_t')/ `pie_2_hat_f'
	qui summarize `a_sigma_12'
	scalar sum_sigma_12_a =r(sum)
	estimates scalar sum_sigma_12_a = sum_sigma_12_a
	/*drop sigma_12_a */
	scalar sigma_12 = sum_sigma_12_a/`total'       
	estimates scalar sigma_12 = sigma_12
	qui scalar chi2=e(chi2)
	estimates scalar chi2=chi2
	qui scalar r2_p= e(r2_p)
	estimates scalar r2_p=r2_p
	
* Now running the second stage with the instruments 

/* Now Second Stage */
	*continous model
	if `"`nosecond'"' ~= `""'{
		qui regress `continous_depvar' I_`dichotomous_depvar' `continous_ivvar' if `touse' 
		}
		else{
		display _newline(2)
		display `ny' _col(15) "NOW THE SECOND STAGE REGRESSIONS WITH INSTRUMENTS" 
		display _newline(2)
		regress `continous_depvar' I_`dichotomous_depvar' `continous_ivvar'  if `touse' 
		}
	if e(df_m) ~= (`continous_ivvar_count'+1){  /* plus one for instrument */
			display _newline (2)
			display `nr' _col(10) "Variable(s) have been dropped during the OLS estimation.
			display `nr' _col(20)  "This is probably due to collinearity."
			display `nr' _col(14) "CHECK IDENTIFICATION (I.E., EXCLUSION CRITERIA)"
			display `nr' _col(24) "Estimation cannot continue."
			qui capture drop I_`continous_depvar' I_`dichotomous_depvar' 
			exit 
		}
	matrix alpha_1 = e(b)    /* coefficient matrix for continous second stage */
	scalar gamma_1 = _b[I_`dichotomous_depvar']
	scalar gamma_1_sq = (gamma_1)^2
	local ols_df = e(df_r)
	local ols_dm = e(df_m)
	local ols_nobs = e(N)

	* dichotomous model
	if `"`nosecond'"' ~= `""'{
		qui probit `dichotomous_depvar' I_`continous_depvar' `dichotomous_ivvar' if `touse', `asis'
		}
		else{
		probit `dichotomous_depvar' I_`continous_depvar' `dichotomous_ivvar' if `touse' , `asis'
		}
	if e(df_m) ~= (`dichotomous_ivvar_count'+1 ){  
			display _newline(2)
			display `nr' _col(10) "Variable(s) have been dropped during the Probit estimation.
			display `nr' _col(20)  "This is probably due to collinearity."
			display `nr' _col(14) "CHECK IDENTIFICATION (I.E., EXCLUSION CRITERIA)"
			display `nr' _col(24) "Estimation cannot continue."
			qui capture drop I_`continous_depvar' I_`dichotomous_depvar' 
			exit 
		}
	matrix alpha_2 = e(b)
	scalar gamma_2 = _b[I_`continous_depvar']
	scalar gamma_2_sq = (gamma_2)^2
	local pr_df = e(df_m)
	local pr_nobs = e(N)


*Now getting scalars that are used in the correction of the variance covariance matrix for the second stage estimations


scalar MA_c = (sigma_11-((2*gamma_1)*(sigma_12)))
estimates scalar MA_c = MA_c

scalar MA_d = ((gamma_2_sq)*(sigma_11)-((2*gamma_2))*(sigma_12))
estimates scalar MA_d = MA_d



*Now generating the J1 and J2 matrix's for the correction of the second stage variance-covariance matrix


	
	* generate a matrix(1,number_of_exogenous) to hold exogenous names 
	matrix exogenous_list = J(1,`number_of_exogenous',1)
	matrix colnames exogenous_list = `exogenous_list'  /* now matrix contains names and position */
	
	global continous_ivvar_count = (`continous_ivvar_count'+1)  /* plus one for the constant */
	matrix continous_ivvar = J(1, `continous_ivvar_count', 1)   /* matrix to get names and position of ivar in second stage continous */
	matrix colnames continous_ivvar = `continous_ivvar'
	local continous_ivvar_names: colfullnames continous_ivvar /* put the names in a macro */
	
	global dichotomous_ivvar_count = (`dichotomous_ivvar_count'+1)  /* plus one for the constant */
	matrix dichotomous_ivvar = J(1, `dichotomous_ivvar_count', 1)   /* matrix to get names and position of ivar in second stage continous */
	matrix colnames dichotomous_ivvar = `dichotomous_ivvar'
	local dichotomous_ivvar_names: colfullnames dichotomous_ivvar /* put the names in a macro */
	
	*Now matrix J1
	matrix J1 = J($number_of_exogenous,$continous_ivvar_count,0) /*J matrix rows equal to exogenous and columns equal to ivvar in 2nd stage */
	matrix J1[$number_of_exogenous,$continous_ivvar_count]=1     /* for constant, in stata it is always last */

*Now the loop 
	local exogcntr = 1   /* counter for exogneous list */
	local exogenous_names: colfullnames exogenous_list /* gets names of exogenous in macro */
	local exogenous_names_loop: word 1 of `exogenous_names'  /* stata command for looping through a names list */
	while (`exogcntr' < $number_of_exogenous){   
		while ("`exogenous_names_loop'")~=""{
			local exogenous_token = `"`exogenous_names_loop'"' /*holds the first token in exogenous list */
			local exogenous_token_col_pos =colnumb(exogenous_list, "`exogenous_token'") 
			local sec_stage_continous_cntr = 1     /* second stage continous counter */
			if `sec_stage_continous_cntr' <= `continous_ivvar_count'{  
				tokenize `continous_ivvar' /* tokenize contnious ivvar list */
				while ("`1'"~=""){
					local continous_token = `"`1'"' /* continous token */
					local continous_token_col_pos = colnumb(continous_ivvar, "`continous_token'") /* col position of token */
					if "`exogenous_token'"=="`continous_token'"{
						matrix J1[`exogenous_token_col_pos',`continous_token_col_pos'] = 1 
						local sec_stage_continous_cntr = `continous_ivvar_count' + 1      
						/* if match get out of the 
						   comparing loop immediately */
						} 
						else  
						local sec_stage_continous_cntr = `sec_stage_continous_cntr' + 1 
						macro shift
						}
				local exogcntr = `exogcntr' + 1
				local exogenous_names_loop: word `exogcntr' of `exogenous_names'
				}
	}





	*Now matrix J2
	matrix J2 = J($number_of_exogenous,$dichotomous_ivvar_count,0) /*J matrix rows equal to exogenous and columns equal to ivvar in 2nd stage */
	matrix J2[$number_of_exogenous,$dichotomous_ivvar_count]=1     /* for constant, in stata it is always last */
	*Now the loop 
	local exogcntr = 1   /* counter for exogneous list */
	local exogenous_names: colfullnames exogenous_list /* gets names of exogenous in macro */
	local exogenous_names_loop: word 1 of `exogenous_names'  /* stata command for looping through a names list */
	while (`exogcntr' < $number_of_exogenous){   
		while ("`exogenous_names_loop'")~=""{
			local exogenous_token = `"`exogenous_names_loop'"' /*holds the first token in exogenous list */
			local exogenous_token_col_pos =colnumb(exogenous_list, "`exogenous_token'") 
			local sec_stage_dichotomous_cntr = 1     /* second stage dichotomous counter */
			if `sec_stage_dichotomous_cntr' <= `dichotomous_ivvar_count'{
				tokenize `dichotomous_ivvar' /* tokenize dichotomous ivvar list */]
				while ("`1'"~=""){
					local dichotomous_token = `"`1'"' /* dichotomous token */
					local dichotomous_token_col_pos = colnumb(dichotomous_ivvar, "`dichotomous_token'") /* col position of token */
					if "`exogenous_token'"=="`dichotomous_token'"{
						matrix J2[`exogenous_token_col_pos',`dichotomous_token_col_pos'] = 1 
						local sec_stage_dichotomous_cntr = `dichotomous_ivvar_count' + 1       
						/* if match get out of the 
						   comparing loop immediately */
						} 
						else
						local sec_stage_dichotomous_cntr = `sec_stage_dichotomous_cntr' + 1 
						macro shift
						}
				local exogcntr = `exogcntr' + 1
				local exogenous_names_loop: word `exogcntr' of `exogenous_names'
				}
	}


display _newline(1)
display `ny' _col(10) "NOW THE SECOND STAGE REGRESSIONS WITH CORRECTED STANDARD ERRORS"
display _newline(1)

* Now the corrections following Maddla (1983: 244-245)

	*set up pie_1 and pie_2
	matrix pie_1t = pie_1'
	matrix pie_2t = pie_2'
	* create H and G
	tempname H HT G GT XTX XTXinv
	matrix `H' = pie_2t,J1 /* appends J1 to pie */
	matrix `HT' = `H''
	matrix `G' = pie_1t,J2
	matrix `GT' = `G''
	*get the X'X, where X is the matrix with all exogenous and XTXinv, i.e., the inverse
	qui matrix accum `XTX' = `exogenous_list'  if `touse'  
	matrix `XTXinv' =inv(`XTX')
	*now the variance covariance matrix of alpha_1, i.e., contionous second stage
	tempname a   /* HTXTX */
	tempname b   /* HTXTXH */
	tempname c   /* HTXTXHinv */
	tempname d   /* CHTXTXHinv */
	tempname e   /* GAMMAHTXTXHinv*/
	tempname f   /* XTXH*/
	tempname V_o /* V_o i.e., probit variance covariance matrix from first stage probit */
	tempname g   /* HTXTXV_o */
	tempname i   /* HTXTXV_oXTXH */
	tempname j   /* GAMMAHTXTXHinvHTXTXV_oXTXH */
	tempname k   /* GAMMAHTXTXHinvHTXTXV_oXTXHHTXTXHinv */
	tempname alpha1_vce /* CHTXTXHinv + GAMMAHTXTXHinvHTXTXV_oXTXHHTXTXHinv */	 
	matrix define `V_o'= V_o
	matrix `a'= `HT' * `XTX'
	matrix `b' = `a' * `H'
	matrix `c' = syminv(`b')
	matrix `d' = MA_c * `c' 
	matrix `e' = gamma_1_sq * `c'   /* no sigma_22 because it is normalized to one in probit */
	matrix `f' = `XTX' * `H'
	matrix `g' = `a' * `V_o'  
	matrix `i' = `g' * `f'
	matrix `j' = `e' * `i'
	matrix `k' = `j' * `c'
	matrix `alpha1_vce'  = `d'+ `k'
	matrix rownames `alpha1_vce' = I_`dichotomous_depvar' `continous_ivvar' _cons
	matrix colnames `alpha1_vce' = I_`dichotomous_depvar' `continous_ivvar' _cons
	estimates post alpha_1 `alpha1_vce', depname (`continous_depvar') dof(`ols_df') esample(`samp1') /* esample new*/
	estimates scalar sigma_11 = sigma_11
	estimates scalar sigma_12 = sigma_12	
	estimates scalar gamma_1 = gamma_1
	estimates scalar gamma_1_sq = gamma_1_sq
	estimates scalar MA_c = MA_c
	estimates scalar F = F
	estimates scalar r2 = r2
	estimates scalar adj_r = adj_r
	estimates scalar df_r = `ols_df'  
	estimates scalar N = `ols_nobs'
	estimates scalar df_m = `ols_dm'
	estimates local depvar = "`continous_depvar'"
	estimates local cmd = "regress" 
	estimates local model = "ols"
	estimates display
	
		if `"`estimates_hold'"' ~= `""'{
			estimates hold model_1
			}
			

	
	
	*Variance covariance matrix for alpha_2, i.e., dichotomous second stage
	tempname aa	/* V_oinv*/
	tempname bb	/* GTV_oinv */
	tempname cc	/* GTV_oinvG */
	tempname dd	/* GTV_oinvGinv */
	tempname ee	/* DGTV_oinvGinv */
	tempname ff	/* V_oinvG */
	tempname gg	/* XTXinvV_oinvG */
	tempname hh	/* GTV_oinvXTXinvV_oinvG */
	tempname ii     /* GTV_oinvXTXinvV_oinvG*GTV_oinvGinv */
	tempname jj     /* DGTV_oinvGinvGTV_oinvXTXinvV_oinvGGTV_oinvGinv */
	tempname alpha2_vce  /*GTV_oinvGinv + DGTV_oinvGinvGTV_oinvXTXinvV_oinvGGTV_oinvGinv */
	matrix `aa' = syminv(`V_o')
	matrix `bb' = `GT'*`aa'
	matrix `cc' = `bb'*`G'
	matrix `dd' = syminv(`cc')
	matrix `ee' = MA_d *`dd'
	matrix `ff' = `aa'*`G'
	matrix `gg' =`XTXinv'*`ff'
	matrix `hh' = `bb'*`gg'
	matrix `ii' = `hh'*`dd' 
	matrix `jj' =  `ee'*`ii'
	matrix `alpha2_vce' = `dd'+`jj'
	matrix rownames `alpha2_vce' = I_`continous_depvar' `dichotomous_ivvar' _cons
	matrix colnames `alpha2_vce' = I_`continous_depvar' `dichotomous_ivvar' _cons
	estimates post alpha_2 `alpha2_vce', depname (`dichotomous_depvar') esample(`samp2') 
	estimates scalar sigma_11 = sigma_11
	estimates scalar sigma_12 = sigma_12
	estimates scalar gamma_2 = gamma_2
	estimates scalar gamma_2_sq = gamma_2_sq
	estimates scalar MA_d = MA_d
	estimates scalar chi2=chi2
	estimates scalar r2_p=r2_p
	estimates scalar df_m = `pr_df'   
	estimates scalar N = `pr_nobs'
	estimates local depvar = "`dichotomous_depvar'"
	estimates local cmd = "probit" 

	estimates display
		if `"`estimates_hold'"' ~= `""'{
				estimates hold model_2
			}
			
		if `"`estimates_hold'"' ==`""'{		
		estimates clear
		estimates scalar sigma_11 = sigma_11
		estimates scalar sigma_12 = sigma_12
		estimates scalar gamma_2 = gamma_2
		estimates scalar gamma_2_sq = gamma_2_sq
		estimates scalar MA_c = MA_c
		estimates scalar MA_d = MA_d
		estimates scalar F = F
		estimates scalar r2 = r2
		estimates scalar adj_r = adj_r
		estimates scalar chi2=chi2
		estimates scalar r2_p=r2_p
		}
	


* cleanup or ask if they want to prserve the variables created. 



	if `"`instpre'"'==`""' {
		if  "`estimates_hold'" == ""{
		qui drop I_`continous_depvar' I_`dichotomous_depvar' 
		}



end	/* have to put an end so that program Xtract will be called */
	
	program define Xtractequ1
	syntax varlist
	gettoken continous_depvar continous_ivvar: varlist
	c_local continous_depvar "`continous_depvar'"   	
	c_local  continous_ivvar  "`continous_ivvar'"
	
end /* end for extractequ1*/

	program define Xtractequ2
	syntax varlist
	gettoken dichotomous_depvar dichotomous_ivvar: varlist
	c_local dichotomous_depvar "`dichotomous_depvar'"
	c_local dichotomous_ivvar "`dichotomous_ivvar'"
	
end /* end for extractequ2*/


program define Getexoglist         /* Taken from N.J. Cox's uniqlist.ado program*/
args varlist
tokenize `varlist'
local newlist "`1'"
mac shift
while "`1'" != ""{
	local list_count: word count `newlist'
	local i = 1
	local putin = 1
	while `i'<=`list_count'{
		local word: word `i' of `newlist'
		if "`word'" == "`1'"{
			local putin = 0
			local i = `list_count'
			}
		local i = `i' + 1
		}
	if `putin' != 0{
	local newlist "`newlist'  `1'"
	}
mac shift
}
c_local list "`newlist'"
end /* for Getexoglist */





