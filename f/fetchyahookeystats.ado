* Authors:
* Mehmet F. Dicle, Ph.D., Loyola University New Orleans (mfdicle@loyno.edu)
* John Levendis, Ph.D., Loyola University New Orleans
* January 19, 2011

program define fetchyahookeystats, rclass

	version 10.0

	syntax anything(name=tickers), field(string) [save(string)] [page(integer 1)]
	
	* FOR KEY STATISTICS
	* field can have one or more of the following (there should be space between the codes, ex. s n a b l1 j4); 
	* a: Ask 
	* b: Bid 
	* b4: Book Value 
	* c: Percent Change 
	* c1: Change 
	* d: Dividend per Share 
	* d1: Last Trade Date 
	* e: Earning per Share 
	* f6: Float Shares 
	* g: Day's Low 
	* h: Day's High 
	* j: 52-Week Low 
	* j1: Market Capitalization 
	* j4: EBITDA 
	* k: 52-Week High 
	* l1: Last Trade Price
	* m3: 50-Day Moving Average
	* m4: 200-Day Moving Average
	* n: Name
	* o: Open
	* p: Previous Close
	* p5: Price/Sales
	* p6: Price/Book
	* q: Ex-Dividend Date
	* r: Price/Earnings
	* s: Symbol
	* s7: Short Ratio
	* v: Volume
	* x: Exchange
	* y: Dividend Yield
	
	* Yahoo* Finance API adds new symbols time to time. Users can download these new fields. 
	* However, the new fields will not have corresponding variable names. 
	
	* Yahoo! Finance API can provide key statistics for multiple securities. 
	* However, it is usually 50 symbols at a time.
	* Also, some HTML protocols do not allow html addresses to contain more than certain number of characters
	* If there are 30 securities, then download them all at once
	* If there are more than 30 securities, then download them one by one and append them into a data file
	local howmany :word count `tickers'
	
	* Symbol and name are default fields
	local field = "s n `field'"
	
	* If there are less than and equal to 30 symbols
	if (`howmany'<=30) {
		local tickers2 :subinstr local tickers " " "+", all
		local field2 :subinstr local field " " "", all
		insheet using "http://download.finance.yahoo.com/d/quotes.csv?s=`tickers2'&f=`field2'&h=`page'", noname comma clear

		local vars=0
		foreach name in `field' {
			local vars=`vars'+1
			local unknown=1
			if (lower("`name'")=="a") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Ask 
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="b") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Bid 
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="b4") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Book_Value
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="c") {
				capture: rename v`vars' Percent_Change
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="c1") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Change
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="d") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Dividend_per_Share
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="d1") {
				capture {
					gen double Last_Trade_Date=date(v`vars',"MDY")
					format Last_Trade_Date %td
					drop v`vars'
				}
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="e") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Earnings_per_Share
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="f6") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Floating_Shares
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="g") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Days_Low
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="h") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Days_High
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="j") {
				capture: destring v`vars', replace force
				capture: rename v`vars' _52_Weeks_Low
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="j1") {
				capture: rename v`vars' Market_Capitalization
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="j4") {
				capture: destring v`vars', replace force
				capture: rename v`vars' EBITDA
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="k") {
				capture: destring v`vars', replace force
				capture: rename v`vars' _52_Week_High
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="l1") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Last_Trade_Price
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="m3") {
				capture: destring v`vars', replace force
				capture: rename v`vars' _50_Days_Moving_Average
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="m4") {
				capture: destring v`vars', replace force
				capture: rename v`vars' _200_Days_Moving_Average
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="n") {
				capture: rename v`vars' Name
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="o") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Open
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="p") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Previous_Close
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="p5") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Price_to_Sales
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="p6") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Price_to_Book
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="q") {
				capture: rename v`vars' Ex_Dividend_Date
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="r") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Price_to_Earnings
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="s") {
				capture: rename v`vars' Symbol
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="s7") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Short_Ratio
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="v") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Volume
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="x") {
				capture: rename v`vars' Exchange
				if (_rc!=0) drop v`vars'
			}
			else if (lower("`name'")=="y") {
				capture: destring v`vars', replace force
				capture: rename v`vars' Dividend_Yield
				if (_rc!=0) drop v`vars'
			}
			else {
				if (length(v`vars')>30) {
					drop v`vars'
				}
				else {
					capture: rename v`vars' Unknown_Field_`unknown'
					if (_rc==0) {
						local unknown=`unknown'+1
					}
					else {
						drop v`vars'
					}
				}
			}
		}
		
		if ("`save'"!="") quietly: save "`save'.dta", replace	
	}


	* If there are more than 30 symbols
	if (`howmany'>30) {
		local field2 :subinstr local field " " "", all
		
		foreach symbol in `tickers' {
			* Some symbols contain special characters (ex. .,-,^). These need to be kept the same for downloading the data from Yahoo! Finance
			* However, special characters need to be replaced to be used as Stata variables. 
			local symbol2 :subinstr local symbol "." "_", all
			local symbol2 :subinstr local symbol2 "^" "_", all
			local symbol2 :subinstr local symbol2 "-" "_", all

			insheet using "http://download.finance.yahoo.com/d/quotes.csv?s=`symbol'&f=`field2'&h=`page'", noname comma clear

			local vars=0
			foreach name in `field' {
				local vars=`vars'+1
				local unknown=1;
				else if (lower("`name'")=="a") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Ask 
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="b") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Bid 
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="b4") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Book_Value
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="c") {
					capture: rename v`vars' Percent_Change
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="c1") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Change
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="d") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Dividend_per_Share
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="d1") {
					capture {
						gen double Last_Trade_Date=date(v`vars',"YMD")
						format Last_Trade_Date %td
						drop v`vars'
					}
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="e") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Earnings_per_Share
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="f6") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Floating_Shares
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="g") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Days_Low
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="h") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Days_High
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="j") {
					capture: destring v`vars', replace force
					capture: rename v`vars' _52_Weeks_Low
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="j1") {
					capture: rename v`vars' Market_Capitalization
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="j4") {
					capture: destring v`vars', replace force
					capture: rename v`vars' EBITDA
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="k") {
					capture: destring v`vars', replace force
					capture: rename v`vars' _52_Week_High
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="l1") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Last_Trade_Price
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="m3") {
					capture: destring v`vars', replace force
					capture: rename v`vars' _50_Days_Moving_Average
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="m4") {
					capture: destring v`vars', replace force
					capture: rename v`vars' _200_Days_Moving_Average
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="n") {
					capture: rename v`vars' Name
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="o") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Open
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="p") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Previous_Close
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="p5") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Price_to_Sales
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="p6") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Price_to_Book
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="q") {
					capture: rename v`vars' Ex_Dividend_Date
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="r") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Price_to_Earnings
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="s") {
					capture: rename v`vars' Symbol
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="s7") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Short_Ratio
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="v") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Volume
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="x") {
					capture: rename v`vars' Exchange
					if (_rc!=0) drop v`vars'
				}
				else if (lower("`name'")=="y") {
					capture: destring v`vars', replace force
					capture: rename v`vars' Dividend_Yield
					if (_rc!=0) drop v`vars'
				}
				else {
					if (length(v`vars')>30) {
						drop v`vars'
					}
					else {
						capture: rename v`vars' Unknown_Field_`unknown'
						if (_rc==0) {
							local unknown=`unknown'+1
						}
						else {
							drop v`vars'
						}
					}
				}
			}
			
			save "temporary_`symbol'.dta", replace
		}

		* Append individual files into one data file
		* Erase individual files
		clear
		foreach symbol in `tickers' {
			* Some symbols contain special characters (ex. .,-,^). These need to be kept the same for downloading the data from Yahoo! Finance
			* However, special characters need to be replaced to be used as Stata variables. 
			local symbol2 :subinstr local symbol "." "_", all
			local symbol2 :subinstr local symbol2 "^" "_", all
			local symbol2 :subinstr local symbol2 "-" "_", all

			local first :word 1 of `tickers'
			if ("`first'"=="`symbol'") {
				capture: use "temporary_`symbol2'.dta", clear
				if (_rc==0) erase "temporary_`symbol2'.dta"
			}
			else {
				capture: append using "temporary_`symbol2'.dta"
				if (_rc==0) erase "temporary_`symbol2'.dta"
			}
		}
		
		if ("`save'"!="") quietly: save "`save'.dta", replace	

	}
	
	
end




