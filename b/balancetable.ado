* Date: 15/09/2016
* Written by: Mattia Chiapello
* Update 09/06/2017: added 'covariates' option
* Update 09/06/2017: made possible to export to Excel files (and not only LaTeX files)
* Update 03/07/2017: corrected 'varname' and 'varlabel' options and added 'wrap' with sub-options
* Update 03/11/2017: v4.0: added all the 'balancetable_complex' subroutine, allowing for more than two treatment arms;
*						   added marksample touse to run the command on subsamples;
*						   removed additional line with "Mean", "Mean" and "Difference" from 'balancetable_simple'

*! version 4.0  03nov2017  Mattia Chiapello

cap program drop balancetable
program define balancetable
	version 14.0
	gettoken main_arg all_options: 0, parse(, )

	if strpos("`main_arg'", "(")==0 {
		balancetable_simple `main_arg' `all_options'
	}
	else if strpos("`main_arg'", "(")==1 {
		balancetable_complex `main_arg' `all_options'
	}
	else {
		dis as error "Error: parenthesized rules should be placed at the beginning"
		error 197
	}
end


cap program drop balancetable_simple
program define balancetable_simple
	version 14.0
	syntax varlist(min=2) using/ [if] [in], ///
		[vce(passthru)] [FE(varname)] [COVariates(varlist fv ts)] ///
		[stddiff] ///
		[ctitles(string asis)] [leftctitle(string)] ///
		[PVALues] [VARLAbels] [VARNAmes] [wrap WRAPsubopt(string)] ///
		[NONUMbers] [NOOBServations] [observationscolumn] [format(passthru)] ///
		[VARWIdth(numlist integer max=1)]  [tabulary] [BOOKTabs] ///
		[prehead(string asis)] [posthead(string asis)] [prefoot(string asis)] [postfoot(string asis)] ///
		[REPLACE]

	* Process syntax
	marksample touse, novarlist strok
	gettoken mainvar depvarlist: varlist
	tokenize `"`ctitles'"'
	* Check presence of 'listtab' command
	cap which listtab
	if _rc ssc install listtab
	* Check correct extension of filename
	if ustrright("`using'",4) == ".tex" local filetype = "latex"
	else if ustrright("`using'",4) == ".xls" | ustrright("`using'",5) == ".xlsx" local filetype = "excel"
	else {
		dis as error "Error: the filename must have extesions .tex, .xls or .xlsx"
		exit
	}
	* Check correct values of mainvar
	qui levelsof `mainvar' if `touse', local(values)
	if "`values'" != "0 1" {
		display as error "Error: the variable `mainvar' should take values 0 and 1 only"
		exit
	}
	tempname postBalance
	tempfile balance
	qui postfile `postBalance' ///
		Line str100 Variable Group1Means Group2Means Difference str5 Starsvar StdDiff Observations using "`balance'", replace
	* Fixed Effects option
	if "`fe'" != "" local fe = "i.`fe'"
	* Loop on variables to build each line of the table
	foreach x of local depvarlist {
		* Save text to go in the left column
		if "`varlabels'" != "" & "`varnames'" == "" {
			local variable: var label `x'
			if "`filetype'" == "latex" local variable: subinstr local variable "_" "\_", all
		}
		else if "`varlabels'" == "" {
			if "`filetype'" == "latex" local variable: subinstr local x "_" "\_", all
			else if "`filetype'" == "excel" local variable `x'
		}
		else {
			display as error "Error: labels and nolabels are alternative options and may not be used together."
			error
		}
		* Wrap option (with respective suboptions)
		if "`wrap'" != "" | "`wrapsubopt'" != "" {
			local maxvarwidth = 32
			wrap_subopt `wrapsubopt', wrap_varwidth(`varwidth')
			local variable_pt2: piece 2 `maxvarwidth' of "`variable'", nobreak
			local variable: piece 1 `maxvarwidth' of "`variable'", nobreak
			if "`indent'" != "" & "`filetype'" == "latex" local indent "\quad"
			else if "`indent'" != "" & "`filetype'" == "excel" local indent " "
			if "`variable_pt2'" != "" & "`filetype'" == "latex" local variable_pt2 "`indent' `variable_pt2'"
			else if "`variable_pt2'" != "" & "`filetype'" == "excel" local variable_pt2 " `variable_pt2'"
		}
		* Varwidth option
		if "`varwidth'" != "" & "`filetype'" == "latex" {
			local variable = `"`variable'\rule{`=`varwidth'-`:udstrlen local variable''ex}{0pt}"'
			if "`variable_pt2'" != "" local variable_pt2 = `"`variable_pt2'\rule{`=`varwidth'-`:udstrlen local variable_pt2''ex}{0pt}"'
		}
		* Mean and SD of group1
		qui sum `x' if `mainvar' == 0 & `touse'
		local group1mean = r(mean)
		local group1sd = r(sd)
		* Mean and SD of group2
		qui sum `x' if `mainvar' == 1 & `touse'
		local group2mean = r(mean)
		local group2sd = r(sd)
		* Coefficient and conventional SE of difference
		qui reg `x' `mainvar' `fe' `covariates' if `touse', `vce'
		local diff = _b[`mainvar']
		local se = _se[`mainvar']
		local obs = e(N)
		* Significance stars
		local stars
		if abs(`diff'/`se') > invt(e(df_r),0.95) local stars "*"
		if abs(`diff'/`se') > invt(e(df_r),0.975) local stars "**"
		if abs(`diff'/`se') > invt(e(df_r),0.995) local stars "***"
		* Standardized difference option
		if "`stddiff'" != "" local std_diff = (`group2mean'-`group1mean')/(sqrt(`group2sd'^2+`group1sd'^2))
		else local std_diff = "."
		* Print SE or p-values
		if "`pvalues'" == "" {
		post `postBalance' (1) ("`variable'") (`group1mean') (`group2mean') (`diff') ("") (`std_diff') (`obs')
		post `postBalance' (2) ("`variable_pt2'") (`group1sd') (`group2sd') (`se') ("`stars'") (.) (.)
		}
		else if "`pvalues'" != "" {
		qui test `mainvar'
		local pval = r(p)
		post `postBalance' (1) ("`variable'") (`group1mean') (`group2mean') (`diff') ("") (`std_diff') (`obs')
		post `postBalance' (2) ("`variable_pt2'") (`group1sd') (`group2sd') (`pval') ("`stars'") (.) (.)
		}
	}
	postclose `postBalance'
	* Sample size
	qui count if `mainvar' == 0 & `touse'
	local group1obs = strtrim("`: dis %20.0gc r(N)'")
	qui count if `mainvar' == 1 & `touse'
	local group2obs = strtrim("`: dis %20.0gc r(N)'")
	qui count if (`mainvar' == 0 | `mainvar' == 1) & `touse'
	local obs_tot = strtrim("`: dis %20.0gc r(N)'")
	* Format option
	if "`format'" == "" local formatting = "format(%10.3fc)"
	else if "`format'" != "" local formatting = "`format'"
	* Edit "dataset"
	preserve
	use `balance', clear
	qui tostring Group1Means Group2Means Difference StdDiff, replace force `formatting'
	qui tostring Observations, replace force format(%20.0gc) 
	qui replace Group1Means = "("+Group1Means+")" if Line == 2
	qui replace Group2Means = "("+Group2Means+")" if Line == 2
	qui replace Difference = "("+Difference+")"+Starsvar if Line == 2
	qui replace Group1Means="" if Group1Means=="."
	qui replace Group2Means="" if Group2Means=="."
	qui replace StdDiff="" if StdDiff=="."
	qui replace Observations="" if Observations=="."
	
	* LaTeX file
	if "`filetype'" == "latex" {
		local col_nr = 3
		* Stddiff option (standardized difference)
		if "`stddiff'" != "" {
			local ++col_nr
			local stddiff_col = "StdDiff"
			if "`tabulary'" == "" local stddiff_c = "c"
			else if "`tabulary'" != "" local stddiff_c = "C"
			local stddiff_numbers = "& (`col_nr')"
			local stddiff_title1 = "& ``col_nr''"
			//local stddiff_title2 = "& Std. Diff."
			local stddiff_sample = "& "
		}
		* Observationscolum option
		if "`observationscolumn'" != "" {
			local ++col_nr
			local obs_col = "Observations"
			if "`tabulary'" == "" local obs_c = "c"
			else if "`tabulary'" != "" local obs_c = "C"
			local obs_numbers = "& (`col_nr')"
			local obs_title1 = "& ``col_nr''"
			//local obs_title2 = "& Observations"
			local obs_sample = "`stddiff_sample' & `obs_tot'"
		}
		else local obs_sample = "`obs_tot' `stddiff_sample'" 
		* Booktabs option
		if "`booktabs'" == "" {
			local top_line = "\hline\hline"
			local mid_line = "\hline"
			local btm_line = "\hline\hline"
		}
		else if "`booktabs'" != "" {
			local top_line = "\toprule"
			local mid_line = "\midrule"
			local btm_line = "\bottomrule"
		}
		* Nonumbers option
		if "`nonumbers'" == "" local mnumbers = `"" & (1) & (2) & (3) `stddiff_numbers' `obs_numbers' \\""'
		* Leftctitle option
		if "`leftctitle'" == "" local leftctitle = "Variable"
		* Ctitles option
		if `"`ctitles'"' != "" local title1 = `""`leftctitle' & `1' & `2' & `3' `stddiff_title1' `obs_title1' \\""'
		* Noobservations option
		if "`noobservations'" == "" local observations = `""`mid_line'" "Observations & `group1obs' & `group2obs' & `obs_sample' \\""'
		/* Maxvarwidth option
		if "`varwidth'" == "" & "`tabulary'" == "" local left_c = "l"
		else if "`varwidth'" == "" & "`tabulary'" == "" local left_c = "L"
		else if "`varwidth'" != "" local left_c = "p{`varwidth'ex}"*/
		* Tabulary option
		if "`tabulary'" == "" {
			local begin = "\begin{tabular}{lccc`stddiff_c'`obs_c'}"
			local end = "\end{tabular}"
		}
		else if "`tabulary'" != "" {
			local begin = "\begin{tabulary}{\textwidth}{LCCC`stddiff_c'`obs_c'}"
			local end = "\end{tabulary}"
		}
		* Print table
		listtab Variable Group1Means Group2Means Difference `stddiff_col' `obs_col' using "`using'", ///
			rstyle(tabular) `replace' ///
			head(`begin' `prehead' ///
			"`top_line'" `posthead' ///
			`mnumbers' ///
			`title1' ///
			"`mid_line'") ///
			foot(`observations' `prefoot' ///
			"`btm_line'" `postfoot' ///
			`end')
			//"Variable & Mean & Mean  & Difference `stddiff_title2' `obs_title2' \\" ///
	}
	
	* Excel file
	else if "`filetype'" == "excel" {
		local nr_depvars: word count `depvarlist'
		qui putexcel set "`using'", `replace'
		local col_nr = 3
		local col_pos = 4
		* Stddiff option (standardized difference)
		if "`stddiff'" != "" {
			local ++col_nr
			local ++col_pos
			local col_letter: word `col_pos' of `c(ALPHA)'
			local stddiff_col = "StdDiff" //
			local stddiff_numbers = `"`col_letter'\`active_line' = ("(`col_nr')")"'
			local stddiff_title1 = `"`col_letter'\`active_line' = ("``col_nr''")"'
			local stddiff_title2 = `"`col_letter'\`active_line' = ("Std. Diff.")"'
		}
		* Observationscolum option
		if "`observationscolumn'" != "" {
			local ++col_nr
			local ++col_pos
			local col_letter: word `col_pos' of `c(ALPHA)'
			local obs_col = "Observations"
			local obs_numbers = `"`col_letter'\`active_line' = ("(`col_nr')")"'
			local obs_title1 = `"`col_letter'\`active_line' = ("``col_nr''")"'
			local obs_title2 = `"`col_letter'\`active_line' = ("Observations")"'
			local obs_sample = `"`col_letter'\`active_line' = ("`obs_tot'")"'
		}
		else local obs_sample = `"D\`active_line' = ("`obs_tot'")"'
		local last_col: word `col_pos' of `c(ALPHA)'
		qui putexcel A1:`last_col'1 = border("top", "medium")
		local active_line = 1
		* Nonumbers option
		if "`nonumbers'" == "" {
			qui putexcel B`active_line' = ("(1)") C`active_line' = ("(2)") D`active_line' = ("(3)") `stddiff_numbers' `obs_numbers'
		}
		* Leftctitle option
		if "`leftctitle'" == "" local leftctitle = "Variable"
		* Ctitles option
		if `"`ctitles'"' != "" {
			local ++active_line
			qui putexcel A`active_line' = ("`leftctitle'") B`active_line' = ("`1'") C`active_line' = ("`2'") D`active_line' = ("`3'") `stddiff_title1' `obs_title1'
		}
		qui putexcel 
		//B`active_line' = ("Mean") C`active_line' = ("Mean") D`active_line' = ("Difference") `stddiff_title2' `obs_title2'
		qui putexcel A`active_line':`last_col'`active_line' = border("bottom", "thin")
		local results_line = `active_line'+1
		local active_line = `active_line'+2*`nr_depvars'
		* Noobservations option
		if "`noobservations'" == "" {
			local ++active_line
			qui putexcel A`active_line':`last_col'`active_line' = border("top", "thin")
			qui putexcel A`active_line' = ("Observations") B`active_line' = ("`group1obs'") C`active_line' = ("`group2obs'") `obs_sample'
		}
		qui putexcel A`active_line':`last_col'`active_line' = border("bottom", "medium")
		qui putexcel A1:A`active_line' = halign("left") B1:`last_col'`active_line' = halign("center")
		qui putexcel clear
		export excel Variable Group1Means Group2Means Difference `stddiff_col' `obs_col' using "`using'", cell(A`results_line') sheetmodify missing("")
		//if "`observationscolumn'" != "" qui putexcel E`active_line'=border("bottom", "medium") E1:E`active_line'=halign("center") using "`using'", modify
	}
	restore
end


cap program drop balancetable_complex
program define balancetable_complex
	syntax anything using/ [if] [in],  ///
		[vce(passthru)] [FE(varname)] [COVariates(varlist fv ts)] ///
		[ctitles(string asis)]  [leftctitle(string)] ///
		[PVALues] [VARLAbels] [VARNAmes] [wrap WRAPsubopt(string)] ///
		[NONUMbers] [NOOBServations] [observationscolumn] [format(passthru)] ///
		[VARWIdth(numlist integer max=1)]  [tabulary] [BOOKTabs] ///
		[prehead(string asis)] [posthead(string asis)] [prefoot(string asis)] [postfoot(string asis)] ///
		[REPLACE]

	* Process syntax
	marksample touse, novarlist strok
	balancetable_parsing `anything'
	tokenize `"`ctitles'"'
	* Check presence of 'listtab' command
	cap which listtab
	if _rc ssc install listtab
	* Check correct extension of filename
	if ustrright("`using'",4) == ".tex" local filetype = "latex"
	else if ustrright("`using'",4) == ".xls" | ustrright("`using'",5) == ".xlsx" local filetype = "excel"
	else {
		dis as error "Error: the filename must have extesions .tex, .xls or .xlsx"
		exit
	}
	* Build the variables column (Column 0)
	tempname postBalanceVar
	tempfile balance_var
	qui postfile `postBalanceVar' Line str100 Variable using `balance_var', replace
	foreach x in `depvarlist' {
		* Save text to go in the left column
		if "`varlabels'" != "" & "`varnames'" == "" {
			local variable: var label `x'
			if "`filetype'" == "latex" local variable: subinstr local variable "_" "\_", all
		}
		else if "`varlabels'" == "" {
			if "`filetype'" == "latex" local variable: subinstr local x "_" "\_", all
			else if "`filetype'" == "excel" local variable `x'
		}
		else {
			display as error "Error: labels and nolabels are alternative options and may not be used together."
			error
		}
		* Wrap option (with respective suboptions)
		if "`wrap'" != "" | "`wrapsubopt'" != "" {
			local maxvarwidth = 32
			wrap_subopt `wrapsubopt', wrap_varwidth(`varwidth')
			local variable_pt2: piece 2 `maxvarwidth' of "`variable'", nobreak
			local variable: piece 1 `maxvarwidth' of "`variable'", nobreak
			if "`indent'" != "" & "`filetype'" == "latex" local indent "\quad"
			else if "`indent'" != "" & "`filetype'" == "excel" local indent " "
			if "`variable_pt2'" != "" & "`filetype'" == "latex" local variable_pt2 "`indent' `variable_pt2'"
			else if "`variable_pt2'" != "" & "`filetype'" == "excel" local variable_pt2 " `variable_pt2'"
		}
		* Varwidth option
		if "`varwidth'" != "" & "`filetype'" == "latex" {
			local variable = `"`variable'\rule{`=`varwidth'-`:udstrlen local variable''ex}{0pt}"'
			if "`variable_pt2'" != "" local variable_pt2 = `"`variable_pt2'\rule{`=`varwidth'-`:udstrlen local variable_pt2''ex}{0pt}"'
		}
	post `postBalanceVar' (1) ("`variable'")
	post `postBalanceVar' (2) ("`variable_pt2'")
	}
	postclose `postBalanceVar'
	* Fixed Effects option
	if "`fe'" != "" local fe = "i.`fe'"
	* Build remaining columns with results (Column 1 ... Column N)
	forvalues i = 1/`par_nr' {
		tempname postBalanceCol`i'
		tempfile balance_col`i'
		qui postfile `postBalanceCol`i'' Line Col`i' str3 Stars`i' using `balance_col`i'', replace
		* Compute statistics for "mean" type of column
		if "`par`i'_type'" == "mean" {
			foreach x in `depvarlist' {
				qui sum `x' if `touse' `par`i'_if'
				post `postBalanceCol`i'' (1) (r(mean)) ("")		
				post `postBalanceCol`i'' (2) (r(sd)) ("")
			}
		}
		* Compute statistics for "diff" type of column
		else if "`par`i'_type'" == "diff" {
			* Check correct values of mainvar
			qui levelsof `par`i'_mainvar' if `touse' `par`i'_if', local(values)
			if "`values'" != "0 1" {
				display as error "Error: the variable `par`i'_mainvar' should take values 0 and 1 only"
				exit
			}
			foreach x in `depvarlist' {
				qui reg `x' `par`i'_mainvar' `fe' `covariates' if `touse' `par`i'_if', `vce'
				qui test `par`i'_mainvar'
				* Check stars
				if r(p) < 0.01 local stars = "***"
				else if r(p) >= 0.01 & r(p) < 0.05 local stars = "**"
				else if r(p) >= 0.05 & r(p) < 0.10 local stars = "*"
				else local stars = ""
				post `postBalanceCol`i'' (1) (_b[`par`i'_mainvar']) ("")
				* Pvalues option
				if "`pvalues'" != "" post `postBalanceCol`i'' (2) (r(p)) ("`stars'")
				else post `postBalanceCol`i'' (2) (_se[`par`i'_mainvar']) ("`stars'")
			}
		}
		* Calculate observations in subsample
		qui count if `touse' `par`i'_if'
		local col`i'_obs = strtrim("`: dis %20.0gc r(N)'")
		postclose `postBalanceCol`i''
	}
	* Format option
	if "`format'" == "" local formatting = "format(%10.3fc)"
	else if "`format'" != "" local formatting = "`format'"
	* Merge postfiles and edit "dataset"
	preserve
	use `balance_var', clear
	forvalues i = 1/`par_nr' {
		merge 1:1 _n using `balance_col`i'', nogen noreport
		qui tostring Col`i', replace force `formatting'
		qui replace Col`i' = "" if Col`i' == "."
		qui replace Col`i' = "(" + Col`i' + ")" + Stars`i' if Line == 2
	}

	* LaTeX file
	if "`filetype'" == "latex" {
		* Tabulary option
		if "`tabulary'" == "" {
			local begin = "\begin{tabular}{l*{`par_nr'}c}"
			local end = "\end{tabular}"
		}
		else if "`tabulary'" != "" {
			local begin = "\begin{tabulary}{\textwidth}{L*{`par_nr'}C}"
			local end = "\end{tabulary}"
		}
		* Booktabs option
		if "`booktabs'" == "" {
			local top_line = "\hline\hline"
			local mid_line = "\hline"
			local btm_line = "\hline\hline"
		}
		else if "`booktabs'" != "" {
			local top_line = "\toprule"
			local mid_line = "\midrule"
			local btm_line = "\bottomrule"
		}
		* Noobservations, nonumbers, ctitles and options
		if "`leftctitle'" == "" local leftctitle = "Variable"
		forvalues i = 1/`par_nr' {
			if "`nonumbers'" == "" local numbers_list = "`numbers_list' & (`i')"
			if `"`ctitles'"' != "" local titles_list = "`titles_list' & ``i''"
			if "`noobservations'" == "" local obs_list = "`obs_list' & `col`i'_obs'"
		local mnumbers = `""`numbers_list' \\""'
		local title1 = `""`leftctitle'`titles_list' \\""'
		local observations = `""`mid_line'" "Observations `obs_list' \\""'
		}
		* Print table
		listtab Variable Col* using "`using'", ///
			rstyle(tabular) `replace' ///
			head(`begin' `prehead' ///
			"`top_line'" `posthead' ///
			`mnumbers' ///
			`title1' ///
			"`mid_line'") ///
			foot(`observations' `prefoot' ///
			"`btm_line'" `postfoot' ///
			`end')
	}

	* Excel file
	else if "`filetype'" == "excel" {
		local nr_depvars: word count `depvarlist'
		qui putexcel set "`using'", `replace'
		***local col_nr = `par_nr'+1
		***local col_pos = 4
		local last_col: word `=`par_nr'+1' of `c(ALPHA)'
		*Start printing header
		qui putexcel A1:`last_col'1 = border("top", "medium")
		local active_line = 1
		* Nonumbers option
		if "`nonumbers'" == "" {
			forvalues i = 1/`par_nr' {
				qui putexcel `: word `=`i'+1' of `c(ALPHA)''`active_line' = ("(`i')")
			}
		}
		* Leftctitle option
		if "`leftctitle'" == "" local leftctitle = "Variable"
		* Ctitles option
		if `"`ctitles'"' != "" {
			local ++active_line
			qui putexcel A`active_line' = ("`leftctitle'")
			forvalues i = 1/`par_nr' {
				qui putexcel `: word `=`i'+1' of `c(ALPHA)''`active_line' = ("``i''")
			}
		}
		qui putexcel A`active_line':`last_col'`active_line' = border("bottom", "thin")
		* Start printing footer
		local results_line = `active_line'+1
		local active_line = `active_line'+2*`nr_depvars'
		* Noobservations option
		if "`noobservations'" == "" {
			local ++active_line
			qui putexcel A`active_line':`last_col'`active_line' = border("top", "thin")
			qui putexcel A`active_line' = ("Observations")
			forvalues i = 1/`par_nr' {
				qui putexcel `: word `=`i'+1' of `c(ALPHA)''`active_line' = ("`col`i'_obs'")
			}
		}
		qui putexcel A`active_line':`last_col'`active_line' = border("bottom", "medium")
		qui putexcel A1:A`active_line' = halign("left") B1:`last_col'`active_line' = halign("center")
		qui putexcel clear
		* Export actual results
		export excel Variable Col* using "`using'", cell(A`results_line') sheetmodify missing("")
	}
	restore
