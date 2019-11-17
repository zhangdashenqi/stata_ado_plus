capture program drop viblmdb
program define viblmdb 
  syntax , [b0(real 0) b1(real 1) b0_inc(real .1) b1_inc(real .1)  ///
            xat(real 0)  xinc(real 1) xmin(real 0) xmax(real 1) ///
            ccmin(real -4) ccmax(real 4) ccat(real 0) ccinc(real .1) xname(string) *]

/************************************************
  Initial values for the dynamic control panel
************************************************/
  global DB_b0 = `b0'
  global DB_b0_inc = `b0_inc'
  global DB_b1 = `b1'
  global DB_b1_inc = `b1_inc'
  
  global DB_cc = `ccat'
  global DB_cc_inc = `ccinc'
  global DB_clow = `ccmin'
  global DB_chigh = `ccmax'
  
  global DB_xat = `xat'
  global DB_xinc = `xinc'
  global DB_xmin = `xmin'
  global DB_xmax = `xmax'


 if ("`xname'" == "") {
  global DB_x_lab = "x"
  	}
  else {
  global DB_x_lab = "`xname'"
	}

/*************************************************
  Panel selection parameters
*************************************************/
  global DB_pall = 0
  global DB_p1 = 1
  global DB_p2 = 0
  global DB_p3 = 0
 
/*************************************************
  Initializing and setting up the dialog window 
*************************************************/

  global DB_ccplots = 0
  global DB_logit = 0
  global DB_prob = 1
  global DB_v7 = 1
  global DB_v8 = 0
  global DB_cck = 0
  
  db _viblm

  viblmgraph, b0($DB_b0) b1($DB_b1) ccmin($DB_clow) ccmax($DB_chigh) ccat($DB_cc) ///
                      v7 type(1) ab xname($DB_x_lab) saving(g1, replace)

end
  
