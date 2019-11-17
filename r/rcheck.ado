* Check sensitivity (robustness) of results under alternative model formulations.
* Kenneth L. Simons, June 2002, modified July 2002.
* Examples:
*   rcheck, command("regress y x1 x2 %X") addvars("x3|x4 x5 x6") check("x1>0; x2>x1")
*   rcheck, command("regress y x1 x2 %X") addvars("x3|x4 x5 x6") check("%p[x2]<.05")
*   rcheck, command("regress %Y x1 x2 %X") addvars("^y1|^y2|^y3 x3|x4 x5 x6") check("_b[x1]>0; _b[x2]>_b[x1]")
*   rcheck, command("regress %Y x1 x2 %X %V1") addvars("^y1|^y2|^y3 x3|x4 x5 x6") v1("%none|if age>50") check("_b[x1]>0; _b[x2]>_b[x1]")
* In programming this, it was important to keep Stata from chopping off strings with more than 80 characters.
* Hence string variables are never set using "=" because that chops off the ends of long strings, and Stata string functions like substr cannot be used.
program define rcheck
	version 7.0
	syntax , COmmand(string) CHeck(string) [Addvars(string) Display(string) Pvaltype(integer 0) v1(string) v2(string) v3(string) v4(string) v5(string) v6(string) v7(string) v8(string) v9(string)]
	
	* Check the display parameter.
	if "`display'" == "" {local display = "none"}
	else if "`display'" ~= "verbose" & "`display'" ~= "all" & "`display'" ~= "none" & "`display'" ~= "0" & "`display'" ~= "1" & "`display'" ~= "errors" {
		display in red "The display() option must be one of: verbose all none 0 1 errors"
		error 999
	}
	
	* What method should be used to compute any p-values?
	if `pvaltype' < 0 | `pvaltype' > 2 {
		di in red "The pvaltype() option must be 1 or 2, 1 for t-test (as in OLS) or 2 for asymptotic MLE."
		error 999
	}
	local com1 : word 1 of `command'
	local isType1 = index(" regress reg regr regre regres areg ", " `com1' ")
	local isType2 = index(" logit logistic probit clogit blogit ", " `com1' ")
	local isType2 = `isType2' | index(" bprobit glogit gprobit mlogit ologit oprobit ", " `com1' ")
	local isType2 = `isType2' | index(" tobit cnreg intreg heckprob ", " `com1' ")
	local isType2 = `isType2' | index(" poisson nbreg gnbreg stcox streg ", " `com1' ")
	* I haven't checked type for, among others: svyreg svyivreg heckman treatreg xtreg xtivreg xtabond xtlogit xtprobit xttobit xtintreg xtpois xtnbreg xtregar xtgee svyoprobit svymlogit svyologit svyintreg
	if `isType1' {
		local pValComputeMethod = 1
		if `pvaltype' == 2 {
			di in red "The pvaltype() option must be 1 for command: `com1'."
			error 999
		}
	}
	else if `isType2' {
		local pValComputeMethod = 2
		if `pvaltype' == 1 {
			di in red "The pvaltype() option must be 2 for command: `com1'."
			error 999
		}
	}
	else {local pValComputeMethod = `pvaltype'}  /* unknown compute method */
	
	* Break the check string into semicolon-separated parts.  Prepare each part.
	* Could be done more carefully in case user makes a mistake.
	tokenize "`check'", parse(";")
	local nChecks = 1
	local tokenNum = 1
	while "``tokenNum''" ~= "" {
		local true`nChecks' = 0
		local false`nChecks' = 0
		local missing`nChecks' = 0
		local unable`nChecks' = 0
		local min`nChecks' = .
		local max`nChecks' = .
		local sum`nChecks' = 0
		local checkOrigStr`nChecks' "``tokenNum''"
		rebuildCheckString , check("``tokenNum''") pvalcomputemethod(`pValComputeMethod')
		local check`nChecks' "$resultsCheck_rebuildCheckString"
		local nChecks = `nChecks' + 1
		local tokenNum = `tokenNum' + 1
		while "``tokenNum''" == " " | "``tokenNum''" == ";" {
			local tokenNum = `tokenNum' + 1  /* Skip past spaces and semicolons.  For example, if no spaces, the 2nd, 4th, etc. tokens can only be semicolons. */
		}
	}
	local nChecks = `nChecks' - 1
	
	* If added variables string was not supplied, use "%none" (to give 1 item for the repeat loops for analyses - 0 would yield no analyses) and don't try to do substitutions for %X or %Y in the command string.
	local avlen: length local addvars
	if `avlen' == 0 {
		local addvars "%none"
		local substForAddedVars = 0
	}
	else {local substForAddedVars = 1}
	
	* Ensure added variables string is delimited properly with single spaces between parts.
	* Space between parts, but no space around & or |, nor a space after ( nor before ).
	* Note that tokenize does not create a token for a space, but does create tokens for other parsing characters.
	tokenize "`addvars'", parse(" |&()")
	local addvars ""  /* This will be rebuilt from the tokens. */
	local prevA ""
	local a "`1'"
	local b "`2'"
	local bNum = 2
	while "`b'" ~= "" {
		if ("`prevA'" == "(" | "`prevA'" == "&" | "`prevA'" == "|" | "`prevA'" == "") | ("`a'" == ")" | "`a'" == "&" | "`a'" == "|") {
			* No space goes between these tokens.
			local addvars "`addvars'`a'"
		}
		else {
			* Need a space between the tokens.
			local addvars "`addvars' `a'"
		}
		local prevA "`a'"
		local a "`b'"
		local bNum = `bNum' + 1
		local b "``bNum''"
	}
	* Add the remainder of the string.
	if ("`prevA'" == "(" | "`prevA'" == "&" | "`prevA'" == "|" | "`prevA'" == "") | ("`a'" == ")" | "`a'" == "&" | "`a'" == "|") {
		* No space goes between these tokens.
		local addvars "`addvars'`a'"
	}
	else {
		* Need a space between the tokens.
		local addvars "`addvars' `a'"
	}
	
	* Go through each part of the additions string, parse it, and prepare to loop through configurations of added variables.
	* This cannot be programmed via recursion, because Stata has a limit of 32 nested programs running.
	local wNum = 0
	local nConfigurations = 1
	local addingSomeXVars = 0
	local addingSomeYVars = 0
	foreach w of local addvars {
		local wNum = `wNum' + 1
		* Determine or'ed parts.
		local w: subinstr local w "|" " ", all
		local nOredParts: word count `w'
		if `nOredParts' == 1 {
			* This contains only one ored part.  If it is not "%none" (possibly with spaces around it), then add an extra "%none" part.
			local wNoNone : subinstr local w "%none" "", all count(local numNonesInW)
			local wNoNonesNoSpaces : subinstr local wNoNone " " "", all
			local wNoSpacesNoNoneLen : length local wNoNonesNoSpaces
			if ~(`numNonesInW'==1 & `wNoSpacesNoNoneLen'==0) {
				local w "`w' %none"
			}
		}
		local w`wNum'Options: word count `w'
		local nConfigurations = `nConfigurations' * `w`wNum'Options'
		local oredNum = 0
		foreach oredPart of local w {
			local oredNum = `oredNum' + 1
			* This or'ed part describes a set of 0 or more variables to be added to the model.
			* Determine and'ed parts.  They will be stored in local variables.
			local d`wNum'p`oredNum' ""  /* Dependent variable(s) for wNum, oredNum. */
			local i`wNum'p`oredNum' ""  /* Independent variable(s) for wNum, oredNum. */
			local oredPart: subinstr local oredPart "&" " ", all
			foreach andedPart of local oredPart {
				if "`andedPart'" == "%none" {}  /* Add no variable. */
				else {
					local c1 = substr("`andedPart'", 1, 1)  /* This is ok even with more than 80 characters. */
					if "`c1'" == "^" {
						* This refers to a dependent variable.
						gettoken thecarat andedPartWithoutCarat : andedPart, parse("^")  /* Get the andedPart without the leading ^. */
						****local andedPartWithoutCarat = substr("`andedPart'", 2, .)  /* NEED TO FIX THIS TO WORK FOR MORE THAN 80 CHARS (TOKENIZE PARSING WITH ^). */
						if "`d`wNum'p`oredNum''" == "" {local d`wNum'p`oredNum' "`andedPartWithoutCarat'"}
						else {local d`wNum'p`oredNum' "`d`wNum'p`oredNum'' `andedPartWithoutCarat'"}
						local addingSomeYVars = 1
					}
					else {
						* This refers to an independent variable.
						if "`i`wNum'p`oredNum''" == "" {local i`wNum'p`oredNum' "`andedPart'"}
						else {local i`wNum'p`oredNum' "`i`wNum'p`oredNum'' `andedPart'"}
						local addingSomeXVars = 1
					}
				}
			}
		}
	}
	* Determine some numbers needed to loop through configurations below.
	local nW = `wNum'
	local prod = 1
	foreach i of numlist `nW'(-1)1 {
		local prodLater`i' = `prod'
		local prod = `prod' * `w`i'Options'
	}
	* Ensure that if X or Y variables are to be added, the command string includes "%X" or "%Y".
	local badCommandStr = 0
	if `substForAddedVars' & `addingSomeXVars' {
		local junk: subinstr local command "%X" "", all count(local xsubs)
		if `xsubs' == 0 {
			local badCommandStr = 1
			display in red "The command string must include %X where added independent variables are placed."
		}
	}
	if `substForAddedVars' & `addingSomeYVars' {
		local junk: subinstr local command "%Y" "", all count(local ysubs)
		if `ysubs' == 0 {
			local badCommandStr = 1
			display in red "The command string must include %Y where added dependent variables are placed."
		}
	}
	
	* Check the additional variations strings, V1 through V9, and prepare to use them.
	forval vnum = 1/9 {
		local len : length local v`vnum'
		if `len'==0 {
			local v`vnum'Count = 1
			local v`vnum'_1 "%V`vnum'"  /* If there are any %V1, %V2, etc., in the command string, they will just get replaced by themselves. */
		}
		else {
			tokenize "`v`vnum''", parse("|")
			local i = 1
			local len : length local `i'
			local partNum = 0
			while `len' > 0 {
				local tokenIsOr = "``i''" == "|"
				if `tokenIsOr' {
					* Skip this token, it's just an | separating parts.
					if `i'==1 {
						display in red "The v`vnum' option must not begin or end with the | symbol (use %none to mean nothing)."
						error 999
					}
					else if `prevTokenWasOr' {
						display in red "The v`vnum' option contains two | symbols with nothing in between; use %none to mean nothing."
						error 999
					}
				}
				else {
					* This token is some kind of variation.
					local tokenNoSpaces: subinstr local `i' " " "", all
					if "`tokenNoSpaces'" == "" {
						display in red "The v`vnum' option contains two | symbols with nothing in between; use %none to mean nothing."
						error 999
					}
					else if "`tokenNoSpaces'" == "%none" {
						local partNum = `partNum' + 1
						local v`vnum'_`partNum' = ""
					}
					else {
						local partNum = `partNum' + 1
						local v`vnum'_`partNum' "``i''"
					}
				}
				local i = `i' + 1
				local len : length local `i'
				local prevTokenWasOr = `tokenIsOr'
			}
			local v`vnum'Count = `partNum'
			if `partNum' == 0 {
				display in red "The v`vnum' option is ill-specified; put something before and after the | symbol!"
				error 999
			}
			if `tokenIsOr' {
				display in red "The v`vnum' option must not begin or end with the | symbol (use %none to mean nothing)."
				error 999
			}
			* Ensure the command string contains %V#.
			local junk: subinstr local command "%V`vnum'" "", all count(local vsubs)
			if `vsubs' == 0 {
				local badCommandStr = 1
				display in red "The command string must include %V`vnum' where variations in v`vnum'() are placed."
			}
			* If there was only one variant given, and it is not %none, assume another %none.
			if `v`vnum'Count'==1 {
				local variantLength : length local v`vnum'_1
				if `variantLength' > 0 {
					local v`vnum'Count = 2
					local v`vnum'_2 ""
				}
			}
		}
	}
	if `badCommandStr' {error 999}
	
	* Loop through configurations of added variables and run analyses for each.
	* This cannot be programmed via recursion, because Stata has a limit of 32 nested programs running.
	* There are nConfigurations different configurations to analyze.
	* So loop with configNum = 1 to nConfigurations.
	* For word wNum, let prodLater`wNum' denote the product of w`i'Options for i = wNum+1 to nW.
	* Then each time through the loop, use word wordNum's option number mod( int( (configNum - 1) / prodLater`wNum' ), w`wNum'Options ) + 1.
	forval v1Index = 1/`v1Count' {
		local commandMod1 : subinstr local command "%V1" "`v1_`v1Index''", all
	forval v2Index = 1/`v2Count' {
		local commandMod2 : subinstr local commandMod1 "%V2" "`v2_`v2Index''", all
	forval v3Index = 1/`v3Count' {
		local commandMod3 : subinstr local commandMod2 "%V3" "`v3_`v3Index''", all
	forval v4Index = 1/`v4Count' {
		local commandMod4 : subinstr local commandMod3 "%V4" "`v4_`v4Index''", all
	forval v5Index = 1/`v5Count' {
		local commandMod5 : subinstr local commandMod4 "%V5" "`v5_`v5Index''", all
	forval v6Index = 1/`v6Count' {
		local commandMod6 : subinstr local commandMod5 "%V6" "`v6_`v6Index''", all
	forval v7Index = 1/`v7Count' {
		local commandMod7 : subinstr local commandMod6 "%V7" "`v7_`v7Index''", all
	forval v8Index = 1/`v8Count' {
		local commandMod8 : subinstr local commandMod7 "%V8" "`v8_`v8Index''", all
	forval v9Index = 1/`v9Count' {
		local commandMod9 : subinstr local commandMod8 "%V9" "`v9_`v9Index''", all
	forval configNum = 1/`nConfigurations' {
		local dAdded = ""
		local iAdded = ""
		forval wNum = 1/`nW' {
			* Determine which dependent and independent variables to add.
			local optionNum = mod( int( (`configNum' - 1) / `prodLater`wNum'' ), `w`wNum'Options' ) + 1
			local dMore "`d`wNum'p`optionNum''"
			local iMore "`i`wNum'p`optionNum''"
			if "`dMore'" ~= "" {
				if "`dAdded'" == "" {local dAdded "`dMore'"}
				else {local dAdded "`dAdded' `dMore'"}
			}
			if "`iMore'" ~= "" {
				if "`iAdded'" == "" {local iAdded "`iMore'"}
				else {local iAdded "`iAdded' `iMore'"}
			}
		}
		* Add the variables to the model, if addedVars was not null.
		if `substForAddedVars' {
			local altCommandStep : subinstr local commandMod9 "%Y" "`dAdded'", all
			local alteredCommand : subinstr local altCommandStep "%X" "`iAdded'", all
		}
		else {
			local alteredCommand : subinstr local commandMod9 "%X" "%X", all  /* Added vars was null, so don't change the command string any further. */
		}
		* Run the model.
		if "`display'" == "verbose" {
			di
			di
			di in white `"`alteredCommand'"'
			di
			capture noisily `alteredCommand'
		}
		else {
			capture `alteredCommand'
		}
		if _rc ~= 0 {
			di in red "Error in command: `alteredCommand'"
			error _rc
		}
		* Check results.
		local didDisplay = 0
		forval checkNum = 1/`nChecks' {
			finalizeCheckStr , check("`check`checkNum''")
			capture local checkRes = $resultsCheck_finalizeCheckStr
			if _rc ~= 0 {
				local checkRes = "error in check or dropped variable(s)"
				local unable`checkNum' = `unable`checkNum'' + 1
			}
			else if `checkRes' == . {local missing`checkNum' = `missing`checkNum'' + 1}
			else {
				if `checkRes' == 1 {local true`checkNum' = `true`checkNum'' + 1}
				else if `checkRes' == 0 {local false`checkNum' = `false`checkNum'' + 1}
				local min`checkNum' = min(`min`checkNum'', `checkRes')
				local max`checkNum' = max(`max`checkNum'', `checkRes')
				local sum`checkNum' = `sum`checkNum'' + `checkRes'
			}
			if "`display'" == "verbose" | "`display'" == "all" | ("`display'" == "0" & "`checkRes'" == "0") | ("`display'" == "1" & "`checkRes'" == "1") | ("`display'" == "errors" & "`checkRes'" == "error in check or dropped variable(s)") {
				* Display information about the case just analyzed, if requested.
				if `didDisplay' == 0 {
					di
					if "`display'" ~= "verbose" {
						di in white `"`alteredCommand'"'
					}
					local didDisplay = 1
				}
				local checkStr = trim("`checkOrigStr`checkNum''")
				display in white "  `checkStr' : `checkRes'"
			}
		}
	} /* end forval configNum */
	} /* end forval v9Index */
	} /* end forval v8Index */
	} /* end forval v7Index */
	} /* end forval v6Index */
	} /* end forval v5Index */
	} /* end forval v4Index */
	} /* end forval v3Index */
	} /* end forval v2Index */
	} /* end forval v1Index */
	
	* Report results of checks under all model configurations and command variations.
	local nAnals = `nConfigurations'*`v1Count'*`v2Count'*`v3Count'*`v4Count'*`v5Count'*`v6Count'*`v7Count'*`v8Count'*`v9Count'
	if `nAnals'==1 {local wordEnding = "is"}
	else {local wordEnding = "es"}
	di
	di in green "Summary of checks (from `nAnals' statistical analys`wordEnding')"
	local lineLength = length("Summary of checks (from `nAnals' statistical analyses)")
	di in green _dup(`lineLength') "_"
	forval checkNum = 1/`nChecks' {
		local checkStr = trim("`checkOrigStr`checkNum''")
		local nOk = `nAnals' - `missing`checkNum'' - `unable`checkNum''
		if `nOk'>0 {local meanVal = `sum`checkNum'' / `nOk'}
		else {local meanVal = .}
		di in green "`checkStr':"
		di in green "  min=" `min`checkNum'' ", max=" `max`checkNum'' ", mean=" `meanVal' ", #0=`false`checkNum'', #1=`true`checkNum'', #.=`missing`checkNum'', #noncomputable=`unable`checkNum''"
	}
end


* The check string is an expression that the program should check after each statistical analysis.
* It may use the following: _b[varname], _se[varname], and e() results such as e(N), e(df_r), e(F), e(r2), e(r2_a).  (Type estimates list after a stat. analysis.)
* It may also use %p[expression], where expression is a variable name [or maybe in future a linear combination of variables (not using _b !)], to yield a 2-tailed p-value for the expression: 2 * (1 - normprob(abs(_b[expression] / _se[expression]))).
* If a variable name is included without _b, _se, etc., it is assumed to refer to _b[varname].
* In place of a variable name, "{varname1|varname2|...}" may be used to specify that the variable included in the statistical analysis as an independent var. should be used.
program define rebuildCheckString
	version 7.0
	syntax , CHeck(string) pvalcomputemethod(integer)
	
	* Replace variable names with _b[varname], if not already in that form.
	tokenize "`check'", parse("+-*/^()[]>=<~,&|{} ")  /* Tokenize the check string to be able to find variable names. */
	local check = ""  /* The check string will be rebuilt from the tokens. */
	local a ""
	local b ""
	local c "`1'"
	local d "`2'"
	local dNum = 2
	while "`c'"~= "" {
		* Check whether c is a numeric variable.
		capture confirm numeric variable `c'
		local cIsVar = _rc == 0
		* Check whether c is the beginning of {varname1|varname2|...}.
		if "`c'" == "{" {
			* This seems to be the beginning of a special part listing variables of which the one used in the statistical analysis should be used.
			* Could check that the internal format is correct and vars are numeric; not checked in this version of the program.
			local thisNum = `dNum'
			while "``thisNum''" ~= "}" {
				if "``thisNum''" == "" {
					di in red "In checks() option, { must be followed by variable names separated by commas and then by } but the } is missing."
					error 999
				}
				local c "`c'``thisNum''"  /* Build up the whole special part in c. */
				local thisNum = `thisNum' + 1
			}
			local c "`c'}"
			local dNum = `thisNum' + 1  /* Point at the word just past the closing } bracket. */
			local d "``dNum''"
			local cIsVar = 1
		}
		* Replace variable names with _b[varname], if not already in that form.
		if `cIsVar' & "`b'"~="[" & "`d'"~="]" & "`d'"~="(" {local c = "_b[`c']"}  /* Variable name without _b, _se, etc., assumed to mean _b[varname]. */
		* Replace %p[varname] with computation of p-value.
		if `cIsVar' & "`a'"=="%p" & "`b'"=="[" & "`d'"=="]" {
			if `pvalcomputemethod' == 1 {  /* suitable after OLS */
				local d "2*ttail(e(df_r), abs(_b[`c']/_se[`c']))"
			}
			else if `pvalcomputemethod' == 2 {  /* suitable after asymptotic MLE */
				local d "2*(1-normprob(abs(_b[`c']/_se[`c'])))"
			}
			else {
				di in red "The p-value type for this command is unknown; specify pvaltype(1) for t-test as in OLS or pvaltype(2) for asymptotic MLE."
				error 999
			}
			local a = ""
			local b = ""
			local c = ""
		}
		* Advance to next token.
		if "`a'" ~= "" {local check "`check'`a'"}
		local a "`b'"
		local b "`c'"
		local c "`d'"
		local dNum = `dNum' + 1
		local d "``dNum''"
		while "`d'" == " " {  /* Leave out spaces.  Actually this will never happen because Stata doesn't include spaces as tokens. */
			local dNum = `dNum' + 1
			local d "``dNum''"
		}
	}
	local check "`check'`a'`b'"
	
	* In future could detect if check string has form lincom1 <|> lincom2 and if so check both the condition and its significance.
	
	* Return the rebuilt check string.
	global resultsCheck_rebuildCheckString "`check'"
