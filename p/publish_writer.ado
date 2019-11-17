program define publish_writer , sclass
*! Document writing program used by publish.ado 
*! Version 0.0.3 - 17 August 2010
*! Author: Tamas Bartus, Corvinus University Budapest 

	version 11
	if "$publish_file"=="" {
		di as error "No files open; use -publish open- first"
		exit 
	}
	gettoken as 0 : 0
	gettoken write 0 : 0
	if `"`write'"'=="" | `"`write'"'==","{
		publish_`as'_table
		publish_`as'_break
		sret clear
		exit
	}
	else {
		local allowed open close table break text
		local check : subinstr local allowed "`write'" "" ,  count(local change)	
 		if `change'==0 {
			di as error "publish_writer received invalid write() option from publish.ado"
			error 198 
		}
		else publish_`as'_`write'  `0'
		sret clear
		exit
	}
end




*-----------------------------------------------------
* [1] HTML 
*-----------------------------------------------------

program define publish_html_open , sclass
	syntax [ , title(string) from(string) * ]
	
	local using $publish_file
	tempname target source
	file open `target' using `"`using'"', write text replace
	
// writing head of the document

	file open `source' using `"`from'"' , read text
	local doit = 1
	while `doit'==1 {
		file read  `source' line
		if substr(`"`line'"',1,1)!="*" & substr(`"`line'"',1,2)!="" {
			local tmp : subinstr local line "</body>" "" , count(local c)
			if `c'==1 local doit = 0
			else {
				local tmp : subinstr local line "<title>" "" , count(local c)
				if `c'==1 local line <title>`title'</title>
				file write `target' `"`line'"'  _n
			}
		}
		if r(eof)==1 local doit==0
	}
end


program define publish_html_close , sclass
	version 11
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append
  	file write `target' "</body>" _n
	file write `target' "</html>" _n
	file close `target'
	sret list
	sret clear
	foreach word in file section doctype {
		macro drop publish_`word'
	}
end


program publish_html_table , sclass
	version 11
	syntax [, title(string) width(integer 100) nosupercol cellsplit(integer 2) doc * ]

	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append
	file write `target' `"<div align="center">"' _n

// Caption

	local id = $publish_tabnum +1
	global publish_tabnum = `id'

	if "`doc'"=="" {
		if `"`title'"'!="" {
			file write `target' `"<p class=st_caption>Table `id'</p>"' _n
			file write `target' `"<p class=st_caption>`title'</p>"' _n
		}
	}
	else  {
		local field <!--[if supportFields]><span style='mso-element:field-begin'></span><span style='mso-spacerun:yes'> 
		local field `field' </span>SEQ Table \* ARABIC <span style='mso-element:field-separator'></span><![endif]-->
		local field `field' <span style='mso-no-proof:yes'>`id'</span>
		local field `field' <!--[if supportFields]><span style='mso-element:field-end'></span><![endif]-->
		if `id'>1 {
			file write `target'  _n
			file write `target' "<span>" _n
			file write `target' `"<br clear=all style='page-break-before:always;mso-break-type:page-break'>"' _n
			file write `target' "</span>" _n
			file write `target'  _n
		}
		if `"`title'"'!="" {
			if $publish_section !=0 local head $publish_section-
			else local head 
			local head $publish_TitleLeft `head'`field'$publish_NumberChar  $publish_TitleRight
			file write `target'  _n
			file write `target' `"<p class=MsoCaption style='page-break-after:avoid'> `head' </p>"' _n
			file write `target' `"<p class=MsoCaption> `title' </p>"' _n
		}
	}
	file write `target'  _n

// Table begins
	file write `target' ///
		`"<table width=`width'% border=0 cellpadding=0 cellspacing=0 style='border-collapse:collapse;mso-table-layout-alt:fixed;mso-padding-alt:0pt 0pt 0pt 0pt;'>"' _n

