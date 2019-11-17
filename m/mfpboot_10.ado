*! version 1.1.6 PR 30nov2009
program define mfpboot_10
version 8
gettoken cmd 0 : 0
frac_chk `cmd' 
if `s(bad)' {
	di as err "invalid or unrecognised command, `cmd'"
	exit 198
}
/*
	dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
	5 (xtgee), 6(ereg/weibull), 7(streg,stcox).
*/
local dist `s(dist)'
local glm `s(isglm)'
local qreg `s(isqreg)'
local xtgee `s(isxtgee)'
local normal `s(isnorm)'

global MFpdist `dist'

local stata11 = (c(stata_version) >= 11)

* Disentangle
GetVL `0'
local 0 `s(nought)'

local yvar $MFP_dv
* construct RHS for mfp. `rhs' is actual variables in use,
* `RHS' may include brackets for joint selection in mfp.
local rhs $MFP_cur
local RHS
forvalues i=1/$MFP_n {
	local v ${MFP_`i'}
	if wordcount("`v'")>1 {
		local RHS `RHS' (`v')
	}
	else local RHS `RHS' `v'
}

syntax [if] [in] [aw fw iw pw], CLEAR OUTfile(string) [ ADDpowers(str) ADJust(str) aic ///
 ALpha(str) all noBAsedata CATzero(str) CENTer(str) noCONStant CYCles(int 5) ///
 DEAD(varname) DF(str) DFDefault(int 4) noDRYrun FIXpowers(str) FP01 KEEPalso(varlist) ///
 LEVel(cilevel) POwers(str) REPLACE REPlicates(int 100) noRESample SAVing(string) ///
 noSCAling SEEd(int -1) SELect(string) SEQuential noTESTLinear XOrder(str) XPowers(str) ///
 ZERo(str) * ]

local regoptions `options'
local options

if missing("`adjust'") {
	local adjust "`center'"
}
else if !missing("`center'") {
	di as err "may not specify both adjust() and center()"
	exit 198
}
if (`replicates' < 1) & !missing("`basedata'") | (`replicates' < 0) & missing("`basedata'") {
	di as err "invalid replicates()"
	exit 198
}
if `dist' == 7 & !missing(`"`saving'"') {
	di as err "saving() not supported for st survival data"
	exit 198
}
if !missing("`keepalso'") & missing(`"`saving'"') {
	di as err "keepalso() invalid without saving()"
	exit 198
}
if `seed' > -1 {
	set seed `seed'
}

// Build up mfp options
local mfpoptions `aic' `all' `fp01' `constant' `sequential' `testlinear'
if (`cycles' != 5) 	local mfpoptions `mfpoptions' cycles(`cycles')
if (`dfdefault' != 4) 	local mfpoptions `mfpoptions' dfdefault(`dfdefault')
if (`level' != 95)  	local mfpoptions `mfpoptions' level(`level')
foreach opt in addpowers alpha catzero df fixpowers powers select xorder xpowers zero {
	if !missing("``opt''") local mfpoptions `mfpoptions' `opt'(``opt'')
}

tempvar touse
quietly {
	local nx: word count `rhs'
	marksample touse
	markout `touse' `varlist' `dead'
	if !missing("`dead'") {
		local regoptions "`regoptions' dead(`dead')"
	}
/*
	Adjustment---must be frozen here to avoid different
	adjustments in each replicate. Also store names of predictors.
*/
	frac_adj "`adjust'" "`rhs'" `touse'
	local adjust
	forvalues i = 1 / `nx' {
		local uniq`i' = r(uniq`i')
		local adj`i' `r(adj`i')'
	}
	forvalues i = 1 / `nx' {
		local v`i': word `i' of `rhs'
		local adj `adj`i''
		if ("`adj'" != "no") & !missing("`adj'") {
			if "`adj'" == "mean" {
				sum `v`i'' if `touse', meanonly
				local adj = r(mean)
			}
			else noi confirm num `adj'
		}
		local adj`i' `adj'
	}
/*
	Degrees of freedom for each variable
*/
	if !missing("`df'") {
		frac_dis "`df'" df 1 . "`rhs'"
		forvalues i = 1 / `nx' {
			if !missing("${S_`i'}") {
				local df`i' ${S_`i'}
			}
		}
	}
