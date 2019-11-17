*! Version 4.0.0  STB-38 sg71
#delimit ;
*  Stata code for NMSIMP;
capture program drop amoeba;
program define amoeba;
   version 4.0;
   if "`1'"=="" {; 
      di in g _n "amoeba" in w _n(2)
      _col(10) "amoeba obj xin yout xout [stepsize funcmax tolerance]" in y _n(2)
      _col(5) "maximize the function " in w "obj " in y _n
      _col(5) "starting at the ROW vector " in w "xin " in y _n
      _col(5) "report max value in scalar " in w "yout " in y _n
      _col(5) "report max vector in " in w "xout " in y _n
      _col(5) "call to obj is the form " in w "obj x y " in y _n(2)
      _col(5) "options: stepsize, # of iterations, convergence tolerance" _n
      _col(5) "use . to skip options" _n;
      exit;
      };
     tempname ysave ptmp ytmp rtol ytry sstep step avec p toler stepsz y psum;
*         initialize values ;
     loc obj = "`1'";
     loc NP = colsof(`2');
     loc MP = `NP'+1;
     loc n_func = 0;
     mat `avec' = J(1,`MP',1.0);
     mat `ptmp' = `2';
     if "`5'"=="" | "`5'"=="." {; sca `stepsz' = 1.1;};
     else                      {; sca `stepsz' = 1+`5';}; 
     if "`6'"=="" | "`6'"=="." {; loc funcmax = 1000;};
     else                      {; loc funcmax = `6';}; 
     if "`7'"=="" | "`7'"=="." {; sca `toler' = 1E-5;};
     else                      {; sca `toler' = `7';}; 
     mat `p' = `ptmp';
     `obj' `ptmp' `ysave';
     di _n in b _dup(20) "-" in w " Starting Amoeba " in b _dup(20) "-";
     mat l `ptmp', t(Starting values)  format(%9.5f);
     di in b "Starting value of `obj': " in y %9.5f `ysave';
     mat `y' = J(1,1,`ysave');
     loc j = 1;
     while `j' < 2 {;
       loc i = 1;
       while `i' <= `NP' {;
          sca `sstep' = `ptmp'[1,`i']*`stepsz';
          mat `step' = J(1,1,`sstep');
          mat sub `ptmp'[1,`i'] = `step';
          `obj' `ptmp' `ysave';
          mat `p' = `p' \ `ptmp';
          sca `sstep' = `ptmp'[1,`i'];
          mat `step' = J(1,1,`sstep');
          mat sub `ptmp'[1,`i'] = `step';     
          mat `ytmp' = J(1,1,`ysave');
          mat `y' = `y' , `ytmp';        
          loc i = `i'+1;
          };
       mat `psum' = `avec'*`p';
       sca `rtol' = `toler'+1.0;
       while (`n_func' <= `funcmax') & (`rtol' > `toler') {;
            di in b "." _cont;
            loc n_func = `n_func'+1;
            loc ilo = 1; loc ihi = 1;
            if `y'[1,1] < `y'[1,2] {; loc inhi = 2; loc ilo = 2;};
            else           	       {; loc ihi = 2; loc inhi = 1;};
            loc i = 1;
            while `i' <= `MP' {;
               sca `ysave' = `y'[1,`i'];
               if `ysave' > `y'[1,`ilo'] {; loc ilo = `i';};
                  if `ysave' < `y'[1,`ihi'] {; loc inhi = `ihi'; loc ihi = `i';};
                  else {;
                    if (`ysave' < `y'[1,`inhi'])&(`i' != `ihi') {; loc inhi = `i';};
                       };
                  loc i = `i' + 1;
               };
            amotry `obj' -1.0 `ytry' `ihi' `p' `y' `psum';
            mat `psum' = `avec'*`p';
            if `ytry' >= `y'[1,`ilo'] {; amotry `obj' 1.4 `ytry'  `ihi' `p' `y' `psum'; mat `psum' = `avec'*`p';};
            else {;
	         if `ytry' <= `y'[1,`inhi'] {;
                    sca `ysave' = `y'[1,`ihi'];
                    amotry `obj' 0.25 `ytry'  `ihi' `p' `y' `psum';
                    mat `psum' = `avec'*`p';
                    if `ytry' <= `ysave' {;
                       loc i = 1;
                       mat `ptmp' = `p'[`ilo',1...];
                       mat `ptmp' = 0.5*`ptmp';
                       while `i' <= `MP' {;
                          mat `psum' = `p'[`i',1...];
                          mat `psum' = 0.5*`psum';
                          mat `psum' = `psum' + `ptmp';
                          mat sub `p'[`i',1] = `psum';
                          `obj' `psum' `ysave' ;
                          mat `ytmp' = J(1,1,`ysave');
                          mat sub `y'[1,`i'] = `ytmp';
                          loc i = `i' + 1;
                          };
                       mat `psum' = `avec'*`p';
                       };
                    };
              };
            sca `rtol' = abs(`y'[1,`ihi']-`y'[1,`ilo'])/(max(abs(`y'[1,`ihi'])+abs(`y'[1,`ilo']),1E-5));
            sca `3' = `y'[1,`ilo'];
            mat `4' = `p'[`ilo',1...];
            };
       loc j = `j' + 1;
       mat `ptmp' = `p'[`ilo',1...];
       mat `p' = `ptmp';
       mat `y' = `y'[1,`ilo'];
       };
   di _n in b    _col(5)  "Value of `obj'"
                 _col(30) "Simplex Size"
                 _col(50) "Iterations" _n
            in y _col(5)  %8.5f `3'
                 _col(30) %5.3e `rtol'
                 _col(50) %3.0f `n_func';
   mat l `4', t(Amoeba final values stored in `4') format(%9.5f);
   di _n in b _dup(20) "-" in w " Ending Amoeba" in b _dup(20) "-" _n;
   end;

capture program drop amotry;
program define amotry;
   version 4.0;
   loc obj = "`1'";
   loc fac = "`2'" ;
   loc ytry = "`3'" ;
   loc ihi = "`4'";
   loc p = "`5'" ;
   loc y = "`6'" ;
   loc psum = "`7'"  ;
   tempname fac1 fac2 ptry ptmp mtmp ;
   sca `fac1' = (1.0-`fac')/colsof(`p') ;
   sca `fac2' = `fac1' - `fac' ;
   mat `ptry' = `p'[`ihi',1...] ;
   mat `ptmp' = `ptry'*`fac2'   ;
   mat `mtmp' = `psum'*`fac1'    ;
   mat `ptry' = `mtmp' - `ptmp'  ;
   `obj' `ptry' `ytry'          ;
   if `ytry' > `y'[1,`ihi'] {   ;
      mat `mtmp' = J(1,1,`ytry')   ;
      mat sub `y'[1,`ihi'] = `mtmp' ;
      mat sub `p'[`ihi',1] = `ptry' ;
     } ;
 end ;
