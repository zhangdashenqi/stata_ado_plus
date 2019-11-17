*! version 1.0.0 10aug11 N.Orsini, M.Bottai

capture program drop lqreg
program define lqreg, eclass byable(recall) sort prop(mi)
	version 6.0, missing
	local options "Level(cilevel)"

	if replay() {
		if "`e(cmd)'"!="lqreg" { error 301 } 
		if _by() { error 190 }
		syntax [, `options']
	}
	else {
		local cmdline : copy local 0
		syntax varlist [if] [in] [, `options' Quantiles(numlist)   /*
			*/ WLSiter(integer 1) Reps(integer 100) SEED(string) noLOg noDOts GENerate(string) ymin(string) ymax(string)  CLuster(varlist) ASe ]

		// check significance level  
 
		local opts "level(`level')"
		
		if "`cluster'" != "" & "`reps'" == "" {
			di as err "specify the option reps(#) for bootstrap"
			exit 198
		}
		
		marksample touse
		
		if "`log'"!="" | "`dots'"!="" {
			local log "*"
		}

		SetQ `quantil'
		tokenize "`r(quants)'"
		local nq 1
		while "``nq''" != "" {
			local q`nq' ``nq''	
			local nq = `nq' + 1
		}
		local nq = `nq' - 1
		
		if "`reps'"!= "" { 
						  tempfile BOOTRES
						  capture confirm integer number `reps' 
							if _rc != 0 {
								di as err "Reps must be an integer number > 1"
								exit 198
							}
						    if (`reps')<2 { 
							di as err "Reps must be an integer number > 1"
								exit 198
							}
		}

		tempname coefs vce VCE coefs0 coefs1 handle
		tempvar e bcons bwt
 
		quietly count if `touse'
		if r(N)<4 { 
			di in red "insufficient observations"
			exit 2001
		}

		* local opts "wls(`wlsiter')"
		gettoken depv rhs : varlist
		_rmcoll `rhs' [`weight'`exp'] if `touse'
		local rhs `r(varlist)'

	// determine unit (minimal increment of depvar) from codebook   
	
	tempname p 
		
	scalar `p' = 1
	
	capture assert float(`depv') == float(round(`depv',1)) if `touse'
	if _rc == 0 {
		while _rc == 0 {
			scalar `p' = `p'*10
			capture assert float(`depv') == float(round(`depv',`p')) if `touse'
		}
		scalar `p' = `p'/10
	}
	else {
		while _rc {
			scalar `p' = `p'/10
			capture assert float(`depv') == float(round(`depv',`p')) if `touse'
		}
	}
	
		// Transform the bounded outcome

		tempvar logity flag   
		
		tempname depmin depmax epsilon 
		
		qui su `depv'		
		
		// Epsilon = (minimal increment of the dependent variable)/2
		
		scalar `epsilon' = `p'/2
		 
        if "`ymin'" == "" {
								scalar `depmin' = r(min)-`epsilon'
                                }
                           else {
								scalar `depmin' = `ymin'
                                }
								
     if "`ymax'" == "" {
					scalar `depmax' = r(max)+`epsilon'
                      }
                else {
					scalar `depmax' = `ymax'
					}

	qui gen `logity' = log((`depv'-`depmin')/(`depmax'-`depv'))                         

	if "`generate'" != "" {	
	
	local nw : word count `generate'
	
	if `nw' != 1 {
			di as err "specify one variable name"
			exit 198
	}
	else {
			gen double `generate' = `logity'
			label var `generate' "Logit `depv'"
	}
		
	}
	
	qui regress `logity' `rhs' if `touse'
 
		tokenize "`rhs'"
		local i 1
		while "``i''" != "" {
			if _se[``i''] == 0 {
				di in blu /*
			*/ "note: ``i'' dropped because of collinearity"
				local `i' " "
			}
			local i = `i' + 1
		}

		forvalues k=1/`nq' {
 			local myeq = "q" + string(`q`k''*100,"%2.0f")
			local eqnames `eqnames' `myeq'
		}
		local eqnames : list uniq eqnames
		local k : word count `eqnames'

		local k 1 
		while `k' <= `nq' {
			tempname coef`k'  vce`k'
			local myeq : word `k' of `eqnames'
			local i 1
			while "``i''" != "" {
				local result "`result' `coef`k''[1,`i']"
				local eqnams "`eqnams' `myeq'"
				local conams "`conams' ``i''"
				tempvar v
				local vl "`vl' `v'"
				local i = `i' + 1
			}
			local result "`result' `coef`k''[1,`i']"
			local eqnams "`eqnams' `myeq'"
			local conams "`conams' _cons"
			tempvar v
			local vl "`vl' `v'"
			local k = `k' + 1
		}
		
		preserve

		qui {
			keep if `touse'
			keep `depv' `logity' `rhs'
			qreg `logity' `rhs', `opts' q(`q1') 
		}
		if e(N)==0 | e(N)>=. { error 2001 } 
		local nobs `e(N)'
		local tdf `e(df_r)'
		local rsd1 `e(sum_rdev)'
		local msd1 `e(sum_adev)'

		local vle "_cons"
		local vli "`bcons'"

		mat `coefs' = e(b)
        mat `vce1' = e(V)
		
		local k 2
		while `k' <= `nq' {
		
			qui qreg `logity'  `rhs', `opts' q(`q`k'')
			if e(N) != `nobs' {
				di in red /*
	*/ "`q0' quantile:  `nobs' obs. used" _n /*
	*/ "`q`k'' quantile:  `e(N)' obs. used" _n /*
	*/ "Same sample cannot be used to estimate both quantiles." /*
	*/ "Sample size probably too small."
				exit 498
			}
			if e(df_r) != `tdf' {
				di in red /*
	*/ "`q0' quantile:  " `nobs'-`tdf' " coefs estimated" _n /*
	*/ "`q`k'' quantile:  " `e(N)'-`e(df_r)' coefs estimated" _n /*
	*/ "Same model cannot be used to estimate both quantiles." /*
	*/ "Sample size probably too small."
				exit 498
			}
			local msd`k' `e(sum_adev)'
			local rsd`k' `e(sum_rdev)'
			mat `coefs' = `coefs', e(b)
	
			mat  `vce`k'' = e(V)
		   
			local k = `k' + 1
		}
		
		mat colnames `coefs' = `conams'
		mat coleq `coefs' = `eqnams'

