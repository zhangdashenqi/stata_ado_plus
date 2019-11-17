*! version 3.0.7  30march2006 Cappellari & Jenkins (aa option dropped; use -mdraws- instead)
*! version 3.0.6  30march2006 Cappellari & Jenkins (antithetic var type double in adoonly code)
*! version 3.0.5  24march2006 Cappellari & Jenkins (draws vble names altered so can have M>=10)
*! version 3.0.4  15march2006 Cappellari & Jenkins (cholesky matrix checking altered again)
*! version 3.0.3  11feb2006 Cappellari & Jenkins (more cholesky matrix checking)
*! version 3.0.2  08feb2006 Cappellari & Jenkins (mucked with by Gutierrez for plugin)
*! version 3.0.1  06dec2005 Cappellari & Jenkins (cholesky factors not corrs, drop means option)
*! version 2.2.0  01aug2005  Cappellari & Jenkins (means option as matrix not list)
*! version 2.1.0  01june2005  Cappellari & Jenkins (aa option added)
*! version 2.0.0  19apr2005  Cappellari & Jenkins
*! Multivariate normal probabilities by method of MSL

program _gmvnp
        version 8.2

	gettoken type 0 : 0
	gettoken g 0 : 0
	gettoken eqs 0 : 0

	syntax varlist [if] [in], PREfix(string) ///
		CHOL(name) [ DRaws(integer 5) ///
		Signs(varlist) ADOonly]

	local Z "`prefix'"
	local D "`draws'"
	local M : word count `varlist'
	if `M' < 2 {
		di as error "need at least two variables"
		exit 198
	}

	// Error trapping on Cholesky matrix:
	//   (a) square
	//   (b) lower triangular <=> above-diagonal elements = 0


        local nrows = rowsof(`chol')
        local ncols = colsof(`chol')
        if "`nrows'" != "`ncols'" {
                di as err "{p 0 0 4}number of rows and cols of Cholesky "
                di as err "matrix should be equal{p_end}"
                exit 503
        }

        forval j = 1/`M' {
                if `j' > 1  {
                        forval i = `=`j'-1'(-1)1 {
                                if `chol'[`i',`j'] != 0 {
                    di as err "{p 0 0 4}Cholesky matrix should be lower triangular: "
                    di as err "elements above leading diagonal should equal 0{p_end}"
                    exit 198
                                }
                        }
                }
        }
 

quietly {

	marksample touse
	markout `touse' `varlist'   

        count if `touse' 
        if r(N) == 0 { 
                di as error "no valid observations"
                error 2000
	}

	gen double `g' = 0 if `touse'		// override user type
	tempvar sp0 
	gen double `sp0' = 1 if `touse'

	if "`adoonly'" == "" {
		capture plugin call _mvnp, names `Z' `D' `M' vnames
		if _rc == 199 {
			di as err "plugin not loaded or not available: " _c
			di as err "use the " as inp "adoonly" as err " option"
			exit 199
		}
		local todo calc`aa'
		plugin call _mvnp `g' `varlist' `vnames' `signs' ///
			if `touse', `todo' `D' `M' `chol' 
		exit
	}

	tokenize `varlist'			// varlist has dimension M
	local i = 1				// see [P] p. 236 re style
	while "``i''" ~= ""	{
		tempvar I`i' d`i' arg`i' sp`i'	
		if "`signs'" != "" {
			local k`i' : word `i' of `signs'
		}
		else {
			local k`i' = 1
		}

		gen double `I`i'' = ``i''  if `touse'	
		gen double `d`i'' = 0  if `touse'
		gen double `sp`i'' = 0 if `touse'
		gen double `arg`i'' = 0 if `touse'

		forval j = 1/`i' {
			tempname c`i'`j'
			scalar `c`i'`j'' = `chol'[`i',`j']
		}
		local i = `i' + 1
	}

	forval d = 1/`D' {
		forval i = 1/`M' {
			replace `arg`i'' = `k`i'' *`I`i''

			if `i' > 1 {
				forval j = `=`i'-1'(-1)1 {
		replace `arg`i'' = `arg`i'' - `k`i''*`k`j''*`d`j''*`c`i'`j''
				}
			}
			replace `d`i'' = invnorm(`Z'`i'_`d'* ///
					   normprob((`arg`i'')/`c`i'`i''))
			local j = `i'-1
			
		replace `sp`i'' = normprob((`arg`i'')/`c`i'`i'')*`sp`j''
			
			
		}
		replace `g' = `g' + `sp`M''/`D'  
	}
}  

end

capture program _mvnp, plugin using("mvnp.plugin")
