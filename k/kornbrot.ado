*! Richard Goldstein 2.0.0 20 Oct 2002
* NJC assist 
*! kornbrot -- Kornbrot's rank difference test   (STB-29: snp9)
program define kornbrot
	version 7.0
	syntax varname =/exp [if] [in] 
	tempvar score rank ranka rankb touse id
	unab exp : `exp'   
	preserve
	marksample touse
        markout `touse' `exp'

	quietly { 
	        count if `touse'
	        local n = r(N)
		if `n' == 0 {
			noi di as txt "no observations"
			exit 2000 
		} 
		keep if `touse' 
	        gen `id' = _n
		expand =2
		gen `score' = cond(_n <= `n', `varlist', `exp') 
		egen `rank' = rank(`score')
		replace `rank' = (2 * `n' + 1) - `rank'
		gen `ranka' = `rank' in 1/`n'             
		gen `rankb' = `rank' in -`n'/l         
		sort `id' `ranka'
		replace `rankb' = `rankb'[_n+1] if `rankb' == .
	        drop if `ranka' == . | `ranka' == `ranka'[_n-1]
		replace `varlist' = `ranka'  
		replace `exp' = `rankb'  
	} 
	
	signrank `varlist' = `exp'
end

