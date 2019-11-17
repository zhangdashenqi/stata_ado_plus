*! ver 1.1 -- pbe 3/14/06
*! ver 1.0 -- pbe 5/2/02
*! originated as tmeans -- pbe 4/5/00
program define robmean, rclass
  version 6.0
  syntax varlist(max=1) [if] [in]  [, trim(real 0.2) k(real 1.28) ]
  tokenize `varlist'
  preserve
  marksample touse
  quietly keep if `touse'
  display
  display in green "`trim' highest and lowest cases trimmed or winsorized"
  display
  display in green %14s "`1' |" "     Obs     Estimate   Std. Dev.     Min       Max"
  display in green "-----------------------------------------------------------------"

  tempvar winvar mestvar mdif rwt
  generate `winvar' = `1'
  generate `mestvar' = `1'
  generate `mdif' = `1'

    quietly sort `1'
    quietly count if `1' == .
    local mcount = r(N)
    quietly count if `1' ~= .
    local ntrim = int(r(N) * `trim') + 1
    local last = r(N) -`mcount' - `ntrim' + 1
    quietly summarize `1', detail   
    display in green %14s "mean |" in yellow  %8.0f r(N) %12.4f r(mean) /*
            */ %12.4f r(sd) %10.0g r(min) %9.0g r(max)
    display in green %14s "median |" in yellow  %8.0f r(N) %12.4f r(p50) 
    return scalar mean = r(mean)
    return scalar median = r(p50)
    local med=r(p50)
    return scalar N = r(N)
    quietly summarize `1' in `ntrim'/`last' 
    display in green %14s "trimmed |" in yellow  %8.0f r(N) %12.4f r(mean) /*
            */ %12.4f r(sd) %10.0g r(min) %9.0g r(max)
    return scalar tr_mean = r(mean)
    return scalar tr_N = r(N)
    quietly replace `winvar' = `1'[`ntrim'] in 1/`ntrim'
    quietly replace `winvar' = `1'[`last'] in `last'/l
    quietly summarize `winvar'        
    display in green %14s "winsorized |" in yellow  %8.0f r(N) %12.4f r(mean) /*
            */ %12.4f r(sd) %10.0g r(min) %9.0g r(max)
    return scalar wi_mean = r(mean)
    
    egen t1_madn = mad(`mestvar')
    local madn = t1_madn/.6745
      quietly replace `mdif' = abs(`1' - `med') 
      quietly replace `mdif' = `mdif'/`madn'
      drop t1_madn
    quietly replace `mestvar'=. if `mdif'>`k'
    quietly count if `1'<`med' & `mestvar'==.
    local lower=r(N)
    quietly count if `1'>`med' & `mestvar'==.
    local upper=r(N)
    local num1 = (`k'*`madn')*(`upper'-`lower')
    
    quietly summarize `mestvar' 
    local huber = (`num1'+r(sum))/r(N)
    display in green %14s "huber 1-step |" in yellow  %8.0f r(N) %12.4f `huber' /*
            */ _skip(12)  %10.0g r(min) %9.0g r(max)
            
                quietly summarize `mestvar'
        local mome = r(mean)
        display in green %14s "mod 1-step |" in yellow  %8.0f r(N) %12.4f `mome' /*
            */ %12.4f r(sd)  %10.0g r(min) %9.0g r(max)
    return scalar one_step = `huber'
        return scalar mod_1_step = `mome'
    quietly rreg `1', gen(`rwt')
    local mest = _b[_cons]
    quietly summarize `1' if `rwt'~=. & `rwt'>.01
    display in green %14s "multi-step |" in yellow  %8.0f r(N) %12.4f `mest' /*
            */ _skip(12)  %10.0g r(min) %9.0g r(max)
    return scalar multi_step = `mest'
  display in green "-----------------------------------------------------------------"
end
