*! 1.0.1  11apr1995                             (STB-25: dm29)
program define textab
	version 4.0
	local varlist  "req ex min(1)"
	local if       "opt"
	local in       "opt"
	#delimit ;
	local options  "VLINes(string)    SEP(string)        TABskip(string)
			Font(string)      BSTRs(string)      ESTRs(string)
			MISSing(string)   ALign(string)      FORMat(string)
			noCENter";
	#delimit cr

	parse "`*'"

	local nvars : word count `varlist'
	tempvar use last
	mark `use' `if' `in'

	qui gen `last'=_n
	qui replace `last'=`last'*`use'

	qui summ `last'
	local bigob = _result(6)

	qui de
	local nobs = _result(1)

	local i=1
	local j=1
	parse "`vlines'", parse(" ,")
	while `i'<=(`nvars'+1) {
		if "``j''"=="s" {
			local vr`i'="{\vrule}"
			local j=`j'+1
		}
		else if "``j''"=="d" {
			local vr`i'="{\vrule\hskip2pt\vrule}"
			local j=`j'+1
		}
		else if "``j''"=="b" {
			local vr`i'="{\vrule width1.2pt}"
			local j=`j'+1
		}
		else {
			if "``j''"!="," {local j=`j'+1}
			local vr`i'=""
		}
		local i=`i'+1
		local j=`j'+1
	}

	local i=1
	local j=1
	parse "`sep'", parse(" ,")
	while `i'<=3 {
		local spp`i'="y"
		if "``j''"=="s" {
			local sp`i'="\noalign{\hrule}"
			local j=`j'+1
		}
		else if "``j''"=="b" {
			local sp`i'="\noalign{\hrule height1.2pt}"
			local j=`j'+1
		}
		else {
			if "``j''"!="," {local j=`j'+1}
			local sp`i'="%"
			local spp`i'="n"
		}
		local i=`i'+1
		local j=`j'+1
	}

	local i=1
	local j=1
	parse "`format'", parse(" ,")
	while `i'<=`nvars' {
		if "``j''" != "," {
			local fm`i' = "``j''"
			local j=`j'+1
		}
		else {
			local fm`i'=""
		}
		local j=`j'+1
		local i=`i'+1
	}

	local i=1
	local j=1
	parse "`missing'", parse(",")
	while `i'<=`nvars' {
		if "``j''" != "," {
			local mis`i' = "``j''"
			local j=`j'+1
		}
		else {
			local mis`i'=""
		}
		local j=`j'+1
		local i=`i'+1
	}

	local i=1
	parse "`varlist'", parse(" ")
	while `i'<=`nvars' {
		local V`i' = "``i''"
		local i=`i'+1
	}

	local blen = length("`bstrs'")
	local elen = length("`estrs'")

	if "`tabskip'" != "" {local topt = "tabs(`tabskip')" }
	else                 {local topt = ""                }
	if "`align'"   != "" {local aopt = "justfy(`align')" }
	else                 {local aopt = ""                }
	if "`font'"    != "" {local fopt = "font(`font')"    }
	else                 {local fopt = ""                }
	if `blen'      != 0  {local bopt = "begin(`bstrs')"  }
	else                 {local bopt = ""                }
	if `elen'      != 0  {local eopt = "end(`estrs')"    }
	else                 {local eopt = ""                }

	di "% " in gr "BEGINNING OF TEXTAB TABLE"
	if "`center'"=="" { di "$$\vbox{" }
	else 		  { di "\vbox{"   }
	
	align, `topt' `aopt' `fopt' `bopt' `eopt' nvars(`nvars')

/* di "\vrule height 0.7\baselineskip depth 0.3\baselineskip width0pt"  Reg */
/* di "\vrule height 1.1\baselineskip depth 0.3\baselineskip width0pt"  Top */
/* di "\vrule height 0.7\baselineskip depth 0.7\baselineskip width0pt"  Bot */
/* di "\vrule height 1.1\baselineskip depth 0.7\baselineskip width0pt"  Duo */

	tempvar decoded
	local varc=1

	di "`sp1'"
	if "`spp1'"!="n" & "`spp2'"!="n" {
		di _col(5) in ye "\vrule height 1.1\baselineskip " /*
		*/	"depth 0.7\baselineskip width0pt&%" /*
		*/ _col(70) in gr "strut (AB)"
	}
	else if "`spp1'"!="n" & "`spp2'"=="n" {
		di _col(5) in ye "\vrule height 1.1\baselineskip " /*
		*/	"depth 0.3\baselineskip width0pt&%" /*
		*/ _col(70) in gr "strut (A)"
	}
	else if "`spp1'"=="n" & "`spp2'"!="n" {
		di _col(5) in ye "\vrule height 0.7\baselineskip " /*
		*/	"depth 0.7\baselineskip width0pt&%" /*
		*/ _col(70) in gr "strut (B)"
	}
	else if "`spp1'"=="n" & "`spp2'"=="n" {
		di _col(5) in ye "\vrule height 0.7\baselineskip " /*
		*/	"depth 0.3\baselineskip width0pt&%" /*
		*/ _col(70) in gr "strut"
	}

	while `varc'<=`nvars' {
		di _col(5) in ye "`vr`varc''&" in white "``varc''" in ye "&%"
		local lvar`varc': value label ``varc''
		if "`lvar`varc''" != "" {
			qui decode ``varc'', gen(`decoded')
			local lvar`varc' "`decoded'"
		}
		else local lvar`varc' ``varc''
		local varc=`varc'+1
	}
	di _col(5) "`vr`varc''\cr%"

	di "%"
	di "% " in gr "End of headers and beginning of table values "
	di "%"

	di "`sp2'"

	local obsc=1
	if "`spp2'"!="n" {
		di _col(5) "\vrule height 1.1\baselineskip " /*
		*/	"depth 0.3\baselineskip width0pt&%" /*
		*/      _col(70) in gr "strut (A)" 
	}
	else {
		di _col(5) "\vrule height 0.7\baselineskip " /*
		*/	"depth 0.3\baselineskip width0pt&%"  /*
		*/      _col(70) in gr "strut" 
	}
	local varc=1
	while `varc'<=`nvars' {
		capture conf string variable `lvar`varc'' 
		local val = `lvar`varc''[`obsc']
		if _rc == 0 { local comp = ("`val'" == "") }
		else        { local comp = (`val' == .)   }
		
		if `comp' == 0 {
			if "`fm`varc''" != "" {
				di _col(5) in ye "`vr`varc''&"/*     
				*/ in white `fm`varc'' `lvar`varc''[`obsc'] /*
				*/ in ye  "&%" _col(60) in gr "Column `varc'"
			}
			else {
				capture confirm string variable `lvar`varc''
				if _rc==0 {
				di _col(5) in ye "`vr`varc''&"          /*     
				*/ in white `lvar`varc''[`obsc'] /*
				*/ in ye "&%" _col(60) in gr "Column `varc'"
				}
				else {
				di _col(5) in ye "`vr`varc''&"          /*     
				*/ in white string(`lvar`varc''[`obsc']) /*
				*/ in ye "&%" _col(60) in gr "Column `varc'"
				}
			}
		}
		else {
			di _col(5)  "`vr`varc''&"              /*
			*/ "{`mis`varc''}&%"                    /*
			*/	_col(60) in gr "Column `varc'"
		}
		local varc=`varc'+1
	}
	di _col(5) "`vr`varc''\cr%" _col(60) in bl "Row `obsc'" 
	local obsc=`obsc'+1
	while `obsc'<=`nobs' {
		local varc=1

		if `use'[`obsc']!=0 {
			if `obsc'!=`bigob' {
			   di _col(5) in ye "\vrule height 0.7\baselineskip "/*
			   */	"depth 0.3\baselineskip width0pt&%" /*
			   */ _col(70) in gr "strut"
			}
			else {
			   if "`spp3'"!="n" {
				di _col(5) in ye /*
				*/ "\vrule height 0.7\baselineskip " /*
				*/ "depth 0.7\baselineskip width0pt&%" /*
				*/ _col(70) in gr "strut (B)" 
			   }
			   else {
				di _col(5) in ye /*
				*/ "\vrule height 0.7\baselineskip " /*
				*/ "depth 0.3\baselineskip width0pt&%" /*
				*/ _col(70) in gr "strut"
			   }
			}

			while `varc'<=`nvars' { 
			capture conf string variable `lvar`varc'' 
			local val = `lvar`varc''[`obsc']
			if _rc == 0 { 
				local comp = ("`val'" == "") 
			}
			else        { local comp = (`val' == .)   }
		
			if `comp' == 0 {
				if "`fm`varc''" != "" {
					di _col(5) in ye "`vr`varc''&"	/*     
				*/ in white `fm`varc'' `lvar`varc''[`obsc']/*
				*/ in ye "&%" _col(60) in gr "Column `varc'"
				}
				else {
					capture conf string var `lvar`varc''
					if _rc == 0 {
					di _col(5) in ye "`vr`varc''&"	/*     
				*/ in white `lvar`varc''[`obsc'] /*
				*/ in ye "&%" _col(60) in gr "Column `varc'"
					}
					else {
					di _col(5) in ye "`vr`varc''&"	/*     
				*/ in white string(`lvar`varc''[`obsc']) /*
				*/ in ye "&%" _col(60) in gr "Column `varc'"
					}
				}
			   }
			   else {
				di _col(5) in ye "`vr`varc''&"		/*
				*/ in white "{`mis`varc''}" in ye "&%"	/*
				*/ _col(60) in gr "Column `varc'"
			   }
			   local varc=`varc'+1
			}
			di _col(5) in ye "`vr`varc''\cr%" /* 
			*/ _col(60) in bl "Row `obsc'"
		}
		local obsc=`obsc'+1
	}

	di in ye "`sp3'"
	di in ye "}}%" _col(20) in gr "End of textab produced table"
	if "`center'"=="" {di in ye "$$"}
	di in ye "% " in gr"END OF TEXTAB TABLE"
	
	exit
                                       
end

program define align
	version 3.1
	local if      "opt"
	local in      "opt"
	#delimit ;
	local options "JUSTFY(string) FONT(string) BEGIN(string) 
			END(string) MODE(string) TABS(string) NVARS(int 0)";
	#delimit cr

	parse "`*'"

	local i=0
	local j=1
	parse "`tabs'", parse(",")
	while `i'<=`nvars' {
		if "``j''"=="" | "``j''"=="," {local T`i'=5}
		else                          {
			if `i'==0 {local T`i'=``j''}
			else      {local T`i'=``j''/2}
			local j = `j'+1
		}
		local i=`i'+1
		local j=`j'+1
	}
	* end of TABSKIPS                 T0 ... TN

	local i=1
	local j=1
	parse "`font'", parse(",")
	while `i'<=`nvars' {
		if "``i''"=="," {local F`i'=""}
		else            {
			local F`i'="``j''"
			local j=`j'+1
		}
		local i=`i'+1
		local j=`j'+1
	}
	* end of FONTS                    F1 ... FN

	local i=1
	parse "`begin'", parse(",")
	while `i'<=`nvars' {
		local ilen = length("``i''")
		if `ilen' == 1 {
			if "``i''"=="," { local B`i'=""     }
			else            { local B`i'="``i''"}
		}
		else                    { local B`i'="``i''" }
		local i=`i'+1
		local ilen = length("``i''")
		if `ilen' == 1 {
			if "``i''"=="," {mac shift}
		}
	}
	* end of BEGINS                   B1 ... BN

	local i=1
	parse "`end'", parse(",")
	while `i'<=`nvars' {
		local ilen = length("``i''")
		if `ilen' == 1 {
			if "``i''"=="," { local E`i'=""     }
			else            { local E`i'="``i''"}
		}
		else                    { local E`i'="``i''" }
		local i=`i'+1
		local ilen = length("``i''")
		if `ilen' == 1 {
			if "``i''"=="," {mac shift}
		}
	}
	* end of ENDS                     E1 ... EN

	local i=1
	parse "`justfy'", parse(" ,")
	di _col (3) "\tabskip=`T0'pt%" _col(70) in gr "Tab0"
	di "\halign{" _newline _col(3) in white "#" in ye "\tabskip=0pt&% " /* 
	*/ in bl "strut with width=0pt for vertical bars if they exist"
	while `i'<=`nvars' {
		di _col(3) in white "#" in ye "\tabskip=`T`i''pt&%"   /*
		*/ _col(70) in  gr "(Sep)"
		if "``i''"=="l" {
			di _col(3) "`B`i''{`F`i''{" in white "#" in ye  /* 
			*/ "}}`E`i''{\hfil}\tabskip=`T`i''pt&%"         /*
			*/ _col(70) in gr "(L) Var `i'"
		}
		else if "``i''"=="r"{
			di _col(3) "{\hfil}`B`i''{`F`i''{" in white "#"     /*
			*/ in ye "}}`E`i''\tabskip=`T`i''pt&%"              /*
			*/ _col(70) in gr "(R) Var `i'"
		}
		else {
			di _col(3) "{\hfil}`B`i''{`F`i''{" in white "#"     /*
			*/ in ye "}}`E`i''{\hfil}\tabskip=`T`i''pt&%"       /*
			*/ _col(70) in gr "(C) Var `i'"
		}
		local i=`i'+1
		if "``i''"=="," { mac shift }
	}
	di _col(3) in white "#" in ye "\tabskip=0pt\cr%" _col(70) in gr "(Sep)"
	di "%" 
	di "% " in gr "End of halign directive and beginning of column headers"
	di "%"
	
	exit
end
exit





		
	


