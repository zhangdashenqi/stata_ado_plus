  *! v.1.0.0 10aug2011 N.Orsini, M.Bottai 

capture program drop lqregplot
program define lqregplot
version 9.2

syntax anything [, GENerate(namelist max=4) Quantiles(numlist) LOptions(string) Level(integer $S_level) Reps(string) SEED(string) NOSmooth ASe * ]

if ("`e(cmd)'"!="lqreg") {
	error 301
}

if "`generate'" != "" {
	if `: word count `generate''  != 4 {
			di as err "specify 4 new variable names"
			exit 198
		}
}

// check the method for confidence interval

if ("`reps'" != "") & ("`ase'") != "" {
	di as err "specify either reps() or ase"
	exit 198
}
// check nr of bootstrap 

if "`reps'" != "" {
	local nrbs = `reps'
}
else {
	local nrbs = `e(reps)'
}

// check significance level  

			if `level' <10 | `level'>99 { 
							di in red "level() invalid"
							exit 198
							} 

	 	local l1  `level'
		local level = `level' * 0.005 + 0.50

// Logistic transformation of the bounded outcome

local depv = e(depvar) 
local depmin = e(ymin)
local depmax = e(ymax)
tempvar logity
qui gen `logity' = log((`depv'-`depmin')/(`depmax'-`depv'))   
   
local covariate "`anything'"

local nw : word count `covariate'

	if `nw' != 1 {
				di as err "specify one variable name of the previously fitted model"
				exit 198
	}

local n = e(df_r)
local typecmd = e(cmdline)

tokenize "`typecmd'" , parse(",")

local cmd "`1'"

if ("`ase'" != "") | ("`e(reps)'" == "")   {
di in gr "Asymptotic $S_level% Confidence Intervals"
	local newcmd1 : subinstr local cmd  "`e(cmd)'" "qreg"
	local newcmd2 : subinstr local newcmd1 "`depv'" "`logity'"
}
else {
di in gr "Bootstrap(" in y `nrbs' in gr") $S_level% Confidence Intervals"
	local newcmd2 "`cmd'"
}

qui est store _temp_reg_results 

local increase = 0
local currentn = c(N)

if "`quantiles'" == "" {
	numlist ".05(.01).95" , sort
	local listquantiles "`r(numlist)'"
}

if "`quantiles'" != "" {
	numlist "`quantiles'" , sort
	local listquantiles "`r(numlist)'"
}

local numberquantiles : word count `listquantiles'

if c(N) < `numberquantiles' {
			local increase = 1 
			qui set obs `numberquantiles' 
			}
			
tempvar q b  lb  ub 

qui gen  `q'  = .  
qui gen `b'  = .
qui gen `lb' = .
qui gen `ub' = .

local s = 1 
qui foreach x of local listquantiles {

di "`x'"
	replace `q' = `x' in `s'

	// set the seed
	if "`seed'" != "" {
		set seed `seed'
	}
	local seed `c(seed)'
			
	if ("`ase'" != "") | ("`e(reps)'" == "")   {
		`newcmd2', q(`x') 
		}
		else {
			`newcmd2', q(`x') reps(`nrbs')
		}
		
	replace `b' =   _b[`covariate'] in `s'
	replace `lb' = (_b[`covariate'] - abs(invttail(`n',`level'))*_se[`covariate']) in `s'
	replace `ub' = (_b[`covariate'] + abs(invttail(`n', `level'))*_se[`covariate']) in `s'
	local s = `s' + 1
	}
 
 
if "`nosmooth'" == "" {
	qui foreach k of varlist `b' `lb'  `ub'  {
			lowess `k' `q', gen(`k's) nograph `loptions'   //
		}
	}
	else {
		qui foreach k of varlist `b' `lb'  `ub'  {
		 gen `k's = `k' 
		}
	}
  
	
	 qui su `lb's 
	 local yscalemin = r(min)
	 qui su `ub's 
	 local yscalemax = r(max)
	 local step = (`yscalemax'-`yscalemin')/10
	 qui su `q'
	 local qmin = r(min)
	 local qmax = r(max)
	 local stepxl = .1	 
	 local stepmt = .05
	 local fmtxl = "%3.2fc"
	 // If quantiles are given as percentages
	 
	 if `qmin' > 1 {
					local stepxl = 5
					local stepmt = 1
				    local fmtxl = "%3.0fc"
	 }
 
if "`nosmooth'" != "" {
	tw (rcap `lb's `ub's  `q', lc(black) ) ///
	(scatter `b's `q', ms(o) mc(black) lw(medthick))  ///
	if inrange(`q',`qmin'-.001,`qmax'+.001), ///
    ylabel(`yscalemin'(`step')`yscalemax', angle(h) format(%4.3f))  ///
	xlabel(`qmin'(`stepxl')`qmax', format(`fmtxl')) xmtick(`qmin'(`stepmt')`qmax') ///
	ytitle("Estimated Coefficient") xtitle("Quantile (p)") ///
	legend(off)  title("`covariate'") name(f_`covariate', replace)  
}
else {
	two (rarea `lb's `ub's  `q', col(gs14) ) ///
	(line `b's `q', lc(black) lw(medthick) yline(0,lc(black) lp(l))) ///
	 if inrange(`q',`qmin'-.001,`qmax'+.001), ///
    ylabel(`yscalemin'(`step')`yscalemax', angle(h) format(%4.3f))  ///
	xlabel(`qmin'(`stepxl')`qmax', format(`fmtxl')) xmtick(`qmin'(`stepmt')`qmax') ///
	ytitle("Estimated Coefficient") xtitle("Quantile (p)") ///
	legend(off)  title("`covariate'") name(f_`covariate', replace)  
}
	  
 // Save new variables containing the displayed results

	if "`generate'" != "" {

		local listvarnames "`b's `lb's `ub's `q'" 
		local nnv : word count `generate' 
		tokenize `generate'

		forv i = 1/`nnv' {	
				qui gen ``i'' = `: word `i' of `listvarnames'' if `b's != . 
		}
	}
 
// Get back to previously lqreg estimates

	 qui est restore _temp_reg_results
	 qui est drop _temp_reg_results
	 
// Get back to original sample size if sample size < 100 
 
	 if (`increase' == 1) & ("`generate'" == "") {
	 qui drop in `=`currentn'+1'/l
	 qui set obs `currentn'
	 }
	 
end
exit
