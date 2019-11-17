*! $Id: personal/m/meantab.ado, by Keith Kranker <keith.kranker@gmail.com> on 2012/01/07 18:15:06 (revision ef3e55439b13 by user keith) $
*! Create a "summary statistics" table. 
* 
* Create a "summary statistics" table. 
* Rows are variables. 
* Columns are subgroups. 
* Column w/ difference/tstat as an option.
*!
*! By Keith Kranker
*! $Date$


program define meantab, eclass  

version 9.2

syntax varlist(min=1 numeric) [if] [in] ///
	/// note: 7/13/2011 I'm not sure  weights are right, below.  I'm commenting them out ///
	/// [fweight pweight aweight iweight] 
	, ///
	over(varname)   	///  Key option --> creates columns
	[ 				    ///  
	Tstat 				///  Use a regression to obtain t-statistic on difference from primary category. If  this is selected, you can use "char OverVarname[omit] to choose which category is ommitted" 
	Difference			///  Instead of the "all" column, calculate differences between columns 1 and 2
	noBlank             ///  In the main table, do not display a blank row between variables 
	noSE                ///  In the main table, do not display standard errors
	noNBelow            ///  Put a row at the bottom of the table with number of individuals in each group where `if' `in'
	noNCELls			///  Put a row for each variable with number of individuals in the calculation.
	noNCOLumn			///  If nocells is called, program adds an extra column with number of observations in row.  This option overrides this behavior.
	Missing  			///  Treats missing (.) as a group of the over variable
	CASEwise			///  perform casewise deletion of observations
	NOISily 			///  Display extra results: checking; mean command output and tstat regression output
	Format(passthru) 	///  Specify format for display of tables (matrix saves all digits)
	SAVEFormat(str) 	///  Format for saving mean/se in matrix (and therefore display of tables)
	estout level(passthru) obs(integer -1) dof(integer 2) ///   Display a "pretty" table with ereturn display table.  Warning: this is really problematic.
	noMATrix			///  Suppress display of e(table)
	STDize(passthru) STDWeight(passthru) NOSTDRescale /// passthru MEAN's model
	vce(passthru) CLuster(passthru)  /// passthru commands to regression
	robust     /// passed to regress for difference and tstat options
	svy       /// types "svy: " before mean and regress command
	]

quietly {

// Selects observations using the "casewise" behavior based on the marksample
if "`casewise'"=="casewise" local if "if `touse'"
marksample touse 

// Display sample sizes
if "`noisily'"=="noisily" {
  noisily {
	di as txt "Count if `over' !=. :"
	count if `over' !=.
	di as txt "Count `if' `in' :"
	count `if' `in' 
	di as txt "Casewise sample size :"
	count if `touse'
	}
}
count if `touse'
local count_touse = r(N)
if (`obs' == -1)  local obs = `count_touse'
local varnum : word count `varlist'

if (( `varnum' > 10 | `count_touse' > 10000 ) & ( "`noisily'" != "noisily" )) local dots "dots" 

// Set up temporary variables
local v = 0 
tempvar group 
tempname overlab ncount full_table full_m full_se full_n full_t full_nrow  /// 
	     n_column m se n m2 se2 t tse blank  m_v se_v  n_v m_v_all se_v_all ///
		 n_v_all t_v cell_temp cell_temp_sformat ncount_temp b_temp V_temp 
	

// Use a temporary variable instead of `over'  This allows you to loop through columns via 1,2,...`c_n'
egen `group' = group(`over') `if' `in' , `missing' label lname(`overlab')  
`noisily' tab `group'  `if' `in' , matcell(`ncount_temp')
mat `ncount' = `ncount_temp''
local n_final = r(N)
local c_n  = r(r) 
local c_n1 = r(r) + 1

// for this temporary `group' variable, I need to match up the [omit] character from the existing variable
local omit_of_over  : char `over'[omit] 
if inlist("`omit_of_over'","",".") {
	`noisily' di as txt "char `over'[omit] = " as res "is blank." as txt "Something will be chosen automatically."
}
else {
	`noisily' di as txt "char `over'[omit] = " as res "`omit_of_over'" as txt " is equivalent to "
	cap confirm string var `over'  
	if !_rc local omit_of_over `""`omit_of_over'""'
	forvalues row = 1 / `c(N)' {
		if `=`group'[`row']' == `omit_of_over' {
			local omit_of_group = `=`group'[`row']'
			continue, break
			}
		}
