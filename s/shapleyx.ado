*! v 2.0.1 PR 02sep2013.
/*
	Shapley decomposition, idea by Tony Shorrocks, shora@essex.ac.uk.
	Adapted by Patrick Royston from an implementation by Stas Kolenikov,
	kolenikovs@missouri.edu. Based on version 3.2, 01July2001.
	
	Enhancements include factor variables support and composite lists, such
	as age (age_1 age_2) where age_1 and age_2 are transformations of the 
	variable age. The variables age_1 age_2 are included or excluded from
	the model jointly.
	
	All global macros have been eliminated from the shapley.ado code.
	
	02sep2013: Renamed from shapley2 to shapleyx following email from
	Florian Wendelspiess Chávez Juárez about his shapley2.
*/
program define shapleyx, rclass
version 11.2
/*
	Parse as follows:
	shapleyx <factor_list>, options : program whatever @ whatever
*/
	local call `0'

	gettoken part call: call, parse(" :") quotes
	while `"`part'"'!=`":"' & `"`part'"' != `""' {
		local left `"`left' `part'"'
		gettoken part call: call, parse(" :") quotes
	}
/*
	`left' is the thing up to the colon, i.e. factors and options,
	and `call' is the call to the program
*/
	if "`call'" == "" {
		di as err "no program was called"
		exit 198
	}

	gettoken part left: left, parse(" ,") quotes
	while `"`part'"'!=`","' & `"`part'"' != "" {
		local factor `"`factor' `part'"'
		gettoken part left: left, parse(" ,") quotes
	}

	// `factor' is the factor list, and `left' are net options

	local 0 `part'`left'

	syntax , RESult(string) [ debug SAVing(string) Dots replace STOring(string) ///
	 PERCent TRace fromto TItle(string) NOIsily noPRESERVE]

	tokenize `result'
	if ("`1'" == "global") {
		local result `2'
		local global "$"
	}

	tempname dmatrix
/*
	!! PR Create `names' without the i. stuff, `factors' has the full list including
	e.g. FP transformations and factor variables. It includes parens () to separate
	varlists. `names' is the original variables.
*/
	_vl2 `factor'
	local factors `r(varlist)'
	local names `r(namelist)'
	local m = r(m)

	matrix `dmatrix' = J(`m'+1, 2, 0)
	matrix rownames `dmatrix' = `names' total
	matrix colnames `dmatrix' = OneStage Shapley

	if `"`saving'"'=="" {
		tempfile shsave
		local saving `shsave'
	}
	if `"`storing'"'=="" {
		tempfile shstore
		local storing `shstore'
	}

	if ("`debug'" != "") {
		di _n as txt "List of factors : " as txt `"`factor'"'
		di    as txt "Shapley options : " as txt `"`0'"'
		di    as txt "Call to program : " as txt `"`call'"'
	}

	tempfile savefile basefile
	if ("`preserve'"!="nopreserve") preserve
	cap save `"`basefile'"', replace
	if ("`debug'" != "") di as txt "r(" c(rc) ")"

	di as txt _n "    Shapley decomposition"
	if "`title'"!="" {
		di as txt "    of `title'"
	}
	di

	if ("`debug'" != "") {
		di as txt "The list of the local macros:" _n "saving   = " as res `"`saving'"'
		dir `"`saving'"'
		di as txt "storing  = " as res `"`storing'"'
		dir `"`storing'"'
		di as txt "savefile   = " as res `"`savefile'"'
		di as txt "basefile   = " as res "``basefile''"
		dir `"`basefile'"'
	}

	SHMat01, names(`names') savefile(`savefile') `debug'
	* OK, now we have our 011011 patterns in `savefile'

	if ("`debug'" != "") {
		drop _all
		use `"`savefile'"'
		list
		restore, preserve
	}

	// Calculate the partial values
	SHFill, names(`names') saving(`saving') factors(`factors') call(`call') ///
	 savefile(`savefile') basefile(`basefile') `dots' `trace' `debug' ///
	 `noisily' result(`result') global(`global') `replace'

	if "`fromto'"!="" {
		qui use `"`saving'"'
		di as txt "All factors present: `result' = " as res __res[_N]
		di as txt "No  factors present: `result' = " as res __res[1]
	}

	// do the decomposition
	SHDeComp, names(`names') `dots' saving(`saving') storing(`storing') `debug' `replace'

	// output the results
	SHDisp, names(`names') storing(`storing') dmatrix(`dmatrix') `percent' diff(`shdiff')
	return matrix decompos `dmatrix'
	return local names `names'
	return local factors `factors'

	qui use `"`basefile'"', clear
end

program define _vl2, rclass
version 11.2
/*
	Extracts 2 lists from the input string: primary variables or strings
	(user-defined names), and things in parens following them, probably FPs
	or dummy variables. Returns 1st list as a macro `r(namelist)', then
	individual macros and the 2nd list for the variables.
*/
syntax [anything(name=xlist)]
GetVL `xlist'
local nx = r(nx)
local namelist
local j 1
local m 0
while `j' <= `nx' {
	local j1 = `j' + 1
	local ++m
	local x `r(xvar`j')'
	local namelist `namelist' `x'
	if "`r(paren`j1')'" == "1" {
		local xvar`m' `r(xvar`j1')'
		local j `j1'
	}
	else {
		local xvar`m' `r(xvar`j')'		
	}
	local ++j
}
// Strip factor info from namelist
tokenize `namelist'
local namelist
local varlist
forvalues j = 1 / `m' {
	capture fvexpand ``j'' // ``j'' may be a string, not a variable
	if "`r(fvops)'" == "true" {
		local vn = substr("``j''", 1 + strpos("``j''", "."), .) // name of factor var stripped of prefix
	}
	else local vn ``j''
	local namelist `namelist' `vn'
	local varlist `varlist' (`xvar`j'')
	return local xvar`j' `xvar`j''
}
return scalar m = `m'
return local namelist `namelist'
return local varlist `varlist'
end

program define GetVL, rclass /* xvarlist [(xvarlist)] ... */
version 11.2
local xlist `0'
if (`"`xlist'"'=="") error 102
local nx 0
gettoken xvar xlist : xlist, parse("()") match(par)
while (`"`xvar'"'!="" & `"`xvar'"'!="[]") {
	capture confirm var `xvar' // `xvar' could just be a string
	if (c(rc) == 0) fvunab xvar : `xvar'
	local nvar : word count `xvar'
	if ("`par'"!="" | `nvar'==1) {
		local ++nx
		local xvar`nx' "`xvar'"
		local xvars "`xvars' `xvar'"
		if ("`par'"!="") local paren`nx' 1
	}
	else {
		tokenize `xvar'
		forvalues i = 1 / `nvar' {
			local ++nx
			local xvar`nx' "``i''"
			local xvars "`xvars' ``i''"
		}
	}
	gettoken xvar xlist : xlist, parse("()") match(par)
	if ("`par'"=="(" & `"`xvar'"'=="") {
		di as err "empty () found"
		exit 198
	}
}
forvalues i = 1 / `nx' {
	return local xvar`i' `xvar`i''
	return local paren`i' `paren`i''
}
return scalar nx = `nx'
end

program define SHDisp
// display the results of decomposition and collect the returned values
version 11.2

syntax [, percent names(string) storing(string) dmatrix(name) diff(string) ]
tokenize `names'

if "`percent'"!="" {
	local pc1 "|  Per cent"
	local pc2 "|"
	local pc3 "+------------"
}

di as txt _n ///
" Factors | 1st round |  Shapley  `pc1'" _n ///
"         |  effects  |   value   `pc2'" _n ///
"---------+-----------+-----------`pc3'"

quietly {
	drop _all
	use `"`storing'"'
	local m: word count `names'
	local i 1
	local sum1 0
	local sum2 0
	forvalues i = 1 / `m' {
		local namei : word `i' of `names'
		sum `namei' [fw=__weight]
		matrix `dmatrix'[`i',2]=r(mean)
		local sum2=`sum2'+`dmatrix'[`i',2]
		tempname n`i'
		gen `n`i'' = __diff if __factor=="`namei'" & __stage==1
		sum `n`i''
		matrix `dmatrix'[`i',1]=r(mean)
		local sum1=`sum1'+`dmatrix'[`i',1]
		noi di as txt abbrev("``i''", 9) _col(10) "| " as res %8.5g `dmatrix'[`i',1] ///
		 _col(22) as txt "| " as res %8.5g `dmatrix'[`i',2] _col(34) _c
		 if "`percent'"!="" {
			 noi di as txt "| " as res %6.2f `dmatrix'[`i',2]*100/`diff' as txt " %"
		 }
		 else noi di
	} // end of while across factors
} // end of quietly
matrix `dmatrix'[`m'+1, 2] = `diff' // total
matrix `dmatrix'[`m'+1, 1] = `sum1' // total at the first stage
di as txt ///
"---------+-----------+-----------`pc3'" _n ///
"Residual | " as res %8.5g `dmatrix'[`m'+1,2]-`dmatrix'[`m'+1,1] _col(22) as txt "|" _n ///
"---------+-----------+-----------`pc3'" _n ///
"   Total | " as res %8.5g `dmatrix'[`m'+1,2] _col(22) as txt "| " ///
             as res %8.5g `dmatrix'[`m'+1,2] _col(34) _c
if "`percent'"!="" {
	di as txt "| 100.00 %"
}
else di
end

program define SHDeComp
// purpose: does all decomposition
version 11.2
syntax [, names(string) saving(string) storing(string) dots debug replace]

if "`dots'"!="" {
	di as txt "Calculating the differences due to factor elimination..."
}
qui {
	preserve
	tempname shdec
	postfile `shdec' __factor __from __to __stage __diff __weight using `"`storing'"', `replace'
	drop _all
	use `"`saving'"'
	gsort -__ID
	local shdiff=__result[1]-__result[_N]
	tokenize `names'
	local m : word count `names'

	tempname d0
	scalar `d0' = 1
	forvalues i = 1 / `m' {
		tempname d`i' diff`i'
		local i1 = `i' - 1
		scalar `d`i'' = `d`i1'' * 2
		if ("`debug'" != "") di as txt `d`i1'' "*2=" `d`i''
	}
	// to have degrees of 2. We did that in SHMat01, btw.
	local stage 0
	while `stage' <= `m' { /* step across stages starting at zero */
		version 6: local wei`stage'=exp(lnfact(`m'-`stage'-1)+lnfact(`stage'))
/*
	some weights attached to stages differences
	should be (`m'-1)!/(`m'-`stage'-1)! `stage'!
	to represent the number of trajectories passing by
*/
		if ("`debug'" != "") noi di as txt "Stage " as res `stage' as txt ": 1/weight = " as res `wei`stage''
		local ++stage
	}

	// now, explicit subscripting...
	tempname ID plus
	scalar `ID'=1
	while `ID'<=_N {
		* now, we need to find out where 1s are...
		forvalues k = 1 / `m' {
			local kk : word `k' of `names'
			if `kk'[`ID'] {
				* ... and to find the differences with this factor eliminated
				scalar `plus'=`d`m''/`d`k''
				scalar `diff`k''=__result[`ID']-__result[`ID'+`plus']
				local stage=`m'-__round[`ID']
				if ("`debug'" != "") {
					noi di as txt " Now posting : " as txt `"post `shdec' (`k') (`ID') (`ID'+`plus') (__round[`ID']) (`diff`k'') (`wei`stage'')"'
				}
				post `shdec' (`k') (`ID') (`ID'+`plus') (__round[`ID']) (`diff`k'') (`wei`stage'')
			} // yeah, that was 1
		}
		scalar `ID' = `ID' + 1
	}
	postclose `shdec'
	if ("`dots'"!="") noi di
	drop _all
	use `"`storing'"'
	lab data "Shapley: marginal differences"
	rename __factor __fno
	lab var __fno "No. of the factor"
	gen str8 __factor=" "
	forvalues k = 1 / `m' {
		local kk : word `k' of `names'
		replace __factor = "`kk'" if __fno==`k'
		gen double `kk' = __diff if __fno==`k'
		lab var `kk' "Contribution of `kk'"
	}
	lab var __from  "ID from"
	lab var __to	 "ID to"
	lab var __stage "Stage of exclusion"
	lab var __diff  "Marginal contribution of the factor"
	lab var __weigh "Weights / no. trajectorius through"
	save `"`storing'"', replace
}
if ("`debug'" != "") di as txt "SHDeComp successful!"
c_local shdiff `shdiff'
end

program define SHFill
	version 11.2
	syntax [, names(string) saving(string) factors(string) call(string) replace ///
	 savefile(string) basefile(string) dots trace debug noisily result(string) global(string) ]
	local m: word count `names'

	if "`dots'"!="" {
		di as txt _n "Filling in the values with different factor compositions..."
		tempname m2m
		scalar `m2m' = 2^`m'
	}
	quietly {
		preserve

		// Extract "factor" varlists from `factors'
		forvalues i = 1 / `m' {
			gettoken factor`i' factors : factors, parse("()") match(par)
		}

		// parse the call
		gettoken part right: call, parse(" @") quotes
		while `"`part'"' != `"@"' & `"`part'"' != "" {
			local left `"`left' `part'"'
			gettoken part right: right, parse(" @") quotes
		}
		if `"`part'"'!=`"@"' {
			di as err "Cannot cycle across factors; put @ in the call"
			exit 198
		}
		// now, `left' is the thing up to the @, and `right', after @

		tempname ID round
		local i 1
		while `i' > 0 { // cycle over the observations in `savefile', i.e. 010110
			drop _all
			scalar `ID' = 0
			scalar `round' = 0
			cap use in `i' using `"`savefile'"'
			if c(rc)==0 { /* there are still observations in the `savefile' */
				local clist
				forvalues k = 1 / `m' {
			 		local kk : word `k' of `names'
					scalar `ID' = 2 * `ID' + `kk'
					scalar `round' = `round' + `kk'
					if `kk' {
						local clist `clist' `factor`k''
					}
				} // cycle over factors; `clist' is current list with factor==1
				drop _all
				use `"`basefile'"'
