/* sampncti.ado                                                 (SJ4-2: st0062)
   version 2.1 dah 30dec2003
   Sample size/power calculation using a noncentral t distribution
   Requires package nct
*/
program define sampncti, rclass
    version 8.0
    local dalpha = 1 - $S_level/100
	syntax anything(id="arguments"), SD1(real) [sd2(real 0) N1(integer 0) n2(integer 0) /*
		*/ Ratio(real 1) Power(real .9) Alpha(real `dalpha') ONESAMple ONESIDed Welch]
    tokenize `anything'
    if "`3'"!="" {
        disp as error "too many arguments specified"
        exit 198
    }
    if "`2'"=="" {
        confirm number `1'
        local delta `1'
        local method "delta"
    }
    else {
        confirm number `1'
        local m1 `1'
        confirm number `2'
        local m2 `2'
        local delta=abs(`m1'-`m2')
        local method "means"
    }
	if `alpha'<=0 | `alpha'>=1 {
		di as error "alpha() out of range"
		exit 198
	}

	if `power'<=0 | `power'>=1 {
		di as error "power() out of range"
		exit 198
	}
	if `sd1'<0 | `sd2'<0 {
		di as error "sd() out of range"
		exit 198
	}
	if `ratio'<=0 {
		di as error "ratio() out of range"
		exit 198
	}
	if `n1'<0 | `n2'<0 {
		di as error "n() out of range"
		exit 198
	}
    if "`onesided'"!="" {
        local alph=`alpha'
        local nsid "one"
    }
    else {
        local alph=`alpha'/2
        local nsid "two"
    }
    if "`onesample'"=="" { /*two-sample*/
	    if `sd2'==0 {
    	    local sd2 `sd1'
    	}
	    if `n1'>0|`n2'>0 { /*calculate power*/
	        if `n2'==0 {
	            local n2=round(`ratio'*`n1')
	        }
	        else if `n1'==0 {
	            local n1=round(`n2'/`ratio')
	        }
	        else {
	            local ratio=`n2'/`n1'
	        }
	        qui {
				if `sd1'==`sd2' {
		            local df=`n1'+`n2'-2
                }
                else if "`welch'"=="" {
                    local df=(((`sd1'^2)/`n1'+(`sd2'^2)/`n2')^2)/ /*
                    */ ((((`sd1'^2)/`n1')^2)/(`n1'-1)+(((`sd2'^2)/`n2')^2)/(`n2'-1))
                }
                else {
                    local df=(((`sd1'^2)/`n1'+(`sd2'^2)/`n2')^2)/ /*
                    */ ((((`sd1'^2)/`n1')^2)/(`n1'+1)+(((`sd2'^2)/`n2')^2)/(`n2'+1))-2
                }
                local dfr=round(`df')
	            nct2 invttail(`df',`alph') `delta'/sqrt((`sd1'^2)/`n1'+(`sd2'^2)/`n2') `dfr'
	            local rpow=r(p)
	        }
			disp _n as text "Estimated power from noncentral t-distribution for" _n /*
			*/ "  two-sample comparison of means"
			if "`method'"=="delta" {
				disp _n as text "Test Ho: delta = 0, where delta is the difference in means" _n /*
				*/ _col(23) "between the two arms"
	        }
	        else {
	        	disp _n as text "Test Ho: m1 = m2, where m1 is the mean in population 1" _n /*
	            */ _col(21) "and m2 is the mean in population 2"
	        }
	        disp _n as text "Assumptions:" _n(2) /*
			*/ _col(10) "alpha = " as result %8.4f `alpha' as text "  (`nsid'-sided)"
	        if "`method'"=="delta" {
	        	disp as text _col(10) "delta = " as result %8.0g `delta'
	        }
	        else {
	            disp as text _col(13) "m1 = " as result %8.0g `m1' _n /*
	            */ as text _col(13) "m2 = " as result %8.0g `m2'
	        }
			disp as text _col(12) "sd1 = " as result %8.0g `sd1' _n /*
			*/ as text _col(12) "sd2 = " as result %8.0g `sd2' _n /*
			*/ as text "sample size n1 = " as result %8.0g `n1' _n /*
			*/ as text _col(13) "n2 = " as result %8.0g `n2' _n /*
			*/ as text _col(10) "n2/n1 = " as result %8.2f `ratio'
            if `sd1'!=`sd2' {
                if "`welch'"=="" {
                    disp _n as text "Satterthwaite's degrees of freedom: " as result %9.4f `df'
                }
                else {
                    disp _n as text "Welch's degrees of freedom: " as result %9.4f `df'
                }
            }
			disp _n as text "Estimated power:" /*
			*/ _n(2) _col(10) "power = " as result %8.4f `rpow'
	        local power `rpow'
	    }
	    else { /*calculate sample size*/
	        qui {
	            sampsi `delta' 0, sd1(`sd1') sd2(`sd2') p(`power') a(`alpha') r(`ratio') `onesided'
	            local n1t=r(N_1)
	            local n2t=r(N_2)
                if `n1t'==1 & `n2t'==1 {
                    local n1t 2
                    local n2t=max(round(`ratio'*`n1t'),1)
                }
                if `sd1'==`sd2' {
		            local dft=`n1t'+`n2t'-2
                }
                else if "`welch'"=="" {
                    local dft=(((`sd1'^2)/`n1t'+(`sd2'^2)/`n2t')^2)/ /*
                    */ ((((`sd1'^2)/`n1t')^2)/(`n1t'-1)+(((`sd2'^2)/`n2t')^2)/(`n2t'-1))
                }
                else {
                    local dft=(((`sd1'^2)/`n1t'+(`sd2'^2)/`n2t')^2)/ /*
                    */ ((((`sd1'^2)/`n1t')^2)/(`n1t'+1)+(((`sd2'^2)/`n2t')^2)/(`n2t'+1))-2
                }
                local dfr=round(`dft')
	            nct2 invttail(`dft',`alph') `delta'/sqrt((`sd1'^2)/`n1t'+(`sd2'^2)/`n2t') `dfr'
	            local pt=r(p)
				while `pt'<`power' {
	                local n1t=`n1t'+1
	                local n2t=max(round(`ratio'*`n1t'),1)
	                if `sd1'==`sd2' {
			            local dft=`n1t'+`n2t'-2
        	        }
            	    else if "`welch'"=="" {
                	    local dft=(((`sd1'^2)/`n1t'+(`sd2'^2)/`n2t')^2)/ /*
                    	*/ ((((`sd1'^2)/`n1t')^2)/(`n1t'-1)+(((`sd2'^2)/`n2t')^2)/(`n2t'-1))
                	}
                	else {
                	    local dft=(((`sd1'^2)/`n1t'+(`sd2'^2)/`n2t')^2)/ /*
                	    */ ((((`sd1'^2)/`n1t')^2)/(`n1t'+1)+(((`sd2'^2)/`n2t')^2)/(`n2t'+1))-2
                	}
                    local dfr=round(`dft')
		            nct2 invttail(`dft',`alph') `delta'/sqrt((`sd1'^2)/`n1t'+(`sd2'^2)/`n2t') `dfr'
	            	local pt=r(p)
	            }
	        }
			di _n as text "Estimated sample size from noncentral t-distribution for" _n /*
			*/ "  two-sample comparison of means"
			if "`method'"=="delta" {
				disp _n as text "Test Ho: delta = 0, where delta is the difference in means" _n /*
				*/ _col(23) "between the two arms"
	        }
	        else {
	        	disp _n as text "Test Ho: m1 = m2, where m1 is the mean in population 1" _n /*
	            */ _col(21) "and m2 is the mean in population 2"
	        }
			disp _n as text "Assumptions:" _n(2) /*
			*/ _col(10) "alpha = " as result %8.4f `alpha' as text "  (`nsid'-sided)" _n /*
			*/ _col(10) "power = " as result %8.4f `power'
	        if "`method'"=="delta" {
	        	disp as text _col(10) "delta = " as result %8.0g `delta'
	        }
	        else {
	            disp as text _col(13) "m1 = " as result %8.0g `m1' _n /*
	            */ as text _col(13) "m2 = " as result %8.0g `m2'
	        }
			disp as text _col(12) "sd1 = " as result %8.0g `sd1' _n /*
			*/ as text _col(12) "sd2 = " as result %8.0g `sd2' _n /*
			*/ as text _col(10) "n2/n1 = " as result %8.2f `ratio'
            if `sd1'!=`sd2' {
                if "`welch'"=="" {
                    disp _n as text "Satterthwaite's degrees of freedom: " as result %9.4f `dft'
                }
                else {
                    disp _n as text "Welch's degrees of freedom: " as result %9.4f `dft'
                }
            }
			disp _n as text "Estimated required sample size:" /*
			*/ _n(2) _col(13) "n1 = " as result %8.0f `n1t' _n /*
			*/ as text _col(13) "n2 = " as result %8.0f `n2t'
	        local n1 `n1t'
	        local n2 `n2t'
            local df `dft'
	    }
    }
    else { /*one-sample*/
        local df=`n1'-1
		if `sd2'>0 {
			di as error "for one-sample comparison of mean, only one sd(#) can be specified"
			exit 499
		}
	    if `n1'>0|`n2'>0 { /*calculate power*/
			if `n1'>0&`n2'>0 {
				di as error "for one-sample comparison of mean, only one n(#) can be specified"
				exit 499
			}
	        if `n1'==0 {
                local n1 `n2'
                local n2 0
	        }
	        qui {
	            local df=`n1'-1
	            nct2 invttail(`df',`alph') `delta'*sqrt(`n1')/`sd1' `df'
	            local rpow=r(p)
	        }
			disp _n as text "Estimated power from noncentral t-distribution for" _n /*
			*/ "  one-sample comparison of mean to hypothesized value"
			if "`method'"=="delta" {
				disp _n as text "Test Ho: delta = 0, where delta is the deviation from the" _n /*
				*/ _col(23) "hypothesized value"
	        }
	        else {
	        	disp _n as text "Test Ho: m = " as result %6.0g `m1' as text ", where m is the mean in the population"
	        }
	        disp _n as text "Assumptions:" _n(2) /*
			*/ _col(10) "alpha = " as result %8.4f `alpha' as text "  (`nsid'-sided)"
	        if "`method'"=="delta" {
	        	disp as text _col(10) "delta = " as result %8.0g `delta'
	        }
	        else {
	            disp as text " alternative m = " as result %8.0g `m2'
	        }
			disp as text _col(13) "sd = " as result %8.0g `sd1' _n /*
			*/ as text " sample size n = " as result %8.0g `n1' /*
			*/ _n(2) as text "Estimated power:" /*
			*/ _n(2) _col(10) "power = " as result %8.4f `rpow'
	        local power `rpow'
	    }
	    else { /*calculate sample size*/
	        qui {
	            sampsi `delta' 0, sd1(`sd1') p(`power') a(`alpha') `onesided' onesample
	            local nt=r(N_1)
	            local dft=`nt'-1
	            nct2 invttail(`dft',`alph') `delta'*sqrt(`nt')/`sd1' `dft'
	            local pt=r(p)
				while `pt'<`power' {
	                local nt=`nt'+1
	    	        local dft=`nt'-1
		            nct2 invttail(`dft',`alph') `delta'*sqrt(`nt')/`sd1' `dft'
	            	local pt=r(p)
	            }
	        }
			di _n as text "Estimated sample size from noncentral t-distribution for" _n /*
			*/ "  one-sample comparison of mean to hypothesized value"
			if "`method'"=="delta" {
				disp _n as text "Test Ho: delta = 0, where delta is the deviation from the" _n /*
				*/ _col(23) "hypothesized value"
	        }
	        else {
	        	disp _n as text "Test Ho: m = " as result %6.0g `m1' as text ", where m is the mean in the population"
	        }
			disp _n as text "Assumptions:" _n(2) /*
			*/ _col(10) "alpha = " as result %8.4f `alpha' as text "  (`nsid'-sided)" _n /*
			*/ _col(10) "power = " as result %8.4f `power'
	        if "`method'"=="delta" {
	        	disp as text _col(10) "delta = " as result %8.0g `delta'
	        }
	        else {
	            disp as text " alternative m = " as result %8.0g `m2'
	        }
			disp as text _col(13) "sd = " as result %8.0g `sd1' /*
			*/ _n(2) as text "Estimated required sample size:" /*
			*/ _n(2) _col(14) "n = " as result %8.0f `nt'
	        local n1 `nt'
	        local n2 0
            local df `dft'
	    }
    }
    return scalar df_t=`df'
	return scalar power=`power'
    return scalar N_2=`n2'
    return scalar N_1=`n1'
end
