*! ivreg2h  1.0.6  11aug2013  cfb/mes
*! cloned from
*! xtivreg2 1.0.13 28Aug2011
*! author mes
*! 1.0.4: reinstate xtivreg2 code to fix up vnames
*! 1.0.5: deal with inadequate number excluded insts, logic driving est table
*! 1.0.6: introduce gen option to generate and leave behind generated instruments, with stub and replace option
*!        fix e(cmd) and e(cmdline) macros

program define ivreg2h, eclass byable(recall)
	version 8.2
	local lversion 01.0.6
// will be overridden by ivreg2 e(version) for ivreg2_p

	if replay() {
		syntax [, FIRST FFIRST rf Level(integer $S_level) NOHEader NOFOoter /*
			*/ EForm(string) PLUS VERsion]

		if "`version'" != "" & "`first'`ffirst'`rf'`noheader'`nofooter'`eform'`plus'" != "" {
			di as err "option version not allowed"
			error 198
		}
		if "`version'" != "" {
			di in gr "`lversion'"
			ereturn clear
			ereturn local version `lversion'
			ereturn local cmd "ivreg2h"
			exit
		}
		if `"`e(cmd)'"' != "ivreg2h"  {
			error 301
		}
		tempname regest
		capture _estimates hold `regest', restore
		local ivreg2_cmd "ivreg2"
		capture `ivreg2_cmd', version
        if _rc != 0 {
* No ivreg2, check for ivreg29 or ivreg28
            local ivreg2_cmd "ivreg29"
            capture `ivreg2_cmd', version
            if _rc != 0 {
                local ivreg2_cmd "ivreg28"
                capture `ivreg2_cmd', version
                if _rc != 0 {   
di as err "Error - must have ivreg2/ivreg29/ivreg28 version 2.1.15 or greater installed"
                exit 601
                }
            }
        }
		local vernum "`e(version)'"
		capture _estimates unhold `regest'	
	}
// end replay()
	else {

		local cmdline "ivreg2h `*'"

		syntax [anything(name=0)] [if] [in] [aw fw pw iw/] , [ fe fd /*
			*/	Ivar(varname) Tvar(varname) first ffirst rf /*
			*/	savefirst SAVEFPrefix(name) saverf SAVERFPrefix(name) CLuster(varlist)	/*
			*/	orthog(string) ENDOGtest(string) REDundant(string) PARTIAL(string)		/*
			*/	BW(string) SKIPCOLL														/*
			*/	GEN1 GEN2(string)														/*
			*/	* ]

// ms - `gen'=1 if ivreg2h leaves behind generated instruments, =0 if not
		local gen = ("`gen1'`gen2'"~="")

		local n 0

		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
		if `s(stop)' {
			error 198
		}
		while `s(stop)'==0 {
			if "`paren'"=="(" {
				local n = `n' + 1
				if `n'>1 { 
capture noi error 198 
di in red `"syntax is "(all instrumented variables = instrument variables)""'
exit 198
				}
				gettoken p lhs : lhs, parse(" =")
				while "`p'"!="=" {
					if "`p'"=="" {
capture noi error 198 
di in red `"syntax is "(all instrumented variables = instrument variables)""'
di in red `"the equal sign "=" is required"'
exit 198 
					}
					local endo `endo' `p'
					gettoken p lhs : lhs, parse(" =")
				}
* To enable Cragg HOLS estimator, allow for empty endo list
				if "`endo'" != "" {
					tsunab endo : `endo'
				}
* To enable OLS estimator with (=) syntax, allow for empty exexog list
				if "`lhs'" != "" {
					tsunab exexog : `lhs'
				}
			}
			else {
				local inexog `inexog' `lhs'
			}
			gettoken lhs 0 : 0, parse(" ,[") match(paren)
			IsStop `lhs'
		}
		local 0 `"`lhs' `0'"'

		tsunab inexog : `inexog'
		tokenize `inexog'
		local lhs "`1'"
		local 1 " " 
		local inexog `*'

		tempname regest
		capture _estimates hold `regest', restore
		local ivreg2_cmd "ivreg2"
		capture `ivreg2_cmd', version
		local vernum "`e(version)'"
		loc lversion `vernum'
		capture _estimates unhold `regest'

		if "`gmm'" != "" & "`exexog'" == "" {
di as err "option -gmm- invalid: no excluded instruments specified"
			exit 102
		}

