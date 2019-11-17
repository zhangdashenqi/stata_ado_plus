/*******************************************************************************

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								   
                    * Ketchup package comes with no warranty *


	
	
	Ketchup version 1.0  August, 2014
	Ketchup version 1.1  August, 2014
	Ketchup version 1.2  August, 2014
	Ketchup version 1.3  September, 2014 
	Ketchup version 1.4  October, 2014
	*/
	
cap program drop markdoc	
	program ketchup
		version 11
		
		syntax anything(name=smclfile id="The smclfile name is")  ///
		[, erase replace Keep NOlight Date Export(name) Font(str) Title(str) ///
		AUthor(str) AFFiliation(str) STYle(name) Printer(name) SETpath(str) ///
		PANdoc(str) ]
		
		global setpath "`setpath'"
		global printer "`printer'"
		global pandoc "`pandoc'"

		
		********************************************************************
		*CHECKING THE REQUIRED SOFTWARE
		********************************************************************
		ketchupcheck	
	
		********************************************************************
		*Reading the wordlist for syntax highlighting
		********************************************************************
		
		cap quietly findfile synlightlist.ado
		local r1 `r(fn)'
		
		cap quietly findfile knit.ado
		local r2 `r(fn)'
	
		if "`r1'" == "" & "`r2'" ~= ""  {
				di _n
				di as err `"{p}The {bf:{help synlight}} package is required. "' ///
				`"please click on "' ///
				`"{ul:{bf:{stata "ssc install synlight":Install Synlight Now}}} "' ///
				`"or alternatively type {ul:{bf:ssc install synlight}}"'
				di as txt "(synlight is a HTML-based syntax highlighter for Stata)" _n
				exit 198
				}
				
		
		if "`r1'" ~= "" & "`r2'" == ""  {
				di _n
				di as err `"The {bf:{help weaver}} package is required. "' ///
				`"Click on {ul:{bf:{stata "ssc install weaver":Install Weaver Now}}} "' ///
				`"or alternatively type {ul:{bf:ssc install weaver}}"'
				di as txt "(Weaver provides a handful of commands for writing dynamic reports in Stata)" _n
				exit 198
				}
				
		
		if "`r1'" == "" & "`r2'" == ""  {
				di _n
				di as err `"The {bf:{help synlight}} and {bf:{help weaver}} packages are required. "' _n
				di as err `"please type {ul:{bf:ssc install synlight}} and {ul:{bf:ssc install weaver}} "'
				di as txt "{p}(Synlight is a HTML-based syntax highlighter " ///
						  "for Stata and Weaver provides a handful of " ///
						  "commands for writing dynamic reports in Stata)" _n
				exit 198
				}
		
		
		*LOAD SYNLIGHT LIST
		synlightlist
		

		********************************************************************
		*SYNTAX PROCESSING
		********************************************************************
	
		if "$pandoc" ~= "" {
					confirm file "$pandoc"
					}
					
					
		*define the default file format
		if "`export'" == "" {
				local export html
				}
				
		local input `smclfile'	
		
		if (!index(lower("`input'"),".smcl")) {
*				local convert "`input'.`export'"
				local prehtml "`input'_temp_.html"
				local html "`input'.html"
				local pdf "`input'.pdf"