/*
	Assign default df for vars not so far accounted for.
	Give 1 df if 2-3 distinct values, 2 df for 4-5 values,
	dfdefault df for >=6 values.
*/
	local pb
	local failed 0
	forvalues i = 1 / `nx' {
		if missing("`df`i''") {
			if `uniq`i'' <= 3 {
				local df`i' 1
			}
			else if `uniq`i'' <= 5 {
				local df`i' = min(2,`dfdefault')
			}
			else local df`i' `dfdefault'
		}
		local np`i' = cond(`df`i'' == 1, 1, int(.1 + `df`i'' / 2))
		local xs`i' `v`i'' /* was =substr("`v`i''",1,12), abbreviation abandoned */
		forvalues j = 1 / `np`i'' {
			local pb `pb' `xs`i''p`j' `xs`i''b`j' 
		}
	}
/*
	Shift/scale/adjust: determine here,
	apply to all boot replications and store
*/
	forvalues i = 1 / `nx' {
		local sh`i' 0			/* shift */
		local sc`i' 1			/* scale */
		local V `v`i''
		if `df`i'' > 1 {
			fracgen `V' 0 if `touse', nogen `scaling'
			if r(shift) != 0 | r(scale) != 1 {
				local sh`i' = r(shift)
				local sc`i' = r(scale)
				local lab: var lab `v`i''
				lab var `v`i'' "`lab' WARNING: CHANGED"
				replace `V' = (`V' + `sh`i'') / `sc`i''
			}
		}
		if !missing("`adj`i''") {
			if "`adj`i''" != "no" {
				local a: di %9.0g (`adj`i''+`sh`i'')/`sc`i''
				local a = trim("`a'")
			}
			if missing("`adjust'") {
				local comma
			}
			else local comma ,
			local adjust `adjust'`comma'`V':`a'
		}
	}
	if !missing("`adjust'") {
		if `stata11' local adjopt center(`adjust')
		else local adjopt adjust(`adjust')
	}
	if !missing(`"`saving'"') {
		tempfile tmp0 tmp
	}
	if "`dryrun'" != "nodryrun" {
		if (`"`regoptions'"'!="") {
			local diregopts `", `regoptions'"'
		}
		local dimfpopts ", noscaling"
		if (`"`mfpoptions'"'!="") {
			local dimfpopts `dimfpopts' `mfpoptions'
		}
		if (`"`adjopt'"'!="") {
			local dimfpopts `dimfpopts' `adjopt'
		}
		if (`"`xordopt'"'!="") {
			local dimfpopts `dimfpopts' `xordopt'
		}
		if (`"`weight'"'!="") {
			local diwgt `" [`weight' `exp']"'
		}
		noi di as txt _n "Dry run of mfp ..."
		if `stata11' {
			noi di as txt _n `"mfp`dimfpopts': `cmd' `yvar' `RHS'`diwgt'`diregopts'"'
			mfp,`mfpoptions' noscaling `adjopt' `xordopt': `cmd' `yvar' `RHS' [`weight'`exp'], `regoptions'
		}
		else {
			noi di as txt _n `"mfp `cmd' `yvar' `RHS' [`weight'`exp'], `mfpoptions' `regoptions' noscaling `adjopt' `xordopt'"'
			mfp `cmd' `yvar' `RHS' [`weight'`exp'], `mfpoptions' `regoptions' noscaling `adjopt' `xordopt'
		}
	}
	noi di as txt _n "Bootstrapping ..."
	local i = cond("`basedata'" == "nobasedata", 1, 0) /* i=0 gives model for base data */
	local i0 `i'
	while `i'<=`replicates' {
		if mod(`i', 10) == 0 noi di as txt `i', _cont
		preserve
		drop if `touse'==0
		if `i' > 0 & "`resample'" != "noresample" {
			bsample
		}
		if `i' == 1 & "`resample'" == "noresample" {
			/* impose random covariate order */
			local xordopt xorder(r)
		}
		if !missing(`"`saving'"') {
			save `tmp0', replace
			cap drop i
			gen long i = `i'
			order i `yvar' `dead' `rhs' `keepalso'
			keep i `yvar' `dead' `rhs' `keepalso'
			if `i' == `i0' {
				lab var i "Boot replication"
				save `"`saving'"', replace
			}
			else save `tmp', replace
			use `tmp0', replace
		}
		if `stata11' capture mfp, `mfpoptions' noscaling `adjopt' `xordopt': ///
		 `cmd' `yvar' `RHS' [`weight'`exp'], `regoptions'
		else capture mfp `cmd' `yvar' `RHS' [`weight'`exp'], `mfpoptions' ///
		 `regoptions' noscaling `adjopt' `xordopt'
		local rc = _rc
		if `rc' == 1 {
			noisily error 1
		} 
		if `rc' == 198 {
			noisily di as err "warning: encountered syntax error in mfp"
		}
		if `rc' == 0 {
			if `i' == `i0' {	/* initialise postfile */
