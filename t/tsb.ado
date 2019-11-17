/* tsb.ado 
The wrapper ado file to wrap the Mata function, tsbmataX_X.mo, for implementing a 
 two-stage re-sampling routine proposed by Davison and Hinkley (1987). 
 Options are available for performing the routine with (default) or without 
 a shrinkage correction.

Author: Edmond S.-W. Ng, edmondngsw@googlemail.com
Date created: 8 Jul 2012 
*/
capture program drop tsb  
program define tsb, rclass 
	version 11.2 
	syntax varlist(min=1) [if] [in], STATS(string) CLUSTER(varname) /*
	*/ [ STRATA(varname) REPS(integer 1000) LAMBDA(string) NOSHRINK NODOTS UNBAL(string) /*
	*/ LEVEL(cilevel) SEED(string)] 
	
	/* set seed */
	if "`seed'"~="" set seed `seed' 
	
	/* Mark sample to use */
	marksample touse 
	markout `touse' `strata' , strok 
	preserve 
	quietly keep if `touse'
		
	/* Data checking if required 'options' have been specified */
	display _newline
	display as text "*** User-supplied settings ***"
	
	if "`cluster'"=="" {
		display as error "cluster() required"
		exit 198 
	}
	else {
		display as text "Cluster variable: "  as result "`cluster'"
	}
	if "`stats'"=="" {
		display as error "stats() required"
		exit 198 
	}
	else {
		display as text "Statistic (function): " as result "`stats'"
	}
	
	/* Prepare optional vars to form option string for 'tsbX_X.mo' */
	if "`strata'"=="" {
		tempvar strata
		gen `strata' = 1		
		local stratastr "strata(`strata')"  
		display as text "Strata variable: " as result " not supplied (assumed constant)"
	} 
	else {	
		local stratastr "strata(`strata')"  
		display as text "Strata variable: " as result "`strata'"
	}
	if "`unbal'"=="" {
		local unbalstr ""
	} 
	else {	
		local unbalstr "unbal(`unbal')"  
		display as text "Average cluster size: " as result "`unbal'"
	}

	if "`lambda'"=="" {
		local lambdastr ""
	} 
	else {	
		local lambdastr "lambda(`lambda')"  
		display as text "Lambda = " as result `lambda'
	}
	display _newline
		
		
	*** TSB routine begins *** 
	mata: tsb_sam=tsbmata1_0b(`stats',"`varlist'","`cluster'",`reps', " `stratastr' `lambdastr' `noshrink' `nodots' `unbalstr' " )

	mata: tsb_a=bcaa(`stats'," `varlist' `cluster' `strata' ",`lambda')  /* modified 1746,13Dec11 */
	*mata: tsb_a=bcaa(`stats'," `varlist' `cluster' `strata' ")  /* THIS LINE WORKED */
	
	mata: tsb_obsstat=(*`stats')(st_data(.,("`varlist' `cluster' `strata'")),`lambda') 

	* export Mata objects to Stata matrices 
	tempname tsb_obsstat tsb_a tsb_nobs
	mata: st_matrix("`tsb_obsstat'",tsb_obsstat)
	mata: st_matrix("`tsb_a'",tsb_a)
	mata: tsb_nobs=rows(st_data(.,"`varlist'"))
	mata: st_matrix("`tsb_nobs'",tsb_nobs)

	* Restore original sample 
	restore 
	
	* Preserve original data for calculating confidence intervals using 'bstat' *
	preserve 
	clear 
	
	local tsb_nobs=`tsb_nobs'[1,1]
	quietly set obs `reps'
	quietly gen bsam=. 
	mata: st_store(.,1,tsb_sam) 
	quietly save bsample, replace 
	quietly bstat using bsample, stat(`tsb_obsstat') accel(`tsb_a') n(`tsb_nobs') level(`level') 
	estat boot, all 

	mata: tsb_sam_mean=mean(tsb_sam)
	mata: st_matrix("tsb_sam_mean",tsb_sam_mean)
	mata: st_matrix("tsb_sam",tsb_sam)

	display as text " "
	display as text "Mean of TSB sample of statistic of interest = " 
	matrix list tsb_sam_mean, noblank noheader nonames 
	display _newline 
	
	/* clean up Mata workspace */
	capture mata: mata drop tsb_*

	/* return results */
	return matrix tsb_sam = tsb_sam

	restore 
end 
*************** End of 'tsb.ado' ****************
