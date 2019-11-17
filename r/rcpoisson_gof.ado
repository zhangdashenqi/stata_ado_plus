*!version 1.2.0  30jan2001
program define rcpoisson_gof, rclass
	version 7.0
	syntax [, Pearson]
	if "`e(cmd)'" != "rcpoisson" {
		di as error "last estimates for rcpoisson not found"
		exit 301
	}
	quietly {
		tempvar lstobs wt
		gen long `lstobs'=_n if e(sample)
		replace `lstobs'=`lstobs'[_n-1] if `lstobs'==.
		local lastobs=`lstobs'[_N]
		local dv "`e(depvar)'"

		if "`e(wexp)'"!="" {
			gen float `wt' `e(wexp)' if e(sample)
			if "`wtype'"=="aweight" {
				noisily di as text /*
	*/ "note: you are responsible for interpretation of analytic weights"
				sum `wt' if e(sample)
				replace `wt' = `wt'/r(mean)   
			}
		}
		else    gen float `wt' = e(sample)
	
		if "`pearson'"=="" {
			tempvar Poisson
			_crclf `Poisson' = `dv' if e(sample) 
			replace `Poisson' = sum(`Poisson'*`wt') if e(sample)
			local llconst = `Poisson'[`lastobs']
			replace `Poisson' = cond(`dv'==0, 0, /*
				*/ `dv'*(ln(`dv')-1)) if e(sample)
			replace `Poisson' = sum(`Poisson'*`wt') if e(sample)
			local llperf = `Poisson'[`lastobs'] - `llconst'
	
			local chi2 = -2*(e(ll) - `llperf')
		}
		else {
			tempvar yhat elem
			predict `yhat' if e(sample), n
			gen double `elem' = `wt'*(`dv'-`yhat')^2/`yhat'
			summarize `elem' if e(sample), meanonly

			local chi2 = r(sum)
		}
		local df   = e(N) - e(df_m) - 1
		local prob = chiprob(`df',`chi2') 

		ret scalar chi2 = `chi2'
		ret scalar df   = `df'
	}
	di
	di as text _col(10) "Goodness-of-fit chi2" /*
		*/ _col(32) "= " as result %9.0g `chi2'
	di as text _col(10) "Prob > chi2(" as result `df' as text ")" /*
		*/ _col(32) "=    " as result %6.4f `prob'
end

program define _crclf
        version 7.0
	syntax newvarname(gen) =exp [in] [if]
        tempvar tmp
        quietly {
                gen `tmp' `exp' `if' `in'
                replace `1' = lngamma(1 + `tmp')
        }
end
exit
exit

Uses e(gof) preferentially as the gof command.  
If this is not found will see if cmd2(1-6)_g exists,
then if est_command(1-6)_g exists, 
Otherwise, uses _gof

