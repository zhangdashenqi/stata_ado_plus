//  #0 
//  Program     : graphout  
//  Author      : Joseph D. Wolfe 
//  Description : Save graphs in single file (rtf, html, tex)
//  Requirements: >= Stata 10 (untested on previous versions)

*history at end of program 
*!version 0.3.9 :: 6/16/14, 2:07 PM; use working directory if no path

//  #1
//  Program define graphout 

capture clear  programs
program define graphout
       
syntax [anything] using/,       ///
    [                           ///
    REPlace	                    ///  replace previous file (default)
    APPend                      ///  add graphs to existing file
    DOCument                    ///  makes TEX file a self-contained document
                                ///
    height(string)              ///  adjust height of graph
    width(string)               ///  adjust width ofs graph
    scale(numlist >=0 <=1)   	///  adjust scale of graph
                                ///
    ALIGNment(string)   	    ///  align graph (default=center)
    						    ///  
    title(string asis)          ///  add title to graph
    note(string asis)           ///  add notes below graph
    NOCount                     ///  does not add Figure # above graph
    BASEcount(numlist)          ///  starts Figure at specific #
    						    /// 
    PLACEment(string)           ///  tex: position of tex figure
    FBARrier(numlist >0)        ///  tex: add float barrier 
    float                       ///  tex: puts figures in float environ
    LABel(string)               ///  tex: add \label{} to floating figure
    clear                       ///  clear  globals after file is created
    ]
       
//  #2
//  Set Macros And Defaults
 
local SaveFileAs `"`using'"'

* macros for handles and files   
tempname ahandle bhandle
tempfile repfile appfile

* get path and file info for file to save graphs  
_cllct_getFileNameAndPath, fileinfo(`"`SaveFileAs'"')
local path          `"`s(PathToFile)'"'
local file_name     `"`s(file_name)'"'

* get graph extension (Ben Jann is the author of _getfilesuffix)  
_getfilesuffix      `"`file_name'"'
local file_ext      `"`s(suffix)'"'
local file_dispext   = upper(`"`file_ext'"')

* check if graphsto global has graph names 
* if it does have them use those names; otherwise use names in `anything'  
local PathGraphExt ""
if `"`anything'"' == "" {
	if "$X_st0red_X_grAph_Number" == "" {
		di as error "no stored or specified graphs"
		exit
	}

	*number of graphs to be used 
	if "$X_st0red_X_grAph_Number" != "" local gnum = $X_st0red_X_grAph_Number

	if "$X_st0red_X_grAph_g1" != "" {
		forvalues g = 1/`gnum' { 
		
			local global_name "X_st0red_X_grAph_g`g'"
			local GraphName`g' `"$`global_name'"'  
			
			local global_name "X_st0red_X_grAph_p`g'"
			local path`g'     `"$`global_name'"'  
			
		}
	}
}
else {
	local gnum = 0
	foreach grph of local anything {
		local ++gnum
		local PathGraphExt`gnum' `"`grph'"' 
		
		_cllct_getFileNameAndPath, fileinfo(`"`grph'"')
		local path`gnum'          `"`s(PathToFile)'"'
		local GraphName`gnum'     `"`s(file_name)'"'		
	}
}

*loop through graphs to get graph specific information for file creation
forvalues g = 1/`gnum' {


	if `"`path`g''"'=="." local path`g' ""
	
	local path_hold : pwd

