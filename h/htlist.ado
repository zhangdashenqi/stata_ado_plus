*! version 2.0 Apr 2012 by LQ
*! version 1.1 Nov 2007 by JJAV

*! This program displays the values of variables into the HTML file
*! Disclaimer: This program is provided "AS IS".
*! Authors are not responsible of any kind of damage, derived from the use of this program.

program define htlist
version 8.0
syntax [varlist] [if] [in] [, NODisplay Display NOLabel NOObs /*
*/ VArname NOVarlab /*
*/ Table(string) Align(string)]

preserve
if `"`table'"' == "" {
	local table = `"BORDER="1" CELLSPACING="0" CELLPADDING="2""'
}
local varal "align=left"
local valal "align=right"

if "`noobsv'" == "" {
	tempvar n
	qui gen `n' = _n
}

if "`if'`in'" != "" {
	qui keep `if' `in'
}

local varnum : word count "`varlist'"

if "`nodispl'"  != "" & "`display'" != "" {
	noi di in as err "nodisplay<->display error"
	error 101
}

local mode "long"
if "`nodispl'" != "" | "`nodispl'" == "" & "`display'" == ""  & `varnum' <= 6 {
	local mode "browse"
}

htput <TABLE `table'>
if "`mode'" == "long" {
	local cols = cond("`varname'"!="",1,0)+cond("`novarla'" == "", 1, 0)+1
	if `cols' == 1 {
		local valal "ALIGN LEFT"
	}
	local i = 1 
	while `i' <= _N {
		if "`noobs'" == "" {
			htput <TR>
			htput <TD colspan=`cols'> Observation  `: di `n'[`i']'  </TD>
			htput </TR>
		}
		else{
			if `i' != 1 {
				htput <TR>
				htput <TD colspan=`cols'>&nbsp;</TD>
				htput </TR>
			}
		}
		tokenize "`varlist'"
		while "`1'" != "" {
			htput <TR>
			if "`varname'" != "" {			
				local x = "`1'"
				htput <TD `varal'>`x'</TD>
			}
			if "`novarla'" == "" {
				local x: variable label `1'
				if `"`x'"' == "" {
					local x = "`1'"
				}
				htput <TD `varal'>`x'</TD>
			}
			local x = `1'[`i']
			local type: type `1'
			if regexm("`type'", "^str") {
				if `"`x'"' == "" {
					local x = "&nbsp;"
				}
				htput <TD `valal'>`x'</TD>
			}
			else {
				local y: label (`1') `x'
				if "`y'" != "`x'" & "`nolabel'" == "" {
					htput <TD `valal'>`y'</TD>
				}
				else {		
					local format: format `1'
					htput <TD `valal'> `: di `format' `x'' </TD>
				}
			}
			htput </TR>
			mac shift
		}
		local i = `i'+1
	}
}
else {
	if `varnum' == 1 {
		if "`align'" != "" {
			local valal = "ALIGN=`align'"
		}
		else {
			local valal = "ALIGN=CENTER"
		}
	}
	else {
		local valal = "ALIGN=CENTER"
	}
	if "`novarlab'" == "" {
		htput <TR>
		if "`noobs'" == "" {
			htput <TH>&nbsp;</TH>
		}
		tokenize "`varlist'"
		while "`1'" != "" {
			if "`novarlab'" == "" {
				local x: variable label `1'
				if `"`x'"' == "" {
					local x = "`1'"
				}
				htput <TH ALIGN=CENTER>`x'</TH>
			}
		mac shift			
		}		
		htput </TR>
	 }

	if "`varname'" != "" {
		htput <TR>
		if "`noobs'" == "" {
			htput <TH>&nbsp;</TH>
		}
		tokenize "`varlist'"
		while "`1'" != "" {
			local x = "`1'"
			htput <TH ALIGN=CENTER>`x'</TH>
			mac shift
		}
		htput </TR>
	}
	
	local i = 1 
	while `i' <= _N {
		htput <TR>
		if "`noobs'" == "" {
			htput <TD ALIGN=RIGHT>`i'</TD>
		}
		tokenize "`varlist'"
		while "`1'" != "" {
			local x = `1'[`i']
			local type: type `1'
			if regexm("`type'", "^str") {
				if `"`x'"' == "" {
					local x = "&nbsp;"
				}
				htput <TD `valal'>`x'</TD>
			}
			else {
				local y: label (`1') `x'
				if "`y'" != "`x'"  & "`nolabel'" == "" {
					htput <TD `valal'>`y'</TD>
				}
				else {		
					local format: format `1'
					htput <TD `valal'> `:di `format' `x'' </TD>
				}
			}
	
			mac shift
		}
		htput </TR>
		local i = `i'+1
	}
}
htput </TABLE>
end
