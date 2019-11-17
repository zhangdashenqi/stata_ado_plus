*! version 1.0.0 10aug1999
program define trunc_ll
	version 6.0
	args lnf theta1 theta2
	if $T_flag == 1 { 
	     qui replace `lnf' = ln(normd(($ML_y1-`theta1')/`theta2')) /*
		  */ - ln(`theta2') /* 
		  */ - ln(normprob(-($T_a - `theta1')/`theta2'))
        }
	if $T_flag == -1 { 
	     qui replace `lnf' = ln(normd(($ML_y1-`theta1')/`theta2')) /*
		  */ - ln(`theta2') /* 
		  */ - ln(normprob(($T_b - `theta1')/`theta2'))
        }
	if $T_flag == 0 {
	     qui replace `lnf' = ln(normd(($ML_y1-`theta1')/`theta2')) /*
		  */ - ln(`theta2') /*
		  */ - ln(normprob(($T_b - `theta1')/`theta2')         /*
		  */ - normprob(($T_a - `theta1')/`theta2'))
        }
	if $T_flag == 2 {
	     qui replace `lnf' = ln(normd(($ML_y1 -`theta1')/`theta2')) /*
		  */ -ln(`theta2')
	}
end
