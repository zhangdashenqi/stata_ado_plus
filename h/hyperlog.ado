*  hyperlog:  Convert Stata do-file and corresponding log file into an
*  HTML hyperlinked index file for quick navigation.
*
*  John Eng, M.D.
*! version 1.0.1  November 2006
*
*  The prototype for this program was stata2html.pl.
*
*  Current limitations:
*  1.  Not all commands within code blocks (foreach, forvalues, if, while)
*      may match.
*  2.  Log commands within code blocks require multipass mode.
*  3.  Mulitpass mode could take a long time if the log file is long or there
*      are a lot of unmatched lines.
*  4.  The log file must be opened from within the corresponding do-file.
*
*  Version history:
*  1.0.0   Sep 2005   Initial version
*  1.0.1   Nov 2006   Added default file extension, optional second argument, replace option,
*                     version comment (*!), HTML class attribute

program hyperlog
version 8.0
syntax anything(id="one or two filenames") [, MULTIpass replace debug]

** Check number of arguments
tokenize `"`anything'"'
if ((`"`1'"' == "") | (`"`3'"' != "")) error 198  // Wrong number of arguments
local doFileName `"`1'"'
local logFileName `"`2'"'

** Add default extension to first argument, if necessary
if (index(`"`doFileName'"', ".") == 0) local doFileName = `"`doFileName'"' + ".do"

