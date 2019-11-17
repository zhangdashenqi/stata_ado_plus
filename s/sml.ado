********************************************************************************************************************
* Klein and Spady (1993) estimator *
* version  26/10/2005		     *
************************************

program define sml, eclass
	version 9.0
	if replay() {
		if "`e(cmd)'" ~= "ks" error 301
		Replay `0'
	}
	else Estimate `0'
end



program define Estimate, eclass

	* parse syntax 
		syntax varlist(min=2) [pw iw fw]  [if] [in], 					///
			 [noCONstant OFFset(varname numeric) From(string) 			///
			  BWidth(real 0) Level(passthru) noLOg *]
				
	* Variables definition
		tokenize `varlist'
		local lhs "`1'"
		mac shift
		local rhs "`*'"
		global predictors `rhs'

	* Selection of the sample 
		marksample touse	
		markout `touse' `offset'				

	* Check estimation sample
		if r(N) == 0 { 
			error 2000 
		}

	* Options 
		local nc `constant'
		if "`offset'"  != "" local off "offset(`offset')" 
		if "`weight'" != "" local wgt [`weight'`exp']
		mlopts mlopts, `options'
		di in gr "`mlopts'"

	* From option and starting values 
		if "`from'" == "" {
			cap probit `lhs' `rhs' `wgt' if `touse', `nc' `off'
			tempname b0
			matrix `b0'=e(b)
			local from "`b0', skip"
		}

	* Bandwidth parameter option 
		if "`bwidth'" == "" | "`bwidth'" == "0" {
			qui count if `touse'	
			global bwidth = 1/(r(N)^(1/6.02))
		}
		else {
			if `bwidth' > 0 global bwidth=`bwidth'
			if `bwidth' <= 0 {
				di in red "Bandwidth parameter must be a positive value"
				exit 411
			}
		}

	* Estimation 
		ml model d2 sml_ll ("`lhs'": `lhs'=`rhs', noconst `off') `wgt' if `touse', 	///
				max nopreserve difficult init(`from') search(off) 			///
				title("SML Estimator - Klein & Spady (1993)") `log'  `mlopts' 

	* Estimation return
		ereturn local cmd "sml"
		ereturn scalar bwidth=$bwidth

	* Display estimates
		Replay, `level' 
end



program define Replay
	syntax [, Level(int $S_level)]
	ml display, level(`level')
end 