*removed in 0.3.9; if no path specified assume working directory
*	if `"`path`g''"'=="." | `"`path`g''"'=="" {
*		local path`g' : pwd
*		
*		capture cd `"`path`g''/"'
*		if !_rc local path`g' `"`path`g''/"'
*		capture cd `"`path`g''\"'
*		if !_rc local path`g' `"`path`g''\"'
*		
*		qui cd `"`path_hold'"'		
*	}
*	if regexm(`"`path`g''"', "^[\.]") {
*		qui cd `path`g''
*		local path`g' : pwd
*
*		capture cd `"`path`g''/"'
*		if !_rc local path`g' `"`path`g''/"'
*		capture cd `"`path`g''\"'
*		if !_rc local path`g' `"`path`g''\"'
*			
*		qui cd `"`path_hold'"'		
*	}
	
	*make sure directory exists
	capture cd `"`path`g''"'	
	if _rc {
		di as error "Pathway to graph is incorrect"
		exit 198		
	}
	qui cd `"`path_hold'"'

	* verify that graphs exist in specified directory 
	qui capture findfile `"`GraphName`g''"', path(`"`path`g''"')
	if _rc {
			di as error ///
		`"file "`path`g''`GraphName`g''" not found"'
		exit 601
	}
	
	* see if title and options are specified in graphout command
	if `"`title'"' != "" {
		_title_options, title(`"`title'"')
		local title`g' `"`s(title)'"'
		local title_error`g' `"`s(title_error)'"'
		local title_options`g' = lower(`"`s(options)'"')
	}
	
	*get graph extension
	_getfilesuffix `"`GraphName`g''"'
	loc GraphExt`g'   `"`s(suffix)'"'	

	*error if graphs do not include format/extension  
	if `:list sizeof GraphExt`g''==0 {
		di as error ///
		"graphs must include format (e.g., .png or.eps)"
		exit 198
	}

	*add title from graphsto
	if "$X_st0red_X_grAph_t`g'"!= "" {
		local global_name "X_st0red_X_grAph_t`g'"
		local title`g' `"$`global_name'"'  
	}
	*add note from graphsto
	if "$X_st0red_X_grAph_n`g'"!= "" {
		local global_name "X_st0red_X_grAph_n`g'"
		local note`g' `"$`global_name'"'  
	}

	* default is to put titles above graph  
	if `"`title_options`g''"'=="" {
	   local title_options`g' "above"
	}
	
	
}

* if append specified and file not found, add replace option  
qui capture findfile `"`file_name'"', path(`path')
local file_exist = _rc 
if `file_exist' == 601 & "`replace'"==""{
	loc replace "replace"
	loc append  ""
} 

* make tex files a float if options require it  
if ("`placement'"!="" | "`fbarrier'"!="" | "`label'"!="") {
    local float "float"
}

* basecount  
if "`basecount'" != "" local fignum = `basecount'-1

* fbarrier option - forces tex to process lots of floats   
if "`fbarrier'" !="" {
	local brpkg  "\usepackage{placeins}"
	local break  "\FloatBarrier" 
	local brnum  "`fbarrier'"
}
local numgraph = 0  
 
* set alignment   
if "`alignment'" == "" {  
	if "`file_ext'" == "rtf"  local gralign "\ql"
	if "`file_ext'" == "tex"  local gralign "center"
	if "`file_ext'" == "html" local gralign "left"
}
if "`alignment'" == "center" | "`alignment'" == "c" {
	if "`file_ext'" == "rtf"  local gralign "\qc"
	if "`file_ext'" == "tex"  local gralign "center"
	if "`file_ext'" == "html" local gralign "center"
}
if "`alignment'" == "right"  | "`alignment'" == "r" {
	if "`file_ext'" == "rtf"  local gralign "\qr"
	if "`file_ext'" == "tex"  local gralign "flushright"
	if "`file_ext'" == "html" local gralign "right"
}
if "`alignment'" == "left"   | "`alignment'" == "l"  {
	if "`file_ext'" == "rtf"  local gralign "\ql"
	if "`file_ext'" == "tex"  local gralign "flushleft"
	if "`file_ext'" == "html" local gralign "left"
}

//  #3
//  Error Messages 

* file found but append and replace not specified  
if `file_exist' == 0 & "`replace'"=="" & "`append'"=="" {
	di as error ///
	`"`file_name' already exists"'
	exit 602
}

