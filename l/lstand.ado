*! version 1.0.1  J. Hilbe: 11-11-96        STB-35: sg63
* Calculation of Standardized coefficients, Atkinson's R, and comparative
*    statistics following the logistic command

program define lstand
version 3.0
   if "$S_E_cmd"~="logistic" {
   noi di in red "To be used following " in bl "logistic " in red "command"
   error 301
   }
   local in "opt"
   local if "opt"
   local weight "fweight"
   parse "`*'"
   parse "$S_E_vl", parse(" ")
   if "$S_E_wgt"!="" {
       if "`weight'"=="" {
            local wgt "[{S_E_wgt}{S_E_exp}]"
            local subttl ", weighted statistics"
       }
       else local subttl ", unweighted statistics"
    }
    if "`if'`in'`all'"=="" {
         local if "$S_E_if"
         local in "$S_E_in"
    }
    qui {
    local depvar "$S_E_depv"
    qui logistic
    local llo=(_result(6) + (-2*_result(2)))/2
    tempvar cof secof wald parcor stdcof z pz or
        gen `cof'    =.
        gen `secof'  =.
        gen `wald'   =.
        gen `parcor' =.
        gen `stdcof' =.
        gen `z'      =.
        gen `pz'     =.
        gen `or'     =.
        local i = 0
        mac shift

     noi di _n in gr "Table of Predictor Estimates:
     noi di in gr "Standardized Coefficients and Partial Correlations"
     noi di in gr _n _col(1) /*
 */ "No.  Var         Coef          OR      St.Coef      PartCorr    Prob(z)"
     noi di in gr _dup(71) "="
     noi di in gr _col(1) "0" _col(5) "Constant" %9.4f in ye _col(13) /*
        */ _coef[_cons]
     while "`1'"!= "" {
          local i=`i'+1
            replace `cof'   = _b[`1'] in `i'
            replace `or'    = exp(_b[`1']) in `i'
            replace `secof' = _se[`1'] in `i'
            qui summ `1'
            replace `stdcof' = (_b[`1']*sqrt(_result(4)))/1.8137994
            replace `wald'  = (`cof'/`secof')^2 in `i'
            replace `parcor'= sqrt((`wald'-2)/(2*abs(`llo')))
            replace `parcor'=-`parcor' if (`cof')<0
            replace `parcor'= 0 if `wald'<2
            replace `z'     = `cof'/`secof' in `i'
            replace `pz'    = normprob(`z')*2 if `z'<=0 in `i'
            replace `pz'    = (1-normprob(`z'))*2 if `z'>=0 in `i'
            #delimit ;
            noisily di in gr `i' %9.4f _col(5) "`1'" %9.4f in ye _col(13)
                             `cof'[`i'] %9.4f _col(25) `or'[`i'] %9.4f
                             _col(38) `stdcof'[`i'] %9.4f _col(52)
                             `parcor'[`i'] %7.3f _col(65) `pz'[`i'];
            #delimit cr
            mac shift
       }
       noi di in gr _dup(71) "="
    }
end

