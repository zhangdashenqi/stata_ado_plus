*! version 3.4 Apr 2012 by LQ
*! version 3.3 Dec 2011 by LQ
*! version 3.2 Oct 2011 by LQ
*! version 3.1 Sep 2011 by LQ
*! version 3.0 Jul 2011 by LQ
*! version 2.1 May 2011 by LQ
*! version 2.0 Apr 2011 by LQ
*! version 1.1 Jun 2009 by LQ

*! This program makes a table of summary statistics in HTML format
*! Disclaimer: This program is provided "AS IS".
*! Authors are not responsible of any kind of damage, derived from the use of this program.

program define htsummary
syntax varlist(min=1 max=2) [if] [in], [Head] [noTotal] [ROWTotal] [CLose] /*
*/                          [Log] [MEDian] [FReq] [Row] [Add(real 0)] [REcode(string asis)] /*
*/ 			    			[Anova] [Kw] [CHI] [EXACT] [TEST] /*
*/ 			    			[Format(string)] /*
*/                          [Pval(real -1)] [MEthod(string asis)] /*
*/			    			[MIssing] /*
*/			    			[Color(real -1)] 

version 8

/* save data in memory */			
	tempfile data
	qui save `data', replace

/* GENERE TYPE OF SUMMARY */
	if "`log'" == "" & "`median'" == "" & "`freq'" == "" {
		local type arithmetic
		local footnote "Arithmetic Mean (SD) [n]"
	}
	if "`log'" != "" & "`median'" == "" & "`freq'" == "" {
		local type geometric
		local footnote "Geometric Mean (SD) [n]"
	}
	if "`log'" == "" & "`median'" != "" & "`freq'" == "" {
		local type median
		local footnote "Median (IQR) [n]"
	}
	if "`log'" == "" & "`median'" == "" & "`freq'" != "" {
		local type freqs
		if "`row'" == "" local footnote "n (column percentage)"
		else local footnote "n (row percentage)"
	}
	if "`type'" == "" {
		di ase err "Only one of log, median or freq are allowed"
		exit
	}

/* ASSERTIONS */
	if "`head'" == "" {
		cap assert "$HTsummary" == "on"
		if _rc != 0 {
			di as err "use option head for first row"
			exit
		}
	}	 
	else {
		cap assert "$HTsummary" != "on" 
		if _rc != 0 {
			di as err "htsummary in use, option head not allowed"
			exit
		}
	}	 
	
	if "`anova'" != "" | "`kw'" != "" {
		cap assert "`freq'" == ""
		if _rc != 0 {
			di as err "method not allowed with freq"
			exit
		}
	}
	
	if "`chi'" != "" | "`exact'" != "" { 
		cap assert "`freq'" != ""
		if _rc != 0 {
			di as err "this method is only allowed with combination with freq"
			exit
		}
	}
	
	if "`missing'" != "" {
		cap assert "`freq'" != ""
		if _rc != 0 {
			di as err "missing is only allowed with combination with freq"
			exit
		}
	}
	
	if "`row'" != "" {
		cap assert "`freq'" != ""
		if _rc != 0 {
			di as err "row is only allowed with combination with freq"
			exit
		}
	}
	
	if "`rowtotal'" != "" {
		cap assert "`freq'" != ""
		if _rc != 0 {
			di as err "rowtotal is only allowed with combination with freq"
			exit
		}
	}
	
	if "`test'" != "" {
		cap assert "`anova'" == "" & "`kw'" == "" & "`chi'" == "" & "`exact'" == ""
		if _rc != 0 {
			di as err "test is not allowed with combination with anova, kw, chi or exact"
			exit
		}
	}
	
