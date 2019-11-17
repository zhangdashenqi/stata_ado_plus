#delimit;

program define sudcd_exp;

	version 7;

	args lnf theta1 theta2 theta3;

	tempvar lambda1 lambda2 rho _rtcnsr _aft P_cond P_marg P_cum P_cens0 P_cens1 e_l1 e_l2;

	quietly gen double `rho' 	= (exp(2*`theta3')-1)/(exp(2*`theta3')+1);

	quietly gen byte   `_rtcnsr'	= $ML_y3;
	quietly gen byte   `_aft'	= 1 - 2*$ML_y4;

	quietly gen double `lambda1'	= exp(-`theta1');
	quietly gen double `lambda2'	= exp(`_aft'*`theta2');

	quietly gen double `e_l1'	= exp(-`lambda1');
	quietly gen double `e_l2'	= exp(-`lambda2'*$ML_y2);

	quietly gen double `P_cond'	= `e_l1'*[1 + `rho'*(2*`e_l2' - 1)*(`e_l1' - 1)];
	quietly gen double `P_marg'	= `lambda2'*`e_l2';
	quietly gen double `P_cum'	= (1 - `e_l1')*(1 - `e_l2')*[1 + `rho'*`e_l2'*`e_l1'];
	quietly gen double `P_cens1'	= 1 - (1 - `e_l1') - (1 - `e_l2') + `P_cum';
	quietly gen double `P_cens0'	= (1 - `e_l1') - `P_cum';

	quietly replace `lnf' = ln(1 - `P_cond') + ln(`P_marg') 	if $ML_y1==0 & `_rtcnsr'==0;
	quietly replace `lnf' = ln(`P_cond') + ln(`P_marg') 		if $ML_y1==1 & `_rtcnsr'==0;
	quietly replace `lnf' = ln(`P_cens0') 				if $ML_y1==0 & `_rtcnsr'==1;
	quietly replace `lnf' = ln(`P_cens1') 				if $ML_y1==1 & `_rtcnsr'==1;


end;

exit;
