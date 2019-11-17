*! version 1.2.0  18JUN2011
capture program drop dea
program define dea, rclass
    version 11.0
	
/** HISTORY:
 * -----------------------------------------------------------------------------
 * 2012-09-22(SAT): Add FDH(Free Disposal Hull) Model
 * ---------------------------------------------------------------------------*/
 
/** Terms Description:
 * -----------------------------------------------------------------------------
 * RTS: Return To Scale
 * CRS: Constant Return to Scale
 * VRS: Variant Return to Scale
 * IRS: Increasing Return to Scale
 * DRS: Decreasing Retrn to Scale
 * ---------------------------------------------------------------------------*/
 
// syntax checking and validation-----------------------------------------------
// rts - return to scale, ort - orientation
// input varlist = output varlist
// example:
//     dea Employee Area = Sales Profits, rts(CRS) ort(IN) tol1(1e-14)
//     dea Employee Area = Sales Profits, sav
// -----------------------------------------------------------------------------
    // returns 1 if the first nonblank character of local macro `0' is a comma,
    // or if `0' is empty.
	if replay() {
        dis as err "ivars and ovars required."
        exit 198
    }

    // get and check invarnames
	gettoken word 0 : 0, parse("=,")
    while ~("`word'" == ":" | "`word'" == "=") {
        if "`word'" == "," | "`word'" == "" {
                error 198
        }
        local invarnames `invarnames' `word'
        gettoken word 0 : 0, parse("=,")
    }
    unab invarnames : `invarnames'

    #del ;
    syntax varlist(min=1) [if] [in] [using/]
    [,
        RTS(string)         // ignore case sensitive,[{CRS|CCR}|{BCC|VRS}|DRS|IRS]
        ORT(string)         // ignore case sensitive,[{IN|INPUT}|{OUT|OUTPUT}]
        STAGE(integer 2)    // stage 1 or 2
		FDH		    		// Free Disposal Hull
		
        TOL1(real 1e-14)    // entering or leaving value tolerance
        TOL2(real 1e-8) 	// B inverse tolerance: 2.22e-12
        TRACE               // Whether or not to do the log
        SAVing(string)      // log file name
        REPLACE             // Whether or not to replace the log file

		Bounded(varlist)    // bounded variables list
		ORDinal(varlist)    // order variables list
		CAtegorical(varlist)// categorical variables list
    ];
    #del cr

    local num_invar : word count `invarnames'
    local i 1
    while (`i'<=`num_invar') {
        local invarn : word `i' of `invarnames'
        local junk : subinstr local invarnames "`invarn'" "", ///
            word all count(local j)
        if `j' > 1 {
            di as error ///
                "cannot specify the same input variable more than once"
            error 498
        }
        local i = `i' + 1
    }

    // default model - CRS(Constant Return to Scale)
    if ("`rts'" == "") local rts = "CRS"
    else {
        local rts = upper("`rts'")
        if ("`rts'" == "CCR") local rts = "CRS"
        else if ("`rts'" == "BCC") local rts = "VRS"
        else if (~("`rts'" == "CRS" | "`rts'" == "VRS" | ///
                   "`rts'" == "DRS" | "`rts'" == "IRS")) {
            di as err "option rts allow for case-insensitive " _c
            di as err "CRS (eq CCR) or VRS (eq BCC) or DRS or IRS or nothing."
            exit 198
        }
    }

    // default orientation - Input Oriented
    if ("`ort'" == "") local ort = "IN"
    else {
        local ort = upper("`ort'")
        if ("`ort'" == "I" | "`ort'" == "IN" | "`ort'" == "INPUT") {
            local ort = "IN"
        }
        else if ("`ort'" == "O" | "`ort'" == "OUT" | "`ort'" == "OUTPUT") {
            local ort = "OUT"
        }
        else {
            di as err "option ort allows for case-insensitive " _c
            di as err "(i|in|input|o|out|output) or nothing."
            exit 198
        }
    }

    // default stage - 1
    if (~("`stage'" == "1" | "`stage'" == "2")) {
        dis as err "option stage allows 1 or 2 or nothing exclusively."
        exit 198
    }

    if ("`using'" != "") use "`using'", clear
    if (~(`c(N)' > 0 & `c(k)' > 0)) {
        dis as err "dataset required!"
        exit 198
    }

// end of syntax checking and validation ---------------------------------------

    set more off
    capture log close dealog
    log using "dea.log", replace text name(dealog)
    preserve

    if ("`if'" != "" | "`in'" != "") {
        qui keep `in' `if'  // filtering : keep in range [if exp]
    }

	if ("`bounded'" != "" | "`ordinal'" != "" | "`categorical'" != "") {
		idea, ivars(`invarnames') ovars(`varlist') ///
			  rts(`rts') ort(`ort') stage(`stage') ///
			  tol1(`tol1') tol2(`tol2') 		   ///
			  `trace' saving(`saving') `replace' ///
			  b(`bounded') ord(`ordinal') ca(`categorical')
	}
	else {
		deanormal, ivars(`invarnames') ovars(`varlist') ///
				   rts(`rts') ort(`ort') stage(`stage') `fdh' ///
				   tol1(`tol1') tol2(`tol2') ///
				   `trace' saving(`saving') `replace'
	}
    return add
	set more on
	
    restore, preserve
    log close dealog
end

********************************************************************************
* DEA Normal - Data Envelopment Analysis Normal
********************************************************************************
program define deanormal, rclass
    #del ;
    syntax , IVARS(string) OVARS(string) RTS(string) ORT(string)
    [
        STAGE(integer 2) FDH TOL1(real 1e-3) TOL2(real 1e-12)
        TRACE SAVing(string) REPLACE DMUI(integer 0)
    ];
    #del cr

    preserve
    // di _n as input ///
    //     "options: RTS(`rts') ORT(`ort') STAGE(`stage') SAVing(`saving')"
    // di as input "Input Data:"
    // list

    // -------------------------------------------------------------------------

    tempname dmuIn dmuOut frameMat ///
			 deamainrslt dearslt fdhrslt vrsfrontier crslambda
    mkDmuMat `ivars', dmumat(`dmuIn') sprefix("i")
    mkDmuMat `ovars', dmumat(`dmuOut') sprefix("o")
    local dmuCount = colsof(`dmuIn')
    if ("`ort'" == "OUT") local minrank = 1
    else local minrank = 0

    mata: _mkframemat("`frameMat'", "`dmuIn'", "`dmuOut'", ///
            "`rts'", "`ort'")
    deamain `dmui' `dmuIn' `dmuOut' `frameMat' `rts' `ort' `stage' ///
            `tol1' `tol2' `trace'
    matrix `deamainrslt' = r(deamainrslt)

    mata: _dmurank("`deamainrslt'", ///
            `=rowsof(`dmuIn')', `=rowsof(`dmuOut')', `minrank', `tol2')
    matrix `dearslt' = r(rank), `deamainrslt'

    // use mata function '_setup_dearslt_names' because the maximum string
    // variable length needs to be kept under the 244 for all the time
    mata: _setup_dearslt_names("`dearslt'", "`dmuIn'", "`dmuOut'")

    if ("`rts'" == "VRS") {
        // caution : join order! (CRS -> VRS -> DRS)
        // 1. VRS TE(VRS Technical Efficiency)
        matrix `deamainrslt' = r(deamainrslt)
        matrix `vrsfrontier' = `deamainrslt'[1...,1]

        // 2. CRS TE(CRS Technical Efficiency)
        local stageForVRS = 2
        mata: _mkframemat("`frameMat'", "`dmuIn'", "`dmuOut'", ///
                "CRS", "`ort'")
        deamain `dmui' `dmuIn' `dmuOut' `frameMat' "CRS" `ort' `stageForVRS'  ///
                `tol1' `tol2' `trace'
        matrix `deamainrslt' = r(deamainrslt)
        matrix `vrsfrontier' = `deamainrslt'[1...,1], `vrsfrontier'
        matrix `crslambda' = `deamainrslt'[1...,2..(`dmuCount' + 1)]

        // 3. DRS TE(DRS Technical Efficiency)
        local stageForVRS = 1
        mata: _mkframemat("`frameMat'", "`dmuIn'", "`dmuOut'", ///
                "DRS", "`ort'")
        deamain `dmui' `dmuIn' `dmuOut' `frameMat' "DRS" `ort' `stageForVRS' ///
                `tol1' `tol2' `trace'
        matrix `deamainrslt' = r(deamainrslt)
        matrix `vrsfrontier' = `vrsfrontier', `deamainrslt'[1...,1] // VRS
        mata: _roundmat("`vrsfrontier'", 1e-14) // round off

        //
        matrix `vrsfrontier' = `vrsfrontier', J(rowsof(`vrsfrontier'), 2, 0)
        matrix rownames `vrsfrontier' = `: colfullnames `dmuIn''
        matrix colnames `vrsfrontier' = CRS_TE VRS_TE DRS_TE SCALE RTS

        if ("`trace'" == "trace") matrix list `crslambda'
        forvalues i = 1/`=rowsof(`vrsfrontier')' {
            matrix `vrsfrontier'[`i',4] = /*
                */ float(`vrsfrontier'[`i',1]/`vrsfrontier'[`i',2])

            /*******************************************************************
             * if CRS(CCR) == VRS(BCC) then CRS
             * else
             *     if sum of ル equals to 1, then CRS mark
             *     if sum of ル is greater than 1, then DRS mark
             *     if sum of ル is less than 1, then IRS mark
             ******************************************************************/
            // (-1:drs, 0:crs, 1:irs)
            if (`vrsfrontier'[`i',1] == `vrsfrontier'[`i',2]) {
                matrix `vrsfrontier'[`i',5] = 0
            }
            else {
                local sumlambda = 0
                forvalues j = 1/`dmuCount' {
                    if (`crslambda'[`i', `j'] < .) {
                        local sumlambda = `sumlambda' + `crslambda'[`i', `j']
                    }
                }
                if (`sumlambda' < 1) {
                    matrix `vrsfrontier'[`i',5] = 1 // irs mark
                }
                else { // if (`sumlambda' >= 1) {
                    matrix `vrsfrontier'[`i',5] = -1 // drs mark
                }
            }
        }
    }
	
	// apply FDH
	if ("`fdh'" != "") {
		apply_fdh `dmuIn' `dmuOut' `ort' `stage' `frameMat' `trace'
		matrix `fdhrslt' = r(fdhrslt)
		
		mata: _dmurank("`fdhrslt'", ///
            `=rowsof(`dmuIn')', `=rowsof(`dmuOut')', `minrank', `tol2')
    	matrix `fdhrslt' = r(rank), `fdhrslt'

    	// use mata function '_setup_dearslt_names' because the maximum string
    	// variable length needs to be kept under the 244 for all the time
    	mata: _setup_dearslt_names("`fdhrslt'", "`dmuIn'", "`dmuOut'")
	}

    // -------------------------------------------------------------------------
    // REPORT
    // -------------------------------------------------------------------------
    di as result ""
    di as input "options: RTS(`rts') ORT(`ort') STAGE(`stage')"
    di as result "`rts'-`ort'PUT Oriented DEA Efficiency Results:"
    matrix list `dearslt', noblank nohalf noheader f(%9.6g)
    
    if ("`fdh'" != "") {
    	di as result ""
    	di as input "options: ORT(`ort') STAGE(`stage')"
    	di as result "`rts'-`ort'PUT Oriented DEA Efficiency(FDH) Results:"
    	matrix list `fdhrslt', noblank nohalf noheader f(%9.6g)
    }

    if ("`saving'" != "") {
        // if the saving file exists and replace option not specified, 
        // make the backup file.
        if ("`replace'" == "") {
            local dotpos = strpos("`saving'",".")
            if (`dotpos' > 0) {
                mata: _file_exists("`saving'")
            }
            else {
                mata: _file_exists("`saving'.dta")
            }
            if r(fileexists) {
                local curdt = subinstr("`c(current_date)'", " ", "", .) + /*
                    */ subinstr("`c(current_time)'", ":", "", .)
                if (`dotpos' > 0) {
                    #del ;
                    local savefn = substr("`saving'", 1, `dotpos' - 1) +
                                   "_bak_`curdt'" +
                                   substr("`saving'",`dotpos', .);
                    #del cr
                    qui copy "`saving'" "`savefn'", replace
                }
                else {
                    local savefn = "`saving'_bak_`curdt'" + ".dta"
                    qui copy "`saving'.dta" "`savefn'", replace
                }
            }
        }

        if ("`rts'" != "VRS") {
            restore, preserve
            svmat `dearslt', names(eqcol)
            capture {
                renpfix _
                renpfix ref ref_
                renpfix islack is_
                renpfix oslack os_
            }
            capture save `saving', replace

            // di as result ""
            // di as result "DEA Result file:"
            // list
        }
    }
    return matrix dearslt = `dearslt'
    if ("`fdh'" != "") {
    	return matrix fdhrslt = `fdhrslt'
    }

    if ("`rts'" == "VRS") {
        if ("`trace'" == "trace") {
            di _n(2) as result "CRS lambda(ル)"
            matrix list `crslambda' , noblank nohalf noheader f(%9.6f)
        }

        // if you don't have to verify, you can comment the following sentence.
        di _n(2) as result "VRS Frontier(-1:drs, 0:crs, 1:irs)"
        matrix list `vrsfrontier', noblank nohalf noheader f(%9.6f)

        di _n(2) as result "VRS Frontier:"
        restore, preserve
        svmat `vrsfrontier', names(col)
        rename RTS RTSNUM
        qui generate RTS = "drs" if RTSNUM == -1
        qui replace RTS = "-" if RTSNUM == 0
        qui replace RTS = "irs" if RTSNUM == 1
        drop DRS_TE RTSNUM
        format CRS_TE VRS_TE SCALE %9.6f
        list
        if ("`saving'"!="") {
            capture save `saving', replace
        }
    }
    restore, preserve
end

********************************************************************************
* Imprecise DEA - Imprecise Data Envelopment Analysis
********************************************************************************
program define idea, rclass
    #del ;
    syntax , IVARS(string) OVARS(string) RTS(string) ORT(string)
    [
        STAGE(integer 2) TOL1(real 1e-3) TOL2(real 1e-12)
        TRACE SAVing(string) REPLACE 
		Bounded(varlist) ORDinal(varlist) CAtegorical(varlist)
    ];
    #del cr
	
    preserve
	// -------------------------------------------------------------------------
    // di _n as input ///
    //     "options: RTS(`rts') ORT(`ort') STAGE(`stage') SAVing(`saving')"
    // di as input "Input Data:"
    // list
	
	// 1. decomposition variables and make base matrix
	tempname baseMat dmuIn dmuOut dea_rslt vrs_frontier crs_lambda
	mkbasemat, ivars(`ivars') ovars(`ovars') basemat(`baseMat') b(`bounded')
	
	// 2. make variables for dmui
	forvalues dmui = 1/`=rowsof(`baseMat')' {
		keep dmu
		qui svmat `baseMat', names(col)
		
		if ("`bounded'" != "") {
			foreach boundedVar of var `bounded' {
				if (regexm("`ivars'", "`boundedVar'")) {
					// when input, itself choose min value.
					qui replace `boundedVar' = `boundedVar'_2 if _n != `dmui'
				}
				else if(regexm("`ovars'", "`boundedVar'")) {
					// when output, itself choose max value.
					qui replace `boundedVar' = `boundedVar'_2 if _n == `dmui'
				}
				drop `boundedVar'_2
			} // end of foreach
		} // end of first if
		
		if ("`ordinal'" != "") {
			foreach ordVar of var `ordinal' {
				if (regexm("`ivars'", "`ordVar'")) {
					// when input, 
					// 1. if it's superior dmu to itself, 
					//    then replace missing value.
					// 2. if it's not missing value, then replace the 1.
					// 3. if it's missing value, then replace the number of dmus
					qui {
						replace `ordVar' = . if `ordVar' < `ordVar'[`dmui']
						replace `ordVar' = 1 if `ordVar' != .
						replace `ordVar' = _N if `ordVar' == .
					}
				}
				else if(regexm("`ovars'", "`ordVar'")) {
					// when output, 
					// 1. if it's superior dmu to itself or itself, 
					//     then replace missing value.
					// 2. if it's not missing value, then replace the 0.
					// 3. if it's missing value, then replace the 1.
					qui {
						replace `ordVar' = . if `ordVar' <= `ordVar'[`dmui']
						replace `ordVar' = 0 if `ordVar' != .
						replace `ordVar' = 1 if `ordVar' == .
					}
				}
			} // end of foreach
		} // enf of if for `ordinal'

		run_dea_for_dmui, ///
				 ivars(`ivars') ovars(`ovars') rts(`rts') ort(`ort') ///
				 stage(`stage') tol1(`tol1') tol2(`tol2') ///
				 `trace' saving(`saving') `replace' dmui(`dmui')
				 
		matrix `dmuIn' = r(dmuIn)
		matrix `dmuOut' = r(dmuOut)
		matrix `dea_rslt' = nullmat(`dea_rslt') \ r(dmui_dea_rslt)
		
		if ("`rts'" == "VRS") {
			matrix `vrs_frontier' = nullmat(`vrs_frontier')\r(dmui_vrs_frontier)
			matrix `crs_lambda' = nullmat(`crs_lambda')\r(dmui_crs_lambda)
		}
	} // end of forvalues
	
	if ("`ort'" == "OUT") local minrank = 1
    else local minrank = 0
    mata: _dmurank("`dea_rslt'", ///
            `=rowsof(`dmuIn')', `=rowsof(`dmuOut')', `minrank', `tol2')
    matrix `dea_rslt' = r(rank), `dea_rslt'

    // use mata function '_setup_dearslt_names' because the maximum string
    // variable length needs to be kept under the 244 for all the time
    mata: _setup_dearslt_names("`dea_rslt'", "`dmuIn'", "`dmuOut'")
	if ("`rts'" == "VRS") {
		matrix rownames `vrs_frontier' = `: colfullnames `dmuIn''
        matrix colnames `vrs_frontier' = CRS_TE VRS_TE DRS_TE SCALE RTS
	}

	// -------------------------------------------------------------------------
	restore, preserve
	
    // -------------------------------------------------------------------------
    // REPORT
    // -------------------------------------------------------------------------
	report_dea, dearslt(`dea_rslt') ///
				crslambda(`crs_lambda') ///
				vrsfrontier(`vrs_frontier') ///
				rts(`rts') ort(`ort') ///
				stage(`stage') `trace' saving(`saving') `replace'

	// return values
	return matrix dearslt = `dea_rslt'
	restore, preserve
end

********************************************************************************
* Make base Matrix: Decomposition String Variables to Numeric Variables
********************************************************************************
program define mkbasemat, rclass
	#del ;
    syntax , IVARS(string) OVARS(string) BASEMAT(name)
	[
		Bounded(varlist) ORDinal(varlist) CAtegorical(varlist)
    ];
	#del cr
	
	// 1. decomposition variables
	if ("`bounded'" != "") {
		foreach boundedVar of var `bounded' {
			qui split `boundedVar', p(",") ///
					gen("`boundedVar'_") destring i("[]")
			order `boundedVar'_*, after(`boundedVar')
			drop `boundedVar'
			ren `boundedVar'_1 `boundedVar'
		}
	}
	
	// 2. make matrix
	qui ds, has(type numeric)
	mkmat `r(varlist)', matrix(`basemat') rownames(dmu)
	matrix `basemat' = `basemat'
end

********************************************************************************
* run DEA for dmui - run Data Envelopment Analysis
********************************************************************************
program define run_dea_for_dmui, rclass
    #del ;
    syntax , IVARS(string) OVARS(string) RTS(string) ORT(string)
    [
        STAGE(integer 2) TOL1(real 1e-3) TOL2(real 1e-12)
        TRACE SAVing(string) REPLACE DMUI(integer 0)
    ];
    #del cr

	tempname dmuIn dmuOut frameMat deamainrslt dearslt vrsfrontier crslambda
    mkDmuMat `ivars', dmumat(`dmuIn') sprefix("i")
    mkDmuMat `ovars', dmumat(`dmuOut') sprefix("o")
    local dmuCount = colsof(`dmuIn')

    mata: _mkframemat("`frameMat'", "`dmuIn'", "`dmuOut'", ///
            "`rts'", "`ort'")
    deamain `dmui' `dmuIn' `dmuOut' `frameMat' `rts' `ort' `stage' ///
            `tol1' `tol2' `trace'
    matrix `deamainrslt' = r(deamainrslt)
	
    if ("`rts'" == "VRS") {
        // caution : join order! (CRS -> VRS -> DRS)
        // 1. VRS TE(VRS Technical Efficiency)
        matrix `deamainrslt' = r(deamainrslt)
        matrix `vrsfrontier' = `deamainrslt'[1...,1]

        // 2. CRS TE(CRS Technical Efficiency)
        local stageForVRS = 2
        mata: _mkframemat("`frameMat'", "`dmuIn'", "`dmuOut'", ///
                "CRS", "`ort'")
        deamain `dmui' `dmuIn' `dmuOut' `frameMat' "CRS" `ort' `stageForVRS'  ///
                `tol1' `tol2' `trace'
        matrix `deamainrslt' = r(deamainrslt)
        matrix `vrsfrontier' = `deamainrslt'[1...,1], `vrsfrontier'
        matrix `crslambda' = `deamainrslt'[1...,2..(`dmuCount' + 1)]

        // 3. DRS TE(DRS Technical Efficiency)
        local stageForVRS = 1
        mata: _mkframemat("`frameMat'", "`dmuIn'", "`dmuOut'", ///
                "DRS", "`ort'")
        deamain `dmui' `dmuIn' `dmuOut' `frameMat' "DRS" `ort' `stageForVRS' ///
                `tol1' `tol2' `trace'
        matrix `deamainrslt' = r(deamainrslt)
        matrix `vrsfrontier' = `vrsfrontier', `deamainrslt'[1...,1] // VRS
        mata: _roundmat("`vrsfrontier'", 1e-14) // round off

        //
        matrix `vrsfrontier' = `vrsfrontier', J(rowsof(`vrsfrontier'), 2, 0)

        if ("`trace'" == "trace") matrix list `crslambda'
        forvalues i = 1/`=rowsof(`vrsfrontier')' {
            /*******************************************************************
             * if CRS(CCR) == VRS(BCC) then CRS
             * else
             *     if sum of ル equals to 1, then CRS mark
             *     if sum of ル is greater than 1, then DRS mark
             *     if sum of ル is less than 1, then IRS mark
             ******************************************************************/
            // (-1:drs, 0:crs, 1:irs)
            if (`vrsfrontier'[`i',1] == `vrsfrontier'[`i',2]) {
                matrix `vrsfrontier'[`i',5] = 0
            }
            else {
                local sumlambda = 0
                forvalues j = 1/`dmuCount' {
                    if (`crslambda'[`i', `j'] < .) {
                        local sumlambda = `sumlambda' + `crslambda'[`i', `j']
                    }
                }
                if (`sumlambda' < 1) {
                    matrix `vrsfrontier'[`i',5] = 1 // irs mark
                }
                else { // if (`sumlambda' >= 1) {
                    matrix `vrsfrontier'[`i',5] = -1 // drs mark
                }
            } // end of first if~else
        } // end of forvalues
    } // end of vrs
	
	// return values
	return matrix dmuIn = `dmuIn'
	return matrix dmuOut = `dmuOut'
	return matrix dmui_dea_rslt = `deamainrslt'
	if ("`rts'" == "VRS") {
		return matrix dmui_vrs_frontier = `vrsfrontier'
		return matrix dmui_crs_lambda = `crslambda'
	}
