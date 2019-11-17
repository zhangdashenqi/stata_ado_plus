*! tsfit -- estimate a time series regression
*! version 1.0.0     Sean Becketti     September 1993           STB-15: sts4
program define tsfit
	version 3.1
	local options "LEvel(integer $S_level)"
	if (substr("`1'",1,1)=="," | "`*'"=="") { 
		if "$S_E_cmd"~="tsfit" { 
			error 301
		}
		parse "`*'"
	}
	else { 
		local varlist "req ex"
       		local if "opt pre"
		local in "opt pre"
		local weight "aweight fweight"
		local options "`options' noCOnstant Current(str) Lags(str) noSAmple Static(str) *"
		parse "`*'"
/*
	Parse the equation, retrieve the specification, and create the lags.
*/
		if ("`current'"!="") {
			_parsevl `current'
			local current "$S_1"
			local c "current(`current')"
		}
		if ("`lags'"!="") {
			local l "lags(`lags')"
			parse "`lags'", parse(" ,")
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
                local tstot 1           /* Number of time series terms */
                while `i'<`nx' {        /* for each TS variable        */
                       local i = `i' + 1
                       local j = `i' + 5
                       local nx`i' : word count ${S_`j'}
                       local tstot = `tstot' + `nx`i''
                }
                if ("`sample'"=="") { _ts_dsmp `reglist' `if' `in' `weight'`exp' }
/*
	Run the regression, store information for follow-on programs, 
	then display the regression.
*/
		qui reg `reglist' `if' `in' [`weight'`exp'], `constan' `options'
		if _result(1)==0 | _result(1)==. { 
			exit 2000
		}
/*
	Strip out the names of variables that don't really enter the regression.
*/
		parse "`reglist'", parse(" ")
		local i 2     /* first regressor */
                local j 0     /* which TS variable? */
                local k 0     /* term number of current TS variable */
		while "``i''"!="" { 
			if _b[``i'']==0 { 
				local `i' " " 
			}
			else if `i'<=`tstot' {
                                local k = `k' + 1
                                local x`j' "`x`j'' ``i''"
/*
        If this is the last term in the current lag polynomial,
        store it in the "last" macro and increment the counters.
*/
                                if `k'==`nx`j'' {
                                        global S_E_last "$S_E_last ``i''"
                                        local k 0
                                        local j = `j' + 1
                                }
			}
			local i = `i' + 1
		}
                local i -1
                while `i'<`nx' {                       /* TS terms and # of terms */
                        local i = `i' + 1
                        global S_E_x`i' "`x`i''"
                        global S_E_nx`i' "`nx`i''"
                }
		global S_E_ivl "`varlist'"	       /* varlist on input       	  */
		global S_E_vl "`*'"	               /* non-dropped regressors          */
		global S_E_nx "`nx'"		       /* N(RHS time series variables 	  */
		global S_E_curr "`c'"		       /* current()			  */
		global S_E_lags "`l'"		       /* lags()			  */
		global S_E_stat "`s'"		       /* static()			  */
		global S_E_if "`if'"
		global S_E_in "`in'"
		global S_E_wgt "`weight'"
		global S_E_exp "`exp'"
		global S_E_cmd "tsfit"
		global S_E_cons "`constan'"	       /* !="" if noconstant		*/
		global S_E_K = _result(1) - _result(5) /* N(Non-dropped regressors)+cons */
		global S_E_N = _result(1)
		global S_E_rmse = _result(9)
	}
	if `level'<10 | `level'>99 {
		local level 95
	}
	regress, level(`level')
end