* If first requested, also needs to request savefirst or savefprefix and set drop flag
		if "`first'" != "" & "`savefirst'`savefprefix'" == "" {
			local savefirst "savefirst"
			local dropfirst "dropfirst"
		}
		if "`savefirst'" != "" & "`savefprefix'" == "" {
			local savefprefix "_xtivreg2_"
		}

* If rf requested, also needs to request saverf or saverfprefix and set drop flag
		if "`rf'" != "" & "`saverf'`saverfprefix'" == "" {
			local saverf "saverf"
			local droprf "droprf"
		}
		if "`saverf'" != "" & "`saverfprefix'" == "" {
			local saverfprefix "_xtivreg2_"
		}

		tempvar wvar
		if "`weight'" !="" {
			local wtexp `"[`weight'=`exp']"'
			gen double `wvar'=`exp'
		}
		else {
			gen long `wvar'=1
		}

* Begin estimation blocks
			loc qq qui
			marksample touse
			markout `touse' `lhs' `inexog' `exexog' `endo' `cluster' /* `tvar' */, strok
			tsrevar `lhs', substitute
			local lhs_t "`r(varlist)'"
			tsrevar `inexog', substitute
			local inexog_t "`r(varlist)'"
			loc n_inex : word count `inexog_t'
// di in r "n_inex `n_inex'"
			tsrevar `endo', substitute
			local endo_t "`r(varlist)'"
			loc n_endo : word count `endo_t'
// di in r "n_endo `n_endo'"
			tsrevar `exexog', substitute
			local exexog_t "`r(varlist)'"
			loc n_exex : word count `exexog_t'
// di in r "n_exex `n_exex'"
			tsrevar `orthog', substitute
			local orthog_t "`r(varlist)'"
			tsrevar `endogtest', substitute
			local endogtest_t "`r(varlist)'"
			tsrevar `redundant', substitute
			local redundant_t "`r(varlist)'"
			tsrevar `partial', substitute
			local partial_t "`r(varlist)'"

* preserve here, prior to first sort
// cfb disabled			preserve
            tempname b V S W firstmat touse2
// cfb ivreg2h: switch off noconstant
			local dofminus 0
// cfb check classical id status
			loc n_est 0
			if `n_exex' == 0 | `n_endo' > `n_exex' {
				if "`inexog_t'" == "" {
					di as res _n "No excluded instruments: standard IV model not estimable"
				}
				else {
					di as res _n "Too few excluded instruments: standard IV model not estimable"
				}
			cap est drop StdIV
			} 
		else {
// COMPUTE STANDARD IV RESULTS IF EQUATION IS IDENTIFIED
			di as res _n " ***** Standard IV Results *****"
									
				`qq'    `ivreg2_cmd' `lhs_t' `inexog_t' (`endo_t' = `exexog_t') `wtexp' if `touse', ///
						dofminus(`dofminus') /* nocons */ `first' `ffirst' `rf' ///
						savefprefix(`savefprefix') saverfprefix(`saverfprefix') ///
						cluster(`cluster') orthog(`orthog_t') endog(`endogtest_t') ///
						redundant(`redundant_t') partial(`partial_t') tvar(`tvar') bw(`bw') `options'

* Replace any time series locals with original time series names
// cfb
                        g byte `touse2' = `touse'

* Now fix main results
                        mat `b'       =e(b)
                        mat `V'       =e(V)
                        mat `S'       =e(S)
                        mat `W'       =e(W)
                        mat `firstmat'=e(first)
* Matrix column names to be changed
                        local l_cnames  : colnames `b'
                        local l_cnamesS : colnames `S'
                        local l_cnamesW : colnames `W'
                        local l_cnamesf : colnames `firstmat'
* Full list of names to change
                        local l_vnames   "`lhs'   `inexog'   `endo'   `exexog'"
                        local l_vnames_t "`lhs_t' `inexog_t' `endo_t' `exexog_t'"
* Macros to be fixed
                        local l_insts     "`e(insts)'"
                        local l_inexog    "`e(inexog)'"
                        local l_instd     "`e(instd)'"
                        local l_exexog    "`e(exexog)'"
                        local l_depvar    "`e(depvar)'"
                        local l_clist     "`e(clist)'"
                        local l_elist     "`e(elist)'"
                        local l_redlist   "`e(redlist)'"
                        local l_partial  "`e(partial)'"
* If any collinear or duplicates
                        local l_collin    "`e(collin)'"
                        local l_dups      "`e(dups)'"
                        local l_insts1    "`e(insts1)'"
                        local l_inexog1   "`e(inexog1)'"
                        local l_instd1    "`e(instd1)'"
                        local l_exexog1   "`e(exexog1)'"
                        local l_partial1  "`e(partial1)'"
                        foreach vn of local l_vnames {
                                tokenize `l_vnames_t'
                                local vn_t `1'
                                mac shift
                                local l_vnames_t `*'
                                local l_cnames  : subinstr local l_cnames    "`vn_t'" "`vn'"
                                local l_cnamesS : subinstr local l_cnamesS   "`vn_t'" "`vn'"
                                local l_cnamesW : subinstr local l_cnamesW   "`vn_t'" "`vn'"
                                local l_cnamesf : subinstr local l_cnamesf   "`vn_t'" "`vn'"
* Macro varlists
                                local l_insts   : subinstr local l_insts     "`vn_t'" "`vn'"
                                local l_inexog  : subinstr local l_inexog    "`vn_t'" "`vn'"
                                local l_instd   : subinstr local l_instd     "`vn_t'" "`vn'"
                                local l_exexog  : subinstr local l_exexog    "`vn_t'" "`vn'"
                                local l_partial : subinstr local l_partial   "`vn_t'" "`vn'"
                                local l_depvar  : subinstr local l_depvar    "`vn_t'" "`vn'"
                                local l_clist   : subinstr local l_clist     "`vn_t'" "`vn'"
                                local l_elist   : subinstr local l_elist     "`vn_t'" "`vn'"
                                local l_redlist : subinstr local l_redlist   "`vn_t'" "`vn'"
                                local l_collin  : subinstr local l_collin    "`vn_t'" "`vn'"
                                local l_dups    : subinstr local l_dups      "`vn_t'" "`vn'"
                                local l_insts1  : subinstr local l_insts1    "`vn_t'" "`vn'"
                                local l_inexog1 : subinstr local l_inexog1   "`vn_t'" "`vn'"
                                local l_instd1  : subinstr local l_instd1    "`vn_t'" "`vn'"
                                local l_exexog1 : subinstr local l_exexog1   "`vn_t'" "`vn'"
                                local l_partial1: subinstr local l_partial1  "`vn_t'" "`vn'"
                        }
                        mat colnames `b'       =`l_cnames'
                        mat colnames `V'       =`l_cnames'
                        mat rownames `V'       =`l_cnames'
                        mat colnames `S'       =`l_cnamesS'
                        mat rownames `S'       =`l_cnamesS'
                        mat colnames `W'       =`l_cnamesW'
                        mat rownames `W'       =`l_cnamesW'
                        mat colnames `firstmat'=`l_cnamesf'

                        ereturn post `b' `V', dep(`l_depvar') esample(`touse2') noclear
                        ereturn matrix S `S'
                        if ~matmissing(`W') {
                                ereturn matrix W `W'
                        }
                        if ~matmissing(`firstmat') {
                                ereturn matrix first `firstmat'
                        }
                        ereturn local insts    `l_insts'
                        ereturn local inexog   `l_inexog'
                        ereturn local instd    `l_instd'
                        ereturn local exexog   `l_exexog'
                        ereturn local partial  `l_partial'
                        ereturn local collin   `l_collin'
                        ereturn local dups     `l_dups'
                        ereturn local insts1   `l_insts1'
                        ereturn local inexog1  `l_inexog1'
                        ereturn local instd1   `l_instd1'
                        ereturn local exexog1  `l_exexog1'
                        ereturn local partial1 `l_partial1'
                        ereturn local depvar   `l_depvar'
                        ereturn local clist    `l_clist'
                        ereturn local elist    `l_elist'
                        ereturn local redlist  `l_redlist'
                        ereturn scalar sigma_e=e(rmse)
//				est replay
				est store StdIV
				loc ++n_est
 `ivreg2_cmd', `first' `ffirst' `rf' `noheader' `nofooter' `plus' `levopt' `efopt' `dropfirst' `droprf'
 		}	// end standard IV block
			
// COMPUTE RESULTS FOR GENERATED INSTRUMENTS ONLY

// Even if no excluded insts, must generate insts						
// Lewbel hetero instruments, based only on centered included exog in FSR

// di as err "original inexog"
// di as err "`e(inexog)'"
                local l_inexog    "`e(inexog)'"
                local l_inexog : subinstr local l_inexog "." "_", all
// di as err "new inexog"
// di as err "`l_inexog'"
				loc n_inexog: word count `inexog_t'
				if `n_inexog' == 0 {
					di in red _n "Error: no Z variables available for construction of generated instruments." _n
					error 198
				}
				loc n_endo_t: word count `endo_t'
				loc geninst_t	
				loc geninst
				loc i 0		
				foreach e of local endo_t {
					qui reg `e' `inexog_t' if `touse'
					tempvar `e'_eps
					qui predict double ``e'_eps' if e(sample), residual
					loc ++i
					loc en: word `i' of `endo'
					foreach v of local inexog_t {
                        tokenize `l_inexog'
                        local vn `1'
                        mac shift
                        local l_inexog `*'
 						tempvar z_`e'_`v'_eps
						su `v' if `touse', mean
						qui g double `z_`e'_`v'_eps' = (`v' - r(mean)) * ``e'_eps' if `touse'
						loc geninst_t "`geninst_t' `z_`e'_`v'_eps'"
						loc geninst "`geninst' `en'_`vn'_g"
					}
				}
// di "geninst and geninst_t (immediately after creation):"
// di as err "`geninst'"
// di as err "`geninst_t'"