end


cap program drop wrap_subopt
program define wrap_subopt
	syntax [anything], [wrap_varwidth(numlist missingokay)]
	
	if ustrregexm("`anything'","indent") {
		c_local indent indent
		local anything = subinstr("`anything'","indent","",.)
	}
	if "`anything'" != "" {
		confirm number `anything'
		c_local maxvarwidth = `anything'
		if "`wrap_varwidth'" != "" {
			cap assert `anything' <= `wrap_varwidth'
			if _rc {
				dis in smcl in red "The number indicated in the {bf:wrap()} option cannot exceed the one indicated in the {bf:varwidth()} option"
				error 121
			}
		 }
	}
end


cap program drop balancetable_parsing
program define balancetable_parsing
	version 14.0
	syntax anything(equalok name=to_parse)

	* Separate parenthesis and depvars
	local par_nr = 0
	while strpos("`to_parse'", "(") > 0 {
		local ++par_nr
		gettoken par`par_nr'_all to_parse: to_parse, match(mattia)
	}
	c_local par_nr = `par_nr'
	c_local depvarlist "`to_parse'"
	*Check parenthesis type
	forvalues i = 1/`par_nr' {
		if ustrregexm(`"`par`i'_all'"',"^(mean)[ ]*(if[ ]+.*)?$") {
			c_local par`i'_type = ustrregexs(1)
			c_local par`i'_if = subinword(ustrregexs(2),"if","&",1)		// this makes it compatible with marksample touse
		}
		else if ustrregexm(`"`par`i'_all'"',"^(diff)[ ]+([a-zA-z0-9_]+)[ ]*(if[ ]+.*)?$") {
			c_local par`i'_type = ustrregexs(1)
			c_local par`i'_mainvar = ustrregexs(2)
			c_local par`i'_if = subinword(ustrregexs(3),"if","&",1)		// this makes it compatible with marksample touse
		}
		else {
			dis as error "Error: syntax in parenthesis `i' is not allowed"
			error 197
		}
	}
end
