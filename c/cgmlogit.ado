*!Version 2.3.0 5Feb07 (By Jonah B. Gelbach)
*!Version 2.2.0 24Jan07 (By Jonah B. Gelbach)
*!Version 2.1.0 19Sep06 (By Jonah B. Gelbach)
*!Version 2.0.1 	(By Douglas L. Miller)
*!Version 2.0.0 22May06 (By Jonah B. Gelbach)
*!Version 1.0.1 22May06 (By Jonah B. Gelbach)
*!Version 1.0.0 28Mar06 (By Jonah B. Gelbach)
*! 9Feb09 (By Judson Caskey - Change to logit)

*************
* CHANGELOG *
*************

* 2.3.0: medium edit by JBG to 
*
*		## add treatment of if & in conditions
*		## add treatment of weights
*	
*        (required edit of syntax of to sub_robust subroutine, as well as adding some code on main regress line)
*
*
* 2.2.0: medium edit by JBG to make sure that "robust" option doesn't get passed to regress for line where we obtain (X'X)^(-1) using mse1 option.
*	 (comment: this seems like a stata bug to me -- why should stata allow you to use the robust option when the whole point is to get (X'X)^(-1)????
*
* 2.1.0: medium edit by JBG to move from use of -tab- to -unique- (I just dumped in the text of unique.ado to address this locally)
*
* 2.0.1: minor edit by Doug to unabbreviate "pred"
*
* 2.0.0: major addition: command now handles arbitrary number of grouping vars
*	 		 also, we now use cgmreg to calculate manually when only one clustering variable is used.
*			       this feature helps show that the sub_robust routine is correct

* 1.0.1: corrected error in 1.0.0:
*	I forgot to subtract out the estimate with cluster(bothvars) when `numcvars'==2


*********************
* SCHEMATIC OF CODE *
*********************

/*

	1. Run the regression, with mse1 option (this option sets robust off and variance=1, so that resulting "cov" matrix is (X'X)^-1)

	2. Save some matrices, scalars, and macros from the ereturned regress output

	3. Generate predicted residuals

	4. Set up a giant matrix that has

		* one column for every clustering variable
		* [(2^K) - 1] rows, where K is the number of clustering variables
		* elements equal to either 0 or 1

	   Each row of this matrix corresponds to one subcase, so that it provides a list of clustering vars for which we will calculate the middle matrix.

	   We then add or subtract the middle matrices according to the inclusion/exclusion rule: 

		* when the number of included clustering vars is odd, we add
		* when the number of included clustering vars is even, we subtract

	5. We then iterate over the rows of this matrix, using egen, group() and the list of included clustering variables 
	   to create a grouped var indicating an observation's membership category according to this group

	6. We then use the sub_robust subroutine (which uses _robust) to calculate the appropriate part of the covariance matrix

	7. The resulting part of the covariance matrix is added/subtracted to the matrix `running_mat', as given by the inc/exc rule

	8. The header in the stata output tells us

				Number of obs		[Total number of included observations]
				Num clusvars 		[Number of clustering vars, i.e., dimensions]
				Num combinations	[Total number of possible combinations of the clusvars, i.e., 2^K-1]

	   Followed by a list of the number of distinct categories in each clustering variable.

	9. Then the regression output appears, and we are done.

*/


program define cgmlogit, eclass byable(onecall) sortpreserve

	syntax anything [if] [in] [aweight fweight iweight pweight /], Cluster(string) [*]


	tempname b b2 bT running_sum Bigmat element elementM groupvar rows cols chi2 depname e_df_m e_p numcvars numvars S numsubs e_r2_p c n ///
		e_ll_0 e_ll e_N_cdf e_N_cds
	tempvar regvar clusvar

	marksample touse
	qui egen `regvar'=rowmiss(`anything')
	qui egen `clusvar'=rowmiss(`cluster')
	qui replace `touse'=(`touse' & `regvar'==0 & `clusvar'==0)

	local `numcvars' : word count `cluster'
	local `numvars' : word count `anything'
	if regexm("`options'","noconstant") == 1 local `numvars'=``numvars''-1

	di
	while ( regexm("`options'","robust")==1 ) {

		di " -> Removing string 'robust' from your options line: it's unnecessary as an option,"
		di "    but it can cause problems if we leave it in."
		di "    If some variable in your options list contains the string 'robust', you will"
		di "    have to rename it."
		di 
		local options = regexr("`options'", "robust", "")

	} 

	/* deal with weights */
	if "`weight'"~="" {
		local weight "[`weight'=`exp']"
	} 
	else {
		local weight ""
	}

	/* main regression */
	di in green "Note: +/- means the corresponding matrix is added/subtracted"
	di

	/* matrix that holds the running sum of covariance matrices as we go through clustering subsets */
	mat `running_sum' = J(``numvars'',``numvars'',0)

	/* we will use a_cluster for matrix naming below as our trick to enumerate all clustering combinations */
	mat `Bigmat' = J(1,1,1)

	*taking inductive approach
	forvalues a=2/``numcvars'' { /* inductive loop for Bigmat */

		mat `Bigmat' = J(1,`a',0) \ ( J(2^(`a'-1)-1,1,1) , `Bigmat' ) \ (J(2^(`a'-1)-1,1,0) , `Bigmat' ) 
		mat `Bigmat'[1,1] = 1

	} /* end inductive loop for Bigmat */

	mat colnames `Bigmat' = `cluster'

	local `numsubs' = 2^``numcvars'' - 1
	local `S' = ``numsubs'' 			/* for convenience below */

	forvalues s=1/``S'' { /* loop over rows of `Bigmat' */

		{	/* initializing */
			local included=0
			local grouplist
		} /* done initializing */

		foreach clusvar in `cluster' { /* checking whether each `clusvar' is included in row `s' of `Bigmat' */

			mat `elementM' = `Bigmat'[`s',"`clusvar'"] 
			local `element' = `elementM'[1,1]


			if ``element'' == 1 { /* add `clusvar' to grouplist if it's included in row `s' of `Bigmat' */

				local included= `included' + 1
				local grouplist "`grouplist' `clusvar'"

			} /* end add `clusvar' to grouplist if it's included in row `s' of `Bigmat' */
		} /* checking whether each `clusvar' is included in row `s' of `Bigmat' */


		*now we use egen to create the var that groups observations by the clusvars in `grouplist'
		qui egen `groupvar' = group(`grouplist') if `touse'

		*now we get the robust estimate
		local plusminus "+"
		if mod(`included',2)==0 { /* even number */
			local plusminus "-"
		} /* end even number */

                sub_robust `if' `in' `weight', groupvar(`groupvar') varlist(`anything') plusminus(`plusminus') running_sum(`running_sum') touse(`touse') options(`options')
	
		di "Calculating cov part for variables: `grouplist' (`plusminus')"

		drop `groupvar'

	} /* end loop over rows of `Bigmat' */
	

	mat `b' = e(b)
	if regexm("`options'","noconstant") == 0 mat `bT'=[I(colsof(`b')-1),J(colsof(`b')-1,1,0)]
	else mat `bT'=[I(colsof(`b'))]

	local `depname' = e(depvar)

	scalar `n'			= e(N)
	scalar `e_ll_0'		= e(ll_0)
	scalar `e_ll'		= e(ll)
	scalar `e_df_m'		= e(df_m)
	scalar `e_r2_p'		= e(r2_p)
	scalar `e_N_cdf'		= e(N_cdf)
	scalar `e_N_cds'		= e(N_cds)

	* Compute chi2 statistic

	matrix `chi2'=`b'*`bT''*inv(`bT'*`running_sum'*`bT'')*`bT'*`b''
	scalar `e_p'		= chi2tail(`e_df_m',`chi2'[1,1])

	/* final cleanup and post */

	dis " "
	dis in green "Logit with clustered SEs" ///
		_column (50) "Number of obs" _column(69) "=" _column(71) %8.0f in yellow `n'
	dis in green _column(50) "Wald chi2(" in yellow `e_df_m' in green ")" _column(69) "=" _column(71) %8.2f in yellow `chi2'[1,1]
	dis in green "Number of clustvars" _column(20) "=" _column(21) %5.0f in yellow ``numcvars'' ///
          in green _column(50) "Prob > chi2" _column(69) "=" _column(71)  %8.4f in yellow `e_p'
   	dis in green "Num cobminations" _column(20) "=" _column(21) %5.0f in yellow ``S'' ///
	    in green _column(50) "Pseudo R2" _column(69) "=" _column(71) %8.4f in yellow `e_r2_p'
	if "`if'"~="" di in green _column(50) "If condition" _column(69) "= `if'"
	if "`in'"~="" di in green _column(50)     "In condition" _column(69) "= `in'"
	if "`weight'"~="" di in green _column(50) "Weights are" _column(69) "= `weight'"


	di
	local `c' 0
	foreach clusvar in `cluster' { /* getting num clusters by cluster var */

		local `c' = ``c'' + 1
		qui unique `clusvar' if `touse'
		di in green _column(50) "G(" in yellow "`clusvar'" in green ")" _column(69) "=" in yellow %8.0f _result(18)
		
	} /* end getting num obs by cluster var */

	ereturn post `b' `running_sum', e(`touse') depname(``depname'') 

	ereturn local clustvar	= "`cluster'"
	ereturn local clusvar	= "`cluster'"
	ereturn scalar N		= `n'
	ereturn scalar ll_0	= `e_ll_0'
	ereturn scalar ll		= `e_ll'
	ereturn scalar df_m	= `e_df_m'
	ereturn scalar chi2	= `chi2'[1,1]
	ereturn scalar p		= chi2tail(`e_df_m',`chi2'[1,1])
	ereturn scalar r2_p	= `e_r2_p'
	ereturn scalar N_cdf	= `e_N_cdf'
	ereturn scalar N_cds	= `e_N_cds'

	ereturn local title	= "Logit with clustered SEs"
	ereturn local depvar	= "``depname''"
	ereturn local cmd		= "cgmlogit"
	ereturn local crittype	= "log pseudolikelihood"
	ereturn local predict	= "logit_p"
	ereturn local estat_cmd	= "logit_estat"
	ereturn local chi2type	= "Wald"
	ereturn local vcetype	= "Robust"

	ereturn display

end



prog define sub_robust

	syntax [if] [in] [aweight fweight iweight pweight /] , groupvar(string) varlist(string) plusminus(string) running_sum(string) touse(string) [options(string)]


	/* deal with weights */
	if "`weight'"~="" {
		local weight "[`weight'=`exp']"
	} 
	else {
		local weight ""
	}


	if "`if'"=="" local if "if 1"
	else          local if "`if' & `touse'"

	qui logit `varlist' `if' `in' `weight', cluster(`groupvar') `options'

	mat `running_sum' = `running_sum' `plusminus' e(V)

