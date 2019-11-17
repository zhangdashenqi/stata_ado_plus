*! version 1.0
*! July 14, 2013
*! Update: July 24, 2016
*! Update: Jun 21, 2017
*! Author: Mehmet F. Dicle, mfdicle@gmail.com

program define tftools, rclass
	
	version 10.0

	gettoken proc rest : 0, parse(",")
	
	local replay = (("`proc'"==""|"`proc'"==",") & "`e(cmd)'"== "tftools")
	if (`replay') {
		di "Please chose one of the technical analysis tools (movingaverage, bollingerbands, macd or rsi)."
	}
	else {
		* if ther is no "if" or "in"
		if "`proc'" == "movingaverage" {
			tftools_movingaverage `rest'
		}
		else if "`proc'" == "bollingerbands" {
			tftools_bollingerbands `rest'
		}
		else if "`proc'" == "macd" {
			tftools_macd `rest'
		}
		else if "`proc'" == "rsi" {
			tftools_rsi `rest'
		}
		else {
			* if there is "if" OR "in"
			gettoken proc2 rest2 : proc, parse(" ")
			if "`proc2'" == "movingaverage" {
				tftools_movingaverage `rest2' `rest'
			}
			else if "`proc2'" == "bollingerbands" {
				tftools_bollingerbands `rest2' `rest'
			}
			else if "`proc2'" == "macd" {
				tftools_macd `rest2' `rest'
			}
			else if "`proc2'" == "rsi" {
				tftools_rsi `rest2' `rest'
			}
			else {
				di "`proc' is undefined. Please chose one of the technical analysis tools (movingaverage, bollingerbands, macd or rsi)."
			}
		}
	}
		
end



