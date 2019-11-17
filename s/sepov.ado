* version 1.1.0  27/09/99	sepov.ado           [STB-51: sg117]
* Dean Jolliffe, Anastassia Semykina

#delimit;

program define sepov;
	version 5.0;
	local varlist "required existing min(1)";
	local weight "pweight iweight";
	local if "optional";
	local in "optional";
	local options "Povline(string) Alfa(real 0) *";
	parse "`*'";
	parse "`varlist'", parse(" ");
	tempvar fgt0 fgt1 fgt2 fgta;

	if `alfa'>=0 {;
	  while "`1'"~="" {;   
           local lbl : variable label `1';
           if "`lbl'"=="" { local lbl "(unlabeled)" };
	   quietly {;
	      gen `fgt0'=0;
	      replace `fgt0'=1 if `1'<`povline';
	      gen `fgt1'=0;
	      replace `fgt1'=1-`1'/`povline' if `1'<`povline';
	      gen `fgt2'=0;
	      replace `fgt2'=(1-`1'/`povline')^2 if `1'<`povline';
	   };

	   if `alfa'==0|`alfa'==1|`alfa'==2 {;
	      quietly svymean `fgt0' `fgt1' `fgt2' `if' `in' [`weight'`exp'], `options';
	      di in gre _n(2) "Poverty measures for the variable `1': `lbl'";
	      rename `fgt0' p0;
	      rename `fgt1' p1;
	      rename `fgt2' p2;
	      svymean p0 p1 p2 `if' `in' [`weight'`exp'], `options';
	      drop p0 p1 p2;
	   };

	   else {;
	      quietly {;
	        gen `fgta'=0;
	        replace `fgta'=(1-`1'/`povline')^`alfa' if `1'<`povline';
	      svymean `fgt0' `fgt1' `fgt2' `fgta' `if' `in' [`weight'`exp'], `options';
	      };
	      di in gre _n(2) "Poverty measures for the variable `1': `lbl'";
	      rename `fgt0' p0;
	      rename `fgt1' p1;
	      rename `fgt2' p2;
	      rename `fgta' p`alfa';
	      svymean p0 p1 p2 p`alfa'  `if' `in' [`weight'`exp'], `options';
	      drop p0 p1 p2 p`alfa';
	   };

	   macro shift;
	  };
	};

	if `alfa'<0 {;
	   di in red "Negative alfa is not allowed";
	};
end;
