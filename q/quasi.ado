*! Version 4.0.0  STB-38 sg71
#delimit ;
version 4.0;
capture program drop quasi;
program define quasi;
version 4.0;
  tempname delta fp fae fad fac df xi hdg zeps
           fac1 fae1 dg hdg xmin fy gstep toler gt xold dx xtol;
   if "`1'"=="" {;
      di in g _n "quasi" in w _n(2)
      _col(10) "quasi [obj xin yout xout [g h gstep itmax toler bhhh]]" in y _n
      _col(5) "MAXimize the function " in w "obj " in y _n
      _col(5) "starting at the ROW vector " in w "xin " in y _n
      _col(5) "report max value in scalar " in w "yout " in y _n
      _col(5) "report max vector in " in w "xout " in y _n
      _col(5) "report gradient in " in w "g " in y _n
      _col(5) "report hessian in " in w "h " in y _n
      _col(5) "call to obj is the form " in w "obj x y [objvar]" in y _n(2);
              exit;
      };
  gl qfunc = "`1'";
  loc xsend = "`2'";
  gl qnames : colnames(`xsend');
  gl qeqnms : coleq(`xsend');
  loc fy = "`3'";
  loc xout = "`4'";
  if "`5'" == "" | "`5'"=="."{;  tempname g;}; else {;loc g = "`5'";  };
  if "`6'" == "" | "`6'"=="."{; tempname h;  }; else {; loc h = "`6'";};
  if "`7'"=="" | "`7'"=="." {; sca `gstep' = 1E-5;};  else {; sca `gstep' = `7';}; 
  if "`8'"=="" | "`8'"=="." {; loc itmax = 100;};  else    {; loc itmax = `8';};
  if "`9'"=="" | "`9'"=="." {; sca `toler' = 1E-6;}; else  {; sca `toler' = `9';}; 
  if "`10'"=="" | "`10'"=="." {; gl bhhh = ""; }; else  {; gl bhhh = "y";};
  mat `xout' = `xsend';
  $qfunc `xout' `fp';
  di _n in b _dup(20) "-" in w " Starting Quasi " in b _dup(20) "-";
  mat l `xout', t(Starting values) format(%9.5f);
  di in b "Starting value of $qfunc: " in y %9.5f `fp';
  sca `fy' = `fp';
  sca `zeps' = 1E-5;
  sca `xtol' = 1E-8;
  loc NP = colsof(`xsend');
  mat `h' = I(`NP');
  mat rownames `h' = $qnames;
  mat roweq `h'    = $qeqnms;
  mat colnames `h' = $qnames;
  mat coleq `h'    = $qeqnms;
  fgrad $qfunc `xout' `g' `gstep' `h';
  loc iter = 0;
  loc fail = 0;
  sca `dx' = `xtol' + 1;
  sca `df' = 1/max(abs(`fy'),`zeps');
  mat `gt' = `df'*`g';
  sca `df' = abs(`gt'[1,1]);
  loc i = 2;
  while `i' < `NP'
        {;
        if `df' < abs(`gt'[`i',1]) {; sca `df' = abs(`gt'[`i',1]); };
        loc i = `i' + 1;
        };
  sca `delta' = `df';
  while (`fail'<1) & (`iter'<=`itmax') & (`delta' > `toler')
        & (`dx' > `xtol') {;
        mat `xold' = `xout';
        di in b "." _cont;
        sca `fp' = `fy';
*                          line minimization ;
        mat `xi' = `g''*`h';       * row rather than column vector;
        mat `xi' = -1 * `xi';
        mat p_linmin = `xout';
        mat x_linmin = `xi';
        golden `xmin' `fy';
        mat `xi' = `xmin' * `xi';
        mat `xout' = `xout' + `xi';
        mat colnames `xout' = $qnames;
        mat coleq    `xout' = $qeqnms;
*                .          update hessian ;
        mat `dg' = `g';
        fgrad $qfunc `xout' `g' `gstep' `h';
        mat rownames `g' = $qnames;
        mat roweq    `g' = $qeqnms;
        if "`bhhh'"=="" {;
          mat `dg' = `g'-`dg';  * 0 on first interation;
          mat `hdg' = `h'*`dg';
          mat `fac1' = `xi' * `dg' ; mat `fae1' = `hdg'' * `dg';
          sca `fac' = `fac1'[1,1]; sca `fae' = `fae1'[1,1];
          if (abs(`fac')>1E-14) & (abs(`fae')>1E-14) {;
             sca `fac' = 1.0/`fac'; sca `fad' = 1.0/`fae';
             mat `dg' = `fac'*`xi'; mat `dg' = `dg'';
             mat `gt' = `fad'*`hdg';
             mat `dg' = `dg' - `gt';
             mat `xi' = `xi''*`xi'; mat `xi' = `fac'*`xi';
             mat `dg' = `dg'*`dg''; mat `dg' = `fae'*`dg';
             mat `hdg' = `hdg'*`hdg''; mat `hdg' = `fad'*`hdg';
             mat `h' = `h' + `xi';
             mat `h' = `h' - `hdg';
             mat `h' = `h' + `dg';
             };
           else {; loc fail = 1; };
          };
        loc iter = `iter' + 1;
*          calculate deltas;
        sca `df' = 1/max(abs(`fy'),`zeps');
        mat `gt' = `df'*`g';
        sca `df' = abs(`gt'[1,1]);
        sca `dx' = abs(`xold'[1,1]-`xout'[1,1]);
        loc i = 2;
        while `i' < `NP'
           {;
           if `dx' < abs(`xold'[1,`i']-`xout'[1,`i']) {; sca `dx' = abs(`xold'[1,`i']-`xout'[1,`i']); };
           if `df' < abs(`gt'[`i',1]) {; sca `df' = abs(`gt'[`i',1]); };
           loc i = `i' + 1;
           };
        sca `delta' = `df';
        sca `df' = abs(`fy'-`fp')/max(abs(`fy'),`zeps');
    };
   if (`delta'>`toler') {;
      if (`fail'==1) {; di in r " STEP fail - try restart ";};
      if (`dx' <= `xtol') {; di in r "Change in vector ended - try restart"; };
      };
   di _n     in b _col(5)  "Value of $qfunc"
                 _col(30) "Gradient Size"
                 _col(50) "Iterations" _n
            in y _col(5)  %8.5f `3'
                 _col(30) %5.3e `delta'
                 _col(50) %3.0f `iter';
   mat l `4', t(Quasi final values stored in `4') format(%9.5f);
   di _n in b _dup(20) "-" in w " Ending Quasi " in b _dup(20) "-" _n;
  capture mat drop x_linmin p_linmin;
  capture global drop qfunc;
end;

cap program drop ffunc;
program define ffunc;
version 4.0;
  tempname xt;
  loc x = "`1'";
  loc ff = "`2'";
  mat `xt' = `x'*x_linmin;
  mat `xt' = p_linmin + `xt';
  mat colnames `xt' = $qnames;
  mat coleq    `xt' = $qeqnms;
  $qfunc `xt' `ff';
end;

capture program drop mnbrak;
program define mnbrak;
version 4.0;
  tempname tiny  glimit ulim u r q fu dum gold ;
  loc ax = "`1'";
  loc bx = "`2'";
  loc cx = "`3'";
  loc fa = "`4'";
  loc fb = "`5'";
  loc fc = "`6'";
  sca `tiny' =    1.0e-20;
  sca `glimit'  = 10.0;
  sca `gold'  =   1.61803399;
  loc itmax = 100;
  ffunc `ax' `fa';
  ffunc `bx' `fb';
  if `fb' < `fa' {;
     sca `dum' = `ax';
     sca `ax' = `bx';
     sca `bx' = `dum';
     sca `dum' =`fb';
     sca `fb' = `fa';
     sca `fa' = `dum';};
  sca `cx' = `bx'+`gold'*(`bx'-`ax');
  ffunc `cx' `fc';
  loc iter = 0;
  while (`fb' <= `fc') & (`iter'<=`itmax') {;
        sca `r' = (`bx'-`ax')*(`fb'-`fc');
        sca `q' = (`bx'-`cx')*(`fb'-`fa');
        sca `dum' = -sign(`q'-`r') * max(abs(`q'-`r'),`tiny');
        sca `u' = `bx' -((`bx'-`cx')*`q'-(`bx'-`ax')*`r')/(2.0*`dum');
        sca `ulim' = `bx'+`glimit'*(`cx'-`bx');
        if (`bx'-`u')*(`u'-`cx') > 0.0 {;
           ffunc `u' `fu';
           if `fu' > `fc' 
              {; sca `ax' = `bx'; sca `fa' = `fb'; sca `bx' = `u';  sca `fb' = `fu';exit; };
           else {; if `fu' < `fb' {;sca `cx' = `u';sca `fc' = `fu'; exit;};};
           sca `u' = `cx'+`gold'*(`cx'-`bx');
           ffunc `u' `fu';
           };
        else {; if (`cx'-`u')*(`u'-`ulim') > 0.0 
                  {; ffunc `u' `fu';
                     if `fu' > `fc' 
                       {; sca `bx' = `cx'; sca `cx' = `u';
                          sca `u' = `cx'+`gold'*(`cx'-`bx');
                          sca `fb' = `fc'; sca `fc' = `fu'; 
                          ffunc `u' `fu';};
                     else {; if (`u'-`ulim')*(`ulim'-`cx') >= 0.0 
                             {;sca `u' = ulim; ffunc `u' `fu'; };};
                   };
               else  {;sca `u' = `cx'+`gold'*(`cx'-`bx'); ffunc `u' `fu';};
               sca `ax' = `bx'; 
               sca `bx' = `cx';
               sca `cx' = `u'; 
               sca `fa' = `fb'; 
               sca `fb' = `fc'; 
               sca `fc' = `fu';
             };
        loc iter = `iter' + 1;
        };
     if `iter' > `itmax' {; di in r "mnbrak failed"; };
   end;

capture program drop golden;
program define golden;
version 4.0;
tempname c rgold f1 f2 x0 x1 x2 x3 ax bx cx tol xx fa fx fb;
  loc xmin = "`1'";
  loc gold = "`2'";
  sca  `rgold' =  0.61803399;
  sca `tol' = 1.0e-2;
  sca `ax' = 0.0; 
  sca `bx' = 0.2;
  loc iter = 0;
  loc itmax = 100;
  mnbrak `ax' `bx' `xx' `fa' `fb' `fx';
  sca `c' = 1.0-`rgold';   sca `x0' = `ax'; sca `x3' = `xx';
  if abs(`bx'-`xx') > abs(`xx'-`ax')
    {; sca `x1' = `xx'; sca `x2' = `xx' + `c'*(`bx'-`xx'); };
  else
    {; sca `x2' = `xx'; sca `x1' = `xx' - `c'*(`xx'-`ax');};
  ffunc `x1' `f1'; ffunc `x2' `f2';
  while (`iter'<=`itmax') & (abs(`x3'-`x0') > `tol'*(abs(`x1')+abs(`x2')) ) {;
        if `f2' > `f1'
           {; sca `x0' = `x1'; sca `x1' = `x2'; 
              sca `x2' = `rgold'*`x1'+`c'*`x3';
              sca `f1' = `f2';  ffunc `x2' `f2';};
        else
           {; sca `x3' = `x2';sca `x2' =`x1';
              sca `x1' =`rgold'*`x2'+`c'*`x0';
              sca `f2' =`f1'; ffunc `x1' `f1'; };
        loc iter = `iter' + 1;
        };
  if `f1' > `f2'
     {; sca `gold' = `f1'; sca `xmin' = `x1'; };
  else
     {; sca `gold' = `f2'; sca `xmin' = `x2';};
end;

capture program drop fgrad;
program define fgrad;
* compute gradient and (if bhhh exists) the inverse of its outer product;
version 4.0;
  tempname eps mneps mdelta delta l1 di gx;
  loc obj = "`1'";
  loc x = "`2'";
  loc g = "`3'";
  sca `eps' = `4';
  loc h = "`5'"; 
  sca `mneps' = 1E-7;
  loc NP = colsof(`x');
  mat `mdelta' = I(`NP');
  loc m = 1;
  if "$bhhh" != "" {;
    tempvar agop1 hh;
    while `m' <= `NP' {;
      loc gn = "gop`m'";
      tempvar `gn';
      mat `delta' = `mdelta'[`m',1...];
      sca `di' = max(abs(`x'[1,`m'])*`eps',`mneps');
      mat `delta' = `delta'*`di';
      mat `gx' = `x' + `delta';
      mat colnames `gx' = $qnames;
      mat coleq    `gx' = $qeqnms;
      `obj' `gx' `l1' `agop1';
      mat `gx' = `x' - `delta';
      mat colnames `gx' = $qnames;
      mat coleq    `gx' = $qeqnms;
      `obj' `gx' `l1' ``gn'';
      qui replace ``gn'' = (`agop1'-``gn'')/(2*`di');
      loc m = `m' + 1;
       };
    qui drop `agop1';
    qui gen byte `agop1' = 1;
    qui mat vecaccum `g' = `agop1' `gop1'-``gn'', noconstant;
    mat `g' = `g'';
    qui mat accum `hh' = `gop1'-``gn'', noconstant;
    qui mat `h' = syminv(`hh');
    };
  else {;
    tempname d dd l2;
    while `m' <= `NP' {      ;
      mat `delta' = `mdelta'[`m',1...]  ;
      sca `di' = max(abs(`x'[1,`m'])*`eps',`mneps') ;
      mat `delta' = `delta'*`di'  ;
      mat `gx' = `x' + `delta'     ;
      mat colnames `gx' = $qnames;
      mat coleq    `gx' = $qeqnms;
      `obj' `gx' `l1'          ;
      mat `gx' = `x' - `delta'   ;
      mat colnames `gx' = $qnames;
      mat coleq    `gx' = $qeqnms;
      `obj' `gx' `l2'         ;
      sca `dd' = (`l1' - `l2')/(2*`di') ;
      mat `d' = J(1,1,`dd')     ;
      if `m'==1 {; mat `g' = `d'; }; else {; mat `g' = `g' \ `d'; };
      loc m = `m' + 1;
      };
    };
  end  ;
