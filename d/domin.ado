*! domin version 3.0 Jan, 15 2014 J. N. Luchman

program define domin, eclass 
/*history and version information at end of file*/

version 12.0

if (replay()) {

	if ("`e(cmd)'" != "domin") error 301
	
	if (_by()) error 190
	
	Display `0'
	
	exit 0
	
}

syntax varlist(min = 1) [in] [if] [aw pw iw fw] , [Reg(string) Fitstat(string) Sets(string) ///
All(varlist fv) noCOMplete noCONditional EPSilon mi miopt(string) CONSmodel]

/*defaults and warnings*/
if (("`reg'" == "") & ("`epsilon'" == "")) {	//if no "reg" and "epsilon" options specified - notification

	local reg "regress"	//make default analysis "regress"
	
	display "{err}Regression type not entered in {opt reg()}. " _newline ///
	"{opt reg(regress)} assumed." _newline
	
}

if (("`fitstat'" == "") & ("`epsilon'" == "")) {	//if no "fitstat" and "epsilon" options specified - notification

	local fitstat "e(r2)"	//make default fitstat the proportion of variance explained R2
	
	display "{err}Fitstat type not entered in {opt fitstat()}. " _newline ///
	"{opt fitstat(e(r2))} assumed." _newline
	
}

if (("`epsilon'" != "") & (("`reg'" != "") | ("`fitstat'" != ""))) {	//warning if any "reg" or "fitstat" option specified with "epsilon"

	display "{err}Option {opt epsilon} assumes {opt reg(regress)}" _newline ///
	"and {opt fitstat(e(r2))}.  Entries in {opt reg()} and/or" _newline ///
	"{opt fitstat()} ignored." _newline

}

if (("`mi'" == "") & ("`miopt'" != "")) {	//warning if "miopt" is used without "mi"

	local mi "mi"
	
	display "{err}You have added {cmd:mi estimate} options without adding the {opt mi} option.  {opt mi}" _newline ///
	"assumed." _newline

}

/*exit conditions*/
if (("`epsilon'" != "") & ("`sets'" != "")) {	//epsilon and "sets" cannot go together

	display "{err}Options {opt epsilon} and {opt sets()} not allowed together."
	
	exit 198

}

if (("`epsilon'" != "") & ("`all'" != "")) {	//epsilon and "all" cannot go together

	display "{err}Options {opt epsilon} and {opt all()} not allowed together."
	
	exit 198

}

if (("`epsilon'" != "") & ("`consmodel'" != "")) {	//epsilon and "consmodel" cannot go together

	display "{err}Options {opt epsilon} and {opt consmodel} not allowed together."
	
	exit 198

}

if (("`epsilon'" != "") & (("`mi'" != "") | ("`miopt'" != ""))) {	//epsilon and multiple imputation options cannot go together

	display "{err}Options {opt epsilon} and {opt mi} or {opt miopt} not allowed together."
	
	exit 198

}

