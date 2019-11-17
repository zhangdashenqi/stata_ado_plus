program define corr2docx
	version 15.0
	 
	syntax varlist(numeric min=2) [if] [in] using/, [append replace title(string) fmt(string) STAR STAR2(string asis) note(string) ADDONE]
     
	if "`append'" != "" & "`replace'" != "" {
		disp as error "you could not specify both append and replace"
		exit 198
	}
	 if mod(`=wordcount(`"`star2'"')', 2) == 1 {
		disp as error "you specify the option star() incorrectly"
		exit 198
	}
	putdocx begin,pagesize(A4) landscape
	putdocx paragraph, halign(center) spacing(after, 0)
    if `"`title'"' != "" {
		putdocx text (`"`title'"'),bold font(Arial,18,black)
	} 
	else	{
		putdocx text ("Correlation Coefficient"),bold font(Arial,18,black)
    }
	local num  `=wordcount("`varlist'")+1'
	putdocx table abc = (`num',`num'),border(all, nil) border(top) halign(center) layout(autofitw)
	local i = 2
    local j = 2
    foreach var of varlist `varlist'  { 
		putdocx table abc(`i',`=`j'-1') = ("`var'"),font(Arial,10,black) halign(left) valign(center)
		local i = `i'+1
    }
    local i = 2
    foreach var of varlist `varlist'  { 
		putdocx table abc(`=`i'-1',`j') = ("`var'"),font(Arial,10,black) halign(center) valign(center)
		local j = `j'+1
    }
	if `"`note'"' != ""	{
		putdocx table abc(`num',.),addrows(2,after)
		putdocx table abc(`=`num'+1',1) = (`"`note'"'),font(Arial,10,black) colspan(`=`num'+1') border(top)
		putdocx table abc(`=`num'+2',1) = ("Lower-triangular cells report Pearson's correlation coefficients, upper-triangular cells are Spearman’s rank correlation"),font(Arial,10,black) colspan(`num')
		local nnum `=`num'+2'
	}
	else	{
		putdocx table abc(`num',.),addrows(1,after)
		putdocx table abc(`=`num'+1',1) = ("Lower-triangular cells report Pearson's correlation coefficients, upper-triangular cells are Spearman’s rank correlation"),font(Arial,10,black) colspan(`num') border(top)
		local nnum `=`num'+1'
	}
	if `"`star'"' != ""	{
		putdocx table abc(`nnum',.),addrows(1,after)
		putdocx table abc(`=`nnum'+1',1) = ("*** p<0.01, ** p<0.05, * p<0.1"),font(Arial,10,black) colspan(`num')
	}
	if `"`star2'"' != ""	{
		putdocx table abc(`nnum',.),addrows(1,after)
		if ustrregexm("`star2'","^\*") == 1	{
			local stars = ustrregexra("`star2'","([\*]+)\s*?([\d\.]+)","$1 p<$2")
			local stars = ustrregexra("`stars'","([\d\.]+)\s*?([\*]+)","$1, $2")
			putdocx table abc(`=`nnum'+1',1) = ("`stars'"),font(Arial,10,black) colspan(`num')
		}
		else if ustrregexm("`star2'","^\*") == 0	{
			dis as error "you specify the option star() incorrectly"
			exit 198
		}
	}
	*Pearson
	token `varlist'
	local varnum = wordcount("`varlist'")
	forvalue colvar = 1(1)`varnum'	{
		forvalue rowvar = `=`colvar'+1'(1)`varnum'	{
			qui reg ``colvar'' ``rowvar'' `if' `in'
			local corr = sqrt(e(r2)) * (-1)^(_b[``rowvar'']<0)
			local p = Ftail(e(df_m), e(df_r), e(F))
			if "`fmt'" == ""	{
				local fmt %04.3f
			}
			else	{
				local fmt "`fmt'"
			}
			if "`star'" != ""	{
				if `p' > 0.1  & `p' < 1     {
					local star1 = ""    
				}	
				if `p' > 0.05 & `p' <= 0.1  {
					local star1 = "*"   
				}
				if `p' > 0.01 & `p' <= 0.05 {
					local star1 = "**"  
				}
				if `p' >= 0    & `p' <= 0.01 {
					local star1 = "***"
				}
				local corr : disp `fmt' `corr'
				local corr = "`corr'" + "`star1'"
			}
			if `"`star2'"' != "" {
				token `"`star2'"'
				local levelnum = wordcount(`"`star2'"')/2
				forvalue i = 1(1)`levelnum'	{
					local star_`i' ``=`i'*2-1''
					local siglevel`i' ``=`i'*2''
				}
				local siglevel0 = 0
				local corr : disp `fmt' `corr'
				if "`levelnum'" == "1"	{
					if `p' <= real("`siglevel1'") & `p' >= real("`siglevel0'")	{
						local corr = "`corr'" + "`star_1'"
					}
					if `p' >= real("`siglevel1'")	{
						local corr = "`corr'"
					}
				}
				if "`levelnum'" == "2"	{
					if real("`siglevel1'") > real("`siglevel2'")	{
						dis as error "you specify the option star() incorrectly"
						exit 198
					}
					if `p' <= real("`siglevel1'") & `p' >= real("`siglevel0'")	{
						local corr = "`corr'" + "`star_1'"
					}
					if `p' <= real("`siglevel2'") & `p' > real("`siglevel1'")	{
						local corr = "`corr'" + "`star_2'"
					}
					if `p' >  real("`siglevel2'")	{
						local corr = "`corr'"
					}
				}
				if "`levelnum'" == "3"	{
					if real("`siglevel1'") > real("`siglevel2'")	{
						dis as error "you specify the option star() incorrectly"
						exit 198
					}
					if real("`siglevel2'") > real("`siglevel3'")	{
						dis as error "you specify the option star() incorrectly"
						exit 198
					}
					if `p' <= real("`siglevel1'") & `p' >= real("`siglevel0'")	{
						local corr = "`corr'" + "`star_1'"
					}
					if `p' <= real("`siglevel2'") & `p' > real("`siglevel1'")	{
						local corr = "`corr'" + "`star_2'"
					}
					if `p' <= real("`siglevel3'") & `p' > real("`siglevel2'")	{
						local corr = "`corr'" + "`star_3'"
					}
					if `p' >  real("`siglevel3'")	{
						local corr = "`corr'"
					}
				}
			}
			if	"`star'" == "" & `"`star2'"' == ""	{
				local corr : disp `fmt' `corr'
			}
			putdocx table abc(`=`rowvar'+1',`=`colvar'+1') = ("`corr'"),font(Arial,10,black) halign(center) valign(center)
			token `varlist'
		}
	}
	*Spearman
	token `varlist'
	local varnum = wordcount("`varlist'")
	qui spearman `varlist' `if' `in'
	forvalue rowvar = 1(1)`varnum'	{
		forvalue colvar = `=`rowvar'+1'(1)`varnum'	{
			if `varnum' == 2	{
				local p = r(p)
				local corr = r(rho)
			}
			else	{
				mat P = r(P)
				mat CORR = r(Rho)
				local p = scalar(P[`rowvar',`colvar'])
				local corr = scalar(CORR[`rowvar',`colvar'])
			}
			if "`fmt'" == ""	{
				local fmt %04.3f
			}
			else	{
				local fmt "`fmt'"
			}
			if "`star'" != ""	{
				if `p' > 0.1  & `p' < 1     {
					local star1 = ""    
				}	
				if `p' > 0.05 & `p' <= 0.1  {
					local star1 = "*"   
				}
				if `p' > 0.01 & `p' <= 0.05 {
					local star1 = "**"  
				}
				if `p' >= 0    & `p' <= 0.01 {
					local star1 = "***"
				}
				local corr : disp `fmt' `corr'
				local corr = "`corr'" + "`star1'"
			}
			if `"`star2'"' != "" {
				token `"`star2'"'
				local levelnum = wordcount(`"`star2'"')/2
				forvalue i = 1(1)`levelnum'	{
					local star_`i' ``=`i'*2-1''
					local siglevel`i' ``=`i'*2''
				}
				local siglevel0 = 0
				local corr : disp `fmt' `corr'
				if "`levelnum'" == "1"	{
					if `p' <= real("`siglevel1'") & `p' >= real("`siglevel0'")	{
						local corr = "`corr'" + "`star_1'"
					}
					if `p' >= real("`siglevel1'")	{
						local corr = "`corr'"
					}
				}
				if "`levelnum'" == "2"	{
					if real("`siglevel1'") > real("`siglevel2'")	{
						dis as error "you specify the option star() incorrectly"
						exit 198
					}
					if `p' <= real("`siglevel1'") & `p' >= real("`siglevel0'")	{
						local corr = "`corr'" + "`star_1'"
					}
					if `p' <= real("`siglevel2'") & `p' > real("`siglevel1'")	{
						local corr = "`corr'" + "`star_2'"
					}
					if `p' >  real("`siglevel2'")	{
						local corr = "`corr'"
					}
				}
				if "`levelnum'" == "3"	{
					if real("`siglevel1'") > real("`siglevel2'")	{
						dis as error "you specify the option star() incorrectly"
						exit 198
					}
					if real("`siglevel2'") > real("`siglevel3'")	{
						dis as error "you specify the option star() incorrectly"
						exit 198
					}
					if `p' <= real("`siglevel1'") & `p' >= real("`siglevel0'")	{
						local corr = "`corr'" + "`star_1'"
					}
					if `p' <= real("`siglevel2'") & `p' > real("`siglevel1'")	{
						local corr = "`corr'" + "`star_2'"
					}
					if `p' <= real("`siglevel3'") & `p' > real("`siglevel2'")	{
						local corr = "`corr'" + "`star_3'"
					}
					if `p' >  real("`siglevel3'")	{
						local corr = "`corr'"
					}
				}
			}
			if	"`star'" == "" & `"`star2'"' == ""	{
				local corr : disp `fmt' `corr'
			}
			putdocx table abc(`=`rowvar'+1',`=`colvar'+1') = ("`corr'"),font(Arial,10,black) halign(center) valign(center)
		}
	}
	if "`addone'" == "" { 
		forvalue i = 2(1)`=`varnum'+1'	{
			putdocx table abc(`i',`i') = (""),font(Arial,10,black) halign(center) valign(center)	
		}
	}
	else	{
		forvalue i = 2(1)`=`varnum'+1'	{
			putdocx table abc(`i',`i') = ("1"),font(Arial,10,black) halign(center) valign(center)		
		}
	}
	if "`replace'" == "" & "`append'" == "" {
		putdocx save `using'
	}
	else                                   {
		putdocx save `using', `replace'`append'
	}
end
