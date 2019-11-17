    *Chuntao LI
    *China Stata Club(爬虫俱乐部)
    *Wuhan, China
    *chtl@zuel.edu.cn

    *Zijian LI
    *China Stata Club(爬虫俱乐部)
    *Wuhan, China
    *jeremylee_41@163.com

    *Yuan XUE
    *China Stata Club(爬虫俱乐部)
    *Wuhan, China
    *xueyuan19920310@163.com




program define t2docx
	version 15.0 
	syntax varlist(numeric) [if] [in] using/, [append replace title(string) ///
	fmt(string) NOSTAr STAR STAR2(string asis) staraux noT ] by(varname)

	set more off
	
	if "`append'" != "" & "`replace'" != "" {    
		disp as error "you could not specify both append and replace"
		exit 198
	}
	 
	if ("`nostar'" != "") & ("`star'" != "" | "`star2'" != "" | "`staraux'" != "") {
		disp as error "you could not specify both nostar and star[()]|staraux"
		exit 198
	}
	
	if "`t'" != "" & "`staraux'" != "" {
		disp as error "you could not specify both not and staraux"
		exit 198
	}
	 
	putdocx begin
	putdocx paragraph, halign(left) spacing(after, 0)
	
	if `"`title'"' != "" {  
		putdocx text (`"`title'"') ,font("Times New Ronam",12)
	} 
	else {
		putdocx text ("t-test table") ,font("Times New Ronam",12)
	}
		 
	local num  `=wordcount("`varlist'")'
	local colnum = 7
	if "`t'" != "" local colnum = 6
	
	putdocx table ttbl = (`=`num'+2', `colnum'), border(all, nil) border(top) halign(center)

	forval i = 1(1)`colnum'{
		putdocx table ttbl(1, `i'), border(bottom) 
	}
	qui tabstat `varlist' `if' `in', s(N mean) by(`by') save
  
	putdocx table ttbl(1, 1) = ("varname"), font("Times New Ronam",10) halign(left) 
	putdocx table ttbl(1, 2) = ("obs(`r(name1)')"), font("Times New Ronam",10) halign(right) 
	putdocx table ttbl(1, 3) = ("mean(`r(name1)')"), font("Times New Ronam",10) halign(right)
	putdocx table ttbl(1, 4) = ("obs(`r(name2)')"), font("Times New Ronam",10) halign(right) 
	putdocx table ttbl(1, 5) = ("mean(`r(name2)')"), font("Times New Ronam",10) halign(right) 
	putdocx table ttbl(1, 6) = ("mean-diff"),  font("Times New Ronam",10) halign(right) 
	if "`t'" == "" putdocx table ttbl(1, 7) = ("t"),  font("Times New Ronam",10) halign(right)
		
	
	local row = 2
	foreach v of varlist `varlist'{
		putdocx table ttbl(`row', 1) = (`"`v'"'), font("Times New Ronam",10) halign(left) 
		local row = `row'+1
	}


	local row = 2	
	foreach v of varlist `varlist'{
		qui ttest `v', by(`by')
		

		if "`fmt'" == ""                      {  
			local fmt %9.3f   
		}
		else {
			local fmt "`fmt'"
		}
		
		local star_1 *
		local star_2 **
		local star_3 ***
		local siglevel1 0.1
		local siglevel2 0.05
		local siglevel3 0.01
		local levelnum = 3
			
		if `"`star2'"' != "" {
			if mod(`=wordcount(`"`star2'"')', 2) == 1 {
				disp as error "you specify the option star() incorrectly"
				exit 198
			}
			else {
				token `"`star2'"'
				local levelnum = wordcount(`"`star2'"')/2
				forvalue i = 1(1)`levelnum' {
					local star_`i' ``=`i'*2-1''
					local siglevel`i' ``=`i'*2''
				}
			}
		}
			
		local siglevel`=`levelnum'+1' = 0
			
		local staroutput = ""
		local bstar = ""
		forvalues i = 1/`levelnum' {
			if `r(p)' <= `siglevel`i'' & `r(p)' > `siglevel`=`i'+1'' {
				local staroutput `star_`i''
			}
		}
		
		if "`staraux'" == "" {
			local bstar `staroutput'
		}
		else {
			local tstar `staroutput'
		}
		if "`nostar'" != "" {
			local bstar = ""
			local tstar = ""
		}
		
		putdocx table ttbl(`row', 2) = (`"`=subinstr("`: disp `bfm' r(N_1)'", " ", "", .)'"'),  font("Times New Ronam",10) halign(right) 
		putdocx table ttbl(`row', 3) = (`"`=subinstr("`: disp `fmt' r(mu_1)'", " ", "", .)'"'),  font("Times New Ronam",10) halign(right) 
		putdocx table ttbl(`row', 4) = (`"`=subinstr("`: disp `bfm' r(N_2)'", " ", "", .)'"'),  font("Times New Ronam",10) halign(right)
		putdocx table ttbl(`row', 5) = (`"`=subinstr("`: disp `fmt' r(mu_2)'", " ", "", .)'"'),  font("Times New Ronam",10) halign(right) 
		putdocx table ttbl(`row', 6) = (`"`=subinstr("`: disp `fmt' r(mu_1)-r(mu_2)'", " ", "", .)'`bstar'"'), font("Times New Ronam",10) halign(right) 
		if "`t'" == "" putdocx table ttbl(`row', 7) = (`"`=subinstr("`: disp `fmt' r(t)'", " ", "", .)'`tstar'"'),  font("Times New Ronam",10) halign(right) 
		
		local row = `row'+1
	}

	putdocx table ttbl(`=`num'+2',1) = ("`star_1', `star_2' or `star_3' indicates a significance level at `=`siglevel1'*100'%, `=`siglevel2'*100'% and `=`siglevel3'*100'% respectively"), font("Times New Ronam",8) colspan(7) border(top)

	if "`replace'" == "" & "`append'" == "" {  
		putdocx save `using'
	}
	else {
		putdocx save `using', `replace'`append'
	}
end
