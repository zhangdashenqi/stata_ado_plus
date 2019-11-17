*! $Id: personal/d/did3.ado, by Keith Kranker <keith.kranker@gmail.com> on 2012/01/07 18:15:06 (revision ef3e55439b13 by user keith) $
*! Create difference-in-differences tables.
*
* See help file for more information
*
*! By Keith Kranker
*! $Date$

program define did3, eclass   by(recall)

	version 10.1
	syntax varlist(min=3 max=3 numeric) [if] [in] [aw fw iw pw] ///
		[, 					///
		NOISily 			///  Display extra results: checking; regression output; and means & SE tables 
		Format(string) 		///  Specify format for display of tables (matrix saves all digits)
		save 				///  Save the ereturn results from the diff-in-diff regression 
		Labels(string)		///  { tcpp  | varname } 
		vce(passthru) Robust CLuster(passthru) hc2 hc3 /// passthru commands to regression
		]
		
	gettoken  y xvars : varlist
	gettoken  treat after: xvars
	marksample touse
	
	if missing("`weight'") local wtexp ""
	else                   local wtexp "[`weight' `exp']"


	* Display variable names, with labels 
	local y_lab : var label `y'
	local t_lab : var label `treat'
	local a_lab : var label `after'
	
	di  _n 
	di  as txt "Y:" 	   as res _col(10) "`y'   (`y_lab')" 
	di  as txt "Row:" 	   as res _col(10) "`treat'   (`t_lab')" 
	di  as txt "Column:"   as res _col( 9) "`after'   (`a_lab')" 
	
	di  as txt "   Check if row {0|1|.}: " _c
		assert `treat' == 0 | `treat' == 1 | `treat' == . if `touse'
		di as res "OK" as txt ")" _c
	
	di  as txt "   Check if column {0|1|.}: " _c
		assert `after' == 0 | `after' == 1 | `after' == . if `touse'
		di as res "OK" as txt ")" _n
		
	tempvar interaction // Interaction of `treat' and `after'
	gen `interaction' = `after' * `treat'

	* If no format is specified, display results in the current format of `y'
	if "`format'" == "" local format : format `y' 

	quietly {

	* * *  Calculate and store means/standard errors for subpopulations  * * * 

	foreach pp in 0 1 {
		foreach tc in 1 0  {
			if "`noisily'" != "" noisily di as input "regress `y' if (`treat' == `tc' &  `after' == `pp')            `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'"
			`noisily'                                 regress `y' if (`treat' == `tc' &  `after' == `pp') & `touse'  `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'
			local m`tc'`pp' =  _b[_cons]
			local s`tc'`pp' =  _se[_cons]
			returnstars , beta(`m`tc'`pp'') st_err( `s`tc'`pp'') df_r(`e(df_r)')
			if "`noisily'" == "" noisily di as txt "Mean of `y' if `treat'==`tc' &`after'==`pp':  " as res  string(`m`tc'`pp'',"`format'") "  ("  string(`s`tc'`pp'',"`format'") ")" r(stars) as txt " n=" as res e(N)
			
		} // end loop through rows 1 & 2
	}     // end loop through columns 1 & 2

	* * *  Calculate and store differences/standard errors for columns * * *  

	foreach pp in 0 1 {
	    if "`noisily'" != "" noisily di as input "regress `y' `treat' if  (`after' == `pp')           `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'"
		`noisily'                                 regress `y' `treat' if  (`after' == `pp') & `touse' `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'
		local md`pp' = _b[`treat']
		local sd`pp' = _se[`treat']
		returnstars , beta(`md`pp'') st_err( `sd`pp'') df_r(`e(df_r)')
		if "`noisily'" == "" noisily di as txt "Difference of `y' (by `treat') if `after'==`pp':  " as res string(`md`pp'',"`format'") "  ("  string(`sd`pp'',"`format'") ")" r(stars) as txt " n=" as res e(N)
	}     // end loop through columns 1 & 2

	* * *  Calculate and store differences/standard errors for rows * * *  

	foreach tc in 1 0  {
		if "`noisily'" != "" noisily di as input "regress `y' `after' if (`treat' == `tc')           `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'"
		`noisily'                                 regress `y' `after' if (`treat' == `tc') & `touse' `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'
		local m`tc'd = _b[`after']
		local s`tc'd = _se[`after']
		returnstars , beta(`m`tc'd') st_err( `s`tc'd') df_r(`e(df_r)')
		if "`noisily'" == "" noisily di as txt "Difference of `y' (by`after') if `treat'==`tc':  " as res string(`m`tc'd',"`format'") "  ("  string(`s`tc'd',"`format'") ")" r(stars) as txt " n=" as res e(N)
	} // end loop through rows 1 & 2

	* * *  Calculate and store difference-in-difference estimate * * *  

	if "`noisily'" != "" noisily di as input "regress `y' `treat' `after' (`treat' *`after')             `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'"
	`noisily'                                 regress `y' `treat' `after' `interaction'       if `touse' `wtexp',  `vce' `robust' `cluster' `hc2' `hc3'
	local mdd = _b[`interaction']
	local sdd = _se[`interaction']
	returnstars , beta(`mdd') st_err( `sdd') df_r(`e(df_r)')
	if "`noisily'" == "" noisily di as txt "Difference-in-Difference:  " as res string(`mdd',"`format'") "  ("  string(`sdd',"`format'") ")" r(stars) as txt " n=" as res e(N)
	if "`noisily'" == "" noisily di as txt "Asterisks indicate if mean is different from zero at the 10*, 5**, and 1*** percent level.)"
	if "`save'" == "" ereturn clear
	
	}     // end quietly block


	* * *  Form Matrix, Save, and Display Results  * * * 

	* Setup temp names
	tempname temp means_table sterr_table full_table blk
	tempname R1  R1s  R2  R2s R3  R3s blk

	* Save Individual Rows 
	matrix input     `R1'  = (`m10',`m11',`m1d' )
	matrix input     `R1s' = (`s10',`s11',`s1d' )
	matrix input     `R2'  = (`m00',`m01',`m0d' )
	matrix input     `R2s' = (`s00',`s01',`s0d' )
	matrix input     `R3'  = (`md0',`md1',`mdd' )
	matrix input     `R3s' = (`sd0',`sd1',`sdd' )
	matrix input     `blk' = ( .z  , .z  , .z   )

	* Obtain Row and Column Lables
	local r1L : label (`treat') 1 , strict
				if ("`r1L'"=="" | "`labels'"=="varname") local r1L "`treat'=1"
	local r0L : label (`treat') 0 , strict
				if ("`r0L'"=="" | "`labels'"=="varname") local r0L "`treat'=0"
	local c1L : label (`after') 1 , strict
				if ("`c1L'"=="" | "`labels'"=="varname") local c1L "`after'=1"
	local c0L : label (`after') 0 , strict
				if ("`c0L'"=="" | "`labels'"=="varname") local c0L "`after'=0"
	if ("`labels'" == "tcpp") {
		local rowlabel `"Treatment Control Difference"'
		local collabel `"Pre Post Difference"'
		}
	else {
		local rowlabel `""`r1L'" "`r0L'" "Difference""'
		local collabel `""`c0L'" "`c1L'" "Difference""'
		}
	foreach i in `rowlabel' {
		local rowlabel_blks `"`rowlabel_blks' "`i'" " " " " "'  // " Are used to create blanks in full_table
	}
		
	* Save table with only the means
	matrix           `means_table' = `R1'\ `R2'\ `R3'
	matrix rownames  `means_table' = `rowlabel'
	matrix colnames  `means_table' = `collabel'
	ereturn matrix    mean = `means_table' 
	if "`noisily'" != "" matrix list e(mean) , format(`format')

	* Save table with only the standard errors
	matrix           `sterr_table' = `R1s' \ `R2s' \ `R3s'
	matrix rownames  `sterr_table' = `rowlabel'
	matrix colnames  `sterr_table' = `collabel'
	ereturn matrix    se = `sterr_table' 
	if "`noisily'" != "" matrix list e(se) ,  format(`format')

	* Save a "pretty" table
	matrix           `full_table' = `R1'\ `R1s' \ `blk' \ `R2'\ `R2s' \ `blk' \ `R3'\ `R3s' \ `blk'
	matrix rownames  `full_table' = `rowlabel_blks'
	matrix colnames  `full_table' = `collabel'
	ereturn matrix    table = `full_table' 
	if "`noisily'" != "" matrix list e(table) ,          format(`format') nodotz
	else                 matrix list e(table) , noheader format(`format') nodotz

	* Save scalar with diff-in-diff estimate
	ereturn scalar did   = `mdd'
	ereturn scalar didse = `sdd'

end  

program define returnstars ,  rclass
	version 9
	syntax , beta(real) st_err(real) df_r(real)
	local tstat = abs( `beta' / `st_err' )
	if `df_r'==. local tstat = 2*(1-normprob( `tstat' ))
    else         local tstat = tprob( `df_r', `tstat' )
	
	if (`tstat'<=0.10 & `tstat'!=.) local ast "*  "   
	if (`tstat'<=0.05 & `tstat'!=.) local ast "** "  
	if (`tstat'<=0.01 & `tstat'!=.) local ast "***"
	if (`tstat'> 0.10 | `tstat'==.) local ast "   "   
	return local stars "`ast'"
end