// even though residuals are uncorrelated with the regressors used to generate them, 
// the product of residuals and the (centered) regressors are non-null
				
		di as res _n " ***** IV with Generated Instruments only *****"
// list of original regressors here		
		di as res "Instruments created from Z:"_n "`inexog'"

				`qq'    `ivreg2_cmd' `lhs_t' `inexog_t' (`endo_t' = `geninst_t') `wtexp' if `touse', ///
						dofminus(`dofminus') /* nocons */ `first' `ffirst' `rf' ///
						savefprefix(`savefprefix') saverfprefix(`saverfprefix') ///
						cluster(`cluster') orthog(`orthog_t') endog(`endogtest_t') ///
						redundant(`redundant_t') partial(`partial_t') tvar(`tvar') bw(`bw') `options'

* Replace any time series locals with original time series names
// cfb
                        g byte `touse2' = `touse'
* Now fix main results
                        mat `b'       =e(b)
                        mat `V'       =e(V)
                        mat `S'       =e(S)
                        mat `W'       =e(W)
                        mat `firstmat'=e(first)
* Matrix column names to be changed
                        local l_cnames  : colnames `b'
                        local l_cnamesS : colnames `S'
                        local l_cnamesW : colnames `W'
                        local l_cnamesf : colnames `firstmat'
* Full list of names to change
                        local l_vnames   "`lhs'   `inexog'   `endo'   `exexog'   `geninst'"
                        local l_vnames_t "`lhs_t' `inexog_t' `endo_t' `exexog_t' `geninst_t'" 
//         di as err    "`geninst_t'"
//         di as err _n "`geninst'"
//         di as err    "`e(inexog)'"
* Macros to be fixed
                        local l_insts     "`e(insts)'"
                        local l_inexog    "`e(inexog)'"
                        local l_instd     "`e(instd)'"
                        local l_exexog    "`e(exexog)'"
                        local l_depvar    "`e(depvar)'"
                        local l_clist     "`e(clist)'"
                        local l_elist     "`e(elist)'"
                        local l_redlist   "`e(redlist)'"
                        local l_partial   "`e(partial)'"
* If any collinear or duplicates
                        local l_collin    "`e(collin)'"
                        local l_dups      "`e(dups)'"
                        local l_insts1    "`e(insts1)'"
                        local l_inexog1   "`e(inexog1)'"
                        local l_instd1    "`e(instd1)'"
                        local l_exexog1   "`e(exexog1)'"
                        local l_partial1  "`e(partial1)'"
                        foreach vn of local l_vnames {
                                tokenize `l_vnames_t'
                                local vn_t `1'
                                mac shift
                                local l_vnames_t `*'
                                local l_cnames  : subinstr local l_cnames    "`vn_t'" "`vn'"
                                local l_cnamesS : subinstr local l_cnamesS   "`vn_t'" "`vn'"
                                local l_cnamesW : subinstr local l_cnamesW   "`vn_t'" "`vn'"
                                local l_cnamesf : subinstr local l_cnamesf   "`vn_t'" "`vn'"
* Macro varlists
                                local l_insts   : subinstr local l_insts     "`vn_t'" "`vn'"
                                local l_inexog  : subinstr local l_inexog    "`vn_t'" "`vn'"
                                local l_instd   : subinstr local l_instd     "`vn_t'" "`vn'"
                                local l_exexog  : subinstr local l_exexog    "`vn_t'" "`vn'"
                                local l_partial : subinstr local l_partial   "`vn_t'" "`vn'"
                                local l_depvar  : subinstr local l_depvar    "`vn_t'" "`vn'"
                                local l_clist   : subinstr local l_clist     "`vn_t'" "`vn'"
                                local l_elist   : subinstr local l_elist     "`vn_t'" "`vn'"
                                local l_redlist : subinstr local l_redlist   "`vn_t'" "`vn'"
                                local l_collin  : subinstr local l_collin    "`vn_t'" "`vn'"
                                local l_dups    : subinstr local l_dups      "`vn_t'" "`vn'"
                                local l_insts1  : subinstr local l_insts1    "`vn_t'" "`vn'"
                                local l_inexog1 : subinstr local l_inexog1   "`vn_t'" "`vn'"
                                local l_instd1  : subinstr local l_instd1    "`vn_t'" "`vn'"
                                local l_exexog1 : subinstr local l_exexog1   "`vn_t'" "`vn'"
                                local l_partial1: subinstr local l_partial1  "`vn_t'" "`vn'"
                        }
//                   di as err "`l_inexog'"
                        mat colnames `b'       =`l_cnames'
                        mat colnames `V'       =`l_cnames'
                        mat rownames `V'       =`l_cnames'
                        mat colnames `S'       =`l_cnamesS'
                        mat rownames `S'       =`l_cnamesS'
                        mat colnames `W'       =`l_cnamesW'
                        mat rownames `W'       =`l_cnamesW'
                        mat colnames `firstmat'=`l_cnamesf'

                        ereturn post `b' `V', dep(`depvar') esample(`touse2') noclear
                        ereturn matrix S `S'
                        if ~matmissing(`W') {
                                ereturn matrix W `W'
                        }
                        if ~matmissing(`firstmat') {
                                ereturn matrix first `firstmat'
                        }
                        ereturn local insts    `l_insts'
                        ereturn local inexog   `l_inexog'
                        ereturn local instd    `l_instd'
                        ereturn local exexog   `l_exexog'
                        ereturn local partial  `l_partial'
                        ereturn local collin   `l_collin'
                        ereturn local dups     `l_dups'
                        ereturn local insts1   `l_insts1'
                        ereturn local inexog1  `l_inexog1'
                        ereturn local instd1   `l_instd1'
                        ereturn local exexog1  `l_exexog1'
                        ereturn local partial1 `l_partial1'
                        ereturn local depvar   `l_depvar'
                        ereturn local clist    `l_clist'
                        ereturn local elist    `l_elist'
                        ereturn local redlist  `l_redlist'
// ms
 						ereturn local cmd		"ivreg2h"
 						ereturn local cmdline	"`cmdline'"
 						if `gen' {
							ereturn local geninsts "`geninst'"
						}
                        ereturn scalar sigma_e=e(rmse)
