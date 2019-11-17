capture program drop margin
program define margin
*! Average marginal effects for categorical and limited dependent variable models
*! This version: 28 October 2004 - Author: Tamas Bartus

	if int(_caller())<6 {
		di in r "-margin- does not support this version of Stata"
		exit
	}
	if int(_caller())<8 {
		margin6 `0'
	}
	else margin8 `0'
end
	

program define margin8 , eclass
	version 8

*******************************************************************************
*
* [1] SYNTAX CHECK, ESTIMATION
*
*******************************************************************************	

	if "`e(cmd)'"=="" {
		di in r "Last estimates not found"
		exit 301
	}
	if "`e(cmd)'"!="margin" {
		if `e(df_m)'==0  {
			di in r "There are no independent variables; running -margin- makes no sense"
			exit
		}
	}

	syntax [ , Count Model(string) Eform Dummies(string) Percent Replace  Table NOOFFset trace hascons mean]
	local Doit = ("`model'`count'`eform'`dummies'`table'`nooffset'`hascons'`mean'"!="")|("`e(margin_cmd)'"=="")
	if "`e(cmd)'"=="margin" {
		local Doit = 0
	}

	if `Doit'==1 {	/* START OF ESTIMATION */
		if "`eform'"!="" {
			local length : word count `e(depvar)'
			if `length'>1 {
				di in r "The eform option can only be used after single-equation commands"
				exit
			}
		}
   		if "`model'"=="" {
			local model = e(cmd)
		}
		
		SetEnv `model' `eform' /* Checks model & sets environment */

		if "`s(type)'"=="0" {
			di in r "-margin- does not work with `model'; use -mfx- instead"
			exit
		}
		if "`dummies'"!="" {
			local dummies dummies(`dummies')
		}

		preserve
		margin_e `depvar' , `eform' `table' `dummies' `count' `nooffset' `trace' `hascons' `mean'
		restore

	}  /* END OF ESTIMATION */

	
*******************************************************************************
*
* [2] COLLECTING AND DISPLAYING RESULTS
*
*******************************************************************************	

	tempname b V bpost Vpost tab
	tempvar touse
	
	local Prefix margin_
	local Class e
	if "`e(cmd)'"=="margin"	 {
		local Prefix
	}
	else if `Doit'==1 {
		local Class r
	}

	mat `b' = `Class'(`Prefix'b)
	mat `V' = `Class'(`Prefix'V)
	mat `tab' = `Class'(margin_tab)
  	local depvar = `Class'(margin_depv)
  	local title  = `Class'(margin_title)
  	local cmd    = `Class'(margin_cmd)
	
	local numobs = e(N)
	qui gen byte `touse' = e(sample)
	local mdf  = e(df_m)
	local rdf  = e(df_r)
	if `rdf'!=. {
		local df "dof(`rdf')"
	}
	if "`depvar'"!="" {
		local depname depname(`depvar')
	}

	* Display form (avoiding double percentages)

	local dispform asis
	if `"`e(margin_display)'"'=="percent" {
		local percent
		local dispform percent
	}
	if `"`e(margin_display)'"'!="percent" & "`percent'"!="" {
		local percent  percent
		local dispform percent
	}

	if  "`percent'"!="" {
		mat `b' = 10^2 * `b'
		mat `V' = 10^4 * `V'
	}
	
	mat `bpost' = `b'
	mat `Vpost' = `V'

	if  "`replace'"=="" {
		tempname ehold
		_est hold `ehold'
	}
	
	di
	di in g "Marginal effects on " in y "`title'" in g " after " in y "`cmd'"
	di
	ereturn post `bpost' `Vpost' , `df' `depname' obs(`numobs') esample(`touse')
	ereturn disp

	if  "`replace'"=="" {
		_est unhold `ehold'
	} 
	else {
		ereturn local cmd      margin
		ereturn scalar df_m =  `mdf'
		if `rdf'!=. {
			ereturn scalar df_r = `rdf'
		}
	}			   
	ereturn mat   margin_b        `b'
	ereturn mat   margin_V        `V'
	ereturn mat   margin_tab      `tab'
	ereturn local margin_display  `dispform'
	ereturn local margin_title    `title'
	ereturn local margin_depv     `depvar'
	ereturn local margin_cmd      `cmd'

	if "`table'"!="" {
		if "`percent'"!="" {
			local format %12.2f
		}
		else local format %20.5f
		di _newline(2) in g "Descriptive statistics for individual marginal effects"
		di
		mat list e(margin_tab) , noblank nohalf noheader format(`format')
	}

end


program define SetEnv , sclass
	version 6
	sret clear
	sret local model "`1'"
	sret local ncons 1
	if "`2'"!="" {
		sret local type 9
		sret local neq  1
		sret local nout 1
		sret local nap  0
		exit
	}
	else if "`1'"=="logit"    | "`1'"=="logistic" | "`1'"=="probit"  | "`1'"=="cloglog" | /*
		*/  "`1'"=="poisson" {
		sret local nout 1
		sret local type 1
		sret local neq  1
		sret local nap  0
		exit
	}
	else if "`1'"=="xtprobit" | "`1'"=="xtlogit"  | "`1'"=="nbreg" | /*
		*/  "`1'"=="tobit"    | "`1'"=="cnreg"    | "`1'"=="intreg"  | "`1'"=="truncreg"  {
		sret local nout 1
		sret local type 1
		sret local neq  1
		sret local nap  1
		exit
	}
 	else if "`1'"=="oprobit"  | "`1'"=="ologit" {
		qui tab `e(depvar)'	if e(sample)
		local ncons = e(k_cat)-1
		local nout = r(r)
		sret local ncons `ncons'
		sret local neq  1
		sret local nout `nout'
		sret local type 2
		sret local nap `ncons'
		exit
	}
	else if "`1'"=="mlogit" | "`1'"=="gologit"  {
		qui tab `e(depvar)' if e(sample)
		local neq = r(r)-1
		local nout = r(r)
		sret local ncons 1
		sret local neq  `neq'
		sret local nout `nout'
		sret local type 2
		sret local nap  0
		exit
	}
	else if "`1'"=="heckman"  | "`1'"=="heckprob" | /*
		*/  "`1'"=="biprobit"  | "`1'"=="zip"      | "`1'"=="zinb"       {
		local neq = 2
		local nout = 1 + ("`1'"=="biprobit")*3 + (substr("`1'",1,2)=="zi")*2
		local type = 3
		if "`1'"=="biprobit" {
			if substr(e(title),1,1)=="B" {
				local type = 2
			}
			*else local nout 1
			else local type 0
		}

		sret local neq `neq'
		sret local nout `nout'
		sret local type `type'
		if "`1'"=="heckman" {
			sret local nap 2
		}
		else if "`1'"=="zip" {
			sret local nap 0
		}
		else sret local nap 1
		exit
	}
	else sret local type 0
end

