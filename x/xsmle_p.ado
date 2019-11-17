*! version 1.4 1oct2014 
* See end of file for version history

program define xsmle_p, sortpreserve
	
	version 10

	syntax [anything] [if] [in] [, 			   ///
			RForm 				   ///  default
			LImited 			   ///
			FUll					///
			NAive				   ///
			xb					/// /*prediction when the model is sem or gspre*/
			a            /// /* alpha_i, the fixed or random-effect */
			RFTransform(string)	/* not documented */	   ///  
			]
	
	/* RFTransform documentation
	{synopt :{opt rft:ransform(real matrix T)}}user-provided (I-{it:rho}*W)^(-1){p_end}}
	{phang}
	{opt rftransform()} tells {cmd:predict} use the user-specified inverse of
	(I-{it:rho}*W).  The matrix {it:T} should reside in Mata memory.
	This option is available only with the reduced-form predictor.
	*/
	
	marksample touse 	// this is not e(sample)
	
	tempvar esample
	qui gen byte `esample' = e(sample)
	
	*** Check for panel setup                
	_xt, trequired 
	local id: char _dta[_TSpanel]
	local time: char _dta[_TStvar]
	tempvar temp_id temp_t Ti
	qui egen `temp_id'=group(`id') if `touse'==1
	sort `temp_id' `time'
	qui by `temp_id': g `temp_t' = _n if `temp_id'!=.
    
	*** Count panels and original panel length (before any transformation of the data) 
	qui by `temp_id': gen long `Ti' = _N if _n==_N & `touse'==1
	qui summ `Ti' if `touse'==1, mean
	local t_orig = r(max)
	qui count if `Ti'<.
	local N_g = r(N)
		
	// Parsing of spatial weight matrices 
	
	ParseSpatMat, cwmat(`e(wmatrix)') cemat(`e(ematrix)') cdmat(`e(dmatrix)') crft(`rftransform')
	if "`r(_wmatspmatobj)'"!="" {
		tempname wmatrix
		mat `wmatrix' = r(_wmatspmatobj)
		local _wmatspmatobj 1
	}
	else local wmatrix "`r(wmatrix)'"
	if "`r(_ematspmatobj)'"!="" {
		tempname ematrix
		mat `ematrix' = r(_ematspmatobj)
		local _ematspmatobj 1
	}
	else local ematrix "`r(ematrix)'"
	if "`r(_dmatspmatobj)'"!="" {
		tempname dmatrix
		mat `dmatrix' = r(_dmatspmatobj)
		local _dmatspmatobj 1
	}
	else local dmatrix "`r(dmatrix)'"
	
	// parse anything
	
	local words : word count `anything'	
	if (`words'<1 | `words'>3) {
		di "{err}invalid syntax"
		exit 198
	}
	
	// parse predict options
			
	local stat "`rform'`limited'`full'`naive'`xb'`a'"
	local words : word count `stat'
	
	*** Parsing model
	ParseMod modtype : `"`e(model)'"'
	
	if ("`stat'"=="limited" | "`stat'"=="full") & `modtype'!=4 {
		di "{err}Limited-information predictor is not allowed after `e(model)' model"
		exit 198
	}
	if ("`stat'"!="xb" & "`stat'"!="") & (`modtype'==3 | `modtype'==5) {
		di "{err}Only X*beta predictor is allowed after `e(model)' model"
		exit 198
	}
	
	if `words'==0 {
		if "`e(cmd)'"=="xsmle" {		
			di "{txt}(option rform assumed)"
			local stat rform
		}
	}
	
	if `words'>1 {
		di "{err}only one statistic is allowed"
		exit 198
	}
	
	if "`a'" != "" & "`e(effects)'"=="fe" & "`e(type)'"!="ind" {
		di "{err}Fixed-effects can be post-estimated only when -type(ind)-."
		exit 198
	}
	
	gettoken type pvar : anything
	qui generate `type' `pvar' = .
	if "`pvar'"=="" local pvar `type'
	
	if "`e(dlag)'"=="no" local dlag 0
	else local dlag 1

	*** Get parameters estimates
	tempname __b _bbeta _ttheta _spat _rho _lambda _sigma2
	mat `__b' = e(b) 
	mat `_bbeta' = `__b'[1,"Main:"]
	if `modtype'==2 {
		mat `_ttheta' = `__b'[1,"Wx:"]
		mat `_bbeta' = (`_bbeta',`_ttheta')
	}
	if (`modtype'==1 | `modtype'==2) mat `_rho' = `__b'[1,"Spatial:"]
	if `modtype'==3 mat `_lambda' = `__b'[1,"Spatial:"]
	if `modtype'==4 {
		mat `_spat' = `__b'[1,"Spatial:"]
		mat `_rho' = `_spat'[1,1]
		mat `_lambda' = `_spat'[1,2]
	}
	if `modtype'==5 {
		mat `_spat' = `__b'[1,"Spatial:"]
		mat `_lambda' = `_spat'[1,2]
	}
	
	*** Sort data for the estimation of spatial panel data models
	sort `temp_t' `temp_id'
	
	mata: _xsmle_predict("`pvar'","`touse'","`esample'", "`temp_id'", "`temp_t'",`modtype',"`e(effects)'","`e(depvar)'","`e(rhsvar)'","`e(drhsvar)'",`e(noconst)', "`stat'","`rftransform'","`wmatrix'","`ematrix'","`dmatrix'",`dlag', "`_bbeta'","`_rho'","`_lambda'")

	// label new variable	
	local stat = trim("`stat'")
	
	if "`stat'"=="naive" label var `pvar' "Naive prediction"
	if "`stat'"=="rform" label var `pvar' "Reduced form prediction"
	if "`stat'"=="limited" label var `pvar' "Limited information prediction"
	if "`stat'"=="full" label var `pvar' "Full information prediction"
	if "`stat'"=="xb" label var `pvar' "Linear prediction"
	if "`stat'"=="a" & "`e(effects)'" == "fe" label var `pvar' "Fixed-effects prediction"
	if "`stat'"=="a" & "`e(effects)'" == "re" label var `pvar' "Random-effects prediction"
	
end


/* ----------------------------------------------------------------- */


program define ParseSpatMat, rclass
	syntax [, CWMATrix(string) CEMATrix(string) CDMATrix(string) CRFT(string) ]

mata: st_rclear()
ret local rcmd "ParseSpatMat"

local wmatrix `cwmatrix'
local ematrix `cematrix'
local dmatrix `cdmatrix'
local rftmatrix `crft'

if ("`wmatrix'"=="" & "`ematrix'"=="") {
	display as error "At least one of wmatrix() and ematrix() must be specified"
	error 198
}
if ("`wmatrix'" != "") {
	local n_wmatrix: word count `wmatrix'
	if `n_wmatrix'!=1 {
		display as error "Only one spatial weighting matrix `wmatrix' is allowed"
	    error 198
	}
	capture confirm matrix `wmatrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`wmatrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only stata matrix and -spmat- objects are allowed."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`wmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		
		capture mata: SPMAT_check_if_banded("`wmatrix'",1)
		if _rc !=0 {
			noi di as error "xsmle does not support banded matrices"
			exit 498
		}
		
		tempname wmatrix_new
		capture spmat getmatrix `wmatrix' `wmatrix_new'
		if _rc {
			di "{inp}`wmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _wmatspmatobj
			mata: st_matrix("`_wmatspmatobj'", `wmatrix_new')
			mata: `wmatrix_new'=.
			local rww=rowsof(`_wmatspmatobj')
		    local rcw=colsof(`_wmatspmatobj')
		    if `rww' != `rcw' {
			    display as error "Spatial weighting matrix `wmatrix' is not square"
			    error 198
		    }	
			ret matrix _wmatspmatobj = `_wmatspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`wmatrix')
    	local rcw=colsof(`wmatrix')
    	if `rww' != `rcw' {
	    	display as error "Spatial weighting matrix `wmatrix' is not square"
	    	error 198
    	}
		return local wmatrix "`wmatrix'"
	}
}

if ("`ematrix'" != "") {
	local n_ematrix: word count `ematrix'
	if `n_ematrix'!=1 {
		display as error "Only one spatial weighting matrix `ematrix' is allowed"
	    error 198
	}
	capture confirm matrix `ematrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`ematrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only stata matrix and -spmat- objects are allowed."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`ematrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		
		capture mata: SPMAT_check_if_banded("`ematrix'",1)
		if _rc !=0 {
			noi di as error "xsmle does not support banded matrices"
			exit 498
		}
		
		tempname ematrix_new
		capture spmat getmatrix `ematrix' `ematrix_new'
		if _rc {
			di "{inp}`ematrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _ematspmatobj
			mata: st_matrix("`_ematspmatobj'", `ematrix_new')
			mata: `ematrix_new'=.
			local rww=rowsof(`_ematspmatobj')
		    local rcw=colsof(`_ematspmatobj')
		    if `rww' != `rcw' {
			    display as error "Spatial weighting matrix `ematrix' is not square"
			    error 198
		    }	
			ret matrix _ematspmatobj = `_ematspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`ematrix')
    	local rcw=colsof(`ematrix')
    	if `rww' != `rcw' {
	    	display as error "Spatial weighting matrix `ematrix' is not square"
	    	error 198
    	}
		return local ematrix "`ematrix'"
	}
}

if ("`dmatrix'" != "") {
	local n_dmatrix: word count `dmatrix'
	if `n_dmatrix'!=1 {
		display as error "Only one spatial weighting matrix `dmatrix' is allowed"
	    error 198
	}
	capture confirm matrix `dmatrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`dmatrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only stata matrix and -spmat- objects are allowed."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`dmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		
		capture mata: SPMAT_check_if_banded("`dmatrix'",1)
		if _rc !=0 {
			noi di as error "xsmle does not support banded matrices"
			exit 498
		}
		
		tempname dmatrix_new
		capture spmat getmatrix `dmatrix' `dmatrix_new'
		if _rc {
			di "{inp}`dmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _dmatspmatobj
			mata: st_matrix("`_dmatspmatobj'", `dmatrix_new')
			mata: `dmatrix_new'=.
			local rww=rowsof(`_dmatspmatobj')
		    local rcw=colsof(`_dmatspmatobj')
		    if `rww' != `rcw' {
			    display as error "Spatial weighting matrix `dmatrix' is not square"
			    error 198
		    }	
			ret matrix _dmatspmatobj = `_dmatspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`dmatrix')
    	local rcw=colsof(`dmatrix')
    	if `rww' != `rcw' {
	    	display as error "Spatial weighting matrix `dmatrix' is not square"
	    	error 198
    	}
		return local dmatrix "`dmatrix'"
	}
}

if ("`rftmatrix'" != "") {
	local n_rftmatrix: word count `rftmatrix'
	if `n_rftmatrix'!=1 {
		display as error "Only one spatial weighting matrix `rftmatrix' is allowed"
	    error 198
	}
	capture confirm matrix `rftmatrix'
	local _rc_mat_assert = _rc
	if `_rc_mat_assert' != 0 {
		capture mata: SPMAT_assert_object("`rftmatrix'")
		local _rc_spmat_assert = _rc
		if `_rc_spmat_assert' == 3499 {
			capt findfile spmat.ado
		    if _rc {
		        di as error "Only stata matrix and -spmat- objects are allowed."
				di as error "You can install -spmat- by typing {stata net install sppack}."
		        error 499
		    }
		}
		if `_rc_spmat_assert' != 0 {
			di "{inp}`rftmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		tempname rftmatrix_new
		capture spmat getmatrix `rftmatrix' `rftmatrix_new'
		if _rc {
			di "{inp}`rftmatrix' {err}is not a valid {help spmat} object"
			exit 498
		}
		else {
			tempname _rftspmatobj
			mata: st_matrix("`_rftspmatobj'", `rftmatrix_new')
			mata: `rftmatrix_new'=.
			local rww=rowsof(`rftspmatobj')
		    local rcw=colsof(`rftspmatobj')
		    if `rww' != `rcw' {
			    display as error "Spatial weighting matrix `rftmatrix' is not square"
			    error 198
		    }	
			ret matrix _rftspmatobj = `_rftspmatobj'
		}
	}
	if `_rc_mat_assert' == 0 {
    	local rww=rowsof(`rftmatrix')
    	local rcw=colsof(`rftmatrix')
    	if `rww' != `rcw' {
	    	display as error "Spatial weighting matrix `rftmatrix' is not square"
	    	error 198
    	}
		return local rftmatrix "`rftmatrix'"
	}
}

end

/* ----------------------------------------------------------------- */

program define ParseMod
	args returmac colon model

	local 0 ", `model'"
	syntax [, SAR SDM SEM SAC GSPRE * ]

	if `"`options'"' != "" {
		di as error "model(`options') not allowed"
		exit 198
	}
	
	local wc : word count `sar' `sdm' `sem' `sac' `gspre'

	if `wc' > 1 {
		di as error "model() invalid, only " /*
			*/ "one model can be specified"
		exit 198
	}

	if `wc' == 0 {
		c_local `returmac' 1
	}
	else {
		if ("`sar'"=="sar") local modtype=1
		if ("`sdm'"=="sdm") local modtype=2
		if ("`sem'"=="sem") local modtype=3
		if ("`sac'"=="sac") local modtype=4
		if ("`gspre'"=="gspre") local modtype=5
		c_local `returmac' `modtype' 		
	}	

end

/* ----------------------------------------------------------------- */

program define ParseType
	args returmac colon type

	local 0 ", `type'"
	syntax [, Ind Time Both * ]

	if `"`options'"' != "" {
		di as error "type(`options') not allowed"
		exit 198
	}
	
	local wc : word count `ind' `time' `both'

	if `wc' > 1 {
		di as error "type() invalid, only " /*
			*/ "one type can be specified"
		exit 198
	}
	if `wc' == 0 {
		c_local `returmac' 1
	}
	else {
		if ("`ind'"=="ind") local _efftype=1
		if ("`time'"=="time") local _efftype=2
		if ("`both'"=="both") local _efftype=3
		c_local `returmac' `_efftype' 		
	}	

end



exit

*! version 1.0 10oct2012
*! version 1.1 23jan2013 - Bug fixes
*! version 1.2 12feb2013 - Check for banded matrices added
*! version 1.3 14may2013 - The command gives now an error when fixed-effects postestimation and type(time) or type(both)






