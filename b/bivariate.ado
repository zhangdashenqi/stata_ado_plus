program define bivariate, rclass
*!	bivariate.ado Version 2.2 by Mead Over, CGD, 9Feb2016
	version 11.1
	syntax varlist(fv) [if] [in] [fweight  aweight  pweight  iweight] ,  ///
		[ Depvar(varname) Matrix(name) ROWnames(string) noVIF UNCentered List  ///
		Tabstat Format Format2(str) addstat(string)  ///  The -addstat- option can enhance tabstat
		OBSGain GROUPSTats(string) group(varname) nowide ]  
		//	-obsgain- Requests -bivariate to add a column giving the number of observations
		//  that could be added to the analyis if this variable were dropped from the right-hand-side
	
	marksample touse
		sum `touse', meanonly
		local dropped = _N - `r(sum)'
		local nobs = `r(sum)'
	
	if "`depvar'"=="" {  // Default is that the first variable is the dependent variable
		local depvar = word("`varlist'", 1)
		local varlist : list varlist - depvar
	}
	if "`varlist'"=="" {
		di as err _n "Program requires a dependent variable and at least one independent variables."
		exit 198
	}
	
	if "`wide'" =="nowide" {
		local wide
	}
	else {
		local wide wide
	}

	//	Following lines of code assures that each value of any discrete variable is
	//	separately related to the dependent variuable.  Requires Stata version 11.1
	local varlist = subinstr("`varlist'","i.","ibn.",.)

	//  Unless the -list- option is specified, 
	//	this command keeps all dummies, so that 
	//  the resulting varlist does not have full rank.
	fvrevar `varlist' if `touse', `list'
		local varlist `r(varlist)'
	
	//	Remove the collinear variables, restoring full-rank
	if "`list'"=="" {
		_rmcoll `varlist', forcedrop		
		local varlist `r(varlist)'
	}

	foreach rhsvar of varlist `varlist' {
		if strmatch("`rhsvar'","__??????") {
			sum `rhsvar', meanonly
				local max = `r(max)'
			local rhsname : char `rhsvar'[fvrevar]
			
			//	Label the values of the dummies created from the factor variables
			local dotpos = strpos("`rhsname'",".")
			local beforedot = substr("`rhsname'",1,`dotpos'-1)
			local afterdot = substr("`rhsname'",`dotpos'+1,.)
			local bpos = strpos("`beforedot'","b")
			if `bpos' == 0 {
				local bpos = .
			}
			else {
				local bpos = `bpos' - 1
			}
			local rhsval = real(substr("`beforedot'",1,`bpos'))
			if `rhsval'~=. {
				local origlbl : label (`afterdot') `rhsval'
				tempname `rhsvar'lbl
				label define ``rhsvar'lbl' `max' `"`origlbl'"'
				label values `rhsvar' ``rhsvar'lbl'
			}
		}
		else {
			local rhsname `rhsvar'
		}
		local expvarlist `expvarlist' `rhsname'
	}

	if "`vif'"~="novif" {
		qui _regress `depvar' `varlist' if `touse' [`weight' `exp']
		qui estat vif , `uncentered'
		getvif
		tempname vifmat
		mat def `vifmat' = r(vifmat)
		return scalar meanvif = `r(meanvif)'
		return scalar maxvifval = `r(maxvifval)'
		return local maxvifvar `r(maxvifvar)'
		if "`uncentered'"=="uncentered" {
			local viftype "Uncentered"
		}
		else {
			local viftype "Centered"
		}
	}
	else {
		if "`uncentered'"~="" {
			di as err "Option -uncentered- is incompatible with option -novif-"
			exit 198
		}
		local viftype "Suppressed"
	}

	if "`matrix'"=="" {
		local matrix bivariate
	}
	tempname `matrix'
	if "`format'" != "" & `"`format2'"' != "" {  
		di as err "may not specify both format and format()"
		exit 198
	}
	if `"`format2'"' != "" {
		capt local tmp : display `format2' 1
		if _rc {
			di as err `"invalid %fmt in format(): `format2'"'
			exit 120
		}
		local format2 format(`format2')
	}
	if `"`format'"' != "" {
		local format format(%9.3f)
	}
	
	local everdummy = 0
	di _n as txt "Summary of the bivariate relationships between the dependent variable: " as res "`depvar'"
	di as txt " and each of the independent variables: " as res "`expvarlist'"
	if `dropped' > 0 {
		di _n as txt "Casewise deletion deletes : " as res "`dropped'" as txt " observations."
	}
	di _n as txt "The analysis uses : " as res "`nobs'" as txt " observations."
	di    as txt "The variance inflation factor is: " as res "`viftype'"
	
	if "`rownames'"~="" {
		if ~("`rownames'"=="varname" | "`rownames'"=="eqname" | "`rownames'"=="none") {
			di _n as err "The rownames() option must contain one of the following three strings:"
			di    as res "    varname" as err " if the label of the larger value of each dummy variable is used as its row name"
			di    as res "    eqname" as err " if the label of the larger value of each dummy variable is used as its equation name"
			di    as res "    none" as err " if dummy variable value labels are ignored, equation names remain blank"
			di    as err "                      and the rownames are the variable names."
			exit 198
		}
	}

	//	Add a column giving number of observations to be gained 
	//	if the variable in that row were dropped from the analysis
	local maxobsgain = 0
	local i = 1
	foreach rhsvar of varlist `varlist' {
		if strmatch("`rhsvar'","__??????") {
			local rhsname : char `rhsvar'[fvrevar]
		}
		else {
			local rhsname `rhsvar'
		}
		qui levelsof `rhsvar' if `touse'
			local ncat : word count `r(levels)'

		if "`weight'"=="" {
			qui sum `rhsvar'  if `touse'
				local mean = r(mean)
				local sd = r(sd)
					local min = r(min)
					local max = r(max)
		}
		else {
			qui sum `rhsvar'  if `touse' [aweight `exp']
				local mean = r(mean)
				local sd = r(sd)
					local min = r(min)
					local max = r(max)
		}
		if `ncat'==2 {  // Treat this independent variable as a dummy variable
			if ~(`max' == 1 & `min' == 0) {
				di _n as err "Warning: The variable " as res "`rhsvar'" as err " has only two values: " as res "`min'" as err " and " as res "`max'"
				di    as err "Should it be recoded as a dummy variable with values 0 and 1 ?"
			}
			local lbl0 : label (`rhsvar') `min'
			local lbl1 : label (`rhsvar') `max'   //  Assumes that the label of the larger value is the condition
				// Replaces characters that are unacceptable in a matrix row or column name
				local lbl1 = subinstr("`lbl1'", ">", "GT",1)
				local lbl1 = subinstr("`lbl1'", ">=", "GE",1)
				local lbl1 = subinstr("`lbl1'", "<", "LT",1)
				local lbl1 = subinstr("`lbl1'", "<=", "LE",1)
				local lbl1 = subinstr("`lbl1'", ".", "%",1)
				local lbl1 = subinstr("`lbl1'", ".", "%",1)
				local pcnt = substr("`lbl1'",strpos("`lbl1'","%")+1,2)
				local lbl1 = subinstr("`lbl1'","%`pcnt'","`pcnt'%",1)
				local lbl1 = "`max'=" + "`lbl1'"
			qui ttest `depvar'  if `touse', by(`rhsvar')
				local mu_1 = `r(mu_1)'
				local mu_2 = `r(mu_2)'
				local t = -`r(t)'
				local p = `r(p)'
			local rho = .
			local everdummy = 1
		}
		else {
			qui _regress `depvar' `rhsvar'  if `touse' [`weight' `exp']
				local rho = sign(_b[`rhsvar'])*sqrt(e(r2))
				local t = sign(_b[`rhsvar'])*sqrt(e(F))
				local p = Ftail(e(df_m), e(df_r), e(F))
				local pcnt1 = .
			local mu_1 = .
			local mu_2 = .
			local lbl1 "Continuous"
		}
		
		if "`obsgain'"~="" {
			local wothisone : list expvarlist - rhsname

			qui _regress `depvar' `wothisone' `if' `in'
				local obsplus = `e(N)' - `nobs'

				if `obsplus' > 0 {
					di as txt "Without the variable " as res "`rhsname'" as txt " nobs is: " `e(N)'
				}
				local comma_og , `obsplus'
			if `obsplus' > `maxobsgain' {
				local maxobsgain = `obsplus'
				local maxobsgainvar `rhsname'
			}
			local obsgaincolname `""Obs Gained""'
		}
		
		if "`vif'"~="novif" {
			local rn = rownumb(`vifmat',"`rhsvar'")
			local vifval = el(`vifmat',`rn',1)
			mat def ``matrix'' = (	nullmat(``matrix'') \   ///
								`rho', `mu_1', `mu_2', `t', `p', `vifval' `comma_og')
		}
		else {
			mat def ``matrix'' = (	nullmat(``matrix'') \   ///
								`rho', `mu_1', `mu_2', `t', `p' `comma_og')
		}
	
		if "`rownames'"=="" | "`rownames'"=="none" {
			local rownms`i' `rownms`i'' `rhsname'
		}
		else {
			local lbl1 = subinstr(`"`lbl1'"'," ","_",.)
			if "`rownames'"=="varname" {
				local rownms`i' `rownms`i'' `"`lbl1'"' 
				local eqns `eqns' `rhsname'	
			}
			if "`rownames'"=="eqname" {
				if `"`lbl1'"'=="Continuous" {
					local rownms`i' `rownms`i'' `rhsname'
					local eqns `eqns' `"`lbl1'"'
				}
				else {
					if strpos("`rhsname'",".") {
						local dotpos = strpos("`rhsname'",".")
						local afterdot = substr("`rhsname'",`dotpos'+1,.)
						local rhsname `afterdot'
					}
					local rownms`i' `rownms`i'' `"`lbl1'"' 
					local eqns `eqns' `rhsname'	
				}
			}
		}

		if length(`"`rownms`i''"')> 210 {
			local i = `i' + 1
			if `i' > 5 {
				di as err "Too many variables for program -bivariate-"
				exit 198
			}
		}
	}
	
	mat roweq   ``matrix'' = `eqns'
	mat rownames ``matrix'' = `rownms1' `rownms2' `rownms3' `rownms4'  `rownms5' 
	if "`vif'"~="novif" {
		mat colnames ``matrix'' =  "Correlation" "For D=0" "For D=1" "t-stat" "p-value" "VIF" `obsgaincolname'
		return matrix vifmat = `vifmat'
	}
	else {
		mat colnames ``matrix'' =  "Correlation" "For D=0" "For D=1" "t-stat" "p-value" `obsgaincolname'
	}
	if `everdummy'==0 {  // If there are no dummy variables, delete the columns 2 and 3.
		tempname col1 cols45
		mat def col1   = ``matrix''[1...,"Correlation"]
		mat def cols45 = ``matrix''[1...,"t-stat"...]
		mat def ``matrix'' = col1 , cols45
	}
	
	di _n(2) as txt "Bivariate table for the dependent variable: " as res "`depvar'"
	matlist  ``matrix'', noheader `format2'

	if "`obsgain'"~="" {
		return scalar maxobsgain = `maxobsgain'
		return local maxobsgainvar `maxobsgainvar'
	}

	return scalar N = `nobs'
	return matrix `matrix' = ``matrix''

	di as txt  ///
		_n "If Gallup's -frmttable- is installed, click here:"
	di as txt "    {stata frmttable , statmat(r(`matrix')) } "

	//	Produce the descriptive statistics output
	if "`tabstat'"~="" {
		di _n as txt "Option -tabstat-:"  ///
			_n "Descriptive statistics on the dependent and the independent variables: "
		qui tabstat `depvar' `varlist' if `touse' [`weight' `exp'], s(mean median sd cv min max skewness `addstat') columns(stat) `format' `format2' save
		tempname StatTotal TransposedST
		matrix define `StatTotal' = r(StatTotal)
		mat colnames `StatTotal' = `depvar' `rownms1' `rownms2' `rownms3' `rownms4'  `rownms5' 
		matrix define `TransposedST' = `StatTotal''
		return matrix StatTotal = `StatTotal'
		matlist `TransposedST' , noheader `format2'
		
		di as txt  ///
			_n "If Gallup's -frmttable- is installed, click here:"
		di as txt "    {stata frmttable , statmat(r(TransposedST)) } "
		return matrix TransposedST = `TransposedST'
	}

	//	Produce the statistics by group using the discriminant analysis command
	if "`groupstats'`group'"~="" {
		grouptab`wide' `depvar' `varlist' if `touse' [`weight' `exp'], group(`group') groupstats(`groupstats') `format2'
		tempname grouptab
		tempname frmttable
		mat define `grouptab' = r(grouptab)
		mat define `frmttable' = r(frmttable)
		if "`wide'" ~= "" {
			return local statlist `r(statlist)'
			return local N_stats  `r(N_stats)'
			return matrix frmttable = `frmttable'
		}
		return matrix grouptab = `grouptab'
	}

end	//	End of program bivariate

program define getvif, rclass
* Based on program maxvif   Version 1.0  by Mead Over, May 4, 2012
	if "`r(name_1)'`r(vif_1)'" == "" {
		di as err "This command must be executed immediately after the command -" as txt "estat vif" as err "-"
		exit 198
	}
	tempname vifmat
	tempname sumvif
	scalar `sumvif' = 0
	local i = 1
	local j = 1
	local maxvif = -99999999999999999999
	while "`r(name_`i')'`r(vif_`i')'" ~= "" {
	
		scalar `sumvif' = `sumvif' + `r(vif_`i')'

		if `r(vif_`i')'>`maxvif' {
			local maxvif = `r(vif_`i')'
			local maxvifvar `r(name_`i')'
		}
		
		mat `vifmat' = (nullmat(`vifmat') \ `r(vif_`i')' )
		
		local rownames`j' = "`rownames`j'' " + "`r(name_`i')'"
		
		while length("`rownames`j''")> 220 {
			local j = `j' + 1
			if `j' > 5 {
				di as err "Too many variables for program -bivariate-"
				exit 198
			}
		}

		local i = `i' + 1
	}
	matrix colnames `vifmat' = "VIF"
	matrix rownames `vifmat' = `rownames1' `rownames2' `rownames3' `rownames4' `rownames5'
	return matrix vifmat = `vifmat'
	return scalar meanvif = `sumvif'/(`i'-1)
	return scalar maxvifval = `maxvif'
	return local maxvifvar `maxvifvar'		
	return local viftype `viftype'
end  /* End of program getvif */

program define grouptab, rclass
	//	Produce the statistics by group using the discriminant analysis command
	//	Arrange the results matrix in long format
	syntax varlist [if] [in] [fweight aweight pweight iweight][, groupstats(string) group(varname) format(string)]  

	if "`format'"~="" {
		local format format(`format')
	}
	local i = 1
	if "`groupstats'`group'" ~= "" {
		if "`group'" == "" {
			di as err _n "Option -groupstats- selected, but no -group- variable designated."
			exit 198
		}
		if "`groupstats'" == "" {
			local groupstats n mean
		}
		qui discrim lda `varlist' `if' [`weight' `exp'], group(`group')
			local N_groups = e(N_groups)
			local N_vars = e(k)
		estat grsumma, `groupstats'
		local matlist 
		local statlist
		local N_stats = 0
		foreach stat0 in `groupstats' {
			tempname `stat0'_mat
			if "`stat0'" == "n" {
				local stat count
				mat define `n_mat' = r(`stat')
			}
			else {
				local stat `stat0'
				mat define ``stat'_mat' = r(`stat')
				local matlist `matlist' ``stat'mat'
				local statlist `statlist' `stat'
				local N_stats = `N_stats' + 1
			}
		}
		tempname grouptab	//	Name of the new matrix of group statistics
		foreach var of varlist `varlist' {
			local rowno = `rowno' + 1
			if strmatch("`var'","__??????") {
				local rhsname : char `var'[fvrevar]
			}
			else {
				local rhsname `var'
			}
			foreach stat in `statlist' {
				local thisrow
				local comma
				foreach cat of numlist 1/`N_groups' {
					local thisel = el(matrix(``stat'_mat'),`rowno',`cat')
					local thisrow `thisrow' `comma' `thisel'
					local comma ,
				}
				mat def `grouptab' = (	nullmat(`grouptab') \   `thisrow' )
				local grownms`i' `grownms`i'' `stat' 
				local geqnms`i' `geqnms`i'' `rhsname'	
			}
			if length("`grownms`i''")> 220 | length("`geqnms`i''")> 220 {
				local i = `i' + 1
				if `i' > 5 {
					di as err "Too many variables for option -group()- of program -bivariate-"
					exit 198
				}
			}
		}		
		mat rownames `grouptab' = `grownms1' `grownms2' `grownms3' `grownms4'  `grownms5' 
		mat roweq    `grouptab' = `geqnms1' `geqnms2' `geqnms3' `geqnms4'  `geqnms5' 
		local vlbl : value label `group'
		qui levelsof `group'
			local lvls `r(levels)'
		foreach grp of numlist 1/`N_groups' {
			if "`vlbl'"=="" {
				local gcolnms `gcolnms' Group`grp'
			}
			else {
				local thislvl : word `grp' of `lvls'
				local thislbl : label `vlbl' `thislvl'
				local gcolnms `gcolnms' `thislbl'
			}
		}
		mat colnames `grouptab' =  `gcolnms'
	}
	di _n as txt "Statistics by group available in the matrix r(grouptab)"
	matlist `grouptab', `format' noheader
	return matrix grouptab `grouptab'	//	Returns the long version of the grouptab matrix

	di as txt   ///
		_n "If Gallup's -frmttable- is installed, click here:"
	di as txt "    {stata frmttable , statmat(r(grouptab))} "

	return local statlist `statlist'
	return local N_stats = `N_stats'

end	//	End of program grouptab

program define grouptabwide, rclass
	//	Produce the statistics by group using the discriminant analysis command
	//	Arrange the results matrix in wide format
	syntax varlist [if] [in] [fweight aweight pweight iweight][, groupstats(string) group(varname) format(string)]  

	if "`format'"~="" {
		local format format(`format')
	}
	local i = 1
	if "`groupstats'`group'" ~= "" {
		if "`group'" == "" {
			di as err _n "Option -groupstats- selected, but no -group- variable designated."
			exit 198
		}
		if "`groupstats'" == "" {
			local groupstats n mean
		}

		qui discrim lda `varlist' `if' [`weight' `exp'], group(`group')
			local N_groups = e(N_groups)
			local N_vars = e(k)

		estat grsumma, `groupstats'  // This output provides group sizes
		local matlist 
		local statlist
		local N_stats = 0

		foreach stat0 in `groupstats' {
			tempname `stat0'_mat
			if "`stat0'" == "n" {
				local stat count
				mat define `n_mat' = r(`stat')
			}
			else {
				local stat `stat0'
				mat define ``stat'_mat' = r(`stat')
				local matlist `matlist' ``stat'mat'
				local statlist `statlist' `stat'
				local N_stats = `N_stats' + 1
			}
		}

		tempname grouptab	//	Name of the new matrix of group statistics
		local rowno = 0
		foreach var of varlist `varlist' {
			local rowno = `rowno' + 1
			if strmatch("`var'","__??????") {
				local rhsname : char `var'[fvrevar]
			}
			else {
				local rhsname `var'
			}
			local thisrow
			local comma
			foreach cat of numlist 1/`N_groups' {
*				foreach cat of numlist 1/`N_groups' {
				foreach stat in `statlist' {
					local colno = `colno' + 1
					local thisel = el(matrix(``stat'_mat'),`rowno',`cat')
					local thisrow `thisrow' `comma' `thisel'
					local comma ,
					local gcolnms`i' `gcolnms`i'' `stat' 
				}
			}
			mat def `grouptab' = (	nullmat(`grouptab') \   `thisrow' )
			local grownms`i' `grownms`i'' `rhsname' 
			if length("`grownms`i''")> 220 ///
				| length("`gcolnms`i''")> 220 ///
				| length("`geqnms`i''")> 220 {
				local i = `i' + 1
				if `i' > 5 {
					di as err "Too many variables for option -group()- of program -bivariate-"
					exit 198
				}
			}
		}		

		local vlbl : value label `group'
		qui levelsof `group'
			local lvls `r(levels)'
		foreach grp of numlist 1/`N_groups' {
			foreach stat in `statlist' {
				local gcolnms `gcolnms' `stat'
				if "`vlbl'"=="" {
					local geqnms `geqnms' Group`grp'
				}
				else {
					local thislvl : word `grp' of `lvls'
					local thislbl : label `vlbl' `thislvl'
					local geqnms `geqnms' `thislbl'
				}
			}
		}
		
		mat rownames `grouptab' = `grownms1' `grownms2' `grownms3' `grownms4'  `grownms5' 
		mat colnames `grouptab' = `gcolnms'
		mat coleq    `grouptab' = `geqnms'
	}
	tempname frmttable
	mat define `frmttable' = `grouptab'
	mat coleq    `frmttable' = _:  			//	Blanks out the equation names to create
	mat colnames `frmttable' = `geqnms'		//	a matrix for the frmttable command

	di _n as txt "Statistics by group available in the matrix r(grouptab)"
	matlist `grouptab', `format' noheader
	return matrix grouptab `grouptab'	//	Returns the wide version of the grouptab matrix	
	return matrix frmttable `frmttable'
	local N_substats = `N_stats' - 1
	di as txt  ///
		_n "If Gallup's -frmttable- is installed, click on one of the following links:"
	di as txt "    {stata frmttable , statmat(r(grouptab))} "
	di as txt "    {stata frmttable , statmat(r(frmttable)) note(Statistics are -- `statlist') substat(`N_substats')} "
	return local statlist `statlist'
	return local N_stats = `N_stats'
