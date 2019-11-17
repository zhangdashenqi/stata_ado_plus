*! version 1.2.0  18JUN2011
capture program drop malmq
program define malmq, rclass
    version 10.0

// syntax checking and validation-----------------------------------------------
// rts - return to scale, ort - orientation
// input varlist = output varlist
// -----------------------------------------------------------------------------
    // returns 1 if the first nonblank character of local macro `0' is a comma,
    // or if `0' is empty.
    if replay() {
        dis as err "ivars and ovars required."
        exit 198
    }

    // get and check invarnames
    gettoken word 0 : 0, parse(" =:,")
    while `"`word'"' != ":" & `"`word'"' != "=" {
        if `"`word'"' == "," | `"`word'"'=="" {
                error 198
        }
        local invarnames `invarnames' `word'
        gettoken word 0 : 0, parse(" :,")
    }
    unab invarnames : `invarnames'

    #del ;
    syntax varlist(min=1) [if] [in] [using/]
    [,
        Period(name)
        ORT(string)       // ignore case sensitive,[{IN|INPUT}|{OUT|OUTPUT}]
        TOL1(real 1e-14)  // entering or leaving value tolerance
        TOL2(real 1e-8)   // B inverse tolerance: 2.22e-12
        MINSUBScript      // minimal subscript pivot
        TRACE             // Whether or not to do the log
        SAVing(string)    // log file name
        REPLACE           // Whether or not to replace the log file
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
            di as err "option ort allow for case-insensitive " _c
            di as err "(i|in|input|o|out|output) or nothing."
            exit 198
        }
    }

    if ("`using'" != "") use "`using'", clear
    if (~(`c(N)' > 0 & `c(k)' > 0)) {
        dis as err "dataset is not ready!"
        exit 198
    }

    if ("`period'" == "") {
        di as err "you must specify period (varname)"
        exit 198
    }

// end of syntax checking and validation ---------------------------------------

    set more off
    capture log close malmquistlog
    log using "malmquist.log", replace text name(malmquistlog)
    preserve

    if ("`if'" != "" | "`in'" != "") {
        qui keep `in' `if'  // filtering : keep in range [if exp]
    }

    deamalmquist `period', ivars(`invarnames') ovars(`varlist') ///
                  ort(`ort') tol1(`tol1') tol2(`tol2') `minsubscript' ///
                  `trace' saving(`saving') `replace'
    return add

    restore, preserve
    log close malmquistlog
end

********************************************************************************
* DEA Malmquist
********************************************************************************
program define deamalmquist, rclass
    #del ;
    syntax varname(numeric), IVARS(string) OVARS(string) ORT(string)
        [
            TOL1(real 1e-3) TOL2(real 1e-12) MINSUBScript
            TRACE SAVing(string) REPLACE
        ];
    #del cr
    preserve

    // di _n(2) as input "options: ts(`varlist') ORT(`ort')"
    // di as input "Input Data:"
    // list

    tempname tsvec
    local tsn = "`varlist'"
    mata: _uniqrowmat("`tsvec'", "`tsn'") // sorted unique row matrix
    if (rowsof(`tsvec') < 2) {
        di as err "time series `tsn' observations must be ge 2"
        exit 451 // invalid values for time variable
    }

    // crs{i|o|f|r}: crs {input|output|frame|result}
    // t, t1: t+1, c: cross --> crsi_ct1: crsi cross t+1,
    tempname crsi_t crso_t crsf_t crsr_t crsi_t1 crso_t1 crsf_t1 crsr_t1
    tempname crsr_ct crsr_ct1
    tempname vrsi_t vrso_t vrsf_t vrsr_t vrsi_t1 vrso_t1 vrsf_t1 vrsr_t1
    tempname crossrslt effr_t1 effrslt prodidxr_t prodidxrslt
    tempname tfpch effch techch pech sech
    local stage = 1
    forvalues t = 1/`=rowsof(`tsvec') - 1' {
        local tsval_t = `tsvec'[`t',1]
        local tsval_t1 = `tsvec'[`t'+1,1]

        // CRS-DEA t
        local rts = "CRS"
        if (`t' == 1) {
            if ("`trace'" != "") di _newline "CRS-DEA ts[`tsval_t']:"
            mkDmuMat `ivars' if `tsn'==`tsval_t', dmumat(`crsi_t') sprefix("i")
            mkDmuMat `ovars' if `tsn'==`tsval_t', dmumat(`crso_t') sprefix("o")
            mata: _mkframemat("`crsf_t'", "`crsi_t'", "`crso_t'", ///
                    "`rts'", "`ort'", `stage')
            deamain `crsi_t' `crso_t' `crsf_t' `rts' `ort' `stage' ///
                    `tol1' `tol2' `minsubscript' `trace'
            matrix `crsr_t' = r(deamainrslt)
        }
        else {
            matrix `crsi_t' = `crsi_t1'
            matrix `crso_t' = `crso_t1'
            matrix `crsf_t' = `crsf_t1'
            matrix `crsr_t' = `crsr_t1'
        }
        // CRS-DEA t+1
        if ("`trace'" != "") di _newline "CRS-DEA ts[`tsval_t1']:"
        mkDmuMat `ivars' if `tsn'==`tsval_t1', dmumat(`crsi_t1') sprefix("i")
        mkDmuMat `ovars' if `tsn'==`tsval_t1', dmumat(`crso_t1') sprefix("o")
        mata: _mkframemat("`crsf_t1'", "`crsi_t1'", "`crso_t1'", ///
                    "`rts'", "`ort'", `stage')
        deamain `crsi_t1' `crso_t1' `crsf_t1' `rts' `ort' `stage' ///
                `tol1' `tol2' `minsubscript' `trace'
        matrix `crsr_t1' = r(deamainrslt)

        // Cross CRS-DEA t
        if ("`trace'" != "") di _newline "Cross CRS-DEA t[`tsval_t']:"
        deamain `crsi_t1' `crso_t1' `crsf_t' `rts' `ort' `stage' ///
                `tol1' `tol2' `minsubscript' `trace'
        matrix `crsr_ct' = r(deamainrslt)
        // Cross CRS-DEA t+1
        if ("`trace'" != "") di _newline "Cross CRS-DEA t+1[`tsval_t1']:"
        deamain `crsi_t' `crso_t' `crsf_t1' `rts' `ort' `stage' ///
                `tol1' `tol2' `minsubscript' `trace'
        matrix `crsr_ct1' = r(deamainrslt)

        // VRS-DEA t
        local rts = "VRS"
        if (`t' == 1) {
            if ("`trace'" != "") di _newline "VRS-DEA ts[`tsval_t']:"
            mkDmuMat `ivars' if `tsn'==`tsval_t', dmumat(`vrsi_t') sprefix("i")
            mkDmuMat `ovars' if `tsn'==`tsval_t', dmumat(`vrso_t') sprefix("o")
            mata: _mkframemat("`vrsf_t'", "`vrsi_t'", "`vrso_t'", ///
                    "`rts'", "`ort'", `stage')
            deamain `vrsi_t' `vrso_t' `vrsf_t' `rts' `ort' `stage' ///
                    `tol1' `tol2' `minsubscript' `trace'
            matrix `vrsr_t' = r(deamainrslt)
        }
        else {
            matrix `vrsi_t' = `vrsi_t1'
            matrix `vrso_t' = `vrso_t1'
            matrix `vrsf_t' = `vrsf_t1'
            matrix `vrsr_t' = `vrsr_t1'
        }
        // VRS-DEA t+1
        if ("`trace'" != "") di _newline "VRS-DEA ts[`tsval_t1']:"
        mkDmuMat `ivars' if `tsn'==`tsval_t1', dmumat(`vrsi_t1') sprefix("i")
        mkDmuMat `ovars' if `tsn'==`tsval_t1', dmumat(`vrso_t1') sprefix("o")
        mata: _mkframemat("`vrsf_t1'", "`vrsi_t1'", "`vrso_t1'", ///
                    "`rts'", "`ort'", `stage')
        deamain `vrsi_t1' `vrso_t1' `vrsf_t1' `rts' `ort' `stage' ///
                `tol1' `tol2' `minsubscript' `trace'
        matrix `vrsr_t1' = r(deamainrslt)

        // ------------
        // transform DEA Results to Malmquist efficiency scores
        if (`t' == 1) {
            local dmuCount = colsof(`crsi_t')
            local rnames : colfullnames `crsi_t'
            local cnames = "`tsn' CRS_eff VRS_eff"

            matrix `effrslt' = J(`dmuCount', 1, `tsval_t')
            matrix `effrslt' = `effrslt', `crsr_t'[1...,1], `vrsr_t'[1...,1]
            matrix rownames `effrslt' = `rnames'
            matrix colnames `effrslt' = `cnames'
        }
        matrix `effr_t1' = J(`dmuCount', 1, `tsval_t1')
        matrix `effr_t1' = `effr_t1', `crsr_t1'[1...,1], `vrsr_t1'[1...,1]
        matrix rownames `effr_t1' = `rnames'

        matrix `effrslt' = `effrslt' \ `effr_t1'

        // make DEA Results Malmquist productivity index
        // tfpch: total factor productivity change
        // effch: technical efficiency change
        // techch: technical change
        // pech: pure technical efficiency change
        // sech: scale efficiency change
        matrix `prodidxr_t' = J(`dmuCount', 1, `tsval_t')
        matrix `prodidxr_t' = `prodidxr_t', J(`dmuCount', 1, `tsval_t1')
        matrix `prodidxr_t' = `prodidxr_t', J(`dmuCount', 5, 0)
        forvalues dmui = 1/`dmuCount' {
            scalar `tfpch' = sqrt((`crsr_ct'[`dmui',1] ///
                                 / `crsr_t'[`dmui',1]) ///
                                * (`crsr_t1'[`dmui',1] ///
                                 / `crsr_ct1'[`dmui',1]))
            scalar `effch' = `crsr_t1'[`dmui',1]/`crsr_t'[`dmui',1]
            scalar `techch' = sqrt((`crsr_ct'[`dmui',1] ///
                                  / `crsr_t1'[`dmui',1]) ///
                                 * (`crsr_t'[`dmui',1] ///
                                  / `crsr_ct1'[`dmui',1]))
            scalar `pech' = `vrsr_t1'[`dmui',1]/`vrsr_t'[`dmui',1]
            scalar `sech' = `effch'/`pech'
            matrix `prodidxr_t'[`dmui', 3] = ///
                (`tfpch', `effch', `techch', `pech', `sech')
        }
        matrix rownames `prodidxr_t' = `rnames'
        if (`t' == 1) matrix colnames ///
            `prodidxr_t' = from thru tfpch effch techch pech sech

        matrix `prodidxrslt' = nullmat(`prodidxrslt') \ `prodidxr_t'

        matrix `crossrslt' = nullmat(`crossrslt') \ ///
                (`prodidxr_t'[1...,1..2], `crsr_ct'[1...,1], `crsr_ct1'[1...,1])
    }

    // -------------------------------------------------------------------------
    // REPORT
    // -------------------------------------------------------------------------
    di _n(2) as txt "Cross CRS-DEA Result:"
    matrix colnames `crossrslt' = from thru t t1
    matrix rownames `crossrslt' = `: rowfullnames `prodidxrslt''
    matrix list `crossrslt', noblank nohalf noheader f(%9.6g)

    di _n "Malmquist efficiency `ort'PUT Oriented DEA Results:"
    // matrix list `effrslt', noblank nohalf noheader f(%9.6g)
    qui {
        keep dmu
        gen str dmu1 = dmu
        rename dmu `tsn'1
        rename dmu1 dmu
        svmat `effrslt', names(col)
        replace `tsn'1 = string(`tsn')
        drop `tsn'
        rename `tsn'1 `tsn'
        format CRS_eff VRS_eff %9.6g
    }
    list
    return matrix effrslt = `effrslt'

    di _n "Malmquist productvity index `ort'PUT Oriented DEA Results:"
    // matrix list `prodidxrslt', noblank nohalf noheader f(%9.6g)
    restore, preserve
    qui {
        keep dmu
        keep in 1/`=rowsof(`prodidxrslt')'
        gen str dmu1 = dmu
        rename dmu period
        rename dmu1 dmu
        svmat `prodidxrslt', names(col)
        replace period = string(from) + "~" + string(thru)
        drop from thru
        format tfpch effch techch pech sech %9.6g
    }
    list
    return matrix prodidxrslt = `prodidxrslt'

    if ("`saving'"!="") {
        // if save file exist and don't replace, make the backup file.
        if ("`replace'" == "") {
            local dotpos = strpos("`saving'",".")
            if (`dotpos' > 0) {
                mata: file_exists("`saving'")
            }
            else {
                mata: file_exists("`saving'.dta")
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
        capture save `saving', replace
    }
    restore, preserve
end

********************************************************************************
* DEA Main - Data Envelopment Analysis Main
********************************************************************************
program define deamain, rclass
    args dmuIn dmuOut frameMat rts ort stage tol1 tol2 minsubscript trace

    tempname efficientVec deamainrslt

    // stage step 1.
    if ("`trace'" == "trace") {
        di _n(2) as txt "RTS(`rts') ORT(`ort') 1st stage."
    }
    mata: _dealp("`frameMat'", "`dmuIn'", "`dmuOut'", "`rts'", "`ort'", ///
        1, `tol1', `tol2', "`minsubscript'", "`efficientVec'", "`trace'")
    matrix `deamainrslt' = r(dealprslt)

    // stage step 2.
    if ("`stage'" == "2") {
        if ("`trace'" == "trace") {
            di _n(2) as txt "RTS(`rts') ORT(`ort') 2nd stage."
        }
        matrix `efficientVec' = `deamainrslt'[1...,1]

        mata: _dealp("`frameMat'", "`dmuIn'", "`dmuOut'", "`rts'", "`ort'", ///
            2, `tol1', `tol2', "`minsubscript'", "`efficientVec'", "`trace'")
        matrix `deamainrslt' = r(dealprslt)
    }

    // // if output oriented, get theta from eta
    // if ("`ort'" == "OUT") {
    //     tempname eta
    //     forvalues i = 1/`=rowsof(`deamainrslt')' {
    //         scalar `eta' = el(`deamainrslt', `i', 1)
    //         matrix `deamainrslt'[`i',1] = 1/`eta'
    //         matrix `deamainrslt'[`i',2] = `deamainrslt'[`i',2...]/`eta'
    //     }
    // }

    // adjust negative value
    forvalues i = 1/`=rowsof(`deamainrslt')' {
        forvalues j = 1/`=colsof(`deamainrslt')' {
            if (`deamainrslt'[`i',`j'] < 0) {
                matrix `deamainrslt'[`i',`j'] = 0
            }
        }
    }

    return matrix deamainrslt = `deamainrslt'
end

********************************************************************************
* Data Import and Conversion
********************************************************************************

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
 * Declare the variable's boundary condition structure.
 */
struct BoundCond {
    real scalar val, lower, upper, free
}

/**
 * Declare the LP's parameter structure.
 */
struct LpParamStruct {
    string scalar rts       // return to scale(CRS|VRS|IRS|DRS)
	real scalar isin        // if 1 then 'in', other then 'out'
	real scalar stagestep   // stage step. 1 or 2
	
    real scalar dmus        // number of dmus
    real scalar slacks      // number of slacks
	real scalar artificials // number of artificials
	
	real scalar tol1        // tolerance 1
    real scalar tol2        // tolerance 2
    real scalar isminsubscript // whether min subscript or not.
    string scalar trace     // whether trace or not.
}

/**
 * Declare the LP's result structure.
 */
struct LpResultStruct {
	real scalar xVal	// objective funtion value.
	real matrix XB		// basic feasible solution value.
	real scalar rc		// return code(sucess is zero)
	string scalar rmsg	// return message
}

/**
 * make frame matrix and set matrix value at the param frameMat
 * rts - return to scale, ort - orientation
 */
function _mkframemat( string scalar frameMat,
                      string scalar dmuIn,
                      string scalar dmuOut,
                      string scalar rts,
                      string scalar ort,
                      real scalar stage )
{
    real matrix F, DI, DO
    real scalar row, col, sig, isin
    real scalar dmus, slackins, slackouts, slacks
    real scalar frows, fcols

    DI = st_matrix(dmuIn)
    DO = st_matrix(dmuOut)
    if (cols(DI) != cols(DO)) {
        _error(3200, "The in and out count of dmu does not match!")
    }

    // basic value setting for artificial variabels
    isin = (ort == "IN"); sig = (isin ? -1 : 1)

    dmus = cols(DI) // or cols(DO), because cols(DI) == cols(DO)
    slackins = rows(DI); slackouts = rows(DO)
    if (rts == "CRS") {
		slacks = slackins + slackouts
	    // target coefficient\slackins\slackouts
        frows = 1 + slackins + slackouts
		// target coefficient,theta,dmus,slackins,slackouts,rhs
        fcols = 1 + 1 + dmus + slackins + slackouts + 1
    }
    else if (rts == "VRS") {
		slacks = slackins + slackouts
		// target coefficient\slackins\slackouts\sum of lamda
        frows = 1 + slackins + slackouts + 1
		// target coefficient,theta,dmus,slackins,slackouts,rhs
        fcols = 1 + 1 + dmus + slackins + slackouts + 1
    }
	else if (rts == "IRS") {
        slacks = slackins + slackouts + 1
        // target coefficient\slackins\slackouts\sum of lamda
        frows = 1 + slackins + slackouts + 1
		// target coefficient,theta,dmus,slackins,slackouts,sum of lamda,rhs
        fcols = 1 + 1 + dmus + slackins + slackouts + 1 + 1
    }
    else if (rts == "DRS") {
        slacks = slackins + slackouts + 1
        // target coefficient\slackins\slackouts\sum of lamda
        frows = 1 + slackins + slackouts + 1
		// target coefficient,theta,dmus,slackins,slackouts,sum of lamda,rhs
        fcols = 1 + 1 + dmus + slackins + slackouts + 1 + 1
    }
    else {
        _error(3498, "invalid rts option.")
    }

    // make frame matrix for CRS(CCR)
    F = J(frows, fcols, 0)
    F[1, 1] = 1
    replacesubmat(F, 2, 3, sig * DI)
    replacesubmat(F, 2 + slackins, 3, -sig * DO)
    replacesubmat(F, 2, 3 + dmus, sig * I(slacks))

    // adjustment
	if (rts == "VRS") {
        replacesubmat(F, frows, 3, J(1, dmus, 1))
        F[frows,fcols] = 1
    }
	else if (rts == "IRS") {
        replacesubmat(F, frows, 3, J(1, dmus, 1))
        F[frows,2 + dmus + slacks] = -1
        F[frows,fcols] = 1
    }
    else if (rts == "DRS") {
        replacesubmat(F, frows, 3, J(1, dmus, 1))
        F[frows,2 + dmus + slacks] = 1
        F[frows,fcols] = 1
    }

    // return result
    st_matrix(frameMat, F)
}

/**
 * DEA Loop - Data Envelopment Analysis Loop for DMUs
 */
function _dealp ( string scalar frameMat,
                  string scalar dmuIn,
                  string scalar dmuOut,
                  string scalar rts,
                  string scalar ort,
                  real scalar stagestep,
                  real scalar tol1,
                  real scalar tol2,
                  string scalar minsubscript,
                  string scalar efficientVec,
                  string scalar trace )
{
    real matrix F, DI, DO, M, VARS, LPRSLT, DEALPRSLT, ARTIF
    real scalar dmus, slackins, slackouts, slacks, artificials, artificialrow
    real scalar frows, fcols, isin, isminsubscript
    real colvector effvec, slackidx, skipdmu
    string scalar tracename
	
	struct BoundCond matrix boundF, boundM
	struct LpParamStruct scalar param

    F  = st_matrix(frameMat)
    DI = st_matrix(dmuIn)
    DO = st_matrix(dmuOut)
    if (cols(DI) != cols(DO)) {
        _error(3200, "in and out count of dmu does not match!")
    }
	if (!(rts == "CRS" || rts == "VRS" || rts == "IRS" || rts == "DRS")) {
		_error(3498, "rts must be one of CRS, VRS, IRS, DRS")
	}

    // basic value setting for artificial variabels
    isin = (ort == "IN")
    isminsubscript = (minsubscript != "nominsubscript")
    frows = rows(F); fcols = cols(F)
    dmus = cols(DI) // or cols(DO), because cols(DI) == cols(DO)
    slackins = rows(DI); slackouts = rows(DO)

    tracename = rts + "-" + (isin ? "IN" : "OUT")
    tracename = tracename + "-" + (stagestep == 1 ? "SI" : "SII")
	
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
	
	// put artificial for slackins on the inactive status
	if (stagestep == 2) {
	    effvec = st_matrix(efficientVec)
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
	// set boundary value for the efficiency variable(theta, eta):
	// -INFINITE <= efficiency <= INFINITE
	boundF[1,2].val = 0; boundF[1,2].lower = 0; boundF[1,2].upper = .
	
	// set boundary value for the weight variable(lamda, mu):
	// 0 <= weight <= INFINITE
	for (i=3; i<dmus+3; i++) {
		boundF[1,i].val = 0; boundF[1,i].lower = 0; boundF[1,i].upper = .
	}
		
	// set boundary value for the non-structural variable(slack, artificial).
	// 0 <= slacks and atrificials <= INFINITE
	for (i=dmus+3; i<fcols; i++) { 
		boundF[1,i].val = 0; boundF[1,i].lower = 0; boundF[1,i].upper = .
	}
	// liststruct(boundF); // for debug
	
	// set the lp's parameters
	param.rts            = rts
	param.isin           = isin
	param.stagestep      = stagestep
	param.dmus           = dmus
	param.slacks         = slacks
	param.artificials    = artificials
	param.tol1           = tol1
	param.tol2           = tol2
	param.isminsubscript = isminsubscript
	param.trace          = trace
	// liststruct(param); // for debug
	// -------------------------------------------------------------------------
    DEALPRSLT = J(0, 1+ dmus + slacks, 0)
    if (isin) {
        for (dmui=1; dmui<=dmus; dmui++) {
			if (skipdmu[dmui]) {
				LPRSLT = J(1, cols(DEALPRSLT), .)
			}
			else {
				M = F; boundM = boundF
				if (stagestep == 1) replacesubmat(M, 2, 2, DI[,dmui])
				else replacesubmat(M, 2, fcols, DI[,dmui]*effvec[dmui])
				replacesubmat(M, 2+slackins, fcols, DO[,dmui])

				// execute LP
				VARS   = lp_phase1(M, boundM, dmui, tracename, param)
				if (VARS[1,1] == .) {
					LPRSLT = J(1, cols(DEALPRSLT), .)
				}
				else {
					LPRSLT = lp_phase2(M, boundM, VARS, dmui, tracename, param);
				}
			}
            DEALPRSLT = DEALPRSLT \ LPRSLT
        }
    }
    else {
        for (dmui=1; dmui<=dmus; dmui++) {
			if (skipdmu[dmui]) {
				LPRSLT = J(1, cols(DEALPRSLT), .)
			}
			else {
				M = F; boundM = boundF
				replacesubmat(M, 2, fcols, DI[,dmui])
				if (stagestep == 1) {
					if (rts == "CRS" || rts == "DRS") M[1,2] = -1
					replacesubmat(M, 2+slackins, 2, DO[,dmui])
				}
				else replacesubmat(M, 2+slackins, fcols, DO[,dmui]*effvec[dmui])

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
					LPRSLT = J(1, cols(DEALPRSLT), .)
				}
				else {
					LPRSLT = lp_phase2(M, boundM, VARS, dmui, tracename, param);
				}
			}
            DEALPRSLT = DEALPRSLT \ LPRSLT
        }
    }

    // adjust efficiency
    if (stagestep == 2) {
        replacesubmat(DEALPRSLT, 1, 1, effvec)
    }
    st_matrix("r(dealprslt)", DEALPRSLT)
}

real matrix function lp_phase1 ( real matrix M,
                                 struct BoundCond matrix boundM,
                                 real scalar dmui,
                                 string scalar aTracename,
                                 struct LpParamStruct scalar param )
{
    real matrix T, VARS
    real scalar mrows, mcols, phase
	real vector reorderidx, bfsidx, nonbfsidx
    string scalar tracename, msg
	struct LpResultStruct scalar lpresult

    mrows = rows(M); mcols = cols(M)
    tracename = aTracename + "-PI"

    // 1st: initialize matrix.
    if (param.trace == "trace") {
        displayas("txt")
        printf("\n\n\n----------[PHASE I]----------")
        printf("\n[DMUi=%g]%s: initialize matrix.\n",
            dmui, tracename); M
    }

    // 2nd: classify basic and nonbasic.
	VARS = (0, 1..1+param.dmus+param.slacks, -1..-param.artificials, 0)
	bfsidx = J(1, mrows-1, .); nonbfsidx = J(1, 0, .)
	for (j = 3+param.dmus; j <= mcols-1; j++) {
		T = (M[2::mrows,j] :== 1)
		if (any(T)) {
		    maxindex(T, 1, i, w); bfsidx[i] = j
		}
		else nonbfsidx = nonbfsidx, j
	}
	reorderidx = (1, bfsidx[1,], 2..2+param.dmus, nonbfsidx[1,], mcols)
	VARS = VARS[,reorderidx]; 
	M = M[,reorderidx]; boundM = boundM[,reorderidx]

    if (param.trace == "trace") {
        displayas("txt")
        printf("\n[DMUi=%g]%s: classify basic and nonbasic.\n",
            dmui, tracename); M; VARS
    }

    // 3rd: slove the linear programming(LP).
	phase = 1
    lpresult = lp(M, boundM, VARS, dmui, phase, tracename, param)
	
	if(lpresult.rc) VARS[1,1] = .
    return(VARS)
}

real matrix function lp_phase2 ( real matrix M,
                                 struct BoundCond matrix boundM,
                                 real matrix VARS,
                                 real scalar dmui,
                                 string scalar aTracename,
                                 struct LpParamStruct scalar param )
{
    real matrix T, XB, orgVARS, LPRSLT
    real scalar mrows, mcols, realslacks
	real vector slackidx
    string scalar tracename, msg
	struct LpResultStruct scalar lpresult

    orgVARS = VARS
    mrows = rows(M); mcols = cols(M)

    tracename = aTracename + "-PII"

	// modify target function value:
	M[1,] = J(1,mcols,0); M[1,1] = 1
	if (param.stagestep == 1) { // X = theta
		for (j=2; j<mcols; j++) {
			if (VARS[1,j] == 1) M[1,j] = 1 // because of theta index == 1
		}
	}
	else if (param.stagestep == 2) { // X = S1 + S2 + ... + Sn
	    realslacks = (param.rts == "IRS" || param.rts == "DRS") ?
		        param.slacks-1 : param.slacks;
		slackidx = (2+param.dmus..1+param.dmus+realslacks)
		for (j=2; j<mcols; j++) {
			for (i=1; i<=realslacks; i++) {
				if (VARS[1,j] == slackidx[i] && !allof(M[,j], 0)) M[1,j] = 1
			}
		}
	}

    if (param.trace == "trace") {
        displayas("txt")
        printf("\n----------[PHASE II]----------")
        printf("\n[DMUi=%g]%s: initialize matrix.\n",
            dmui, tracename); M
        printf("\n[DMUi=%g]%s: VARS.\n", dmui, tracename); VARS
    }

    phase = 2
    lpresult = lp(M, boundM, VARS, dmui, phase, tracename, param)

    // -------------------------------------------------------------------------
    // phase 2 final.
    // -------------------------------------------------------------------------
	if(lpresult.rc) {
		LPRSLT = J(1, 1+param.dmus+param.slacks, .)
	}
	else {
		// lpresult = theta(1) + dmus + slacks
		LPRSLT = J(1, 1+param.dmus+param.slacks, 0) 
		for (j=1; j<=rows(lpresult.XB) ; j++) {
			if (VARS[1,j+1] > 0) LPRSLT[1, VARS[1,j+1]] =lpresult.XB[j, 1]
		}
		if (param.stagestep == 1 && LPRSLT[1, 1] <= 0) {
			LPRSLT[1, 1] = lpresult.xVal
		}
	}

    if (param.trace == "trace") {
        msg = sprintf("[DMUi=%g]%s-FINAL", dmui, tracename);
        printf("\n%s: original VARS.\n", msg); orgVARS
        printf("\n%s: VARS.\n", msg); VARS
        printf("\n%s: XB.\n", msg); lpresult.XB
        printf("\n%s: LPRSLT.\n", msg); LPRSLT
    }

    return(LPRSLT)
}

/**
 * Declare the LP's tableau structure.
 */
struct LpTableauStruct {
	pointer(real matrix) scalar CB, CNj
	pointer(real matrix) scalar  B,  Nj, b
	pointer(real matrix) scalar Bi,CBBi, rawXB, XB
}

/**
 * return 0: sucess
 * return 1: B inverse error
 * return 2: XB has negative value.
 */
real scalar function decompsition(real matrix M,
								struct BoundCond matrix boundM,
								real scalar mrows, 
								real scalar mcols,
								real scalar slacks,
								struct LpTableauStruct scalar tbl,
								struct LpParamStruct scalar param )
{
	real matrix CB, CNj
	real matrix  B,  Nj, b
	real matrix Bi,CBBi, rawXB, XB, BiNjXj
	real scalar Njcols, result
	
	// set the tableau.
	tbl.CB = &CB; tbl.CNj  = &CNj;  
	tbl.B  = &B;  tbl.Nj   = &Nj;   tbl.b = &b
	tbl.Bi = &Bi; tbl.CBBi = &CBBi
	tbl.rawXB = &rawXB; tbl.XB = &XB;
	
	CB  = M[1,2::1+slacks]; 		CNj = M[1,2+slacks::mcols-1]
	B   = M[2..mrows,2::1+slacks];  Nj  = M[2..mrows,2+slacks::mcols-1]   
	b   = M[2..mrows,mcols]

	Bi = lusolve(B, I(rows(B)), 1e-14)
	if (any(Bi :== .)) { // B is singular matrix.
		return (result = 1);
		// Bi = svsolve(B, I(rows(B)), 1e-14)
		// if (any(Bi :== .)) return (result = 1);
	}
	
	CBBi = CB*Bi
	// BFS(basic feasible solution)
	Njcols = cols(Nj); BiNjXj = J(rows(Nj), 1, 0)
	for (j=1; j<=Njcols; j++) {
		BiNjXj = BiNjXj :+ (Bi*Nj[.,1]*(boundM[1,1+slacks+j].val))
	}
	rawXB = Bi*b - BiNjXj
	XB = edittozerotol(rawXB, param.tol2) // BFS(basic feasible solution)
	// BFS(basic feasible solution) must be nonnegative.
	if (any(XB :< 0)) return (result = 2);

	return (result = 0); // sucess
}

struct LpResultStruct function lp ( real matrix M,
									struct BoundCond matrix boundM,
									real matrix VARS,
									real scalar dmui,
									real scalar phase,
									string scalar tracename,
									struct LpParamStruct scalar param )
{
    real matrix B, CB, Bi, b, XB, rawXB, BiNjXj, CBBi, Nj, CNj, Aj, alpha
    real matrix T, TH1, TH2, valT, lowerT, upperT, LVi, V
    real scalar mrows, mcols, enteringVar, leavingVar, calci, maxiter
    real scalar existArtificial, xVal, alphaVal
	real scalar minYn, tcols, tempVal, minVal, maxVal
	struct BoundCond matrix boundT
	struct LpResultStruct scalar lpresult
	struct LpTableauStruct scalar tbl
	
	real colvector enterings, leavings
	real scalar    enteringi, leavingi
	
	real scalar slacks, isin, tol1, tol2, isminsubscript
	string scalar trace
	
	// -------------------------------------------------------------------------
	slacks = rows(M) - 1 // number of basic feasible solution
	isin = param.isin
	tol1 = param.tol1; tol2 = param.tol2
	isminsubscript = param.isminsubscript
	trace = param.trace
    minYn = 0
	if (param.stagestep == 1) minYn = (phase == 1) ? 1 : isin
	else minYn = (phase == 1)
    // -------------------------------------------------------------------------
	mrows = rows(M); mcols = cols(M)
    LVi = J(slacks, 1, .) // leaving variable index matrix.
    // -------------------------------------------------------------------------
if (trace == "trace") {
    displayas("txt"); msg = "initial tableau in the LP."
    printf("\n[DMUi=%g]%s: %s\n", dmui, tracename, msg); M
}
	lpresult.rc = 0; lpresult.rmsg = ""
    existArtificial = (phase == 2 && any(VARS[,2::1+slacks] :< 0));
    maxiter = st_numscalar("c(maxiter)")
    for (calci=1 ; calci<=maxiter ; calci++) { // prevent infinite loop

if (trace == "trace") {
	printf("\n[DMUi=%g]%s-LOOP[%g] Start...\n", dmui, tracename, calci)
}
        B  = M[2..mrows,2::1+slacks];       CB  = M[1,2::1+slacks]
        Nj = M[2..mrows,2+slacks::mcols-1]; CNj = M[1,2+slacks::mcols-1]
		b  = M[2..mrows,mcols]

		Bi = lusolve(B, I(rows(B)), 1e-14)
		if (any(Bi :== .)) { // B is singular matrix.
		    Bi = svsolve(B, I(rows(B)), 1e-14)
			if (any(Bi :== .)) {
				lpresult.rc = 3498; 
				lpresult.rmsg = sprintf("%s[DMUi=%g][LOOP=%g]%s",
					"No Solution(BFS's inverse is not exist):",
					dmui, calci, tracename)
				break;
				
			}
		}
		CBBi = CB*Bi
		
		// BFS(basic feasible solution)
		Njcols = cols(Nj); BiNjXj = J(rows(Nj), 1, 0)
		for (j=1; j<=Njcols; j++) {
			BiNjXj = BiNjXj :+ (Bi*Nj[.,1]*(boundM[1,1+slacks+j].val))
		}
		rawXB = Bi*b - BiNjXj
		XB = edittozerotol(rawXB, tol2) // BFS(basic feasible solution)
		
		if (any(XB :== .)) {
			lpresult.rc = 3498; 
			lpresult.rmsg = sprintf("%s[DMUi=%g][LOOP=%g]%s",
				"No Solution(XB contains missing value):",
				dmui, calci, tracename)
			break;
			
		}
		
		// BFS(basic feasible solution) must be nonnegative.
		
		boundT = boundM[1,2+slacks::mcols-1]
		tcols = cols(boundT); valT = J(1,tcols,.)
		for(j=1; j<=tcols; j++) {
			valT[1,j] = boundT[1,j].val
		}
		xVal = edittozerotol((CB*rawXB + CNj*valT'), tol2) // objective funtion value
        
        T = VARS[1,2::1+rows(XB)] // rows(XB) equals to the number of slacks.

if (trace == "trace") {
    printf("\n[DMUi=%g]%s-LOOP[%g]: CBBi * b = %g\n",
        dmui, tracename, calci, xVal);
    display("Entered index(if value is negative, that's artificial):"); T;
    display("XB = Bi*b - BiNjXj:"); rawXB;
}

        // ---------------------------------------------------------------------
        // loop termination condition.
        // ---------------------------------------------------------------------
        if (phase == 1) {
            // objective function value is zero
			if (xVal == 0 ) {
				// if all artificals are out or the remaining artificals are at zero, 
				// stop and go phaseII
				T = (T :< 0) // artificial remain or not?
				if (allof(T, 0) || allof(select(XB, T'), 0)) break;
				
				// If the remaining artificails are not at zero, No Solution.
				lpresult.rc = 3498
				lpresult.rmsg = sprintf("%s[DMUi=%g][LOOP=%g]%s",
					"No Solution(Remaining artificails are not at zero):",
					dmui, calci, tracename)
				break;
				
			}
		}

        // ---------------------------------------------------------------------
        // Select entering variable.
        // ---------------------------------------------------------------------
        enteringVar = 0; tempVal = 0; minVal = 0; maxVal = 0; boundi = 0
        Njcols = cols(Nj); T = J(1, Njcols, .)
        for (j=1; j<=Njcols; j++) {
            tempVal = CBBi * Nj[,j] - CNj[1,j]
			// if (abs(tempVal) < tol1) continue;

			boundi = 1 + slacks + j
			if (boundM[1,boundi].val == boundM[1,boundi].lower) { // lower bound
				T[1,j] = tempVal
			}
			else { // upper bound
				T[1,j] = -tempVal
			}
        } // end of for
		
		if (!minYn) { // maximization.
			T = T :/ (T :< 0)
			if (!allof(T, .)) {
				minindex(T, 1, enterings, w); enteringi = 1
				enteringVar = enterings[enteringi]
				evj = 1+slacks+enteringVar
			}
		}
		else { // minimization.
			T = T :/ (T :> 0)
			if (!allof(T, .)) {
				maxindex(T, 1, enterings, w); enteringi = 1
				enteringVar = enterings[enteringi]
				evj = 1+slacks+enteringVar
			}
		}

        // No more candidate for entering variable.
        if (enteringVar == 0) {
			if (trace == "trace") {
                printf("\n[DMUi=%g]%s-LOOP[%g]:", dmui, tracename, calci)
                printf("No more candidate for entering variable.\n:(CB*Bi*Nj)-Cj\n");T
            }
			if (phase == 1) {
				lpresult.rc = 3498; 
				lpresult.rmsg = sprintf("%s[DMUi=%g][LOOP=%g]%s",
					"No Solution(No more candidate for entering variable):",
					dmui, calci, tracename)
			}
            break
        }

if (trace == "trace") {
    displayas("txt"); msg = "Select entering variable."
    printf("\n[DMUi=%g]%s-LOOP[%g]: %s(%g:%g)\n:(CB*Bi*Nj)-Cj\n",
        dmui, tracename, calci, msg, enteringVar, T[enteringVar]); T
}

        // ---------------------------------------------------------------------
        // Select leaving variable.
        // ---------------------------------------------------------------------
        leavingVar = 0
        Aj = Nj[,enteringVar]
        alpha = edittozerotol(Bi*Aj, tol1)
        if (existArtificial) {
            T = VARS[1,2::1+slacks]; tcols = cols(T)
            for (j=1; j<=tcols; j++) {
                if (T[1,j] < 0 && alpha[j,1] != 0) {
                    leavingVar = j; lvj = 1+leavingVar
                    break;
                }
            }
        }
		
		if (leavingVar == 0) {
			boundT = boundM[1,2::1+slacks]
			tcols = cols(boundT)
			lowerT = upperT = J(1,tcols,.)
			for(j=1; j<=tcols; j++) {
				lowerT[1,j] = boundT[1,j].lower
				upperT[1,j] = boundT[1,j].upper
			}
			
			// XB=Bi*b
			leavingCase = 0
			if (boundM[1,evj].val ==  boundM[1,evj].lower) {
				minVal = .;
				// 1. alpha's positive min value
				TH1 = boundM[1,evj].lower :+ ((rawXB :- lowerT') 
											:/ (alpha :* (alpha :> 0)))
				// TH1 = edittozerotol(TH1, tol1)
				if (any(TH1 :< minVal)) {
					minindex(TH1, 1, mi, w)
					leavingVar = mi[1]; lvj = 1+leavingVar
					if (phase == 1 && w[1,2] >= 2 && VARS[1,lvj] > 0) {
						// if phase 1 and same min ratio test result,
						// artificial variable must leave first.
						tcols = w[1,2]
						for (j=2; j<=tcols; j++) {
							if (VARS[1,mi[j]+1] < 0) {
								leavingVar = mi[j]; lvj = 1+leavingVar
								break;
							}
						}
					}
					minVal = TH1[leavingVar,1]; 
					leavingCase = 1
				}
				// 2. alpha's negative min value
				TH2 = boundM[1,evj].lower :+ ((rawXB :- upperT') 
											:/ (alpha :* (alpha :< 0)))
				// TH2 = edittozerotol(TH2, tol1)
				if (any(TH2 :< minVal)) {
					minindex(TH2, 1, mi, w)
					leavingVar = mi[1]; lvj = 1+leavingVar
					minVal = TH1[leavingVar,1]; leavingCase = 2
				}
				// 3. get the enteringVar's upper value
				if (boundM[1,evj].upper < minVal) {
					minVal = boundM[1,evj].upper; leavingCase = 3
				}
				
if (trace == "trace") {
    displayas("txt"); msg = "Select leaving variable.[MinVal]"
    printf("\n[DMUi=%g]%s-LOOP[%g]: %s(%g:%g)\n",
        dmui, tracename, calci, msg, leavingVar, minVal)
    display("XB | alpha:(XB=Bi*b, alpha=Bi*Aj):");rawXB,alpha
    display("[MinVal]enteringVar's upper | theta1 | theta2")
	printf("\n[boundM[1,%g].upper:%g][leavingCase:%g]\n",
			evj, boundM[1,evj].upper, leavingCase); TH1,TH2
}

				if (leavingCase == 1) {
					boundM[1,lvj].val = boundM[1,lvj].lower
				}
				else if (leavingCase == 2) {
					boundM[1,lvj].val = boundM[1,lvj].upper
				}
				else { // if (leavingCase == 3)
					boundM[1,evj].val = boundM[1,evj].upper; continue;
				}
			}
			else { // if (boundM[1,evj].val ==  boundM[1,evj].upper)
				maxVal = 0;
				// 1. alpha's positive min value
				TH1 = boundM[1,evj].upper :+ ((rawXB :- upperT') 
											:/ (alpha :* (alpha :> 0)))
				// TH1 = edittozerotol(TH1, tol1)
				if (any(TH1 :> maxVal)) {
					maxindex(TH1, 1, mi, w)
					leavingVar = mi[1]; lvj = 1+leavingVar
					maxVal = TH1[leavingVar,1]; leavingCase = 1
				}
				// 2. alpha's negative min value
				TH2 = boundM[1,evj].upper :+ ((rawXB :- lowerT') 
											:/ (alpha :* (alpha :< 0)))
				// TH2 = edittozerotol(TH2, tol1)
				if (any(TH2 :> maxVal)) {
					maxindex(TH2, 1, mi, w)
					leavingVar = mi[1]; lvj = 1+leavingVar
					maxVal = TH1[leavingVar,1]; leavingCase = 2
				}
				// 3. get the enteringVar's lower value
				if (boundM[1,evj].lower > maxVal) {
					maxVal = boundM[1,evj].lower; leavingCase = 3
				}

if (trace == "trace") {
    displayas("txt"); msg = "Select leaving variable.[MaxVal]"
    printf("\n[DMUi=%g]%s-LOOP[%g]: %s(%g:%g)\n",
        dmui, tracename, calci, msg, leavingVar, maxVal)
    display("XB | alpha:(XB=Bi*b, alpha=Bi*Aj):");XB,alpha
    display("[MaxVal]enteringVar's lower | theta1 | theta2")
	printf("\n[boundM[1,%g].lower:%g][leavingCase:%g]\n",
			evj, boundM[1,evj].lower, leavingCase); TH1,TH2
}

			    if (leavingCase == 1) {
					boundM[1,lvj].val = boundM[1,lvj].upper
				}
				else if (leavingCase == 2) {
					boundM[1,lvj].val = boundM[1,lvj].lower
				}
				else  { // if (leavingCase == 3)
					boundM[1,evj].val = boundM[1,evj].lower; continue;
				}
			}
        }

        // If no leaving variable exits
        if (leavingVar == 0) {
            if (trace == "trace")
                display("Break: No more candidate for leaving variable.")
			
			lpresult.rc = 3498; 
			lpresult.rmsg = sprintf("%s[DMUi=%g][LOOP=%g]%s",
				"No Solution(No more candidate for leaving variable):",
				dmui, calci, tracename)
					
            break
        }
        // theta is not leaving at 2nd phase. // 
        if (phase == 2 && VARS[,lvj] == 1) {
            if (trace == "trace") display("Break: theta(еш) is not leaving.")
            break
        }

        // ---------------------------------------------------------------------
        // reply calculatation result.
        // ---------------------------------------------------------------------
		LVi[leavingVar,1] = VARS[,evj]
		_swapcols(M, lvj, evj)
		_swapcols(boundM, lvj, evj)
		_swapcols(VARS, lvj, evj)

        // Clear artificial variable
		if (VARS[,evj] < 0) {
			T = J(1, cols(VARS), 1); T[1,evj] = 0
			
			VARS   = select(VARS, T)
			M      = select(M, T)
			boundM = select(boundM, T)
			mcols  = cols(M)
			
			// if artificial variable exist at phase II
			if (existArtificial) {
				existArtificial = any(VARS[,2::1+slacks] :< 0)
			}
		}

if (trace == "trace") {
    printf("\n[DMUi=%g]%s-LOOP[%g]: updated tableau.[%g(%g) <--> %g(%g)]\n",
        dmui, tracename, calci, lvj, leavingVar, evj, enteringVar); M
    display("LVi: Entered variable's VARS index value."); LVi
    display("VARS: Variable's index."); VARS
}

    } //end of main for

    // return lpresult
	if (calci > maxiter) {
		lpresult.rc = 3498; 
		lpresult.rmsg = sprintf("%s[DMUi=%g][LOOP=%g]%s",
			"No Solution(LOOP greater than maxiter):",
			dmui, calci, tracename)
	}
	if(lpresult.rc) display(lpresult.rmsg)
	lpresult.xVal = xVal
	lpresult.XB = XB
    return(lpresult)
}
/* A[.,lvj] <--> A[.,evj] */
function _swapcols( transmorphic matrix A, 
					real scalar lvj, 
					real scalar evj )
{
		transmorphic colvector  v

		v = A[., lvj]
		A[., lvj] = A[., evj]
		A[., evj] = v
}


function replacesubmat ( transmorphic matrix M,
                         real scalar row,
                         real scalar col,
                         transmorphic matrix T )
{
    M[|row,col\row + rows(T) - 1, col + cols(T) - 1|] = T
}

function _setup_dearslt_names(string scalar dearsltmat,
                              string scalar dmuinmat,
                              string scalar dmuoutmat )
{
    string matrix DMU_CS     // dmu in matrix column stripes
    string matrix DEARSLT_CS // dea result matrix column stripes
    string matrix DEARSLT_RS // dea result matrix row stripes
    real matrix M
    real scalar mcols, cnt

    M = st_matrix(dearsltmat)
    mcols = cols(M)

    DMU_CS = st_matrixcolstripe(dmuinmat)
    for (i = 1; i <= rows(DMU_CS); i++) {
        DMU_CS[i, 1] = "ref"
    }

    DEARSLT_CS = ("","rank"\"","theta")\DMU_CS\ // column join
        st_matrixrowstripe(dmuinmat)\st_matrixrowstripe(dmuoutmat)
    if (mcols - rows(DEARSLT_CS) > 0) {
        cnt = 0
        for (i = rows(DEARSLT_CS)+1 ; i <= mcols ; i++) {
            DEARSLT_CS = DEARSLT_CS \ ("slack", "slack_" + strofreal(++cnt))
        }
    }

    DEARSLT_RS = st_matrixcolstripe(dmuinmat)

    // name the row and column of dea result matrix
    st_matrixrowstripe(dearsltmat, DEARSLT_RS)
    st_matrixcolstripe(dearsltmat, DEARSLT_CS)
}

/**
 * deamat - dmucount x ( 1(theta) + dmu count + slcak(in, out) count)
 */
function _dmurank( string scalar deamat,
                   real scalar dmuincount,
                   real scalar dmuoutcount,
                   real scalar minrank,
                   real scalar tol )
{
    real matrix M
    real rowvector v, vv, retvec, slcaksum
    real scalar m, mm, row

    M = st_matrix(deamat)
    v = round(M[,1], tol)
    if (minrank) minindex(v, rows(v), i, w)
    else maxindex(v, rows(v), i, w)

    retvec = J(rows(v), 1, .)
    if (allof(w[,2], 1)) {
        retvec[i[1::rows(v)]] = (1::rows(v))
    }
    else {
        // rank correction for ties
        slcaksum = rowsum(M[|1,cols(M) - (dmuincount + dmuoutcount - 1)\.,.|])
        for (m = 1; m <= rows(w); m++) {
            if (w[m,2] >= 2) {
                vv = i[w[m,1]::(w[m,1] + w[m,2] - 1)]
                if (minrank) maxindex(slcaksum[vv], w[m,2], ii, ww)
                else minindex(slcaksum[vv], w[m,2], ii, ww)
                for (mm = 1; mm <= rows(ww); mm++) {
                    for (row = ww[mm,1]; row < ww[mm,1] + ww[mm,2]; row++) {
                        retvec[vv[ii[row]]] = w[m,1] + ww[mm,1] - 1
                    }
                }
            }
            else {
                retvec[i[w[m,1]]] = w[m,1] // row = w[m,1]
            }
        }
    }
    st_matrix("r(rank)", retvec)
}

function maxvecindex( string scalar vecname )
{
    real matrix A

    A = st_matrix(vecname)
    maxindex(A, 1, i, w)

    st_numscalar("r(maxval)", A[i[1]])
    st_numscalar("r(maxindex)", i[1])
    st_matrix("r(maxindexes)", i)
}

function minvecindex( string scalar vecname )
{
    real matrix A

    A = st_matrix(vecname)
    if (sum(A :< .) > 0) {
        minindex(A, 1, i, w)
        st_numscalar("r(minval)", A[i[1]])
        st_numscalar("r(minindex)", i[1])
        st_matrix("r(minindexes)", i)
    }
    // if overall missing value.
    else {
        st_numscalar("r(minval)", .)
        st_numscalar("r(minindex)", 0)
        st_matrix("r(minindexes)", 0)
    }
}

function _roundmat( string scalar matname, real scalar tol )
{
    real matrix A
    A = round(st_matrix(matname), tol)
    st_matrix(matname, A)
}

function _uniqrowmat( string scalar matname, string scalar varname )
{
    st_matrix(matname, sort(uniqrows(st_data(., varname)), 1))
}

function _file_exists( string scalar fn )
{
    st_numscalar("r(fileexists)", fileexists(fn))
}
end

// End of the MATA Definition Area ---------------------------------------------