/*
	!! PR: if `clist' is empty, add a zero variable to the model
	- this avoids -stcox- going wrong, for example.
*/
			if `"`clist'"' == "" {
				cap drop SHzero
				gen SHzero = 0
				local clist SHzero
			}
			 local callit `left' `clist' `right'
			 if ("`debug'" != "") noi di as txt "The call is: " as txt "`callit'"
			 capture `noisily' `callit'
			 local rc = c(rc)
			 if `rc' != 0  {
				 noi di as err "Error in the called program! " _c 
				 if "`trace'"=="" {
					noi di as err
					exit `rc'
				 }
				 else {
					noi di as err "Look what it did:" _n(2) as txt ">> `left' `clist' `right'" _n
					noi `callit'
				 }
			 }
			 tempname res
			 scalar `res' = `global'`result'
			 drop _all
			 use in `i' using `"`savefile'"'
			 compress
			 gen double __result = `res'
			 lab var __result "`result' from `call'"
			 gen long __ID=`ID'
			 lab var __ID "Binary representation"
			 gen byte __round=`round'
			 lab var __round "Number of 1s"
			 if (`i'==1) save `"`saving'"', `replace'
			 else {
				  append using `"`saving'"'
				  save `"`saving'"', replace
			 }
			 if "`dots'"!="" {
				noi di as txt "." _c
				if ("`debug'" != "") noi di as err %4.1f `i'/`m2m'*100 "% " _c
				local j 1
				foreach step of num .1(.1)1 {
					if (`i'/`m2m'>=`step' & (`i'-1)/`m2m'<`step') noi di as txt `j'*10 "%" _c
					local ++j
				}
			 }
			 local ++i
		  } // file was succesfully opened
		  else local i=-1 // no more observations
	  } // cycle over the observations in `savefile', i.e. 010110
	  use `"`saving'"'
	  label data "Shapley: results of factor substitution in various ways"
	  compress
	  forvalues k = 1 / `m' {
	  	local namek : word `k' of `names'
		  lab var `namek' "Shapley factor"
	  }
	  save `"`saving'"', replace
	} // end of quietly; that's it, we have the results in `saving' file
	if ("`dots'"!="") di
	if ("`debug'" != "") di as txt "SHFill successful!"
end

program define SHMat01
	version 11.2
	syntax, names(string) savefile(string) [ debug ]
	tokenize `names'
	local m: word count `names'
	if `m' <= 0 {
		di as err "Wrong number of arguments in Mat01a"
		exit 198
	}
	if `m' > 56 {
		di as err "Too many factors: no more than 56"
		error 198
	}

	// scalars d* are degrees of 2
	tempname d0
	scalar `d0' = 1
	forvalues i = 1 / `m' {
		tempname d`i'
		local i1 = `i' - 1
		scalar `d`i'' = `d`i1'' * 2
		if ("`debug'" != "") di as txt `d`i1'' "*2=" `d`i''
	}
	tempname shfile
	if ("`debug'" != "") {
		di as txt "2^" as res `m' as txt "=" as res `d`m''
		postfile `shfile' `names' using `"`savefile'"'
	}
	else {
		qui postfile `shfile' `names' using `"`savefile'"'
	}

	tempname k trk
	scalar `k' = `d`m'' - 1
	while `k' >= 0 { // work out the m2m-`k'-th row of the matrix
		local i = `m' - 1
		scalar `trk' = `k'
		// truncated `k'
		local zerone
		while `i' >= 0 { // find what the `i'-th bit of `k' is
		  local zo = (`trk' - `d`i'' > -0.5)
		  local zerone `zerone' (`zo')
		  if `zo' scalar `trk' = `trk' - `d`i''
		  local --i
		}
		if ("`debug'" != "") {
			di as txt `k' ". `zerone'"
		}
		post `shfile' `zerone'
		scalar `k' = `k' - 1
	}
	postclose `shfile'
	if ("`debug'" != "") di as txt "SHMat01 successful!"
end
exit

Files created:
  `saving':
  factors  : present 1/not present 0
  __ID     : binary representation of 0/1 pattern
  __result : the corresponding result
  __round  : number of 1s in the pattern; round of exclusion = #factors - it

  `storing':
  __factor : the name of the factor
  __fno    : the number of the factors in the list
  __from   : the pattern of the parent node
  __to     : the pattern of the daughter node
  __stage  : the stage of exclusion; 0 is nothing excluded; #factors is all
             excluded
  __weight : the number of trajectories passing through
  __diff   : the marginal difference