* no file extension found  
if `:list sizeof file_ext'==0 {
	di as error ///
	"file extension is missing (rtf, html, or tex)"
	exit 198
}
 
* file creation: no file extension found  
if "`file_ext'" != "rtf" & "`file_ext'" != "html" & "`file_ext'" != "tex" {
	di as error ///
	"file extension must be rtf, html, or tex"
	exit 198
}

forvalues g = 1/`gnum' {
	_getfilesuffix `"`GraphName`g''"'
	local gext_error `"`s(suffix)'"'
	if "`file_ext'" == "html" & "`gext_error'"!="png" {
		di as error "HTML files require PNG graphs"
		exit 198
	}
}

* file creation: can't specify append and replace at same time  
if "`append'" != "" & "`replace'" != "" {
	di as error ///
	"append and replace cannot be used together"
	exit 198
}

* size: cannot adjust size of graphs with rtf  
if ("`height'"!="" | "`width'"!="" | "`scale'"!="") & "`file_ext'"=="rtf" {
	di as error ///
	"graph size cannot be changed in rtf files"
	exit 198
	}

* size: too many options specified   
if ("`height'"!="" | "`width'"!="") & "`scale'"!="" {
	di as error ///
	"height and width cannot be specified with scale"
	exit 198
	}

* size: verify that size options are correct  
if ("`height'" != "" | "`width'" != "" | "`scale'"!= "") {
	* remove spaces in size options  
	local width  : subinstr local width   " " "", all  
	local height : subinstr local height  " " "", all  
	local grsize `"`width' `height' `scale'"'
	
	*** html ***  
	if ("`file_ext'" == "html" & "`scale'" == "")  {		
	foreach grsz of local grsize {
		if (regexm("`grsz'", "[a-zA-Z]+")) |              ///
		   (regexm("`grsz'", "[% - _]+"))    local stop = 1
		                                else local stop = 0 
			if `stop'==1 {
				loc szprob "`grsz'"
				continue, break
			}
		}
	}
	
	*** tex ***  
	if ("`file_ext'" == "tex" & "`scale'" == "")  {		
	foreach grsz of local grsize {
		if (regexm("`grsz'", "(^([0-9]+))*((in|mm|cm)+)$")) local stop = 0
			                                           else local stop = 1
		if (regexm("`grsz'", "[% - _]+"))                   local stop = 1
			if `stop'==1 {
				loc szprob "`grsz'"
				continue, break
			}
		}
	}
	
	*** tex & html ***  
	if "`scale'" != "" {
	foreach grsz of local grsize {
		if (regexm("`grsz'", "\."))          local stop = 0
				                        else local stop = 1
		if (regexm("`grsz'", "[% - _ / \]+")) |                   ///
		   (regexm("`grsz'", "[a-zA-Z]+"))   local stop = 1
			if `stop'==1 {
				local szprob "`grsz'"
				continue, break
			}
		}
	}
	if `stop' {		
	di as error ///
	"`szprob' invalid""
	exit 198	
	}
}  // end error that verifies that size options are correct

* error for alignment  
if "`alignment'" != ""  {
	if inlist(`"`alignment'"', "center", "right", "left") | ///
	   inlist(`"`alignment'"', "c", "r", "l") local stop = 0
	if "`stop'"=="" {
		di as error ///
		`"`alignment' invalid specification for alignment"'
		exit 198
	}
}

* error for placement  
if "`placement'"!= "" {
	if "`file_ext'" != "tex" {
		di as error ///
			"placement is only available for TEX files"
			exit 198
	}
	if inlist("`placement'", "h","t","b","p","H") local stop = 0
	else local stop = 1
	if `stop'== 1 {
			di as error ///
			`"`placement' invalid specification for placement"'
			exit 198	
	}
}

* error for fbarrier  
if "`file_ext'" != "tex" & "`fbarrier'"!="" {
	di as error ///
	"fbarrier only allowed for TEX files"
	exit 198
}

