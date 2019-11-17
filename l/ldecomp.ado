*! version 1.0.2 MLB 22Feb2008
* fix a bug in in the -normal- option
program define ldecomp, rclass
	version 9.0
	syntax varname [if] [in] [fw iw pw], ///
	Direct(varname)                      ///
	Indirect(varlist)                    /// 
	[                                    /// 
	OBSpr                                ///
	PREDPr                               ///
	PREDOdds                             ///
	RIndirect                            ///
	RDirect                              ///
	INTeractions                         ///
	NORMal                               ///
	LOR                                  ///
	noor                                 ///
	range(numlist min=2 max=2)           ///
	nip(integer 1000)                    ///
	]
	
	marksample touse
	markout `touse' `direct' `indirect'
	
	local wgt "[`weight'`exp']"
	if "`weight'" == "pweight" {
		local swgt "[aw`exp']"
	}
	else {
		local swgt "[`weight'`exp']"
	}
	
	if "`range'" != "" & "`normal'" == "" {
		di as err "option range() may only be specified if option normal is also specified"
		exit 198
	}
	if `nip' != 1000 & "`normal'" == "" {
		di as err "option nip() may only be specified if option normal is also specified"
		exit 198
	}
	if `: word count `indirect'' > 1 & "`normal'" != "" {
		di as err "option indirect() may contain only one variable if option normal is specified"
		exit 198
	}
	
	
// compute predicted and counterfactual proportions
	preserve
	
	qui levelsof `direct' if `touse'
	local levs "`r(levels)'"
	
	local i = 1

	tempname prop odds prop_obs distfirst assocfirst lndistfirst lnassocfirst reldir relindir
	local k : word count `levs'
	matrix `prop_obs' = J(`k',1,.)
	
	foreach lev in `levs' {
		tempvar d`lev'
		qui gen byte `d`lev'' = `direct' == `lev' if `touse'
		local dirvars "`dirvars' `d`lev''"
		if "`interactions'" != "" {
			foreach var of varlist `indirect' {
				tempvar d`lev'X`var'
				qui gen `d`lev'X`var'' = `d`lev'' * `var' if `touse'
				local dirvars "`dirvars' `d`lev'X`var''"
			}
		}
	}
	
	if "`interactions'" == "" {
		local indir "`indirect'"
	}
	else {
		local indir ""
	}
	
	qui logit `varlist' `indir' `dirvars' if `touse', nocons
	
	if "`normal'" == "" {
		foreach lev in `levs' {
			qui replace `d`lev'' = 1 if `touse'
			if "`interactions'" != "" {
				foreach var of varlist `indirect' {
					qui  replace `d`lev'X`var'' = `var' if `touse'
				}
			}
			local restvals : list levs - lev
			foreach rest in `restvals' {
				qui replace `d`rest'' = 0 if `touse'
				if "`interactions'" != "" {
					foreach var of varlist `indirect' {
						qui  replace `d`rest'X`var'' = 0 if `touse'
					}
				}
			}
			tempvar pr`lev'
			local pr "`pr' `pr`lev''"
			qui predict double `pr`lev'' if `touse', pr
			local vallab : label (`direct') `lev' 
			local vallab : subinstr local vallab " " "_", all
			local coln "`coln' association:`vallab'"
			local rown "`rown' `vallab'"
			sum `dep' if `direct' == `lev' & `touse' `swgt', meanonly
			matrix `prop_obs'[`i',1] = `r(mean)'
			local `i++'
		}
		collapse (mean) `pr' if `touse' `wgt', by(`direct')
		mkmat `pr', matrix(`prop')
	}
	
	if "`normal'" != ""{
		foreach lev in `levs' {
			tempname m`lev' sd`lev'
			qui sum `indirect' if `direct' == `lev' & `touse' `swgt'
			scalar `m`lev'' = r(mean)
			scalar `sd`lev'' = r(sd)
		}
	
		tempvar y x
	
		if "`range'" == "" {
			qui sum `indirect' if `touse' `swgt', meanonly
			local low =  r(min) - .1*(r(max) - r(min))
			local high = r(max) + .1*(r(max) - r(min))
			qui range `x' `low' `high' `nip'
		}
		else {
			qui range `x' `range' `nip'
		}
		qui gen `y' = .
		
		matrix `prop' = J(`k', `k', .)
		
		
		foreach lev in `levs' {
			local j = 1
			if "`interactions'" == "" {
				local indir "_b[`indirect']*`x' + "
				local int ""
			}
			else {
				local indir ""
				local int "+ _b[`d`lev'X`indirect'']*`x'"
			}
			foreach lev2 in `levs' {
				qui replace `y' = normalden(`x', scalar(`m`lev2''), scalar(`sd`lev2''))* ///
					          invlogit(`indir' _b[`d`lev''] `int') 
				qui integ `y' `x'
				matrix `prop'[`j', `i'] = `r(integral)'
				local `j++'	
			}
			sum `varlist' if `direct' == `lev' & `touse' `swgt', meanonly
			matrix `prop_obs'[`i',1] = `r(mean)'
			local `i++'
			local vallab : label (`direct') `lev' 
			local vallab : subinstr local vallab " " "_", all
			local coln "`coln' association:`vallab'"
			local rown "`rown' `vallab'"
			local title2 "(assuming that `indirect' is normally distributed)"
		}
	}
	
	restore	

