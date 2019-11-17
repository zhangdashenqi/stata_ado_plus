capture program drop do2htm
program define do2htm
  version 8

  if date(c(born_date),"dmy") < date("4/10/2003","mdy") {
    display as text "Your stata executable is from " c(born_date) " and needs to be updated"
    display as text "for this program to work.  You can update stata with the " as command "update all" as text " command."
    exit
  }

  syntax anything(name=dofile id="The name of a .do is") ///
    [, replace TItle(string asis) INput(string) Result(string) BG(string) ats]

  local dofile : subinstr local dofile ".do" "" 
  local dofile : subinstr local dofile ".DO" "" 

  grss clear
  global grss_png `dofile'
  global grss_log2htm 1

  set more off
  capture log close
  log using `dofile'.smcl, `replace'
  do `dofile'
  log close

  log2html2 `dofile', `replace' title(`title') input(`input') result(`result') bg(`bg') `ats'

  global grss_png 
  global grss_log2htm 
end


*! mnm changes, 4/18/03
*! mnm changed 6/16, fixed problem with ** comments
*! log2html 1.2.0  cfb/njc  3Mar2003
*! log2html 1.1.1  cfb/njc  17Dec2001
capture program drop log2html2
program define log2html2, rclass
	version 8.0
	syntax anything(name=smclfile id="The name of a .smcl logfile is") ///
	[, replace TItle(string asis) INput(string) Result(string) BG(string) ats]
	
	tempname hi ho
	tempfile htmlfile
	local smclfile : subinstr local smclfile ".smcl" "" 
	local smclfile : subinstr local smclfile ".SMCL" "" 
	local outfile `"`smclfile'.htm"'
  if "`ats'" != "" {
		qui log html `"`smclfile'"' `"`htmlfile'"', `replace'  whbf // * omitted yebf
  }
  else {
		qui log html `"`smclfile'"' `"`htmlfile'"', `replace'  whbf yebf
	}
	
	local cinput = cond("`input'" == "", "CC6600", "`input'") 
	local cresult = cond("`result'" == "", "000099", "`result'") 
	
	local cbg "ffffff"
	if "`bg'" ~= "" { 
		if ("`bg'" == "gray" | "`bg'" == "grey") local bg "cccccc" 
		local cbg `bg'
	}
	
	file open `hi' using `"`htmlfile'"', r
	file open `ho' using `"`outfile'"', w `replace'
	file write `ho'  _n
	file write `ho' "<html>" _n "<head>" _n
	if `"`title'"' ~= "" {
		file write `ho' `"<title>`title'</title>"' _n
		file write `ho' `"<h2>`title'</h2>"' _n
	}
	file write `ho' "</head>" _n	
	file write `ho' "<body bgcolor=`cbg'>" _n
	file read `hi' line

	local cprev = 0 
	local commentprev = 0
  local comment = 0

	if "`ats'" != "" { // ats style output
		while r(eof)==0 {

			* blank command
			if substr(`"`line'"',1,9) == "<b>. </b>" {
        if (`commentprev') {
					file write `ho' "</blockquote><pre>" _n
 				}
				local commentprev = 0
				file read `hi' line
				continue
			}

			* img line
			local line: subinstr local line "<b>#grssbefore#" "<img border='0' src=", count(local img)
      if (`img' > 0) {
  			local line: subinstr local line "#grssafter#</b>" ">"
				file write `ho' "<br>" _n
				file write `ho' `"`macval(line)'"' _n
				local commentprev = 0
				file read `hi' line
        continue
			}

			* empty paragraph line
			local line: subinstr local line "<p>" "", count(local par)
      if (`par' > 0) {
				local commentprev = 0
				file write `ho' "<br>" _n
				file read `hi' line
				continue
			}

			* strip "grss"
			local line: subinstr local line "<b>. grss " "<b>. "

			* strip continuation line
			* if ! (`commentprev'==0) {
				if substr(`"`line'"',1,7) == "<b>&gt;" {
					local line: subinstr local line "<b>&gt;" "<b>"
				}
			* }          

			* see if this is a comment
			if (substr(`"`line'"',1,7) == "<b>. **") {
				local comment 1
			}
			else {
				local comment 0
			}




			if (`comment') & ! (`commentprev') {
				local line: subinstr local line "<b>. **" "</pre><blockquote>"
  			local line: subinstr local line "</b>" "
			}
			if (`comment') & (`commentprev') {
				local line: subinstr local line "<b>. **" ""
  			local line: subinstr local line "</b>" "
			}
			if ! (`comment') & (`commentprev') {
				local line "</blockquote><pre>`line'"
			}


			file write `ho' `"`macval(line)'"' _n
			local commentprev = `comment'
			file read `hi' line
		}
	}
  else {
		while r(eof)==0 {


			* mnm addition, img line
			local line: subinstr local line "<b>#grssbefore#" "<img border='0' src=", count(local img)
      if (`img' > 0) {
  			local line: subinstr local line "#grssafter#</b>" ">"
				file write `ho' "<br>" _n
				file write `ho' `"`macval(line)'"' _n
				local commentprev = 0
				file read `hi' line
        continue
			}



			* command lines 
			local line: subinstr local line "<b>. " "<font color=`cinput'>. ", count(local c)
	
			* catch continuation lines
			if substr(`"`line'"',1,7) == "<b>&gt;" & `cprev' { 
				local line : subinstr local line "<b>" "<font color=`cinput'>", count(local c) 
			} 	
		 	else { 
				local line: subinstr local line "<b>" "<font color=`cresult'>", all
			}
		
			local line: subinstr local line "</b>" "</font>", all

			file write `ho' `"`macval(line)'"' _n
			local cprev = `c' 
			file read `hi' line
		}
	}

	file write `ho' "</body>" _n "</html>" _n
	file close `ho'
	di _n `"HTML log file `outfile' created"' 
end