* error for document option for nontex files  
if "`document'" != "" & "`file_ext'" != "tex"  {
	di as error ///
	"document only allowed for TEX files"
	exit 198
}

* error for float and non-TEX document  
if "`float'" != "" & "`file_ext'"!="tex"{
	di as error ///
	"float option is only available for TEX files"
	exit 198
}

* error for title syntax problem  
if "`title_error'" != "" {
	di as error ///
	"title() includes invalid syntax"
	exit 198
}

* error for misspecified options in title  
if "`title_options'" != "" {
	if inlist("`title_options'", "above", "below") local stop = 0 
	if "`stop'"=="" {
		di as error ///
		"title suboptions misspecified"
		exit 198
	}
}

* label errors  
if "`label'" != "" & "`file_ext'"!="tex" {
	di as error ///
	"label() option is only available for TEX files"
	exit 198
}

* error for nocount with float option  
if ("`nocount'"!="" & "`float'"!="") {
	di as error ///
	"nocount and float options cannot be used together"
	exit 198
}

//  #4
//  rtf: locals to create file

if "`file_ext'" == "rtf" {
	
	* prepare options  
	local open   "{\rtf"
	local body1 `"{\pard \keep \`gralign'"' 
	local body2 `"\line \`gralign' \field \fldedit{\*\fldinst{ INCLUDEPICTURE  \\d"' 
	local body4 `"\par}"'  
	local close    `"}"'
}

//  #5
//  html: locals to create file 

if "`file_ext'" == "html" {	
	* html uses %, so need to remove decimal plae on scale  
	if "`scale'"!= "" local scale = `scale'*100
	
	* size options  
	if "`height'"!="" & "`width'"=="" local size `"height=`height'"' 		
	if "`height'"=="" & "`width'"!="" local size `"width=`width'"' 
	if "`height'"!="" & "`width'"!="" local size `"height=`height' width=`width'"'
	if "`scale'"!="" local size `"width=`scale'%"'
	
	* alignment option  
    local gralign `"<div style="text-align: `gralign';">"' 
    local gralign `"`gralign' <font size="4" color="black""'
	local gralign `"`gralign' font face="times new roman">"'	
	
	* prepare options  
	local open   "<html><body>"
	local body1  "`gralign'"
	local body2 `"`gralign' <img src="'
	local close  "</body></html>"
}

//  #6
//  tex: locals to create file 

if "`file_ext'" == "tex" {	
	* options  
	if ("`height'"!="" & "`width'"=="") local size `"[height=`height']"' 
	if ("`height'"=="" & "`width'"!="") local size `"[width=`width']"' 
	if ("`height'"!="" & "`width'"!="") local size `"[height=`height', width=`width']"'
	if  "`scale'" !=""                  local size `"[scale=`scale']"'
	if ("`height'"=="" & "`width'"=="" & "`scale'"=="") local size "[scale=1]"
	if "`placement'" !="" local place "[`placement']"	
	if "`placement'" =="" local place ""	

	* prepare options   
	if "`document'" !="" {  
		local open   `"\documentclass{article} \usepackage{graphicx} `tex_brpkg' \begin{document}"'
		local close  `"\end{document}"'	
	}
	
	if "`label'" != "" local label `"\label{`label'}"'

	local space "_n"
	local body1 `"\begin{`gralign'} `begfig'`place' "'
	local body2 `"\\* \includegraphics`size'{"'
	local body4 `"`label' \end{`gralign'}"'
}

//  #7
//  Append File (Based On Eng 2007 And Jann 2007)