** Get root name based on do-file name
local rootName = trim(`"`doFileName'"')
if (index(`"`doFileName'"', ".") > 1) {
	local i = index(reverse(`"`doFileName'"'), ".")
	local rootName = substr(`"`doFileName'"', 1, length(`"`doFileName'"')-`i')
	}

** Process optional second argument, add default extension if necessary
if (`"`logFileName'"' == "") local logFileName = `"`rootName'"' + ".log"
if (index(`"`logFileName'"', ".") == 0) local logFileName = `"`logFileName'"' + ".log"

** Default parsing and matching behavior
local PARSE_LOG_CMDS = 1  // If enabled, parse log commands to turn matching on or off
local ALLOW_REWIND = 0    // If enabled, scanning of log file does not stop after first non-matching line
local DEBUG_FLAG = 0      // If enabled, show all mismatches

** Check options
if ("`multipass'" == "multipass") {
	local PARSE_LOG_CMDS = 0
	local ALLOW_REWIND = 1
	}
if ("`debug'" == "debug") local DEBUG_FLAG = 1
if ("`replace'" == "") confirm new file "`rootName'_hlog.html"

** Open do-file, log file, and HTML output files
tempname fpDo     // File handle for Stata do-file
tempname fpLog    // File handle for Stata log file
tempname fpCtrl   // File handle for HTML do-file 
tempname fpDisp   // File handle for HTML log file
file open `fpDo' using `"`doFileName'"', read text
file open `fpLog' using `"`logFileName'"', read text
file open `fpCtrl' using `"`rootName'_do.html"', write text `replace'
file open `fpDisp' using `"`rootName'_log.html"', write text `replace'

** Write HTML header for do-file
local currentDate = "$S_DATE at $S_TIME"
file write `fpCtrl' `"<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">"' _n
file write `fpCtrl' `"<HTML>"' _n
file write `fpCtrl' `"<!--"' _n
file write `fpCtrl' `""' _n
file write `fpCtrl' `"        This HTML file was computer-generated on `currentDate' by"' _n
file write `fpCtrl' `"        hyperlog, a Stata program written by John Eng (jeng@jhmi.edu)."' _n
file write `fpCtrl' `""' _n
file write `fpCtrl' `"-->"' _n
file write `fpCtrl' `"<HEAD>"' _n
file write `fpCtrl' `"<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=ISO-8859-1">"' _n
file write `fpCtrl' `"<TITLE>Stata Do-File</TITLE>"' _n
file write `fpCtrl' `"<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">"' _n
file write `fpCtrl' `"function goLink(linkName) {"' _n
file write `fpCtrl' `"    window.parent.displayFrame.location.href = window.parent.displayFrame.location.pathname + "#" + linkName;"' _n
file write `fpCtrl' `"    }"' _n
file write `fpCtrl' `"</SCRIPT>"' _n
file write `fpCtrl' `"<STYLE TYPE="text/css">"' _n
file write `fpCtrl' `"PRE.hyperlog {font-family: Andale Mono, Lucida Console, Courier, Courier New, monospace; font-size: 11px}"' _n
file write `fpCtrl' `"A.hyperlog:link, A.hyperlog:visited, A.hyperlog:active {text-decoration: none; color: blue}"' _n
file write `fpCtrl' `"</STYLE>"' _n
file write `fpCtrl' `"</HEAD>"' _n
file write `fpCtrl' `"<BODY BGCOLOR=WHITE>"' _n
file write `fpCtrl' `"<PRE CLASS=hyperlog>"' _n

** Write HTML header for log file
file write `fpDisp' `"<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">"' _n
file write `fpDisp' `"<HTML>"' _n
file write `fpDisp' `"<!--"' _n
file write `fpDisp' `""' _n
file write `fpDisp' `"        This HTML file was computer-generated on `currentDate' by"' _n
file write `fpDisp' `"        hyperlog, a Stata program written by John Eng (jeng@jhmi.edu)."' _n
file write `fpDisp' `""' _n
file write `fpDisp' `"-->"' _n
file write `fpDisp' `"<HEAD>"' _n
file write `fpDisp' `"<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=ISO-8859-1">"' _n
file write `fpDisp' `"<TITLE>Stata Log File</TITLE>"' _n
file write `fpDisp' `"<STYLE TYPE="text/css">"' _n
file write `fpDisp' `"PRE.hyperlog {font-family: Andale Mono, Lucida Console, Courier, Courier New, monospace; font-size: 11px}"' _n
file write `fpDisp' `"A.hyperlog {color: red}"' _n
file write `fpDisp' `"</STYLE>"' _n
file write `fpDisp' `"</HEAD>"' _n
file write `fpDisp' `"<BODY BGCOLOR=WHITE>"' _n
file write `fpDisp' `"<PRE CLASS=hyperlog>"' _n

** Main processing loop through do-file
local linkCount = 0
local logFlag = 0      // If set, then logging has been turned on
local warningFlag = 0  // Number of command lines not found
local baseFilePos = 0
local begOfLinePos = 0

file read `fpDo' s
while (r(eof) == 0) {

	* Detect start of logging in do-file
	local s2 = subinstr(`"`macval(s)'"', char(9), " ", .)  // Substitute tabs in line from do-file
	if ((`PARSE_LOG_CMDS' == 1) & ((word(`"`macval(s2)'"', 1) == "log") & ((word(`"`macval(s2)'"', 2) == "using") | (word(`"`macval(s2)'"', 2) == "on")))) {
		local logFlag = 1
		}

	* Detect end of logging in do-file
	else if ((`PARSE_LOG_CMDS' == 1) & ((word(`"`macval(s2)'"', 1) == "log") & ((word(`"`macval(s2)'"', 2) == "off") | (word(`"`macval(s2)'"', 2) == "close")))) {
		local logFlag = 0
		}

	* Detect command lines (non-blank, non-comment) in do-file
	else if (!((trim(`"`macval(s2)'"') == "") | (index(`"`macval(s2)'"', "*") == 1) | (word(`"`macval(s2)'"', 1) == "//") | (word(`"`macval(s2)'"', 1) == "/*") | ((`logFlag' == 0) & (`PARSE_LOG_CMDS' == 1)))) {
		* Process one command line from do-file
		local indexKey = substr(". " + ltrim(`"`macval(s2)'"'), 1, 40)  // Form text line to search for in log file
		local foundFlag = 0
		file read `fpLog' t
		while (r(eof) == 0) {  // Scan through log file for a match
			local targetKey `"`macval(t)'"'
			if (substr(`"`macval(targetKey)'"', 1, 1) == ".") {
				local targetKey = ". " + ltrim(substr(subinstr(`"`macval(targetKey)'"', char(9), " ", .), 2, .))  // Substitute tabs and delete leading spaces
				}
			local targetKey = substr(`"`macval(targetKey)'"', 1, 40)
			if (`"`macval(indexKey)'"' == `"`macval(targetKey)'"') {  // Process matching lines
				* Copy log file lines preceding the match
				file seek `fpLog' query
				local savedFilePos = r(loc)
				file seek `fpLog' `baseFilePos'
				file seek `fpLog' query
				local currentPos = r(loc)
				while (`currentPos' < `begOfLinePos') {
					file read `fpLog' t2
					local t2: subinstr local t2 "&" "&amp;", all
					local t2: subinstr local t2 "<" "&lt;", all
					file write `fpDisp' `"`macval(t2)'"' _n
					file seek `fpLog' query
					local currentPos = r(loc)
					}
				file seek `fpLog' `savedFilePos'
				* Write hyperlink line to HTML do-file
				local s: subinstr local s "&" "&amp;", all
				local s: subinstr local s "<" "&lt;", all
				local s `"<A CLASS=hyperlog HREF="javascript:goLink('Link`linkCount'')">`macval(s)'</A>"'
				file write `fpCtrl' `"`macval(s)'"' _n
				* Write hyperlink line to HTML log file
				local t: subinstr local t "&" "&amp;", all
				local t: subinstr local t "<" "&lt;", all
				local t `"<A CLASS=hyperlog NAME="Link`linkCount'">`macval(t)'</A>"'
				file write `fpDisp' `"`macval(t)'"' _n
				* Update counters and flags
				local linkCount = `linkCount' + 1
				local foundFlag = 1
				local baseFilePos = `savedFilePos'
				local begOfLinePos = `savedFilePos'
				continue, break  // Stop scanning log file
				}
			file seek `fpLog' query
			local begOfLinePos = r(loc)
			file read `fpLog' t
			}  // End of loop over log file
		if (`foundFlag' == 1) {  // If match found, skip to next line in do-file
			file read `fpDo' s
			continue  // Go to next line in do-file
			}
		else {  // If no match found, rewind log file if allowed (multipass mode)
			if (`ALLOW_REWIND' == 1) file seek `fpLog' `baseFilePos'
			local warningFlag = `warningFlag' + 1
			if (`DEBUG_FLAG' > 0) {
				if (`DEBUG_FLAG' == 1) display as error "do-file line(s) not found in log file:"
				display as error _asis substr(`"`macval(indexKey)'"', 3, .)
				local DEBUG_FLAG = `DEBUG_FLAG' + 1
				}
			}
		}

	* Otherwise, just copy the do-file text line
	local s: subinstr local s "&" "&amp;", all
	local s: subinstr local s "<" "&lt;", all
	file write `fpCtrl' `"`macval(s)'"' _n
	file read `fpDo' s
	}  // End of loop over do-file

** Write out remaining log file
file seek `fpLog' `baseFilePos'
file read `fpLog' t
while (r(eof) == 0) {
	local t: subinstr local t "&" "&amp;", all
	local t: subinstr local t "<" "&lt;", all
	file write `fpDisp' `"`macval(t)'"' _n
	file read `fpLog' t
	}
forvalues i = 1/66 {  // Write blank lines so links at end of page will also work
	file write `fpDisp' _n
	}

** Write HTML trailer for do-file
file write `fpCtrl' `"</PRE>"' _n
file write `fpCtrl' `"</BODY>"' _n
file write `fpCtrl' `"</HTML>"' _n

** Write HTML trailer for log file
file write `fpDisp' `"</PRE>"' _n
file write `fpDisp' `"</BODY>"' _n
file write `fpDisp' `"</HTML>"' _n

** Close files
file close `fpDo'
file close `fpLog'
file close `fpCtrl'
file close `fpDisp'

** Write main HTML file setting up frames to display the HTML files created above
tempname fpMain
file open `fpMain' using "`rootName'_hlog.html", write text `replace'
file write `fpMain' `"<HTML>"' _n
file write `fpMain' `"<!--"' _n
file write `fpMain' `""' _n
file write `fpMain' `"        This HTML file was computer-generated on `currentDate' by"' _n
file write `fpMain' `"        hyperlog, a Stata program written by John Eng (jeng@jhmi.edu)."' _n
file write `fpMain' `""' _n
file write `fpMain' `"-->"' _n
file write `fpMain' `"<HEAD>"' _n
file write `fpMain' `"<TITLE>Stata Log File Browser Page</TITLE>"' _n
file write `fpMain' `"</HEAD>"' _n
file write `fpMain' `"<FRAMESET COLS="*,600">"' _n
file write `fpMain' `"    <FRAME NAME="controlFrame" SRC="`rootName'_do.html">"' _n
file write `fpMain' `"    <FRAME NAME="displayFrame" SRC="`rootName'_log.html">"' _n
file write `fpMain' `"</FRAMESET>"' _n
file write `fpMain' `"</HTML>"' _n
file close `fpMain'

** Construct full path to index file, if not already a full path specification
local indexPath ""
if ((substr(`"`rootName'"', 2, 1) != ":") & (substr(`"`rootName'"', 1, 1) != "/")) {
	local indexPath `"`c(pwd)'`c(dirsep)'"'
	}

** Show confirmation message
display as text `"Input files:  `doFileName', `logFileName'"'
display as text `"Ouput files:  `rootName'_hlog.html (`rootName'_do.html, `rootName'_log.html)"'
if (`warningFlag' > 0) {
	display as text "(`warningFlag' unmatched command " plural(`warningFlag', "line") " in do-file)"
	}
display as text _n `"To view index file, open file {browse "file://`indexPath'`rootName'_hlog.html":`rootName'_hlog.html} in a web browser."'
end
