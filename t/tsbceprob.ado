/* tsbceprob.ado 
The wrapper ado file to wrap the Mata function, tsbmataX_X.mo, for implementing a 
 two-stage re-sampling routine proposed by Davison and Hinkley (1987). 
 Options are available for performing the routine with (default) or without 
 a shrinkage correction.

Author: Edmond S.-W. Ng, edmondngsw@googlemail.com
Date created: 8 Jul 2012 
*/
capture program drop tsbceprob    
program define tsbceprob, rclass     
	version 11.2 
	syntax varlist(min=1) [if] [in], STATS(string) CLUSTER(varname) /*
	*/ [ STRATA(varname) REPS(integer 1000) LAMBDA(string) NOSHRINK NODOTS /* 
	*/ UNBAL(string) LEVEL(cilevel) SEED(string)] 
	 	
	/* for test script 
	st_view(data1=.,.,"tmcost1 qalygain cluster tx")
	cost=data1[,1]
	effect=data1[,2]
	cluster=data1[,3]
	treat=data1[,4]
	*/
	
	/* set seed */
	if "`seed'"~="" set seed `seed'
	
	* Mark sample to use *
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
	mata: tsb_sam=tsbmata1_0b(`stats',"`varlist'","`cluster'",`reps', " `stratastr' `lambdastr' `noshrink' `nodots' "  )

	* Restore original sample 
	restore 

	*** calc cost-effectiveness probabilities *** 
	mata: tsb_sam=(tsb_sam:==rowmax(tsb_sam))  /* indicator for highest NB value per row */
	mata: tsb_sam=tsb_sam:/rowsum(tsb_sam) /* accounting for potential ties */ 
	/*mata: tsb_sam */
	mata: tsb_ceprob=mean(tsb_sam)	/* calc CE probabilities (for different tx)  over the replications */
	
	tempname tsb_ceprob
	mata: st_matrix("`tsb_ceprob'",(tsb_ceprob,`lambda')) /* export CE probabilities and lambda value 
													used to a matrix in Stata for later use */  	
	display _newline
	display as text "Cost-effective probabilities and WTP value"
	matrix list `tsb_ceprob', noblank noheader nonames  /* display CE prob */
	display _newline 
	return matrix tsb_ceprob = `tsb_ceprob' 
	
	/* clear up Mata obects */
	capture mata: mata drop tsb_*
end 
*************** End of 'tsbceprob.ado' ****************