if "`append'" != "" {
	_cllct_appendFILE, ahandle(`ahandle') bhandle(`bhandle')             ///
		  appfile(`appfile') savefile(`SaveFileAs') file_ext(`file_ext') ///
		  fignum(`fignum') `nocount' fbarrier(`fbarrier') 
	local fignum `"`s(fignum)'"'
}

//  #8
//  Replace/Create File

if "`replace'" != "" {
	qui file open  `ahandle' using `repfile', replace write
	file write `ahandle' `"`open'"'
}

//  #9
//  Add Graphs To File 

local numgraph = 1
forvalues g = 1/`gnum'  {
	local ++numgraph
	local flbreak ""
			
	if ("`nocount'" == "" & "`float'" == "") local fignum = `fignum' + 1

	*set note and title options for each of the file types
	if "`file_ext'"=="rtf" {
		local body3 `" \\*MERGEFORMATINET}}{\fldrslt {}} \line `note`g''"'
		local path`g' : subinstr local path`g' "\" "/", all
	}
	if "`file_ext'"=="html" {
		local title `"`title`g'' </div>"'
		local note  `"`gralign' `note`g'' </div> <P> &nbsp"'
		local body3 `" `size'> <br> </font> </div> `note'"'
		
	}
	if "`file_ext'"=="tex" {		
		if `"`title'"'   !="" local title `""`title`g'' `t'""'
		if `"`figure'"'  !="" local title `"`title'"'
		if `"`note'"'    !="" local note  `"`note`g''"'
		
		*check if TEX figures should be floats  
		if "`float'"!="" {
			local begfig "\begin{figure}"
			local endfig "\end{figure}"	
			local title `""\caption{`title`g''}""'
		}
		local body3 `"} \\* `note`g''"'
	}	

	* macros for nocount  
	local colon ""
	if ("`nocount'"=="" & "`float'"=="") {
		local figure "Figure"
		if `"`title`g''"' != "" local colon ":"  
	}
 	
	* place title above or below graphs (default=above) 
	local atitle ""
	local btitle "" 
	if `"`title_options`g''"' == "above" {
		local atitle `"`figure' `fignum'`colon' `title`g''"'
	}
	if `"`title_options`g''"' == "below" {
		local btitle `"`figure' `fignum'`colon' `title`g''"'
	}
		
	* add floatbarrier if specified    
	if "`break'"!="" {
		if `numgraph' == `brnum'  {
			local tex_flbreak `"`break'"'
			local numgraph = 0
		}
	}
	
	*combine graph name with path to graph		
	local grph `"`path`g''`GraphName`g''"'
			
	file write `ahandle' `"`body1'"' _n `"`atitle' `body2' "`grph'" `body3' `btitle' `endfig' `body4'"' `space'
}
file write `ahandle' _n `"`close'"' _n

//  #10
//  Save File 

file close `ahandle'

if "`append'"   != "" {
	file close `bhandle'
	copy `"`appfile'"' `macval(SaveFileAs)', replace
}

