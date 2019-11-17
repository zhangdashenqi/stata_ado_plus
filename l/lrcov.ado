*!version 2011-Feb-24, Qunyong Wang, brynewqy@nankai.edu.cn
/*
lrcov d.(unemp hours ipman income)
*/
program lrcov , rclass
version 11.0
syntax varlist(ts fv) [if] [in] [ , noCENTer CONStant WVar(varlist) ///
	dof(integer 0) ///
	vic(string) vlag(integer 0)  ///
	KERNel(string) BWIDth(real 0) bmeth(string) blag(real 0) bweig(numlist) bwmax(real 0) BTRUnc ///
	disp(string) ]
	
	marksample touse
	markout `touse' `wvar' 
	// remove multi-collinearity variable(s) in varlist
	if "`constant'"!="" { // with constant
		qui _rmcoll `varlist' if `touse', expand
	}
	else {
		qui _rmcoll `varlist' if `touse', expand noconstant
	}
	local ynamea "`r(varlist)'"
	* remove o.x & b.x from `ynamea'
	foreach v of local ynamea {
		if ( !strmatch("`v'","*o.*") & !strmatch("`v'","*b.*") ) {
			local varnames "`varnames' `v'"
			fvrevar `v' if `touse'
			local yvars "`yvars' `r(varlist)'"
		}
	}
	* drop the duplicates macros generated from fvrevar command
	local reps: list dups yvars
	local yvars: list uniq yvars
	local reps: list uniq reps
	local yvars: list yvars - reps

	if "`constant'"!="" {
		tempname consvar
		qui gen `consvar'=1 if `touse'
		local yvars "`yvars' `consvar'"
		local varnames "`varnames' _cons"
	}
	local k: word count `yvars'
	qui count if `touse'
	local n=r(N)
	if "`matnames'"=="" local matnames "`varnames'"
	
	// some options which may be placed in the syntax
	local vconstant = ""  // VCONStant
	local vadjdof = "" // noVADJdof 
	*local divn = ""  // noDIVN, if division by obs
	local vmaxeig = .
	
	// default cases and error checking
	if "`kernel'"=="" local kernel="bartlett"
	local ifcent = cond("`center'"!="", 0, 1)  // default = 1
	*local ifdivn = cond("`divn'"!="",0,1)  // default: division by n
	local ifdivn = 1
	local vcst = cond("`vconstant'"!="", 1, 0)  // default = 0
	local vdof = cond("`vadjdof'"!="", 0, 1)  // default = 1
	*local bcst = cond("`bconstant'"!="", 1, 0)  // default = 0
	local bcst = 1
	local btru = cond("`btrunc'"!="", 1, 0)  // default = 0

	if ("`disp'"=="") local disp = "two"
	local disp = lower("`disp'")
	local dlist = "two one cont"
	local ifdv : list disp in dlist
	if (!`ifdv') {
		dis as err "disp() is not in (two one cont)"
		exit 198
	}
	
	tempname bweigm
	if ("`bweig'"=="") {
		matrix `bweigm' = J(1,`k',1)
	}
	else {
		local nkw: word count `bweig'
		if `nkw'!=`k' {
			display as err "The number of elements in bweig() is not equal to variables"
			error 198
		}
		else {
			matrix `bweigm' = J(1,`k',1)
			forvalues i=1/`k' {
				local e: word `i' of `bweig'
				matrix `bweigm'[1,`i'] = `e'
			}
		}
	}

	// LRCOV
	mata: lrcov("`yvars'", "`touse'", "`wvar'", `ifcent', `dof', "`vic'", `vlag', `vcst', `vdof', `vmaxeig', "`kernel'", `bwidth', "`bmeth'", `blag', `bcst', "`bweigm'", `bwmax', `btru', `ifdivn')

	if ("`disp'"=="") local disp = "two" 
	foreach mat of local disp {
		if "`mat'"=="two" {
			matrix rownames `Omega'=`matnames'
			matrix colnames `Omega'=`matnames'
			matlist `Omega', rowtitle("Two-sided") border(rows) noblank 
		}
		if "`mat'"=="one" {
			matrix colnames `Omegaone' = `matnames'
			matrix rownames `Omegaone' = `matnames'
			matlist `Omegaone', rowtitle("One-sided") border(rows) noblank 
		}
		if "`mat'"=="sone" {
			matrix colnames `Omegaslow' = `matnames'
			matrix rownames `Omegaslow' = `matnames'
			matlist `Omegaslow', rowtitle("Strict One") border(rows)  noblank
		}
		if "`mat'"=="cont" {
			matrix colnames `Omega0' = `matnames'
			matrix rownames `Omega0' = `matnames'
			matlist `Omega0', rowtitle("Contemp") border(rows)  noblank
		}
	}
	// save results
	foreach m in Omega Omega0 Omegaone Omegasone {
		return matrix `m' = ``m''
	}
	return local kernel = `"`kernel'"'
	if ("`kernel'"!="none") {
		return local bmeth = `"`bmeth'"'
		return scalar bwidth = `bwid'
	}
	if ("`vic'"!="") {
		return local vic = `"`vic'"'
	}
	return scalar vlag = `vlag'
end 