// **********
//				est replay
				est store GenInst
				loc ++n_est
// ms
// hack to enable ivreg2 to do the replaying
				ereturn local cmd "`ivreg2_cmd'"
 `ivreg2_cmd', `first' `ffirst' `rf' `noheader' `nofooter' `plus' `levopt' `efopt' `dropfirst' `droprf'
// ms
// undo hack
				ereturn local cmd "ivreg2h"
//		su `geninst' if e(sample)
//		corr `geninst' `inexog_t' if e(sample)
				
// COMPUTE RESULTS FOR GENERATED AND EXCLUDED INSTRUMENTS
				
// Lewbel hetero instruments, based on centered included exog + excluded exog in FSR
		if "`exexog_t'" != "" {
                local l_inexog    "`e(inexog)'"
                local l_inexog : subinstr local l_inexog "." "_", all
				loc n_inexog: word count `inexog_t'
				if `n_inexog' == 0 {
					di in red _n "Error: no Z variables available for construction of generated instruments." _n
					error 198
				}
				loc n_endo_t: word count `endo_t'
				loc geninst_t 	
				loc geninst 
				loc i 0		
				foreach e of local endo_t {
					qui reg `e' `inexog_t' if `touse'
					tempvar `e'_eps
					qui predict double ``e'_eps' if e(sample), residual
					loc ++i
					loc en: word `i' of `endo'
					foreach v of local inexog_t {
                        tokenize `l_inexog'
                        local vn `1'
                        mac shift
                        local l_inexog `*'
						tempvar z_`e'_`v'_eps
						su `v' if `touse', mean
						qui g double `z_`e'_`v'_eps' = (`v' - r(mean)) * ``e'_eps' if `touse'
						loc geninst_t "`geninst_t' `z_`e'_`v'_eps'"
						loc geninst "`geninst' `en'_`vn'_g"
					}
				}

// MS: if standard IV estimation identified, and orthog option empty,
// automatically report test of orthogonality of generated IVs
		if "exexog_t" ~= "" & "`orthog'"=="" {
			local orthog_t "`exexog_t'"
		}

		di as res _n " ***** IV with Generated Instruments and External Instruments  *****"