end	//	End of program grouptabwide

*	Version 1.1 adds the estat vif column
*	Version 1.2 incorporates factor variables
*	Version 1.3 change the sign on the t-value reported by ttest to correspond with
*		a test that mean(1) - mean(0) == 0
*	Version 1.4 7/11/2012 Name the rows of the return matrices after the underlying factor variables
*	Version 1.5 5/24/2013 Modify to accept a list of variable names > 256 characters
*	Version 1.6 6/12/2013 Add the -addstat- and the -obsgain- options.
*	Version 1.7 6/21/2013 Fix bug in matrix rownames
*	Version 1.8 6/21/2013 Add the groupstats and group options
*	Version 1.9 12/10/2013 Add the line -local varlist = subinstr("`varlist'","i.","ibn.",.)- 
*	Version 2.0 6/5/2014 Add the Stata version number
*	Version 2.1 10/8/2015 Require version 11.1 in line 3 to enable factor variables to work
*					but option -obsgain- does not work with i. factor variables.
*					It shows that dropping only one of a set of dummy variables coes not increase sample,
*					because other variables in the set have the same missing observations.
*					Also if `touse' appears in several places without the `in' macro.  Shouldn't they always appear together?
*	Version 2.2 2/10/2016 Tweaks include:
*					Wrap the -frmttable- messages and provide clickable links.
*					Restrict the message "Without the variable `rhsname' nobs is: `e(N)'"
*					to the variables with obsplus > 0.
*					For the -obsgain- option, save some cpu time by replacing -regress- with -_regress-
*					Add the _rmcoll command to strip out collinear variables, so that -group()-option
*					works with factor variables and obsgain works on dummy variables. 
*					Add correct row names for expanded factor variables
*					Use matlist command, with noheader option to avoid printing name of temporary matrix
*					and to assure proper rownames on all output.
*					Replace blanks with _'s in line 239 to allow rowname(equname) to work