program define tftools_movingaverage, rclass
	
	version 10.0
	
	syntax [if] [in], symbol(varlist numeric max=1) period(integer) ma_type(string) generate(string)
	* ma_type: sma (simple moving average)
	* ma_type: ema (exponential moving average)
	* ma_type: sd (moving standard deviation)
	* ma_type: sum (moving sum)
	* ma_type: min (moving minimum)
	* ma_type: max (moving maximum)
		
	qui: {
	
		local aaa111=`period'
		local bbb222=`period'-1

		if ("`ma_type'"=="max") {
			* moving maximum, 5 days
			gen `generate'_max_`period'=.
			label variable `generate'_max_`period' "Moving maximum (`period' days) for `symbol'"

			egen obs____temp____1 = seq() `if' `in'
			summ obs____temp____1
			local obs = r(max)

			forval aa=`period'/`obs' {
				egen temp=max(`symbol') if obs____temp____1<=`aa' & obs____temp____1>=`aa'-(`period'-1)
				replace `generate'_max_`period'=temp if obs____temp____1==`aa'
				drop temp
			}
			drop obs____temp____1
		}

		if ("`ma_type'"=="min") {
			* moving minimum, 5 days
			gen `generate'_min_`period'=.
			label variable `generate'_min_`period' "Moving minimum (`period' days) for `symbol'"

			egen obs____temp____1 = seq() `if' `in'
			summ obs____temp____1
			local obs = r(max)

			forval aa=`period'/`obs' {
				egen temp=min(`symbol') if obs____temp____1<=`aa' & obs____temp____1>=`aa'-(`period'-1)
				replace `generate'_min_`period'=temp if obs____temp____1==`aa'
				drop temp
			}
			drop obs____temp____1
		}
		
		if ("`ma_type'"=="sum") {
			* moving total return, 5 days
			gen `generate'_sum_`period'=.
			label variable `generate'_sum_`period' "Moving total return (`period' days) for `symbol'"

			egen obs____temp____1 = seq() `if' `in'
			summ obs____temp____1
			local obs = r(max)

			forval aa=`period'/`obs' {
				egen temp=total(`symbol') if obs____temp____1<=`aa' & obs____temp____1>=`aa'-(`period'-1)
				replace `generate'_sum_`period'=temp if obs____temp____1==`aa'
				drop temp
			}
			drop obs____temp____1
		}

		if ("`ma_type'"=="sd") {
			* moving standard deviation, 10 days
			gen `generate'_sd_`period'=.
			label variable `generate'_sd_`period' "Moving standard deviaion (`period' days) for `symbol'"
			
			egen obs____temp____1 = seq() `if' `in'
			summ obs____temp____1
			local obs = r(max)
			
			forval aa=`period'/`obs' {
				egen temp=sd(`symbol') if obs____temp____1<=`aa' & obs____temp____1>=`aa'-(`period'-1)
				replace `generate'_sd_`period'=temp if obs____temp____1==`aa'
				drop temp
			}
			drop obs____temp____1
		}
				
		if ("`ma_type'"=="sma") {
			* simple moving average, 10 days
			* 9 lagged terms, current observation, 0 forward term
			tssmooth ma `generate'_sma_`aaa111'=`symbol' `if' `in', window(`bbb222' 1 0)

			egen obs____temp____1 = seq() `if' `in'
			summ obs____temp____1
			local obs = r(max)

			replace `generate'_sma_`aaa111'=. if obs____temp____1<`aaa111'
			replace `generate'_sma_`aaa111'=. if obs____temp____1>`obs'

			label variable `generate'_sma_`aaa111' "SMA (`aaa111' days) for `symbol'"
			drop obs____temp____1
		}
		
		if ("`ma_type'"=="ema") {
			* simple moving average, 10 days
			* 9 lagged terms, current observation, 0 forward term
			tssmooth ma temp_`generate'_sma_`aaa111'=`symbol' `if' `in', window(`bbb222' 1 0)

			egen obs____temp____1 = seq() `if' `in'
			summ obs____temp____1
			local obs = r(max)

			replace temp_`generate'_sma_`aaa111'=. if obs____temp____1<`aaa111'

			* exponential moving average, 10 days
			* 10 lagged terms, current observation, 0 forward term
			gen multiplier`aaa111'= 2 / (`aaa111'+1) `if' `in'
			gen `generate'_ema_`aaa111'=temp_`generate'_sma_`aaa111' if obs____temp____1==`aaa111'
			replace `generate'_ema_`aaa111'=(multiplier`aaa111' * (`symbol' - L.`generate'_ema_`aaa111')) + L.`generate'_ema_`aaa111' if obs____temp____1>`aaa111'

			label variable `generate'_ema_`aaa111' "EMA (`aaa111' days) for `symbol'"
			drop multiplier`aaa111' temp_`generate'_sma_`aaa111' obs____temp____1
		}
		
	}
	
end



program define tftools_bollingerbands, rclass
	
	version 10.0
	
	syntax [if] [in], symbol(varlist numeric max=1) generate(string) [period(string) sdevs(string)]

	if ("`period'"=="") local period="20"
	if ("`sdevs'"=="") local sdevs="2"	
	
	local bb=`period'-1
	
	qui: {
		gen sd_`period'=.
		
		egen obs____temp____2 = seq() `if' `in'
		summ obs____temp____2
		local obs = r(max)

		forval aa = `period'/`obs' { 	
			egen temp=sd(`symbol') if obs____temp____2<=`aa' & obs____temp____2>=`aa'-`bb'
			replace sd_`period'=temp if obs____temp____2==`aa' 
			drop temp
		}

		* simple moving average
		tftools movingaverage `if' `in', symbol(`symbol') period(`period') ma_type(sma) generate(`generate')

		gen `generate'_middle_band=`generate'_sma_`period'
		gen `generate'_upper_band=`generate'_sma_`period'+(sd_`period'*`sdevs')
		gen `generate'_lower_band=`generate'_sma_`period'-(sd_`period'*`sdevs')
		
		drop sd_`period' `generate'_sma_`period' obs____temp____2

	}
	
end



program define tftools_macd, rclass
	
	version 10.0
	
	syntax [if] [in], symbol(varlist numeric max=1) generate(string)
		
	qui: {
		* simple moving average, 12 days
		tftools movingaverage `if' `in', symbol(`symbol') period(12) ma_type(sma) generate(`generate')

		* simple moving average, 26 days
		tftools movingaverage `if' `in', symbol(`symbol') period(26) ma_type(sma) generate(`generate')

		* exponential moving average, 12 days
		tftools movingaverage `if' `in', symbol(`symbol') period(12) ma_type(ema) generate(`generate')

		* exponential moving average, 26 days
		tftools movingaverage `if' `in', symbol(`symbol') period(26) ma_type(ema) generate(`generate')

		gen MACD_line=`generate'_ema_12-`generate'_ema_26 `if' `in'

		egen obs____temp____2 = seq() `if' `in'
		summ obs____temp____2
		local obs = r(max)

		* simple moving average, 9 days
		* 8 lagged terms, current observation, 0 forward term
		tssmooth ma sma_9_MACD_line=MACD_line `if' `in', window(8 1 0)
		replace sma_9_MACD_line=. if obs____temp____2<(26+9)
		label variable sma_9_MACD_line "SMA (9 days) for MACD_line"

		* exponential moving average, 9 days
		* 9 lagged terms, current observation, 0 forward term
		gen multiplier9= 2 / (9+1) `if' `in'
		gen ema_9_MACD_line=sma_9_MACD_line if obs____temp____2==(26+9)
		
		replace ema_9_MACD_line=(multiplier9 * (MACD_line - L.ema_9_MACD_line)) + L.ema_9_MACD_line if obs____temp____2>(26+9)
		label variable ema_9_MACD_line "EMA (9 days) for MACD_line"

		gen signal_line=ema_9_MACD_line

		gen MACD_histogram= MACD_line - signal_line `if' `in'
		drop multiplier* sma* ema* obs____temp____2
		
		rename MACD_line `generate'_MACD_line
		rename signal_line `generate'_signal_line
		rename MACD_histogram `generate'_MACD_histogram
		
	}
	
end



program define tftools_rsi, rclass
	
	version 10.0
	
	syntax [if] [in], symbol(varlist numeric max=1) generate(string)

	qui: {
		gen change=D.`symbol' `if' `in'
		egen obs____temp____1 = seq() if change!=.
				
		gen gain=abs(change) if change>0 & change!=.
		gen loss=abs(change) if change<0 & change!=.
		replace gain=0 if gain==. & change!=.
		replace loss=0 if loss==. & change!=.
	
		* First AG and AL, i.e. 14th day
		tssmooth ma AG=gain `if' `in', window(14 0 0)
		tssmooth ma AL=loss `if' `in', window(14 0 0)
		replace AG=. if obs____temp____1!=14
		replace AL=. if obs____temp____1!=14

		replace AG=((L.AG*13)+gain)/14 if (obs____temp____1>14)
		replace AL=((L.AL*13)+loss)/14 if (obs____temp____1>14)

		gen RSI=AG/AL `if' `in'
		gen `generate'_RSI=100 if AL==0 & change!=.
		replace `generate'_RSI=100-(100/(1+RSI)) `if' `in'

		drop change gain loss AG AL RSI obs____temp____1
	}
	
end



