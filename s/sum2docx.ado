program define sum2docx

	version 15.0 //使用putdocx，只能在Stata15中使用
	
	syntax varlist(numeric) [if] [in] using/, [append replace title(string) obs ///
	mean MEANfmt(string) var VARfmt(string) sd SDfmt(string) skewness ///
	SKEWNESSfmt(string) kurtosis KURTOSISfmt(string) sum SUMfmt(string) min ///
	MINfmt(string) max MAXfmt(string) p1 P1fmt(string) p5 P5fmt(string) p10 ///
	P10fmt(string) p25 P25fmt(string) median MEDIANfmt(string) p75 P75fmt(string) ///
	p90 P90fmt(string) p95 P95fmt(string) p99 P99fmt(string)]

	if "`append'" != "" & "`replace'" != "" { //append和replace不能同时定义
		disp as error "you could not specify both append and replace"
		exit 198
	}
	
	tempfile postsum
	
	local varlen = 0
	foreach var of varlist `varlist' {
		if length(`"`var'"') > `varlen' local varlen = length(`"`var'"')
	}
	
	local postvar "str`varlen' VarName "
	local num = 1
	
	if "`obs'" != "" {
		local postvar "`postvar'Obs " //如果输出样本量，添加Obs
		local postcontent `"`postcontent'(r(N)) "'
		local num = `num' + 1
	}
	
	local postvar = "`postvar'Mean " //输出均值的名称
	local postcontent `"`postcontent'(r(mean)) "'
	local num = `num' + 1
	if "`meanfmt'" == "" local meanfmt %9.3f //默认的均值格式为%9.3f
	
	if "`var'" != "" | "`varfmt'" != "" { //输出方差
		local postvar = "`postvar'Variance "
		local postcontent `"`postcontent'(r(Var)) "'
		local num = `num' + 1
		if "`varfmt'" == "" local varfmt `meanfmt' //如果不定义方差的格式，默认为均值的格式
	}
	
	if "`sd'" != "" | "`sdfmt'" != "" {
		local postvar = "`postvar'SD "
		local postcontent `"`postcontent'(r(sd)) "'
		local num = `num' + 1
		if "`sdfmt'" == "" local sdfmt `meanfmt'
	}
	
	if "`skewness'" != "" | "`skewnessfmt'" != "" {
		local postvar = "`postvar'Skewness "
		local postcontent `"`postcontent'(r(skewness)) "'
		local num = `num' + 1
		if "`skewnessfmt'" == "" local skewnessfmt `meanfmt'
	}
	
	if "`kurtosis'" != "" | "`kurtosisfmt'" != "" {
		local postvar = "`postvar'Kurtosis "
		local postcontent `"`postcontent'(r(kurtosis)) "'
		local num = `num' + 1
		if "`kurtosisfmt'" == "" local kurtosisfmt `meanfmt'
	}
	
	if "`sum'" != "" | "`sumfmt'" != "" {
		local postvar = "`postvar'Sum "
		local postcontent `"`postcontent'(r(sum)) "'
		local num = `num' + 1
		if "`sumfmt'" == "" local sumfmt `meanfmt'
	}
	
	if "`min'" != "" | "`minfmt'" != "" {
		local postvar = "`postvar'Min "
		local postcontent `"`postcontent'(r(min)) "'
		local num = `num' + 1
		if "`minfmt'" == "" local minfmt `meanfmt'
	}
	
	if "`median'" != "" | "`medianfmt'" != "" {
		local postvar = "`postvar'Median "
		local postcontent `"`postcontent'(r(p50)) "'
		local num = `num' + 1
		if "`medianfmt'" == "" local medianfmt `meanfmt'
	}
	
	if "`max'" != "" | "`maxfmt'" != "" {
		local postvar = "`postvar'Max "
		local postcontent `"`postcontent'(r(max)) "'
		local num = `num' + 1
		if "`maxfmt'" == "" local maxfmt `meanfmt'
	}
	
	if "`p1'" != "" | "`p1fmt'" != "" {
		local postvar = "`postvar'P1 "
		local postcontent `"`postcontent'(r(p1)) "'
		local num = `num' + 1
		if "`p1fmt'" == "" local p1fmt `meanfmt'
	}
	
	if "`p5'" != "" | "`p5fmt'" != "" {
		local postvar = "`postvar'P5 "
		local postcontent `"`postcontent'(r(p5)) "'
		local num = `num' + 1
		if "`p5fmt'" == "" local p5fmt `meanfmt'
	}
	
	if "`p10'" != "" | "`p10fmt'" != "" {
		local postvar = "`postvar'P10 "
		local postcontent `"`postcontent'(r(p10)) "'
		local num = `num' + 1
		if "`p10fmt'" == "" local p10fmt `meanfmt'
	}
	
	if "`p25'" != "" | "`p25fmt'" != "" {
		local postvar = "`postvar'P25 "
		local postcontent `"`postcontent'(r(p25)) "'
		local num = `num' + 1
		if "`p25fmt'" == "" local p25fmt `meanfmt'
	}
	
	if "`p75'" != "" | "`p75fmt'" != "" {
		local postvar = "`postvar'P75 "
		local postcontent `"`postcontent'(r(p75)) "'
		local num = `num' + 1
		if "`p75fmt'" == "" local p75fmt `meanfmt'
	}
	
	if "`p90'" != "" | "`p90fmt'" != "" {
		local postvar = "`postvar'P90 "
		local postcontent `"`postcontent'(r(p90)) "'
		local num = `num' + 1
		if "`p90fmt'" == "" local p90fmt `meanfmt'
	}
	
	if "`p95'" != "" | "`p95fmt'" != "" {
		local postvar = "`postvar'P95 "
		local postcontent `"`postcontent'(r(p95)) "'
		local num = `num' + 1
		if "`p95fmt'" == "" local p95fmt `meanfmt'
	}
	
	if "`p99'" != "" | "`p99fmt'" != "" {
		local postvar = "`postvar'P99 "
		local postcontent `"`postcontent'(r(p99)) "'
		local num = `num' + 1
		if "`p99fmt'" == "" local p99fmt `meanfmt'
	}
	
	qui {
		cap postclose post_sum
		
		postfile post_sum `postvar' using `postsum.dta', replace
		
		foreach var of varlist `varlist' {
			sum `var' `if' `in', d
			post post_sum ("`var'") `postcontent'
		}
		
		postclose post_sum
		
		preserve
		use `postsum.dta', clear
		local row = _N + 1
		format `meanfmt' Mean
		if "`var'" != "" | "`varfmt'" != "" format `varfmt' Variance
		if "`sd'" != "" | "`sdfmt'" != "" format `sdfmt' SD
		if "`skewness'" != "" | "`skewnessfmt'" != "" format `skewnessfmt' Skewness
		if "`kurtosis'" != "" | "`kurtosisfmt'" != "" format `kurtosisfmt' Kurtosis
		if "`sum'" != "" | "`sumfmt'" != "" format `sumfmt' Sum
		if "`min'" != "" | "`minfmt'" != "" format `minfmt' Min
		if "`max'" != "" | "`maxfmt'" != "" format `maxfmt' Max
		if "`p1'" != "" | "`p1fmt'" != "" format `p1fmt' P1
		if "`p5'" != "" | "`p5fmt'" != "" format `p5fmt' P5
		if "`p10'" != "" | "`p10fmt'" != "" format `p10fmt' P10
		if "`p25'" != "" | "`p25fmt'" != "" format `p25fmt' P25
		if "`median'" != "" | "`medianfmt'" != "" format `medianfmt' Median
		if "`p75'" != "" | "`p75fmt'" != "" format `p75fmt' P75
		if "`p90'" != "" | "`p90fmt'" != "" format `p90fmt' P90
		if "`p95'" != "" | "`p95fmt'" != "" format `p95fmt' P95
		if "`p99'" != "" | "`p99fmt'" != "" format `p99fmt' P99
		compress
		putdocx begin
		if `"`title'"' != "" {
			putdocx paragraph, spacing(after, 0)
			putdocx text (`"`title'"')
		}
		putdocx table sumtable = data("_all"), varnames border(all, nil) border(bottom) border(top)
		putdocx table sumtable(1,1), border(bottom)
		forvalues i = 2/`num' {
			putdocx table sumtable(1,`i'), border(bottom)
			forvalues j = 1/`row' {
				putdocx table sumtable(`j',`i'), halign(right)
			}
		}
		if "`replace'" == "" & "`append'" == "" { //如果既没有replace也没有append，直接save
			putdocx save `using'
		}
		else {
			putdocx save `using', `replace'`append'
		}
		restore
	}

end