// decompose total effect into direct and indirect effects	
	mata: decomp_lor()

// display results	
	matrix rownames `prop_obs' = `rown'
	matrix colnames `prop_obs' = "proportion"

	matrix rownames `prop' = `rown'
	matrix colnames `prop' = `coln'
	matrix rownames `odds' = `rown'
	matrix colnames `odds' = `coln'

	forvalues i= 1/`k' {
		local l = `i' + 1
		forvalues j = `l'/`k'{
			local rown2 "`rown2' `: word `j' of `levs''/`:word `i' of `levs''" 
		}
	}

	matrix colnames `distfirst'  = indirect:[i,j]/[j,j] direct:[i,i]/[i,j] total:[i,i]/[j,j]
	matrix rownames `distfirst'  = `rown2'
	matrix colnames `assocfirst' = indirect:[i,i]/[j,i] direct:[j,i]/[j,j] total:[i,i]/[j,j]
	matrix rownames `assocfirst'  = `rown2'
	
	matrix colnames `lndistfirst'  = indirect:[i,j]/[j,j] direct:[i,i]/[i,j] total:[i,i]/[j,j]
	matrix rownames `lndistfirst'  = `rown2'
	matrix colnames `lnassocfirst' = indirect:[i,i]/[j,i] direct:[j,i]/[j,j] total:[i,i]/[j,j]
	matrix rownames `lnassocfirst'  = `rown2'
	
	matrix colnames `reldir' = method_1 method_2 average
	matrix rownames `reldir' = `rown2'
	matrix colnames `relindir' = method_1 method_2 average
	matrix rownames `relindir' = `rown2'

	if "`obspr'" != "" {
		di as txt "actual proportions"
		matlist `prop_obs', underscore format(%11.3g) noblank
	}
	
	if "`predpr'" != "" {
		di as txt _n "predicted and counterfactual proportions"
		
		if "`title2'" != "" di as txt "`title2'"
		matlist `prop', underscore showcoleq(c) rowtitle("distribution") format(%11.3g) noblank
	}
	
	if "`predodds'" != "" {
		di as txt _n "predicted and counterfactual odds"

		if "`title2'" != "" di as txt "`title2'"
		matlist `odds', underscore showcoleq(c) rowtitle("distribution") format(%11.3g) noblank
	}

	if "`or'" == "" {
		di as txt _n _n"decomposition of odds ratios"
		di as txt "(method 1)"
		matlist `distfirst', format(%12.3g) tw(5) noblank
		
		di as txt _n"(method 2)"
		matlist `assocfirst', format(%12.3g) tw(5) noblank
		
		di as txt _n"Column names:"
		di as txt "i refers to the first category in the row name"
		di as txt "j refers to the second category in the row name"
		di as txt "first number in pair refers to the distribution"
		di as txt "second number in pair refers to the association"
		
		if "`: value label `direct''" != "" {
			di _n "value labels"
			foreach i in `levs' {
				di as txt %4.0f `i' " `: label (`direct') `i''"
			}
		}
	}
	
	if "`lor'" != "" {
		di as txt _n _n"decomposition of log odds ratios"
		di as txt "(method 1)"
		matlist `lndistfirst', format(%12.3g) tw(5) noblank
		
		di as txt _n"(method 2)"
		matlist `lnassocfirst', format(%12.3g) tw(5) noblank
		di as txt _n"Column names:"
		di as txt "i refers to the first category in the row name"
		di as txt "j refers to the second category in the row name"
		di as txt "first number in pair refers to the distribution"
		di as txt "second number in pair refers to the association"
		
		if "`: value label `direct''" != "" {
			di _n "value labels"
			foreach i in `levs' {
				di as txt %4.0f `i' " `: label (`direct') `i''"
			}
		}
	}

	if "`rdirect'" != "" {
		di as txt _n _n"relative importance of direct effect"
		matlist `reldir', format(%9.3g) underscore tw(5) noblank ///
		lines(columns)
	}
	
	if "`rindirect'" != "" {
		di as txt _n _n"relative importance of indirect effect"
		matlist `relindir', format(%9.3g) underscore tw(5) noblank ///
		lines(columns)
	}		

	if "`rdir'`rind'" != ""  {
		if "`: value label `direct''" != "" {
			di _n "value labels"
			foreach i in `levs' {
				di as txt %4.0f `i' " `: label (`direct') `i''"
			}
		}
	}
	
// return results	
	return matrix rindirect = `relindir'
	return matrix rdirect = `reldir'
	return matrix lnmethod2 = `lnassocfirst'
	return matrix lnmethod1 = `lndistfirst'
	return matrix method2 = `assocfirst'
	return matrix method1 = `distfirst'
	return matrix predodds = `odds'
	return matrix predpr = `prop'
	return matrix obspr = `prop_obs'
end

mata:
void decomp_lor() {
	matname = st_local("prop")
	matodds = st_local("odds")
	matdist = st_local("distfirst")
	matassoc = st_local("assocfirst")
	matlndist = st_local("lndistfirst")
	matlnassoc = st_local("lnassocfirst")
	matdir = st_local("reldir")
	matindir = st_local("relindir")
	prop = st_matrix(matname)
	odds = prop :/ (1:- prop)
	st_matrix(matodds, odds)
	distfirst = J(comb(rows(prop),2),3,.)
	k=1
	for(i=1;i<=rows(odds);i++){
		for(j=i+1;j<=rows(odds);j++) {
			distfirst[k,1] = odds[j,i]/odds[i,i]
			distfirst[k,2] = odds[j,j]/odds[j,i]
			distfirst[k,3] = odds[j,j]/odds[i,i]
			k = k + 1
		}
	}
	lndistfirst = ln(distfirst)
	st_matrix(matdist, distfirst)
	st_matrix(matlndist, lndistfirst)
	
	assocfirst = J(comb(rows(prop),2),3,.)
	k=1
	for(i=1;i<=rows(odds);i++){
		for(j=i+1;j<=rows(odds);j++) {
			assocfirst[k,1] = odds[j,j]/odds[i,j]
			assocfirst[k,2] = odds[i,j]/odds[i,i]
			assocfirst[k,3] = odds[j,j]/odds[i,i]
			k = k + 1
		}
	}
	lnassocfirst = ln(assocfirst)
	st_matrix(matassoc, assocfirst)
	st_matrix(matlnassoc, lnassocfirst)
	
	reldir = lndistfirst[.,2]:/lndistfirst[.,3],
		 lnassocfirst[.,2]:/lnassocfirst[.,3]
	reldir = reldir, (reldir[.,1] :+ reldir[.,2]):/2
	st_matrix(matdir, reldir)

	relindir = lndistfirst[.,1]:/lndistfirst[.,3],
		   lnassocfirst[.,1]:/lnassocfirst[.,3]
	relindir = relindir, (relindir[.,1] :+ relindir[.,2]):/2
	st_matrix(matindir, relindir)
}
end
