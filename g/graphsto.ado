//  #0 
//  Program     : graphsto  
//  Author      : Joseph D. Wolfe 
//  Description : captures graph name in global graphout can use
//  Requirements: >=Stata 10 (currently untested on previous versions)  

*history at end of program 
*!version 0.2.3 :: 4/23/14, 5:07 PM :: Wrapper for graph export + title/note

//  #1
//  Program Define  

capture clear  programs
program define graphsto

local caller : di _caller()
local everything `"`0'"'

*add up graphs; only 
if regexm(`"`0'"', "[\.]+") {
	global X_st0red_X_grAph_Number = $X_st0red_X_grAph_Number + 1
}

//  #2
//  Which Version Of Graphsto?

*check differences in users syntax to make backward compatible 
local v22=0
if `"`1'"' == "clear"   |  `"`1'"' == "drop" |  `"`1'"' == "dir" {
	local v22=1
}
if regexm(`"`everything'"', "graph export") local v22=1 
if regexm(`"`everything'"', "gr_export")    local v22=1

//  #3
//  Different Commands For Old v22 And New v23 Versions

if `v22'==1 _graphstoV022 `everything'
if `v22'==0 _graphstoV023 `everything'


end // graphsto

//  subroutines --------------------------------------------------------------
//  #1------------------------------------------------------------------------
//  _cllct_getFileNameAndPath: Get File Name and Path 

*version 0.0.1 :: 03/01/11 12:31 PM   

program  _cllct_getFileNameAndPath, sclass
syntax, fileinfo(string) 
version 10

if regexm(`"`fileinfo'"', "[\]|[/]")  {
	local more `"`fileinfo'"'
	local stop = 1

	while `stop' != 0 {
		if regexm(`"`more'"', "[\]") {
			gettoken hold more : more, parse("\")
			local PathToFile `"`macval(PathToFile)'`hold'"'
			local trash : subinstr local more "\" "", all count(local stop)
		}

		if regexm(`"`more'"', "[/]") {
			gettoken hold more : more, parse("/")
			local PathToFile "`macval(PathToFile)'`hold'"
			local trash : subinstr local more "/" "", all count(local stop)
		}
	}
	sreturn local file_name  `"`more'"'
	sreturn local PathToFile `"`PathToFile'"'
}

else {
	sreturn local file_name `"`fileinfo'"'
	sreturn local PathToFile ""	
}

end // _getFileNameAndPath 

//  #2------------------------------------------------------------------------
//  Previous Version of Graphsto _graphstoV022

*version 0.2.2 :: 12/12/13, 10:59 PM

program  _graphstoV022

local caller : di _caller()
local everything `"`0'"'

if `"$X_st0red_X_grAph_Number"'!="" local gnum = $X_st0red_X_grAph_Number
if `"$X_st0red_X_grAph_Number"'=="" local gnum = 0

if `"`1'"' == "clear"   local sendtoclear = 1
if `"`1'"' == "drop"    local sendtoclear = 1
if `"`1'"' == "dir"     local sendtodir   = 1
if `"`1'"' == ",clear"  local sendtoclear = 1
if `"`1'"' == ",drop"   local sendtoclear = 1
if `"`1'"' == ",dir"    local sendtodir   = 1
if `"`1'"' == ","  & (`"`2'"'=="clear" | `"`2'"'=="drop") {
	     local sendtoclear = 1
}
if `"`1'"' == ","  & (`"`2'"'=="dir") {
	     local sendtodir = 1
}

if "`sendtodir'"==""   local sendtodir = 0
if "`sendtoclear'"=="" local sendtoclear = 0

if  regexm(`"`1'"',"^:[a-zA-Z]+") |    ///
    regexm(`"`1'"',":")           local sendtoparse = 1
	                         else local sendtoparse = 0

*errors
if `sendtoparse'==0 & regexm(`"`3'"',":") {
	di as error ///
	"invalid syntax: see graphsto help file for more information"
	exit 198
}

if (`sendtoclear' == 0 & `sendtodir' == 0 & `sendtoparse'==0) {
	di as error ///
	"Invalid syntax: see graphsto help file for more information"
	exit 198
}