*	mat li `running_sum'
end


*! version 1.1  mh 15/4/98  arb 20/8/98
*got this from http://fmwww.bc.edu/repec/bocode/u/unique.ado
program define unique
local options "BY(string) GENerate(string) Detail"
local varlist "req ex min(1)"
local if "opt"
local in "opt"
parse "`*'"
tempvar uniq recnum count touse
local sort : sortedby
mark `touse' `if' `in'
qui gen `recnum' = _n
sort `varlist'
summ `touse', meanonly
local N = _result(18)
sort `varlist' `touse'
qui by `varlist': gen byte `uniq' = (`touse' & _n==_N)
qui summ `uniq'
di in gr "Number of unique values of `varlist' is  " in ye _result(18)
di in gr "Number of records is  "in ye "`N'"
if "`detail'" != "" {
	sort `by' `varlist' `touse'
	qui by `by' `varlist' `touse': gen int `count' = _N if _n == 1
	label var `count' "Records per `varlist'"
	if "`by'" == "" {
		summ `count' if `touse', d
	}
	else {
		by `by': summ `count' if `touse', d
	}
}
if "`by'" !="" {
	if "`generate'"=="" {
		cap drop _Unique
		local generat _Unique
	}
	else {
		confirm new var `generate'
	}

        drop `uniq'
	sort `by' `varlist' `touse'
	qui by `by' `varlist': gen byte `uniq' = (`touse' & _n==_N)
	qui by `by': replace `uniq' = sum(`uniq')
	qui by `by': gen `generate' = `uniq'[_N] if _n==1
	di in blu "variable `generate' contains number of unique values of `varlist' by `by'"
	list `by' `generate' if `generate'!=., noobs nodisplay
}
sort `sort' `recnum'
end

