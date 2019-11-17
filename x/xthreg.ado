*! version 2014-Jan-9, QunyongWang@outlook.com
* use hansen1999, clear
* xthreg i q1 q2 q3 d1 qd1, rx(c1) qx(d1) thnum(1) trim(0.05) grid(300) bs(300)
* xthreg depr drgdp, rx(dcpi) qx(dcpi) thnum(1) trim(0.05) grid(300) bs(100)
program xthreg, eclass
version 13.0
syntax varlist(numeric ts) [if] [in], rx(varlist numeric ts) qx(varname numeric ts) ///
	[ THnum(integer 1) Trim(numlist) Grid(integer 300) bs(numlist) ///
	gen(string) THLevel(real 95) noBSLOG noREG ///
	THGiven * ]
	if (`thnum'<=0 | `thnum'>3) {
		dis as error "number of threshold must be positive integer and less than 3!"
		exit(198)
	}
	tempname trimb bsb mthgiv
	if "`trim'"=="" {
		matrix `trimb'=J(`thnum',1,0.01)
	}
	else {
		local ntrim: word count `trim'
		if (`ntrim'!=`thnum') {
			dis as error "number of parameters in trim() is not equal to thnum()!"
			exit(198)
		}
		matrix `trimb' = J(`thnum',1,.)
		forvalues i=1/`ntrim' {
			local el: word `i' of `trim'
			matrix `trimb'[`i',1]=`el'
		}
	}
	if "`bs'"=="" {
		matrix `bsb'=J(`thnum',1,0)
		local bsnum = 0
	}
	else {
		local niter: word count `bs'
		if (`niter'!=`thnum') {
			dis as error "number of parameters in bs() is not equal to thnum()!"
			exit(198)
		}
		matrix `bsb' = J(`thnum',1,0)
		local bsnum = 0
		forvalues i=1/`thnum' {
			local el: word `i' of `bs'
			matrix `bsb'[`i',1]=`el'
			local bsnum = `bsnum'+`el'
		}
	}
	
	tsrevar `varlist'
	local varlist2=r(varlist)
	tsrevar `rx'
	local rx2=r(varlist)
	tsrevar `qx'
	local qx2=r(varlist)

	tsunab varlist3: `varlist'
	gettoken dep indeps: varlist3
	local indeps=trim("`indeps'")
	tsunab rx3: `rx'
	tsunab qx3: `qx'
	
	/* Gen sample variable specified by if & in */
	marksample touse
	markout `touse' `varlist' `rx' `qx'
	
	/* Check whether this is balanced panel */
	qui xtdes if `touse'
	if r(sd)>0 {
		dis as err "Panel threshold model need balanced panel, check your data!"
		exit
	}
	local t = r(mean)
	local n = r(N)
	qui xtset
	local ivar=r(panelvar)
	local tvar=r(timevar)
	local tmin=r(tmins)
	local tmax=r(tmaxs)
	/* Check whether there exist time-invarying variables */
	local tiv=0
	local j=1
	foreach v of varlist `varlist' `rx' `qx' {
		tempvar ct`j'
		local vname: word `j' of `varlist2' `rx2' `qx2'
		qui bysort `ivar': egen `ct`j''=sd(`vname')
		qui count if `ct`j''!=0 
		if r(N)==0 {
			local tiv=`tiv'+1
			dis as err "There exist time-invaying variable:" as res " `v'"
	*		continue, break
		}
		local j=`j'+1
	}
	if `tiv'>0 exit	
	if "`bslog'"=="" local iflog = 1
	else local iflog = 0
	// estimation using mata function
	//set trace on
	local thn = e(thnum)
	if ("`thgiven'"=="") {
		local thn = 0
		mata: thestm(`t', "`varlist3'", "`rx3'", "`qx3'", "`touse'", `thnum', `grid', "`trimb'", `thlevel'/100, "`bsb'", `iflog')
	}
	else if missing(`thn') {
		dis in gr "There is no stored estimation result, xthreg will omit thgiven option"
		mata: thestm(`t', "`varlist3'", "`rx3'", "`qx3'", "`touse'", `thnum', `grid', "`trimb'", `thlevel'/100, "`bsb'", `iflog')
	}
	else {
		tempname thexist fexist
		if `thn'==1 {
			tempname Lr1
			matrix `Lr1' = e(LR)
		}
		else {
			tempname Lr1 Lr21 Lr22
			matrix `Lr1' = e(LR)
			matrix `Lr21' = e(LR21)
			matrix `Lr22' = e(LR22)
		}
		matrix `thexist' = e(Thrss)
		matrix `fexist' = e(Fstat)
		mata: thestm(`t', "`varlist3'", "`rx3'", "`qx3'", "`touse'", `thnum', `grid', "`trimb'", `thlevel'/100, "`bsb'", `iflog', "`thexist'")
	}
	
	// e(LR_i_j),e(SeRSS_i_j), e(Thcoef)
	if "`thgiven'"!="" & !missing(`thn') {
		local nrow  = rowsof(`thexist') 
		matrix `Thrss'[1, 1] = `thexist'
		matrix `Fstat'[1, 1] = `fexist'
	}
	matrix colnames `Thrss' = Threshold RSS Location Lower Upper 
	if `bsnum'>0 {
		matrix colnames `Fstat' = RSS MSE Fstat Prob Crit10 Crit5 Crit1
	}
	if (`thnum'==1) {
		matrix rownames `Thrss' = Th-1
		matrix rownames `Fstat' = Single
		matrix colnames `LR' = LR Threshold
	}
	else if (`thn'<=1 & `thnum'>=2) {
		matrix rownames `Thrss' = Th-1 Th-21 Th-22
		matrix rownames `Fstat' = Single Double
		matrix colnames `LR21' = LR Threshold
		matrix colnames `LR22' = LR Threshold
	}
	if (`thnum'==3) {
		matrix rownames `Thrss' = Th-1 Th-21 Th-22 Th-3
		matrix rownames `Fstat' = Single Double Triple
		matrix colnames `LR3' = LR Threshold
	}
	// display some information
	dis _n in gr "Threshold estimator (level = `thlevel'):"
	tempname Thrssdisp
	matrix `Thrssdisp' = `Thrss'[1...,1],`Thrss'[1...,4..5]
	local r = rowsof(`Thrssdisp')-1
	local rf "--"
	forvalues i=1/`r' {
		local rf "`rf'&"
	}
	local rf "`rf'-"
	local cf "& %10s | %12.4f & %12.4f & %12.4f &"
	matlist `Thrssdisp', cspec(`cf') rspec(`rf') noblank rowtitle("model")

	if `bsnum'>0 {
		dis _n in gr "Threshold effect test (bootstrap = `bs'):"
		local r=rowsof(`Fstat')-1
		local rf "--"
		forvalues i=1/`r' {
			local rf "`rf'&"
		}
		local rf "`rf'-"
		local cf "& w8 %10s | w8 %9.4f & w7 %9.4f & w7 %9.2f & w6 %6.4f & w6 %7.4f & w6 %7.4f & w6 %7.4f &"
		matlist `Fstat', cspec(`cf') rspec(`rf') noblank rowtitle("Threshold")
	}

	// post-estimation 
	if "`reg'"=="" {
		if `thnum'==1 {
			local ths = "`=el(`Thrss',1,1)'"
		}
		else if `thnum'==2  {
			local ths = "`=el(`Thrss',2,1)' `=el(`Thrss',3,1)'"
		}
		else if `thnum'==3  {
			local ths = "`=el(`Thrss',2,1)' `=el(`Thrss',3,1)' `=el(`Thrss',4,1)'"
		}
		qui numlist "`ths'", sort
		local ths=r(numlist)
		local ths: subinstr local ths " " ",", all
		if "`gen'"=="" local gen = "_cat"
		capture drop `gen'
		qui gen `gen'=irecode(`qx',`ths') if `touse'
		xtreg `varlist3' i.`gen'#c.(`rx3') if `touse', fe `options'
	}
	// return results
	ereturn matrix Thrss `Thrss'
	ereturn matrix Fstat `Fstat'
	ereturn matrix trim=`trimb'
	ereturn matrix bs=`bsb'
	ereturn local ix `"`indeps'"'
	ereturn local rx `"`rx3'"'
	ereturn local qx `"`qx3'"'
	ereturn local ivar `"`ivar'"'
	ereturn scalar grid=`grid'
	ereturn scalar thnum=`thnum'
	if "`thgiven'"!="" & !missing(`thn')  {
		ereturn matrix LR = `Lr1'
		if `thn'==2 & `thnum'==3 {
			ereturn matrix LR21 = `Lr21'
			ereturn matrix LR22 = `Lr22'
		}
	}
	if (`thnum'==1) {
		ereturn matrix LR `LR'
	}
	else if (`thn'<=1 & `thnum'>=2) {
		ereturn matrix LR21 `LR21'
		ereturn matrix LR22 `LR22'
	}
	if (`thnum'==3) {
		ereturn matrix LR3 `LR3'
	}
end
