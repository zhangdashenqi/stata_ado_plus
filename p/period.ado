*! period -- set or display period (frequency)
*! version 1.1.0     Sean Becketti     September 1993           STB-15: sts4
*  revised to store the results in S_D_peri rather than S_period
program define period /* #  or  word   or  # word  */
	version 3.1
	_ts_peri `*'
	mac def S_D_peri "$S_1 $S_2"
	di "$S_1 ($S_2)"
end
