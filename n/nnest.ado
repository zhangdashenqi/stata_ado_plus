* nnest version 1.0 29June98
* nnest version 2.0 15Aug01
* Now for version 7

* Author : Gregorio Impavido (gimpavido@worldbank.org)
*
* Description :
program define nnest
	version 7.0

	tempvar yhat_M1 yhat_M2 res_M1 res_M2

	/* Check that the syntax is correct */
	local args "`*'"
	local nargs : word count `args'
	if `nargs' <= 2 {
	     di in red "Too few variables"
	     exit 198
	}


	/* Construct Y M1 and M2 and check that variables exist */
	gettoken depvar 0 : 0, parse(" , (") match(paren)
	unab depvar : `depvar'
	gettoken M1 0 : 0, parse("(") match(paren)
	unab M1 : `M1'
	gettoken M2 0 : 0, parse(" ") match(paren)
	unab M2 : `M2'

	/* Check that regressors for M2 have been entered */
	if "`M2'" == "" {
	     di in red "You forgot to enter the list of regressors for M2"
	     exit 198
	}

/* J test */
quietly {
	reg `depvar' `M2' 
	local s2_M2 =_result(4)/_result(1) /* This is the MLE est for Cox */
	local n_M2  = _result(1)
	predict `yhat_M2'
	reg `depvar' `M1' 
	local s2_M1 =_result(4)/_result(1) /* This is the MLE est for Cox */
	local n_M1  = _result(1)
	predict `yhat_M1'

if `n_M2' != `n_M1' {
	di in r "M1 and M2 have different number of observations"
	exit 198}

	reg `depvar' `M1' `yhat_M2' 
	local tz  = _b[`yhat_M2']/_se[`yhat_M2']
	local dz2 = _result(5)
	local tzsig    = tprob(`dz2', `tz')
	reg `depvar' `M2' `yhat_M1' 
	local tx  = _b[`yhat_M1']/_se[`yhat_M1']
	local dx2 = _result(5)
	local txsig    = tprob(`dx2', `tx')
}

di _n     in gr "M1 : Y = a + Xb with X = [" in ye "`M1'" in gr "]"
di   in gr "M2 : Y = a + Zg with Z = [" in ye "`M2'" in gr "]"

di _n in gr "J test for non-nested models"

di _n     in gr "H0 : M1" _skip(2) "t(" in ye `dz2' in gr ")" _col(20) in ye %9.5f `tz'
di   in gr "H1 : M2" _skip(2) "p-val" _col(20) in ye %9.5f `tzsig'

di _n     in gr "H0 : M2" _skip(2) "t(" in ye `dx2' in gr ")" _col(20) in ye %9.5f `tx'
di   in gr "H1 : M1" _skip(2) "p-val" _col(20) in ye %9.5f `txsig'

/* The Cox-Pesaran and Deaton Statistics */

/* Now we're testing H0 : M1 , H1 : M2 */

quietly {
	reg `yhat_M1' `M2' 
	local rss_M21    = _result(4)
	predict `res_M2' , resid  
	local s2_M2M1     =  `s2_M1' + 1/`n_M2'*`rss_M21'
	reg `res_M2' `M1' 
	local rss_M22    = _result(4)
	local c12 = (`n_M2'/2)*ln(`s2_M2'/`s2_M2M1')
	local vc12     = `s2_M1'*`rss_M22'/(`s2_M2M1'^2)
	local q1  = `c12'/sqrt(`vc12')
	local q1sig    = 1 - normprob(abs(`q1'))

/* Now we're testing H0 : M2 , H1 : M1 */
	reg `yhat_M2' `M1' 
	local rss_M11    = _result(4)
	predict `res_M1' , resid
	local s2_M1M2 = `s2_M2' + 1/`n_M2'*`rss_M11'
	reg `res_M1' `M2' 
	local rss_M12    = _result(4)
	local c21 = (`n_M1'/2)*ln(`s2_M1'/`s2_M1M2')
	local vc21 = `s2_M2'*`rss_M12'/(`s2_M1M2'^2)
	local q2  = `c21'/sqrt(`vc21')
	local q2sig    = 1- normprob(abs(`q2'))
}


di _n in gr "Cox-Pesaran test for non-nested models"

di _n     in gr "H0 : M1" _skip(2) "N(0,1)" _col(20) in ye %9.5f `q1'
di   in gr "H1 : M2" _skip(2) "p-val" _col(20) in ye %9.5f `q1sig'

di _n     in gr "H0 : M2" _skip(2) "N(0,1)" _col(20) in ye %9.5f `q2'
di   in gr "H1 : M1" _skip(2) "p-val" _col(20) in ye %9.5f `q2sig'

end
