#delimit;
program define wblsel_p;
	version 7;
	args lnf theta1 theta2 theta3 theta4;

	tempvar theta2af lambda1 lambda2 rhostar durdep _rtcnsr _aft;

	quietly gen byte   `_rtcnsr'	= $ML_y3;
	quietly gen byte   `_aft'	= 1 - 2*$ML_y4;

	quietly gen double `theta2af'	= `_aft'*`theta2';
	quietly gen double `lambda1'	= exp(-`theta1');
	quietly gen double `lambda2'	= exp(`theta2af');

	quietly gen double `rhostar' 	= (exp(2*`theta3')-1)/(exp(2*`theta3')+1);
	quietly gen double `durdep' 	= exp(`theta4');
	
	quietly replace `lnf' = `theta2af' + ln(`durdep') + (`durdep'-1)*ln($ML_y2) 
				- `lambda2'*($ML_y2^`durdep') - `lambda1'
		 		+ ln(1+`rhostar'*(2*exp(-`lambda2'*($ML_y2^`durdep'))-1)*(exp(-`lambda1')-1)) 
			if $ML_y1 & !`_rtcnsr';

	quietly replace `lnf' = ln(1 - (1-exp(-`lambda1')) - (1-exp(-`lambda2'*($ML_y2^`durdep'))) 
				+ ((1-exp(-`lambda1'))*(1-exp(-`lambda2'*($ML_y2^`durdep')))*(1+`rhostar'*exp(-`lambda2'*($ML_y2^`durdep')-`lambda1'))) )
			if $ML_y1 & `_rtcnsr';

	quietly replace `lnf' = ln(1-exp(-`lambda1')) if !$ML_y1;

end;

exit;
