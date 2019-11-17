*! Log likelihood for confa: linear form; part of confa suite; 16 Oct 2008
program define confa_lf

   args lnf $CONFA_args
   * $CONFA_args contains the names of the equations, but
   * we need the variable names
   gettoken lnf allthenames : 0

   tempvar lnl
   qui g double `lnl' = .

   mata: CONFA_NormalLKHDr( "`allthenames'", "`lnl'")

   qui replace `lnf' = `lnl'

   if $CONFA_loglevel > 3 li `lnl'

end

exit
