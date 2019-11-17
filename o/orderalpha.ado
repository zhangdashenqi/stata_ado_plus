********************************************************************************************************************************
** ORDER-ALPHA-EFFICIENCY (orderalpha) *****************************************************************************************
********************************************************************************************************************************

*! version 1.0.2 2012-02-06 ht
*! author Harald Tauchmann
*! Order-alpha efficiency analysis  

capture program drop orderalpha
program orderalpha, eclass
version 11.1
if !replay() {
    quietly {
        local cmd "orderalpha"
        local cmdline "`cmd' `*'"
        syntax anything(equalok) [if] [in], [DMU(varlist max=1)] [ALPha(real 100)] [ORT(string)] /*
        */ [GENerate(namelist max=3 local)] [NOGenerate] [REPLace] [BOOTstrap] [REPS(integer 0)] [TUNe(real 0)] [TABle(string)] [INVert] [DOTs(integer 0)] [LEVel(real 95)] 
            ** MANAGE MORE
            local moreold `c(more)'
            set more off
			** TOKENIZE ANYTHING
			tokenize `anything', parse("=")
            if "`1'"  == "=" {
                display as error "Error: no inputs specified"
				exit 102
            }
			unab inputs : `1' 
			macro shift
			local outputs "`*'"
            if "`outputs'"  == "" {
                display as error "Error: invalid syntax"
				exit 198
            } 
			if "`outputs'"  == "=" | "`outputs'"  == "= " {
                display as error "Error: no outputs specified"
				exit 102
            }
			local outputs : subinstr local outputs "=" "", all count(local eqerror)
            if `eqerror'  > 1 {
                display as error "Error: invalid syntax"
				exit 198
            }
			unab outputs : `outputs'
            ** CHECK FOR DUPLICATES IN INPUT-LIST
			local duperror : list dups inputs
            if "`duperror'" != "" {
                local inputs : list uniq inputs
                display as error "Warning: duplicates in list of inputs dropped"
            }
            ** CHECK FOR DUPLICATES IN OUTPUT-LIST
			local duperror : list dups outputs
            if "`duperror'" != "" {
                local outputs : list uniq outputs
                display as error "Warning: duplicates in list of outputs dropped"
            }
            ** NUMBER OF INPUTS and OUTPUTS
            local nin : word count `inputs'
            local nout : word count `outputs'
            ** TEMPORARY FILES, MATRICES, and VARIABLES
            tempfile resufile
            tempname _oaeffi _bbstr _mbbstr _empmat _oarank _bb _bV _b_bs _reps _bias _se _refmat _oarefs 
            tempvar _tempid _orgord _strid _xmax _xmin _in_exclu _out_exclu _effrank _bweight _esamp _tempsavee _tempsaver _tempsavep _obsno _tab_dmu _tab_eff _tab_se _tab_z _tab_rank _tab_ref
            forvalues jj = 1(1)`nin' {
                tempvar _xi_`jj'
            }
            forvalues jj = 1(1)`nout' {
                tempvar _xo_`jj'
            }
            ** CHECK INPUT-OUTPUT-SPECIFICATION
			local ioerror : list inputs & outputs
            if "`ioerror'" != "" {
				local nioerror : word count `ioerror'
				if `nioerror' == 1 {
					display as error "Error: variable `ioerror' is input and output"
				}
				else {
					display as error "Error: variables `ioerror' are inputs and outputs"
				}
                exit 103
            }
            ** CHECK SPECIFICATION OF ORIENTATION
			if "`ort'" == "outpu" | "`ort'" == "outp" | "`ort'" == "out" | "`ort'" == "ou"  | "`ort'" == "o" {
				local ort "output"
			}
			if "`ort'" == "inpu" | "`ort'" == "inp" | "`ort'" == "in" | "`ort'" == "i"  {
				local ort "input"
			}
            if "`ort'" != "output" & "`ort'" != "input" & "`ort'" != "" {
                display as error "Error: option ort incorrectly specified"
                exit 198            
            }
            local ort2 "`ort'"
            if "`ort'" == "" {
                local ort2 "input"
            }
            ** CHECK SPECIFICATION OF ALPHA
            if `alpha' > 100 | `alpha' <= 0 {
                display as error "Error: alpha outside the interval (0,100]"
                exit 198
            }
            if `alpha' < 1 & `alpha' > 0 {
                display as error "Warning: alpha < 1, alpha must be specified in terms of percentiles!"
            }
            ** ALPHA: ROUNDED and COMPLEMENT VALUE
            local ralpha = round(`alpha')
            local r2alpha = string(`alpha',"%-05.2f")
            local ialpha = 100-`alpha'
            ** CHECK OPTION LEVEL
            if `level' < 10 | `level' >= 100 {
                local level = 95
            }
            ** CHECK BOOTSTRAP SPECIFICATION
            local reps2 = `reps'
            if `reps' == 0 & "`bootstrap'" == "" {
                local noboot = 1
            }
            if `reps' > 0 & "`bootstrap'" == "" {
                local noboot = 0
                if `reps' == 1 {
                    display as error "Error: reps() must be an integer greater than 1"
                    exit 198
                }
            }
            if `reps' == 0 & "`bootstrap'" == "bootstrap" {
                local noboot = 0
                local reps2 = 100
            }
            if `reps' > 0 & "`bootstrap'" == "bootstrap" {
                local noboot = 0
                if `reps' == 1 {
                    display as error "Error: reps() must be an integer greater than 1"
                    exit 198
                }
            }
            ** CHECK BOOTSTRAP-TUNING PARAMETER
            if `tune' == 0 {
                local tune = (1+ exp(0.5*(100-`alpha')))/(2+ exp(0.5*(100-`alpha')))
            }
            if `tune' < 0.5 |  `tune' > 1 {
                local tune = (1+ exp(0.5*(100-`alpha')))/(2+ exp(0.5*(100-`alpha')))
                display as error "Warning: tune() ouside interval [0.5,1], set to default: `tune'"
            }
            ** INVERTING of OUTPUT-ORIENTED EFFICIENCY **
            if "`ort'" == "output" & "`invert'" == "invert" {
                local invi = -1
            }
            else {
                local invi = 1
            }
            ** NEW SAVE LOCALS
            local nsave : word count `generate'
            if "`nogenerate'" != "nogenerate" {
                if `nsave' == 0 {
                    if `alpha' == 100 { 
                        local savee "_fdh_`ort2'"
                        local saver "_fdhrank_`ort2'"
                        local savep "_fdhref_`ort2'"
                    }
                    else {
                        local savee "_oa_`ort2'_`ralpha'"
                        local saver "_oarank_`ort2'_`ralpha'"
                        local savep "_oaref_`ort2'_`ralpha'"
                    }
                }
                if `nsave' == 1 {
                    local savee : word 1 of `generate'
                    if `alpha' == 100 { 
                        local saver "_fdhrank_`ort2'"
                        local savep "_fdhref_`ort2'"
                    }
                    else {
                        local saver "_oarank_`ort2'_`ralpha'"
                        local savep "_oaref_`ort2'_`ralpha'"
                    }
                }
                if `nsave' == 2 {
                    local savee : word 1 of `generate'
                    local saver : word 2 of `generate'
                    if `alpha' == 100 { 
                        local savep "_fdhref_`ort2'"
                    }
                    else {
                        local savep "_oaref_`ort2'_`ralpha'"
                    }
                }
                if `nsave' == 3 {
                    local savee : word 1 of `generate'
                    local saver : word 2 of `generate'
                    local savep : word 3 of `generate'
                }
            }
            else {
                local savee "`_tempsavee'"
                local saver "`_tempsaver'"
                local savep "`_tempsavep'"
            }
            ** DROP VARIABLES TO BE REPLACED
            if "`replace'" == "replace" {
                capture drop `savee'
                capture drop `saver'
                capture drop `savep'
                capture drop `savep'*
            }
            ** CHECK DMU-IDENTIFIER AND CREATE TEMPORARY ID
			if "`dmu'" == "" {
				tempvar _id 
				gen `_id' = _n
				local varlist "`_id'"
			}
			else {
				local varlist "`dmu'"
			}
			gen `_orgord' =_n
			sort `varlist'
            gen `_tempid' = _n
            sort `_orgord'
            ** PRESERVE ORIGINAL DATA-FILE
            preserve
            sort `varlist'
            ** GENERATE EMPTY SAVE-VARIABLES
            gen `savee' =.
            gen `saver' =.
            ** CHECK WHETHER DMU-IDENTIFIER IS STRING
            capture confirm string variable `varlist'
            if !_rc {
                gen `savep' = ""
            }
            else {
                gen `savep' =.
            }           
            ** CHECK OPTION GENERATE
            if "`nogenerate'" == "nogenerate" & `nsave' != 0 {
                display as error "Warning: option generate(`generate') inconsistent with option nogenerate, no variable saved"
            }
            ** SELECT RELEVANT SAMPLE
            if `"`if'"' != `""' {
                keep `if'
            }
            if `"`in'"' != `""' {
                keep `in'
            }
            ** DROP DMUs WITH MISSING INFORMATION
            foreach jj of varlist `inputs' `outputs' {
                drop if `jj' <= 0 | `jj' >=.
            }
            drop if missing(`varlist')
            ** SAMPLE-SIZE FOR EFFICIENCY ANALYSIS
            local samps = _N
            ** CHECK FOR EMPTY SAMPLE 
            if `samps' == 0 {
                display as error "Error: no observations"
                restore
				sort `_orgord' 
				exit 2000
            }
            ** CHECK IDENTIFIER FOR DUPLICATES
            duplicates report `varlist'
            if r(N) > r(unique_value) {
                noisily: display as error "Error: variable `varlist' does not uniquely identify dmus"
                restore
				sort `_orgord' 
                exit 498
            }
            ** CHECK SPECIFICATION of OPTION TABLE
			if "`table'" == "ful" | "`table'" == "fu" | "`table'" == "f" { 
                local table "full"
            }
			if "`table'" == "score" | "`table'" == "scor" | "`table'" == "sco" | "`table'" == "sc" | "`table'" == "s" {   
                local table "scores"
            }
            if "`table'" != "scores" & "`table'" != "full" {
                if "`table'" != "no" & "`table'" != "" {
                    display as error "Warning: option table() incorrectly specified, set to default: table(no)"
                }
                local table "no"
            }
            if "`table'" == "full" & `samps' > 2994 {
                local table "scores"
                display as error "Warning: too many dmus for table(full), switched to table(scores)"
            }
            ** VARIABLE: OBS-NUMBER
            gen `_obsno' = _n
            capture confirm string variable `varlist'
            if !_rc {
                gen `_strid' = strtoname(`varlist',0)
            }
            else {
                capture recast int `varlist' 
                capture confirm int variable `varlist'
                if _rc {
                    display as error "Warning: non-integer numeric variable used as identifier, may cause error"
                    tostring `varlist', generate(`_strid') force
                    replace `_strid' = strtoname(`_strid',1)
                }
                else {
                    tostring `varlist', generate(`_strid')
                }
            }
            mat `_empmat' = J(`samps',1,1)
            mata : dmumatname("`_strid'", "`_empmat'")
            mat `_empmat' = `_empmat''
            mat coleq `_empmat' = `varlist'
			if "`dmu'" == "" {
				local cn : colnames `_empmat'
			}
			else {
				local cn : colfullnames `_empmat'
			}
            ** COMPUTE ORIGINAL EFFICIENCY SCORES
            if "`ort'" == "output" {
                forvalues ii = 1(1)`samps' {
                    capture drop `_xmin'
                    local jj = 0
                    foreach vv of varlist `outputs' {
                        local jj = 1+ `jj'
                        capture drop `_xo_`jj'' 
                        gen `_xo_`jj'' = `vv'/`vv'[`ii']
                        if `jj' == 1 {
                            local xrlo "`_xo_`jj''"
                        }
                        else {
                            local xrlo "`xrlo', `_xo_`jj''"
                        }
                    }
                    if `jj' == 1 {
                        gen `_xmin' = `xrlo'
                    }
                    else {
                        gen `_xmin' = min(`xrlo')
                    }
                    capture drop `_in_exclu'
                    gen `_in_exclu' = 0
                    foreach vv of varlist `inputs' {
                        replace `_in_exclu' = 1 if `vv' > `vv'[`ii']
                    }   
                    if `alpha' == 100 {
                        sum `_xmin' if `_in_exclu' == 0
                        local effi = r(max)
                    }
                    else {
                        _pctile `_xmin' if `_in_exclu' == 0, percentiles(`alpha')
                        sum `_xmin' if `_in_exclu' == 0 & `_xmin' <= r(r1)
                        local effi = r(max)
                    }
                    replace `savee' = (`effi')^`invi' if _n == `ii'
                    ** IDENTIFY REFERENCE DMUs
                    tab `_obsno' if `_in_exclu' == 0 & round(`_xmin',10^-12) == round(`effi',10^-12), matrow(`_refmat')
                    local kmax = rowsof(`_refmat')
                    forvalues kk = 1(1)`kmax' {
                        if `kk' == 1 {
                            local ll = `_refmat'[`kk',1]
                            capture replace `savep' = `varlist'[`ll'] if _n == `ii'
                            if _rc != 0 {
                                gen `savep' = `varlist'[`ll'] if _n == `ii'
                            }
                        }
                        else {
                            local ll = `_refmat'[`kk',1]
                            capture replace `savep'_`kk' = `varlist'[`ll'] if _n == `ii'
                            if _rc != 0 {
                                gen `savep'_`kk' = `varlist'[`ll'] if _n == `ii'
                            }
                        }
                    }
                    ** MAX-NUMBER OF REFERENCE-DMUs
                    if `ii' == 1 {
                        local maxref = `kmax'
                    }
                    else {
                        if `kmax' > `maxref' {
                            local maxref = `kmax'
                        }
                    }
                    ** LOOP-DOTS
                    if `dots' >= 2 {
                        if `ii'/50 == round(`ii'/50) | `ii' == `samps' {
                            noisily: display as text ". `ii'"
                        }
                        else {
                            if `ii' == 1 {
                                noisily: display _newline as text "looping through data:"
                            }
                            noisily: display as text "." _continue
                        }
                    }
                }
            }
            else {
                forvalues ii = 1(1)`samps' {
                    capture drop `_xmax'
                    local jj = 0
                    foreach vv of varlist `inputs' {
                        local jj = 1+ `jj'
                        capture drop `_xi_`jj'' 
                        gen `_xi_`jj'' = `vv'/`vv'[`ii']
                        if `jj' == 1 {
                            local xrli "`_xi_`jj''"
                        }
                        else {
                            local xrli "`xrli', `_xi_`jj''"
                        }
                    }
                    if `jj' == 1 {
                        gen `_xmax' = `xrli'
                    }
                    else {
                        gen `_xmax' = max(`xrli')
                    } 
                    capture drop `_out_exclu'
                    gen `_out_exclu' = 0
                    foreach vv of varlist `outputs' {
                        replace `_out_exclu' = 1 if `vv' < `vv'[`ii']
                    }   
                    if `alpha' == 100 {
                        sum `_xmax' if `_out_exclu' == 0
                        local effi = r(min)
                    }
                    else {
                        _pctile `_xmax' if `_out_exclu' == 0, percentiles(`ialpha')
                        sum  `_xmax' if `_out_exclu' == 0 & `_xmax' >= r(r1)
                        local effi = r(min)
                    }
                    replace `savee' = `effi' if _n == `ii'
                    tab `_obsno' if `_out_exclu' == 0 & round(`_xmax',10^-12) == round(`effi',10^-12), matrow(`_refmat')
                    local kmax = rowsof(`_refmat')
                    forvalues kk = 1(1)`kmax' {
                        if `kk' == 1 {
                            local ll = `_refmat'[`kk',1]
                            capture replace `savep' = `varlist'[`ll'] if _n == `ii'
                            if _rc != 0 {
                                gen `savep' = `varlist'[`ll'] if _n == `ii'
                            }
                        }
                        else {
                            local ll = `_refmat'[`kk',1]
                            capture replace `savep'_`kk' = `varlist'[`ll'] if _n == `ii'
                            if _rc != 0 {
                                gen `savep'_`kk' = `varlist'[`ll'] if _n == `ii'
                            }
                        }
                    }
                    ** MAX-NUMBER OF REFERENCE-DMUs
                    if `ii' == 1 {
                        local maxref = `kmax'
                    }
                    else {
                        if `kmax' > `maxref' {
                            local maxref = `kmax'
                        }
                    }
                    ** LOOP-DOTS
                    if `dots' >= 2 {
                        if `ii'/50 == round(`ii'/50) | `ii' == `samps' {
                            noisily: display as text ". `ii'"
                        }
                        else {
                            if `ii' == 1 {
                                noisily: display _newline as text "looping through data:"
                            }
                            noisily: display as text "." _continue
                        }
                    }
                }
            }
            ** CALCULATE RANKS
            if "`ort'" == "output" & "`invert'" != "invert" {
                gsort +`savee'
            }
            else {
                gsort -`savee'
            }
            capture drop `_effrank'
            gen `_effrank' = _n
            replace `_effrank' = `_effrank'[_n-1] if _n >= 2 &`savee'[_n] == `savee'[_n-1] 
            sort `_tempid'
            replace `saver' = `_effrank'
            
            ** BOOTSTRAPPING
            if `noboot' == 0 & `samps' > 1000 {
                display as error "Warning: boostrapping generates huge matrices, e(V) is `samps' x `samps'"
            }
            if `noboot' == 0 & `samps' > `c(matsize)' {
                display as error "Error: boostrapping generates huge (`samps' x `samps') matrix, matsize too small"
            }
            if `noboot' == 0 & `samps' <= `c(matsize)' {
                capture drop `_bweight'
                gen `_bweight' =.
                forvalues bb = 1(1)`reps2' {
                    local bsamps = int((`samps')^`tune')
                    bsample (`bsamps'), weight(`_bweight')
                    sort `_tempid'
                    forvalues ii = 1(1)`samps' {
                        if "`ort'" == "output" {
                            local jj = 0
                            foreach vv of varlist `outputs' {
                                local jj = 1+ `jj'
                                replace `_xo_`jj'' = `vv'/`vv'[`ii']
                            }
                            if `jj' == 1 {
                                replace `_xmin' = `xrlo'
                            }
                            else {
                                replace `_xmin' = min(`xrlo')
                            }
                            capture drop `_in_exclu'
                            gen `_in_exclu' = 0
                            foreach vv of varlist `inputs' {
                                replace `_in_exclu' = 1 if `vv' > `vv'[`ii']
                            } 
                            count if `_in_exclu' == 0 & `_bweight' >0
                            if r(N) == 0 {
                                local ceffi = 0
                                local effi = 0
                            }
                            else {      
                                local ceffi = 1
                                if `alpha' == 100 {
                                    sum `_xmin' if `_in_exclu' == 0 [fw=`_bweight']
                                    local effi = r(max)
                                }
                                else {
                                    _pctile `_xmin' if `_in_exclu' == 0 [fw=`_bweight'], percentiles(`alpha')
                                    sum `_xmin' if `_in_exclu' == 0 & `_xmin' <= r(r1) [fw=`_bweight']
                                    local effi = r(max)
                                }
                            }
                        }       
                        else {
                            local jj = 0
                            foreach vv of varlist `inputs' {
                                local jj = 1+ `jj'
                                replace `_xi_`jj'' = `vv'/`vv'[`ii']
                            }
                            if `jj' == 1 {
                                replace `_xmax' = `xrli'
                            }
                            else {
                                replace `_xmax' = max(`xrli')
                            }
                            capture drop `_out_exclu'
                            gen `_out_exclu' = 0
                            foreach vv of varlist `outputs' {
                                replace `_out_exclu' = 1 if `vv' < `vv'[`ii']
                            } 
                            count if `_out_exclu' == 0 & `_bweight' >0
                            if r(N) == 0 {
                                local effi = 0
                            }
                            else {
                                local ceffi = 1
                                if `alpha' == 100 {
                                    sum `_xmax' if `_out_exclu' == 0 [fw=`_bweight']
                                    local effi = r(min)
                                    local effi = (`effi')^`invi'
                                }
                                else {
                                    _pctile `_xmax' if `_out_exclu' == 0 [fw=`_bweight'], percentiles(`ialpha')
                                    sum `_xmax' if `_out_exclu' == 0 & `_xmax' >= r(r1) [fw=`_bweight']
                                    local effi = r(min)
                                    local effi = (`effi')^`invi'
                                }
                            }
                        }                   
                        if `ii' == 1 { 
                            matrix `_bbstr' = (`effi')
                        }
                        else {
                            matrix `_bbstr' = (`_bbstr' , `effi')
                        }
                    }
                    if `bb' == 1 {
                        mat `_mbbstr' = `_bbstr'   
                    }
                    else {
                        mat `_mbbstr' = (`_mbbstr' \ `_bbstr')
                    }
                    if `dots' >= 1 {
                        if `bb'/50 == round(`bb'/50) | `bb' == `reps2' {
                            noisily: display as text ". `bb'"
                        }
                        else {
                            if `bb' == 1 {
                                noisily: display _newline as text "bootstrap replications:"
                            }
                            noisily: display as text "." _continue
                        }
                    }
                }
                ** CALCULATE VCE
                mata : bstrvce("`_mbbstr'", "checkbstr", "`_bV'", "`_b_bs'", "`_reps'", "`_se'")
                if "`checkbstr'" != "valid" {
                    display as error "Warning: bootstrap failed for some dmus, increase reps() or tune()"
                }
            }
            ** GENERATE RESULTS
            ** VECTOR OF EFFICIENCY SCORES
            mkmat `savee', matrix(`_oaeffi') nomissing
            matrix colnames `_oaeffi' = score
            matrix rownames `_oaeffi' = `cn'
            matrix `_oaeffi' = `_oaeffi''
            ** VECTOR OF EFFICIENCY RANKS
            mkmat `_effrank', matrix(`_oarank') nomissing
            matrix colnames `_oarank' = rank
            matrix rownames `_oarank' = `cn'
            matrix `_oarank' = `_oarank''
            ** MATRIX OF REFERENCE DMUs
            local refvars "`savep'"
            local cnref "ref1"
            forvalues kk = 2(1)`maxref' {
                local refvars "`refvars' `savep'_`kk'"
                local cnref "`cnref' ref`kk'"
            }
            capture confirm numeric variable `savep'
            if !_rc {
                mkmat `refvars', matrix(`_oarefs')
                matrix colnames `_oarefs' = `cnref'
                matrix rownames `_oarefs' = `cn'
                matrix `_oarefs' = `_oarefs''
            }
            ** SHARE OF EFFICIENT DMUs
            count if `savee' == 1 
            local efficient = r(N)/`samps'
            ** SHARE OF SUPER-EFFICIENT DMUs
            if "`ort'" == "output" & "`invert'" != "invert" {
                count if `savee' >= 0 & `savee' < 1
                local super = r(N)/`samps'
            }
            else {
                count if `savee' > 1 & `savee' <.
                local super = r(N)/`samps'
            }
            ** MEAN and MED EFFICIENCY
            sum `savee', detail
            local mean_e = r(mean)
            local med_e = r(p50)
            ** EXTRACTING BOOTSTRP RESULTS
            if "`checkbstr'" == "valid" & `noboot' == 0 & `samps' <= `c(matsize)' {
                mat `_bias' =  `_oaeffi'- `_b_bs'
                matrix rownames `_bias' = bias
                matrix colnames `_bias' = `cn'
                matrix rownames `_reps' = reps
                matrix colnames `_reps' = `cn'
                matrix rownames `_bV' = `cn'
                matrix colnames `_bV' = `cn'
                matrix colnames `_b_bs' = `cn'
                matrix rownames `_se' = `cn'
            }
            ** GENERATE TEMP-VARIABLES FOR RESULT-TABLES
            if "`table'" == "full" {
                gen `_tab_dmu' = `varlist'
                gen `_tab_eff' = `savee'
                if "`checkbstr'" == "valid" & `noboot' == 0 & `samps' <= `c(matsize)' { 
                    local tmpn "`_tab_se'"
                    mat colnames `_se' = `tmpn'
                    svmat `_se', names(col)
                    replace `_tab_se'=. if `_tab_se' == 0
                }
                else {
                    gen `_tab_se' =.
                }
                gen `_tab_z' = abs(`_tab_eff'-1)/`_tab_se'
                gen `_tab_rank' = `saver'
                gen `_tab_ref' = `savep'
                ** LABELS TO BE DISPLAIED IN THE RESULTS TABLE
				if "`dmu'" == "" {
					label var `_tab_dmu' "dmu (obs. no.)"
				}
				else {
					label var `_tab_dmu' "dmu (`varlist')"
				}
                label var `_tab_eff' "Eff. Score"
                label var `_tab_se' "Std. Err."
                label var `_tab_z' "z Stat."
                label var `_tab_rank' "Eff. Rank"
                label var `_tab_ref' "Ref. DMU"
            }
            ** MERGE RESULTS WITH ORIGINAL DATA
            capture drop `_esamp'
            gen `_esamp' = 1
            if "`nogenerate'" == "nogenerate" {
                if "`table'" == "full" {
                    keep  `_tempid' `_esamp' `_tab_dmu' `_tab_eff' `_tab_se' `_tab_z' `_tab_rank' `_tab_ref'
                }
                else {
                    keep  `_tempid' `_esamp'
                }
            }
            else {
                if "`table'" == "full" {
                    keep  `_tempid' `savee' `saver' `savep'* `_esamp' `_tab_dmu' `_tab_eff' `_tab_se' `_tab_z' `_tab_rank' `_tab_ref'
                }
                else {
                    keep  `_tempid' `savee' `saver' `savep'* `_esamp'
                }
            }
            save `resufile', replace
            restore
            merge 1:1 `_tempid' using `resufile', nogenerate update replace force
            replace `_esamp' = 0 if `_esamp' != 1
            ** POSTING RESULTS
            if "`checkbstr'" == "valid" & `noboot' == 0 & `samps' <= `c(matsize)' { 
                ereturn clear
				ereturn post `_oaeffi' `_bV', depname(dmu) obs(`samps') esample(`_esamp') properties(b V)
                capture confirm numeric variable `varlist'
                if !_rc {
                    ereturn matrix reference = `_oarefs'
                }
                ereturn matrix ranks = `_oarank' 
            }
            else {
                ereturn post `_oaeffi', depname(dmu) obs(`samps') esample(`_esamp') properties(b)
                capture confirm numeric variable `varlist'
                if !_rc {
                    ereturn matrix reference = `_oarefs'
                }
                ereturn matrix ranks = `_oarank' 
            }
            ereturn scalar N = `samps'
            ereturn scalar alpha = `alpha'
            ereturn scalar inputs = `nin'
            ereturn scalar outputs = `nout'
            ereturn scalar efficient = `efficient'
            ereturn scalar super = `super'
            ereturn scalar mean_e = `mean_e'
            ereturn scalar med_e = `med_e'
			ereturn local inputlist "`inputs'"
			ereturn local outputlist "`outputs'"
            if "`ort'" == "output" {
                ereturn local ort "output"
            }
            else {
                ereturn local ort "input"
            }
            if "`ort'" == "output" & "`invert'" == "invert" {
                ereturn local invert "inverted"
            }
            if "`ort'" == "output" & "`invert'" != "invert" {
                ereturn local invert "notinverted"
            }
            if "`checkbstr'" == "valid" & `noboot' == 0 & `samps' <= `c(matsize)' {
                ereturn local vcetype "Bootstrap"
                ereturn local vce "bootstrap"
                ereturn matrix  b_bs = `_b_bs'
                ereturn matrix  reps = `_reps'
                ereturn matrix  bias = `_bias'
                ereturn scalar  N_reps = `reps2'
                ereturn scalar  tune = `tune'
                ereturn scalar  N_bs = `bsamps'
            }
            ereturn scalar  level = `level'
            ereturn local table "`table'"
            if "`nogenerate'" == "nogenerate" {
                ereturn local saved ""
            }
            else {
                ereturn local saved "`savee' `saver' `refvars'"
            }
            if `alpha' == 100 {
                ereturn local model "Free Disposal Hull"
            }
            else {
                ereturn local model "Order-alpha"
            }
			if "`dmu'" == "" {
				ereturn local dmuid "obs. no."
				}
			else {
				ereturn local dmuid "`varlist'"
			}
            ereturn local title "Order-alpha efficiency analysis"
            ereturn local cmdline `cmdline'
            ereturn local cmd `cmd'
            ** LABELING SAVED VARIABLES 
            if "`nogenerate'" != "nogenerate" {
                local sve : word 1 of `e(saved)'
                local svr : word 2 of `e(saved)'
                forvalues kk = 1(1)`maxref' {
					local kk2 = 2+`kk'
                    local svp_`kk' : word `kk2' of `e(saved)'
                    if `maxref' > 1 {
                        local dno_`kk' " # `kk'"
                    }
                    else {
                        local dno_`kk' ""
                    }
                }
                if `alpha' == 100 {
                    label variable `sve' "FDH `e(ort)'-oriented efficiency"
                    label variable `svr' "efficiency rank (FDH `e(ort)'-oriented)"
                    forvalues kk = 1(1)`maxref' {
                        capture label variable `svp_`kk'' "reference dmu`dno_`kk'' (FDH `e(ort)'-oriented)"
                    }
                }
                else {
                    if int(`e(alpha)') == `e(alpha)' {
                        label variable `sve' "order-alpha(`e(alpha)') `e(ort)'-oriented efficiency"
                        label variable `svr' "efficiency rank (order-alpha(`e(alpha)') `e(ort)'-oriented)"
                        forvalues kk = 1(1)`maxref' {
                            capture label variable `svp_`kk'' "reference dmu`dno_`kk'' (order-alpha(`e(alpha)') `e(ort)'-oriented)"
                        }
                    }
                    else {
                        label variable `sve' "order-alpha(`r2alpha') `e(ort)'-oriented efficiency"
                        label variable `svr' "efficiency rank (order-alpha(`r2alpha') `e(ort)'-oriented)"
                        forvalues kk = 1(1)`maxref' {
                            capture label variable `svp_`kk'' "reference dmu`dno_`kk'' (order-alpha(`r2alpha') `e(ort)'-oriented)"
                        }
                    }
                }
            }
        }
    set more `moreold'
	sort `_orgord' 
    }
    else {
        if "`e(cmd)'" != "orderalpha" error 301
        syntax [, LEVel(real `e(level)')]
    }
    ** DISPLAY RESULTS
    if "`e(saved)'" == "" {
        local vardisp "no variable saved"
    }
    else {
        local dispsco : word 1 of `e(saved)'
        local vardisp "variable " as result "`dispsco'" as text ""
    }
    if "`e(ort)'" == "output" & "`e(invert)'" == "inverted" {
        local noteinv "inverted "
    }
    else {
        local noteinv ""
    }
    local notenose1 "Note: no bootstrapping; no VCE, SEs, and confidence intervals computed"
    local notenose2 "Note: no bootstrapping; no standard errors computed"
    local notez "Note: z-Statistic is abs(Eff.Score - 1)/Std.Err."
	if "`dmu'" == "" {
		local tabscore "_coef_table, coeftitle(Eff. Score) level(`level')"/* neq(1)"*/
	}
	else {
		local tabscore "_coef_table, coeftitle(Eff. Score) level(`level') neq(1)"
	}
    local tabfull "tabdisp `_tab_dmu' if e(sample), cellvar(`_tab_eff' `_tab_se' `_tab_z' `_tab_rank' `_tab_ref') cellwidth(10) stubwidth(15) missing"

    if "`e(ort)'" == "output" {
        if `e(alpha)' == 100 {
            display _newline as text "FDH `noteinv'output-oriented efficiency scores estimated (`vardisp')"
            display _newline as text "Number of dmus" _skip(16) as text " = " as result `e(N)'
            display as text "Number of inputs" _skip(14) as text " = " as result `e(inputs)'
            display as text "Number of outputs" _skip(13) as text " = " as result `e(outputs)' 
            display as text "Mean efficiency" _skip(15) as text " = " as result %-06.4g `e(mean_e)' 
            display as text "Median efficiency" _skip(13) as text " = " as result %-06.4g `e(med_e)'
            display as text "Share of efficient dmus" _skip(7) as text " = " as result %-06.4g `e(efficient)'
            if "`e(table)'" == "scores" {
                display
                `tabscore'  
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose1'"
                }
            }
            if "`e(table)'" == "full" & !replay() {
                `tabfull'
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose2'"
                }
                else {
                    display as text "`notez'"
                }
            }
        }
        else {
            if int(`e(alpha)') == `e(alpha)' {
                display _newline as text "Order-alpha(" as result"`e(alpha)'" as text") `noteinv'output-oriented efficiency scores estimated (`vardisp')"
            }
            else {
                display _newline as text "Order-alpha("as result %-05.2f `e(alpha)' as text") `noteinv'output-oriented efficiency scores estimated (`vardisp')"
            }
            display _newline as text "Number of dmus" _skip(16) as text " = " as result `e(N)'
            display as text "Number of inputs" _skip(14) as text " = " as result `e(inputs)'
            display as text "Number of outputs" _skip(13) as text " = " as result `e(outputs)' 
            display as text "Mean efficiency" _skip(15) as text " = " as result %-06.4g `e(mean_e)' 
            display as text "Median efficiency" _skip(13) as text " = " as result %-06.4g `e(med_e)'
            display as text "Share of efficient dmus" _skip(7) as text " = " as result %-06.4g `e(efficient)'
            display as text "Share of super-efficient dmus" _skip(1) as text " = " as result %-06.4g `e(super)'
            if "`e(table)'" == "scores" {
                display
                `tabscore'  
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose1'"
                }
            }
            if "`e(table)'" == "full" & !replay() {
                `tabfull'   
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose2'"
                }
                else {
                    display as text "`notez'"
                }
            }
        }
    }
    else {
        if `e(alpha)' == 100 {
            display _newline as text "FDH input-oriented efficiency scores estimated (`vardisp')"
            display _newline as text "Number of dmus" _skip(16) as text " = " as result `e(N)'
            display as text "Number of inputs" _skip(14) as text " = " as result `e(inputs)'
            display as text "Number of outputs" _skip(13) as text " = " as result `e(outputs)' 
            display as text "Mean efficiency" _skip(15) as text " = " as result %-06.4g `e(mean_e)' 
            display as text "Median efficiency" _skip(13) as text " = " as result %-06.4g `e(med_e)'
            display as text "Share of efficient dmus" _skip(7) as text " = " as result %-06.4g `e(efficient)'
            if "`e(table)'" == "scores" {
                display
                `tabscore'  
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose1'"
                }
            }
            if "`e(table)'" == "full" & !replay() {
                `tabfull'   
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose2'"
                }
                else {
                    display as text "`notez'"
                }
            }
        }
        else {
            if int(`e(alpha)') == `e(alpha)' {
                display _newline as text "Order-alpha(" as result"`e(alpha)'" as text") input-oriented efficiency scores estimated (`vardisp')"
            }
            else {
                display _newline as text "Order-alpha("as result %-05.2f `e(alpha)' as text") input-oriented efficiency scores estimated (`vardisp')"
            }
            display _newline as text "Number of dmus" _skip(16) as text " = " as result `e(N)'
            display as text "Number of inputs" _skip(14) as text " = " as result `e(inputs)'
            display as text "Number of outputs" _skip(13) as text " = " as result `e(outputs)' 
            display as text "Mean efficiency" _skip(15) as text " = " as result %-06.4g `e(mean_e)' 
            display as text "Median efficiency" _skip(13) as text " = " as result %-06.4g `e(med_e)'
            display as text "Share of efficient dmus" _skip(7) as text " = " as result %-06.4g `e(efficient)'
            display as text "Share of super-efficient dmus" _skip(1) as text " = " as result %-06.4g `e(super)' 
            if "`e(table)'" == "scores" {
                display
                `tabscore'  
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose1'"
                }
            }
            if "`e(table)'" == "full" & !replay() {
                `tabfull'   
                if "`e(vce)'" != "bootstrap" { 
                    display as text "`notenose2'"
                }
                else {
                    display as text "`notez'"
                }
            }
        }
    }
