*! tsload -- load a user-specified time series model in the S_E_macros.
*! version 1.0.0     Sean Becketti     July 1993
program define tsload
	version 3.1
	local varlist "req ex"
       	local if "opt pre"
	local in "opt pre"
	local weight "aweight fweight"
	local options "Coefficients(str) noCOnstant CUrrent(str) Lags(str) Static(str) Rmse(real 0) Variance(real 0)"
	parse "`*'"
	global S_E_cmd
	if "`coeffic'"=="" {
		di in re "You must specify coefficients."
		exit 198
	}
	if (`rmse'>0 & `varianc'>0) { exit 198 } /* both specified */
	if (`rmse'<0 & `varianc'<0) { exit 198 } /* negative */
	if `rmse'==0 { local rmse = cond(`varianc'==0,.,sqrt(`varianc')) }
/*
	Parse the equation, retrieve the specification, and create the lags.
*/
	if ("`current'"!="") {
		_parsevl `current'
		local current "$S_1"
		local c "current(`current')"
	}
	local depl 0
	if ("`lags'"!="") {
		local l "lags(`lags')"
		parse "`lags'", parse(" ,")
		local depl `1'
	}
	if ("`static'"!="") {
		_parsevl `static'
		local static "$S_1"
		local s "static(`static')"
	}
	qui _ts_meqn `varlist', `c' `l' `s'
	local reglist "$S_1"
	local nx "$S_2"
	local maxlag "$S_3"
        local i -1              /* Store the number of terms   */
        while `i'<`nx' {        /* for each TS variable        */
               local i = `i' + 1
               local j = `i' + 5
               local nx`i' : word count ${S_`j'}
        }
/*
	Store the coefficients.
*/
	_subchar "," " " "`coeffic'"	/* prepare coefficients */
	local coeffic "$S_1"
	parse "`coeffic'", parse(" ")
	local b0
	if "`constan'"=="" {
		conf number `1'
		local b0 `1'
		mac shift
		local coeffic "`*'"
		local model "(`b0')"
		local plus +
	}
	local nb : word count `coeffic'
	parse "`reglist'", parse(" ")	/* prepare varlist */
	local depv `1'
	mac shift
	local xlist "`*'"
	local nv : word count `xlist'
	if `nb'!=`nv' { 
		di in re "Number of variables = `nv', number of coefficients = `nb'"
		exit 198
	}
	local i 0
	while `i'<`nb' {
		local i = `i' + 1
		local b`i' : word `i' of `coeffic'
		conf number `b`i''
		local v : word `i' of `xlist'
		local model "`model'`plus'((`b`i'')*`v')"
		local plus +
	}
	local i = `i' + 1
	local b`i'
/*
	Run a fake regression to initialize predict.
*/
	tempvar ysave
	rename `depv' `ysave'
	qui gen `depv' = `model' `if' `in'
        reg `reglist' `if' `in', `constan'
        cap reg `reglist' `if' `in', `constan'
	local rc = _rc
	drop `depv'
	rename `ysave' `depv'
	if `rc' | _result(1)==0 | _result(1)==. { 
		local rc = cond(`rc',`rc',2000)
		exit `rc'
	}
/*
	Store the model information.
*/
	local k = 0
	local i = -1		      			/* coefficients			  */
	while `i'<`nx' {
		local i = `i' + 1
                global S_E_nx`i' "`nx`i''"
		local j = 0
		while `j'<${S_E_nx`i'} {
			local j = `j' + 1
			local k = `k' + 1
			local v : word `k' of `xlist'
                	global S_E_x`i' "${S_E_x`i'} `v'"
		}
	}
	global S_E_depv `depv'
	global S_E_rl "`reglist'"			/* non-dropped regressors 	  */
	global S_E_vl "`varlist'"			/* RHS time series variables 	  */
	global S_E_nx `nx'				/* N(RHS) ts_vars		  */
	global S_E_nb `nb'
	global S_E_curr "`c'"				/* current()			  */
	global S_E_lags "`l'"				/* lags()			  */
	global S_E_depl `depl'				/* requested lags of LHS variable */
	global S_E_depn $S_E_depl			/* actual lags of LHS variable    */
	global S_E_depL $S_E_depl			/* highest lag of LHS variable	  */
	global S_E_stat "`s'"				/* static()			  */
	global S_E_if "`if'"
	global S_E_in "`in'"
	global S_E_wgt "`weight'"
	global S_E_exp "`exp'"
	global S_E_cmd "tsfit"
	global S_E_cons "`constan'"			/* !="" if noconstant		*/
	global S_E_K = `nv' + ("`constant'"=="")
	global S_E_rmse `rmse'
end