end

* After running a statistical analysis, substitute the correct variable name in place of {...} (see the notes above rebuildCheckString).
program define finalizeCheckStr
	version 7.0
	syntax , check(string)
	tokenize "`check'", parse("{}")
	local newCheckStr = ""
	local i = 1
	while "``i''" ~= "" {
		if "``i''" == "{" {
			local j = `i' + 2
			if "``j''" ~= "}" {
				di in red "Unable to interpret {} in check: `check'"
				exit 999
			}
			local j = `i' + 1
			chooseVarInModel , v("``j''")
			local addPart "$resultsCheck_chooseVarInModel"
			local i = `i' + 2
		}
		else {
			local addPart = "``i''"
		}
		local newCheckStr "`newCheckStr'`addPart'"
		local i = `i' + 1
	}
	global resultsCheck_finalizeCheckStr "`newCheckStr'"
end

* From a comma-separated list of variable names, choose the (first) one that was used in the statistical analysis just carried out.
program define chooseVarInModel
	version 7.0
	syntax , v(string)
	* Tokenize the |-separated list of variable names.
	tokenize "`v'", parse("|")
	* Get the independent variable names.
	matrix b = e(b)
	local bnames : colnames(b)
	local nB : word count `bnames'
	* Find the first variable name that was used in the model.
	local i = 1
	local keepGoing = 1
	while `keepGoing' {
		forvalues bWordNum = 1/`nB' {  /* Loop through each word in bnames, and check if it equals the variable name in question.  Can't use the index function because it's limited to 80 chars. */
			local thisBName : word `bWordNum' of `bnames'
			if "`thisBName'" == "``i''" {
				global resultsCheck_chooseVarInModel = "``i''"
				local keepGoing = 0
				continue, break
			}
		}
		if "``i''" == "" {
			* No listed variable was used in the model.
			global resultsCheck_chooseVarInModel = "."
			local keepGoing = 0
			**di in red "Problem in check involving {`v'} - no listed variable used in model !"
			**error 999
		}
		local i = `i' + 1
	}
end