// list of original regressors here		
		di as res "Instruments created from Z:" _n "`inexog'"				
//         di as err    "`geninst_t'"
//         di as err _n "`geninst'"						
			   `qq'    `ivreg2_cmd' `lhs_t' `inexog_t' (`endo_t' = `exexog_t' `geninst_t') `wtexp' if `touse', ///
						dofminus(`dofminus') /* nocons */ `first' `ffirst' `rf' ///
						savefprefix(`savefprefix') saverfprefix(`saverfprefix') ///
						cluster(`cluster') orthog(`orthog_t') endog(`endogtest_t') ///
						redundant(`redundant_t') partial(`partial_t') tvar(`tvar') bw(`bw') `options'
						
* Replace any time series locals with original time series names

* Now fix main results
                        mat `b'       =e(b)
                        mat `V'       =e(V)
                        mat `S'       =e(S)
                        mat `W'       =e(W)
                        mat `firstmat'=e(first)
* Matrix column names to be changed
                        local cnames  : colnames `b'
                        local cnamesS : colnames `S'
                        local cnamesW : colnames `W'
                        local cnamesf : colnames `firstmat'
* Full list of names to change
                        local l_vnames   "`lhs'   `inexog'   `endo'   `exexog'   `geninst'"
                        local l_vnames_t "`lhs_t' `inexog_t' `endo_t' `exexog_t' `geninst_t'" 
* Macros to be fixed
                        local l_insts     "`e(insts)'"
                        local l_inexog    "`e(inexog)'"
                        local l_instd     "`e(instd)'"
                        local l_exexog    "`e(exexog)'"
                        local l_depvar    "`e(depvar)'"
                        local l_clist     "`e(clist)'"
                        local l_elist     "`e(elist)'"
                        local l_redlist   "`e(redlist)'"
                        local l_partial  "`e(partial)'"
* If any collinear or duplicates
                        local l_collin    "`e(collin)'"
                        local l_dups      "`e(dups)'"
                        local l_insts1    "`e(insts1)'"
                        local l_inexog1   "`e(inexog1)'"
                        local l_instd1    "`e(instd1)'"
                        local l_exexog1   "`e(exexog1)'"
                        local l_partial1  "`e(partial1)'"
                        foreach vn of local l_vnames {
                                tokenize `l_vnames_t'
                                local vn_t `1'
                                mac shift
                                local l_vnames_t `*'
                                local l_cnames  : subinstr local l_cnames    "`vn_t'" "`vn'"
                                local l_cnamesS : subinstr local l_cnamesS   "`vn_t'" "`vn'"
                                local l_cnamesW : subinstr local l_cnamesW   "`vn_t'" "`vn'"
                                local l_cnamesf : subinstr local l_cnamesf   "`vn_t'" "`vn'"
* Macro varlists
                                local l_insts   : subinstr local l_insts     "`vn_t'" "`vn'"
                                local l_inexog  : subinstr local l_inexog    "`vn_t'" "`vn'"
                                local l_instd   : subinstr local l_instd     "`vn_t'" "`vn'"
                                local l_exexog  : subinstr local l_exexog    "`vn_t'" "`vn'"
                                local l_partial : subinstr local l_partial   "`vn_t'" "`vn'"
                                local l_depvar  : subinstr local l_depvar    "`vn_t'" "`vn'"
                                local l_clist   : subinstr local l_clist     "`vn_t'" "`vn'"
                                local l_elist   : subinstr local l_elist     "`vn_t'" "`vn'"
                                local l_redlist : subinstr local l_redlist   "`vn_t'" "`vn'"
                                local l_collin  : subinstr local l_collin    "`vn_t'" "`vn'"
                                local l_dups    : subinstr local l_dups      "`vn_t'" "`vn'"
                                local l_insts1  : subinstr local l_insts1    "`vn_t'" "`vn'"
                                local l_inexog1 : subinstr local l_inexog1   "`vn_t'" "`vn'"
                                local l_instd1  : subinstr local l_instd1    "`vn_t'" "`vn'"
                                local l_exexog1 : subinstr local l_exexog1   "`vn_t'" "`vn'"
                                local l_partial1: subinstr local l_partial1  "`vn_t'" "`vn'"
                        }
                        mat colnames `b'       =`l_cnames'
                        mat colnames `V'       =`l_cnames'
                        mat rownames `V'       =`l_cnames'
                        mat colnames `S'       =`l_cnamesS'
                        mat rownames `S'       =`l_cnamesS'
                        mat colnames `W'       =`l_cnamesW'
                        mat rownames `W'       =`l_cnamesW'
                        mat colnames `firstmat'=`l_cnamesf'

                        ereturn post `b' `V', dep(`depvar') esample(`touse') noclear
                        ereturn matrix S `S'
                        if ~matmissing(`W') {
                                ereturn matrix W `W'
                        }
                        if ~matmissing(`firstmat') {
                                ereturn matrix first `firstmat'
                        }
                        ereturn local insts    `l_insts'
                        ereturn local inexog   `l_inexog'
                        ereturn local instd    `l_instd'
                        ereturn local exexog   `l_exexog'
                        ereturn local partial  `l_partial'
                        ereturn local collin   `l_collin'
                        ereturn local dups     `l_dups'
                        ereturn local insts1   `l_insts1'
                        ereturn local inexog1  `l_inexog1'
                        ereturn local instd1   `l_instd1'
                        ereturn local exexog1  `l_exexog1'
                        ereturn local partial1 `l_partial1'
                        ereturn local depvar   `l_depvar'
                        ereturn local clist    `l_clist'
                        ereturn local elist    `l_elist'
                        ereturn local redlist  `l_redlist'
// ms
 						ereturn local cmd		"ivreg2h"
 						ereturn local cmdline	"`cmdline'"
 						if `gen' {
							ereturn local geninsts "`geninst'"
						}
                        ereturn scalar sigma_e=e(rmse)

				est store GenExtInst
