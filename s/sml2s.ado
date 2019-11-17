************************************
* Author: Giuseppe De Luca
* Version 1
* date: 23/12/2006
* Title: SML2 estimator
* version  26/10/2005
************************************



************************************************************************
program define sml2s, eclass
	version 9.0
	if replay() {
		if "`e(cmd)'" ~= "sml2s" error 301
		Replay `0'
	}
	else Estimate `0'
end
************************************************************************



************************************************************************
program define Estimate, eclass

	* Dependent variable
		gettoken depvar 0 : 0 , parse(" =,[")
		gettoken equals rest : 0 , parse(" =")
		if "`equals'" == "=" local 0 `"`rest'"'
		local depvarn : subinstr local depvar "." "_"

	* parse syntax 
		syntax varlist(min=1) [pw fw iw] [if] [in], SELect(string)				///
			 [noCONstant OFFset(varname numeric) From(string) 				///
			  bwidth1(real 0) bwidth2(real 0) Level(passthru) noLOg *]

	* Identify Selection equation 
		Select seldep selind selnc seloff : `"`select'"'
		local selname : subinstr local seldep "." "_"


	* Options 
		local nc `constant'
		local snc `selnc'
		if "`seloff'"  != "" local soff "offset(`seloff')" 
		if "`offset'"  != "" local off "offset(`offset')" 
		if "`weight'" != "" local wgt [`weight'`exp']
		mlopts mlopts, `options'
		di in gr "`mlopts'"

	* Identify estimation sample 
		marksample touse, novarlist
		markout `touse' `seldep' `selind' `seloff' `cluster', strok
		marksample touse2
		markout `touse2' `depvar' `varlist' `offset'
		qui replace `touse' = 0 if `seldep' & !`touse2'

	* Check estimation sample 
		qui count if `touse' 
		if r(N)==0 error 2000 
		qui count if `touse2' 
		if r(N)==0 error 2000 
		
	* Check bandwidth parameters 
		if "`bwidth1'" == "" | "`bwidth1'" == "0" {
			qui count if `touse'
			global bw1 = 1/(r(N)^(1/6.5))
		}
		else {
			if `bwidth1' > 0 global bw1=`bwidth1'
			if `bwidth1' <= 0 {
				di in red "Bandwidth parameter must be positive"
				exit 411
			}
		}

		if "`bwidth2'" == "" | "`bwidth2'" == "0" {
			qui count if `touse2'
			global bw2 = 1/(r(N)^(1/6.5))
		}
		else {
			if `bwidth2' > 0 global bw2=`bwidth2'
			if `bwidth2' <= 0 {
				di in red "Bandwidth parameter must be positive"
				exit 411
			}
		}

	* From option and starting values 
		if "`from'" == "" {
		* Starting values main parameters
			local vareq2 `"`varlist'"'
			tokenize `vareq2'
			local k2: word count `vareq2'
			local vareq1 `"`selind'"'
			tokenize `vareq1'
			local k1: word count `vareq1'
			local j=`k2'+2
			local k=`k2'+`k1'+1
			cap heckprob `depvar' `varlist' `wgt' if `touse', `nc' `off'	///
				  sel(`seldep'=`selind', `snc' `soff')
			if "`nc'"!="" {
				local j=`j'-1
				local k=`k'-1
			}
  			tempname b00 b0 b1 b2
			matrix `b00' = e(b)
			matrix `b1' = `b00'[1..1,1..`k2']
			matrix `b2' = `b00'[1..1,`j'..`k']
			matrix `b0' = (`b1' , `b2')
			local from "`b0', skip"
		}


	* Estimation 
		ml model d0 sml2s_ll 	(`depvarn':`depvar'=`varlist', noconst `off') 		///
						(`selname':`seldep'=`selind' , noconst `soff')		///
						if `touse', miss nopreserve max difficult			///
						init(`from') search(off) `log'  `mlopts'			///
						title("Two-stage SML estimator - Lee (1995)") 

	* Estimation return
		ereturn local cmd "sml2s"
		ereturn scalar bwidth1=$bw1
		ereturn scalar bwidth2=$bw2

	* Display estimates
		Replay, `level' 
end
************************************************************************



************************************************************************
program define Replay
	syntax [, Level(int $S_level)]
	ml display, level(`level')
end 
************************************************************************





************************************************************************
program define Select
	args seldep selind selnc seloff colon sel_eqn

	gettoken dep rest : sel_eqn, parse(" =")
	gettoken equal rest : rest, parse(" =")

	if "`equal'" == "=" { 
		tsunab dep : `dep'
		c_local `seldep' `dep' 
	}
	else	local rest `"`sel_eqn'"'
	
	local 0 `"`rest'"'
	syntax [varlist(numeric default=none ts)] 	/*
		*/ [, noCONstant OFFset(varname numeric) ]

	if "`varlist'" == "" {
		di in red "no variables specified for selection equation"
		exit 198
	}

	c_local `selind' `varlist'
	c_local `selnc' `constant'
	c_local `seloff' `offset'
end
*****************************************************************************




