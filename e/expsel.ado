#delimit;
program define expsel;
	version 7;
	args lnf theta1 theta2 theta3;

	tempvar theta2af lambda1 lambda2 rhostar _rtcnsr _aft;

	quietly gen byte   `_rtcnsr'	= $ML_y3;
	quietly gen byte   `_aft'	= 1-2*$ML_y4;
	quietly gen double `theta2af'	= `_aft'*`theta2';
	quietly gen double `lambda1'	= exp(-`theta1');
	quietly gen double `lambda2'	= exp(`theta2af');
	quietly gen double `rhostar' 	= (exp(2*`theta3')-1)/(exp(2*`theta3')+1);

	quietly replace `lnf' = `theta2af' - `lambda2'*$ML_y2 - `lambda1'
		 		+ ln(1+`rhostar'*(2*exp(-$ML_y2*`lambda2')-1)*(exp(-`lambda1')-1)) 
			if $ML_y1 & !`_rtcnsr';

	quietly replace `lnf' = ln(1 - (1-exp(-`lambda1')) - (1-exp(-$ML_y2*`lambda2')) 
				+ ((1-exp(-`lambda1'))*(1-exp(-$ML_y2*`lambda2'))*(1+`rhostar'*exp(-$ML_y2*`lambda2'-`lambda1'))) ) 
			if $ML_y1 & `_rtcnsr';

	quietly replace `lnf' = ln(1-exp(-`lambda1')) 
			if !$ML_y1;

end;

exit;