// Asymptotic standard errors using qreg

if ("`ase'" != "") {
	
		tempname coefs2
		mat `coefs2' = `coefs'
		
		//  Create the diagonal var/cov matrix from qreg output on each quantile
		
		mat `VCE' = `vce1' 
		
		version 9
		local k 2
		while `k' <= `nq' {
			mata: st_matrix("`VCE'", blockdiag(st_matrix("`VCE'"),st_matrix("`vce`k''")) )		
			local k = `k' + 1	
		}
		version 6
		
		mat rownames `VCE' = `conams'
		mat roweq `VCE' = `eqnams'
		mat colnames `VCE' = `conams'
		mat coleq `VCE' = `eqnams'
 
	     est  post `coefs2' `VCE', obs(`nobs') dof(`tdf') depn(`depv')
		 
		restore
		est repost, esample(`touse')   
}

// Bootstrap confidence intervals

if ("`ase'" == "") {
 
		qui gen double `bwt' = .
		`log' di in gr "(bootstrapping " _c
		qui postfile `handle' `vl' using "`BOOTRES'", double
		quietly noisily {
		
			// set the seed
			if "`seed'" != "" {
				set seed `seed'
			}
			local seed `c(seed)'
	
			local j 1
			while `j'<=`reps' {

				version 8
				if "`cluster'" != "" {
								bsample , weight(`bwt') cluster(`cluster') 
				}
				else {
								bsample , weight(`bwt') 
				}
				version 6
				
				capture noisily {
					local k 1
					while `k'<=`nq' {
						qreg_c `logity'  `rhs', /*
						*/ `opts' q(`q`k'') wvar(`bwt')
						mat `coef`k'' = e(b)
						local k =`k' + 1
					}
				}
				local rc = _rc
				if (`rc'==0) {
					post `handle' `result'
					`log' di in gr "." _c
					local j=`j'+1
				}
				else {
					if _rc == 1 { exit 1 }
					`log' di in gr "*" _c
				}
			}
		}
		local rc = _rc 
		postclose `handle'
		if `rc' { 
			exit `rc'
		}

		qui use "`BOOTRES'", clear

		quietly mat accum `VCE' = `vl', dev nocons
		mat rownames `VCE' = `conams'
		mat roweq `VCE' = `eqnams'
		mat colnames `VCE' = `conams'
		mat coleq `VCE' = `eqnams'
		mat `VCE'=`VCE'*(1/(`reps'-1))

		est post `coefs' `VCE', obs(`nobs') dof(`tdf') depn(`depv')
	
		`log' noi di in gr ")"
		restore
		est repost, esample(`touse')
		capture erase "`BOOTRES'"
		est scalar reps = `reps'
		est local vcetype "Bootstrap"
		
} // End Boostrap 

 
		est local depvar "`depv'"
		est scalar N = `nobs'
		est scalar df_r = `tdf'
		est scalar ymin = `depmin'
		est scalar ymax = `depmax'
		est local seed `seed'
	 
		local k 1
		while `k' <= `nq' {
			local rounded : di %3.2f `q`k''
			est scalar q`k' = `q`k''
			local k = `k' + 1
		}
		est scalar n_q = `nq'
		est local eqnames "`eqnames'"
		est scalar convcode = 0
		est repost, buildfvinfo
		est local marginsnotok stdp stddp Residuals
		est local predict "sqreg_p"
		version 9: ereturn local cmdline `"lqreg `cmdline'"'
		est local cmd "lqreg"
		_post_vce_rank
}

	di _n in gr "Logistic Quantile Regression" _col(54) _c
	di in gr "Number of obs =" in ye %10.0g e(N)
	di in gr "Bounded Outcome: `e(depvar)'" in gr "(" in y `e(ymin)' in gr ", " in y  `e(ymax)' in gr ")" _col(54) _c
	if ("`ase'" == "") {
								di in gr "Bootstrap(" in y `e(reps)' in gr ") SEs"
	}
	else {
			di in gr "Asymptotic SEs"  
	}

	PrForm `e(q1)'	
	
	di  

	estimates display, level(`level') 

	error `e(convcode)'
end

capture program drop SetQ
program define SetQ /* <nothing> | # [,] # ... */ , rclass
	if "`*'"=="" {
		ret local quants ".5"
		exit
	}
	local orig "`*'"

	tokenize "`*'", parse(" ,")

	while "`1'" != "" {
		FixNumb "`orig'" `1'
		ret local quants "`return(quants)' `r(q)'"
		mac shift 
		if "`1'"=="," {
			mac shift
		}
	}
end

capture program drop FixNumb
program define FixNumb /* # */ , rclass
	local orig "`1'"
	mac shift
	capture confirm number `1'
	if _rc {
		Invalid "`orig'" "`1' not a number"
	}
	if `1' >= 1 {
		ret local q = `1'/100
	}
	else 	ret local q `1'
	if `return(q)'<=0 | `return(q)'>=1 {
		Invalid "`orig'" "`return(q)' out of range"
	}
end
		
capture program drop Invalid
program define Invalid /* "<orig>" "<extra>" */
	di in red "quantiles(`1') invalid"
	if "`2'" != "" {
		di in red "`2'"
	}
	exit 198
end

capture program drop PrForm
program define PrForm /* # */ , rclass
	local aa : di %8.2f `1'
	ret local pr `aa'
	if substr("`return(pr)'",1,1)=="0" {
		ret local pr = substr("`return(pr)'",2,.)
	}
end

exit