/* KEEP VALID RECORDS */
	tokenize `varlist'
	local vrow = "`1'"
	local vcol = "`2'"
	
	if "`format'" != "" format `vrow' `format'

	if "`vcol'" == "" { /* overall descriptive */
		tempvar all
		gen `all' = 1
		label var `all' "Summary statistics"
		local vcol = "`all'"
		local total "nototal"
		local chi 
		local exact
		local anova
		local kw
		local test
	}

	/* convert to numeric, if needed */
		foreach var in vrow vcol {
			cap confirm string variable ``var''
			if _rc == 0 {
				tempvar new`var'
				encode ``var'', gen(`new`var'')
				local `var' `new`var''
			}	
		}	
	
	if `"`if'"' != "" keep `if'
	if `"`in'"' != "" keep `in'
	quietly drop if `vcol' == .
	if `"`recode'"' != "" quiet recode `vrow' `recode'

/* LABEL MANAGEMENT */
	local collab: variable label `vcol'
	if `"`collab'"' == "" local collab = "`vcol'"
	qui levelsof `vcol', local(collevels)
	local ncolum = wordcount("`collevels'")
	if "`missing'" == "" quietly drop if `vrow' == .
	
	local rowlab: variable label `vrow'
	if `"`rowlab'"' == "" local rowlab= "`vrow'"
	if "`type'" != "freqs" local rowform: format `vrow'
	else {
		qui levelsof `vrow', local(rowlevels) `missing' /* show missings as a new level */ 
		local nrow = wordcount("`rowlevels'")
		if `nrow' == 1 local rowtotal ""
	}

/* QUERY TEST */
	if "`test'" != "" {
		if inlist("`type'", "arithmetic", "geometric") local anova anova
		if "`type'" == "median" local kw kw
		if "`type'" == "freqs" {
			querytest `vrow' `vcol'
			local test = r(test)
			if "`test'" == "chi" local chi chi
			else local exact exact
		}
		else noi di in y "Test: `anova'`kw'"
	}	
		
/* TABLE HEADER */
	if "`head'" != "" {
		if "`total'" == "" global HTptot = "on"
		else global HTptot = "off"

		local colspan = (`ncolum'+cond("$HTptot"=="on",1,0))

		htput <TABLE BORDER=1 CELLSPACING=0 CELLPADDING=2>
		htput <TR>
			local span = 1 + cond("`vcol'" == "`all'", 0, 1)
			htput <TH VALIGN=BOTTOM ROWSPAN=`span' COLSPAN=2> Variable </TH> 
			htput <TH ALIGN=CENTER COLSPAN=`colspan'> `collab' </TH>
			if "`anova'" != "" | "`kw'" != "" | "`chi'" != "" | "`exact'" != "" | `pval' != -1 { /* p-values are required */
				htput <TH VALIGN=BOTTOM ROWSPAN=2>p-value</TH>
			}
		htput </TR>

		htput <TR>
			if "`vcol'" != "`all'" {
				foreach i in `collevels' {
					local group: label (`vcol') `i'	
					htput <TH>`group'</TH>
				}
			}
			if "$HTptot" == "on" htput <TH> Total </TH>
			global HTcolor "`color'" /* color option for p-values */
		htput </TR>
		global HTsummary = "on"
	} /* end of header */

/* COMPUTE SUMMARY STATISTICS */
	if "`log'" != "" quiet replace `vrow' = log(`vrow'+`add')
	else quiet replace `vrow' = `vrow' +`add'

	/* compute cell contents */
	if "`type'" != "freqs" {
		foreach i in `collevels' {
			quietly summ `vrow' if `vcol' == `i', detail
			local n = r(N)
			if "`type'" == "arithmetic" {
				local average = r(mean)
				local dispersion = r(sd)
			}
			if "`type'" == "geometric" {
				local average = exp(r(mean))
				local dispersion = exp(r(mean))*r(sd)
			}
			if "`type'" == "median" {
				local average = r(p50)
				local dispersion = r(p75) - r(p25)
			}
			local cell_`i': di string(`average',"`rowform'") " ("string(`dispersion',"`rowform'") ") [" `n' "]"
		}
		if "$HTptot" == "on" {
			quietly summ `vrow', detail
			local n = r(N)
			if "`type'" == "arithmetic" {
				local average = r(mean)
				local dispersion = r(sd)
			}
			if "`type'" == "geometric" {
				local average = exp(r(mean))
				local dispersion = exp(r(mean))*r(sd)
			}
			if "`type'" == "median" {
				local average = r(p50)
				local dispersion = r(p75) - r(p25)
			}
			local cell_tot: di string(`average',"`rowform'") " ("string(`dispersion',"`rowform'") ") [" `n' "]"
		}
	}
	else {  
		foreach i in `rowlevels' {
			foreach j in `collevels' {
				if "`row'" == "" quietly count if `vcol' == `j'
				else quietly count if `vrow' == `i'
				local denom = r(N)
				quietly count if `vrow' == `i' & `vcol' == `j'
				local n = r(N)
				if `denom' > 0 local pct: di %3.0f (`n'/`denom') * 100
				else local pct 0
				if "`i'" != "." local cell_`i'`j': di `n' " ("`pct' "%)"
				else  local cell_miss`j': di `n' " ("`pct' "%)"
			}
		}
		if "`rowtotal'" != "" {
			foreach j in `collevels' {
				if "`row'" == "" quietly count if `vcol' == `j'
				else quietly count
				local denom = r(N)
				quietly count if `vcol' == `j'
				local n = r(N)
				if `denom' > 0 local pct: di %3.0f (`n'/`denom') * 100
				else local pct 0
				local cell_tot`j': di `n' " ("`pct' "%)"
			}
		}
		if "$HTptot" == "on" {
			if "`row'" == "" {
				quietly	count
				local denom = r(N)
			}	
			foreach i in `rowlevels' {
				quietly count if `vrow' == `i'
				local n = r(N)
				if "`row'" != "" local denom = r(N)
				local pct: di %3.0f (`n'/`denom') * 100
				if "`i'" == "." local i "miss"
				local cell_`i'tot: di `n' " ("`pct' "%)" 
			}
			if "`rowtotal'" != "" {
				quietly count
				local n = r(N)
				if "`row'" != "" local denom = r(N)
				local pct:di %3.0f (`n'/`denom') * 100
				local cell_tottot: di `n' " ("`pct' "%)" 
			}
		}
	}	

