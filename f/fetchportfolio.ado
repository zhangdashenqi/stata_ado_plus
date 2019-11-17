*! version 1.1
*! Updated: May 31, 2012
*! December 7, 2011

*! Author: Mehmet F. Dicle, mfdicle@gmail.com


* Update 1: Foreign stocks give back an error (per_BMW.DE_temp invalid name) FIXED



program define fetchportfolio, rclass

	

	version 10.0

	

	syntax anything(name=tickers), year(numlist >0)

	

	qui: {

		local tickers2 :subinstr local tickers "." "_", all

		local tickers2 :subinstr local tickers2 "^" "_", all

		local tickers2 :subinstr local tickers2 "-" "_", all

	

		* Years are entered as a numlist. Thus, the list could be 2000 2001 2010 etc. 

		* When downloading the daly prices from Yahoo Finance, we need the minimum of the list and the maximum of the list. 

		local min_year=9999

		local max_year=0001

		foreach aa in `year' {

			if (`aa'<`min_year') local min_year=`aa'

			if (`aa'>`max_year') local max_year=`aa'

		}



		fetchyahooquotes `tickers', freq(v)   /* downloading the dividend payments */

		foreach aa in `tickers2' { /* tickers2 converst BMW.DE to BMW_DE */

			capture: gen dividends_`aa'=.   /* not every stock pays dividends. create a dividend for those that do not pay that is equal to missing. This is for uniformity. */

		}



		if (substr("`:type date'" , 1, 3) == "str") {

			gen date2=date(date,"YMD")

			drop date

			rename date2 date

			format %td date

		}

		sort date

		

		* Downloading the daily price data along with Fama & French factors, the date range from the January 1st of the minimum year to December 31st of the maximum year.

		noi: fetchyahooquotes `tickers', freq(d) chg(ln per) ff3 merge start("01jan`min_year'") end("31dec`max_year'")  

		foreach aa in `tickers2' { /* tickers2 converst BMW.DE to BMW_DE */

			capture: replace dividends_`aa'=dividends_`aa'/adjclose_`aa'   /* not every security can be downloaded (i.e. insufficient observations) */

		}

		

		local tickers="`r(downloaded)'"

		local howmany :word count `tickers'	/* count the number of tickers entered and downloaded*/

		local tickers2 :subinstr local tickers "." "_", all

		local tickers2 :subinstr local tickers2 "^" "_", all

		local tickers2 :subinstr local tickers2 "-" "_", all

		

		* Changing from calendar days to trading days.

		* Lag of Monday must be Friday, not Sunday

		gen day=_n

		tsset day

		save temp_00001.dta, replace



		// Estimating the CAPM Beta and CAPM R-squared

		foreach aa in `year' {

			use temp_00001.dta, clear

			foreach bb in `tickers2' { /* tickers2 converst BMW.DE to BMW_DE */

				gen per_`bb'_temp=per_`bb'-ff3_RF

				reg per_`bb'_temp ff3_Mkt_RF ff3_SMB ff3_HML if year(date)==`aa'

				local B_`bb'=_b[ff3_Mkt_RF]

				local R2_`bb'=e(r2)

				drop per_`bb'_temp

			}

			clear 

			set obs `howmany'

			gen Symbol=""

			gen Beta_`aa'=.

			gen R2_`aa'=.

			local counter=0

			foreach bb in `tickers' {

				local bba :subinstr local bb "." "_", all

				local bba :subinstr local bba "^" "_", all

				local bba :subinstr local bba "-" "_", all



				local counter=`counter'+1

				replace Symbol="`bb'" if _n==`counter'

				replace Beta_`aa'=`B_`bba'' if _n==`counter'

				replace R2_`aa'=`R2_`bba'' if _n==`counter'

			}

			label variable Beta_`aa' "Multifactor CAPM Beta"

			label variable R2_`aa' "Multifactor CAPM R-squared"

			sort Symbol

			save temp_00001_`aa'.dta, replace

		}



		// Mean, total and standard deviation of returns

		foreach aa in `year' {

			use temp_00001.dta, clear

			foreach bb in `tickers2' {

				summ day if year(date)==`aa'

				

				replace adjclose_`bb' = adjclose_`bb'[`r(max)'-1] in `r(max)' if adjclose_`bb'[`r(max)']==.

				replace adjclose_`bb' = adjclose_`bb'[`r(min)'+1] in `r(min)' if adjclose_`bb'[`r(min)']==.

				

				local son_`bb'= adjclose_`bb'[`r(max)']

				local ilk_`bb'= adjclose_`bb'[`r(min)']

				local sum_`bb'=(`son_`bb''-`ilk_`bb'')/`ilk_`bb''

				

				summ per_`bb' if year(date)==`aa', detail

				local sd_`bb'=r(sd)

				local mean_`bb'=r(mean)

			}

			

			qui: summ ff3_RF if year(date)==`aa', detail

			local mean_ff3_RF=r(mean)

			

			clear 

			set obs `howmany'

			gen Symbol=""

			gen Sum_`aa'=.

			gen Sd_`aa'=.

			gen Mean_`aa'=.

			gen Mean_rf_`aa'=.

			local counter=0

			foreach bb in `tickers' {

				local bba :subinstr local bb "." "_", all

				local bba :subinstr local bba "^" "_", all

				local bba :subinstr local bba "-" "_", all

			

				local counter=`counter'+1

				replace Symbol="`bb'" if _n==`counter'

				replace Sum_`aa'=`sum_`bba''*100 if _n==`counter'

				replace Sd_`aa'=`sd_`bba''*100 if _n==`counter'

				replace Mean_`aa'=`mean_`bba''*100 if _n==`counter'

				replace Mean_rf_`aa'=(`mean_`bba''-`mean_ff3_RF')*100 if _n==`counter'

			}

			label variable Sum_`aa' "Total return for the year (includes dividend yield)."

			label variable Sd_`aa' "Standard deviation of daily returns for the year."

			label variable Mean_`aa' "Average daily return for the year."

			label variable Mean_rf_`aa' "Average daily return for the year minus average risk-free rate."

			sort Symbol

			save temp_00002_`aa'.dta, replace

		}





		* Dividends

		foreach aa in `year' {

			use temp_00001.dta, clear

			foreach bb in `tickers2' {

				qui: summ dividends_`bb' if year(date)==`aa', detail

				local sum_`bb'=r(sum)

			}

			clear 

			set obs `howmany'

			gen Symbol=""

			gen Dividends_`aa'=.

			local counter=0

			foreach bb in `tickers' {

				local bba :subinstr local bb "." "_", all

				local bba :subinstr local bba "^" "_", all

				local bba :subinstr local bba "-" "_", all



				local counter=`counter'+1

				replace Symbol="`bb'" if _n==`counter'

				replace Dividends_`aa'=`sum_`bba''*100 if _n==`counter'

			}

			label variable Dividends_`aa' "Dividend yield for the year."

			sort Symbol

			save temp_00003_`aa'.dta, replace

		}



		erase temp_00001.dta



		local counter=0

		foreach aa in `year' {

			local counter=`counter'+1

			if (`counter'==1) {

				use temp_00001_`aa'.dta, clear

				erase temp_00001_`aa'.dta

			}

			else {

				merge Symbol using temp_00001_`aa'.dta

				erase temp_00001_`aa'.dta

				drop _merge

				sort Symbol

			}

			

			merge Symbol using temp_00002_`aa'.dta

			erase temp_00002_`aa'.dta

			drop _merge

			sort Symbol

			

			merge Symbol using temp_00003_`aa'.dta

			erase temp_00003_`aa'.dta

			drop _merge

			sort Symbol

		}

		

		

		foreach aa in `year' {

			replace Sum_`aa'=Sum_`aa'+Dividends_`aa'

			gen Mean_sd_`aa'=Mean_`aa'/Sd_`aa'

			label variable Mean_sd_`aa' "Mean daily return / Standard deviation of daily returns"

			

			gen Sharpe_`aa' = Mean_rf_`aa'/Sd_`aa'

			label variable Sharpe_`aa' "(Mean daily return - mean risk-free rate) / Standard deviation of daily returns"



			gen Sum_sd_`aa'=Sum_`aa'/Sd_`aa'

			label variable Sum_sd_`aa' "Total return (includes dividend yield) / Standard deviation of daily returns"

			

			gen Mean_Beta_`aa'=Mean_`aa'/Beta_`aa'

			label variable Mean_Beta_`aa' "Mean daily return / Multifactor CAPM Beta"

			

			gen Treynor_`aa'=Mean_rf_`aa'/Beta_`aa'

			label variable Treynor_`aa' "(Mean daily return - mean risk-free rate) / Multifactor CAPM Beta"



			gen Sum_Beta_`aa'=Sum_`aa'/Beta_`aa'

			label variable Sum_Beta_`aa' "Total return (includes dividend yield) / Multifactor CAPM Beta"

		}



	}



end







