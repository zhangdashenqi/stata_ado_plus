capture program drop viblidb
program define viblidb 
  syntax , [b0(real 0) b1(real 1) b2(real 1) b12(real 0) b0_inc(real .1) ///
            b1_inc(real .1)  b2_inc(real .1) b12_inc(real .1) ///
            ccmin(real -4) ccmax(real 4) ccat(real 0) ccinc(real .1) ///
            x1name(string) x2name(string) *]

/************************************************
  Initial values for the dynamic control panel
************************************************/
  global DB_b0 = `b0'
  global DB_b0_inc = `b0_inc'
  global DB_b1 = `b1'
  global DB_b1_inc = `b1_inc'
  
  global DB_b2 = `b2'
  global DB_b2_inc = `b2_inc'
  global DB_b12 = `b12'
  global DB_b12_inc = `b12_inc'

  global DB_cc = `ccat'
  global DB_cc_inc = `ccinc'
  global DB_clow = `ccmin'
  global DB_chigh = `ccmax'
  
  if ("`x1name'" == "") {
  global DB_x1_lab = "x1"
  	}
  else {
  global DB_x1_lab = "`x1name'"
	}


  if ("`x2name'" == "") {
  global DB_x2_lab = "x2"
  	}
  else {
  global DB_x2_lab = "`x2name'"
	}


/*************************************************
  Panel selection parameters
*************************************************/

  global DB_p1 = 1
  global DB_p2 = 0
  global DB_p3 = 0
  global DB_p4 = 0
 
/*************************************************
  Initializing and setting up the dialog window 
*************************************************/

  global DB_ccplots = 0
  global DB_logit = 0
  global DB_prob = 1
  global DB_v7 = 1
  global DB_v8 = 0
  global DB_cck = 0
  
  db _vibli

  vibligraph, b0($DB_b0) b1($DB_b1) b2($DB_b2) b12($DB_b12) ccmin($DB_clow) ccmax($DB_chigh) ///
                      ccat($DB_cc) v7 type(1) abcd x1name($DB_x1_lab) x2name($DB_x2_lab) saving(g1, replace)

end
  