*				local corrected  "`input'_temp.smcl"
*				local output  "`input'.txt"
*				local md  "`input'.md"
				local input  "`input'.smcl"
				}
		
		
		*check the printer names
		if "$printer" == "princexml" | "$printer" == "" {
				global printer prince
				}
		
		if "$printer" == "wk" | "$printer" == "WK" {
				global printer wkhtmltopdf
				}
				
		if "$printer" ~= "" & "$printer" ~= "prince" & "$printer" ///
		~= "wkhtmltopdf" {
		
				di as err "$printer printer is not available. {bf:princexml} " ///
						  "or {bf:wkhtmltopdf} is expected."
                exit 198
				}
				
		/*check that printer and setpath both are used together */
        if "$printer" == "" & "$setpath" != "" {
		
                di as err `"If {bf:ptinter path} specified,"' ///
				`"the {bf:printer(name) option should also be specified}"'
                exit 198
				} 
				
				
		if "$setpath" ~= "" {
				confirm file "$setpath"
				}

				
		* DEFINE THE ACCEPTABLE FILE FORMATS
		
		if "`export'" ~= "pdf" & "`export'" ~= "PDF" & ///
		"`export'" ~= "html" & "`export'" ~= "HTML" & ///
		"`export'" ~= "" {
		
				di as err ///
				`"file formats in export option can be {bf:html} or"' ///
				`" {bf:pdf}"'
                exit 198
				}
		
		* CHECK THE SPECIFIED STYLE
		if "`style'" ~= "" & "`style'" ~= "modern" & "`style'" ~= "minimal" ///
				& "`style'" ~= "elegant" & "`style'" ~= "classic" ///
				& "`style'" ~= "stata" & "`style'" ~= "plain" {
				
				di as err `"Style option can be {bf:classic}, {bf:modern},"' ///
				`" {bf:stata}, {bf:elegant}, {bf:plain}, or {bf:minimal}"'
                exit 198
				}
		
		
		* DEFINE THE DEFAULT STYLE
		if "`style'" == "" {
				local style modern
						}
		
		* MODERN STYLE FONT
		if "`style'" == "modern" {
				if "`font'"=="" & "$printer"=="prince" {
						local font Calibri, Arial, Helvetica, sans-serif
						}
						
				if "`font'"=="" & "$printer"~="prince" {
						local font Arial, Helvetica, sans-serif
						}

				
				local fc #345A8A;
						
				}
		
		* CLASSIC STYLE FONT
		if "`style'" == "classic" {
				if "`font'"=="" {
						local font Times New Roman, Times, serif
						}

				local fc black;			
				}
		
		* MINIMAL STYLE FONT
		if "`style'" == "minimal" {
				if "`font'"=="" {
						local font Courier New, Courier, monospace
						}	
				local fc black;			
				}
		
		* ELEGANT STYLE FONT
		if "`style'" == "elegant" | "`style'" == "plain" {
				if "`font'"=="" & "$printer"=="prince" {
						local font Calibri, Arial, Helvetica, sans-serif
						}
				if "`font'"=="" & "$printer"~="prince" {
						local font Arial, Helvetica, sans-serif
						}	
				local fc #6D6D6D;		
				}

		* STATA STYLE FONT
		if "`style'" == "stata" {
				if "`font'"=="" & "$printer"=="prince" {
						local font Calibri, Arial, Helvetica, sans-serif
						}
				if "`font'"=="" & "$printer"~="prince" {
						local font Arial, Helvetica, sans-serif
						}		
				local fc #969C9D;		
				}

				
			
		********************************************************************
		*PROCESSING THE SMCL FILE : PART 1
		********************************************************************
		
		*tempnames & tempfiles
		tempfile tmp
		tempname hitch canvas 
		qui file open `hitch' using `"`input'"', read
		qui file open `canvas' using `"`tmp'"', write replace
		file write `canvas'  _newline 
		file read `hitch' line
	
		while r(eof) == 0 {				


				*RENAMING BACKSLASH FOR PANDOC
				local line : subinstr local line "\" `"BkLsH"', all
						
				local word1 : word 1 of `"`line'"'

				*>removing indents 
				foreach i of numlist 64/0  {						
						local indent : di _dup(`i') " "
						local b = `i'+1
						
						*removing the indents after ">"				
						if substr(`"`word1'"',1,2) == "> " {						
								local indent : di _dup(`b') " "
								local line : subinstr local line ///
								`">`indent'"' ">", all
								}
								
								
						*Indents after after "."
						if substr(`"`word1'"',1,`b') == ".`indent'" ///
						& `"`line'"' >= ".`indent'" {
								local line : subinstr local line ///
								`".`indent'"' ".", all
								}
						
						*Indents after after "{com}."
						local b = `i'+7
						if substr(`"`word1'"',1,`b') == "{com}. `indent'" {
								cap local line : subinstr local line ///
								"{com}. `indent'" "{com}. ", all
								}
						}
						
						
				*> replacing the "dots" with "{com}. "
				if substr(`"`word1'"',1,1) == "." & `"`line'"' > "." {	
						local h : di substr(`"`macval(line)'"',2,.) 
						local line `"{com}. `macval(h)'"'
						}

				local line : subinstr local line `"{com}. /*"' ">", all
				local line : subinstr local line `"{com}. *"' ">", all
				local line : subinstr local line `"{com}. //"' ">", all
				
				*remove qui log c
				local line : subinstr local line "{com}. qui log c" "", all
				
				*remove "*/"	
				if `"`line'"' == ">*/" | `"`line'"' == ">*/ " {
						local line : subinstr local line ">*/" "", all	
						}
				
				file write `canvas' `"`macval(line)'"' _n 
				file read `hitch' line
				
				}

		file close `canvas'
		file close `hitch'

		
		********************************************************************
		*PROCESSING SMCL: PART 2
		********************************************************************

		
		*tempnames & tempfiles
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using "`tmp'", read
		qui file open `canvas' using `"`tmp1'"', write replace
		file write `canvas' _newline 
		file read `hitch' line
	
		while r(eof) == 0 {				
				
				local jump
				
				local word1 : word 1 of `"`line'"'
						
				*removing further indents
				foreach i of numlist 64/1  {						
						if substr(`"`word1'"',1,1) == ">" {	
								local indent : di _dup(`i') " "
								local line : subinstr local line ///
								">`indent'" ">", all
								}
						}
						
				*removing the lines that only have "{com}. "
				if substr(`"`word1'"',1,`b') == "{com}. " ///
				& `"`line'"' == "{com}. " {
						local jump jump
						}
						
				*removing the lines that only have "."
				if substr(`"`word1'"',1,1) == "." & `"`line'"' == "." {		
						local jump jump
						}			
	
				*> Jump over "Jump" lines
				if "`jump'" == "" {	
						file write `canvas' `"`macval(line)'"' _n 
						}
				
				local space

				if substr(`"`word1'"',1,7) == "{com}. " ///
				& `"`line'"' > "{com}. "{
						local space space
						}
				
				file read `hitch' line
				}

		qui file close `canvas'
		qui file close `hitch'		
		
		

		********************************************************************
		*PROCESSING SMCL: APPENDING LONG LINES IN COMMANDS AND BRACES
		********************************************************************
		
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read
		qui file open `canvas' using `"`tmp1'"', write replace
		file write `canvas'  _newline 
		file read `hitch' line
	
		while r(eof) == 0 {
				local word1 : word 1 of `"`line'"'
				
				*> APPENDING LINES WITH "///" IN COMMAND
				if substr(`"`word1'"',1,7) == "{com}. " & ///
				substr(`"`word1'"',-4,.) == " ///" {
						
					local host `"`macval(line)'"'
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						
						while substr(`"`word1'"',1,1) == ">" {
								local line : di substr(`"`macval(line)'"',2,.)
								local host `"`macval(host)'"' " " `"`macval(line)'"'
								
								file read `hitch' line
								local word1 : word 1 of `"`line'"'
								}
								
						file write `canvas' `"`macval(host)'"' _n
						}
				
				
				
				
				*> APPENDING LINES WITH "///" IN BRACE
				if substr(`"`word1'"',9,7) == "{com}. " & ///
				substr(`"`word1'"',-4,.) == " ///" {
						local host `"`macval(line)'"'
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						
						while substr(`"`word1'"',1,1) == ">" {
								local line : di substr(`"`macval(line)'"',2,.)
								local host `"`macval(host)'"' " " `"`macval(line)'"'
								
								file read `hitch' line
								local word1 : word 1 of `"`line'"'
								}
								
						file write `canvas' `"`macval(host)'"' _n
						}
						
				
				
				
				
				*> APPENDING LINES WITH "/* */ in COMAMND"
				if substr(`"`word1'"',1,7) == "{com}. " & ///
				substr(`"`word1'"',-3,.) == " /*" {
				
						local line : subinstr local line "/*" "/* <br />"
						local host `"`macval(line)'"'
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						
						while substr(`"`word1'"',1,1) == ">" {
								
								if substr(`"`word1'"',-3,.) == " /*" {
										local line : subinstr local line "/*" "/* <br />"
										}
										
								local line : di substr(`"`macval(line)'"',2,.)
								local host `"`macval(host)'"' " " `"`macval(line)'"'
								
								file read `hitch' line
								local word1 : word 1 of `"`line'"'
								}
								
						file write `canvas' `"`macval(host)'"' _n
						}
				
				
				
				*> APPENDING LINES WITH "/* */ in BRACE"
				if substr(`"`word1'"',9,7) == "{com}. " & ///
				substr(`"`word1'"',-3,.) == " /*" {
				
						local line : subinstr local line "/*" "/* <br />"
						local host `"`macval(line)'"'
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						
						while substr(`"`word1'"',1,1) == ">" {
								
								if substr(`"`word1'"',-3,.) == " /*" {
										local line : subinstr local line "/*" "/* <br />"
										}
										
								local line : di substr(`"`macval(line)'"',2,.)
								local host `"`macval(host)'"' " " `"`macval(line)'"'
								
								file read `hitch' line
								local word1 : word 1 of `"`line'"'
								}
								
						file write `canvas' `"`macval(host)'"' _n
						}
				
				
				file write `canvas' `"`macval(line)'"' _n
				file read `hitch' line
				}

		qui file close `canvas'
		qui file close `hitch'
		

		********************************************************************
		*PRIMARY SYNTAX HIGHLIGHTING: NUMBERS , QUOTES , MACROS
		********************************************************************
		
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read
		qui file open `canvas' using `"`tmp1'"', write replace
		file write `canvas'  _newline 
		file read `hitch' line
	
		while r(eof) == 0 {	
				
				local word1 : word 1 of `"`line'"'
						
				
				/* BRACES SYNTAX HIGHLIGHT */
				if substr(`"`word1'"',1,5) == "{txt}" & ///
				substr(`"`word1'"',9,6) == "{com}." { 

if "`nolight'" == "" {					
						/* RENAMING DOLLAR SIGN IN BRACES */
						local line : subinstr local line "$" ///
						`"<span class="macro">DOLLARSIGN</span>"', all
						
						/* RENAMING DOLLAR SIGN IN BRACES */
						local line : subinstr local line "^" ///
						`"SUPERSCRIPTSIGN"', all
						
						/* RENAMING DOLLAR SIGN IN BRACES */
						local line : subinstr local line "~" ///
						`"EQUIVALENCYSIGN"', all
					
						local a : di substr(`"`macval(line)'"',1,14)
						local line : di substr(`"`macval(line)'"',15,.)
						
						/* RENAMING THE NUMBERS IN BRACES (TO FIX PANDOC PROBLEMS) */
						local line : subinstr local line "0" "OrEzZ", all
						local line : subinstr local line "1" "EnOO", all
						local line : subinstr local line "2" "OwTT", all
						local line : subinstr local line "3" "EeRhR", all
						local line : subinstr local line "4" "RuOfF", all
						local line : subinstr local line "5" "EvIfF", all
						local line : subinstr local line "6" "XiSsS", all
						local line : subinstr local line "7" "NeVeSS", all
						local line : subinstr local line "8" "ThGiE", all
						local line : subinstr local line "9" "EnInN", all

						local line `"`macval(a)'"'`"`macval(line)'"'
}						
						
if "`nolight'" == "nolight" {	
local line : subinstr local line "$" "DOLLARSIGN", all
local line : subinstr local line "^" `"SUPERSCRIPTSIGN"', all
local line : subinstr local line "~" `"EQUIVALENCYSIGN"', all
}					
						
						
						}
						
						
				
				
				
				

				
				/* COMMAND SYNTAX HIGHLIGHT */
				if substr(`"`word1'"',1,7) == "{com}. "  { 

						if "`nolight'" == "nolight" {	
								local line : subinstr local line "$" "DOLLARSIGN", all
								local line : subinstr local line "^" `"SUPERSCRIPTSIGN"', all
								local line : subinstr local line "~" `"EQUIVALENCYSIGN"', all
								}

				
						if "`nolight'" == "" {					
								local line : subinstr local line "$" ///
								`"<span class="macro">DOLLARSIGN</span>"', all
						
								/* RENAMING DOLLAR SIGN IN BRACES */
								local line : subinstr local line "^" ///
								`"SUPERSCRIPTSIGN"', all
						
								/* RENAMING DOLLAR SIGN IN BRACES */
								local line : subinstr local line "~" ///
								`"EQUIVALENCYSIGN"', all

					
								/*COMMAND GLOBAL MACRO SYNTAX HIGHLIGHTING */
								local b  `"`macval(line)'"'
						
								foreach word of local line {
						
										if substr(`"`word'"', 1, 31) == ///
										`"class="macro">DOLLARSIGN</span>"' {
								
												local word0 : di substr(`"`word'"',32,.)

												local b : di subinstr(`"`macval(b)'"',`"`word'"', ///
												`"class="macro">DOLLARSIGN</span><span class="macro">`word0'</span>"',1)
												}
										}
						
								
								local line  `"`macval(b)'"'

				
						
						/* NUMBERS HIGHLIGHT */
						foreach word of local line {
						
								local word2 `"`macval(word)'"'
						
								if substr(`"`macval(word)'"', 1, 1) == "." | ///
								   substr(`"`macval(word)'"', 1, 1) == "/" | ///
								   substr(`"`macval(word)'"', 1, 1) == "(" | ///
								   substr(`"`macval(word)'"', 1, 1) == "[" | ///
								   substr(`"`macval(word)'"', 1, 1) == "+" | ///
								   substr(`"`macval(word)'"', 1, 1) == "-" | ///
								   substr(`"`macval(word)'"', 1, 1) == "0" | ///
								   substr(`"`macval(word)'"', 1, 1) == "1" | ///
								   substr(`"`macval(word)'"', 1, 1) == "2" | ///
								   substr(`"`macval(word)'"', 1, 1) == "3" | ///
								   substr(`"`macval(word)'"', 1, 1) == "4" | ///
								   substr(`"`macval(word)'"', 1, 1) == "5" | ///
								   substr(`"`macval(word)'"', 1, 1) == "6" | ///
								   substr(`"`macval(word)'"', 1, 1) == "7" | ///
								   substr(`"`macval(word)'"', 1, 1) == "8" | ///
								   substr(`"`macval(word)'"', 1, 1) == "9" {
						
											/* RENAMING THE NUMBERS IN BRACES (TO FIX PANDOC) */
											local word : subinstr local word "0" "OrEzZ", all
											local word : subinstr local word "1" "EnOO", all
											local word : subinstr local word "2" "OwTT", all
											local word : subinstr local word "3" "EeRhR", all
											local word : subinstr local word "4" "RuOfF", all
											local word : subinstr local word "5" "EvIfF", all
											local word : subinstr local word "6" "XiSsS", all
											local word : subinstr local word "7" "NeVeSS", all
											local word : subinstr local word "8" "ThGiE", all
											local word : subinstr local word "9" "EnInN", all
						
											local line : subinstr local line "`word2'" "`word'"
											}
									}
							}
									
						}

				file write `canvas' `"`macval(line)'"' _n 
				file read `hitch' line
				}

		file close `canvas'
		file close `hitch'
		
		
			

		
		********************************************************************
		*TRANSLATING SMCL TO TXT
		********************************************************************
		
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		
		tempfile tmp1
		qui translate "`tmp'" "`tmp1'", trans(smcl2txt) replace
				
		********************************************************************
		*PROCESSING TXT: APPENDING LONG LINES IN COMMANDS AND BRACES
		********************************************************************
		
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace
		file write `canvas'  _newline
		file read `hitch' line	
		while r(eof) == 0 {
				local word1 : word 1 of `"`line'"'
				
				/* COMMAND LINES */
				if substr(`"`word1'"',1,6) ~= "      " {
						
						local host `"`macval(line)'"'
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
								
						while substr(`"`word1'"',1,8) == "      > " {
								local line : subinstr local line "      > " "", all
								local host `"`macval(host)'"'`"`macval(line)'"'
								
								file read `hitch' line
								local word1 : word 1 of `"`line'"'
								}

						file write `canvas' `"`macval(host)'"' _n				
						}
						
				
				/* BRACES LINES */
				if substr(`"`word1'"',1,6) == "      " & /// 
				substr(`"`word1'"',10,1) == "."  {
						
						local host `"`macval(line)'"'
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						
						if substr(`"`word1'"',1,8) == "      > " {
								
								while substr(`"`word1'"',1,8) == "      > " {
										local line : subinstr local line "      > " "", all
										local host `"`macval(host)'"'`"`macval(line)'"'
								
										file read `hitch' line
										local word1 : word 1 of `"`line'"'
										}	
								}
								
						file write `canvas' `"`macval(host)'"' _n
						}
				
				
				
				/* OUT PUTS */
				if substr(`"`word1'"',1,6) == "      " & /// 
				substr(`"`word1'"',10,1) ~= "." & ///
				`"`line'"' ~= "      " & ///
				`"`line'"' ~= "      >" {
						
						local host `"`macval(line)'"'
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						
								while substr(`"`word1'"',1,8) == "      > " {
										local line : subinstr local line "      > " "", all
										local host `"`macval(host)'"'`"`macval(line)'"'
								
										file read `hitch' line
										local word1 : word 1 of `"`line'"'
										}	

						file write `canvas' `"`macval(host)'"' _n

						}
						
				file write `canvas' `"`macval(line)'"' _n
				file read `hitch' line
				}
				
		file close `canvas'
		file close `hitch'
	
		********************************************************************
		*PROCESSING TXT: ADDING AN EMPTY LINE BETWEEN COMMAND AND OUTPUT
		********************************************************************

		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace
		file write `canvas'  _newline
		file read `hitch' line	
		while r(eof) == 0 {
		
				local word1 : word 1 of `"`line'"'
				
				if substr(`"`word1'"',1,6) ~= "      " {
						file write `canvas' `"`macval(line)'"' _n	
						
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						
						if `"`line'"' ~= "      " & ///
						substr(`"`word1'"',10,1) ~= "." {
								file write `canvas' "      " _n
								}	
						}
						
				file write `canvas' `"`macval(line)'"' _n  
				file read `hitch' line
				
				}			
		file close `canvas'
		file close `hitch'
		

		********************************************************************
		*REMOVING COMMANDS THAT BEGIN WITH KNIT, KN, OR IMG
		********************************************************************
		
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace
		file write `canvas'  _newline
		file read `hitch' line	
		while r(eof) == 0 {
		
				local word1 : word 1 of `"`line'"'
				
				if substr(`"`word1'"',1,6) ~= "      " & ///
				substr(`"`word1'"',8,1) == "." & ///
				substr(`"`word1'"',10,5) == "knit " | ///
				substr(`"`word1'"',1,6) ~= "      " & ///
				substr(`"`word1'"',8,1) == "." & ///
				substr(`"`word1'"',10,3) == "kn " | ///
				substr(`"`word1'"',1,6) ~= "      " & ///
				substr(`"`word1'"',8,1) == "." & ///
				substr(`"`word1'"',10,4) == "img " {
						
						file write `canvas' `"      "' _n
						file read `hitch' line
						local word1 : word 1 of `"`line'"'
						}	
						
						
				if substr(`"`word1'"',1,16) == "      >knitted: " {
						
						local line : subinstr local line "      >knitted: " "      >"
						
						local line : subinstr local line "*----" "<h4>", all
						local line : subinstr local line "----*" "</h4>", all
						
						local line : subinstr local line "*---" "<h3>", all
						local line : subinstr local line "---*" "</h3>", all
						
						local line : subinstr local line "*--" "<h2>", all
						local line : subinstr local line "--*" "</h2>", all
						
						local line : subinstr local line "*-" "<h1>", all
						local line : subinstr local line "-*" "</h1>", all
						
						local line : subinstr local line "#*" "<u>", all
						local line : subinstr local line "*#" "</u>", all
						
						local line : subinstr local line "#___" "<strong><em>", all
						local line : subinstr local line "___#" "</em></strong>", all
						
						local line : subinstr local line "#__" "<strong>", all
						local line : subinstr local line "__#" "</strong>", all
						
						local line : subinstr local line "#_" "<em>", all
						local line : subinstr local line "_#" "</em>", all
						
						}
		
				file write `canvas' `"`macval(line)'"' _n  
				file read `hitch' line
				
				}			
		file close `canvas'
		file close `hitch'

		
		********************************************************************
		*SECONDARY SYNTAX HIGHLIGHTING: COMMENT & STRING
		********************************************************************
if "`nolight'" == "" {
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace
		file write `canvas'  _newline
		file read `hitch' line	
		while r(eof) == 0 {
				local word1 : word 1 of `"`line'"'
				
				if substr(`"`word1'"',1,6) ~= "      " & ///
				substr(`"`word1'"',8,1) == "." & ///
				substr(`"`word1'"',10,5) == "knit " {
						
						file read `hitch' line
						
						}
						
				if substr(`"`word1'"',1,6) ~= "      " {
						local line : subinstr local line ///
						"/*" `"<span class="comment"> &#47;&#42;"', all
						
						local line : subinstr local line ///
						"*/" `"&#42;&#47; </span>"', all
						
						local line : subinstr local line ///
						"`" `"<span class="macro">&#96;"' , all
						
						local line : subinstr local line ///
						"'" "&#39;</span>" , all
						
						
						/* COMMAND HIGHLIGHT */
						foreach com of global synlightlist {
						
								*If the command appears at the end of the line
								local a : di length("`com'")
								local a = -`a'
								if substr(`"`line'"',`a',.) == "`com'" { 
										local line : subinstr local line " `com'" ///
										`" <span class="command">`com'</span>"', all
										}
										
								else {
										local line : subinstr local line " `com' " ///
										`" <span class="command">`com'</span> "', all
										}
								}
								
								
								
						/* FUNCTIONS HIGHLIGHT */
						foreach fun of global synfunclist {
								local a : di length("`fun'")
								local a = `a'-1
								local a : di substr("`fun'",1,`a')
								local line : subinstr local line " `fun'" ///
								`" <span class="function">`a'</span>("', all
								}		

						}
						
				file write `canvas' `"`macval(line)'"' _n		
				file read `hitch' line
				}
				
		file close `canvas'
		file close `hitch'
		
}

				
		********************************************************************
		*CREATING THE PRIMARY MARKDOWN FILE
		********************************************************************
	
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace
		
		file write `canvas'  _newline
		file read `hitch' line	
				
		*addiitonal corrections
		while r(eof) == 0 {
				local word1 : word 1 of `"`line'"'

				
				*Adding CODE TO INCLUDE THE BRACES
				if substr(`"`word1'"',1,6) ~= "      " ///
				& `"`line'"' > "" {
						local a : di substr(`"`macval(line)'"',1,6) 
						local b : di substr(`"`macval(line)'"',9,.) 
						local a : di ///
						`"<span style="white-space:pre;color:`fc'">"'`"`macval(a)'"'`".  </span>"'
						
						local line `"`macval(a)'"'`"`macval(b)'"'
						
						file write `canvas' `"      "' _n(2)
						file write `canvas' `"<code>"' _n
						file write `canvas' `"`macval(line)'"' _n  
						file read `hitch' line
						
						local word1 : word 1 of `"`line'"'
						
						if substr(`"`word1'"',1,10) == "        2." { 
								while substr(`"`word1'"',10,1) == "." {
										
if "`nolight'" == "" {										
										local line : subinstr local line ///
										"`" `"<span class="macro">&#96;"' , all
										
										local line : subinstr local line ///
										"'" "&#39;</span>" , all
}


if "`nolight'" == "nolight" {	
										local line : subinstr local line ///
										"`" "&#96;" , all
										
										local line : subinstr local line ///
										"'" "&#39;" , all
}									

										file write `canvas' `"<br />"'`"`macval(line)'"' _n 
										file read `hitch' line
										local word1 : word 1 of `"`line'"'
										}
								}
								
						file write `canvas' `"</code>"' _n(2)
						}
						
						
						
						
				
				if substr(`"`word1'"',1,7) == "      >" {
						local line : subinstr local line "      > " "", all
						local line : subinstr local line "      >" "", all	
						}
				
				if substr(`"`word1'"',1,7) == "      *" {
						local line : subinstr local line "      * " "", all
						local line : subinstr local line "      *" "", all	
						}
						
				if substr(`"`word1'"',1,8) == "       >" {
						local line : subinstr local line "       > " "", all
						local line : subinstr local line "       >" "", all	
						}			
				
				if substr(`"`word1'"',1,8) == "       *" {
						local line : subinstr local line "       * " "", all	
						local line : subinstr local line "       *" "", all	
						}
				

				*with all due respect, removing the Stata trademark!
				local line : subinstr local line "___  ____  ____  ____  ____(R)" "", all
				local line : subinstr local line "/__    /   ____/   /   ____/ " "", all
				local line : subinstr local line "___/   /   /___/   /   /___/" "", all
				local line : subinstr local line "Statistics/Data Analysis " "", all
						

				file write `canvas' `"`macval(line)'"' _n  
				file read `hitch' line
				}
				
		*> clsoe the HTML template				
		file close `canvas'
		file close `hitch'
			
		*erase translated logfile (output.txt) 
*		cap qui erase "`output'"


		
		********************************************************************
		*SYNTAX HIGHLIGHTING: COMMANDS AND FUNCTIONS IN BRACES
		********************************************************************
if "`nolight'" == "" {
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace
		file write `canvas'  _newline
		file read `hitch' line	
				

		while r(eof) == 0 {
		
				local word1 : word 1 of `"`line'"'
				
				if substr(`"`word1'"',1,11) == "<br />     " {
						
						/* COMMAND HIGHLIGHT */
						foreach com of global synlightlist {
								*If the command appears at the end of the line
								local a : di length("`com'")
								local a = -`a'
								
								if substr(`"`macval(line)'"',`a',.) == "`com'" { 
										local line : subinstr local line " `com'" ///
										`" <span class="command">`com'</span>"', all
										}
										
								else {
										local line : subinstr local line " `com' " ///
										`" <span class="command">`com'</span> "', all
										}
								}
								
						
						/* FUNCTIONS HIGHLIGHT */
						foreach fun of global synfunclist {
								local a : di length("`fun'")
								local a = `a'-1
								local a : di substr("`fun'",1,`a')
								local line : subinstr local line " `fun'" ///
								`" <span class="function">`a'</span>("', all
								}				
						}
				
				file write `canvas' `"`macval(line)'"' _n  
				file read `hitch' line
				}
		file close `canvas'
		file close `hitch'
		
}		
	
			
		********************************************************************
		*PRESERVING THE WHITE SPACE IN THE BRACES
		********************************************************************		
		
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace
		file write `canvas'  _newline
		file read `hitch' line	
				

		while r(eof) == 0 {
		
				local word1 : word 1 of `"`line'"'
				
				if substr(`"`word1'"',1,11) == "<br />     " {
						
						
						
						*add indent
						if substr(`"`word1'"',1,14) == "<br />        " {
								local line : subinstr local line "<br />     " "<br />&#32;&#32;&#32;&#32;"
								foreach i of numlist 40(8)8 {
										local indent : di _dup(`i') " "
										local subs : di _dup(`i') "&#32;"
										local line : subinstr local line `"`indent'"' `"`subs'"'
										}
								}
						
						if substr(`"`word1'"',1,14) ~= "<br />        " & ///
						substr(`"`word1'"',1,13) == "<br />       " {
								local line : subinstr local line "<br />     " "<br />&#32;&#32;&#32;"
								foreach i of numlist 40(8)8 {
										local i = `i'
										local indent : di _dup(`i') " "
										local subs : di _dup(`i') "&#32;"
										local line : subinstr local line `"`indent'"' `"`subs'"'
										}
								}

								
						if substr(`"`word1'"',1,13) ~= "<br />       " & ///
						substr(`"`word1'"',1,12) == "<br />      " {
								local line : subinstr local line "<br />    " "<br />&#32;&#32;"
								foreach i of numlist 40(8)8 {
										local i = `i'
										local indent : di _dup(`i') " "
										local subs : di _dup(`i') "&#32;"
										local line : subinstr local line `"`indent'"' `"`subs'"'
										}
								}
								
						
						}
				
				file write `canvas' `"`macval(line)'"' _n  
				file read `hitch' line
				}
		file close `canvas'
		file close `hitch'
		
		
		********************************************************************
		*ADDING THE HTML CODES TO MARKDOWN FILE
		********************************************************************
		
		tempfile tmp
		quietly  copy `"`tmp1'"' `"`tmp'"', replace
		tempfile tmp1
		tempname hitch canvas 
		qui file open `hitch' using `"`tmp'"', read 
		qui cap file open `canvas' using "`tmp1'", write replace

		file write `canvas' "<!doctype html>" _n
		file write `canvas' "<html>" _n 
		file write `canvas' "<head>" _n ///

		
		file write `canvas' _n(2) "<!-- SYNTAX HIGHLIGHTING CLASSES  -->" _newline(2) 
		file write `canvas' `"<style type="text/css">"' _newline
		file write `canvas' ".command{color:#00008A;}" _newline
		file write `canvas' ".function{color:#00F;}" _newline
		file write `canvas' ".macro{color:#008080;}" _newline
		file write `canvas' ".string{color:#800000;}" _newline
		file write `canvas' ".digit{color:#0070FF;}" _newline 
		file write `canvas' ".comment{color:#0F7F11;}" _newline 
		file write `canvas' ".brace{color:#FF2600;}" _newline 
		file write `canvas' ".sign{color:#000;}" _newline 
		file write `canvas' ".error{color:#F00;}" _newline(2)
		
		file write `canvas' ".string > .macro {color:#800000;}" _newline
		file write `canvas' ".string > .digit {color:#800000;}" _newline
		file write `canvas' ".string > .command {color:#800000;}" _newline
		file write `canvas' ".string > .function {color:#800000;}" _newline(2)

		file write `canvas' ".comment > .macro {color:#0F7F11;}" _newline
		file write `canvas' ".comment > .digit {color:#0F7F11;}" _newline
		file write `canvas' ".comment > .command {color:#0F7F11;}" _newline
		file write `canvas' ".comment > .string {color:#0F7F11;}" _newline
		file write `canvas' ".comment > .function {color:#0F7F11;}" _newline(2)
		
		file write `canvas' ".author {display:block;text-align:center;font-size:16px;margin-bottom:3px;}" _newline
		
		file write `canvas' ".center, #center {" _newline ///
		_skip(4) "display: block;" _newline ///
		_skip(4) "margin-left: auto;" _newline ///
		_skip(4) "margin-right: auto;" _newline ///
		_skip(4) "-webkit-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(4) "-moz-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(4) "box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n(2) ///
		_skip(4) "padding: 0px;" _newline ///
		_skip(4) "border-width: 0px;" _newline ///
		_skip(4) "border-style: solid;" _newline ///
		_skip(4) "cursor:-webkit-zoom-in;" _newline ///
		_skip(4) "cursor:-moz-zoom-in;" _newline ///
		_skip(4) "}" _newline(2) ///
		"pagebreak {" _newline ///
		_skip(8) "page-break-before: always;" _newline ///
		_skip(8) "}" _newline(2) ///
".pagebreak, #pagebreak {" _newline ///
		_skip(8) "page-break-before: always;" _newline ///
		_skip(8) "}" _newline(2) 
		
		file write `canvas' "td > p {padding:0; margin:0;}" _newline
		
		
		file write `canvas' "</style>" _n(4)
		
		
		
/* MODERN (DEFAULT) STYLE */
		
		if "`style'" == "" | "`style'" == "modern" {
		
		file write `canvas' _n(2) "<!-- Modern Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"body {" _newline(2) ///
		_skip(8) "margin:10px 30px 10px 30px;" _newline /// 
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		`" @top-left "' ///
		`"{ content: "`runhead'" ; font-size:11px; margin-top:5px; } "' _n /// 
		"@bottom {" _newline ///
		_skip(8) `"content: "Page " counter(page); font-size:14px; "' _n ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
		"@page:first {" _newline ///
		"@top-left {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		"@bottom {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:5px; " _newline ///
		_skip(8) "margin:0;" _newline ///
		_skip(8) "padding-top:150px; " _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "background-color:white; " _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "display:block;" _newline ///
		_skip(8) "}" _newline(2) ///
"ul {"	_skip(8) "list-style:circle;" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "margin-bottom:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul a {" _newline ///
		_skip(8) "color:black;" _newline ///
		_skip(8) "text-decoration:none;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul {" _newline ///
		_skip(8) "list-style: none;" _newline ///
		_skip(8) "margin: 0px 0 10px -15px;" _newline ///
		_skip(8) "padding-left:15px;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul li {" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "margin-top:20px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"div ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "margin-left:20px;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:none;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///		
"img {" _newline ///
		_skip(8) "margin: 5px 0 5px 0;" _newline ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "display:inline-block;" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "clear: both;" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "color:#17365D;" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "color:#345A8A;" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4 {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5  {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6  {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:14px;" _n ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "text-align:justify;" _n  ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "text-justify:inter-word;" _n ///
		_skip(8) "margin:0 0 14px 0;" _n ///
		_skip(8) "}" _newline(2) ///							
".code {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding:5px;" _n   /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:12px;" _newline ///
		_skip(8) "line-height:14px;" _newline ///
		_skip(8) "background-color:#E1E6F0;" _newline ///
		_skip(8) `"font-family:"Lucida Console", Monaco, monospace, "Courier New", Courier, monospace;"' _newline ///
		_skip(8) "font-weight:normal;" _n  ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #345A8A; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "margin:20px 0 0px 0;" _n   ///
		_skip(8) "}" _newline(2) ///		
".output {" _newline ///
	  	_skip(8) "white-space:pre;" _newline ///
		_skip(8) "display:block;" _n  ///
		_skip(8) `"font-family:monospace,"Lucida Console", Monaco, "Courier New", Courier, monospace;"' _newline ///
		_skip(8) "font-size:12px; " _newline ///
		_skip(8) "line-height: 12px;" _newline ///
		_skip(8) "margin:0 0 14px 0;" _n  ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "border-color: #345A8A; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:14px 5px 0 5px;" _n  ///
		_skip(8) "border-top-style:none;" _newline /// 
		_skip(8) "background-color:transparent;" _n ///
		_skip(8) "}" _newline(2) 
	
if "$printer" == "prince" | "$printer" == "princexml" {
			
		file write `canvas' "@media print {" _n ///
		_skip(8) ".code {line-height:8px;padding:6px;}" _n ///	
		_skip(8) "}" _n(2) 	
		}
			
file write `canvas' "</style>" _newline(4)
}		

		


		/* Stata STYLE */
		
		if "`style'" == "stata" {
		
		file write `canvas' _n(2) "<!-- Stata Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"body {" _newline(2) ///
		_skip(8) "margin:10px 30px 10px 30px;" _newline /// 
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		`" @top-left "' ///
		`"{ content: "`runhead'" ; font-size:11px; margin-top:5px; } "' _n /// 
		"@bottom {" _newline ///
		_skip(8) `"content: "Page " counter(page); font-size:14px; "' _n ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
		"@page:first {" _newline ///
		"@top-left {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		"@bottom {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:5px; " _newline ///
		_skip(8) "margin:0;" _newline ///
		_skip(8) "padding-top:150px; " _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "background-color:white; " _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "display:block;" _newline ///
		_skip(8) "}" _newline(2) ///
"ul {"	_skip(8) "list-style:circle;" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "margin-bottom:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul a {" _newline ///
		_skip(8) "color:black;" _newline ///
		_skip(8) "text-decoration:none;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul {" _newline ///
		_skip(8) "list-style: none;" _newline ///
		_skip(8) "margin: 0px 0 10px -15px;" _newline ///
		_skip(8) "padding-left:15px;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul li {" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "margin-top:20px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"div ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "margin-left:20px;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:none;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///		
"img {" _newline ///
		_skip(8) "margin: 5px 0 5px 0;" _newline ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "display:inline-block;" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "clear: both;" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4  {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5  {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6  {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "margin-bottom:10px;" _newline ///
		_skip(8) "text-align:justify;" _n  ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "text-justify:inter-word;" _n ///
		_skip(8) "margin:0 0 14px 0;" _n ///
		_skip(8) "}" _newline(2) ///
".code {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "margin:20px 0 0px 0;" _n   ///
		_skip(8) "padding: 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:12px;" _newline ///
		_skip(8) "line-height:14px;" _newline ///
		_skip(8) `"font-family:"Lucida Console", Monaco, monospace, "Courier New", Courier, monospace;"' _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "background-color:#EAF2F3;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #D2DADC; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "border-radius:2px;" _n ///
		_skip(8) "}" _newline(2) ///				
".output {" _newline ///
	  	_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "display:block;" _n  ///
		_skip(8) `"font-family:monospace,"Lucida Console", Monaco, "Courier New", Courier, monospace;"' _newline ///
		_skip(8) "font-size:12px; " _newline ///
		_skip(8) "line-height: 12px;" _newline ///
		_skip(8) "margin:0 0 14px 0;" _n  ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #D2DADC; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:14px 5px 5px 5px;" _newline ///
		_skip(8) "border-top-style:none;" _newline ///
		_skip(8) "}" _newline(2)	
	
if "$printer" == "prince" | "$printer" == "princexml" {
			
		file write `canvas' "@media print {" _n ///
		_skip(8) ".code {line-height:8px;padding:6px;}" _n ///	
		_skip(8) "}" _n(2) 	
		}
			
file write `canvas' "</style>" _newline(4)
}		

		
		/* CLASSIC STYLE */
		
		if "`style'" == "classic" {
		
		file write `canvas' _n(2) "<!-- CLASSIC Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"body {" _newline(2) ///
		_skip(8) "margin:10px 30px 10px 30px;" _newline /// 
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		`" @top-left "' ///
		`"{ content: "`runhead'" ; font-size:11px; margin-top:5px; } "' _n /// 
		"@bottom {" _newline ///
		_skip(8) `"content: "Page " counter(page); font-size:14px; "' _n ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
		"@page:first {" _newline ///
		"@top-left {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		"@bottom {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:5px; " _newline ///
		_skip(8) "padding-top:150px; " _newline ///
		_skip(8) "margin:0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "background-color:white; " _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "display:block;" _newline ///
		_skip(8) "}" _newline(2) ///
"ul {"	_skip(8) "list-style:circle;" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "margin-bottom:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul a {" _newline ///
		_skip(8) "color:black;" _newline ///
		_skip(8) "text-decoration:none;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul {" _newline ///
		_skip(8) "list-style: none;" _newline ///
		_skip(8) "margin: 0px 0 10px -15px;" _newline ///
		_skip(8) "padding-left:15px;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul li {" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "margin-top:20px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"div ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "margin-left:20px;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:none;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///		
"img {" _newline ///
		_skip(8) "margin: 5px 0 5px 0;" _newline ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "display:inline-block;" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "clear: both;" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4  {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5  {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6  {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "text-align:justify;" _n  ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "text-justify:inter-word;" _n ///
		_skip(8) "margin:0 0 14px 0;" _n ///
		_skip(8) "}" _newline(2) ///
".code {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-weight:normal;" _n  ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #EBEBEB; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
		_skip(8) "}" _newline(2) ///	
".output {" _newline ///
	  	_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "display:block;" _n  ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:12px; " _newline ///
		_skip(8) "line-height: 12px;" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:14px 5px 0px 5px;" _newline ///
		_skip(8) "border-top-style:none;" _newline ///
		_skip(8) "margin:0 0 14px 0;" _n  ///
		_skip(8) "background-color:transparent;" _n ///
		_skip(8) "}" _newline(2) 
	
if "$printer" == "prince" | "$printer" == "princexml" {
			
		file write `canvas' "@media print {" _n ///
		_skip(8) ".code {line-height:8px;padding:6px;}" _n ///	
		_skip(8) "}" _n(2) 	
		}
			
file write `canvas' "</style>" _newline(4)
}		

		
	
	
	
	
		/* MINIMAL STYLE */
		
		if "`style'" == "minimal" {
		
		file write `canvas' _n(2) "<!-- Minimal Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///	
"body {" _newline(2) ///
		_skip(8) "margin:10px 30px 10px 30px;" _newline /// 
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		`" @top-left "' ///
		`"{ content: "`runhead'" ; font-size:11px; margin-top:5px; } "' _n /// 
		"@bottom {" _newline ///
		_skip(8) `"content: "Page " counter(page); font-size:14px; "' _n ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
		"@page:first {" _newline ///
		"@top-left {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		"@bottom {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:5px; " _newline ///
		_skip(8) "margin:0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "background-color:white; " _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "display:block;" _newline ///
		_skip(8) "}" _newline(2) ///		
"ul {"	_skip(8) "list-style:circle;" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "margin-bottom:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul a {" _newline ///
		_skip(8) "color:black;" _newline ///
		_skip(8) "text-decoration:none;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul {" _newline ///
		_skip(8) "list-style: none;" _newline ///
		_skip(8) "margin: 0px 0 10px -15px;" _newline ///
		_skip(8) "padding-left:15px;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul li {" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "margin-top:20px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"div ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "margin-left:20px;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:none;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///		
"img {" _newline ///
		_skip(8) "margin: 5px 0 5px 0;" _newline ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "display:inline-block;" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "clear: both;" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 20px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 17px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 15px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4  {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5  {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6  {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:14px;" _n ///
		_skip(8) "text-align:justify;" _n  ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "text-justify:inter-word;" _n ///
		_skip(8) "margin-bottom:10px;" _newline ///
		_skip(8) "}" _newline(2) ///
".code {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "line-height:14px;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-style: dotted;" _newline ///
		_skip(8) "margin-top:10px;" _newline ///
		_skip(8) "border-radius:10px" ///
		_skip(8) "}" _newline(2) ///
".output {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "display:block;" _n  ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:12px; " _newline ///
		_skip(8) "line-height: 12px;" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:none;" _newline ///
		_skip(8) "padding:14px 0 5px 5px;" _newline ///
		_skip(8) "background-color:transparent;" _n ///
		_skip(8) "}" _newline(2) 	
	
if "$printer" == "prince" {
			
		file write `canvas' "@media print {" _n ///
		_skip(8) ".code {line-height:8px; padding:6px;}" _n ///	
		_skip(8) "}" _n(2) 	
		}
			
file write `canvas' "</style>" _newline(4)
}		

		


		/* ELEGANT STYLE */
		
		if "`style'" == "elegant" {
		
		file write `canvas' _n(2) ///
		"<!-- ELEGANT Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"body {" _newline(2) ///
		_skip(8) "margin:10px 30px 10px 30px;" _newline /// 
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		`" @top-left "' ///
		`"{ content: "`runhead'" ; font-size:11px; margin-top:5px; } "' _n /// 
		"@bottom {" _newline ///
		_skip(8) `"content: "Page " counter(page); font-size:14px; "' _n ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
		"@page:first {" _newline ///
		"@top-left {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		"@bottom {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:5px; " _newline ///
		_skip(8) "margin:0;" _newline ///
		_skip(8) "padding-top:150px; " _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "background-color:white; " _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "display:block;" _newline ///
		_skip(8) "}" _newline(2) ///
"ul {"	_skip(8) "list-style:circle;" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "margin-bottom:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul a {" _newline ///
		_skip(8) "color:black;" _newline ///
		_skip(8) "text-decoration:none;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul {" _newline ///
		_skip(8) "list-style: none;" _newline ///
		_skip(8) "margin: 0px 0 10px -15px;" _newline ///
		_skip(8) "padding-left:15px;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul li {" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "margin-top:20px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"div ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "margin-left:20px;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:none;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///		
"img {" _newline ///
		_skip(8) "margin: 5px 0 5px 0;" _newline ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "display:inline-block;" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "clear: both;" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4  {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5  {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6  {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "text-align:justify;" _n  ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "text-justify:inter-word;" _n ///
		_skip(8) "margin:0 0 14px 0;" _n ///
		_skip(8) "}" _newline(2) ///
".code {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:12px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "line-height:14px;" _newline ///
		_skip(8) `"font-family:"Lucida Console", Monaco, monospace, "Courier New", Courier, monospace;"' _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #EBEBEB; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "border-top-right-radius:3px;" _n /// 
		_skip(8) "border-top-left-radius:3px;" _n ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "margin:7px 0 0 0;" _n   ///
		_skip(8) "}" _newline(2) ///				
".output {" _newline ///
	  	_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:12px; " _newline ///
		_skip(8) "display:block;" _n  ///
		_skip(8) "line-height: 12px;" _newline ///
		_skip(8) "margin:0 0 14px 0;" _n  ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:14px 5px 0 5px;" _newline ///
		_skip(8) "}" _newline(2)			
	
if "$printer" == "prince" | "$printer" == "princexml" {
			
		file write `canvas' "@media print {" _n ///
		_skip(8) ".code {line-height:8px;padding:6px;}" _n ///	
		_skip(8) "}" _n(2) 	
		}
			
file write `canvas' "</style>" _newline(4)
}		







		/* Plain STYLE */
		
		if "`style'" == "plain" {
		
		file write `canvas' _n(2) ///
		"<!-- ELEGANT Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"body {" _newline(2) ///
		_skip(8) "margin:10px 30px 10px 30px;" _newline /// 
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		`" @top-left "' ///
		`"{ content: "`runhead'" ; font-size:11px; margin-top:5px; } "' _n /// 
		"@bottom {" _newline ///
		_skip(8) `"content: "Page " counter(page); font-size:14px; "' _n ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
		"@page:first {" _newline ///
		"@top-left {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		"@bottom {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:5px; " _newline ///
		_skip(8) "margin:0;" _newline ///
		_skip(8) "padding-top:150px; " _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "background-color:white; " _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "display:block;" _newline ///
		_skip(8) "}" _newline(2) ///
"ul {"	_skip(8) "list-style:circle;" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "margin-bottom:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul a {" _newline ///
		_skip(8) "color:black;" _newline ///
		_skip(8) "text-decoration:none;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul {" _newline ///
		_skip(8) "list-style: none;" _newline ///
		_skip(8) "margin: 0px 0 10px -15px;" _newline ///
		_skip(8) "padding-left:15px;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul li {" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "margin-top:20px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"div ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "margin-left:20px;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:none;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///		
"img {" _newline ///
		_skip(8) "margin: 5px 0 5px 0;" _newline ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "display:inline-block;" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "clear: both;" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4  {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5  {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6  {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "text-align:justify;" _n  ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "text-justify:inter-word;" _n ///
		_skip(8) "margin:0 0 14px 0;" _n ///
		_skip(8) "}" _newline(2) ///
".code {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:12px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "line-height:14px;" _newline ///
		_skip(8) `"font-family:"Lucida Console", Monaco, monospace, "Courier New", Courier, monospace;"' _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "}" _newline(2) ///				
".output {" _newline ///
	  	_skip(8) "white-space:pre;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:12px; " _newline ///
		_skip(8) "display:block;" _n  ///
		_skip(8) "line-height: 12px;" _newline ///
		_skip(8) "margin:0 0 14px 36px;" _n  ///
		_skip(8) "padding:14px 5px 0 5px;" _newline ///
		_skip(8) "}" _newline(2)	

	
	
if "$printer" == "prince" | "$printer" == "princexml" {
			
		file write `canvas' "@media print {" _n ///
		_skip(8) ".code {line-height:8px;padding:6px;}" _n ///	
		_skip(8) "}" _n(2) 	
		}
			
file write `canvas' "</style>" _newline(4)
}	




		

		/*----- SMOOTH ZOOM CSS STYLING -----*/
		
		file write `canvas' _n(2) ///
		`"<style type="text/css">"' _newline /// 
		"/* ---- This is Smooth Zoom CSS ---- */" _newline(2) ///
"#lightwrap {" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "position:fixed;" _newline ///
		_skip(8) "top:0;" _newline ///
		_skip(8) "left:0;" _newline ///
		_skip(8) "width:100%;" _newline ///
		_skip(8) "height:100%;" _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "cursor:-webkit-zoom-out;" _newline ///
		_skip(8) "cursor:-moz-zoom-out;" _newline ///
		_skip(8) "z-index:999;" _newline ///
		_skip(8) "}" _newline(2) ///
/// /* overlay covering website */
"#lightbg {" _newline ///
		_skip(8) "position:fixed;" _newline ///
		_skip(8) "display:none;" _newline ///
		_skip(8) "top:0;" _newline ///
		_skip(8) "left:0;" _newline ///
		_skip(8) "width:100%;" _newline ///
		_skip(8) "height:100%;" _newline ///
		_skip(8) "background:rgba(255, 255, 255, .9);}" _newline(2) ///
"#lightwrap img {" _newline ///
		_skip(8) "position:absolute;" _newline ///
		_skip(8) "display:none;" _newline ///
		_skip(8) "cursor:-webkit-zoom-out;cursor:-moz-zoom-out;" _newline ///
		_skip(8) "}" _newline(2) ///
"#lightzoomed {" _newline ///
		_skip(8) "opacity:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"#off-screen {" _newline ///
		_skip(8) "position: fixed;" _newline ///
		_skip(8) "right:100%;" _newline ///
		_skip(8) "opacity: 0;" _newline ///
		_skip(8) "}" _newline(2) ///	
"</style>" _newline(4)

		
		file write `canvas' "</head>" _n ///

		*writing the header
		if "`title'" ~= "" {
				file write `canvas' `"<header>`title'</header>"' _n
				}
		
		file write `canvas' "<body>" _n 
				
		if "`author'" ~= "" {
				file write `canvas' `"<span class="author">`author'</span>"' _n
				}		
				
		if "`affiliation'" ~= "" {
				file write `canvas' `"<span class="author">`affiliation'</span>"' _n
				}			
				
		/* adding the date in the fitst page */
		if "`date'" == "date" {
				file write `canvas' ///
				`"<span style="font-size: 12px;text-align:center;"' ///
				`"display:block; padding: 0 0 30px 0;">"' ///
				`"<span id="spanDate"></span></span>"' _n(2)
				}
						
						
						
		file write `canvas'  _newline
		file read `hitch' line	
		*reading and writing the code
		while r(eof) == 0 {	

		
if "`nolight'" == "" {		
				local word1 : word 1 of `"`line'"'
				
						if substr(`"`word1'"',1,1) ~= "" {
								local line : subinstr local line ///
								"///" `"<span style="color:#0F7F11">///</span><br /><span style="padding-left:40px;"></span>"', all
								}
}								

								

				file write `canvas' `"`macval(line)'"' _n  
				file read `hitch' line
				}
				

						

				*> clsoe the HTML template
				
				
				
				
	/* ---- Markdown Syntax ---- */

	
file write `canvas' _newline(2) "<!-- Markdown Syntax  -->" _newline(2) ///
"<script>" _newline ///
_newline ///
_skip(4) "(function() {" _newline ///
_skip(4) "document.body.innerHTML = document.body.innerHTML" _newline ///
_skip(8) ".replace(/<img/g, '<img rel="`"""'"zoom"`"""'" ')" _n ///
/// defining the H1, H2, H3, H4 symbols
_skip(8) ".replace(/\*----/g, '<h4>')" _newline ///
_skip(8) ".replace(/----\*/g, '</h4><p>')" _newline ///
_skip(8) ".replace(/\*---/g, '<h3>')" _newline ///
_skip(8) ".replace(/---\*/g, '</h3><p>')" _newline ///
_skip(8) ".replace(/\*--/g, '<h2>')" _newline ///
_skip(8) ".replace(/--\*/g, '</h2><p>')" _newline ///
_skip(8) ".replace(/\*-/g, '<h1>')" _newline ///
_skip(8) ".replace(/-\*/g, '</h1><p>')" _newline ///
/// break and pagebreak
_skip(8) ".replace(/page-break/g, '<div class="`"""'"pagebreak"`"""'" ></div>')" _newline ///
_skip(8) ".replace(/line-break/g, '<br />')" _newline ///
_skip(8) ".replace(/\[#\]/g, '</span>')" _newline ///
/// text decoration
_skip(8) ".replace(/#___/g, '<strong><em>')" _newline ///
_skip(8) ".replace(/___#/g, '</em></strong>')" _newline ///
_skip(8) ".replace(/#__/g, '<strong>')" _newline ///
_skip(8) ".replace(/__#/g, '</strong>')"  _newline ///
_skip(8) ".replace(/#_/g, '<em>')" _newline ///
_skip(8) ".replace(/_#/g, '</em>')" _newline ///
_skip(8) ".replace(/#\*_/g, '<u>')" _newline ///
_skip(8) ".replace(/_\*#/g, '</u>')" _newline ///
/// link codes
_skip(8) ".replace(/\[--/g, '<a href=')" _newline ///
_skip(8) ".replace(/\--]\[-/g, ' >')" _newline ///
_skip(8) ".replace(/-\]/g, '</a>')" _newline ///
/// background colors
_skip(8) ".replace(/\[-yellow\]/g, '<span style="`"""'"background-color:#FAE768"`"""'">')" _newline ///
_skip(8) ".replace(/\[-green\]/g, '<span style="`"""'"background-color:#CBEF66"`"""'">')" _newline ///
_skip(8) ".replace(/\[-blue\]/g, '<span style="`"""'"background-color:#ABC5F6"`"""'">')" _newline ///
_skip(8) ".replace(/\[-pink\]/g, '<span style="`"""'"background-color:#F1A8D0"`"""'">')" _newline ///
_skip(8) ".replace(/\[-purple\]/g, '<span style="`"""'"background-color:#D6ABEF"`"""'">')" _newline ///
_skip(8) ".replace(/\[-gray\]/g, '<span style="`"""'"background-color:#D6D6D6"`"""'">')" _newline ///
/// font colors
_skip(8) ".replace(/\[blue\]/g, '<span style="`"""'"color:#00F"`"""'">')" _newline ///
_skip(8) ".replace(/\[pink\]/g, '<span style="`"""'"color:#FF0080"`"""'">')" _newline ///
_skip(8) ".replace(/\[purple\]/g, '<span style="`"""'"color:#8000FF"`"""'">')" _newline ///
_skip(8) ".replace(/\[green\]/g, '<span style="`"""'"color:#408000"`"""'">')" _newline ///
_skip(8) ".replace(/\[orange\]/g, '<span style="`"""'"color:#FF8000"`"""'">')" _newline ///
_skip(8) ".replace(/\[red\]/g, '<span style="`"""'"color:#F00"`"""'">')" _newline ///
/// text positionning 
_skip(8) ".replace(/\[center\]/g, '<span style="`"""'"display:block; text-align:center"`"""'">')" _newline ///
_skip(8) ".replace(/\[right\]/g, '<span style="`"""'"display:block; text-align:right"`"""'">')" _newline ///
_skip(4) "})();" ///
"</script>" _newline(2)

				
				* ---- JavaScript code for date  ---- *
	
				file write `canvas' _n(2) ///
				"<!-- JavaScript Date  -->" _n(2) ///
				"<script type="  `"""'  "text/javascript" `"""' ">" _n ///
				"var months = ['January','February','March'," ///
				"'April','May','June','July','August'," _n ///
				"'September','October','November','December'];" _n ///
				"var ketchupdate = new Date(); ketchupdate" ///
				".setTime(ketchupdate.getTime());" _n ///
				"document.getElementById" ///
				"(" `"""' "spanDate" `"""' ")" _n ///
				".innerHTML = months[ketchupdate.getMonth()]" ///
				"+ " `"""' " " `"""' " + " _n ///
				"ketchupdate.getDate()+ " `"""' ///
				"<sup style=font-size:60%;>th</sup>, " ///
				`"""' " + ketchupdate.getFullYear();" _n ///
				"</script>"  _newline(2)
				
				
	/* Add Jquery */
file write `canvas' `" <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script> "' _newline   


			
	/* ---- JavaScript "Easing" Code ---- */
file write `canvas' _newline(2) "<script>" _newline /// 
"jQuery.easing['jswing'] = jQuery.easing['swing'];" _newline /// 
"jQuery.extend( jQuery.easing," _newline /// 
"{" _newline /// 
		_skip(4) "def: 'easeOutQuad'," _newline /// 
		_skip(4) "swing: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	/// /* --- alert(jQuery.easing.default); --- */
		_skip(6) 	"return jQuery.easing[jQuery.easing.def](x, t, b, c, d);" _n /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInQuad: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*(t/=d)*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutQuad: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c *(t/=d)*(t-2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutQuad: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t + b;" _newline /// 
		_skip(6) 	"return -c/2 * ((--t)*(t-2) - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInCubic: function (x, t, b, c, d) {" _newline /// 
		_skip(4) "return c*(t/=d)*t*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutCubic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*((t=t/d-1)*t*t + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutCubic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t*t + b;" _newline /// 
		_skip(6) 	"return c/2*((t-=2)*t*t + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInQuart: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*(t/=d)*t*t*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutQuart: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c * ((t=t/d-1)*t*t*t - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutQuart: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t*t*t + b;" _newline /// 
		_skip(6) 	"return -c/2 * ((t-=2)*t*t*t - 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInQuint: function (x, t, b, c, d) {" _newline /// 
		_skip(6) "return c*(t/=d)*t*t*t*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutQuint: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*((t=t/d-1)*t*t*t*t + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutQuint: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;" _newline /// 
		_skip(6) 	"return c/2*((t-=2)*t*t*t*t + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInSine: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c * Math.cos(t/d * (Math.PI/2)) + c + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutSine: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c * Math.sin(t/d * (Math.PI/2)) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutSine: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c/2 * (Math.cos(Math.PI*t/d) - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInExpo: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutExpo: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutExpo: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if (t==0) return b;" _newline /// 
		_skip(6) 	"if (t==d) return b+c;" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;" _newline /// 
		_skip(6) 	"return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInCirc: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c * (Math.sqrt(1 - (t/=d)*t) - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutCirc: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c * Math.sqrt(1 - (t=t/d-1)*t) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutCirc: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return -c/2 * (Math.sqrt(1 - t*t) - 1) + b;" _newline /// 
		_skip(6) 	"return c/2 * (Math.sqrt(1 - (t-=2)*t) + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInElastic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"var s=1.70158;var p=0;var a=c;" _newline /// 
		_skip(6) 	"if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;" _newline /// 
		_skip(4) 	"if (a < Math.abs(c)) { a=c; var s=p/4; }" _newline /// 
		_skip(4) 	"else var s = p/(2*Math.PI) * Math.asin (c/a);" _newline /// 
		_skip(4) 	"return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutElastic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"var s=1.70158;var p=0;var a=c;" _newline /// 
		_skip(6) 	"if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;" _newline /// 
		_skip(6) 	"if (a < Math.abs(c)) { a=c; var s=p/4; }" _newline /// 
		_skip(4) 	"else var s = p/(2*Math.PI) * Math.asin (c/a);" _newline /// 
		_skip(6) 	"return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutElastic: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"var s=1.70158;var p=0;var a=c;" _newline /// 
		_skip(6)	"if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);" _newline /// 
		_skip(6)	"if (a < Math.abs(c)) { a=c; var s=p/4; }" _newline /// 
		_skip(6)	"else var s = p/(2*Math.PI) * Math.asin (c/a);" _newline /// 
		_skip(6)	"if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;" _newline /// 
		_skip(6)	"return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInBack: function (x, t, b, c, d, s) {" _newline /// 
		_skip(6)	"if (s == undefined) s = 1.70158;" _newline /// 
		_skip(6)	"return c*(t/=d)*t*((s+1)*t - s) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutBack: function (x, t, b, c, d, s) {" _newline /// 
		_skip(6)	"if (s == undefined) s = 1.70158;" _newline /// 
		_skip(6)	"return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutBack: function (x, t, b, c, d, s) {" _newline /// 
		_skip(6)	"if (s == undefined) s = 1.70158; " _newline /// 
		_skip(6)	"if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;" _newline /// 
		_skip(6)	"return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInBounce: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"return c - jQuery.easing.easeOutBounce (x, d-t, 0, c, d) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutBounce: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"if ((t/=d) < (1/2.75)) {" _newline /// 
		_skip(6)		"return c*(7.5625*t*t) + b;" _newline /// 
		_skip(6)	"} else if (t < (2/2.75)) {" _newline /// 
		_skip(6)		"return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;" _newline /// 
		_skip(6)	"} else if (t < (2.5/2.75)) {" _newline /// 
		_skip(6)		"return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;" _newline /// 
		_skip(6)	"} else {" _newline /// 
		_skip(6)		"return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;" _newline /// 
		_skip(6)	"}" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutBounce: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"if (t < d/2) return jQuery.easing.easeInBounce (x, t*2, 0, c, d) * .5 + b;" _newline /// 
		_skip(6)	"return jQuery.easing.easeOutBounce (x, t*2-d, 0, c, d) * .5 + c*.5 + b;" _newline /// 
		_skip(2) "}"_newline /// 
"});" _newline /// 
"</script>" _newline(2)





	/* THIS IS THE SMOOTH ZOOM JAVASCRIPT */


	/*
	* Smoothzoom
	* http://kthornbloom.com/smoothzoom
	*
	* Copyright 2014, Kevin Thornbloom
	* Free to use and modify under the MIT license.
	* http://www.opensource.org/licenses/mit-license.php
	*/

file write `canvas' "<script>" _newline ///
"(function($) {" _newline ///
    "$.fn.extend({" _newline ///
        _skip(4)"smoothZoom: function(options) {" _newline ///
			///
            _skip(6)"var defaults = {" _newline ///
                _skip(8)"zoominSpeed: 800," _newline ///
                _skip(8)"zoomoutSpeed: 400," _newline ///
                _skip(8)"resizeDelay: 400," _newline ///
                _skip(8)"zoominEasing: 'easeOutExpo'," _newline ///
                _skip(8)"zoomoutEasing: 'easeOutExpo'" _newline ///
            _skip(6)"}" _newline ///
			///
            _skip(6)"var options = $.extend(defaults, options);" _newline ///
			///
			///		
			///
            /// // CLICKING AN IMAGE
			///
            _skip(6)"$('img[rel=" `"""'"zoom"`"""' "]').click(function(event) {" _newline ///
			///
                _skip(8)"var link = $(this).attr('src')," _newline ///
                    _skip(10)"largeImg = $(this).parent().attr('href')," _newline ///
                    _skip(10)"target = $(this).parent().attr('target')," _newline ///
                    _skip(10)"offset = $(this).offset()," _newline ///
                    _skip(10)"width = $(this).width()," _newline ///
                    _skip(10)"height = $(this).height()," _newline ///
                    _skip(10)"amountScrolled = $(window).scrollTop()," _newline ///
                    _skip(10)"viewportWidth = $(window).width()," _newline ///
                    _skip(10)"viewportHeight = $(window).height();" _newline ///
                /// IF THERE IS NO ANCHOR WRAP
                _skip(8)"if ((!largeImg) || (largeImg == " `"""'"#"`"""'")) {" _newline ///
				///
                    _skip(6)"$('body').append(" `"""'"<div id='lightwrap'><img src="`"""'" + link + "`"""'"></div><div id='lightbg'></div><img id='off-screen' src="`"""'" + link + "`"""'">"`"""'");" _newline ///
                   _skip(6) "$("`"""'"#off-screen"`"""'").load(function() {" _newline ///
                        _skip(8)"$('#lightwrap img').css({" _newline ///
                            _skip(10)"width: width," _newline ///
                            _skip(10)"height: height," _newline ///
                            _skip(10)"top: (offset.top - amountScrolled)," _newline ///
                            _skip(10)"left: offset.left" _newline ///
                        _skip(8)"});" _newline ///
                        _skip(8)"fitWidth();" _newline ///
                        _skip(8)"$('#lightbg').fadeIn();" _newline ///
                    _skip(6)"});" _newline ///
                    _skip(6)"$(this).attr('id', 'lightzoomed');" _newline ///
					///
                    /// IF THERE IS AN ANCHOR, AND IT'S AN IMAGE
                _skip(6) "} else if (largeImg.match("`"""'"jpg$"`"""'")) {" _newline ///
                    "$('body').append("`"""'"<div id='lightwrap'><img src="`"""'" + largeImg + "`"""'"></div><div id='lightbg'></div><img id='off-screen' src="`"""'" + largeImg + "`"""'">"`"""'");" _newline ///
                    _skip(8)"$("`"""'"#off-screen"`"""'").load(function() {" _newline ///
                        _skip(10)"$('#lightwrap img').css({" _newline ///
                            _skip(10)"width: width," _newline ///
                            _skip(10)"height: height," _newline ///
                            _skip(10)"top: (offset.top - amountScrolled)," _newline ///
                            _skip(10)"left: offset.left" _newline ///
                        _skip(10)"});" _newline ///
                        _skip(8)"fitWidth();" _newline ///
                        _skip(8)"$('#lightbg').fadeIn();" _newline ///
                    _skip(6)"});" _newline ///
                    _skip(6)"$(this).attr('id', 'lightzoomed');" _newline ///
					///	
                    /// IF THERE IS AN ANCHOR, BUT NOT AN IMAGE
                _skip(4)"} else {" _newline ///
                    /// SHOULD IT OPEN IN A NEW WINDOW?
                    _skip(4)"if (target = '_blank') {" _newline ///
                        _skip(4)"window.open(largeImg, '_blank');" _newline ///
                    _skip(4)"} else {" _newline ///
                        _skip(4)"window.location = largeImg;" _newline ///
                    _skip(4)"}" _newline ///
                _skip(4)"}" _newline ///
                _skip(4)"event.preventDefault();" _newline ///
            _skip(4)"});" _newline ///
			///	
            /// CLOSE MODAL
			///
            _skip(4)"$(document.body).on("`"""'"click"`"""'", "`"""'"#lightwrap, #lightbg"`"""'", function(event) {" _newline ///
                _skip(6)"var offset = $("`"""'"#lightzoomed"`"""'").offset()," _newline ///
                    _skip(6)"originalWidth = $("`"""'"#lightzoomed"`"""'").width()," _newline ///
                    _skip(6)"originalHeight = $("`"""'"#lightzoomed"`"""'").height()," _newline ///
                    _skip(6)"amountScrolled = $(window).scrollTop();" _newline ///
                _skip(6)"$('#lightbg').fadeOut(500);" _newline ///
                _skip(6)"$('#lightwrap img').animate({" _newline ///
                    _skip(6)"height: originalHeight," _newline ///
                    _skip(6)"width: originalWidth," _newline ///
                    _skip(6)"top: (offset.top - amountScrolled)," _newline ///
                    _skip(6)"left: offset.left," _newline ///
                    _skip(6)"marginTop: '0'," _newline ///
                    _skip(6)"marginLeft: '0'" _newline ///
                _skip(6)"}, options.zoomoutSpeed, options.zoomoutEasing, function() {" _newline ///
                    _skip(6)"$('#lightwrap, #lightbg, #off-screen').remove();" _newline ///
                    _skip(6)"$('#lightzoomed').removeAttr('id');" _newline ///
					///
                _skip(6)"});" _newline ///
            _skip(6)"});" _newline ///
			///
            /// DELAY FUNCTION FOR WINDOW RESIZE
            _skip(6)"var delay = (function() {" _newline ///
                _skip(6)"var timer = 0;" _newline ///
                _skip(6)"return function(callback, ms) {" _newline ///
                    _skip(6)"clearTimeout(timer);" _newline ///
                    _skip(6)"timer = setTimeout(callback, ms);" _newline ///
                _skip(6)"};" _newline ///
            _skip(6)"})();" _newline ///
			///
            /// CHECK WINDOW SIZE EVERY _ MS
            _skip(6)"$(window).resize(function() {" _newline ///
                _skip(6)"delay(function() {" _newline ///
                    _skip(6)"fitWidth();" _newline ///
                _skip(6)"}, options.resizeDelay);" _newline ///
            _skip(4)"});" _newline ///
			///
            /// FIT IMAGE BASED ON HEIGHT
            _skip(4)"function fitHeight() {" _newline ///
			///
                _skip(6)"var viewportHeight = $(window).height()," _newline ///
                    _skip(6)"viewportWidth = $(window).width()," _newline ///
                    _skip(6)"naturalWidth = $('#off-screen').width()," _newline ///
                    _skip(6) "naturalHeight = $('#off-screen').height()," _newline ///
                    _skip(6)"newHeight = (viewportHeight * 0.95)," _newline ///
                    _skip(6)"ratio = (newHeight / naturalHeight)," _newline ///
                    _skip(6)"newWidth = (naturalWidth * ratio);" _newline ///
                _skip(6)"$('#lightwrap img').show();" _newline ///
                _skip(6)"if (newHeight > naturalHeight) {" _newline ///
                    _skip(6)"$('#lightwrap img').animate({" _newline ///
                        _skip(6)"height: naturalHeight," _newline ///
                        _skip(6)"width: naturalWidth," _newline ///
                        _skip(6)"left: '50%'," _newline ///
                        _skip(6)"top: '50%'," _newline ///
                        _skip(6)"marginTop: -(naturalHeight / 2)," _newline ///
                        _skip(6)"marginLeft: -(naturalWidth / 2)" _newline ///
                    _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                _skip(6)"} else {" _newline ///
                    _skip(6)"if (newWidth > viewportWidth) {" _newline ///
                        _skip(6)"fitWidth();" _newline ///
                    _skip(6)"} else {" _newline ///
                        _skip(6)"$('#lightwrap img').animate({" _newline ///
                            _skip(6)"height: newHeight," _newline ///
                            _skip(6)"width: newWidth," _newline ///
                            _skip(6)"left: '50%'," _newline ///
                            _skip(6)"top: '2.5%'," _newline ///
                            _skip(6)"marginTop: '0'," _newline ///
                            _skip(6)"marginLeft: -(newWidth / 2)" _newline ///
                        _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                    _skip(6)"}" _newline ///
                _skip(6)"}" _newline ///
            _skip(4)"}" _newline ///
			///
            /// FIT IMAGE BASED ON WIDTH
            _skip(4)"function fitWidth() {" _newline ///
                _skip(6)"var naturalWidth = $('#off-screen').width()," _newline ///
                    _skip(6)"naturalHeight = $('#off-screen').height()," _newline ///
                    _skip(6)"viewportWidth = $(window).width()," _newline ///
                    _skip(6)"viewportHeight = $(window).height()," _newline ///
                    _skip(6)"newWidth = (viewportWidth * 0.95)," _newline ///
                    _skip(6)"ratio = (newWidth / naturalWidth)," _newline ///
                    _skip(6)"newHeight = (naturalHeight * ratio);" _newline ///
                _skip(6)"$('#lightwrap img').show();" _newline ///
                _skip(6)"if (newHeight > naturalHeight) {" _newline ///
                    _skip(6)"if (naturalHeight > viewportHeight) {" _newline ///
                        _skip(6)"fitHeight();" _newline ///
                    _skip(6)"} else {" _newline ///
                        _skip(6)"$('#lightwrap img').animate({" _newline ///
                            _skip(6)"height: naturalHeight," _newline ///
                            _skip(6)"width: naturalWidth," _newline ///
                            _skip(6)"top: '50%'," _newline ///
                            _skip(6)"left: '50%'," _newline ///
                            _skip(6)"marginTop: -(naturalHeight / 2)," _newline ///
                            _skip(6)"marginLeft: -(naturalWidth / 2)" _newline ///
                        _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                    _skip(6)"}" _newline ///
                _skip(6)"} else {" _newline ///
                    _skip(6)"if (newHeight > viewportHeight) {" _newline ///
                        _skip(6)"fitHeight();" _newline ///
                    _skip(6)"} else {" _newline ///
                        _skip(6)"$('#lightwrap img').animate({" _newline ///
                            _skip(6)"height: newHeight," _newline ///
                            _skip(6)"width: newWidth," _newline ///
                            _skip(6)"top: '50%'," _newline ///
                            _skip(6)"left: '2.5%'," _newline ///
                            _skip(6)"marginTop: -(newHeight / 2)," _newline ///
                            _skip(6)"marginLeft: '0'" _newline ///
                        _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                    _skip(4)"}" _newline ///
                _skip(4)"}" _newline ///
            _skip(4)"}" _newline ///
///
///
        _skip(2)"}" _newline ///
    _skip(2)"});" _newline ///
"})(jQuery);" _newline ///
"</script>" _newline(4)





 


	/* ADDING THE SMOOTH ZOOM SCRIPT */
	file write `canvas' "<script type=" `" "text/javascript">"' ///
    " $(window).load( function() {$('img').smoothZoom({ " ///
    "});});</script> " _newline
						
				file write `canvas' "</body>" _n 
				file write `canvas' "</html>" _n

				file close `canvas'
				file close `hitch'
		
	

		
	
	
		
		********************************************************************
		*EXPORTING THE HTML FILE
		********************************************************************
		
		shell "$pandoc" "`tmp1'" -o "`prehtml'"
		
		********************************************************************
		*CORRECTING THE HTML FILE
		********************************************************************		
		
		tempname hitch canvas 
		file open `hitch' using "`prehtml'", read 
		qui cap file open `canvas' using "`html'", write replace
		qui file write `canvas'  _newline
		file read `hitch' line	
		while r(eof) == 0 {	
				
				local word1 : word 1 of `"`line'"'
				
				*FIX THE IMAGES
				if substr(`"`word1'"',1,8) == "<p><img " {
						local line : subinstr local line "<p><img" "<img"
						local line : subinstr local line "></p>" ">"
						}
						
				local line : subinstr local line "DOLLARSIGN" "$", all
				local line : subinstr local line "SUPERSCRIPTSIGN" "^", all
				local line : subinstr local line "EQUIVALENCYSIGN" "~", all
				
				
				local line : subinstr local line "BkLsH" "\", all
						
				local line : subinstr local line "<p><code>" `"<code class="code">"', all
				local line : subinstr local line "</code></p>" `"</code>"', all	
				local line : subinstr local line "<pre><code>" `"<div class="output">"', all
				local line : subinstr local line "</code></pre>" `"</div>"', all
						
if "`nolight'" == "" {						
				local line : subinstr local line "OrEzZ" ///
				`"<span class="digit">0</span>"', all
						
				local line : subinstr local line "EnOO" ///
				`"<span class="digit">1</span>"', all
						
				local line : subinstr local line "OwTT" ///
				`"<span class="digit">2</span>"', all
						
				local line : subinstr local line "EeRhR" ///
				`"<span class="digit">3</span>"', all
						
				local line : subinstr local line "RuOfF" ///
				`"<span class="digit">4</span>"', all
						
				local line : subinstr local line "EvIfF" ///
				`"<span class="digit">5</span>"', all
						
				local line : subinstr local line "XiSsS" ///
				`"<span class="digit">6</span>"', all
						
				local line : subinstr local line "NeVeSS" ///
				`"<span class="digit">7</span>"', all
						
				local line : subinstr local line "ThGiE" ///
				`"<span class="digit">8</span>"', all
						
				local line : subinstr local line "EnInN" ///
				`"<span class="digit">9</span>"', all


						
				local word1 : word 1 of `"`line'"'	
						
						
				if substr(`"`macval(word1)'"',1,19) == `"<code class="code">"' {
						
						forval i = 1/20 {

								local line = subinstr(`"`macval(line)'"', ///
								"&quot;",`"<span class="string">""',1)
				
								local line = subinstr(`"`macval(line)'"', ///
								"&quot;",`""</span>"',1)  
								}
								
						/* CREATING THE BRACE HIGHLIGHTER */
						local line : subinstr local line "{" ///
						"<span class=brace>{</span>", all
								
						local line : subinstr local line "}" ///
						"<span class=brace>}</span>", all
								
						}
}						
						file write `canvas' `"`macval(line)'"' _n  
						file read `hitch' line
						}
				
				file close `canvas'
				file close `hitch'
				
				
				
				
		*ERASING THE REST OF THE TEMPORARZ FILES
		
		cap qui erase "`prehtml'"
		

		
		********************************************************************
		*HTML RESULTS
		********************************************************************

		if "`export'" == "html" | "`export'" == "HTML" {
				
				di as txt _newline(2)
				di as txt " _  __    _       _                    "
				di as txt "| |/ /___| |_ ___| |__  _   _ _ __     "
				di as txt "| ' // _ \ __/ __| '_ \| | | | '_ \    "
				di as txt "| . \  __/ || (__| | | | |_| | |_) |   "
				di as txt "|_|\_\___|\__\___|_| |_|\__,_| .__/  created " ///
				`"{bf:{browse "`html'"}} "'
				di as txt "                             |_|    " _n
				}                 
   
  


 
		********************************************************************
		*EXPORTING PDF
		********************************************************************
		if "`export'" == "pdf" | "`export'" == "PDF" {	
				
				
				/* MICROSOFT WINDOWS PDF PRINTER DEFAULT PATHS */

				if "`c(os)'"=="Windows" {
				
						*Prince and the default printer setting
						if "$printer" == "prince" | "$printer" == "" {
											
								shell "$setpath" --no-network  --javascript ///
								"`html'" -o "`pdf'"
										
								}		
						
						if "$printer" == "wkhtmltopdf" {	

								shell "$setpath" ///
								--footer-center [page] --footer-font-size 10 ///
								--margin-right 6mm ///
								--margin-left 6mm ///
								"`html'" "`pdf'"
								}			
						}		
				}
						

			/* MACINTOSH PDF PRINTER DEFAULT PATHS*/			
						
			if "`c(os)'" == "MacOSX" {
				
					*Prince and the default printer setting
					if "$printer" == "prince" | "$printer" == "" {
						
							cap shell "$setpath" --no-network  --javascript ///
							"`html'" -o "`pdf'"
							}				
						
					if "$printer" == "wkhtmltopdf" {
								
							shell $setpath ///
							--footer-center [page] --footer-font-size 10 ///
							--margin-right 6mm --margin-left 6mm  ///
							"`html'" "`pdf'"
															
							}
					}
						
		
		

		*UNIX PDF PRINTER DEFAULT PATHS
		
				if "`c(os)'"=="Unix" {
				
						*Prince and the default printer setting
						if "$printer" == "prince" | "$printer" == "" {
						
								cap shell $setpath --no-network  --javascript ///
								"`html'" -o "`pdf'"
								}		
										
						
						if "$printer" == "wkhtmltopdf" {

								shell $setpath ///
								--footer-center [page] --footer-font-size 10 ///
								--margin-right 6mm --margin-left 6mm ///
								"`html'" "`pdf'"					
								}
						}
						
		
		if "`export'" == "pdf" {
		
				cap quietly findfile "`pdf'"
		
	
				if "`r(fn)'" != "" & "`keep'" == "" {

						di as txt _newline(2)	
						di as txt " _  __    _       _                    "
						di as txt "| |/ /___| |_ ___| |__  _   _ _ __     "
						di as txt "| ' // _ \ __/ __| '_ \| | | | '_ \    "
						di as txt "| . \  __/ || (__| | | | |_| | |_) |   "
						di as txt "|_|\_\___|\__\___|_| |_|\__,_| .__/  created " ///
						`"{bf:{browse "`pdf'"}} "'
						di as txt "                             |_|    " _n
				
						*> remove the HTML file
						qui cap erase "`html'"
						}
				
		
				if "`r(fn)'" != "" & "`keep'" == "keep" {

						di as txt _newline(2)	
						di as txt " _  __    _       _                    "
						di as txt "| |/ /___| |_ ___| |__  _   _ _ __     "
						di as txt "| ' // _ \ __/ __| '_ \| | | | '_ \    "
						di as txt "| . \  __/ || (__| | | | |_| | |_) |   "
						di as txt "|_|\_\___|\__\___|_| |_|\__,_| .__/  created " ///
						`"{bf:{browse "`pdf'"}} and {bf:{browse "`html'"}} "'
						di as txt "                             |_|    " _n
				
						}
				
		
				****************************************************************
				*OPEN THE PDF DOCUMENT
				****************************************************************
				if "`r(fn)'" != "" {
		
						/* OPEN PDF */
						if "`c(os)'"=="Windows" {
								*open the pdfdoc
								winexec explorer "`pdf'"
								}
				
						if "`c(os)'"=="MacOSX" {
								*open the pdfdoc
								shell open "`pdf'"
								}
				
						if "`c(os)'"=="Unix" {
								*open pdf
								shell xdg-open "`pdf'"
								}	
						}
					
				
				
				if "`r(fn)'" == "" {
						cap quietly findfile "`html'"
						if "`r(fn)'" != "" {	
				
								di as txt _newline(2)	
								di as txt " _  __    _       _                    "
								di as txt "| |/ /___| |_ ___| |__  _   _ _ __     "
								di as txt "| ' // _ \ __/ __| '_ \| | | | '_ \    "
								di as txt "| . \  __/ || (__| | | | |_| | |_) |   "
								di as txt "|_|\_\___|\__\___|_| |_|\__,_| .__/  created " ///
								`"{bf:{browse "`html'"}} "'
								di as txt "                             |_|    " _n
				
								di as error `"{p}{bf:No PDF was generated. }"' ///
								`"Make sure you have defined the path to the Printer correctly. "' ///
								`"Follow the instructions on "' ///
								`"{browse www.stata-blog.com/ketchup} for more "' ///
								`"information. Alternatively, you can print {browse "`html'"} "' ///
								`"to PDF from "your web browser or other software..."'
								}
						}		
				}		
		
		*remove SMCL
		if "`erase'" == "erase" { 
				cap erase `"`input'"' 
				}	
		
		* drop wordlist macros
		macro drop synlightlist
		macro drop synfunclist
		macro drop setpath
		macro drop printer
		macro drop pandoc
		
		********************************************************************
		*CHECK KETCHUP VERSION
		********************************************************************
		ketchupversion
		
	end









