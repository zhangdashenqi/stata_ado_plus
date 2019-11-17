*! revised to version 8.2, 1/24/04, mnm
*! revised 5/11/00
capture program drop cidemo
program define cidemo
  version 6.0
  args ssize level

  if "`ssize'" == "" { local ssize = 25 }
  if "`level'" == "" { local level = .95 }

  preserve
  drop _all // mnm changed clear to drop _all
  tempname tn tn1 tadj
  scalar `tn1' = `ssize' - 1
  local conf = `level'*100
  global Samp_N = `ssize'
  simul cisamp, reps(50) 
  generate sample = _n
  scalar `tadj' = invt(`tn1',`level')
  quietly replace s = `tadj'*s/sqrt(n)
  quietly count if ((m + s) < 50) | ((m - s) > 50)
  local tot = r(N)
  gen ul = m + s // mnm added
  gen ll = m - s // mnm added

  * mnm changed graph command
  version 8.2: twoway rcap ul ll sample, ylabel(10 20 to 100) xlabel(1 5 10 to 50) ///
    yline(50) ytitle("") subtitle("`conf'% Confidence Intervals for mean = 50, sd = 10, n = `ssize'") ///
    note("intervals not including population mean: `tot'")
end
* cidemo requires cisamp
exit
