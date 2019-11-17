*! _tx_rpl -- replace utility for egen mtr()            (ss1.1: STB-22)
*! version 1.1.0     September 1994     Timothy J. Schmidt
program define _tx_rpl
	version 3.1
	replace $S_1 = `4' if ($S_2 == `1') & ($S_3 > `2') & ($S_3 <= `3') $S_4 $S_5
end

