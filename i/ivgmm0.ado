*! ivgmm0 v1.1.11   C F Baum and David Drukker  16Mar2004
* 1.1.1 :  Corrections by David Drukker 0302
* 1.1.2 :  noconst added 0303
* 1.1.3 :  Save S (as W) added  0411
* 1.1.4 :  Mod for qui (2x) 1115
* 1.1.5 :  Mod for missing touse (?x) 1923
* 1.1.6 :  Mod to use first-stage residuals in J stat 2811
* 1.1.7 :  Add gres option to use GMM resids in calc VC mtx
* 1.1.8 :  Add e(cmd) defn
* 1.1.9 :  Trap N < rank(Z)
* 1.1.10:  Save Sinv as W
* 1.1.11:  Ensure that nocons also removes cons from inst list
    
program define ivgmm0, eclass
	version 6.0
	
* parsing code and subroutines taken from -ivreg-  5.0.4
	local n 0

	gettoken lhs 0 : 0, parse(" ,[") match(paren)
	IsStop `lhs'
	if `s(stop)' { error 198 }
	while `s(stop)'==0 { 
		if "`paren'"=="(" {
		local n = `n' + 1
		if `n'>1 { 
			capture noi error 198 
			di in red `"syntax is " /* 
			   */ (all instrumented variables = instrument /*
			   */  variables)""'
			exit 198
		}
		gettoken p lhs : lhs, parse(" =")
		while "`p'"!="=" {
			if "`p'"=="" {
			exit 198 
			}
			local end`n' `end`n'' `p'
			gettoken p lhs : lhs, parse(" =")
		}
		tsunab end`n' : `end`n''
		tsunab exog`n' : `lhs'
		}
		else {
		local exog `exog' `lhs'
		}
		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
	}
	local 0 `"`lhs' `0'"'

	tsunab exog : `exog'
	tokenize `exog'
	local lhs "`1'"
	local 1 " " 
	local exog `*'

	syntax [if] [in] [,noConstant gres]
* following lifted from newey.ado
        if `"`constan'"'==`""' {
        	tempvar CONS
        	gen byte `CONS' = 1
                local carg `""'
                local cons `"_cons"'
                }
        else {
                local CONS `""'
                local carg `"nocons"'
                local cons `""'
                }
	
/*	[fw] 
	local wtype `weight'
        local wtexp "`exp'"
        if "`weight'" != "" { local wgt `"[`weight' `exp']"' }
*/
	marksample touse
	markout `touse' `lhs' `exog' `exog1' `end1'

	Subtract newexog : "`exog1'" "`exog'"
	local endo_ct : word count `end1'
	local ex_ct : word count `newexog'

	if `endo_ct' > `ex_ct' {
		di in red "equation not identified; must have at " /*
		*/ "least as many instruments not in"
		di in red "the model as there are "           /*
		*/ "instrumented variables"
		exit 481
	}
* generate the IV regression residuals
	qui ivreg `lhs' `exog' (`end1'=`newexog') if `touse' ,`carg'
	local nobs=e(N)
	tempvar resid gresid xb iota gr2 tooz gresid2
	tempname S Sinv W XZ B1 ZY B2 B V Ztu uzwzu essinv
* 1923 if touse
	qui gen `tooz' = `touse'
	qui predict double `resid' if `touse',r
* 4316 generate Z, conditionally including a constant
	gen `iota'=1
	if "`cons'" == "" {
		local exoglst `newexog' `exog'
		}
	else {
		local exoglst `newexog' `exog' `iota' 
		}
* generate weighting matrix S = Z'e'eZ and its inverse
	qui mat accum `S'=`exoglst' [iweight=`resid'^2],noconst
* check to ensure sufficient data
	local enobs = `r(N)'
	mat `Sinv'=syminv(`S')
	local iv_ct = rowsof(`Sinv') - diag0cnt(`Sinv')
	if `enobs' <= `iv_ct' {
		di in r "Error: number of observations must be greater than number of instruments"
		di in r "       including constant."
			error 2001
		}
* generate cross products of Y, X, Z, iota
	local reglst `end1' `exog' `CONS'
	local regct: word count `reglst'
	local regl =`regct'+1
	local xogct: word count `exoglst'
	local xogf =`regl'+1
	local xogl =`regl'+`xogct'
* 1923 if touse
	qui mat accum `W'=`lhs' `reglst' `exoglst' if `touse',noconst