if "`replace'"  != "" {
	copy `"`repfile'"'  `macval(SaveFileAs)', replace
}

*display link to file  
di as text `"(graphs added to {browse `file_name'})"'

//  #11
//  Clear Macros

if "`clear'"!="" {
	capture macro drop X_st0red_X_grAph_*
	di as text "(note: graph directory now empty)"
}

end  // graphout



//  subroutines ------------------------------------------------------------

//  #1
//  grab file extension [taken directly from esttab (Ben Jann)]

program _getfilesuffix, sclass 
version 8
gettoken filename rest : 0
if `"`rest'"' != "" {
	exit 198
}
local hassuffix 0
gettoken word rest : filename, parse(".")
while `"`rest'"' != "" {
	local hassuffix 1
	gettoken word rest : rest, parse(".")
}
if `"`word'"'=="." {
	di as err `"incomplete filename; ends in ."'
	exit 198
}
if index(`"`word'"',"/") | index(`"`word'"',"\") local hassuffix 0
if `hassuffix' sreturn local suffix `"`word'"'
else           sreturn local suffix ""

end // _getfilesuffix

//  #2
//  _title_options: Parse Title 

program  _title_options, sclass
syntax, title(string) 
version 10
	
* check if there is an unmatched quote  
local trash : subinstr local title `"""' "", all count(local numquote)
if `numquote'  ==1 local error "error"

if regexm(`"`title'"', `"""') {
	* errors  
	gettoken title options : title, parse(`"""')
	if regexm(`"`options'"', `","')             local checkopts = 1
	if ("`checkopts'"=="" & "`options'"!="")    local error "error"
	if regexm(`"`options'"', `"""')             local error "error"
	
	local options : subinstr local options "," ""
	local options = trim(`"`options'"')
}
		
else {
	if regexm(`"`title'"', "," )  gettoken title options:   title, parse(",")
	if regexm(`"`options'"', ",") gettoken coma  options: options, parse(",")
	local options = trim(`"`options'"')
}

sreturn local title_error `"`error'"'
if "`error'" == "" {
	sreturn local title `"`title'"'
	if "`options'" != "" sreturn local options `"`options'"'
	else                 sreturn local options ""
}
	
end // _title_options

//  #3
//   _cllct_getFileNameAndPath: Get File Name and Path 

*! version 0.0.1 :: 03/01/11 12:31 PM   

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

//  #4
//  _cllct_appendFILE  

* version 0.0.1 :: 01/28/12 11:09 AM :: Created separate ado for part   
*!version 0.0.2 :: 03/30/12 11:37 AM    

program _cllct_appendFILE, sclass
   
syntax,                         ///
    [                           ///
								/// Necessary options
    ahandle(string asis)        /// temp name of handle
    bhandle(string asis)        /// temp name of handle
    appfile(string asis)        /// temp name of file
    savefile(string asis)   	/// name of file name & loc if avail
								///
								/// Graphout options
	file_ext(string)            /// file extension (e.g., .rtf)
	fignum(numlist)             /// figure number
	tabnum(numlist)             /// figure number
	nocount                     /// don't count graphs
	fbarrier(numlist)           /// tex files
							    ///
								/// Statout options
	tabnum(numlist)             /// table number
    ]

local SaveFileAs `"`savefile'"'

if "`fbarrier'" !="" {
	local brpkg  "\usepackage{placeins}"
	local break  "\FloatBarrier" 
	local brnum  "`fbarrier'"
}
 
* locals to find end of file   
local endflcxv   `"="""' 
local endfltex   `"\end{document}"'
local endflrtf   `"}"'
local endflhtml  `"</body></html>"'
local endfl      `"`endfl`file_ext''"'

* open file with graphs  
qui file open `ahandle'  using `appfile'   , read write
qui file open `bhandle'  using `macval(SaveFileAs)', read write
file seek `bhandle' query
local loc    = r(loc)
local end    = 0

* copy file to temporary file  
while (`end'==0) {
	file seek  `bhandle' `loc'
	file read  `bhandle' line
	local end = r(eof)
	file seek  `bhandle' query
	local loc = r(loc)
	
	*check if file ends  
	local checkend = 1
	if (`"`line'"' == `"`endfl'"') & (`"`file_ext'"'!="csv") {
		local  checkend   = 0
		while `checkend' == 0 { 
			file seek  `bhandle' `loc'
			file read  `bhandle' newline
			local newend  = r(eof)
			file seek  `bhandle' query
			local newloc  = r(loc)
			local newline `"`line'"'
			if `"`newline'"'  != "" local checkend = 1
			if   `newend'     != 0  local checkend = 2 
		}
	}
	if `checkend' == 2 continue, break
	
	*count graphs in tex file too 
	  *1) add break to avoid "too many floats"    
	  *2) add figure # before graph  
	if "`nocount'"=="" & regexm(`"`line'"',"Figure [1-9]+") & "`float'"=="" {
		local fignum = `fignum'+1
	}
	if "`nocount'" == "" & regexm(`"`line'"', "Table [1-9]+")  {
		local tabnum = `tabnum'+1
	}
	if "`file_ext'" == "tex" & "`break'" != "" {
		if regexm(`"`line'"', `"`endfig'"') {
			local numgraph = `numgraph'+1
		}
		if regexm(`"`line'"', `"`break'"') {
			local numgraph =  0
		}
	if `numgraph' == `brnum' {
		local line `"`line' `break'"'
		local numgraph = 0
	}
	}
	*write line to append file  		
	file write `ahandle' `"`line'"' _n	
 }

