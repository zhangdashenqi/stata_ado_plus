* Version 2.0 - 31/03/2016

* Summary of changes from v1.0:
* Vartypes binary2, categorical2, contrange and events added
* Missing data summary added to Excel output
* Fixed bug: Changed generated variables temp1 and temp2 in contmed and contrange vartypes to temp1__ and temp2__ in case temp1 or temp2 already exist in the dataset

program sumtable
	syntax varlist(min=1 max=2) , vartype(name) [vartext(string) dp1(real 0) dp2(real 1) first(real 0) last(real 0) exportname(string) ]

quietly {
	
	*save current dataset to be read back in at the end of each run
	capture rename temp temp1234
	
	preserve
	
	save "currentds1234", replace
	
	*set up empty dataset with no rows
	if `first'==1 {
		clear
		set obs 0
		foreach x in label level levellab {
			gen `x'=9999
		}	
		*set rows to be correctly floats or strings
		tostring label levellab , replace
		save "dummy1234", replace
		use "currentds1234", clear
	}	
	
	*header row
	if `"`vartype'"'=="headerrow" {
		gen label="`vartext'"
		keep if _n==1
		keep label 
		*appending dataset to dummy dataset	and replacing
		append using "dummy1234"
		save "dummy1234", replace
	}
	
	else {
	
	* generating new variable for group variable
	gen treat1234=`2'
	
	*dropping out entries with missing group variable
		drop if treat1234==.
		
		*sorting out string and numeric categorical variables	
		quietly sum `1'
		global catstring=r(min)
		if $catstring==. & (`"`vartype'"'=="categorical" | `"`vartype'"'=="categorical2") {
			encode `1', gen(`1'2)
			rename `1' `1'_str
			rename `1'2 `1'
		}
		if $catstring!=. & (`"`vartype'"'=="categorical" | `"`vartype'"'=="categorical2") {
			capture decode `1', gen(`1'_str)
			capture tostring `1', gen(`1'_str)
		}	
	
		*generating variable and descriptive text 
		gen label="`vartext'"
		local templabel: variable label `1'
		replace label="`templabel'" if label==""
		local drop templabel
		replace label="`1'" if label==""
		gen level=.
		
		*generating count of missing values in each treatment group and overall
		gen temp=1 if `1'==.
		bysort treat1234: egen double miss_grp=total(temp)
		egen double miss_all=total(temp)
		drop temp
	
		**if variable is binary:
		if (`"`vartype'"' == "binary" | `"`vartype'"' == "binary2") { 
			gen levellab=""	
			*generating overall count variable by treatment and overall
			gen temp=1 if `1'!=.
			bysort treat1234: egen double tot_grp=total(temp) 
			egen double tot_all=total(temp)
			drop temp
			*generating first variable to identify one patient for each treatment group
			bysort treat1234: gen first=1 if _n==1
			*generating n and % variables for each treatment group and overall
			bysort treat1234: egen double stat1_grp=total(`1')
			bysort treat1234: egen double stat2_grp=mean(100*`1')
			egen double stat1_all=total(`1')
			egen double stat2_all=mean(100*`1')
		}
	
		**if variable is continuous and normally distributed
		else if `"`vartype'"' == "contmean" {
			gen levellab=""	
			gen tot_grp=.
			gen tot_all=.
			*generating first variable to identify one patient for each treatment
			bysort treat1234: gen first=1 if _n==1
			*generating mean and SD variables for each treatment and overall
			bysort treat1234: egen double stat1_grp=mean(`1')
			bysort treat1234: egen double stat2_grp=sd(`1')
			egen double stat1_all=mean(`1')
			egen double stat2_all=sd(`1')
		}
	
		**if variable is continuous and not normally distributed
		else if `"`vartype'"' == "contmed" {
			gen levellab=""	
			gen tot_grp=.
			gen tot_all=.
			*generating first variable to identify a patient for each treatment
			bysort treat1234: gen first=1 if _n==1
			*generating median and IQR variables for each treatment and overall
			bysort treat1234: egen double stat1_grp=median(`1')
			bysort treat1234: egen temp1__=pctile(`1'), p(25) 
			bysort treat1234: egen temp2__=pctile(`1'), p(75) 
			tostring stat1_grp, format(%12.`dp1'f) replace force
			tostring temp1__ temp2__, format(%12.`dp2'f) replace force
			bysort treat1234: gen stat2_grp="(" + temp1__ + ", " + temp2__ + ")"
			drop temp1__ temp2__
			egen double stat1_all=median(`1')
			egen temp1__=pctile(`1'), p(25) 
			egen temp2__=pctile(`1'), p(75) 
			tostring stat1_all, format(%12.`dp1'f) replace force
			tostring temp1__ temp2__, format(%12.`dp2'f) replace force
			gen stat2_all="(" + temp1__ + ", " + temp2__ + ")"
			drop temp1__ temp2__
		}

		
		**if variable is continuous and not normally distributed and range is required
		else if `"`vartype'"' == "contrange" {
			gen levellab=""	
			gen tot_grp=.
			gen tot_all=.
			*generating first variable to identify a patient for each treatment
			bysort treat1234: gen first=1 if _n==1
			*generating median and IQR variables for each treatment and overall
			bysort treat1234: egen double stat1_grp=median(`1')
			bysort treat1234: egen temp1__=min(`1')
			bysort treat1234: egen temp2__=max(`1')
			tostring stat1_grp, format(%12.`dp1'f) replace force
			tostring temp1__ temp2__, format(%12.`dp2'f) replace force
			bysort treat1234: gen stat2_grp="(" + temp1__ + ", " + temp2__ + ")"
			drop temp1__ temp2__
			egen double stat1_all=median(`1')
			egen temp1__=min(`1')
			egen temp2__=max(`1')
			tostring stat1_all, format(%12.`dp1'f) replace force
			tostring temp1__ temp2__, format(%12.`dp2'f) replace force
			gen stat2_all="(" + temp1__ + ", " + temp2__ + ")"
			drop temp1__ temp2__
		}
		
		
		**if variable is categorical
		else if (`"`vartype'"' == "categorical" | `"`vartype'"' == "categorical2") {
			gen levellab=`1'_str
			replace level=`1'
			*generating overall count variable	
			gen temp=1 if `1'!=.
			bysort treat1234: egen double tot_grp=total(temp) 
			egen double tot_all=total(temp)
			*generating first variable to identify a patient in each category/level for each treatment
			bysort treat1234 `1': gen first=1 if _n==1 & `1'!=.
			*generating n and % variables for each treatment and overall for each level
			bysort treat1234 `1': egen double stat1_grp=total(temp)
			bysort treat1234 `1': gen stat2_grp=(stat1_grp*100)/tot_grp
			bysort `1': egen double stat1_all=total(temp) 
			gen stat2_all=(stat1_all*100)/tot_all
			drop temp
		}	
	
		**if variable is number of events, one row per patient
		else if `"`vartype'"' == "events" { 
			gen levellab=""	
			*generating overall count variable by treatment and overall
			gen temp=1 if `1'!=. & `1'!=0
			replace temp=0 if `1'==0
			bysort treat1234: egen double tot_grp=total(temp) 
			egen double tot_all=total(temp)
			*generating first variable to identify one patient for each treatment group
			bysort treat1234: gen first=1 if _n==1
			*generating n and % variables for each treatment group and overall
			bysort treat1234: egen double stat1_grp=total(`1')
			bysort treat1234: egen double stat2_grp=mean(100*temp)
			egen double stat1_all=total(`1')
			egen double stat2_all=mean(100*temp)
			drop temp
		}
		
		
		*only keeping relevant variables
		keep if first==1
		keep label level levellab stat1_grp stat2_grp ///
			stat1_all stat2_all miss_grp miss_all tot_grp tot_all treat1234
		*converting numeric variables to strings
		tostring tot* miss*, format(%12.0f) replace force
		tostring stat1*, format(%12.`dp1'f) replace force
		tostring stat2*, format(%12.`dp2'f) replace force

		**if variable is binary
		if `"`vartype'"' == "binary" { 
			*adding totals to counts 
			foreach x in grp all {
				replace stat1_`x'=stat1_`x' + "/" + tot_`x'
			}
			*adding percent sign to percent variables
			foreach x in stat2_grp stat2_all {
				replace `x'=`x' + "%"
			}
			*setting zero values to blank
			replace stat1_grp="" if stat1_grp=="0/0"	
			replace stat2_grp="" if stat2_grp==".%"
			*reshaping to make dataset just one row	
			gen temp=1
			reshape wide stat1_grp stat2_grp miss_grp tot_grp, i(temp) j(treat1234)
			drop temp
		}
	
		**if variable is binary (and no denominators required)
		if `"`vartype'"' == "binary2" { 
			*adding percent sign to percent variables
			foreach x in stat2_grp stat2_all {
				replace `x'=`x' + "%"
			}
			*setting zero values to blank
			replace stat1_grp="" if stat1_grp=="0"	
			replace stat2_grp="" if stat2_grp==".%"
			*reshaping to make dataset just one row	
			gen temp=1
			reshape wide stat1_grp stat2_grp miss_grp tot_grp, i(temp) j(treat1234)
			drop temp
		}
		
		
		**if variable is continuous and normally distributed
		else if `"`vartype'"' == "contmean" {
			*setting zero values to blank
			replace stat1_grp="" if stat1_grp=="."
			replace stat2_grp="" if stat2_grp=="."
			*reshaping to make dataset just one row	
			gen temp=1
			reshape wide stat1_grp stat2_grp miss_grp, i(temp) j(treat1234)	
			drop temp
		}
	
		**if variable is continuous and not normally distributed
		else if `"`vartype'"' == "contmed" {
			*setting zero values to blank
			replace stat1_grp="" if stat1_grp=="."
			replace stat2_grp="" if stat2_grp=="(., .)"
			*reshaping to make dataset just one row	
			gen temp=1
			reshape wide stat1_grp stat2_grp miss_grp, i(temp) j(treat1234)
			drop temp
		}

		**if variable is continuous and not normally distributed and range is required
		else if `"`vartype'"' == "contrange" {
			*setting zero values to blank
			replace stat1_grp="" if stat1_grp=="."
			replace stat2_grp="" if stat2_grp=="(., .)"
			*reshaping to make dataset just one row	
			gen temp=1
			reshape wide stat1_grp stat2_grp miss_grp, i(temp) j(treat1234)
			drop temp
		}
		
		**if variable is categorical
		else if `"`vartype'"' == "categorical" {
			*adding percent sign to percent variables
			foreach x in stat2_grp stat2_all {
				replace `x'=`x' + "%"
			}
			*adding totals to counts 
			foreach x in grp all {
				replace stat1_`x'=stat1_`x' + "/" + tot_`x'
			}
			*reshaping to make dataset just one row	per category/level
			gen temp=10000 + level
			reshape wide stat1_grp stat2_grp tot_grp miss_grp, i(temp) j(treat1234)
			drop temp
			*replacing empty variables	
			forvalues x=0(1)1000 {
				capture gsort -tot_grp`x'
				capture replace miss_grp`x'=miss_grp`x'[_n-1] if miss_grp`x'==""
				capture replace tot_grp`x'=tot_grp`x'[_n-1] if tot_grp`x'==""
				capture replace stat1_grp`x'="0/" + tot_grp`x' if stat1_grp`x'==""
				capture gen temp=1 if stat2_grp`x'==""
				capture replace stat2_grp`x'="0" if temp==1
				capture replace stat2_grp`x'=stat2_grp`x'+"." if temp==1 & `dp2'>=1
				capture forvalues i=1(1)`dp2' {
					replace stat2_grp`x'=stat2_grp`x'+"0" if temp==1
				}
				capture replace stat2_grp`x'=stat2_grp`x'+"%" if temp==1
				capture drop temp
			}
		sort level
		}	
		
		
		**if variable is categorical (and no denominators required)
		else if `"`vartype'"' == "categorical2" {
			*adding percent sign to percent variables
			foreach x in stat2_grp stat2_all {
				replace `x'=`x' + "%"
			}
			*reshaping to make dataset just one row	per category/level
			gen temp=10000 + level
			reshape wide stat1_grp stat2_grp tot_grp miss_grp, i(temp) j(treat1234)
			drop temp
			*replacing empty variables	
			forvalues x=0(1)1000 {
				capture gsort -tot_grp`x'
				capture replace miss_grp`x'=miss_grp`x'[_n-1] if miss_grp`x'==""
				capture replace tot_grp`x'=tot_grp`x'[_n-1] if tot_grp`x'==""
				capture replace stat1_grp`x'="0" if stat1_grp`x'==""
				capture gen temp=1 if stat2_grp`x'==""
				capture replace stat2_grp`x'="0" if temp==1
				capture replace stat2_grp`x'=stat2_grp`x'+"." if temp==1 & `dp2'>=1
				capture forvalues i=1(1)`dp2' {
					replace stat2_grp`x'=stat2_grp`x'+"0" if temp==1
				}
				capture replace stat2_grp`x'=stat2_grp`x'+"%" if temp==1
				capture drop temp
			}
		sort level
		}	
		
		
		**if variable is number of events, one row per patient
		else if `"`vartype'"' == "events" { 
			*adding totals to counts 
			foreach x in grp all {
				replace stat1_`x'=stat1_`x' + "/" + tot_`x'
			}
			*adding percent sign to percent variables
			foreach x in stat2_grp stat2_all {
				replace `x'=`x' + "%"
			}
			*setting zero values to blank
			replace stat1_grp="" if stat2_grp==".%"	
			replace stat2_grp="" if stat2_grp==".%"
			*reshaping to make dataset just one row	
			gen temp=1
			reshape wide stat1_grp stat2_grp miss_grp tot_grp, i(temp) j(treat1234)
			drop temp
		}	
		
		
		*dropping total counts
		drop tot_*
		*ordering
		order label level levellab
		order miss_grp* miss_all, last

		*appending dataset to dummy dataset, saving and replacing
		append using "dummy1234"
		save "dummy1234", replace	

	}

	**generating excel output table of all results in excel
	*ordering
	if `last'==1 {
		gen varnum=_n if label[_n]!=label[_n-1]
		replace varnum=varnum[_n-1] if varnum==.
		gen varnum2=-varnum
		sort varnum2 level
		bysort varnum2 label: replace label="" if _n!=1
		drop varnum varnum2 level
		quietly count if levellab!=""
		if `r(N)'==0 drop levellab
	
		*generating missing count footnote
		gen rowcount=_n
		tostring rowcount, gen(rowcount2)
		save "prefootnote1234", replace

		gen header=1 if stat1_all=="" & stat2_all==""
		gen nomiss=1 if miss_all=="0"
		gen binary=1 if strpos(stat1_all, "/")
		gen repeatcat=1 if label==""
		keep rowcount rowcount2 miss_grp* miss_all header nomiss binary repeatcat

		
		gen missing= rowcount2 + "*Data missing for " + miss_all + " patients " + "("
		forvalues x=0(1)1000 {
			capture replace missing = missing + miss_grp`x'+ ", "
		}
			
		replace missing = missing + ")"
		replace missing=subinstr(missing,", )","). ", .)
	
		drop if header==1 | binary==1 | nomiss==1 | repeatcat==1
		keep rowcount missing
	
		gen temp3=1
		capture reshape wide missing, i(temp3) j(rowcount)
		capture egen rowcount=concat(missing*)
		capture keep rowcount
		capture tostring rowcount, replace
		save "missingrow1234", replace
	
		use "prefootnote1234", clear
		drop rowcount
		rename rowcount2 rowcount
		append using "missingrow1234"

		*exporting to Excel
		if "`exportname'" != "" {
				export excel using "`exportname'.xls", replace firstrow(variables)
				}
				else {
				export excel using "summarydatasetexcel.xls", replace firstrow(variables)
				}
			
		erase "dummy1234.dta"
		erase "missingrow1234.dta"
		erase "prefootnote1234.dta"
	}

	restore
	
	capture rename temp1234 temp
	erase "currentds1234.dta"	

}

end
	
	
