*! version  4.0.0  24jan1999
program define lrtest2, rclass
	version 6.0

	syntax [, Saving(string) Using(string) Model(string) Df(real -999999) /*
		*/ FORCE DEtail List DIr CLEAR DROP(string) /*
		*/ UNRestricted(string) Restricted(string) Note(string) SWITCH ]

	if `"`list'`clear'`drop'`dir'"' != "" & /*
		*/ `"`using'`model'`unrestricted'`restricted'`force'`note'`switch'"' != "" {
		di in re "clear,dir,drop,list may not be combined with other options"
		exit 198
	}

	if `"`unrestricted'"' != "" & `"`using'"' != "" {
		di in re "unrestricted() and using() are synomymous. Specify only one."
		exit 198
	}
	if `"`unrestricted'"' != "" {
		local using `"`unrestricted'"'
	}

	if `"`restricted'"' != "" & `"`model'"' != "" {
		di in re "restricted() and model() are synomymous. Specify only one."
		exit 198
	}
	if `"`restricted'"' != "" {
		local model `"`restricted'"'
	}

	if `"`note'"' != "" & `"`saving'"' == "" {
		di in re "note() can only be specified with saving()"
		exit 198
	}

	/*
		manage saved models
	*/

	if ("`list'" != "" | "`dir'" != "") & (`"`saving'"' == "") {
		List "$LRTS_LST"
		exit
	}
	if "`clear'" != "" {
		Clear
		exit
	}
	if `"`drop'"' != "" {
		Drop `drop'
		exit
	}

	/*
		extract information on (restricted) -model- for performing LR test
	*/

	if `"`model'"' == "" {
		local detail

		local nmod "`e(cmd)'"
		local ndepvar "`e(depvar)'"
		local nobs  = e(N)
		local nll   = e(ll)
		local nll0  = e(ll_0)

		tempname V
		mat `V' = e(V)
		local ndf = colsof(`V') - diag0cnt(`V')
		mat drop `V'

		/* If pre version 6 user programmed estimation command, then */
		/* try getting stuff from S_E_ or _result() */
		if `nobs' == . {
			local nmod "$S_E_cmd"
			if "`nmod'" == "" { error 301 }
			Internal `nmod'
			if `r(intern)' == 1 {
				* replay to set _result
				quietly `nmod'
				local nobs = _result(1)
				local nll  = _result(2)
				capt local nll0 = _result(2) - 0.5*_result(5)
				* local ndf  = _result(3) (already set)
			}
			else {
				local nobs  "$S_E_nobs"
				local nll   "$S_E_ll"
				local nll0  "$S_E_ll0"
				* local ndf  "$S_E_mdf"  (already set)
			}
			local ndepvar "$S_E_depv"
		}
		if "`ndepvar'"	== "" { local ndepvar . }
		if "`nll0'"	== "" { local nll0 . }

		if "`nmod'" == "" { error 301 }
		capture confirm integer number `nobs'
		if _rc { error 301 }
		capture confirm number `nll'
		if _rc { error 301 }
		capture confirm integer number `ndf'
		if _rc { error 301 }
		if "`nll0'" != "." {
			capture confirm number `nll0'
			if _rc { error 301 }
		}
	}
	else {
		if length("`model'") > 4 {
			di in red "model() name too long"
			exit 198
		}
		local name LRTS`model'
		local fields $`name'
		if `"`fields'"' == "" {
			di in red "model `model' not found"
			exit 302
		}
		gettoken nmod    fields : fields
		gettoken nobs    fields : fields
		gettoken nll     fields : fields
		gettoken ndf     fields : fields
		gettoken nll0    fields : fields
		gettoken ndepvar nnote  : fields
	}

	/*
		save estimation results
	*/

	if `"`saving'"' != "" {
		if length(`"`saving'"') > 4 {
			di in red "saving() name too long"
			exit 198
		}
		global LRTS`saving' /*
			*/ `"`nmod' `nobs' `nll' `ndf' `nll0' `"`ndepvar'"' `"`note'"'"'

		* add new 4char name to LRTS_LST, if it does not yet occur
		local tmp : subinstr global LRTS_LST /*
			*/ "`saving'" "", all count(local nc)
		if `nc' == 0 {
			global LRTS_LST `"$LRTS_LST `saving'"'
		}

		if "`list'" != "" | "`dir'" != "" {
			List "$LRTS_LST"
		}
		if `"`using'"' == "" {
			exit
		}
	}

	/*
		extract information on (larger, using) for performing LR test
	*/

	if "`using'" != "" {
		if length("`using'") > 4 {
			di in red "using() name too long"
			exit 198
		}
		local user `using'
	}
	else 	local user 0

	local name LRTS`user'
	local fields $`name'
	if `"`fields'"' == "" {
		di in red "model `user' not found"
		exit 302
	}
	gettoken bmod    fields : fields
	gettoken bobs    fields : fields
	gettoken bll     fields : fields
	gettoken bdf     fields : fields
	gettoken bll0    fields : fields
	gettoken bdepvar bnote  : fields

	/*
		check whether a LR test is feasible
	*/

	if "`bmod'" != "`nmod'" & "`force'" == "" {
		di in red "cannot compare `bmod' and `nmod' estimates"
		di in red "specify -force- if models are indeed nested"
		exit 402
	}
	if `bobs' != `nobs' {
		di in blu "Warning: observations differ:  `bobs' vs. `nobs'"
	}
	if "`bdepvar'" != "`ndepvar'" & "`bdepvar'" != "." & "`ndepvar'" != "." {
		di in blu "Warning: dependent variables differ: `bdepvar' vs. `ndepvar'"
	}
	if "`bll0'" != "." & "`nll0'" != "." {
		if reldif(`bll0',`nll0') > 1E-6 {
			di in blu "Warning: log-likelihood of null models differ: " /*
				*/ in ye %10.2f `bll0' in gr " vs. " in ye %10.2 `nll0'
		}
	}

	/*
		if df < 0, switch using() and model()
	*/

	if `df' == -999999 {
		local df = `bdf' - `ndf'
	}
	if `df' < 0 & "`switch'" != "" {
		di in blu "Warning: using() and model() seem to be interchanged (df<0). "
		di in blu "I'll switch them."
		local tmp   `model'
		local model `user'
		local user  `tmp'

		local tmp   `bdf'
		local bdf   `ndf'
		local ndf   `tmp'
		local df = - `df'

		local tmp   `bll'
		local bll   `nll'
		local nll   `tmp'

		local tmp   `bobs'
		local bobs  `nobs'
		local nobs  `tmp'
	}

	/*
		double save in S_# and r()
	*/

	ret scalar df   = `df'
	ret scalar chi2 = -2*(`nll'-`bll')
	ret scalar p    = chiprob(`df',return(chi2))

	ret scalar AIC1 = -2*`nll' + 2 * `ndf'
	ret scalar AIC2 = -2*`bll' + 2 * `bdf'
	ret scalar BIC1 = -2*`nll' + log(`nobs')*`ndf'
	ret scalar BIC2 = -2*`bll' + log(`bobs')*`bdf'

	global S_3 "`return(df)'"
	global S_6 "`return(chi2)'"
	global S_7 "`return(p)'"

	/*
		display results
	*/

	if "`bmod'" != "`nmod'" {
		local name  "`bmod'/`nmod'"
	}
	else local name = upper(substr("`nmod'",1,1))+substr("`nmod'",2,.)

	di in gr "`name' `ndepvar':  likelihood-ratio test" _col(55) /*
		*/ "LR chi2(" in ye `df' in gr ")" _col(67) "=" in ye %10.2f return(chi2) /*
		*/ _n in gr "(Assumption: " in ye "`model'" in gr " nested in " /*
		*/ in ye "`user'" in gr ")" /*
		*/ _col(55) "Prob > chi2 = " in ye %9.4f return(p)

	if "`detail'" != "" {
		List "`user' `model'"
	}
end

/* ==========================================================================
   subroutines
   ==========================================================================
*/

/* Internal
   returns in r(intern) whether argument is internal estimation command
   that saves results in _return()
*/
program define Internal, rclass
	args model
	if "`model'" == "cox" | "`model'" == "logit" |       /*
		*/ "`model'" == "probit"  | "`model'" == "tobit"  |  /*
		*/ "`model'" == "cnreg"   | "`model'" == "ologit" |  /*
		*/ "`model'" == "oprobit" | "`model'" == "mlogit" |  /*
		*/ "`model'" == "clogit" {
		return local intern 1
	}
	else return local intern 0
end


/* Clear
   drop all stored models
*/
program define Clear
	tokenize $LRTS_LST
	while "`1'" != "" {
		global LRTS`1'
		mac shift
	}
	global LRTS_LST
end


/* Drop name-list
   drop specified models
*/
program define Drop
	args list

	if `"`list'"' == "_all" {
		Clear
	}

	tokenize `"`list'"'
	while "`1'" != "" {
		global LRTS_LST : subinstr global LRTS_LST "`1'" "", word count(local nc)
		if `nc' > 0 {
			global LRTS`1'
		}
		else	local nfound "`nfound' `1'"
		mac shift
	}
	if "`nfound'" != "" {
		di in bl "Models not found: `nfound'"
	}
end


/* List name-list
   lists information on models
*/
program define List
	args list

	if "`list'" == "" {
		* no warning message ?
		exit
	}

	di _n in gr /*
	  */ "name |   model    depvar    nobs   log-lik    mdf       AIC       BIC"
	di in gr "-----+" _dup(65) "-"

	local nlist : word count `list'
	local i 1
	while `i' <= `nlist' {
		local name : word `i' of `list'
		local fields ${LRTS`name'}
		if `"`fields'"' != "" {
			gettoken model  fields : fields
			gettoken obs    fields : fields
			gettoken ll     fields : fields
			gettoken df     fields : fields
			gettoken ll0    fields : fields
			gettoken depvar fields : fields
			gettoken note          : fields

			* model selection indices
			local aic = -2*`ll' + 2 * `df'
			local bic = -2*`ll' + log(`obs')*`df'

			* display stuff
			di in gre %4s "`name'" _col(6) "| " _c
			if `"`note'"' != "" {
				di in gre `"`note'"' _n _col(6) "| " _c
			}
			capt noi di in yel "`model'" /*
				*/ _col(11) %~8s   "`depvar'" /*
				*/ _col(21) %5.0f `obs'  /*
				*/ _col(28) %9.2g `ll'   /*
				*/ _col(39) %4.0f `df'  /*
				*/ _col(45) %8.2f `aic'  /*
				*/ _col(55) %8.2f `bic'
			if _rc {
				di in bl "unable to display results for ``i''"
			}
		}
		local i = `i' + 1
	}
end
exit


Design

  lrtest saves models in global macros LRTSname
  in fields seperated by white space. Currently, we store

		model (estimation command)
		obs
		ll
		df
		ll0
		depvar   (embedded in quotes for models with multiple depvars)
		note     (embedded in quotes)

Layout

Logit: likelihood-ratio test                           LR chi2(10) = 1234567890
                                                       Prob > chi2 = 1234567890


----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8

name |   model    depvar    nobs   log-lik    mdf   Akaike    Schwarz
-----+----------------------------------------------------------------
1234 | test-of-note-if-any
     | 12345678  12345678  12345  123456789  1234  12345.78  12345.78


Possibility: if a column is always the same, drop it, and display a single line
   above the header. How do we implement this efficiently?

Should I add ll_0 in the table as well. And a chi2 test against the null-model?

Bug to be fixed: if detail is specified, while the 'current model' is not
  saved, we have to 'temporarily save' the model under name "LAST", and
  drop it at the end. The name LAST should be "reserved".

Optionally save the models under subsequent digits?
