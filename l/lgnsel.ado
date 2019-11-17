#delimit;

program define lgnsel;
	version 7;
	args lnf theta1 theta2 theta3 theta4;

	tempvar theta2af lambda2 rhostar sigma durdep P_obs P_marg P_cond P_cens _rtcnsr;

	quietly gen byte   `_rtcnsr'	= $ML_y3;
	quietly gen double `lambda2'	= exp(-`theta2');
	quietly gen double `rhostar' 	= (exp(2*`theta3')-1)/(exp(2*`theta3')+1);
	quietly gen double `sigma' 	= exp(`theta4');

	quietly gen double `P_obs' 	= norm(`theta1');
	quietly gen double `P_marg' 	= normd(ln($ML_y2*`lambda2')/`sigma')/`sigma';
	quietly gen double `P_cond' 	= norm((`theta1'+ln($ML_y2*`lambda2')*`rhostar'/`sigma')/sqrt(1-`rhostar'^2));
	quietly gen double `P_cens'	= binorm(`theta1',-log($ML_y2*`lambda2')/`sigma',`rhostar');

	quietly replace `lnf' = log(`P_cond') + log(`P_marg')	if $ML_y1 & !`_rtcnsr';
	quietly replace `lnf' = log(`P_cens')			if $ML_y1 &  `_rtcnsr';
	quietly replace `lnf' = log(1-`P_obs') 			if !$ML_y1;

end;

exit;