char `group'[omit] `omit_of_group'
local omit_of_group : char `group'[omit]  
`noisily' di as txt "char `group'[omit] =" as res "`omit_of_group'"
}


if `c_n' <= 1 {
	noisily di as error "`over' only contains one group `if' `in'" ///
	  _n "You must choose a different -over- varname or expand your data set."
	error 197
}


if "`tstat'"!="" & ( "`stdize'"!="" | "`stdweight'"!="" | "`nostdrescale'"!="" ) {
	noisily di as error "You cannot select the -tstat- option and survey optons."
	error 197
	}
if "`vce'"=="vce(robust)" {
	noisily di as error "This program is based on the {help mean} command, which does not allow -vce(robust)-.  (Although the -robust- can be used to calculate robust standard errors for the tstat option.)"
	error 197
	}
	
if length("`cluster'") & length("`svy'") {
	noisily di as err "-cluster- and -svy- cannot be specified at the same time."
	error 197
	}

if !missing("`saveformat'") & !missing("`format'") {
	noisily di as err "-format- and -saveformat- cannot be specified at the same time."
	error 197
	}

if "`noisily'"=="noisily" {
	noisily di as txt _n "There will be `c_n' row columns, plus 1 'all' column for `c_n1' total columns: "
	noisily label list `overlab'
	}
	
if "`svy'"=="svy" local svy_prefix " svy : "
else              local svy_prefix ""
	
// remove variables with no 
foreach y of var `varlist' {
	if ""=="`if'" local if_word = "if"
	else          local if_word = " & "
	qui count `if' `if_word' !mi(`y') & !mi(`group')  `in' 
	if r(N) == 0 {
		local varlist : list local(varlist) - local(y)
		local dropped : list local(varlist) | local(y)
	}
}
if `: list sizeof dropped' noisily di as err "The following variables are dropped because there are no observations: " as txt "`dropped'" _n


if "`dots'"=="dots" noisily di as text "Variables completed: " _c


