*! Author: Mehmet F. Dicle, mfdicle@gmail.com
*! version 1.0
*! January 19, 2011
*! Update: September 4, 2012
*! Update: August 30, 2013
*! Update: May 6, 2016
*! Update: July 24, 2016



program define fetchyahooquotes, rclass
	
	version 10.0
	
	syntax anything(name=tickers), freq(string) [field(string) chg(namelist) start(string) end(string) ff3 merge]
	* freq: frequency of the data: (d)daily, (w)weekly, (m)monthly, (v)dividends only
	* field: variables to download: (o) open, (h) high, (l) low, (c) close, (v) volume
	* chg: change to calculate (l) log (ln)log difference (ln(a/L.a)), (ln2) log difference (ln(a) - ln(L.a)), (per)percentage difference, (sper)symmetric percentage

	local downloaded=""
	local not_downloaded=""
	
	if (("`freq'"=="d") | ("`freq'"=="w") | ("`freq'"=="m") | ("`freq'"=="v")) {
		
		* if we are merging the fetched quotes with the data already in use
		* then save the data already in use
		qui: ds
		if ("`merge'"!="") & ("`r(varlist)'"!="") qui: save _temp_0001.dta, replace
		
		clear 
				
		* Download Fama-French factors from Kenneth French web site
		if (("`freq'"=="d") & ("`ff3'"!="")) {
			qui: {
				copy "http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_daily_TXT.zip" F-F_Research_Data_Factors_daily.zip, replace
				unzipfile F-F_Research_Data_Factors_daily.zip
				erase F-F_Research_Data_Factors_daily.zip
				insheet using F-F_Research_Data_Factors_daily.txt, clear
				erase F-F_Research_Data_Factors_daily.txt
				drop if _n<5
				drop if _n==_N
				split  v1, gen(var)
				destring var2-var5, replace
				gen date=date(var1,"YMD")
				format date %td
				drop v1 var1
				rename var2 ff3_Mkt_RF
				rename var3 ff3_SMB
				rename var4 ff3_HML
				rename var5 ff3_RF
				
				replace ff3_Mkt_RF=ff3_Mkt_RF/100
				replace ff3_SMB=ff3_SMB/100
				replace ff3_HML=ff3_HML/100
				replace ff3_RF=ff3_RF/100
				
				if ("`start'"!="") drop if date<(date("`start'", "DMY"))
				if ("`end'"!="") drop if date>(date("`end'", "DMY"))
				
				sort date
				save "F-F_Research_Data_Factors_daily.dta", replace
			}
			di "Fama/French daily factors are downloaded from 'Kenneth R. French - Data Library'."
		}
				
		* If there is no company to download or none of the tickers entered could not be downloaded then, do nothing...
		* We use a control variable for this purpose
		local symbol_downloaded=0
	
		foreach name in `tickers' {
			* Some symbols contain special characters (ex. .,-,^). These need to be kept the same for downloading the data from Yahoo! Finance
			* However, special characters need to be replaced to be used as Stata variables. 
			local name2 :subinstr local name "." "_", all
			local name2 :subinstr local name2 "^" "_", all
			local name2 :subinstr local name2 "-" "_", all
			
			* for fetching the data from Yahoo! Finace, the symbol is used as it is, with special characters intact
			if ("`start'"=="") & ("`end'"=="") {
				quietly: capture: insheet using "http://ichart.finance.yahoo.com/table.csv?s=`name'&g=`freq'&ignore=.csv", comma clear
			}
			if ("`start'"!="") & ("`end'"=="") {
				local aaa= month(date("`start'", "DMY")) -1
				local bbb= day(date("`start'", "DMY")) 
				local ccc= year(date("`start'", "DMY"))
				quietly: capture: insheet using "http://ichart.finance.yahoo.com/table.csv?s=`name'&g=`freq'&a=`aaa'&b=`bbb'&c=`ccc'&ignore=.csv", comma clear
			}
			if ("`start'"!="") & ("`end'"!="") {
				local aaa= month(date("`start'", "DMY")) -1
				local bbb= day(date("`start'", "DMY")) 
				local ccc= year(date("`start'", "DMY"))
				local ddd= month(date("`end'", "DMY")) -1
				local eee= day(date("`end'", "DMY")) 
				local fff= year(date("`end'", "DMY"))
				quietly: capture: insheet using "http://ichart.finance.yahoo.com/table.csv?s=`name'&g=`freq'&a=`aaa'&b=`bbb'&c=`ccc'&d=`ddd'&e=`eee'&f=`fff'&ignore=.csv", comma clear
			}
			if ("`start'"=="") & ("`end'"!="") {
				local ddd= month(date("`end'", "DMY")) -1
				local eee= day(date("`end'", "DMY")) 
				local fff= year(date("`end'", "DMY"))
				quietly: capture: insheet using "http://ichart.finance.yahoo.com/table.csv?s=`name'&g=`freq'&d=`ddd'&e=`eee'&f=`fff'&ignore=.csv", comma clear
			}
			
			* Is there at least 5 observations: if not, let the user know
			if ((_rc!=0) | (_N<5)) {
				di "`name' does not have sufficient number of observations."
				clear
				if ("`not_downloaded'"!="") {
					local not_downloaded="`not_downloaded' `name'"
				}
				else {
					if ("`not_downloaded'"=="") local not_downloaded="`name'"
				}
			}
			
			* Is there at least 5 observations: if so, let the user know
			if ((_rc==0) & (_N>5)) {
				di "`name' is downloaded."
				if ("`downloaded'"!="") {
					local downloaded="`downloaded' `name'"
				}
				else {
					if ("`downloaded'"=="") local downloaded="`name'"
				}
			}
			
			* If there is at least 5 observations: continue running
			quietly: if ((_rc==0) & (_N>5)) {
				* since individually downloaded symbol files will be merged
				* each variable is renamed to make them unique to a symbol
				if ("`freq'"=="v") rename dividends dividends_`name2'
				if ("`freq'"!="v") {
					rename adjclose adjclose_`name2'
					rename open open_`name2'
					rename close close_`name2'
					rename high high_`name2'
					rename low low_`name2'
					rename volume volume_`name2'
				}
				gen double date_=date(date,"YMD")
				format date_ %td
				drop date
				rename date_ date
				order date
				sort date
				
				* Keep only the requested variables within the field
				local tokeep=""
				foreach fld in `field' {
					if "`fld'"=="o" local tokeep="`tokeep' open_`name2'"
					if "`fld'"=="h" local tokeep="`tokeep' high_`name2'"
					if "`fld'"=="l" local tokeep="`tokeep' low_`name2'"
					if "`fld'"=="c" local tokeep="`tokeep' close_`name2'"
					if "`fld'"=="v" local tokeep="`tokeep' volume_`name2'"
				}
				if ("`freq'"=="v") keep date dividends_`name2'
				if ("`freq'"!="v") keep `tokeep' date adjclose_`name2'
				
				* Drop if there are any duplicate observations
				if ("`freq'"!="v") duplicates drop date adjclose_`name2', force
				
				* Create the change variables
				if ("`chg'"!="") {
					drop if adjclose_`name2'==.
					gen day=_n
					tsset day
					foreach sec in `chg' {
						if ("`sec'"=="l") {
							gen l_`name2'=ln(adjclose_`name2')
							label var l_`name2' "Log of `name2'"
						}
						if ("`sec'"=="ln") {
							gen ln_`name2'=ln(adjclose_`name2'/L.adjclose_`name2')
							label var ln_`name2' "Log difference of `name2' (ln(a/L.a))"
						}
						if ("`sec'"=="ln2") {
							gen ln2_`name2'=ln(adjclose_`name2') - ln(L.adjclose_`name2')
							label var ln2_`name2' "Log difference of `name2' (ln(a)-ln(L.a))"
						}
						if ("`sec'"=="per") {
							gen per_`name2'=(adjclose_`name2'-L.adjclose_`name2')/L.adjclose_`name2'
							label var per_`name2' "Percentage change for `name2'"
						}
						if ("`sec'"=="sper") {
							gen sper_`name2'=(adjclose_`name2'-L.adjclose_`name2')/((adjclose_`name2'+L.adjclose_`name2')/2)
							label var sper_`name2' "Symmetric percentage change for `name2'"
						}
					}
					drop day
				}

				sort date
				tsset date
				save "temporary_`name2'.dta", replace
				local symbol_downloaded=1
			}
		}
	
		* If there is any downloaded company file
		* Merge individual files into one data file
		* Erase individual files
		if (`symbol_downloaded'==1) {
			clear
			local sira = 1
			foreach name in `tickers' {
				* Some symbols contain special characters (ex. .,-,^). These need to be kept the same for downloading the data from Yahoo! Finance
				* However, special characters need to be replaced to be used as Stata variables. 
				local name2 :subinstr local name "." "_", all
				local name2 :subinstr local name2 "^" "_", all
				local name2 :subinstr local name2 "-" "_", all

				local first :word `sira' of `tickers'
				if ("`first'"=="`name'") {
					capture: use "temporary_`name2'.dta", clear
					if (_rc==0) {
						erase "temporary_`name2'.dta"
						sort date
					}
					else {
						local sira = `sira' + 1
					}
				}
				else {
					capture: merge date using "temporary_`name2'.dta"
					if (_rc==0) {
						erase "temporary_`name2'.dta"
						drop _merge
						sort date
					}
				}
			}
			if (("`freq'"=="d") & ("`ff3'"!="")) {
				capture: merge date using "F-F_Research_Data_Factors_daily.dta"
				if (_rc==0) {
					erase "F-F_Research_Data_Factors_daily.dta"
					drop _merge
					sort date
				}
			}
			quietly: sort date
			tsset date
		}
		
		if ("`merge'"!="") {
			qui: ds
			if ("`r(varlist)'"!="") {
				qui: merge date using _temp_0001.dta
				qui: erase _temp_0001.dta
				drop _merge
				sort date
			}
		}

		capture: if ("`start'"!="") drop if date<(date("`start'", "DMY"))
		capture: if ("`end'"!="") drop if date>(date("`end'", "DMY"))		
		
		return local downloaded="`downloaded'"
		return local not_downloaded="`not_downloaded'"
	} 
	else {
		di "option freq should be either d, w, m or v"
	}
	
end



