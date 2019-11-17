*! Version 2.0 <29Dec2015>
*! Author: R.Andres Castaneda -- acastanedaa@worldbank.org
*! Author: Santiago Garriga   -- santiago.garriga@psestudent.eu

/* *===========================================================================
	Do2screen: Program to display do-files in result's screen
-------------------------------------------------------------------
Created: 		06Feb2013	(Santiago Garriga & Andres Castaneda) 
Modified: 	29Dec2015	(Santiago Garriga & Andres Castaneda) 
version:		02 
Dependencies: 	WORLD BANK
*===========================================================================*/
version 9

cap program drop do2screen
program define do2screen, rclass

	syntax  [using/],								///
		[															///
		VARiables(string)							///
			find(string)								///
			lines(int 5) 								///
			range(numlist min=1 max=2)	///
			folder(string)							///
			text(string)								///
			replace											///
			labels											///
			noprevious									///
		]

* ==============================================================================
* =========================================1.ERROR Messages==================== 
* ==============================================================================

* Display Options (Find, Variables and Range)

qui {

local aux = 0
cap confirm existence `variables'
if (_rc == 0 ) local ++aux
cap confirm existence `find'
if (_rc == 0 ) local ++aux
cap confirm existence `range'
if (_rc == 0 ) local ++aux

if (`aux' > 1) {
	disp in red "Options variable, find and range are mutually exclusive. " ///
		" You must chose only one of them"
	error
}

if (`aux' == 0) {
	disp in red "You should choose at least one option: variable, find and range."
	error
}

if (!missing("`previous'") & missing("`variables'")) {
	disp in red "noprevious option must be specified with variables option"
	error
}
if (!missing("`previous'") & (!missing("`find'") | !missing("`range'"))) {
	disp in red "noprevious option cannot be specified with option find or range"
	error
}


* ==============================================================================
* ===========================2. Set Default Options============================= 
* ==============================================================================

* Folder
if (`"`folder'"' != `""') {
	if regexm(`"`folder'"', `"[\]$"') ///
		local folder = reverse(substr(reverse(`"`folder'"'), 2, .))
	if regexm(`"`folder'"', `"[a-zA-Z0-9]$"') local folder "`folder'/"
	local cdir "`c(pwd)'"
	cd "`folder'"
}

* Range and lines (default option for the range)
if ("`range'" != "" ) {
	local start: word 1 of `range'
	if (wordcount("`range'") == 1) {
		local end = `start' + `lines'
	} //  range == 1
	else {
		local end: word 2 of `range'
		local lines = `end' - `start'
	} // range == 2
}