if ("`mi'" == "mi" ) {	//is data actually mi set?

	capture mi describe

	if (_rc != 0) {	//epsilon and multiple imputation options cannot go together

		display "{err}Data are not {cmd:mi set}."
	
		exit `=_rc'
		
	}
	
	if (r(M) == 0) {	//warn and proceed if no imputations
	
		display "{err}No imputations. {opt mi} turned off." _newline
		
		local mi ""
		
		local miopts ""
	
	}

}

capture which lmoremata.mlib	//is moremata present?

if (_rc != 0) {	//if moremata cannot be found, tell user to install it.

	display "{err}Module {cmd:moremata} not found.  Install {cmd:moremata} here {stata ssc install moremata}."
	
	exit 198

}

/*disallow complete and conditional with epsilon option*/
if ("`epsilon'" != "") {

	local conditional "conditional"
	
	local complete "complete"
	
}

/*general set up*/
if ("`mi'" == "mi") tempfile mifile	//produce a tempfile to store imputed fitstats for retreival

gettoken dv ivs: varlist	//parse varlist line to separate out dependent from independent variables

gettoken reg regopts: reg, parse(",")	//parse reg() option to pull out estimation command options

if ("`regopts'" != "") gettoken erase regopts: regopts, parse(",")	//parse out comma if one is present

local diivs "`ivs'"	//create separate macro to use for display purposes

local mkivs "`ivs'"	//create separate macro to use for sample marking purposes

if (`:list sizeof sets' > 0) {	//parse and process the sets if included

	/*pull out set #1 from independent variables list*/
	gettoken one two: sets, bind	//pull out the first set
	
	local setcnt = 1	//give the first set a number that can be updated as a macro
	
	local one = regexr("`one'", "[/(]", "")	//remove left paren
			
	local one = regexr("`one'", "[/)]", "")	//remove right paren
	
	local set1 `one'	//name and number set
	
	local ivs "`ivs' <`set1'>"	//include set1 into list of independent variables, include characters for binding in Mata
	
	local mkivs `mkivs' `set1'	//include variables in set1 in the mark sample independent variable list
	
	local diivs "`diivs' set1"	//include the name "set1" into list of variables
	
	
	while ("`two'" != "") {	//continue parsing beyond set1 so long at sets remain to be parsed (i.e., there's something in the macro "two")

		gettoken one two: two, bind	//again pull out a set
			
		local one = regexr("`one'", "[/(]", "")	//remove left paren
		
		local one = regexr("`one'", "[/)]", "")	//remove right paren
	
		local set`++setcnt' `one'	//name and number set - advance set count by 1
		
		local ivs "`ivs' <`set`setcnt''>"	//include further sets - separated by binding characters - into independent variables list
		
		local mkivs `mkivs' `set`setcnt''	//include sets into mark sample independent variables list
		
		local diivs "`diivs' set`setcnt'"	//include set number into display list
				
	}
			
}

if (`:list sizeof ivs' < 2) {	//exit if too few predictors/sets (otherwise prodices cryptic Mata error)

	display "{err}{cmd:domin} requires at least 2 independent variables or" _newline ///
	"independent variable sets."
	
	exit 198

}

/*finalize setup*/
tempvar touse keep	//declare sample marking variables

tempname obs rmvfs consfs	//declare temporary scalars

mark `touse'	//declare marking variable

quietly generate byte `keep' = 1 `if' `in' //generate tempvar that adjusts for "if" and "in" statements

markout `touse' `dv' `mkivs' `all' `keep'	//do the sample marking

local nobindivs = subinstr("`ivs'", "<", "", .)	//take out left binding character(s) for use in adjusting e(sample) when obs are dropped by an anslysis

local nobindivs = subinstr("`nobindivs'", ">", "", .)	//take out right binding character(s) for use in adjusting e(sample) when obs are dropped by an anslysis

if ("`epsilon'" == "") {	//don't invoke program checks if epsilon option is invoked

	if ("`mi'" == "") capture `reg' `dv' `nobindivs' `all' [`weight'`exp'] if `touse', `regopts'	//run overall analysis - probe to check for e(sample) and whether everything works as it should

	else if ("`mi'" == "mi") {

		capture mi estimate, saving(`mifile') `miopt': `reg' `dv' `nobindivs' `all' [`weight'`exp'] if `keep', `regopts'	//run overall analysis with mi prefix - probe to check for e(sample) and whether everything works as it should

		estimates use `mifile', number(`:word 1 of `e(m_est_mi)'')	//if touse doesn't equal e(sample) - use e(sample) from first imputation and proceed
	
	}
	
	quietly count if `touse'	//tally up observations from count based on "touse"

	if ((r(N) > e(N)) & ("`mi'" != "mi")) quietly replace `touse' = e(sample)	//if touse doesn't equal e(sample) - use e(sample) and proceed; not possible with multiple imputation though

	if (_rc != 0) {	//exit if regression is not estimable or program results in error - return the returned code

		display "{err}{cmd:`reg'} resulted in an error."
	
		exit `=_rc'

	}
	
	capture assert `fitstat' != .	//is the "fitstat" the user supplied actually returned by the command?
	
	if (_rc != 0) {	//exit if fitstat can't be found

		display "{err}{cmd:`fitstat'} not returned by {cmd:`reg'} " _newline ///
		"or {cmd:`fitstat'} is not scalar valued.  See {help return list}."
	
		exit 198

	}

	capture assert sign(`fitstat') != -1	//what is the sign of the fitstat?  domin works best with positive ones - warn and proceed

	if (_rc != 0) {

		display "{err}{cmd:`fitstat'} returned by {cmd:`reg'}." _newline ///
		"is negative.  {cmd:domin} is programmed to work best" _newline ///
		"with positive {opt fitstat()} summary statistics." _newline

	}
	
}

if (("`weight'" != "iweight") & ("`weight'" != "fweight") & ("`mi'" == "")) {	//if weights don't affect obs
	
	quietly count if `touse'	//tally up "touse" if not "mi"
	
	scalar `obs' = r(N)	//pull out the number of observations included
	
}

else if ((("`weight'" == "iweight") | ("`weight'" == "fweight")) & ("`mi'" == "")) {	//if the weights do affect obs

	quietly summarize `=regexr("`exp'", "=", "")' if `touse'	//tally up "touse" by summing weights
	
	scalar `obs' = r(sum)	//pull out the number of observations included
	
}

else {

	quietly mi estimate, `miopt': total `dv' `nobindivs' `all' [`weight'`exp'] if `keep'	//obtain estimate of obs when multiply imputed
	
	scalar `obs' = e(N)	//pull out the number of observations included

}
 
/*begin estimation*/
scalar `rmvfs' = 0	//begin by defining the fitstat of the "all" variables as 0 - needed for dominance() function

if (`:list sizeof all' > 0) {	//if there are variables in the "all" list
	
	if ("`mi'" == "") {	//when there is no "mi" option specified
	
		quietly `reg' `dv' `all' [`weight'`exp'] if `touse', `regopts'	//run analysis with "all" independent variables only
	
		scalar `rmvfs' = `fitstat'	//the resulting "fitstat" is then registered as the value to remove from other fitstats
		
	}
	
	else {	//if "mi" is specified
	
		quietly mi estimate, saving(`mifile', replace) `miopt': `reg' `dv' `all' [`weight'`exp'] if `keep', `regopts'	//run mi analysis with "all" independent variables only
	
		mi_dom, name(`mifile') fitstat(`fitstat') list(`=e(m_est_mi)')	//call mi_dom program to average fitstats
		
		scalar `rmvfs' = r(passstat)	//the resulting average fitstat is then registered as the value to remove from other fitstats
	
	}

}

scalar `consfs' = 0	//begin by defining the fitstat of the constant-only model as 0 - needed for dominance() function

if ("`consmodel'" == "consmodel") {	//if the user desires to know what the baseline fitstat is
	
	if ("`mi'" == "") {	//if "mi" is not declared
	
		quietly `reg' `dv' [`weight'`exp'] if `touse', `regopts'	//conduct analysis without independent variables
	
		scalar `consfs' = `fitstat'	//return baseline fitstat
		
	}
	
	else {	//if "mi" is declared
	
		quietly mi estimate, saving(`mifile', replace) `miopt': `reg' `dv' [`weight'`exp'] if `keep', `regopts'	//conduct mi analysis without independent variables
	
		mi_dom, name(`mifile') fitstat(`fitstat') list(`=e(m_est_mi)')	//compute average fitstat
		
		scalar `consfs' = r(passstat)	//return average baseline fitstat
	
	}
	
}

if ("`epsilon'" ! = "") {	//primary analysis when "epsilon" analysis is invoked

	tempname X Y E R L Lm Bt	//declare tempnames for matrices to be used
	
	if("`weight'" == "pweight") quietly correlate `dv' `ivs' if `touse' [aweight`exp']	//pweights not valid usually for correlate, but act like aweights
	
	if("`weight'" != "pweight") quietly correlate `dv' `ivs' if `touse' [`weight'`exp']	//obtain correlations
	
	matrix `Y' = r(C)	//produce correlations between all variables
	
	matrix `X' = `Y'[2...,2...]	//subset overall matrix to get all between independent variable correlations
	
	matrix `Y' = `Y'[2...,1]	//subset to obtain only independent variable and dependent variable correlations
	
	matrix svd `L' `E' `R' = `X'	//singular value decomposition to orthogonalize independent variable set
	
	matrix `E' = cholesky(diag(`E'))	//obtain sqrt of eigenvalues to use
	
	matrix `Lm' = `L'*`E'*`L''	//put sqrt'd eigenvalues "back" to produce the desired orthogonalized independent variable set
	
	matrix `Bt' = invsym(`Lm')*`Y'	//obtain linear regression weights with orthogonalized independent variable set
	
	mata: Lm = st_matrix("`Lm'"):*st_matrix("`Lm'")	//square values of orthogonalized independent variable set
	
	mata: Bt = st_matrix("`Bt'"):*st_matrix("`Bt'") //square values of regression weights

	mata: st_matrix("domwgts", (Lm*Bt)')	//produce proportion of variance explained and put into Stata
	
	mata: st_numscalar("r(fs)", trace(diag(Lm*Bt)))	//sum relative weights to obtain R2
	
	matrix sdomwgts = domwgts*(1/r(fs))	//produce standardized relative weights (i.e., out of 100%)
	
	mata: st_matrix("ranks", mm_ranks((Lm*Bt)*-1)')	//rank the relative weights

}

else mata: dominance(`"`ivs'"', "`conditional'", "`complete'",`=`rmvfs'', `=`consfs'', "`mi'")	//invoke "dominance() function in Mata

/*display results - this section will not be extensively explained*/
/*name matrices*/
matrix colnames domwgts = `diivs'	

matrix colnames sdomwgts = `diivs'	

matrix colnames ranks = `diivs'	

if ("`complete'" == "") { 	

	matrix colnames cptdom = `diivs'	
	
	matrix coleq cptdom = dominated?	
	
	matrix rownames cptdom = `diivs'	
	
	matrix roweq cptdom = dominates?	
	
}

if ("`conditional'" == "") { 
	
	matrix rownames cdldom = `diivs'
	
	local colcdl `:colnames cdldom'
	
	local colcdl = subinstr("`colcdl'", "c", "", .)
	
	matrix colnames cdldom = `colcdl'
	
	matrix coleq cdldom = #indepvars
	
}	

if (("`epsilon'" == "") & ("`e(title)'" != "")) local title "`e(title)'"

else if (("`epsilon'" == "epsilon") & ("`e(title)'" != "")) local title "Epsilon"

else local title "Custom user analysis"

/*return values*/
ereturn post domwgts [`weight'`exp'], depname(`dv') obs(`=`obs'') esample(`touse')

if ("`epsilon'" != "") ereturn local estimate "epsilon" 

else ereturn local estimate "dominance"

if ("`mi'" == "mi") {

	if (strlen("`miopt'") > 0) ereturn local miopt "`miopt'"

	ereturn local mi "mi"

}

ereturn local reg `"`reg'"'

ereturn local fitstat "`fitstat'"

ereturn local cmd `"domin"'

ereturn local title `"Dominance analysis"'

ereturn local cmdline `"domin `0'"'

ereturn scalar fitstat_o = r(fs)

if (`:list sizeof all' > 0) ereturn scalar fitstat_a = `rmvfs'

if ("`consmodel'" != "") ereturn scalar fitstat_c = `consfs'

if ("`conditional'" == "") ereturn matrix cdldom cdldom
	
if ("`complete'" == "") ereturn matrix cptdom cptdom

ereturn matrix ranking ranks

ereturn matrix std sdomwgts

/*begin display*/
Display

if ("`setcnt'" != "") {

	forvalues x = 1/`setcnt' {

		display "{txt}Variables in set`x': `set`x''"
		
	}
	
}

if (`:list sizeof all' > 0)	display "{txt}Variables included in all subsets: `all'"

end

/*Display program*/
program define Display

tempname domwgts sdomwgts ranks

matrix `domwgts' = e(b)

matrix `sdomwgts' = e(std)

matrix `ranks' = e(ranking)

local diivs: colnames e(b)

mata: st_local("cdltest", strofreal(cols(st_matrix("e(cdldom)"))))

mata: st_local("cpttest", strofreal(cols(st_matrix("e(cptdom)"))))

tokenize `diivs'

local dv = abbrev("`e(depvar)'", 10)

display _newline "{txt}General dominance weights" _newline ///
"{txt}Number of obs{col 27}={res}{col 40}" %12.0f e(N) 

display "{txt}Overall Fit Statistic{col 27}={res}{col 40}" %12.4f e(fitstat_o)

if (e(fitstat_a) != .) display "{txt}All Subsets Fit Stat.{col 27}={res}{col 40}" %12.4f e(fitstat_a)

if (e(fitstat_c) != .) display "{txt}Constant-only Fit Stat.{col 27}={res}{col 40}" %12.4f e(fitstat_c)

display _newline "{txt}{col 13}{c |}{col 20}Dominance{col 35}Standardized{col 53}Ranking"

display "{txt}{lalign 9: `dv'}{col 13}{c |}{col 20}Weight{col 35}Weight" 

display "{txt}{hline 12}{c +}{hline 72}"

forvalues x = 1/`:list sizeof diivs' {

	local `x' = abbrev("``x''", 10)
	
	display "{txt}{col 2}{lalign 11:``x''}{c |}{col 14}{res}" %12.4f `domwgts'[1,`x'] ///
	"{col 29}" %12.4f `sdomwgts'[1,`x'] "{col 53}" %-2.0f `ranks'[1,`x']
	
}

display "{txt}{hline 12}{c BT}{hline 72}"

if (`cdltest' > 0) {

	display "{txt}Conditional dominance statistics" _newline "{hline 85}"
	
	matrix list e(cdldom), noheader format(%12.4f)
	
	display "{txt}{hline 85}"
	
}

if (`cpttest' > 0) {

	display "{txt}Complete dominance designation" _newline "{hline 85}"
	
	matrix list e(cptdom), noheader
	
	display "{txt}{hline 85}"
	
}

end

/*Mata function to compute all tuples of predictors or predictor sets
run all subsets regression, and compute all dominance criteria*/
version 12.0

mata: 

mata clear

mata set matastrict on

void dominance(string scalar ivs, string scalar cdlcompu, string scalar cptcompu, ///
real scalar rmvfs, real scalar consfs, string scalar mi) 
{
	/*object declarations*/
	real matrix include, noinclude, cdl, cdl1, cdl2, design, cpt, focus, rest, compare, eval, ///
	selector1, selector2, eval2, selector3, selector4

	string matrix tuples

	real rowvector fits, counts, combsinc, combsinc2, domwgts, sdomwgts, domawgts, sdomawgts

	string rowvector preds

	real colvector base, combin, cdl3, basecpt, combincpt, indicator, rowcol, basecpt2, combincpt2, ///
	revind

	string colvector iv_mat, tuple
	
	real scalar nvars, ntuples, display, ll, ll_0, fs, cptsum, comparecount, var1, var2, cptdom

	string scalar ivuse
	
	/*parse the predictor inputs*/	
	t = tokeninit(wchars = (" "), pchars = (" "), qchars = ("<>"))
	
	tokenset(t, ivs)
	
	iv_mat = tokengetall(t)'
	
	/*remove characters binding sets together*/
	for (i = 1; i <= rows(iv_mat); i++) {
	
		if (substr(iv_mat[i], 1, 1) == "<") {
		
			iv_mat[i] = substr(iv_mat[i], 1, strlen(iv_mat[i]) - 1)
			
			iv_mat[i] = substr(iv_mat[i], 2, strlen(iv_mat[i]))
			
		}
		
	}
	
	/*set-up and compute all n-tuples of predictors and predictor sets*/
	nvars = rows(iv_mat)
	
	ntuples = 2^nvars - 1
	
	printf("\n{txt}Total of {res}%f {txt}regressions\n", ntuples)
	
	if (nvars > 4) printf("\n{txt}Computing all predictor combinations\n")

	tuples = iv_mat

	for (x = nvars - 1; x >= 1; x--) {

		base = J(x, 1, 1)
	
		base = (base \ J(nvars - x, 1, 0))
	
		basis = cvpermutesetup(base)
	
		for (y = 1; y <= comb(nvars, x); y++) {
	
			combin = cvpermute(basis)
		
			tuple = iv_mat:*combin
		
			tuples = (tuples, tuple)
		
		}
	
	}
	
	/*all subsets regressions and progress bar syntax if predictors or sets of predictors is above 5*/
	display = 1
	
	if (nvars > 4) {
	
		printf("\n{txt}Progress in running all regression subsets\n{res}0%%{txt}{hline 6}{res}50%%{txt}{hline 6}{res}100%%\n")
		
		printf(".")
		
		displayflush()
		
	}

	fits = (.)
	
	for (x = 1; x <= ntuples; x++) {
	
		if (nvars > 4) {
	
			if (floor(x/ntuples*20) > display) {
			
				printf(".")
				
				displayflush()
				
				display++	
				
			}
			
		}

		preds = tuples[., x]'
	
		ivuse = invtokens(preds)
	
		st_local("ivuse", ivuse)
	
		if (strlen(mi) == 0) {
		
			stata("\`reg' \`dv' \`all' \`ivuse' [\`weight'\`exp'] if \`touse', \`regopts'", 1)
		
			fs = st_numscalar(st_local("fitstat")) - rmvfs - consfs
			
		}
		
		else {
		
			stata("mi estimate, saving(mi, replace) \`miopt': \`reg' \`dv' \`all' \`ivuse' [\`weight'\`exp'] if \`keep', \`regopts'", 1)
		
			stata("mi_dom, name(mi) fitstat(\`fitstat') list(\`=e(m_est_mi)')", 1)
			
			fs = st_numscalar("r(passstat)") - rmvfs - consfs
		
		}
	
		fits = (fits, fs)

	}
	
	fits = fits[2..ntuples + 1]

	/*define the incremental prediction matrices and combination rules*/
	/*is variable included in regerssion?*/
	include = sign(strlen(tuples))

	/*# of variables in regression*/
	counts = colnonmissing(exp(ln(include)))

	/*is variable not included in regression?*/
	noinclude = (include:-1)
	
	/*how many combinations at each number of regressors for averaging (in general dominance weights)?*/
	combsinc = J(1, ntuples, 1):*comb(nvars, counts)
	
	combsinc2 = J(1, ntuples, 1):*comb(nvars - 1, counts)
	
	combsinc2 = (0, combsinc2[., 2..ntuples])
	
	combsinc = combsinc - combsinc2
	
	include = include:*combsinc
	
	noinclude = noinclude:*combsinc2
	
	/*compute conditional dominance*/
	if (strlen(cdlcompu) == 0) {
	
		if (nvars > 5) printf("\n\n{txt}Computing conditional dominance\n")
	
		cdl = J(nvars, nvars, 0)
		
		/*loop over orders (i.e., # of predictors) to obtain average incremental prediction within order*/
		for (x = 1; x <= nvars; x++) {
		
			cdl1 = include:^-1
				
			cdl2 = noinclude:^-1
			
			cdl1 = select(cdl1:*fits, counts:==x)
			
			if (x > 1) {
			
				cdl2 = select(cdl2:*fits[1, .], counts:==x-1)
				
				cdl3 = rowsum(cdl1) + rowsum(cdl2)
				
			}
				
			else cdl3 = rowsum(cdl1)
						
			cdl[., x] = cdl3
		
		}
		
		st_matrix("cdldom", cdl)
	
	}
	
	/*define the full design matrix - compute general dominance (average conditional dominance across orders)*/
	design = (include + noinclude):*nvars
	
	design = design:^-1
	
	domwgts = colsum((design:*fits)')
	
	fs = rowsum(domwgts) + rmvfs + consfs

	st_matrix("domwgts", domwgts)

	sdomwgts = domwgts:*fs^-1
	
	st_matrix("sdomwgts", sdomwgts)
	
	st_matrix("ranks", mm_ranks(domwgts'*-1)')

	st_numscalar("r(fs)", fs)
	
	/*compute complete dominance*/
	if (strlen(cptcompu) == 0) {
	
		if (nvars > 5) printf("\n{txt}Computing complete dominance\n")

		cpt = J(nvars, nvars, 0)
		
		/*begin by selecting 2 variables to compare*/
		basecpt = (J(2, 1, 1) \ J(nvars - 2, 1, 0))
	
		basiscpt = cvpermutesetup(basecpt)
		
		/*generate "indicator" for which variables are being compared*/
		indicator = (1::nvars)
		
		for (x = 1; x <= comb(nvars, 2); x++) {  
		
			/*here the variables are actually selected - loop through all combinations*/
			combincpt = cvpermute(basiscpt)
		
			rowcol = select(combincpt:*indicator, combincpt:==1)
		
			focus = select(sign(strlen(tuples)), combincpt:==1)
		
			rest = select(sign(strlen(tuples)), combincpt:==0) 
			
			/*sum the signed differences - a completely dominant predictor will produce a "cptsum"
			equal to the number of comparisons*/
			cptsum = 0
			
			compare = focus:*fits
			
			for (y = 1; y <= nvars - 1; y++) {
			
				/*here specific comparisons are made based on the same set of covariates*/
				eval = select(compare, counts:==y)
				
				selector1 = select(focus, counts:==y)
				
				selector1 = colsum(selector1)
				
				selector2 = select(rest, counts:==y)
				
				/*variable used to keep track of how many comparisons there have been*/
				comparecount = 1
				
				basecpt2 = (J(y - 1, 1, 1) \ J(nvars - y - 1, 1, 0))
				
				/*make comparisons between fitstat's - matching on predictors*/
				while ((comparecount <= comb(nvars - 2, y - 1)) & (nvars > 2)) {
					
					if (y == 1) eval2 = select(eval, selector2[comparecount, .]:==0)
					
					else if (y == 2) {
					
						eval2 = select(eval, selector1:==1)
						
						selector3 = select(selector2, selector1:==1)
					
						eval2 = select(eval2, selector3[comparecount, .]:==1)
					
					}
					
					else {
						
						eval2 = select(eval, selector1:==1)
						
						selector3 = select(selector2, selector1:==1)
						
						basiscpt2 = cvpermutesetup(basecpt2)
						
						combincpt2 = cvpermute(basiscpt2)*10
										
						revind = (nvars - 2::1)
						
						selector4 = J(nvars - 2, 1, 10)
						
						combincpt2 = combincpt2:^revind*(1/10)
						
						selector4 = selector4:^revind*(1/10)
						
						selector4 = selector3:*selector4
						
						selector4 = colsum(selector4)
						
						combincpt2 = colsum(combincpt2)	
						
						eval2 = select(eval2, selector4:==combincpt2)						
					
					}
				
					/*here the comparison is actually made and "cptsum" is updated*/
					var1 = rowsum(eval2[1, .])
				
					var2 = rowsum(eval2[2, .])
				
					cptdom = sign(var1 - var2)
								
					cptsum = cptsum + cptdom
					
					comparecount++
					
				}
				
			}
			
			/*determine completely dominate, dominated by or none*/
			if (nvars == 2) cptsum = sign(rowsum(compare[1, .]) - rowsum(compare[2, .]))
		
			if (cptsum == 2^(nvars - 2)) cpt[rowcol[1, 1], rowcol[2, 1]] = 1
		
			else if (cptsum == -2^(nvars - 2)) cpt[rowcol[1, 1], rowcol[2, 1]]= -1
		
			else cpt[rowcol[1, 1], rowcol[2, 1]] = 0
	
		}
		
		/*make cptdom matrix symmetric in what it is telling the user*/
		cpt = cpt + cpt'*-1
	
		st_matrix("cptdom", cpt)
	
	}
	
}

end

/*program to average fitstat across all multiple imputations for use in domin*/
program define mi_dom, rclass

syntax, name(string) fitstat(string) list(numlist)

tempname passstat

scalar `passstat' = 0

foreach x of numlist `list' {

	estimates use `name', number(`x')
	
	scalar `passstat' = `passstat' + `fitstat'*`:list sizeof list'^-1

}

return scalar passstat = `passstat'

end

/* programming notes and history

- domin version 1.0 - date - April 4, 2013

Basic version

-----

- domin version 1.1 - date - April 13, 2013

//notable changes\\
a] fixed incorrect e(cmd) and e(cmdline) entries
b] fixed markout variables for sets greater than 1

-----

- domin version 1.2 - date - April 16, 2013

//notable changes\\ 
a] version 12.1 declared to ensure compatability with factor variables and other advertised features (thanks to Nick Cox for advice on this issue)
b] fixed markout problem that kept unwanted characters in markout statement (thanks to Ariel Linden for pointing this out)
c] analytic weights disallowed; importance weights allowed in dominance analysis consistent with underlying linear and logit-based regressions

-----

- domin version 2.0 - date - Aug 25, 2013

//notable changes\\
a] tuples, all subset regression, and dominance computations migrated to Mata (thanks to all individuals who pointed out the errors tuples caused when interfacing with domin)
b] incorporates complete and conditional dominance criteria
c] ranking of predictors returned as a matrix, e(ranking)
d] bug related to if and in qualifiers resolved
e] dots representing each regression replaced with a progress bar for predictors/sets>6 or >4 (for logits)
f] piechart dropped as option
g] altered adjusted domin weight computation to result in decomposition of adjusted r2's from full regression
h] incorporates "epsilon" or relative weights approach to general dominance (for regress only)
i] McFadden's pseudo-R2 used for logit-based models (for consistency with Azen & Traxel, 2009)

-----

- domin version 3.0 - date - Jan 15, 2013

//notable changes\\
 a] R2-type metrics no longer default.  Any valid model fit metric can be used.  Consequently, adj R2 was also removed.
 b] increased flexibility of estimation commands to be used by domin.  Any command that follows standard syntax could potentially be used.
 c] wrapper program mvdom and mixdom incorporated into domin package to demonstrate command's flexibility.
 d] due to flexibility in fitstat, constant-only model adjustment incorporated (similar to Stas Kolenikov's -shapley- on SSC) 
 e] error related to reported number of observations fixed when strongly collinear variables dropped.
 f] added multiple imputation support
 g] greatly expanded, clarified, and updated the help file

*/