// ms
// hack to enable ivreg2 to do the replaying
				ereturn local cmd "`ivreg2_cmd'"
				loc ++n_est
 `ivreg2_cmd', `first' `ffirst' `rf' `noheader' `nofooter' `plus' `levopt' `efopt' `dropfirst' `droprf'
// ms
// undo hack
				ereturn local cmd "ivreg2h"
		}	// end block for std+generated IVs

// REPORT OUTPUT

//			if "`exexog_t'" == "" {
// no excluded insts: only GenInst results available
				if `n_exex' == 0  {
					est table       GenInst,            b(%12.4g) se(%7.3g)	stat(N rmse j jdf jp) stfmt(%7.3g)
				}
// equation underid with too few excluded insts, GenInst and GenExtInst available
				if (`n_exex' > 0) & (`n_endo' > `n_exex') {
					est table       GenInst GenExtInst, b(%12.4g) se(%7.3g)	stat(N rmse j jdf jp) stfmt(%7.3g)
				}
				else if `n_est' == 3 {
// equation identified
					est table StdIV GenInst GenExtInst, b(%12.4g) se(%7.3g)	stat(N rmse j jdf jp) stfmt(%7.3g)
				}
//			}

// ms - if requested, rename and leave behind generated instruments
		if `gen' {
			loc repl
			loc stub
			if "`gen2'" != "" {
				loc com = strpos("`gen2'", ",") 
				if `com' {
					loc stub = substr("`gen2'",1,`=`com'-1')
					loc rest = substr("`gen2'", `com', 99)
					loc repl = strpos("`rest'", "replace")
				}
				else {
					loc stub `gen2'_
					loc rest
				}
			}
//		di in r "stub: `stub'"
//		di in r "`rest'"
//		di in r `repl'
			local gen_ct : word count `geninst'	
			forvalues i=1/`gen_ct' {
				local givname_t	: word `i' of `geninst_t'
				local givname	: word `i' of `geninst'
				if "`repl'" != "" {
					if !`repl' {
					confirm new var `stub'`givname'
					}
					else {
						drop `stub'`givname'
					}
				}
				rename `givname_t' `stub'`givname'
			}
		}

* Collinearity and duplicates warning messages, if necessary
		if "`e(dups)'" != "" {
di as res "Warning - duplicate variables detected"
di as res "Duplicates:" _c
			Disp `e(dups)', _col(16)
		}
		if "`e(collin)'" != "" {
di as res "Warning - collinearities detected"
di as res "Vars dropped:" _c
			Disp `e(collin)', _col(16)
		}
* End estimation block
  }
// cfb ivreg2h

end

**********************************************************************

* Taken from ivreg2
program define Disp 
	version 8.2
	syntax [anything] [, _col(integer 15) ]
	local len = 80-`_col'+1
	local piece : piece 1 `len' of `"`anything'"'
	local i 1
	while "`piece'" != "" {
		di in gr _col(`_col') "`first'`piece'"
		local i = `i' + 1
		local piece : piece `i' `len' of `"`anything'"'
	}
	if `i'==1 { 
		di 
	}
end

program define IsStop, sclass
				/* sic, must do tests one-at-a-time, 
				 * 0, may be very large */
	if `"`0'"' == "[" {		
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
* per official ivreg 5.1.3
	if substr(`"`0'"',1,3) == "if(" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else	sret local stop 0
end

exit
