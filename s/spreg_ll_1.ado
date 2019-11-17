*! version 0.1 	25aug2009 	beta written by William D. MacMillan, Jude Hays, and Rob Franzese.
*! version 0.11	27aug2009	beta

program define spreg_ll_1
	args lnf mu rho1 sigma
	tempname p1
	scalar `p1' = `rho1'
	mata: detmaker(	"`p1'", "`p2'", "`p3'", "`p4'", "`p5'", "`p6'", "`p7'", "`p8'", "`p9'", "`p10'", W1, W2, /// 
					W3, W4, W5, W6, W7, W8, W9, W10, numw, nob)
	qui replace `lnf'= A + ln(normalden($ML_y1-`rho1'*SL1-`mu', 0, `sigma'))
end

