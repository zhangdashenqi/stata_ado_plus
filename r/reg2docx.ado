program define reg2docx
	version 15.0
	syntax anything using/, [append replace b Bfmt(string) t Tfmt(string) z ///
	Zfmt(string) p Pfmt(string) se SEfmt(string) NOCONstant CONstant f Ffmt(string) ///
	chi2 CHI2fmt(string) r2 R2fmt(string) ar2 AR2fmt(string) pr2 PR2fmt(string) ///
	aic AICfmt(string) bic BICfmt(string) noOBS obslast NOSTAr STAR STAR2(string asis) ///
	staraux title(string) mtitles MTITLES2(string asis) noMTITLE DEPvars order(string asis) ///
	indicate(string asis) drop(string asis) NOPArentheses PArentheses BRackets]
	
	if "`append'" != "" & "`replace'" != "" {
		disp as error "you could not specify both append and replace"
		exit 198
	}
	
	if ("`t'" != "" | "`tfmt'" != "") + ("`z'" != "" | "`zfmt'" != "") + ///
	("`p'" != "" | "`pfmt'" != "") + ("`se'" != "" | "`sefmt'" != "") >= 2 {
		disp as error "you could only specify one of t|z|p|se[(fmt)]"
		exit 198
	}
	
	if "`noconstant'" != "" & "`constant'" != "" {
		disp as error "you could not specify both noconstant and constant"
		exit 198
	}
	
	if "`obs'" != "" & "`obslast'" != "" {
		disp as error "you could not specify both noobs and obslast"
		exit 198
	}
	
	if ("`nostar'" != "") & ("`star'" != "" | "`star2'" != "" | "`staraux'" != "") {
		disp as error "you could not specify both nostar and star[()]|staraux"
		exit 198
	}
	
	if "`mtitle'" != "" & ("`mtitles'" != "" | `"`mtitles2'"' != "" | "`depvars'" != "") {
		disp as error "you could not specify both nomtitle and mtitles|depvars"
		exit 198
	}
	
	if ("`parentheses'" != "") & ("`noparentheses'" != "" | "`brackets'" != "") {
		disp as error "you could not specify both parentheses and noparentheses|brackets"
		exit 198
	}
	
	local tleft "("
	local tright ")"
	
	if "`noparentheses'" != "" {
		local tleft ""
		local tright ""
	}
	
	if "`brackets'" != "" {
		local tleft "["
		local tright "]"
	}
	
	local star_1 *
	local star_2 **
	local star_3 ***
	local siglevel1 0.1
	local siglevel2 0.05
	local siglevel3 0.01
	local levelnum = 3
	
	if `"`star2'"' != "" {
		if mod(`=wordcount(`"`star2'"')', 2) == 1 {
			disp as error "you specify the option star() incorrectly"
			exit 198
		}
		else {
			token `"`star2'"'
			local levelnum = wordcount(`"`star2'"')/2
			forvalue i = 1(1)`levelnum' {
				local star_`i' ``=`i'*2-1''
				local siglevel`i' ``=`i'*2''
			}
		}
	}
		
	local siglevel`=`levelnum'+1' = 0
	
	local num = 0
	local consexist = 0
	local tails = 0
	foreach mdl in `anything' {
		qui {
			local num = `num' + 1
			est tab `mdl', stat(N F chi2 r2 r2_a r2_p df_m)
			mat scalartab`num' = r(stats)
			if scalar(scalartab`num'[1,1]) < . local N`num' = scalar(scalartab`num'[1,1])
			if scalar(scalartab`num'[2,1]) < . local F`num' = scalar(scalartab`num'[2,1])
			if scalar(scalartab`num'[3,1]) < . local chi2`num' = scalar(scalartab`num'[3,1])
			if scalar(scalartab`num'[4,1]) < . local r2`num' = scalar(scalartab`num'[4,1])
			if scalar(scalartab`num'[5,1]) < . local r2_a`num' = scalar(scalartab`num'[5,1])
			if scalar(scalartab`num'[6,1]) < . local r2_p`num' = scalar(scalartab`num'[6,1])
			if scalar(scalartab`num'[7,1]) < . local df_m`num' = scalar(scalartab`num'[7,1])
			est des `mdl'
			local cmdline = r(cmdline)
			gettoken depvar 0: cmdline
			gettoken depvar 0: 0
			local depvar`num' = "`depvar'"
			est replay `mdl'
			mat table`num' = r(table)'
			local vars`num': rowfullnames table`num'
			local vars`num': rowfullnames table`num'
			if index(`"`vars`num''"', "/") {
				local tailvars`num' = substr(`"`vars`num''"', `=index(`"`vars`num''"', "/")', .)
				local vars`num' = substr(`"`vars`num''"', 1, `=index(`"`vars`num''"', "/") - 1')
			}
			local vars`num' = subinstr("`vars`num''", "`depvar`num'':", "", .)
			if ustrregexm("`vars`num''", "\b_cons\b") {
				local consexist = 1
			}
			local tailvars`num' = subinstr(`"`tailvars`num''"', "/", "", .)
			if "`tailvars`num''" != "" {
				local tails = 1
			}
			local vars_cons`num' = ustrregexra("`vars`num''", " _cons *$", "")
			est stat `mdl'
			mat ictable`num' = r(S)
			local aic`num' = scalar(ictable`num'[1,5])
			local bic`num' = scalar(ictable`num'[1,6])
		}
	}

	if `"`mtitles2'"' != "" {
		token `"`mtitles2'"'
		if "``num''" == "" | "``=`num'+1''" != "" {
			disp as error "the number of mtitles is not equal to the number of models"
			exit 198
		}
		else {
			forvalues i = 1/`num' {
				local mtitle`i' ``i''
			}
		}
	}
	
	else {
		forvalues i = 1/`num' {
			local mtitle`i' `depvar`i''
		}
	}
	
	
	local sig = 3
	if "`bfmt'" == "" local bfmt %9.3f
	if "`tfmt'" == "" local tfmt `bfmt'
	if "`zfmt'" == "" local zfmt `bfmt'
	if "`se'" != "" | "`sefmt'" != "" {
		local sig = 2
		if "`sefmt'" == "" local sefmt `bfmt'
	}
	if "`p'" != "" | "`pfmt'" != "" {
		local sig = 4
		if "`pfmt'" == "" local pfmt `bfmt'
	}
	
	forvalues i = 1/`num' {
		foreach name in `vars_cons`i'' {
			if !ustrregexm(`"`totalvarname'"', "\b`name'\b") {
				local totalvarname = "`totalvarname'" + "`name'" + " "
			}
		}
	}
	if `consexist' == 1 local totalvarname "`totalvarname'_cons"
	
	if "`drop'" != "" {
		foreach var in `drop' {
			if !ustrregexm("`totalvarname'", "\b`var'\b") {
				disp as error "the variable `var' in drop() do not exist"
				exit 198
			}
			local totalvarname = ustrregexra("`totalvarname'", "`var' ", "")
		}
	}
	
	if `"`indicate'"' != "" {
		local indicatenum = 0
		foreach part in `indicate' {
			local indicatenum = `indicatenum' + 1
			if !index(`"`part'"', "=") {
				disp as error "you have specified the option indicate() wrongly"
				exit 198
			}
			local part`indicatenum' = `"`part'"'
		}
		forvalues indi = 1/`indicatenum' {
			local indicatename`indi' = substr(`"`part`indi''"', 1, `=index(`"`part`indi''"', "=")-1')
			local indicatename`indi' = ustrregexra(`"`indicatename`indi''"', " +$", "")
			local indicatevar`indi' = substr(`"`part`indi''"', `=index(`"`part`indi''"', "=")+1', .)
			local indicatevar`indi' = ustrregexra(`"`indicatevar`indi''"', "^ +", "")
		}
		forvalues indi = 1/`indicatenum' {
			forvalues i = 1/`num' {
				local indicatelabel`indi'_`i' = "No"
			}
		}
		local totalv = `"`totalvarname'"'
		foreach var in `totalv' {
			forvalues indi =  1/`indicatenum' {
				if strmatch(`"`var'"', `"`indicatevar`indi''"') {
					local totalvarname = ustrregexra(`"`totalvarname'"', `"\b`var'\b"', "")
					forvalues i = 1/`num' {
						if ustrregexm(`"`vars`i''"', "\b`var'\b") {
							local indicatelabel`indi'_`i' "Yes"
						}
					}
				}
			}
		}
		local totalvarname = ustrregexra(`"`totalvarname'"', " +", " ")
	}
	
	if "`order'" != "" {
		foreach var in `order' {
			if !ustrregexm("`totalvarname'", "\b`var'\b") {
				disp as error "the variable `var' in order() do not exist"
				exit 198
			}
		}
	}
	
	local totalvarname = "`order' `totalvarname'"
	foreach name in `totalvarname' {
		if !ustrregexm(`"`listvarname'"', "\b`name'\b") {
			local listvarname = "`listvarname'`name' "
		}
	}
	
	if "`noconstant'" != "" {
		local listvarname = ustrregexra("`listvarname'", " _cons *$", "")
	}
		
	local colsnum = 1 + `num'
	local rowsnum = 2 + wordcount("`listvarname'")*2 + 1
	
	local top = 2
	if "`mtitle'" != "" {
		local rowsnum = `rowsnum' - 1
		local top = 1
	}
	
	if `tails' == 1 {
		forvalues i = 1/`num' {
			foreach tvar in `tailvars`i'' {
				if !index(`"`tailvar'"', `"`tvar'"') {
					local tailvar `"`tailvar'`tvar' "'
				}
			}
		}
		local rowsnum = `rowsnum' + 1 + `=wordcount(`"`tailvar'"')'*2
	}
	
	if `"`indicate'"' != "" {
		local rowsnum = `rowsnum' + `indicatenum'
	}
	
	if "`obs'" != "" {
		local rowsnum = `rowsnum' - 1
	}
	
	if "`f'" != "" | "`ffmt'" != "" {
		local rowsnum = `rowsnum' + 1
		if "`ffmt'" == "" local ffmt `bfmt'
	}
	
	if "`chi2'" != "" | "`chi2fmt'" != "" {
		local rowsnum = `rowsnum' + 1
		if "`chi2fmt'" == "" local chi2fmt `bfmt'	
	}
	
	if "`r2'" != "" | "`r2fmt'" != "" {
		local rowsnum = `rowsnum' + 1
		if "`r2fmt'" == "" local r2fmt `bfmt'
	}
	
	if "`ar2'" != "" | "`ar2fmt'" != "" {
		local rowsnum = `rowsnum' + 1
		if "`ar2fmt'" == "" local ar2fmt `bfmt'
	}
	
	if "`pr2'" != "" | "`pr2fmt'" != "" {
		local rowsnum = `rowsnum' + 1
		if "`pr2fmt'" == "" local pr2fmt `bfmt'
	}
	
	if "`aic'" != "" | "`aicfmt'" != "" {
		local rowsnum = `rowsnum' + 1
		if "`aicfmt'" == "" local aicfmt `bfmt'
	}
	
	if "`bic'" != "" | "`bicfmt'" != "" {
		local rowsnum = `rowsnum' + 1
		if "`bicfmt'" == "" local bicfmt `bfmt'
	}
		
	putdocx begin
	if `"`title'"' != "" {
		putdocx paragraph, spacing(after, 0)
		putdocx text (`"`title'"')
	}
	putdocx table regtbl = (`rowsnum', `colsnum'), border(all, nil) border(top) border(bottom) halign(center)
	putdocx table regtbl(`top',1), border(bottom)
	forvalues col = 1/`num' {
		if `top' == 1 {
			putdocx table regtbl(1, `=`col'+1') = ("(`col')"), border(bottom) halign(center)
		}
		else {
			putdocx table regtbl(1, `=`col'+1') = ("(`col')"), halign(center)
			putdocx table regtbl(2, `=`col'+1') = ("`mtitle`col''"), border(bottom) halign(center)
		}
	}
	
	local row = `top' + 1
	foreach var in `listvarname' {
		putdocx table regtbl(`row', 1) = ("`var'"), halign(left)
		local row = `row' + 2
		if `row' == `=`top' + wordcount("`listvarname'")*2 + 1' {
			putdocx table regtbl(`=`row' - 1', 1), border(bottom)
		}
	}
	
	if `tails' == 1 {
		putdocx table regtbl(`row', 1) = ("/"), halign(left)
		local row = `row' + 1
		forvalues i = 1/`=wordcount(`"`tailvar'"')' {
			putdocx table regtbl(`row', 1) = (`"`=word(`"`tailvar'"', `i')'"'), halign(left)
			local row = `row' + 2
			if `i' == `=wordcount(`"`tailvar'"')' {
				putdocx table regtbl(`=`row' - 1', 1), border(bottom)
			}
		}
	}
	
	if `"`indicate'"' != "" {
		forvalues i = 1/`indicatenum' {
			putdocx table regtbl(`row', 1) = (`"`indicatename`i''"'), halign(left)
			local row = `row' + 1
			if `i' == `indicatenum' {
				putdocx table regtbl(`=`row'-1', 1), border(bottom)
			}
		}
	}
	
	if "`obs'" == "" & "`obslast'" == "" {
		putdocx table regtbl(`row', 1) = ("N"), halign(left)
		local row = `row' + 1
	}
	else if "`obslast'" != "" {
		putdocx table regtbl(`rowsnum', 1) = ("N"), halign(left)
	}
	
	if "`f'" != "" | "`ffmt'" != "" {
		putdocx table regtbl(`row', 1) = ("F"), halign(left)
		local row = `row' + 1
	}
	
	if "`chi2'" != "" | "`chi2fmt'" != "" {
		putdocx table regtbl(`row', 1) = ("Chi2"), halign(left)
		local row = `row' + 1
	}
	
	if "`r2'" != "" | "`r2fmt'" != "" {
		putdocx table regtbl(`row', 1) = ("R-Square"), halign(left)
		local row = `row' + 1
	}
	
	if "`ar2'" != "" | "`ar2fmt'" != "" {
		putdocx table regtbl(`row', 1) = ("Adj.R-Square"), halign(left)
		local row = `row' + 1
	}
	
	if "`pr2'" != "" | "`pr2fmt'" != "" {
		putdocx table regtbl(`row', 1) = ("Pseudo.R-Square"), halign(left)
		local row = `row' + 1
	}
	
	if "`aic'" != "" | "`aicfmt'" != "" {
		putdocx table regtbl(`row', 1) = ("AIC"), halign(left)
		local row = `row' + 1
	}
	
	if "`bic'" != "" | "`bicfmt'" != "" {
		putdocx table regtbl(`row', 1) = ("BIC"), halign(left)
		local row = `row' + 1
	}
	
	local sigfmt = subinstr("`tfmt'`zfmt'", "`bfmt'", "", 1)
	if `sig' == 2 local sigfmt `sefmt'
	if `sig' == 4 local sigfmt `pfmt'
	forvalues col = 2/`=`num'+1' {
		local row = `top' + 1
		foreach var in `listvarname' {
			if !ustrregexm("`vars`=`col'-1''", "\b`var'\b") {
				local row = `row' + 2
				continue
			}
			local pvalue = scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`var'"), 4])
			local staroutput = ""
			local bstar = ""
			local tstar = ""
			forvalues i = 1/`levelnum' {
				if `pvalue' <= `siglevel`i'' & `pvalue' > `siglevel`=`i'+1'' {
					local staroutput `star_`i''
				}
			}
			if "`staraux'" == "" {
				local bstar `staroutput'
			}
			else {
				local tstar `staroutput'
			}
			if "`nostar'" != "" {
				local bstar = ""
				local tstar = "" 
			}
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `bfmt' scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`var'"), colnumb(table`=`col'-1',"b")])'", " ", "", .)'`bstar'"'), halign(center)
			putdocx table regtbl(`=`row'+1', `col') = (`"`tleft'`=subinstr("`: disp `sigfmt' scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`var'"), `sig'])'", " ", "", .)'`tright'`tstar'"'), halign(center)
			local row = `row' + 2
		}
		putdocx table regtbl(`=`top' + wordcount("`listvarname'")*2', `col'), border(bottom)
						
		if `tails' == 1 {
			local row = `row' + 1
			foreach tvar in `tailvar' {
				if !index("`tailvars`=`col'-1''", "`tvar'") {
					local row = `row' + 2
					continue
				}
				local tvarse = scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 2])
				if scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 3]) < . local tvart = scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 3])
				else local tvart = scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`var'"), 1])/`tvarse'
				if scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 3]) < . local tvarz = scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 3])
				else local tvarz = scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`var'"), 1])/`tvarse'
				if scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 4]) < . local tvarpvalue = scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 4])
				else local tvarpvalue = ttail(`df_m`=`col'-1'', `tvart')
				local staroutput = ""
				local bstar = ""
				local tstar = ""
				forvalues i = 1/`levelnum' {
					if `tvarpvalue' <= `siglevel`i'' & `tvarpvalue' > `siglevel`=`i'+1'' {
						local staroutput `star_`i''
					}
				}
				if "`staraux'" == "" {
					local bstar `staroutput'
				}
				else {
					local tstar `staroutput'
				}
				if "`nostar'" != "" {
					local bstar = ""
					local tstar = "" 
				}
				putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `bfmt' scalar(table`=`col'-1'[rownumb(table`=`col'-1',"`tvar'"), 1])'", " ", "", .)'`bstar'"'), halign(center)
				local tsig = `tvart'
				if `sig' == 2 local tsig = `tvarse'
				if `sig' == 4 local tsig = `tvarpvalue'
				putdocx table regtbl(`=`row'+1', `col') = (`"`tleft'`=subinstr("`: disp `sigfmt' `tsig''", " ", "", .)'`tright'`tstar'"'), halign(center)
				local row = `row' + 2
			}
			putdocx table regtbl(`=`row'-1', `col'), border(bottom)
		}
		
		if `"`indicate'"' != "" {
			forvalues i = 1/`indicatenum' {
				putdocx table regtbl(`row', `col') = (`"`indicatelabel`i'_`=`col'-1''"'), halign(center)
				local row = `row' + 1
				if `i' == `indicatenum' {
					putdocx table regtbl(`=`row'-1', `col'), border(bottom)
				}
			}
		}
		
		if "`obs'" == "" & "`obslast'" == "" {
			putdocx table regtbl(`row', `col') = ("`N`=`col'-1''"), halign(center)
			local row = `row' + 1
		}
		else if "`obslast'" != "" {
			putdocx table regtbl(`rowsnum', `col') = ("`N`=`col'-1''"), halign(center)
		}
		
		if "`f'" != "" | "`ffmt'" != "" {
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `ffmt' `F`=`col'-1'''", " ", "", .)'"'), halign(center)
			local row = `row' + 1
		}
		
		if "`chi2'" != "" | "`chi2fmt'" != "" {
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `chi2fmt' `chi2`=`col'-1'''", " ", "", .)'"'), halign(center)
			local row = `row' + 1
		}
		
		if "`r2'" != "" | "`r2fmt'" != "" {
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `r2fmt' `r2`=`col'-1'''", " ", "", .)'"'), halign(center)
			local row = `row' + 1
		}
		
		if "`ar2'" != "" | "`ar2fmt'" != "" {
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `ar2fmt' `r2_a`=`col'-1'''", " ", "", .)'"'), halign(center)
			local row = `row' + 1
		}
		
		if "`pr2'" != "" | "`pr2fmt'" != "" {
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `pr2fmt' `r2_p`=`col'-1'''", " ", "", .)'"'), halign(center)
			local row = `row' + 1
		}
		
		if "`aic'" != "" | "`aicfmt'" != "" {
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `aicfmt' `aic`=`col'-1'''", " ", "", .)'"'), halign(center)
			local row = `row' + 1
		}
		
		if "`bic'" != "" | "`bicfmt'" != "" {
			putdocx table regtbl(`row', `col') = (`"`=subinstr("`: disp `bicfmt' `bic`=`col'-1'''", " ", "", .)'"'), halign(center)
			local row = `row' + 1
		}
	}
	
	if "`replace'" == "" & "`append'" == "" {
		putdocx save `using'
	}
	else {
		putdocx save `using', `replace'`append'
	}
end
