#delimit;

program define sudcd_lgn;

	version 7;

	args lnf theta1 theta2 theta3 theta4;

	tempvar lambda2 rho sigma P_cond P_marg P_cens0 P_cens1 ln_l2;

	quietly gen double `lambda2'	= exp(-`theta2');
	quietly gen double `ln_l2' 	= ln($ML_y2*`lambda2');

	quietly gen double `rho' 	= (exp(2*`theta3')-1)/(exp(2*`theta3')+1);
	quietly gen double `sigma' 	= exp(`theta4');

	quietly gen double `P_cond'	= norm([`theta1' + `ln_l2'*`rho'/`sigma']/sqrt(1 - `rho'^2));
	quietly gen double `P_marg'	= normd(`ln_l2'/`sigma')/($ML_y2*`sigma');
	quietly gen double `P_cens0'	= binorm( -`ln_l2'/`sigma' , -`theta1', -`rho' );
	quietly gen double `P_cens1'	= binorm( -`ln_l2'/`sigma' ,  `theta1',  `rho' );

	quietly replace `lnf' = ln(1 - `P_cond') + ln(`P_marg') 	if $ML_y1==0 & rtcensr==0;
	quietly replace `lnf' = ln(`P_cond') + ln(`P_marg') 		if $ML_y1==1 & rtcensr==0;
	quietly replace `lnf' = ln(`P_cens0') 				if $ML_y1==0 & rtcensr==1;
	quietly replace `lnf' = ln(`P_cens1') 				if $ML_y1==1 & rtcensr==1;


end;

exit;