// Header of the table
	if `"`s(r0c0)'"'=="" local r0c0 $publish_FirstColHead
	else local r0c0 `s(r0c0)'
	if `s(nscol)'>1 {
		local border style='border-top: solid windowtext 0.5pt;'
		file write `target' " <tr>" _n
		if "`s(cw0)'"!="" local width width=`s(cw0)'% 
		file write `target' `"  <td `width' `border'><p class="publish">`r0c0)'</p></td>"' _n
		forval i = 1 / `s(nscol)' {
			local colspan = `cellsplit'*`s(ncol`i')'
			local colspan colspan=`colspan'
			FormatText html `s(sc`i')'
			if "`s(scw`i')'"!="" local width width=`s(scw`i')'% 
			file write `target' `"  <td `width' `colspan' `border'><p class="publish" align="center" style="text-align: center">`s(text)'</p></td>"' _n
		}
		file write `target' " </tr>" _n
		local border style='border-bottom: solid windowtext 0.5pt;'
		local text &nbsp;
	}
	else {
		local border style='border-bottom: solid windowtext 0.5pt;border-top: solid windowtext 0.5pt;'
		local text "`s(r0c0)'"
	}
	file write `target' " <tr>" _n
	if "`s(cw0)'"!="" local width width=`s(cw0)'% 
	file write `target' `"  <td `width' `border'><p class="publish">`text'</p></td>"' _n
	forval c = 1/ `s(ncol)' {
		local colspan colspan=`cellsplit'
		if "`s(cw`c')'"!="" local width width=`s(cw`c')'% 
		FormatText html `s(c`c')'
		file write `target' `"  <td `width' `colspan' `border'><p class="publish" align="center" style="text-align: center">`s(text)'</p></td>"' _n
	}
	file write `target' " </tr>" _n
		

// Contents of the table
	local border
	forval r = 1 / `s(nrow)' {
		if `r'==`s(nrow)' 	local border style='border-bottom: solid windowtext 0.5pt;'
		file write `target' " <tr>" _n
		FormatText html `s(r`r')'
		file write `target' `"  <td `border'><p class="publish">`s(text)'</p></td>"' _n
		forval c = 1 / `s(ncol)' {
			SplitNumber html `cellsplit' `s(r`r'c`c')'
			local cw = `s(cw`c')'/`cellsplit'
			local cw width="`cw'%"
			//if "`s(cw`c')'"!="" local width =`s(cw`c')'% 
			if `cellsplit'==2 {
				file write `target' ///
					`"  <td `cw' `border'><p class="publish" align=right style="text-align: right">`s(text1)'</p></td><td `cw' `border'><p class="publish">`s(text2)'</p></td>"' _n
			}
			else if `cellsplit'==4 {
				file write `target' ///
					`"  <td `cw' `border'><p class="publish" align=right style="text-align: right">`s(text1)'</p></td><td `cw' `border'><p class="publish">`s(text2)'</p></td>"' _n
				file write `target' ///
					`"  <td `cw' `border'><p class="publish" align="right" style="text-align: right">`s(text3)'</p></td><td `cw' `border'><p class="publish">`s(text4)'</p></td>"' _n
			}
			else file write `target' `"  <td `width' `border'><p class="publish">`s(text1)'</p></td>"' _n
		}
		file write `target' " </tr>" _n
	}

	// End of the table

	file write `target' "</table>" _n
	file write `target' "</div>" _n
	file write `target' "<p> &nbsp; </p>" _n
	// NOTES COME HERE.....
	file write `target'  _n
	file write `target'  _n

end



program publish_html_break
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append	
	file write `target'  _n
	
	file write `target' "<span>" _n
	file write `target' "<br clear=all style='page-break-before:always;mso-break-type:section-break'>" _n
	file write `target' "</span>" _n

end


program define publish_html_text
	version 11
	syntax anything [ , format(string) style(string) ]
	if `"`format'`syle'"'=="" local line `anything'
	else local line <`format' `style'>`anything'</`format'>
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append
	file write `target' `"`line'"' _n
