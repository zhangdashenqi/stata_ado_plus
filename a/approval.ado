* Authors:
* Mehmet F. Dicle, Loyola University New Orleans
* Betul Dicle, Louisiana State University
* January 2012

program define approval, rclass

	version 10.0
	
	syntax , president(numlist >31 integer) [save(string) timeseries]
	
	foreach pres in `president' {
		qui: {
			clear
			mata: presidential_approval(`pres')
			
			split myvar, gen(var) parse("</td>")
			drop myvar
			drop var1
			rename var2 start_date
			drop if start_date == ""
			rename var3 end_date
			drop var4
			rename var5 approving
			rename var6 disapproving
			rename var7 unsure
			compress
			drop if trim(approving)=="Approving" | trim(approving)=="%"

			generate startdate = date(trim(start_date), "MDY")
			format startdate %td
			generate enddate = date(trim(end_date), "MDY")
			format enddate %td
			drop start_date end_date

			replace approving=trim(approving)
			replace disapproving=trim(disapproving)
			replace unsure=trim(unsure)
			
			gen president=""
			replace president="Franklin D. Roosevelt" if `pres'==32
			replace president="Harry S. Truman" if `pres'==33
			replace president="Dwight D. Eisenhower" if `pres'==34
			replace president="John F. Kennedy" if `pres'==35
			replace president="Lyndon B. Johnson" if `pres'==36
			replace president="Richard Nixon" if `pres'==37
			replace president="Gerald R. Ford" if `pres'==38
			replace president="Jimmy Carter" if `pres'==39
			replace president="Ronald Reagan" if `pres'==40
			replace president="George Bush" if `pres'==41
			replace president="William J. Clinton" if `pres'==42
			replace president="George W. Bush" if `pres'==43
			replace president="Barack Obama" if `pres'==44

			gen president2=`pres'
			order president president2

			destring approving disapproving unsure, replace
			sort enddate
			save "temp_president_`pres'.dta", replace
		}
		if `pres'==32 di "Poll results for President Franklin D. Roosevelt is downloaded and parsed."
		if `pres'==33 di "Poll results for President Harry S. Truman is downloaded and parsed."
		if `pres'==34 di "Poll results for President Dwight D. Eisenhower is downloaded and parsed." 
		if `pres'==35 di "Poll results for President John F. Kennedy is downloaded and parsed." 
		if `pres'==36 di "Poll results for President Lyndon B. Johnson is downloaded and parsed." 
		if `pres'==37 di "Poll results for President Richard Nixon is downloaded and parsed." 
		if `pres'==38 di "Poll results for President Gerald R. Ford is downloaded and parsed." 
		if `pres'==39 di "Poll results for President Jimmy Carter is downloaded and parsed."
		if `pres'==40 di "Poll results for President Ronald Reagan is downloaded and parsed."
		if `pres'==41 di "Poll results for President George Bush is downloaded and parsed."
		if `pres'==42 di "Poll results for President William J. Clinton is downloaded and parsed."
		if `pres'==43 di "Poll results for President George W. Bush is downloaded and parsed."
		if `pres'==44 di "Poll results for President Barack Obama is downloaded and parsed."
	}

	local howmany :word count `president'
	
	if (`howmany'==1) {
		if ("`save'"!="") {
			erase "temp_president_`president'.dta"
			save "`save'", replace
		}
		if ("`save'"=="") {
			erase "temp_president_`president'.dta"
		}
	}
	
	if (`howmany'>1) {
		local first :word 1 of `president'
		foreach pres in `president' {
			if ("`first'"=="`pres'") use "temp_president_`pres'.dta", clear
			if ("`first'"!="`pres'") append using "temp_president_`pres'.dta"
			erase "temp_president_`pres'.dta"
		}
		if ("`save'"!="") save "`save'", replace
	}
	
	if ("`timeseries'"!="") {
		qui: {
			save _temp_0001.dta, replace

			use _temp_0001.dta, clear
			gen temp=_n
			drop enddate
			rename startdate date
			save _temp_0002.dta, replace
			
			use _temp_0001.dta, clear
			gen temp=_n
			drop startdate
			rename enddate date
			save _temp_0003.dta, replace
			
			use _temp_0002.dta, clear
			append using _temp_0003.dta
			erase _temp_0001.dta	
			erase _temp_0002.dta
			erase _temp_0003.dta
			sort temp date
			duplicates drop 
			xtset temp date
			tsfill
			foreach aa in president2 approving disapproving unsure {
				replace `aa'=`aa'[_n-1] if ((`aa'==.) & (temp==temp[_n-1]))
			}
			replace president=president[_n-1] if ((president=="") & (temp==temp[_n-1]))
			sort president date
			collapse president2 approving disapproving unsure, by(president date)
			sort president2 date
			xtset president2 date
			if ("`save'"!="") save "`save'", replace
		}
	}
