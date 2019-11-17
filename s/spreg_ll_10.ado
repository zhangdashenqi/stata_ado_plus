*! version 0.1 	25aug2009 	beta written by William D. MacMillan, Jude Hays, and Rob Franzese.
*! version 0.11	27aug2009	beta

program define spreg_ll_10
	args lnf mu rho1 rho2  rho3 rho4 rho5 rho6 rho7 rho8 rho9 rho10 sigma
	tempname p1 p2 p3 p4 p5 p6 p7 p8 p9 p10
	scalar `p1' = `rho1'
	scalar `p2' = `rho2'
	scalar `p3' = `rho3'
	scalar `p4' = `rho4'
	scalar `p5' = `rho5'
	scalar `p6' = `rho6'
	scalar `p7' = `rho7'
	scalar `p7' = `rho7'
	scalar `p8' = `rho8'
	scalar `p9' = `rho9'
	scalar `p10' = `rho10'
	mata: detmaker(	"`p1'", "`p2'", "`p3'", "`p4'", "`p5'", "`p6'", "`p7'", "`p8'", "`p9'", "`p10'", W1, W2, /// 
					W3, W4, W5, W6, W7, W8, W9, W10, numw, nob)
	qui replace `lnf'= A + ln(normalden( $ML_y1-`rho1'*SL1 - `rho2'*SL2 - `rho3'*SL3 		/// 
		- `rho4'*SL4 - `rho5'*SL5 - `rho6'*SL6 - `rho7'*SL7 - `rho8'*SL8- `rho9'*SL9 
		- `rho10'*SL10 -`mu', 0, `sigma'))
end