end


*-----------------------------------------------------
* [2] DOC 
*-----------------------------------------------------

program define publish_doc_open , sclass
	publish_html_open `0'
end


program define publish_doc_close , sclass
	publish_html_close `0'
end


program publish_doc_table , sclass
	if `"`0'"'=="" publish_html_table , doc
	else publish_html_table `0' doc 
end


program publish_doc_break
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append	
	file write `target'  _n
	
	file write `target' "<span>" _n
	file write `target' "<br clear=all style='page-break-before:always;mso-break-type:section-break'>" _n
	file write `target' "</span>" _n

end


program define publish_doc_text
	publish_html_text `0'
end




*-----------------------------------------------------
* [3] TEX
*-----------------------------------------------------



program define publish_tex_open , sclass
	syntax [ , title(string) from(string) * ]
	
	local using $publish_file
	tempname target source
	file open `target' using `"`using'"', write text replace

// writing head of the document

	file open `source' using `"`from'"' , read text
	local doit = 1
	while `doit'==1 {
		file read  `source' line
		if substr(`"`line'"',1,1)!="*" & substr(`"`line'"',1,2)!="" {
			local tmp : subinstr local line "\end{document}" "" , count(local c)
			if `c'==1 local doit = 0
			else {
				local tmp : subinstr local line "\title{" "" , count(local c)
				if `c'==1 local line "\title{`title'}"
				file write `target' `"`line'"'  _n
			}
		}
		if r(eof)==1 local doit==0
	}	
end


program define publish_tex_close , sclass
	version 11
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append
	file write `target' `"\end{document}"' _n
	file close `target'
	sret clear
	foreach word in file section doctype {
		macro drop publish_`word'
	}
end


program publish_tex_table , sclass
	version 11
	syntax [, title(string) width(integer 100) nosupercol  cellsplit(integer 2) ]
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append

// Tabular environment begins
	file write `target'  _n
	file write `target' "\begin{table}" _n
	local width = `width'/100
	local cw0 = `s(cw0)'/100
	if `"`title'"'!="" file write `target' "\caption{`title'}" _n
	// begin tabular
	if `cellsplit'>1 {
		local ncol = cond(`cellsplit'==2,`s(ncol)',2*`s(ncol)')
		file write `target' "\begin{tabular*}{`width'\textwidth}[t]{ p{`cw0'\textwidth} *{`ncol'}{ r@{} @{}l} }" _n
//		file write `target' "\begin{tabular*}{`width'\textwidth}[t]{@{\extracolsep{\fill}} p{`cw0'\textwidth} *{`ncol'}{ r@{} @{}l} }" _n
//		file write `target' "\begin{tabular*}{`width'\textwidth}[t]{@{\extracolsep{\fill}} p{`cw0'\textwidth} *{`ncol'}{ r @{.} l} }" _n
	}
	else file write `target' "\begin{tabular*}{`width'\textwidth}[t]{@{\extracolsep{\fill}} p{`cw0'\textwidth} *{`s(ncol)'}{ l} }" _n
	/*
	// To allow for columns with predefined colwidth:
	local tabspec
	local width = `s(cw0)'/10
	local tabspec p{`width' cm}
	forval i = 1/`s(ncol)' {
		local width = `s(cw`i')'/10
		local tabspec `tabspec' p{`width' cm}
	}
	file write `target' "\begin{tabular}[t]{`tabspec'}" _n
	*/

// Header of the table
	if `s(nscol)'>1 {
		file write `target' "\hline" _n
		if `"`s(r0c0)'"'!=`""' local r0c0 `s(r0c0)'
		else local r0c0 $publish_FirstColHead
		file write `target' "`r0c0'" _n
		forval i = 1 /`s(nscol)' {
			local ncol = `cellsplit'*`s(ncol`i')'
			FormatText tex `s(sc`i')'
			file write `target' `" & \multicolumn{`ncol'}{c}{`s(text)'}"' _n
		}
		file write `target' "`=char(92)'`=char(92)'" _n
		local r0c0
	}
	else file write `target' "\hline" _n

	file write `target' `"`r0c0'"' _n
	forval i = 1 / `s(ncol)' {
		FormatText tex `s(c`i')'
		file write `target' " & \multicolumn{`cellsplit'}{c}{`s(text)'}" _n
	}
	file write `target' "`=char(92)'`=char(92)'" _n
	file write `target' "\hline" _n


// Contents of the table
	
	forval r = 1 / `s(nrow)' {
		FormatText tex `s(r`r')'
		file write `target' `"`s(text)'"' _n
		forval c = 1 / `s(ncol)' {
			SplitNumber tex `cellsplit' `s(r`r'c`c')'
			local cell
			forval i = 1/`cellsplit' {
				local cell `cell' & `s(text`i')'
			}
			file write `target' `"`cell'"' _n
		}
		file write `target' "`=char(92)'`=char(92)'" _n
	}

	// End of the table

	file write `target' "\hline" _n
	file write `target' "\end{tabular*}" _n
	file write `target' "\end{table}" _n
	
	// NOTES COME HERE.....

	file write `target'  _n
end


program publish_tex_break
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append	
	file write `target'  _n
	file write `target' "\pagebreak{}" _n
	file write `target'  _n

end


program define publish_tex_text
	version 11
	syntax anything [ , format(string) style(string)
	if `"`syle'"'!="" local style [`style']
	if `"`format'`syle'"'=="" local line `anything'
	else local line \`format'`style'{`anything'}
	local using $publish_file
	tempname target
	file open `target' using `"`using'"', write text append
	file write `target' `"`line'"' _n
