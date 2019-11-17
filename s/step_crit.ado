//version 1.0.0  21jan2008
program step_crit, rclass
version 10.0
syntax varlist [if] [in] [, BACKward FORward R2ADJ AIC AICC BIC]
qui {
if ( ("`backward'" == "" & "`forward'" == "") | ///
("`backward'" != "" & "`forward'" != "")) {
noi	di as error "must specify JUST 1 direction"
	exit 198
}

tokenize `varlist'
capture assert "`2'" != ""
if (_rc > 0) {
noi	di as error "varlist must have more than one predictor"
	exit 198
}

	//mark used sample
marksample touse

	//set depvar to be dependent variable
local depvar = "`1'"
	//and predlist to hold independent variables
local predlist: subinstr local varlist "`depvar'" "", word all
	//and npreds as an index of the number of our predictors
local npreds: word count `predlist'
tokenize predlist

if ("`forward'" != "") {
		//do forward elimination

		//prepredlist, hold predlist of previous iteration
	local prepredlist ""
		//list of predictors not used in previous iteration
	local prenirpredlist ""

		//no predictors initially in current
	local curpredlist ""
	local curnirpredlist "`predlist'"

		//preINFO, holds INFO of previous iteration
	local preINFO = .	
		//curINFO, holds INFO of current iteration
		//initialize curINFo with total regression
       reg `depvar' if `touse'
       if ("`r2adj'" != "") {
                local curINFO = -e(r2_a)
       }
       else if ("`aic'" != "") {
                local curINFO = e(N)*ln(e(rss)/e(N)) + 2*(e(N) - e(df_r))
       }
       else if ("`aicc'" != "") {
                local curINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r)) + 2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1)
        }
       else if ("`bic'" != "") {
                local curINFO = e(N)*ln(e(rss)/e(N)) + ///
ln(e(N))*(e(N) - e(df_r))
       }
       else {
                di as error "no information criteria specified"
                exit 198
       }
            

        local i = 0
        while (`curINFO' < `preINFO') {
                        //reinitialize pre s
                local preINFO = `curINFO'
                local prepredlist "`curpredlist'"
		local prenirpredlist "`curnirpredlist'"
                        //output previous iteration results to user
                noi di as text "{hline 78}"
                noi di "Stage `i' reg `depvar' "  ltrim("`curpredlist'") ///
 " : INFO " %9.0g `curINFO'
		noi di as text "{hline 78}"
                local i = `i' + 1
                       //points to INFO for regression without variable at index
                        //updated as min for each new regression performed
                local minINFO = .
                local minINFOindex = ""
                        //search through curnirpredlist, doing regressions 
			//with variable at index
                        //update minINFO and minINFOindex
                foreach var of varlist `curnirpredlist' {

                        local tempcurpredlist "`curpredlist' `var'"
                        reg `depvar' `tempcurpredlist' if `touse'

                        if ("`r2adj'" != "") {
                                local tempcurINFO = -e(r2_a)
                        }
                        else if ("`aic'" != "") {
                                local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r))
                        }
                        else if ("`aicc'" != "") {
                                local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r)) + 2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1)
                        }
                        else if ("`bic'" != "") {
                                local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
ln(e(N))*(e(N) - e(df_r))
                        }
                        if (`minINFO' > `tempcurINFO') {
                                local minINFO = `tempcurINFO'
                                local minINFOindex = "`var'"
                        }
                        //show user affect of addition
			  noi di "INFO " %9.0g `tempcurINFO' ///
" :         add " %10s "`var'"   


               }
                        //update current to reflect search results
                local curINFO = `minINFO'
                local curpredlist "`curpredlist' `minINFOindex'" 
		local curnirpredlist: subinstr local curnirpredlist ///
"`minINFOindex'" "", word all
	}
                //output optimal results as estimates
        noi di ""
return local predlist `prepredlist'
}

if ("`backward'" != "") {
		//do backward elimination

		//prepredlist, hold predlist of previous iteration
	local prepredlist ""
		//all predictors initially in
	local curpredlist "`predlist'"

		//preINFO, holds INFO of previous iteration 
	local preINFO = .
		//curINFO, holds INFO of current iteration
		//initialize curINFO with total regression
	reg `varlist' if `touse'
	if ("`r2adj'" != "") {
		local curINFO = -e(r2_a)
	}
	else if ("`aic'" != "") {
		local curINFO = e(N)*ln(e(rss)/e(N)) + 2*(e(N) - e(df_r))
	}
	else if ("`aicc'" != "") {
		local curINFO = e(N)*ln(e(rss)/e(N)) + 2*(e(N) - e(df_r)) + ///
2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1)
	}
	else if ("`bic'" != "") {
		local curINFO = e(N)*ln(e(rss)/e(N)) + ln(e(N))*(e(N) - e(df_r))
	}
	else {
		di as error "no information criteria specified"
		exit 198
	}


	local i = 0

	while (`curINFO' < `preINFO') {
	
			//reinitialize preINFO
		local preINFO = `curINFO'
			//retinitialzie predpredlist
		local prepredlist "`curpredlist'"

			//output previous iteration results to user 
                noi di as text "{hline 78}"
		noi di "Stage `i' reg `depvar' "  ltrim("`curpredlist'")  ///
" : INFO " %9.0g `curINFO'
                noi di as text "{hline 78}"

		local i = `i' + 1

			//points to INFO for regression without variable 
			//at index
			//updated as min for each new regression performed
		local minINFO = .
		local minINFOindex = ""
			//search through curpredlist, doing regressions 
			//without variable at index
			//update minINFO and minINFOindex
		foreach var of varlist `curpredlist' {

                        local tempcurpredlist: subinstr local curpredlist ///
"`var'" "", word all
                        reg `depvar' `tempcurpredlist' if `touse'

			if ("`r2adj'" != "") {
		        	local tempcurINFO = -e(r2_a)
			}
			else if ("`aic'" != "") {
			        local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r))
			}
			else if ("`aicc'" != "") {
			        local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r)) + 2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1)
			}
			else if ("`bic'" != "") {
			        local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
ln(e(N))*(e(N) - e(df_r))
			}
			if (`minINFO' > `tempcurINFO') {
				local minINFO = `tempcurINFO'
				local minINFOindex = "`var'"
			}
			//show user affect of removal
			  noi di "INFO " %9.0g `tempcurINFO' ///
" :         remove " %10s "`var'"   


		}

			//update current to reflect search results
		local curINFO = `minINFO'
		local curpredlist: subinstr local curpredlist ///
"`minINFOindex'" "", word all
	}

		//output optimal results as estimates
	noi di ""
return local predlist `prepredlist'
}
}

end
