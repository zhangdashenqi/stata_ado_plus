*! version 1.0.0  07/19/94                              (STB-25: sg39)
program define iptab
  version 3.1
  local varlist "req ex min(3) max(3)"      /*there must be 3 vars*/
  local if "noprefix"
  local options "Wrap noFreq"               /*default is no wrap, freq*/
  parse "`*'"
  if "`if'"=="" {                           /*_if_ exp is required*/
          di in red "You must specify the if expression"
          exit 198
  }
  parse "`varlist'", parse(" ")
  tempvar target nonmiss
  gen `target'=`if' & `3'~=.                /*target is an indicator var.
                                              showing that an obs. contains the
                                              response of interest (target)*/
  gen `nonmiss'=(`1'~=. & `2'~=. & `3'~=.)  /*nonmiss is an indicator var.
                                              showing that an obs. contains
                                              values for all vars in varlist:
                                              `1' is the item var.;
                                              `2' is the group var.;
                                              `3' is the response var.*/
  tempvar numer denom pct
  qui egen `numer'=sum(`target'), by(`1' `2')   /*find the no. of target
                                                  resps. for each cell in
                                                  the item x group table*/
  qui egen `denom'=sum(`nonmiss'), by(`1' `2')  /*find the no. of nonmissing
                                                  obs. for each cell in the
                                                  item x group table*/
  qui gen `pct'=(`numer'/`denom')*100           /*express numer/denom as % */
  qui format `pct' %4.1f                        /*display pct with 1 decimal*/
  tab `1' `2' if `target'==1, summ(`pct') nost `wrap' `freq'
  /*all target obs. for each combination of item (`1') and group (`2') contain
    the same value of `pct'; _summarize_ therefore finds the means of
    item x group sets of identical values.  There being no within-cell
    variability, the nost option is fixed. */

end