end



*-----------------------------------------------------
* COMMON SUBROUTINES 
*-----------------------------------------------------

program FormatText , sclass
	gettoken as 0 : 0 , parse(" ")
	if `"`0'"'=="" {
		ReturnSpace_`as' 1
		sret local text `s(space)'
		exit
	}
	local text : subinstr local 0 "_" " " , all
	local text = itrim(`"`text'"')
	local text = trim(`"`text'"')
	if substr("`text'",1,5)=="{TAB}" {
		local text = substr("`text'",6,.)
		* local tab = $publish_intend
		* then make a loop and add characters after each other
		ReturnSpace_`as' 2
		local space `s(space)'
	}
	sret local text `space'`text'
end


program ReturnSpace_html , sclass
	forval i = 1/`0' {
		local space `space'&nbsp;
	}
	sret local space `space'
end


program ReturnSpace_doc , sclass
	ReturnSpace_html `0'
end


program ReturnSpace_tex , sclass
	forval i = 1/`0' {
		local space `space'~
	}
	sret local space `space'
end


program SplitNumber , sclass
	gettoken as 0 : 0
	gettoken split  0 : 0
	ReturnSpace_`as' 1
// Do nothing special if split==1
	if `split'==1 {
		if `"`0'"'=="" sret local text`i' `s(space)'
		else sret local text1 `0'
		exit
	}
// Splitting numbers
	local nr = `split'/2
	forval r = 1/`nr' {
		local r1 = 2*`r'-1
		local r2 = 2*`r'
		gettoken token 0 : 0
		// Taking care of missing data
		//local check : subinstr local 0 "." "" , all
		if "`token'"=="" | "`token'"=="."  {
			sret local text`r1' `s(space)'
			sret local text`r2' `s(space)'
			continue
		}
		local pos = strpos("`token'",".")
		if `pos'==0 {
			sret local text`r1' `token'
			sret local text`r2' `s(space)'
		}
		else {
			local t1 = substr("`token'",1,`pos'-1)
			//if "`as'"=="tex" local pos = `pos'+1
			local t2 = substr("`token'",`pos',.)
			sret local text`r1' `t1'
			sret local text`r2' `t2'
		}
	}
end

	   