/* COMPUTE P-VALUES */
	if "`anova'" != "" {
		cap quiet anova `vrow' `vcol' `if' `in', category(`vcol')
		quiet test `vcol'
		local pval = fprob(r(df),r(df_r),r(F))
		if r(df) == 1 local method  t-test
		else local method  ANOVA
	}
	if "`kw'" != "" {
		if `ncolum' == 2 {
			cap quiet ranksum `vrow' `if' `in', by(`vcol')
			local pval = (1-normprob(abs(r(z))))*2
			local method  Wilcoxon Rank Sum test
		}
		else {
			cap quiet kwallis `vrow' `if' `in', by(`vcol')
			local pval = chiprob(r(df),r(chi2_adj))
			local method  Kruskal-Wallis test
		}
	}
	if "`chi'" != "" {
		cap quietly tab `vrow' `vcol', chi `missing'
		local pval = r(p)
		local method  Chi-squared test
	}
	if "`exact'" != "" {
		cap quietly tab `vrow' `vcol', exact `missing'
		local pval = r(p_exact)
		local method  Fisher's exact test
	}
	
	if `pval' != -1 local pval: di %6.4f `pval'
	
/* CELL COLOR */
	if "$HTcolor" != "-1" {
		if `pval' != -1 & round(`pval',0.0001) <= `color' local color `"BGCOLOR="#E3E4FA""'
		else local color ""
	}
	else local color ""

/* BODY TABLE */
	if "`type'" != "freqs" {
		htput <TR>
			htput <TD COLSPAN=2 `color'>`rowlab'
			htsupput `footnote'
			htput </TD>
			foreach i in `collevels' {
				htput <TD ALIGN=RIGHT `color'> `cell_`i''</TD>
			}
			if "$HTptot" == "on" htput <TD ALIGN=RIGHT `color'> `cell_tot'</TD>

			if `pval' != -1 {
				if round(`pval',0.0001) >= 0.0001 htput <TD ALIGN=CENTER VALIGN=CENTER `color'> `pval'
				else htput <TD ALIGN=CENTER VALIGN=CENTER `color'> < 0.0001
				if `pval' != . htsupput `method'
			}
		htput </TR>
	}
	else {
		local first = word("`rowlevels'",1)
		foreach i in `rowlevels' `rowtotal' {

			htput <TR>
			if "`i'" == "`first'" {
					htput <TD ROWSPAN=`= `nrow' + cond("`rowtotal'"=="",0,1)' valign=top `color'>`rowlab'
					htsupput `footnote'
					htput </TD>
			}
			htput <TD `color'>
				if "`i'" != "rowtotal" {
					local thisl: label (`vrow') `i'
					htput `thisl' 
				}
				else htput <i> Total
			htput </TD>

			if "`i'" == "." local i "miss"
			if "`i'" == "rowtotal" {
				local i "tot"
				local font <i>
			}
			foreach j in `collevels' {
				htput <TD ALIGN=RIGHT `color'>`font' `cell_`i'`j'' </TD>
			}
			if "$HTptot" == "on" htput <TD ALIGN=RIGHT `color'>`font' `cell_`i'tot'</TD>
			
			if "`i'" == "`first'" {
					if `pval' != -1 {
						if round(`pval',0.0001) >= 0.0001 htput <TD ALIGN=CENTER VALIGN=TOP ROWSPAN=`= `nrow' + cond("`rowtotal'"=="",0,1)' `color'> `pval'
						else htput <TD ALIGN=CENTER VALIGN=TOP ROWSPAN=`= `nrow' + cond("`rowtotal'"=="",0,1)' `color'> < 0.0001
						if `pval' != . htsupput `method'
					}
			}
			htput </TR>
        	}
	} /* freqs */
		
	if "`close'" != "" {
		htput </TABLE>
		htsupwri
		macro drop HTptot HTcolor HTsummary
	}

