program craggit
	version 9.2
	if replay() {
		if ("`e(cmd)'" != "craggit") error 301
		Replay `0'
	}
	else	{

	//Checking data structure
	
	syntax varlist [fweight pweight] [if] [in], SECond(varlist) [	///
		Level(cilevel) CLuster(varname) HETero(varlist) *	///
	]
	gettoken lhs1 rhs1 : varlist	
	gettoken lhs2 rhs2 : second
	marksample touse
	quietly sum `lhs1' if `touse'
	local minval1 = r(min)	

	quietly sum `lhs2' if `touse'
	local minval2 = r(min)
	if `minval1'<0 | `minval2'<0 {
		di "{error:A dependant variable is not truncated at 0: {help craggit} is not appropriate}"
	}

	else	Estimate `0'

	}
end

program Estimate, eclass sortpreserve
	di ""
	di "{text:Estimating Cragg's tobit alternative}"
	di "{text:Assumes conditional independence}"
	syntax varlist [fweight pweight] [if] [in], SECond(varlist) [	///
		Level(cilevel) CLuster(varname) HETero(varlist) *	///
	]	

	mlopts mlopts, `options'
	gettoken lhs1 rhs1 : varlist
	gettoken lhs2 rhs2 : second
	if "`cluster'" != "" {
		local clopt cluster(`cluster')
	}

	//mark the estimation subsample
	marksample touse

	//perform estimation using ml
        ml model lf craggit_ll						///
                (Tier1: `lhs1' = `rhs1')				///
                (Tier2: `lhs2' = `rhs2')				///
                (sigma: `hetero')					///
                [`weight'`exp'] if `touse', `clopt' `mlopts'		///
                maximize
        ereturn local cmd craggit

        Replay, `level'
end

program Replay
        syntax [, Level(cilevel) *]
        ml display, level(`level')
end