end
** MATA DEFINITION AREA ----------------------------------------
version 11
mata:
void dmumatname(string scalar dmu, string scalar empty)
{
    __STR_DMU = st_sdata(.,(dmu))
    __STR_DMU2 =(__STR_DMU,__STR_DMU)
    st_matrixrowstripe(empty, __STR_DMU2)
}
end

version 11
mata:
void bstrvce(string scalar stataBB, string scalar check, string scalar bV, string scalar bbs, string scalar reps, string scalar see)
{
    BB = st_matrix(stataBB)
    II = editmissing(BB :/ BB, 0)
    CSQ_DMU = II'*II
    validvce_DMU = min(CSQ_DMU)
    st_local(check, "invalid")
    if (validvce_DMU > 1) {
        st_local(check, "valid")
        NB_DMU = colsum(II)
        EB_DMU = colsum(BB) :/ NB_DMU
        MD_DMU = BB - J(rows(BB),1,1)*EB_DMU :* II
        CCSQ_DMU = CSQ_DMU - J(rows(CSQ_DMU),cols(CSQ_DMU),1)
        VCE_DMU = (MD_DMU'*MD_DMU) :/ CCSQ_DMU
        SE_DMU = (diagonal(VCE_DMU)) :^0.5
        st_matrix(bV, VCE_DMU)
        st_matrix(bbs, EB_DMU)
        st_matrix(reps, NB_DMU)
        st_matrix(see, SE_DMU)
    }
}
end
** END OF MATA DEFINITION AREA -----------------------------------
exit 0