/*
	Handle constant. If not in model, don't attempt to save it to file.
*/
				local hascons 0
				cap local B0 = _b[_cons]
				if _rc == 0 {
					local pb `pb' b0
					local hascons 1
				}
				tempname temp
				postfile `temp' i `pb' using `outfile', `replace' double
			}
			local posts
			tokenize `e(fp_fvl)'
			forvalues j = 1 / `nx' {
				if "`e(fp_k`j')'" == "." {
					local np 0	/* var not in model */
				}
				else {
					local np: word count `e(fp_k`j')'
/*
	Screen for collinearities indicated by a missing coefficient (b)
	with a non-missing power (p). Drop variable.
*/
					forvalues k = 1 / `np' {
						local p: word `k' of `e(fp_k`j')'
						cap local b = _b[``k'']
						if ("`p'" != "." & "`p'" != "") /*
						 */ & ("`b'" == "." | "`b'" == "") {
						 	local np 0
						}
					}
					forvalues k = 1 / `np' {
						local p: word `k' of `e(fp_k`j')'
						cap local b = _b[``k'']
						if _rc {
							local b .
							local p .
						}
						local posts `posts' (`p') (`b')
					}
				}
				if `np' <`np`j'' {
					local k = `np' + 1
					forvalues kk = `k' / `np`j'' {
						local posts `posts' (.) (.)
					}
				}
				mac shift `np'
			}
			if `hascons' {
				post `temp' (`i') `posts' (_b[_cons])
			}
			else 	post `temp' (`i') `posts'
			if !missing(`"`saving'"') & `i' > `i0' {
				use `"`saving'"', replace
				append using `tmp'
				save `"`saving'"', replace
			}
			local ++i
		}
		else local ++failed
		restore
	}
	postclose `temp'
/*
	Store shift, scale and adjust values as characteristics,
	and list of variables in model.
*/
	preserve
	use `outfile', clear
	local vl
	forvalues i = 1 / `nx' {
		char `xs`i''p1[shift] `sh`i''
		char `xs`i''p1[scale] `sc`i''
		char `xs`i''p1[adjust] `adj`i''
		local vl `vl' `v`i''
	}
	char _dta[pmb_data] mfpboot
	char _dta[pmb_vl] `vl'
	compress
	save `outfile', replace
}
di _n(2) as txt "Results from original data and " as res `replicates' as txt " bootstrap replicates saved to `outfile'."
if `"`saving'"'!="" {
	di as txt "Results from original data and " as res `replicates' as txt `" bootstrap samples saved to `saving'."'
}
if `failed' > 0 {
	di as inp "[mfp failed at " as res `failed' as inp " replicates which were discarded.]"
}
end

program define GetVL, sclass /* varlist [if|in|,|[weight]] */
macro drop MFP_*
if $MFpdist != 7 {
	gettoken tok 0 : 0
	unabbrev `tok'
	global MFP_dv "`s(varlist)'"
}

global MFP_cur		/* MFP_cur will contain full term list */
global MFP_n 0

gettoken tok : 0, parse(" ,[")
IfEndTrm "`tok'"
while `s(IsEndTrm)'==0 {
	gettoken tok 0 : 0, parse(" ,[")
	if substr("`tok'",1,1)=="(" {
		local list
		while substr("`tok'",-1,1)!=")" {
			if "`tok'"=="" {
				di as err "varlist invalid"
				exit 198
			}
			local list "`list' `tok'"
			gettoken tok 0 : 0, parse(" ,[")
		}
		local list "`list' `tok'"
		unabbrev `list'
		global MFP_n = $MFP_n + 1
		global MFP_$MFP_n "`s(varlist)'"
		global MFP_cur "$MFP_cur `s(varlist)'"
	}
	else {
		unabbrev `tok'
		local i 1
		local w : word 1 of `s(varlist)'
		while "`w'" != "" {
			global MFP_n = $MFP_n + 1
			global MFP_$MFP_n "`w'"
			local i = `i' + 1
			local w : word `i' of `s(varlist)'
		}
		global MFP_cur "$MFP_cur `s(varlist)'"
	}
	gettoken tok : 0, parse(" ,[")
	IfEndTrm "`tok'"
}
sret local nought `0'
end

program define IfEndTrm, sclass
sret local IsEndTrm 1
if "`1'"=="," | "`1'"=="in" | "`1'"=="if" | /*
*/ "`1'"=="" | "`1'"=="[" {
	exit
}
sret local IsEndTrm 0
end