end

mata:
	string strip_tags (string scalar raw)
	{
		tags = ("tr", "TR", "td", "TD", "strong", "STRONG", "/strong", "/STRONG", "span", "SPAN", "/span", "/SPAN", "img", "IMG", "/img", "/IMG", "br", "BR", "!-", "table", "TABLE", "/table", "/TABLE")
		for (j=1; j<=cols(tags); j++) {
			tag = tags[j]
			while (strpos(raw, "<" + tag)) {
				bas_pos = strpos(raw, "<" + tag)
				bas_txt = substr (raw, 1, bas_pos - 1)
				son_txt = substr (raw, bas_pos, .)
				bas_pos2 = strpos(son_txt, ">")
				son_txt = substr (son_txt, bas_pos2 + 1, .)
				raw = bas_txt + son_txt
			}
		}
		return (raw)
	}
	
	string remove_tags (string scalar raw, string scalar tag)
	{
		while (strpos(strlower(raw), "<" + tag)) {
			bas_pos = strpos(strlower(raw), "<" + tag)
			bas_txt = substr (raw, 1, bas_pos - 1)
			son_txt = substr (raw, bas_pos, .)
			bas_pos2 = strpos(strlower(son_txt), "</" + tag + ">") + 3 + strlen(tag)
			son_txt = substr (son_txt, bas_pos2 + 1, .)
			raw = bas_txt + son_txt
		}
		return (raw)
	}

	string remove_space (string scalar raw)
	{
		while (strpos(raw, "  ")) {
			raw = subinstr(raw, "  ", " ")
		}
		return (raw)
	}

	string file_get_contents (string scalar raw)
	{
		fh = fopen(raw, "r")
		raw=""
		while ((line=fget(fh))!=J(0,0,"")) {
			raw=raw+line
		}
		fclose(fh)
		return (raw)
	}

	void presidential_approval (real scalar USpres)
	{
		datam = file_get_contents ("http://www.presidency.ucsb.edu/data/popularity.php?pres=" + strofreal(USpres) + "&sort=time&direct=DESC&Submit=DISPLAY")

		tables = ""
		tag = "table"
		while (strpos(strlower(datam), "<" + tag)) {
			datam_kalan = datam
			starts = ""
			ends = ""
			onceki = 0
			while (strpos(strlower(datam_kalan), "<" + tag)) {
				yer = strpos(strlower(datam_kalan), "<" + tag)
				if (starts!="") {
					starts = (starts,(yer+onceki))
					ends = (ends,0)
				};;
				if (starts=="") {
					starts = (yer)
					ends = (0)
				};;
				datam_kalan = substr (datam_kalan, yer + 5, .)
				onceki = onceki + yer + 4
			}
			starts = (starts,strlen(datam))
			ends = (ends,0)
			
			for (i=1; i<cols(ends); i++) {
				temp = strpos(strlower(substr(datam, starts[i], starts[i+1]-starts[i])), "</" + tag)
				if (temp==0) ends[i] = 0;;
				if (temp!=0) ends[i] = starts[i] - 1 + temp + 3 + strlen(tag)
			}
			
			for (i=1; i<cols(ends); i++) {
				if (ends[i]>0) {
					temp = substr(datam, starts[i], ends[i]-starts[i])
					if (tables!="") tables = (tables\(strofreal(starts[i]),temp));;
					if (tables=="") tables = (strofreal(starts[i]),temp);;
					datam = subinstr(datam, temp, (strlen(temp)*char(32)))
				}
			}
		}

		for (i=1; i<=rows(tables); i++) {
			tables[i,2]=remove_tags(tables[i,2], "object")
			tables[i,2] = strip_tags(tables[i,2])
			tables[i,2] = remove_space(tables[i,2])
			if (strpos(strlower(tables[i,2]), "president</td>")) datam = tables[i,2];;
		}

		datam = subinstr(datam, char(13), "")
		datam = subinstr(datam, "</tr>", char(13))
		datam = subinstr(datam, "</TR>", char(13))
		datam = subinstr(datam, char(9), "")

		datam = subinstr(datam, "&nbsp;", char(32))
		datam = subinstr(datam, "&amp;", char(38))
		
		satir = tokens(datam, char(13))
		sutun=satir'
		
		st_addvar("str244", "myvar")
		st_addobs(rows(sutun))
		st_sstore(.,"myvar",sutun)
	}
end



