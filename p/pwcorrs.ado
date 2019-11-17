*! version 1.8.2  23 April 1996 Fred Wolfe   STB-49 sg64.1
/* developed after Stata pwcorr and Stata spearman. This version
   allows calls to a Spearman OR a Pearson routine. It optionally allows
   a shortened variable column list and a full variable row list. String
   variables are not processed. Sorting is optional for the entire list or
   for the variables not selected in the shortened column list. Specific
	 variables or range of variables can be selected for processing
*/
program define pwcorrs
	version 5.0
	local varlist "opt min(2)"
	local if "opt"
	local in "opt"
	local weight "aweight fweight"
	#delimit ;
	local options "Bonferroni Obs Print(real -1) SIDak SIG CWDeletion
		STar(real -1) Vars(int 0) Above(real 0) SORt SPearman
		SElect(string)";
	#delimit cr
	parse "`*'"
	parse "`varlist'", parse(" ")
	local weight "[`weight'`exp']"

	if "`spearman'" != "" & "`exp'" != ""{
			di in red "weights not allowed in Spearman procedure"
			exit 101
	}

  /* Lengthen obs if required for sort and replace */

  preserve
  local length = _N
	local nvar : word count `varlist'
  if `length' <= (`nvar' + 2){
  	local length = `nvar' + 2
		qui set obs `length'
	}
  local length = `nvar' + 2

  local sortchr = "zzzzzzzz"
	/* this section drops out string variables */
	tempvar sortbin
	qui gen str8 `sortbin' = "`sortchr'"
	local i 1
	local n 1
	while  "``i''" != "" {
        	capture confirm str variable ``i''
        	if _rc != 0{
        		local tmplist "`tmplist' ``i''"
			qui replace `sortbin' = "``i''" in `n'
			local n = `n' + 1
        	}
        	local i = `i' + 1
	}
	local nvar : word count `tmplist'

        /* begin duplicate check & removal */
	local i 1
	local iplus = 2
	while `i' <= _N {
	  	qui replace `sortbin' = "`sortchr'" in `iplus'/ `length' /*
      */ if `sortbin' == `sortbin'[`i']
		local i = `i' + 1
		local iplus = `iplus' + 1
		if `i' > `nvar' +1{
			local i = _N + 1
		}
	}

	/* select section */

	tempvar touse
	qui gen int `touse' = .
	local sellist = lower(trim("`select'"))
	local i 1
	if (substr("`sellist'", 1,1) == "-" | /*
		*/ substr("`sellist'",length("`sellist'"),1) == "-") | /*
		*/ index("`sellist'", "--") != 0{
		di in red "error in - specification"
		exit
	}

	while `i' <= length("`sellist'"){
		local r 1
		if substr("`sellist'", `i',1) == "_" |  /*
		*/ substr("`sellist'", `i',1) == "-" |  /*
		*/ (substr("`sellist'", `i',1) >="a" &  /*
		*/ substr("`sellist'", `i',1) <= "z") | /*
		*/ (substr("`sellist'", `i',1) >="0" &  /*
		*/ substr("`sellist'", `i',1) <= "9"){

		  	while `r' <= `nvar'{
				if `i' != 1 & substr("`sellist'", `i'-1,1) == "-"{
					if substr(`sortbin'[`r'],1,1) >=  substr("`sellist'", `i'-2,1) /*
					*/ &  substr(`sortbin'[`r'],1,1) <=  substr("`sellist'", `i',1){
						qui replace `touse' = 1 in `r' if `sortbin'[`r'] != "`sortchr'"
			}
			}
				else if substr(`sortbin'[`r'],1,1) ==  substr("`sellist'", `i',1){
					qui replace `touse' = 1 in `r' if `sortbin'[`r'] != "`sortchr'"
				}
				local r = `r' + 1
			}
		}
		local i = `i' + 1
	}
	if "`sellist'" !=""{
		if `vars' == 0{
			qui replace `sortbin' = "`sortchr'" if `touse' == .
		}
			else{
				local sortnum = `vars' + 1
				qui replace `sortbin' = "`sortchr'" if `touse' == . in `sortnum'/l
			}
	}


	/* sort section */

	if "`sort'" != ""{
		if `vars' == 0{
			sort `sortbin'
		}
			else{
				local sortnum = `vars' + 1
				sort `sortbin' in `sortnum'/l
			}
		}


	/* move data into final varlist */

		qui replace `sortbin' = "" if `sortbin' == "`sortchr'"
		local tmplist
		local i 1
		while `i' <= `length'{
			if `sortbin'[`i'] != "`sortchr'"{
				local tvar = `sortbin'[`i']
				local tmplist "`tmplist'" "`tvar'" " "
				local i = `i' + 1
			}
		}

	local varlist `tmplist'


	/* pass data to sub programs */

	if "`spearman'" != ""{
		di _col(28) "Spearman Correlations"
	}
	else {di _col(28) "Pearson Correlations"}

	#delimit ;
	corrsub `tmplist' "`if'" "`in'" "`weight'", "`bonferroni'" "`obs'"
	print(`print') "`sidak'" "`sig'" vars(`vars') above(`above')
	 star(`star') "`spearman'" "`cwdeletion'" ;
	#delimit cr

end

program define corrsub
	version 5.0
	local varlist "opt min(2)"
	local if "opt"
	local in "opt"
	local weight "aweight fweight"
	#delimit ;
	local options "Bonferroni Obs Print(real -1) SIDak SIG cwdeletion
		STar(real -1) Vars(int 0) Above(real 0) Spearman ";
	#delimit cr
	parse "`*'"
	parse "`varlist'", parse(" ")
	local weight "[`weight'`exp']"

	local nvar : word count `varlist'

	/* casewise delation section */
	if "`cwdeletion'" != ""{
		tempvar delvar
		qui egen `delvar' = rmiss("`varlist'")
		qui drop if `delvar' > 0
		di "(n=" _N ")"
	}


	if `above' != 0 & `print' != -1{
		#delimit ;
		di in red "above and print cannot be specified
		 at the same time";
		#delimit cr
		exit 198
	}

	if `vars' != 0{
		if `vars' <1 | `vars' > 6{
			di in red "vars must be an integer between 1 and 6"
			exit 198
		}
		if `vars' > `nvar'{
			di in red "vars must be <= number of variables(" `nvar' ")"
			exit 198
		}

		local wvar = `vars'
	}
	else local wvar = `nvar'

	local adj 1
	if "`bonferr'" != "" | "`sidak'" != "" {
		if `vars' == 0{
			local nrho = ((`nvar'*(`nvar'-1))/2)
			}
			else{
				#delimit;
				local nrho = ((`nvar'*(`nvar'-1))/2) -(((`nvar'-`vars')
				*(`nvar'-`vars'-1))/2);
		      #delimit cr
				}
		if "`bonferr'" != "" { local adj `nrho' }
	}
	if (`star' >= 1) {
		local star = `star'/100
		if `star' >= 1 {
			di in red "star() out of range"
			exit 198
		}
	}
	if (`print' >= 1) {
		local print = `print'/100
		if `print' >= 1 {
			di in red "print() out of range"
			exit 198
		}

	}
	local j0 1
	while (`j0' <= `wvar') {
		di
		local j1 = min(`j0'+6,`wvar')
		local j `j0'
		di in gr "          |" _c
		while (`j' <= `j1') {
			local l = 9-length("``j''")
			di in gr _skip(`l') "``j''" _c
			local j = `j'+1
		}
		local l = 9*(`j1'-`j0'+1)
		di in gr _n "----------+" _dup(`l') "-"

		local i `j0'
		while `i' <= `nvar' {
			local l = 9-length("``i''")
			di in gr _skip(`l') "``i'' | " _c
			local j `j0'
			while (`j' <= min(`j1',`i')) {
				if "`spearman'" != ""{
					qui spearman ``i'' ``j'' `if' `in'
				}
				else {
					qui corr ``i'' ``j'' `if' `in' `weight'
				}
				local c`j' = _result(4)
				local n`j' = _result(1)
				local p`j' = min(`adj'*tprob(_result(1)-2,/*
				*/ _result(4)*sqrt(_result(1)-2)/ /*
				*/ sqrt(1-_result(4)^2)),1)
				if "`sidak'" != "" {
					local p`j' = min(1,1-(1-`p`j'')^`nrho')
				}
				local j = `j'+1
			}
			local j `j0'
			while (`j' <= min(`j1',`i')) {
				if `p`j'' <= `star' & `i' != `j' {
					local ast "*"
				}
				else local ast " "
				if `above' != 0{
					if abs(`c`j'') >= `above' {
						di " " %7.4f `c`j'' "`ast'" _c
					}
					else di _skip(9) _c
				}
				if `above' == 0{
					if `p`j'' <= `print' | `print' == -1 |`i' == `j' {
						di " " %7.4f `c`j'' "`ast'" _c
					}
					else 	di _skip(9) _c
				}

				local j = `j'+1
			}
			di
			if "`sig'" != "" {
				di in gr "          |" _c
				local j `j0'
				while (`j' <= min(`j1',`i'-1)) {
					if `p`j'' <= `print' | `print' == -1 {
						di "  " %7.4f `p`j'' _c
					}
					else	di _skip(9) _c
					local j = `j'+1
				}
				di
			}
			if "`obs'" != "" {
				di in gr "          |" _c
				local j `j0'
				while (`j' <= min(`j1',`i')) {
					if `p`j'' <= `print' | `print' == -1 /*
					*/ |`i' == `j' {
						di "  " %7.0g `n`j'' _c
					}
					else	di _skip(9) _c
					local j = `j'+1
				}
				di
			}
			if "`obs'" != "" | "`sig'" != "" {
				di in gr "          |"
			}
			local i = `i'+1
		}
		local j0 = `j0'+7
	}
end