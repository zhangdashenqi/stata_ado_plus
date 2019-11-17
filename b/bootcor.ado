*! Version 1.0.3 <DJN; 12-8-99>  (STB-55: sg138)
program define bootcor, rclass  
    version 6.0

/* PARSE THE COMMAND AND PREPARE VARIABLES */
syntax varlist(min=3 max=4) [if] [in] [, Reps(int 50) STat(string) LEvel(real $S_level) /*
               */ SAVing(string)] 

preserve
qui {
    marksample touse
    keep if `touse'
}

tokenize `varlist'
local W `1'
local X `2'
local Y `3'
local Z `4'
if "`4'" == "" { 
    local Y `1'
    local Z `3' }

if "`stat'" == "" { local stat = "pearson" }

/* CHECK FILE OUTPUT IF NECESSARY */ 
qui if "`saving'" ~= "" {
    confirm new file "`saving'.dct" } 

/* SET LEVEL OF CONFIDENCE */
if `level' <= 0 | `level' > 99.9 {
    di "Invalid Confidence Level"
    error 499 }
if `level' >= 1 {
    local level = `level'/100 }
local ci_z = invnorm((1-((1-`level')/2))) 
local levper = `level' * 100

/*GENERATE SOME SPACE FOR THE TEMPORARY VARIABLES*/ 
local N = _N
qui if `reps' > _N { set obs `reps' } 

/*GENERATE TEMPORARY VARIABLES*/
tempvar WW_ XX_ YY_ ZZ_ II_ 
qui { 
    gen `WW_' = . 
    gen `XX_' = .
    gen `YY_' = .
    gen `ZZ_' = .
    gen `II_' = .
    gen r_boot1 = .
    gen r_boot2 = .
    gen z_boot1 = .
    gen z_boot2 = . 
    gen z_bootd = . } 

/*CREATE BOOTSTRAP RESAMPLES*/
if "`stat'" == "icc" {
    local cmd "icc"
    local res "r(icc)" }
else if "`stat'" == "pearson" {
    local cmd "corr"
    local res "r(rho)" }
else if "`stat'" == "concord" {
    local cmd "concord"
    local res "r(conc)" }
else {
    disp in re "Invalid Statistic"
    disp in re "You have selected a statistic that is either not supported by this"
    disp in re "ado file or is not installed on your machine."
    error 499 }

qui {
    `cmd' `W' `X'
    local valwx = `res'
    `cmd' `Y' `Z'
    local valyz = `res' }
local i 0 
qui while `i' < `reps' { 
    local i = `i' + 1
    replace `II_' = 1 + int(`N'*uniform()) in 1/`N'
    replace `WW_' = `W'[`II_'] in 1/`N'
    replace `XX_' = `X'[`II_'] in 1/`N'
    replace `YY_' = `Y'[`II_'] in 1/`N'
    replace `ZZ_' = `Z'[`II_'] in 1/`N'

    `cmd' `WW_' `XX_' in 1/`N'
    replace r_boot1 = `res' in `i'
    `cmd' `YY_' `ZZ_' in 1/`N'
    replace r_boot2 = `res' in `i' }

/*CREATE DIFFERENCE SCORES */
qui { 
    replace z_boot1 = .5 * (ln((1 + r_boot1)/(1 - r_boot1))) - r_boot1/(2*`N' - 5)
    replace z_boot2 = .5 * (ln((1 + r_boot2)/(1 - r_boot2))) - r_boot2/(2*`N' - 5)
    replace z_bootd = z_boot1 - z_boot2 }

/* OUTPUT TO FILE IF NECCESSARY */ 
qui if "`saving'" ~= "" {
    label variable r_boot1 "Correlation of `W' and `X'"
    label variable r_boot2 "Correlation of `Y' and `Z'"
    label variable z_boot1 "Z-Transform of Correlation of `W' and `X'"
    label variable z_boot2 "Z-Transform of Correlation of `Y' and `Z'" 
    label variable z_bootd "Z-Transform Difference Score"
    outfile r_boot1 r_boot2 z_boot1 z_boot2 z_bootd using `saving', dict } 

/*CALCULATE THE STATISTICS*/
qui {
    su z_boot1 
    local boo1_se = sqrt(r(Var)) 
    local boo1_me = r(mean) 
    local boo1_ll = `boo1_me' - `ci_z' * `boo1_se'
    local boo1_ul = `ci_z' * `boo1_se' + `boo1_me'
    local rbo1_me = (exp(2 * `boo1_me') -1 ) / (exp(2 * `boo1_me') + 1)
    local rbo1_ll = (exp(2 * `boo1_ll') -1 ) / (exp(2 * `boo1_ll') + 1)
    local rbo1_ul = (exp(2 * `boo1_ul') -1 ) / (exp(2 * `boo1_ul') + 1)
    
    su z_boot2
    local boo2_se = sqrt(r(Var)) 
    local boo2_me = r(mean) 
    local boo2_ll = `boo2_me' - `ci_z' * `boo2_se'
    local boo2_ul = `ci_z' * `boo2_se' + `boo2_me'
    local rbo2_me = (exp(2 * `boo2_me') -1 ) / (exp(2 * `boo2_me') + 1)
    local rbo2_ll = (exp(2 * `boo2_ll') -1 ) / (exp(2 * `boo2_ll') + 1)
    local rbo2_ul = (exp(2 * `boo2_ul') -1 ) / (exp(2 * `boo2_ul') + 1)
    
    su z_bootd
    local bood_se = sqrt(r(Var)) 
    local bood_me = r(mean) 
    local bood_ll = `bood_me' - `ci_z' * `bood_se'
    local bood_ul = `ci_z' * `bood_se' + `bood_me'
    local z_z = r(mean)/(sqrt(r(Var)))
    local z_p1 = normprob(`z_z')

    if `z_p1' < .5 {
        qui local z_p2 = `z_p1' * 2 }
    if `z_p1' >= .5 {
        qui local z_p2 = (1-`z_p1') * 2 } 
}

/*OUTPUT RESULTS*/

disp ""
if "`stat'" == "pearson" {
     disp in gr "Results of Bootstrap Comparison of Pearson's R" }
if "`stat'" == "icc" {
     disp in gr "Results of Bootstrap Comparison of Intraclass Correlation" }
if "`stat'" == "concord" {
     disp in gr "Results of Bootstrap Comparison of Concordance" }
disp in gr _dup(72) "-"
disp in gr "Bootstrap Replications: " in ye `reps' _skip(6)in gr "Observations: " in ye `N'
disp in gr _dup(72) "-"
disp in gr "Variables" _col(20) "Observed" _col(35) "Bootstrap Mean(R)" _col(55) /*
          */"[    `levper'% CI    ]"
disp in ye "`W' & `X'" _col(20) %4.3f `valwx' _col(35) %4.3f `rbo1_me' _col(56) %4.3f /*
          */`rbo1_ll' _skip(4) %4.3f `rbo1_ul'  
disp in ye "`Y' & `Z'" _col(20) %4.3f `valyz' _col(35) %4.3f `rbo2_me' _col(56) %4.3f /*
          */`rbo2_ll' _skip(4) %4.3f `rbo2_ul' 
disp in gr _dup(72) "-"
disp in gr "Z-score of Fisher R-to-Z Difference: " in ye %4.3f `z_z' in gr  _skip(6) /*
          */"P-Value: " in ye %4.3f `z_p2'
disp in gr _dup(72) "-"


/* RETURN VALUES */
return scalar bsed = `bood_se'
return scalar bse1 = `boo1_se'
return scalar bse2 = `boo2_se'
return scalar bcorr2u = `rbo2_ul'
return scalar bcorr2l = `rbo2_ll'
return scalar bcorr2 = `rbo2_me'
return scalar corr2 = `valyz'
return scalar bcorr1u = `rbo1_ul'
return scalar bcorr1l = `rbo1_ll'
return scalar bcorr1 = `rbo1_me'
return scalar corr1 = `valwx'
return scalar p = `z_p2'
return scalar z = `z_z'

end


/* ICC AND CONCORD SUBROUTINES FOR STATA V.6 */

program define icc, rclass
*! Adapted from iclassr2.ado version 1.1.2  <JRG; 28Oct98>  
version 6.0
syntax varlist (min=2 max=2) [in] [if]
tempname m k f
tempvar tt
gen `tt' = `1' + `2'
summ `tt'
scalar `k' = r(N)
scalar `f' = r(Var)
replace `tt' = `1' - `2'
summ `tt'
scalar `f' = `f'/((`k'-1)*r(Var)/`k' + r(mean)*r(mean))
scalar `m' = 1
return scalar icc = (`f' - `m') / (`f' + `m')
end


program define concord, rclass
*! Adapted from concord.ado version 2.1.6 18jun1998  TJS & NJC  STB-45 sg84.1
version 6.0
syntax varlist (min=2 max=2) [in] [if]
tempname k xb yb sx2 sy2 r sxy p
qui summ `1'
scalar `k'   = r(N)
scalar `yb'  = r(mean)
scalar `sy2' = r(Var) * (`k' - 1) / `k'
qui summ `2'
scalar `xb'  = r(mean)
scalar `sx2' = r(Var) * (`k' - 1) / `k'
qui corr `1' `2'
scalar `r'   = r(rho)
scalar `sxy' = `r' * sqrt(`sx2' * `sy2')
scalar `p'   = 2 * `sxy' / (`sx2' + `sy2' + (`yb' - `xb')^2)
return scalar conc = `p'
end