sreturn local fignum `fignum'
sreturn local tabnum `tabnum'

end // _appendFILE


exit // graphout


Version History --------------------------------------------------------------

version 0.0.1  10/20/10 
	* added:     basic functions & errors, replace, append & errors
version 0.0.2  10/23/10
	* cleaned:   rtf & tex file create 
	* added:     height, width, scale  & errors
version 0.0.3  10/25/10 
	* cleaned:   create files, append option
	* added:     rtf, html, tex alignment option & errors
version 0.0.4  10/27/10 
	* cleaned:   append/replace
	* added:     rtf, html, tex titles	
version 0.0.5  11/02/10 
	* fixed:     PC needs "respectcase" when searching dir
	* added:     adjust program to work with graphsto 
version 0.0.6  01/19/11
	* changed:   renamed graphout, graph ext. error removed, no default 	
	*            alignmnent, tex default is no longer float, no more 
	*            default center aligned, "respectcase" option for PCs 
	*            was not working corectly on Scott's computer.  Now I 
	*            just convert names to lowercase before searching
	* added:     as, document
version 0.0.7  01/27/11 
	* fixed:     respectcase error related to c(machine_type) returning
	*            PC (64-bit x86-64)     
version 0.0.8  01/28/11 
	* fixed:     fix in v007 didn't work correctly. used regular 
	*            expressions in this version.     
version 0.0.9  01/30/11 
	* fixed:     fix in v007 didn't work correctly. used regular 
	*            expressions in v008 but forgot to fix all commands that 
	*            relied on respectcase. this version fixes them all
	* added:     error for document option
version 0.1.0  01/30/11 
	* added:     nocount option (now figures are counted by default)
	* changed:   html was acting weird without center default so center 
	*            defaults are back, updated rtf locals for spaces, 
	*            put "_n" back in TEX file writing (like 0.0.5), changed
	*            rtf spacing
version 0.1.1  01/31/11 
	* added:     basecount
	* changed:   abbreviations of options 
version 0.1.2  02/02/11 11:30 AM 
	* updated rtf code to keep title and graph on same page
version 0.2.0  02/02/11 1:17 PM  
	* clean code so that rtf, tex, and html are written the same way
	* float option
version 0.2.1  02/03/11 11:56 AM 
	* add suboptions for title
	* adjust append code so it can be used with esttab
version 0.2.2  02/04/11 2:12 PM 
	* update _title_options subroutine
version 0.2.3  02/05/11 9:44 PM 
	* update to use $graphsto_stored_graphs`anything'
version 0.2.4  02/06/11 3:21 AM
	* last update was getting complicated, went back to the code of 0.2.2
version 0.2.5  02/28/11 11:57 AM 
	* allow path to file
version 0.3.0  03/05/11 11:35 AM 
	* new version for web  
version 0.3.0 :: 03/05/11 11:35 AM   
version 0.3.1 :: 12/11/11 05:10 PM :: added link to file  
version 0.3.2 :: 01/28/12 11:09 AM :: Added the use of appendFILE.ado
version 0.3.3 :: 03/30/12 9:29 AM :: Default alignment change 
version 0.3.4 :: 04/03/12 8:52 PM :: Doc and Append don't make error now   
version 0.3.5 :: 04/03/12 8:52 PM :: Include subroutines   
version 0.3.6 :: 4/24/14, 12:41 PM :: Update for changes in graphsto v023 
version 0.3.7 :: 5/5/14, 3:46 PM :: bug fixes
version 0.3.8 :: 5/6/14, 10:58 AM :: more bug fixes

// Hold then Delete ---------------------------------------------------------