end

********************************************************************************
* REPORT
********************************************************************************
program define report_dea, rclass
	#del ;
    syntax , dearslt(name) crslambda(name) vrsfrontier(name) 
	         RTS(string) ORT(string)
    [
        STAGE(integer 2) TRACE SAVing(string) REPLACE
    ];
    #del cr
	
	preserve
	
	di as result ""
    di as input "options: RTS(`rts') ORT(`ort') STAGE(`stage')"
    di as result "`rts'-`ort'PUT Oriented DEA Efficiency Results:"
    matrix list `dearslt', noblank nohalf noheader f(%9.6g)

    if ("`saving'" != "") {
        // if the saving file exists and replace option not specified, 
        // make the backup file.
        if ("`replace'" == "") {
            local dotpos = strpos("`saving'",".")
            if (`dotpos' > 0) {
                mata: _file_exists("`saving'")
            }
            else {
                mata: _file_exists("`saving'.dta")
            }
            if r(fileexists) {
                local curdt = subinstr("`c(current_date)'", " ", "", .) + /*
                    */ subinstr("`c(current_time)'", ":", "", .)
                if (`dotpos' > 0) {
                    #del ;
                    local savefn = substr("`saving'", 1, `dotpos' - 1) +
                                   "_bak_`curdt'" +
                                   substr("`saving'",`dotpos', .);
                    #del cr
                    qui copy "`saving'" "`savefn'", replace
                }
                else {
                    local savefn = "`saving'_bak_`curdt'" + ".dta"
                    qui copy "`saving'.dta" "`savefn'", replace
                }
            }
        }

        if ("`rts'" != "VRS") {
            restore, preserve
            svmat `dearslt', names(eqcol)
            capture {
                renpfix _
                renpfix ref ref_
                renpfix islack is_
                renpfix oslack os_
            }
            capture save `saving', replace

            // di as result ""
            // di as result "DEA Result file:"
            // list
        }
    }

    if ("`rts'" == "VRS") {
        if ("`trace'" == "trace") {
            di _n(2) as result "CRS lambda(ル)"
            matrix list `crslambda' , noblank nohalf noheader f(%9.6f)
        }

        // if you don't have to verify, you can comment the following sentence.
        di _n(2) as result "VRS Frontier(-1:drs, 0:crs, 1:irs)"
        matrix list `vrsfrontier', noblank nohalf noheader f(%9.6f)

        di _n(2) as result "VRS Frontier:"
        restore, preserve
        svmat `vrsfrontier', names(col)
        rename RTS RTSNUM
        qui generate RTS = "drs" if RTSNUM == -1
        qui replace RTS = "-" if RTSNUM == 0
        qui replace RTS = "irs" if RTSNUM == 1
        drop DRS_TE RTSNUM
        format CRS_TE VRS_TE SCALE %9.6f
        list
        if ("`saving'"!="") {
            capture save `saving', replace
        }
    }
	
	restore, preserve
end

********************************************************************************
* DEA Main - Data Envelopment Analysis Main
********************************************************************************
program define deamain, rclass
    args dmui dmuIn dmuOut frameMat rts ort stage tol1 tol2 trace
    tempname efficientVec deamainrslt

    // stage step 1.
    if ("`trace'" == "trace") {
        di _n(2) as txt "RTS(`rts') ORT(`ort') 1st stage."
    }
    mata: _dealp("`frameMat'", "`dmuIn'", "`dmuOut'", "`rts'", "`ort'", ///
        1, `tol1', `tol2', "", "`efficientVec'", "`trace'", ///
		`dmui')
    matrix `deamainrslt' = r(dealprslt)

    // stage step 2.
    if ("`stage'" == "2") {
        if ("`trace'" == "trace") {
            di _n(2) as txt "RTS(`rts') ORT(`ort') 2nd stage."
        }
        matrix `efficientVec' = `deamainrslt'[1...,1]

        mata: _dealp("`frameMat'", "`dmuIn'", "`dmuOut'", "`rts'", "`ort'", ///
            2, `tol1', `tol2', "", "`efficientVec'", "`trace'", ///
			`dmui')
        matrix `deamainrslt' = r(dealprslt)
    }

    return matrix deamainrslt = `deamainrslt'
end

********************************************************************************
* apply FDH(Free Disposal Hull) Model
********************************************************************************
program define apply_fdh, rclass
    args dmuIn dmuOut ort stage frameMat trace
    tempname fdhrslt

    // stage step 1.
    if ("`trace'" == "trace") {
        di _n(2) as txt "RTS(`rts') ORT(`ort') 1st stage."
    }
    mata: _fdh("`dmuIn'", "`dmuOut'", "`ort'", ///
        1, "`frameMat'", "`fdhrslt'", "`trace'")
    matrix `fdhrslt' = r(fdhrslt)

    // stage step 2.
    if ("`stage'" == "2") {
        if ("`trace'" == "trace") {
            di _n(2) as txt "RTS(`rts') ORT(`ort') 2nd stage."
        }

        mata: _fdh("`dmuIn'", "`dmuOut'", "`ort'", ///
            2, "`frameMat'", "`fdhrslt'", "`trace'")
        matrix `fdhrslt' = r(fdhrslt)
    }

    return matrix fdhrslt = `fdhrslt'
end

// Make DMU Matrix -------------------------------------------------------------
program define mkDmuMat
    #del ;
    syntax varlist(numeric) [if] [in], DMUmat(name)
    [
        SPREfix(string)
    ];
    #del cr

    qui ds
    // variable not found error
    if ("`varlist'" == "") {
        di as err "variable not found"
        exit 111
    }

    // make matrix
    mkmat `varlist' `if' `in', matrix(`dmumat') rownames(dmu)
    matrix roweq `dmumat' = "dmu"
    matrix coleq `dmumat' = `=lower("`sprefix'") + "slack"'
    matrix `dmumat' = `dmumat''
end

// Start of the MATA Definition Area -------------------------------------------
version 10
mata:
mata set matastrict on

/**
 * FDH - Branch & Bounded Method
 */
function _fdh (
		string scalar dmuIn,
		string scalar dmuOut,
		string scalar ort,
		
		real scalar stagestep,
		string scalar frameMat,
		string scalar pre_fdhrslt,
		
		string scalar trace )
{
    real matrix F, DI, DO, FDHRSLT

    
    DI = st_matrix(dmuIn)
    DO = st_matrix(dmuOut)
	
	if (stagestep == 1) {
		FDHRSLT = fdh_stage1(DI, DO, ort, trace)
	}
	else { // if (stagestep == 2)
		F  = st_matrix(frameMat)
	    FDHRSLT = st_matrix(pre_fdhrslt)
		
		FDHRSLT = fdh_stage2(DI, DO, ort, F, FDHRSLT, trace)
	}

    st_matrix("r(fdhrslt)", FDHRSLT)
}

/**
 * FDH StageI - Branch & Bounded Method
 */
real matrix function fdh_stage1 ( 
		real matrix DI,
		real matrix DO,
		string scalar ort,
		string scalar trace )
{
	// TM: Theta Metirx, CM: Condition Metrix
    real matrix FDHRSLT, LPRSLT, TM, CM, VM
	real scalar dmus, slackins, slackouts, slacks
	real scalar dmui, init_value, cond_value, mi, mw
	string scalar tracename
	
	dmus = cols(DI) // or cols(DO), because cols(DI) == cols(DO)
	slackins = rows(DI); slackouts = rows(DO)
	slacks = slackins + slackouts
	
	tracename = ort + "-SI"
	
	// define init and condition value
	init_value = 1; cond_value = dmus;

	FDHRSLT = J(0, 1 + dmus + slacks, 0)
	if (ort == "IN") {
		for (dmui=init_value; dmui<=cond_value; dmui++) {
			TM = DI:/DI[,dmui]			//; TM //
			CM = ((TM:>=0):&(TM:<=1))	//; CM // 0 <= theta <= 1

			VM = J(2, dmus, .) // index \ value
			LPRSLT = J(1, cols(FDHRSLT), 0)

			for(i=1; i<=dmus; i++) {
				LPRSLT[1] = .
				if (all(CM[,i])) {
					maxindex(TM[,i], 1, mi, mw)
					VM[,i] = (mi[1] \ TM[mi[1],i])
				}
			}
			minindex(VM[2,], 1, mi, mw)
			LPRSLT[1] = VM[2, mi[1]]
			for(i=1; i <= rows(mi); i++) {
				LPRSLT[1+mi[i]] = 1
			}
            FDHRSLT = FDHRSLT \ LPRSLT
        }
	}
	else { // if (ort == "OUT")
		for (dmui=init_value; dmui<=cond_value; dmui++) {
			TM = DO:/DO[,dmui]	//; TM //
			CM = TM:>=1			//; CM // 1 <= etha

			VM = J(2, dmus, .) // index \ value
			LPRSLT = J(1, cols(FDHRSLT), 0)
			for(i=1; i<=dmus; i++) {
				LPRSLT[1] = .
				if (all(CM[,i])) {
					minindex(TM[,i], 1, mi, mw)
					VM[,i] = (mi[1] \ TM[mi[1],i])
				}
			}
			maxindex(VM[2,], 1, mi, mw)
			LPRSLT[1] = VM[2, mi[1]]
			for(i=1; i <= rows(mi); i++) {
				LPRSLT[1+mi[i]] = 1
			}
            FDHRSLT = FDHRSLT \ LPRSLT
        }
	}

	return(FDHRSLT)
}

/**
 * FDH StageII - Branch & Bounded Method
 */
real matrix function fdh_stage2 ( 
		real matrix DI,
		real matrix DO,
		string scalar ort,
		
		real matrix F,
		real matrix FDHRSLT,
		string scalar trace )
{
	// SVM: Slack Values Metrix
    real matrix M, SVM, SVM2, T
	real scalar dmus, slackins, slackouts, slacks, sum_of_slacks, base_lamda
	real scalar fcols, dmui, init_value, cond_value, mi, mw, base_lamda_count
	real colvector LVec // Lamda Vector
	string scalar tracename

	dmus = cols(DI) // or cols(DO), because cols(DI) == cols(DO)
	slackins = rows(DI); slackouts = rows(DO)
	slacks = slackins + slackouts
	fcols = cols(F)
	
	tracename = ort + "-SII"
	
	// define init and condition value
	init_value = 1; cond_value = dmus;
	
	if (ort == "IN") {
		for (dmui=init_value; dmui<=cond_value; dmui++) {
			M = F[1::1+slacks,]
			replacesubmat(M, 2, 2, DI[,dmui]*FDHRSLT[dmui, 1]) // DI*theta
			replacesubmat(M, 2+slackins, fcols, DO[,dmui])	// DO at RHS
			
			LVec = FDHRSLT[dmui, 2..1+dmus]
			maxindex(LVec, 1, mi, mw)
			base_lamda_count = rows(mi)
			if (base_lamda_count > 1) {
				base_lamda = mi[1]
				SVM = mksvm(M, base_lamda)
				sum_of_slacks = sum(SVM)
				for(i=2; i<=base_lamda_count; i++) {
					SVM2 = mksvm(M, mi[i])
					if (sum_of_slacks < sum(SVM2)) {
						FDHRSLT[dmui, 1+base_lamda] = 0; // set 0 at pre-lamda
						
						// Save current lamda
						base_lamda = mi[i]
						SVM = SVM2
						sum_of_slacks = sum(SVM)
					}
					else {
						FDHRSLT[dmui, 1+mi[i]] = 0; // set 0 at lamda
					}
				}
			}
			else {
				SVM = mksvm(M, mi[1])
			}
			replacesubmat(FDHRSLT, dmui, 2+dmus, SVM[2::1+slacks]')
        }
	}
	else { // if (ort == "OUT") 
		for (dmui=init_value; dmui<=cond_value; dmui++) {
			M = F[1::1+slacks,]
			replacesubmat(M, 2, fcols, DI[,dmui])	// DI at RHS
			replacesubmat(M, 2+slackins, 2, 
				DO[,dmui]*FDHRSLT[dmui, 1]) 		// DO*etha

			LVec = FDHRSLT[dmui, 2..1+dmus]
			maxindex(LVec, 1, mi, mw)
			base_lamda_count = rows(mi)
			if (base_lamda_count > 1) {
				base_lamda = mi[1]
				SVM = mksvm(M, base_lamda)
				sum_of_slacks = sum(SVM)
				for(i=2; i<=base_lamda_count; i++) {
					SVM2 = mksvm(M, mi[i])
					if (sum_of_slacks < sum(SVM2)) {
						FDHRSLT[dmui, 1+base_lamda] = 0; // set 0 at pre-lamda
						
						// Save current lamda
						base_lamda = mi[i]
						SVM = SVM2
						sum_of_slacks = sum(SVM)
					}
					else {
						FDHRSLT[dmui, 1+mi[i]] = 0; // set 0 at lamda
					}
				}
			}
			else {
				SVM = mksvm(M, mi[1])
			}
			// Because original formula is [etha - (sumOfLamda) + slackOut = 0]
			// but we calculated [etha - (sumOfLamda) = -slackOut]
			// so multiple minus at the results.
			replacesubmat(FDHRSLT, dmui, 2+dmus, -(SVM[2::1+slacks]'))
        }
	}

	return(FDHRSLT)
}

/**
 * Make Slace Value Matrix.
 */
real matrix function mksvm (
		real matrix M, 				// Base Matrix that dmui's Theta is applied
		real scalar base_lamda )
{
	// 2: Theta, 2+base_lamda: lamda, cols(M): rhs
	return (M[,2] :+ M[,2+base_lamda] :+ (-M[,cols(M)]))
}

/**
 * FDH - Branch & Bounded Method
 */
real matrix function fdh_backup ( 
		real matrix F,
		real matrix DI,
		real matrix DO,
		string scalar rts,
		string scalar ort,
		real scalar stagestep,
		real scalar tol1,
		real scalar tol2,
		real colvector effvec,
		string scalar trace, 
		real scalar _dmui  )
{
    real matrix M, VARS, LPRSLT, FDHRSLT, ARTIF
    real scalar dmus, slackins, slackouts, slacks, artificials, artificialrow
    real scalar frows, fcols, isin, i, dmui, mindmui, maxdmui
    real colvector l_effvec, skipdmu
    string scalar tracename
	
	struct BoundCond matrix boundF, boundM
	struct LpParamStruct scalar param
	
	
	
	
	

    if (cols(DI) != cols(DO)) {
        _error(3200, "in and out count of dmu is not match!")
    }
	if (!(rts == "CRS" || rts == "VRS" || rts == "IRS" || rts == "DRS")) {
		_error(3498, "rts must be one of CRS, VRS, IRS, DRS")
	}

    // basic value setting for artificial variabels
    isin = (ort == "IN")
    frows = rows(F); fcols = cols(F)
    dmus = cols(DI) // or cols(DO), because cols(DI) == cols(DO)
    slackins = rows(DI); slackouts = rows(DO)

    tracename = rts + "-" + ort + "-" + (stagestep == 1 ? "SI" : "SII")
	
	// -------------------------------------------------------------------------
	// define number of slacks by rts
	if (rts == "CRS" || rts == "VRS") slacks = slackins + slackouts
	else if (rts == "IRS" || rts == "DRS") slacks = slackins + slackouts + 1
	
	// define number of artificials by rts, ort, stage
	if (rts == "CRS" || rts == "DRS") {
		if (stagestep == 1) {
			if (isin) {
				artificials = slackins+slackouts; artificialrow = 2;
			}
			else artificials = 0
		}
		else {
			artificials = slackouts; artificialrow = 2+slackins;
		}
	}
	else if (rts == "VRS" || rts == "IRS") {
		if (stagestep == 1) {
			if (isin) {
				artificials = slackins+slackouts+1; artificialrow = 2;
			}
			else {
				artificials = 1; artificialrow = frows //== 2+slackins+slackouts
			}
		}
		else {
			artificials = slackouts+1; artificialrow = 2+slackins
		}
	}
	if (artificials > 0) {
		ARTIF = J(1, artificials, 1) \ J(frows-1, artificials, 0)
		replacesubmat(ARTIF, artificialrow, 1, I(artificials))
		F = F[,1..fcols-1], ARTIF, F[,fcols]
		frows = rows(F); fcols = cols(F) // revise frows, fcols
	}
	// -------------------------------------------------------------------------
	
	// constants value to right-hand side(rhs) and both sides multiplied by -1.
	if (stagestep == 2) {
		l_effvec = effvec
		skipdmu = (effvec :== .)
		if (isin) {
		    replacesubmat(F, 2, 3, -F[2..1+slackins,3::2+dmus+slackins])
		}
		else {
		    replacesubmat(F, 2+slackins, 3,
                -F[2+slackins..1+slackins+slackouts,3::2+dmus+slacks])
		}
	}
	else skipdmu = J(1, dmus, 0)
	// -------------------------------------------------------------------------
    boundF = J(1, fcols, BoundCond());
	// set the boundary for the efficiency variable(theta, eta):
	// -INFINITE <= efficiency <= INFINITE
	boundF[1,2].val = 0; boundF[1,2].lower = 0; boundF[1,2].upper = .
	
	// set boundary for the weight variable(lamda, mu):
	// 0 <= weight <= INFINITE
	for (i=3; i<dmus+3; i++) {
		boundF[1,i].val = 0; boundF[1,i].lower = 0; boundF[1,i].upper = .
	}
		
	// set boundary for the non-structural variable(slack, artificial).
	// 0 <= slacks and atrificials <= INFINITE
	for (i=dmus+3; i<fcols; i++) { 
		boundF[1,i].val = 0; boundF[1,i].lower = 0; boundF[1,i].upper = .
	}
	// liststruct(boundF); // for debug
	
	// set the lp's parameters
	param.rts            = rts
	param.isin			 = isin
	param.stagestep      = stagestep
	param.dmus           = dmus
	param.slacks         = slacks
	param.artificials    = artificials
	param.tol1           = tol1
	param.tol2           = tol2
	param.trace          = trace
	// liststruct(param); // for debug
	// -------------------------------------------------------------------------
    FDHRSLT = J(0, 1+ dmus + slacks, 0)
	
	// Added by Brian(2012.06.30)
	if (_dmui <= 0 || _dmui >= .) {
		mindmui = 1; maxdmui = dmus;
	}
	else {
		mindmui = _dmui; maxdmui = _dmui;
		if (stagestep == 2) {
			l_effvec = J(1, dmus, effvec[1])
			skipdmu = (l_effvec :== .)
		}
	}
	
    if (isin) {
        for (dmui=mindmui; dmui<=maxdmui; dmui++) {
			if (skipdmu[dmui]) {
				LPRSLT = J(1, cols(FDHRSLT), .)
			}
			else {
				M = F; boundM = boundF
				if (stagestep == 1) replacesubmat(M, 2, 2, DI[,dmui])
				else replacesubmat(M, 2, fcols, DI[,dmui]*l_effvec[dmui])
				replacesubmat(M, 2+slackins, fcols, DO[,dmui])

				// execute LP
				VARS   = lp_phase1(M, boundM, dmui, tracename, param)
				if (VARS[1,1] == .) {
					LPRSLT = J(1, cols(FDHRSLT), .)
				}
				else {
					LPRSLT = lp_phase2(M, boundM, VARS, dmui, tracename, param);
				}
			}

            FDHRSLT = FDHRSLT \ LPRSLT
        }
    }
    else {
        for (dmui=mindmui; dmui<=maxdmui; dmui++) {
			if (skipdmu[dmui]) {
				LPRSLT = J(1, cols(FDHRSLT), .)
			}
			else {
				M = F; boundM = boundF
				replacesubmat(M, 2, fcols, DI[,dmui])
				if (stagestep == 1) {
					if (rts == "CRS" || rts == "DRS") M[1,2] = -1
					replacesubmat(M, 2+slackins, 2, DO[,dmui])
				}
				else replacesubmat(M, 2+slackins, fcols, DO[,dmui]*l_effvec[dmui])

				// execute LP
				if (artificials == 0) { // if artificials == 0 then skip phase 1
					VARS   = (0, 2+dmus..1+dmus+slacks, 1..1+dmus, 0)
					M = M[,1], 
						M[,VARS[,2::cols(VARS)-1] :+ 1], 
						M[,cols(M)]
					boundM = boundM[,1], 
							 boundM[,VARS[,2::cols(VARS)-1] :+ 1], 
							 boundM[,cols(M)]
				}
				else {
					VARS = lp_phase1(M, boundM, dmui, tracename, param)
				}
				
				if (VARS[1,1] == .) {
					LPRSLT = J(1, cols(FDHRSLT), .)
				}
				else {
					LPRSLT = lp_phase2(M, boundM, VARS, dmui, tracename, param);
				}
			}
            FDHRSLT = FDHRSLT \ LPRSLT
        }
    }

    // adjust efficiency
    if (stagestep == 2) {
        replacesubmat(FDHRSLT, 1, 1, effvec)
    }
	return(FDHRSLT)
}

end
// End of the MATA Definition Area ---------------------------------------------