* 4316 constant conditionally
	mat rownames `W'=`lhs' `end1' `exog' `cons' `newexog' `exog' `cons'
	mat colnames `W'=`lhs' `end1' `exog' `cons' `newexog' `exog' `cons'
	mat `XZ' = `W'[2..`regl',`xogf'..`xogl']
	mat `B1'=syminv(`XZ'*`Sinv'*`XZ'')
	mat `ZY' = `W'[`xogf'...,1]
	mat `B'=(`B1'*`XZ'*`Sinv'*`ZY')'
	mat `V' = syminv(`XZ'*`Sinv'*`XZ'')
	estimates post `B' `V', depname("`lhs'") esample(`touse')
/* save Sinv matrix for calculation of J statistic from first-round residuals */
	mat `essinv' = `Sinv'

    	qui _predict double `xb',xb
	qui gen double `gresid'=`lhs'-`xb'
	if "`gres'" != "" {
/* use new gmm residuals for VC matrix */
* 1923 if touse
		qui mat accum `S'=`exoglst' [iweight=`gresid'^2] if `tooz',noconst
		mat rownames `S'=`newexog' `exog' _cons
		mat colnames `S'=`newexog' `exog' _cons
		mat `Sinv'=syminv(`S')
	}

	mat `V' = syminv(`XZ'*`Sinv'*`XZ'')
	estimates repost V=`V'

	est local cmd "ivgmm0"
	est local depvar `lhs'
	est local instd `end1'
	est local insts `exog' `newexog'
        est scalar N =  `nobs'
	est local vcetype `"GMM"'
* 1923 if touse
	qui gen double `gresid2' = `gresid'*`gresid'
        qui summ `gresid2' if `tooz'
/*	calc from mean squared resid--these are not zeromean */	
		est scalar rmse = sqrt(r(mean))
* 1923 if touse
        qui mat vecaccum `Ztu'=`gresid' `exoglst' if `tooz',noconst 

/* 2811: calc Hansen J from original Sinv */
        mat `uzwzu'= `Ztu'*`essinv'*`Ztu''
        est scalar j = `uzwzu'[1,1]
        est scalar df = `ex_ct' - `endo_ct'
        est scalar p  = chiprob(e(df),e(j)) 
        qui gen `gr2'= `gresid'*`gresid'
        qui summ `gr2'
        local ssres = `r(sum)'

/* DMD: add create/save of [1/N Sinv] as external symbol W */
		mat `essinv'=`nobs'*`essinv'	
		est matrix W `essinv'
	
        di _n in gr `"Instrumental Variables Estimation via GMM"' /*
         */  _col(53) `"Number of obs  ="' in yel %10.0f e(N) _n /* 
         */  _col(53) `"Root MSE       ="' in yel %10.4f e(rmse) _n /*
         */  _col(53) `"Hansen J       ="' in yel %10.4f e(j)
        if `ex_ct'>`endo_ct' {
         	di _col(53) "Chi-sq(" %2.0f in ye e(df) /* 
         	*/  in ye ") P-val = " in ye %6.5f e(p) /* _n 
         	*//*_col(53) `"Sargan         ="' in yel %10.4f e(sargan) */
	}
	estimates display
	di in gr "Instrumented:  " _c
        Disp `e(instd)'
        di in gr "Instruments:   " _c
        Disp `e(insts)'
        di in gr _dup(78) "-"
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

program define Disp 
        local first ""
        local piece : piece 1 64 of `"`0'"'
        local i 1
        while "`piece'" != "" {
                di in gr "`first'`piece'"
                local first "               "
                local i = `i' + 1
                local piece : piece `i' 64 of `"`0'"'
        }
        if `i'==1 { di }
end

/*  Remove all tokens in dirt from full */
 *  Returns "cleaned" full list in cleaned */

program define Subtract   /* <cleaned> : <full> <dirt> */
	args	    cleaned     /*  macro name to hold cleaned list
	*/  colon	/*  ":"
	*/  full	/*  list to be cleaned 
	*/  dirt	/*  tokens to be cleaned from full */
	
	tokenize `dirt'
	local i 1
	while "``i''" != "" {
	local full : subinstr local full "``i''" "", word all
	local i = `i' + 1
	}

	tokenize `full'		/* cleans up extra spaces */
	c_local `cleaned' `*'       
end

exit