if (`sendtoclear' == 1 | `sendtodir' == 1) & `sendtoparse'==1 {
	di as error ///
	"Invalid syntax: you cannot use clear or dir with colon"
}

*options 
if `sendtoclear' {
	capture macro drop X_st0red_X_grAph_*
	di as text "(graph directory now empty)"
}

*parse, export, and get graph names
if `sendtoparse' {	
	if !`gnum' {
		local gnum = 1
		global X_st0red_X_grAph_Number = 1
	}

	gettoken trash cmdline : everything, parse(":")	
	
	local cmdword1 : word 1 of `cmdline'
	if "`cmdword1'"!="gr_export" local cmdword2 : word 2 of `cmdline'
	loc grphexport "`cmdword1' `cmdword2'"
	
	local grph_and_opts : subinstr local cmdline "`cmdword1'" ""
	if "`cmdword2'"!="" local grph_and_opts : subinstr local grph_and_opts "`cmdword2'" ""
	gettoken grph export_options: grph_and_opts, parse(",")

	* check if graph export command is correct  
	if regexm(`"`grphexport'"', "graph export") |       ///
       regexm(`"`grphexport'"', "gr_export") local stop = 0 
	                                    else local stop = 1											  
	if `stop' {
		di as error ///
		"graphsto only works with graph export"
		exit 198
	}

	* export graph   
	version `caller':`grphexport' `"`macval(grph)'"' `macval(export_options)'

	* parse file name from path  
	_cllct_getFileNameAndPath, fileinfo(`"`grph'"')
	local grph `"`s(file_name)'"'

	* collect graph names  
	global X_st0red_X_grAph_g`gnum'  `"`grph'"'
}

if `sendtodir' {
	if `"$X_st0red_X_grAph_g1"'!="" {
		forvalues g = 1/`gnum' {
			local gname  `"X_st0red_X_grAph_g`g'"'		
			di as text `"$`gname'"'		
		}
	}
	else di as text "(note: no graphs in directory)"
}


end // _graphstoV22


//  #3------------------------------------------------------------------------
//  New Graphsto _graphstoV023

program _graphstoV023

syntax [anything],              ///
    [                           ///  
    replace                     ///  replace graph
    title(string asis)          ///  add title to graph
    note(string asis)           ///  add notes below graph
    clear                       ///  clear directory
    DIRectory                   ///  display directory of names  
    export(string asis)         ///  any graph export option user wants         
    ]
         
local caller : di _caller()
local everything `"`0'"'
  
*set graph number for globals
if `"`anything'"'!= "" {
	local gnum = $X_st0red_X_grAph_Number

	* get path and file info for file to save graphs  
	_cllct_getFileNameAndPath, fileinfo(`anything')
	local path          `"`s(PathToFile)'"'
	local file_name     `"`s(file_name)'"'
	if `"`path'"'       == "" local path "."

	qui version `caller': graph export `anything', `replace' `export'

	* collect graph names  
 	global X_st0red_X_grAph_g`gnum' `"`file_name'"'

	* collect graph titles  
	global X_st0red_X_grAph_t`gnum' `"`title'"'

	* collect graph notes  
	global X_st0red_X_grAph_n`gnum' `"`note'"'
	
	* path to graph
	global X_st0red_X_grAph_p`gnum' `"`path'"'
}

if "`clear'" != "" {
	capture macro drop X_st0red_X_grAph_*
	di as text "(graph directory now empty)"
}

if "`directory'"!="" {
	local gnum = $X_st0red_X_grAph_Number
	local show : length global X_st0red_X_grAph_g1
	if `show' {
		forvalues g = 1/`gnum' {
			local gname  `"X_st0red_X_grAph_g`g'"'		
			di as text `"$`gname'"'	
		}
	}
	if !`show' di as text "(note: no graphs in directory)"
}

end // _graphstoV23

 
exit

* Version History-------------------------------------------------------------
* version 0.0.1  11/05/10 
	* basic functions & errors 
* version 0.0.2  11/05/10 
	* changed from prefix to wrapper for graph export	      
* version 0.0.3  11/05/10 
	* went back to prefix format  
	* renamed to graphsto
* version 0.1.0  02/05/11 9:32 AM 
	* allow grahsto name: graph export
	* errors 
* version 0.1.1  02/06/11 3:20 AM  
	*last version was getting too complicated came back to 0.0.3  
	*added errors and updated parsing  
* version 0.1.2  03/01/11 12:38 PM  
	*adjust so that users can specify path to file  
* version 0.2.0  03/05/11 11:34 AM 
	*new version for web  
*version 0.2.0 :: 03/05/11 11:34 AM 
*version 0.2.1 :: 03/30/12 11:31 AM  
*version 0.2.2 :: 12/12/13, 10:59 PM :: Include subroutines