foreach y of var `varlist' {
    local ++v 
	if "`dots'"=="dots" noisily di as res "..`v'" _c

	if "`noisily'"=="noisily" noisily di as txt _n "Beginning Analysis for variable " as res "`v'" as txt ":" as res `" `y' `: var label `y''"' _n
		
	* * *  Run -mean- command for each variable with -over- variable, storing results for each column  * * * 

	if "`noisily'"=="noisily" di as input "-> `svy_prefix' mean `y' `if' `in' `weight', over(group(`over'), nolabel) nolegend `vce' `cluster' `level'"
	
	`noisily' `svy_prefix' mean `y' `if' `in' `weight', over(`group', nolabel) nolegend `vce' `cluster' `level'

	local n_over = e(N)
	local c_actual "`e(over_namelist)'"
	mat `m'  = e(b)
	mat `se'  = vecdiag(e(V))
	mat `n'   = e(_N)
	if "`estout'"=="estout" {
		mat `m2' = e(b)
		mat `se2' = vecdiag(e(V))
	}
	
	* Remove matrix equation names
	mat coleq `m'  = : 
	mat coleq `se' = : 
	mat coleq `n'  = : 
	
	tempname 
	
	forvalues c = 1/`c_n'  {
		// Get label for top of column
		local clab : label (`group') `c'
		local clab : subinstr local  clab  "\" " " , all
		local clab : subinstr local  clab  ":" " " , all
		local clab : subinstr local  clab  "/" " " , all
		local clab : subinstr local  clab  "." " " , all
		local clab : subinstr local  clab  "-" " " , all
		if "`clab'" == "." | length("`clab'") == 0 local clab "`over'=ukn"
		if `v'==1 & length(trim("`clab'"))>32 di as txt "Column label truncated: " as res substr(trim("`clab'"),1,32) as txt substr(trim("`clab'"),33,.)
		local clab = substr(trim("`clab'"),1,32)

		// Get mean for this cell
		cap           mat   `cell_temp' = `m'[1,"`c'"]
		if _rc !=0    mat   `cell_temp' = .z
		if !missing("`saveformat'") { 
			cap {
				scalar `cell_temp_sformat' =  `cell_temp'[1,1]
				local   cell_temp_sformat2 = string(`cell_temp_sformat',"`saveformat'")
				mat   `cell_temp' = `cell_temp_sformat2'
			}
		}
		mat colnames `cell_temp' = `"`clab'"'   // "
		if `c'==1  	mat   `m_v'  = (         `cell_temp' )
		else       	mat   `m_v'  = ( `m_v' , `cell_temp' ) 

		// Get se for this cell
		cap  {
			mat   `cell_temp' = `se'[1,"`c'"] 
			local temp2 = sqrt(`cell_temp'[1,1])
			mat   `cell_temp' = `temp2'
		}
		if _rc !=0    mat   `cell_temp' = .z
		if !missing("`saveformat'") { 
			cap {
				scalar `cell_temp_sformat' =  `cell_temp'[1,1]
				local   cell_temp_sformat2 = string(`cell_temp_sformat',"`saveformat'")
				mat   `cell_temp' = `cell_temp_sformat2'
			}
		}
		mat colnames `cell_temp' = `"`clab'"' // "
		if `c'==1  mat   `se_v' =            `cell_temp'
		else       mat   `se_v' = ( `se_v' , `cell_temp' )
		
		// Get n for this cell
		cap           mat   `cell_temp' = `n'[1,"`c'"]
		if _rc !=0    mat   `cell_temp' = .z
		mat colnames `cell_temp' = `"`clab'"' // "
		if `c'==1  mat `n_v'  = (         `cell_temp'  )
		else       mat `n_v'  = ( `n_v' , `cell_temp' )
		
	} // end loop through columns
	
	// Use varname as row label
	mat rowname `m_v'  = "`y'"
	mat rowname `se_v' = "`y'"
	mat rowname `n_v'  = "`y'"
 
 
	* * *  Create an "All" or "Difference" column * * * 
	
	if "`missing'"=="missing" local omitmissing " "
	else if "`if'" == ""      local omitmissing "if  missing(`over') != 1"
	else                      local omitmissing "&   missing(`over') != 1"

	
	if "`difference'" == "difference" {
		* * *  Run -regress- command to create "Difference" column * * * 

		if "`tstat'" == "tstat" di as error "It is recommended that you chose either the -difference- or the -tstat- option, but not both."
		
		if `c_n' != 2 {
			di as error "There are more than two groups in your sample.  Use the -tstat- option, not the -difference- option."
			exit
			}

		if "`noisily'"=="noisily" di as input _n "-> xi: `svy_prefix' regress `y' i.`group' `if'  `omitmissing' `in' `weight', `vce' `cluster' `level'"

		`noisily' xi: `svy_prefix' regress `y' i.`group' `if'  `omitmissing' `in' `weight', `vce' `cluster' `level' `robust'
		
		local n_all = e(N)
		di "assert `n_all' == `n_over'  "  _c
		assert (`n_all' == `n_over')
		di as res "OK"

		mat `m'  = e(b)
		mat `se' = e(V)
		mat `m_v_all'  =  `m'[1,1]
		if !missing("`saveformat'") { 
			cap {
				scalar `cell_temp_sformat' = `m_v_all'[1,1]
				local   cell_temp_sformat2 = string(`cell_temp_sformat',"`saveformat'")
				mat   `m_v_all' = `cell_temp_sformat2'
			}
		}
		mat `se_v_all' =  sqrt(`se'[1,1] )
		if !missing("`saveformat'") { 
			cap {
				scalar `cell_temp_sformat' = `se_v_all'[1,1]
				local   cell_temp_sformat2 = string(`cell_temp_sformat',"`saveformat'")
				mat   `se_v_all' = `cell_temp_sformat2'
			}
		}
		mat `n_v_all'  =  e(N)
		mat colname `m_v_all'  = "Difference"
		mat colname `se_v_all' = "Difference"
		mat colname `n_v_all'  = "Difference"
	}
	else {
		* * *  Run -mean- command for each variable, to create "All" column * * * 
			
		if "`noisily'"=="noisily" di as input _n "-> `svy_prefix' mean `y' `if' `omitmissing' `in' `weight', `vce' `cluster' `level'"
		
		`noisily' `svy_prefix' mean `y' `if' `omitmissing' `in' `weight', `vce' `cluster' `level' 
		
		local n_all = e(N)
		di "assert `n_all' == `n_over'  "  _c
		assert (`n_all' == `n_over')
		di as res "OK"
		
		mat `m'  = e(b)
		mat `se' = e(V)
		mat `n' =  e(_N)
		mat `m_v_all'  =  `m'[1,1]
		if !missing("`saveformat'") { 
			cap {
				scalar `cell_temp_sformat' = `m_v_all'[1,1]
				local   cell_temp_sformat2 = string(`cell_temp_sformat',"`saveformat'")
				mat   `m_v_all' = `cell_temp_sformat2'
			}
		}
		mat `se_v_all' =  sqrt(`se'[1,1] )
		if !missing("`saveformat'") { 
			cap {
				scalar `cell_temp_sformat' = `se_v_all'[1,1]
				local   cell_temp_sformat2 = string(`cell_temp_sformat',"`saveformat'")
				mat   `se_v_all' = `cell_temp_sformat2'
			}
		}
		mat `n_v_all'  =  `n'[1,1]
		mat colname `m_v_all'  = "All"
		mat colname `se_v_all' = "All"
		mat colname `n_v_all'  = "All"
	}
	
	if  missing("`se'") {
		local seline "\ \`se_v' , \`se_v_all'"
	}
	else {
		local seline ""
	}
	
	if 	missing("`blank'") {
		local blk_cmd: display _dup(`c_n') ".z , " ".z"
		mat `blank' = `blk_cmd'
		mat rowname `blank' = " "
		local blankline " \ \`blank' "
	}
	else {
		local blankline ""
	}
		
	// For use with the n-column option; foreach variable, add "n" to the bottom of the column `n_column'
	if ("`ncells'" == "noncells" & "`ncolumn'" != "noncolumn") {
		// Place banks for "empty" rows that contain the cell's "n" or a t-statistic
		if "`ncells'" == "noncells" local ncelldot ""
		else                        local ncelldot "\ .z"
		if "`tstat'" == "tstat" local tcelldot "\ .z"
		else                    local tcelldot ""
		mat `n_column' = ( nullmat(`n_column') \ `n_all'  `ncelldot' `tcelldot' )				
		}
		
	* * * Run regression for the ttest option  * * * 
	if "`tstat'" == "tstat" {
			
		if "`noisily'"=="noisily" di as input _n "-> xi: `svy_prefix' regress `y' i.`group' `if' `omitmissing' `in' `weight', `vce' `cluster' `level'"

		`noisily' xi: `svy_prefix' regress `y' i.`group' `if' `omitmissing' `in' `weight', `vce' `cluster' `level' `robust'
		local t_dof = e(df_r) 
		if ( "`noisily'" == "noisily") noisily di `"assert `n_all' == `e(N)' "'  _c
		assert (`n_all' == e(N) )
		if ( "`noisily'" == "noisily") noisily di as res "OK"
		
		forvalues c = 1/`c_n'  {
			local clab : label (`group') `c'
			local clab : subinstr local  clab  "\" " " , all
			local clab : subinstr local  clab  ":" " " , all
			local clab : subinstr local  clab  "/" " " , all
			local clab : subinstr local  clab  "." " " , all
			local clab : subinstr local  clab  "-" " " , all
			if "`clab'" == "." | length("`clab'") == 0 local clab "`over'=ukn"
			if `v'==1 & length(trim("`clab'"))>32 di as txt "Column label truncated: " as res substr(trim("`clab'"),1,32) as txt substr(trim("`clab'"),33,.)
			local clab = substr(trim("`clab'"),1,32)
			
			di `"local beta_c =  _b[_I`group'_`c']"'
			cap {
				local beta_c =  _b[_I`group'_`c']
			    local serr_c = _se[_I`group'_`c']
				local tstat_c  = round(abs( `beta_c' / `serr_c' ),.001)
				mat   `cell_temp' = ( `tstat_c' )
				}
			if (_rc !=0)  {
				mat   `cell_temp' = .z
				} 
			mat colnames `cell_temp' = `"`clab'"' // "
			if `c'==1  mat `t_v'  = (         `cell_temp' )  
			else       mat `t_v'  = ( `t_v',  `cell_temp' ) 

		}  // end loop through columns

		mat rowname `t_v'  = "`y'"
		drop _I`group'_*
	
		// Store for a t-stat table
		if ( `v'==1 )  	mat `full_t'  = `t_v'
		else   			mat `full_t' = ( `full_t' \ `t_v' )
			
		// Prepare to add to main table	
		mat rownames `t_v' = ": "
		local tline " \ `t_v' , .z "
		
	}  // end tstat section
	else local tline " "
	
* * * Add mean, se, n, [t] for current variable to the tables  * * * 

	if "`ncells'" == "noncells" local nline " "
	else                        local nline " \ `n_v'  , `n_v_all' "

	mat  `full_m'  = ( nullmat(`full_m')  \ `m_v'  , `m_v_all' )
	mat  `full_se' = ( nullmat(`full_se') \ `se_v' , `se_v_all' )
	mat  `full_n'  = ( nullmat(`full_n')  \ `n_v'  , `n_v_all' )

	foreach mat in `se_v' `se_v_all' `n_v' `n_v_all' {
		mat rownames `mat' = ": "  // strip row labels
		}

	mat `full_table' =  ( nullmat(`full_table') \ `m_v' , `m_v_all' `seline' `tline' `nline' `blankline' )
		
	
	if "`estout'"=="estout" {

		* * *  Save b's and v's in a stacked column with equation names for the -estout- table * * * 

		local c_namelist " "
		foreach c in `c_actual' {
			local clab : label (`group') `c'
			local clab : subinstr local  clab  "\" " " , all
			local clab : subinstr local  clab  ":" " " , all
			local clab : subinstr local  clab  "/" " " , all
			local clab : subinstr local  clab  "." " " , all
			local clab : subinstr local  clab  "-" " " , all
			if "`clab'" == "." | length("`clab'") == 0 local clab "`over'=ukn"
			if `v'==1 & length(trim("`clab'"))>32 di as txt _n "Column label truncated: " as res substr(trim("`clab'"),1,32) as txt substr(trim("`clab'"),33,.) _n
			local clab = substr(trim("`clab'"),1,32)

			local c_namelist `"`c_namelist' "`y':`clab'" "'   // `"   "' need to include "
			}

		mat colnames `m2'  = `c_namelist'
		mat `cell_temp' = `m'[1,1]
		if "`difference'" == "difference" mat colnames `cell_temp' = "`y':Difference"
		else                              mat colnames `cell_temp' = "`y':All"
		if `v' == 1 mat b = (     `m2'  , `cell_temp'  )
		else        mat b = ( b , `m2'  , `cell_temp'  )

		mat colnames `se2' = `c_namelist'
		mat `cell_temp' = `se'[1,1]
		if "`difference'" == "difference" mat colnames `cell_temp' = "`y':Difference"
		else                              mat colnames `cell_temp' = "`y':All"
		if `v' == 1  mat V = (     `se2' , `cell_temp' )
		else         mat V = ( V , `se2' , `cell_temp' )
		
	}   // end estout section

}   // end loop thru varlist


* * *   Form final matrixes, save and print results *** 	

// Row for bottom of table with "overall" n counts
mat   `full_nrow'  =     `ncount' , `n_final'
mat   rowname `full_nrow' = "N"
mat   `full_n' =    `full_n'  \ `full_nrow'
if "`nbelow'" != "nonbelow" {
	mat   `full_table' =  `full_table' \ `full_nrow'   // Append N row to bottom of table (by default)
	}

	
// no-ncells option without no-ncolumn option: adds "N" column to table
if ("`ncells'" == "noncells" & "`ncolumn'" != "noncolumn") {
	mat `n_column' = ( `n_column'  \ .z )
	mat colname `n_column' = "N"
	mat `full_table' = ( `full_table' , `n_column' )   // append column with "n" list into last column
	}

// post saved retults to ereturn	
ereturn clear
if "`estout'"=="estout" {
	mat V   = diag(V)
 	ereturn post b V , obs( `obs') dof( `dof')
	}
ereturn matrix    _m         = `full_m'    
ereturn matrix    _se        = `full_se'    
ereturn matrix    _n         = `full_n' 
ereturn matrix    _n_overall = `full_nrow' 
ereturn matrix    table      = `full_table'
if "`tstat'" == "tstat" {
  ereturn matrix  tstat      = `full_t'
  }


// Display final results
if "`matrix" != "nomatrix"  {

	// header to display before table
	if "`tstat'" == "tstat"     local t_lab ", t"
	else                        local t_lab ""
	if "`ncells'" != "noncells" local n_lab ", n"
	else                        local n_lab ""
	local overvarlabel : var label `over'
	if "`overvarlabel'" != "" local overvarlabel "(`overvarlabel')"
	else                      local overvarlabel ""

	noisily di _n ///
	  as txt "Summary statistics: "  as res "mean, SE`t_lab'`n_lab'" _n ///
	  as txt "   by categories of: " as res "`over' `overvarlabel'"

	// display before e(table)
	noisily  mat list e(table)    , nodotz `format' noheader

	}

`noisily' ereturn list		  

} // end quiet block 


if "`estout'"=="estout" {

* This option uses the data stored in b and V to create a table similar to the "means" command
foreach v of var `varlist' {
	local nonmissing "`nonmissing' & `v'!=."   // Grab a list of  varname !=. commands for the "disclaimer" line.
	}

di _n _n 
ereturn display `level'

// Disclaimer lines to point out how this is working. 
di as txt "Means and standard errors are reliable/stable.  t, P>|t|, and confidence  " _n ///
          "intervals depend on the sample size and degrees of freedom that are provided " _n ///
		  "to the ereturn routine.  This table uses n=" as res "`count_touse'" as txt " and dof=" as res "`dof'"  as txt "." _n /// "
		  "If there is no missing data results should match those of the -mean- command. " _n /// 
		  "That is, the commands:" _n ///
		  " .  {stata mean `varlist' `if' `in', over(`over') `vce' `cluster' `level'}"   _n ///
		  " .  {stata mean `varlist' `if' `omitmissing' `in', `vce' `cluster' `level'}"   _n ///
		  "Should be identical to the table produced by:"   _n ///
		  " .  {stata meantab `varlist' `if' `omitmissing' `nonmissing' `in' , over(`over') estout `vce' `cluster' `level' nomatrix}"   _n ///
		  "To undestand the table's construction, use the -noisily- option."   _n 
}

end