/* restore data in memory */			
	qui use `data', replace
end

*!
*! querytest determines the appropriate statistical test 
*! for each type of variables
program querytest, rclass
syntax varlist(min=2 max=2)

	tokenize `varlist'
	
	quietly {
		preserve
			contract `1' `2'
			drop if `1' == . | `2' == .
			egen total= sum(_freq)
			bysort `1': egen total_row = sum(_freq)
			bysort `2': egen total_col = sum(_freq)
			gen expected = (total_row * total_col)/total
			gen low5 = (expected <= 5)
			sum low5
			if r(mean) >= 0.2 local test exact
			else local test chi
			local pct: di %3.0f r(mean)*100
		restore
	}
	noi di in y "`pct' % cells have an expected frequency of 5 or lower --> Test: `test'"
	
	return scalar low5 = `pct'
	return local test = "`test'"
end

*!
*! htsupput put a superscript in HT format
*! and saves the content in a global macro
program define htsupput
	if `"$HTsup"' == "" {
		global HTsup = 1
		global HT1 = `"`0'"'
		local return = 1 
	}
	else{
		local i = 1
		while `i' <= $HTsup {
			local curht = "HT`i'"
			if `"$`curht'"' == `"`0'"' {
				local return = `i'
				local `i' = $HTsup+1
			}
			local i = `i'+1
		}
		if "`return'" == "" {
			global HTsup = $HTsup+1
			local curht = `"HT$HTsup"'
			global `curht' = `"`0'"'
			local return = $HTsup
		}
	}
	* This part put the coefficient
	htput <SUP>`return'</SUP>   
end

*!
*! htsupwri writes the content of superscripts
*! and clean the macros
program define htsupwri
if `"$HTsup"' != "" {
	local i = 1
	while `i' <= $HTsup {
		local xtxt "HT`i'"
		local xtxt = `"$`xtxt'"'
		htput `i': `xtxt' <BR>
		macro drop HT`i'
		local i = `i'+1
	}
}
macro drop HTsup
end 