* text option is selected
if ("`text'" != "") {
	tempname textfile
	if (regexm("`text'","^.*\.txt$") == 0 ) local text "`text'.txt"
	log using "`text'", text name(`textfile') `replace'
}


* If using


if (`"`using'"' == `""') local dofiles: dir . files "*.do"

if `"`using'"' != `""' {
	local dofiles `""`using'""'
	if (substr(reverse(`dofiles'),1,3) != "od.") {
		  local dofiles `"`dofiles'.do"'
		  
	}
}


* =============================================================================
* ==============================3. Run sub-programs============================
* =============================================================================

foreach dofile of local dofiles {

	noi dis as text _new "{p 4 4 2}{cmd:do-file:} "	in y  "  `dofile'" 	 ///
		`"{browse "`folder'`dofile'":{space 10}Open }"'" {p_end}" 
	noi dis as text "{hline 96}" 

	cap noi do2screen_display, variables(`variables')     ///
		find(`"`find'"') dofile(`dofile') range(`range')    ///
		lines(`lines') start(`start') end(`end') `previous' `labels'
}
	
/*===========================================================================
							3.2 Display option								
===========================================================================*/


* Close text file
if ("`text'" != "") {
	log close `textfile'
	noi disp as text `"note: results saved to `text'"'
}

if ("`folder'" != "") cd "`cdir'"

} // end of qui
end

* ==============================================================================
* =========================do2screen_display program============================
* ==============================================================================

program define do2screen_display, rclass

	syntax [anything]								///
		[if] [in],										///
		[															///
		variables(string)							///
		find(string)									///
		range(numlist)								///
		lines(numlist)								///
		start(numlist)								///
		end(numlist)									///
		dofile(string)								///
		labels												///
		noprevious										///
		]

qui {

/*====================================================================
                        1: Initial conditions
====================================================================*/

*--------------------1.1: Load Information of the do-file

	drop _all
	set obs 1
	gen strL oneline = fileread("`dofile'")
	local crlf "`=char(10)'`=char(13)'" 

	set obs 500000
	tempname myfile
	local file "`dofile'" 

	gen line = .
	gen selection = .
	gen strL code = ""

	file open `myfile' using "`file'"  , read 
	file read `myfile' line
	local i = 1
	qui while r(eof)==0 {
		replace line = `i' in `i'
		replace code = `"`macval(line)'"' in `i'
		file read `myfile' line
		local i = `i' + 1
	}

	replace code = ltrim(rtrim(itrim(code)))
	replace code = subinstr(code, "`=char(9)'", " ",.) 
	clonevar origcode = code
	drop if line == .

/*====================================================================
              2: Algorithm for Variables condition
====================================================================*/

	if ("`variables'" != "" ) { // Condition if the user wants to see specific sedlac variable
		

		foreach var of local variables { // analysis for each variable desired
		
			replace code = origcode
			replace selection = .
			*--------------------2.1: Initial conditions of algorithm
			tempname D 
			matrix `D'=J(1,500,1)
			local i=1

			local mainvar "`var'"
			local doughter`var' "nope"		    // e.g., doughter of itf (var) is ipcf 
			local prevars`var' "`var'" 

			local crlf "`=char(10)'`=char(13)'"

			*--------------------2.2:
			local stay = 1
			qui while (`stay' == 1) {
				

				if ("`previous'" == "noprevious") local stay = 0
				local j=`D'[1,`i']
				if (`"`: word `j' of `prevars`var'''"' != `""') {
					
					local var : word `j' of `prevars`var''
					if ("`var'" == "`doughter`var''") {
						disp in red "circular creation for `var'"
						matrix `D'[1,`i']=`D'[1,`i']+1
						continue
					}
					
					

					** exclusion 
					**** Code to identify previous variables
					local way1 = 0
					local way2 = 0
					local fline ""
					
					* local var aedu /* TO ERASE */
					tempvar a
					gen `a' = regexs(2) if regexm(code, `"^(.*[:]?[ ]*[a-z]+ `var'[ ]*=)([ a-z0-9\."]+.*)$"')
					
					sum line if `a' != "", meanonly
					if r(N) != 0 {
						if ("`mainvar'" == "`var'") local bfrlines = r(max)
						levelsof line if (`a' != `""'), local(tlines)
						foreach tline of local tlines {
							* noi disp in red `a'[`tline']
							local fline "`fline' `: disp `a'[`tline']'" 
						}
					}
					if (`"`fline'"' != `""') local way1 = 1
					else {		// in case of other way to generate variables
						tempvar a
						gen `a' = regexm(code, `"^.*,.*[a-z]+\(([a-zA-Z0-9_ ]*[ ]+`var'|[ ]*`var')([ ]*\)|[ ]+[a-zA-Z0-9_ ]*\))"')
						sum line if `a' == 1, meanonly
						if r(N) != 0 {
							if ("`mainvar'" == "`var'") local bfrlines = r(max)
							local fline: disp code[r(min)]
							local way2 = 1
						}
					}
					
					** In case variable is not created
					if (`way1' == 0 & `way2' == 0) {
						matrix `D'[1,`i']=`D'[1,`i']+1
						local var "`doughter`var''"
						continue
					}
					
					*** Code for after the variable is created****
					code_aftervar `var' in 1/`bfrlines', `labels'
					************
					
					**************************
					** creation of variables 
					*************************
					
					
					local tofind = `"`fline'"'
					
					foreach symb in ")" "+" "-" "/" "*" ">=" "<=" ">" "<" "==" "!=" ///
						"~=" " if " " . " " ." "|" " (" " &" " #" " %" " ^"  {
						local tofind: subinstr local tofind "`symb'" "  ", all  // functions closing
					}
					lstrfun tofind, regexr(`"`tofind'"', `" \[[ ]*[a-z]+[ ]*=[ ]*[a-zA-Z0-9]+[ ]*\]"', "")	// functions opening
					lstrfun tofind, regexr(`"`tofind'"', `"^.*="', "")			// everything before equal
					lstrfun tofind, regexr(`"`tofind'"', `",.*"', "")			// everything after comma
					lstrfun tofind, regexr(`"`tofind'"', `"[a-zA-Z]+\("', "")	// functions opening
					
					 * number with decimals
					local b ""
					foreach x of local tofind {
						if !regexm(`"`x'"', `"[0-9]+\.[0-9]+"')  local b "`b' `x'"
					}
					local tofind `"`b'"'
					
					* Regular Numbers
					local c ""
					foreach x of local tofind {
						if !regexm(`"`x'"', `"^[0-9]+"')  local c "`c' `x'"
					}
					local tofind `"`c'"'
					
					local tofind = ltrim(rtrim(itrim(`"`tofind'"')))
					local tofind: list uniq tofind
					
					
					* noi disp in g "prevar of `var': " in y `"`tofind'"'
					
					if (`"`tofind'"' != `""') {
						
						local eqvars = 0
						local d ""
						foreach nvar of local tofind {
							if ("`nvar'" != "`var'") local d "`d' `nvar'"
							else local eqvars = 1
						}
						local tofind `"`d'"'
						
						local tofind = ltrim(rtrim(itrim(`"`tofind'"')))  // just in case
						local tofind: list uniq tofind  // just in case
						
						
						
						* if (`eqvars' == 0) {
						if (`"`tofind'"' != `""') {
							local prevars`var' "`tofind'"
							foreach nvar of local tofind {
								local doughter`nvar' "`var'"
							}
							* local oldvar "`var'"
							local ++i
						}
						else {
							matrix `D'[1,`i']=`D'[1,`i']+1
							local var "`doughter`var''"
						}
					}
					else {
						matrix `D'[1,`i']=`D'[1,`i']+1
						local var "`doughter`var''"
					}
				}
				else {
					matrix `D'[1,`i']=1
					local i=`i'-1
					if (`i'==0) continue, break
					matrix `D'[1,`i']=`D'[1,`i']+1
					local var "`doughter`var''"
				}
				
			} // end of while stay == 1
			
			local crlf "`=char(10)'`=char(13)'" 
			replace code = subinstr(code, "`=char(96)'", "`=char(92)'`=char(96)'",.) 
			scalar s_varcode = "" 
			levelsof line if selection == 1, local(lines) 

			noi disp as text _new "Line {c |}" _col(20) "{cmd: Writing code for:} {result: `mainvar'}" 
			noi disp as text "{hline 5}{c +}{hline 90}" 
			foreach line of local lines {
				local space: disp _dup(`=4-length("`line'")') " "
				local lcode: disp code[`line'] 
				scalar s_varcode = s_varcode + `"`crlf'`space'`line': `lcode'"'
				* noi disp in g "`space'`line':" in y " `lcode'"
				noi disp in g `"`space'`line' :"' in y `" `lcode'"'
			} 

			* noi disp in y s_varcode  
			* noi tabdisp line if `check' == 1, cell(code) 
			noi disp as text  _col(60) "{hline 10}" " (end of analysis of `mainvar')" _newline 
			
		} // End of variables loop  
	} 	// End of variables conditions


	/* -----------------------------------
		If 'find' option is selected
		-----------------------------------*/ 

	if ( `"`find'"' != `""' ) { // lookfor whatever the user needs to see
		replace code = subinstr(code, "`=char(96)'", "`=char(92)'`=char(96)'",.)
		local t = 0
		foreach tofind of local find { // analysis for each variable desired
			local ++t
			replace selection = .

			* Display title and horizontal lines
			noi di as text _new  "Line {c |}		{cmd: Writing code for:}  {result: `tofind'}"
			noi di as text "{hline 5}{c +}{hline 90}"
			
			replace selection = -1 if  strpos(code,`"`tofind'"')!=0
			count if selection == -1
			if (r(N) >= 1) {
				levelsof line if selection == -1, local(nlines)
				local section = 0
				foreach line of local nlines {		// lines where tofind was found

					scalar s_varcode = ""
					local ++section		// number of sections for the same finding
					foreach i of numlist 0/`lines' {

						local space: disp _dup(`=4-length("`=`line'+`i''")') " "
						local lcode: disp code[`=`line'+`i''] 
						scalar s_varcode = s_varcode + `"`crlf'`space'`=`line'+`i'': `lcode'"' 

					}
					
					noi disp in y s_varcode  
					noi di as text  _column(35)  "{hline 10}" ///
						" (end of section `section' for `tofind') " "{hline 10}" _newline

				}  // end of loop for line with foreach 
			
			}  // end of of condition when something found. 
			else {
				noi disp in red "nothing found for " in y " `tofind'"
			}
			noi di as text  _column(60)  "{hline 10}" " (end of analysis of `tofind')" _newline
		} // End of tofind loop		
	} // end of find condition
		
		
	/* -----------------------------------
		If 'range' option is selected
		-----------------------------------*/ 
	if ( "`range'" != "" ) { // look for whatever the user needs to see

		* Display title and horizontal lines
		noi di as text _new  "Line {c |}		{cmd: Writing code between lines:}  {result: `start' & `end'}"
		noi di as text "{hline 5}{c +}{hline 90}"

		local crlf "`=char(10)'`=char(13)'" 
		replace code = subinstr(code, "`=char(96)'", "`=char(92)'`=char(96)'",.) 
		scalar s_varcode = "" 

		foreach line of numlist `start'/`end' {
			local space: disp _dup(`=4-length("`line'")') " "
			local lcode: disp code[`line'] 
			scalar s_varcode = s_varcode + `"`crlf'`space'`line': `lcode'"' 
		} 

		noi disp in y s_varcode  
		noi di as text  _column(45)  "{hline 10}" " (end of analysis of lines between `start' & `end')" _newline
	} // end of range condition
		
}
end

/*====================================================================
                  4: identification of code after creation
====================================================================*/

program code_aftervar, rclass

syntax [anything(name=var)] in, [labels]
marksample touse

qui {
	#delimit ;
	
	
*-------------------4.1: Comments;

	* A. Beginning with Opening and closing comments in the same line;
	cap replace selection = 3 if (regexm(code, `"^[ ]*(/\*.*\*/)(.*)"');
		
	* B. Begin comment in one line and closing in other line;
	replace selection = 4 if regexm(code, `"^(.*)/\*"');
	
	count if selection  == 4;
	if (r(N) > 1 ) {;
		levelsof line if selection == 4, local(lines);
		foreach line of local lines {;
			local inloop = 0;
			local i = -1 ;
			while (`inloop' == 0) {;
				local ++i;
				if regexm(code, `"^(.*)/\*"') in `=`line'+`i'' 
					local partA = regexs(1);
				if regexm(code, `"^(.*)(\*/)(.*)$"') in `=`line'+`i'' 
					local partB = regexs(3);
				if regexm(code, `"\*/"') in `=`line'+`i'' local inloop = 1;
			};
			
			if regexm(`"`partA' `partB'"', "^.* `var' .*") {;
				replace code = `"`partA' `partB'"' in `line';
				replace selection = 1 in `line';
				if (`i'!= 0) replace code = "" in `=`line'+1'/`=`line'+`i'';
			};
			else replace code = "" in `line'/`=`line'+`i'';
		} ; // end of line loop;
	} ; // end of ;
	replace selection = . if selection == 4;
	
	* C. Identify * comments;
	replace code = "" if regexm(code, `"^[ ]*\*"');
    
	* D. Identify comments at the end of the line //;
	replace code = regexs(1) if regexm(code, `"^(.*)(//.*)"');
	
	* E. comment /*  */ after and in the middle of the line of code. Ex. gen var = var2 /* gen var1 */;
	replace code = regexs(1) + " " + regexs(3)  if regexm(code, `"^(.*)(/\*.*\*/)(.*)"');
	
	replace code = ltrim(rtrim(itrim(code)));

*----------------------4.2.1:  General comments;

	cap replace selection = 1 `in' if (regexm(code,
		`"^.*(:)?[ ]*(egen|g|g(e|en|ene|ener|enera|enerat|enerate)|replace)[ ]*(byte|int|long|float|double)?[ ]+`var'[ ]?=[ ]?"'));

	cap replace selection = 1 `in'   if (regexm(code,
		`"^[ ]*recode.*[ ]*(g|g(e|en|ene|ener|enera|enerat|enerate))\(([a-zA-Z0-9_ ]*[ ]+`var'|[ ]*`var')([ ]*\)|[ ]+[a-zA-Z0-9_ ]*\))"'));

	cap replace selection = 1  `in'  if (regexm(code,
		`"^[ ]*(en|(en|de(c|co|cod|code))).*[ ]*(g|g(e|en|ene|ener|enera|enerat|enerate))\([ ]*`var'[ ]*\)"'));

	cap replace selection = 1  `in'  if (regexm(code,
		`"^[ ]*(de|to)string(.*)(g|g(e|en|ene|ener|enera|enerat|enerate))\(([a-zA-Z0-9_ ]*[ ]+`var'|[ ]*`var')([ ]*\)|[ ]+[a-zA-Z0-9_ ]*\))"'));

	cap replace selection = 1 `in'   if (regexm(code,
		`"^[ ]*(de|to)string[ ]+([a-zA-Z0-9_ ]*[ ]+`var'|`var')([ ]*,|[ ]+[a-zA-Z0-9_ ]*,).*replace"'));

	cap replace selection = 1 `in'   if (regexm(code,
		`"^[ ]*re(n|na|nam|name)[ ]+[a-zA-Z0-9_]+[ ]+`var'[ ]*($|,.*)"'));

	cap replace selection = 1 `in'   if (regexm(code,
		`"^[ ]*re(n|na|nam|name)[ ]+\(.*\)[ ]+\(([a-zA-Z0-9_ ]*[ ]+`var'|`var')([ ]*\)|[ ]+[a-zA-Z0-9_ ]*\))[ ]*($|,.*)"'));

*----------------------4.2:  Display Labels;
if (!missing("`labels'")) {;
	cap replace selection = 1 `in'   if (regexm(code,
		`"^[ ]*l(a|ab|abe|abel)[ ]+va(r|ri|ria|riab|riabl|riable)[ ]+`var'[ ]+.*"'));

	cap replace selection = 1 `in'   if (regexm(code,
		`"^[ ]*l(a|ab|abe|abel)[ ]+de(f|fi|fin|fine)[ ]+`var'[ ]+.*"'));

	cap replace selection = 1 `in'   if (regexm(code,
		`"^[ ]*l(a|ab|abe|abel)[ ]+val(u|ue|ues)[ ]+([a-zA-Z0-9_ ]*[ ]+`var'|`var')[ ]+[a-zA-Z0-9_ ]*"'));
};

*----------------------4.3:  Foreach loops;

	cap replace selection = 2  if (regexm(code, 
		`"^[ ]*foreach[ ]+[a-zA-Z0-9_]+[ ]+(in|of (varlist|newlist))[ ]+([a-zA-Z0-9_ ]*[ ]+`var'|`var')([ ]*|[ ]+[a-zA-Z0-9_ ]*)"'));

	count if selection == 2;
	if (r(N) >= 1) {;
		levelsof line if selection == 2, local(nlines);
		foreach line of local nlines {;
			local inloop = 0;
			local i = 0 ;
			while (`inloop' == 0) {;
				local ++i;
				local loopline: disp code[`=`line'+`i''];
				if (regexm(`"`macval(loopline)'"',`"}"') == 1) local inloop = 1;
				replace selection = 1 in `=`line'+`i'';
			}; // end of while ;
		};  // end of loop for line with foreach; 
	};
	replace selection = 1   if selection == 2;

	#delimit cr
}
end

exit 



* =============================================================================
* ============================History of the file==============================
* =============================================================================

Version 1.0.1 <05Mar2015>
v 0.0      <06Feb2015>   <Andres Castaneda, Santiago Garriga>

local using bol_2006_eh_v01_m_v02_a_sedlac_02.do
do2screen using `using', var(relab)
