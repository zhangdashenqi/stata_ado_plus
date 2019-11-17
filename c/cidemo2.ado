*! revised to version 8.2, 1/24/04, mnm
*! version 1.0 created 9/16/00
capture program drop cidemo2
program define cidemo2
  version 6.0

  if "`0'"=="" {
    local ssize = 25
  }
  else {
    gettoken pre 0: 0, parse(,)
    tokenize `pre'
    local ssize = `1'

    syntax [ , LEVel(numlist integer) SAMples(integer 100)]
  }

  if "`level'" == "" {
    local level = 95
  }
  if "`samples'" == "" {
    local samples = 100
  }

  preserve
  drop _all // mnm changed from clear
  tempname tn tn1 tadj
  scalar `tn1' = `ssize' - 1
  global Samp_N = `ssize'
  simul cisamp, reps(`samples') 
  generate sample = _n

  numlist "`level'"
  tokenize `r(numlist)'

  while ("`1'" != "") {
    local cl = `1'
    scalar `tadj' = invt(`tn1',(`cl'/100) )
    capture drop se
    quietly generate se = `tadj'*s/sqrt(n)

    quietly capture drop ul ll sig
    gen ul = m+se
    gen ll = m-se
    gen sig = (ul < 50) | (ll > 50)
    qui count if sig
    local tot = r(N)

    version 8.2: twoway rspike ll ul sample, ///
       ylabel(20 30 to 80) xlabel(1 10 20 to `samples') yline(50) ytitle("") ///
       subtitle("`cl'% Confidence Intervals for mean = 50, sd = 10, n = $Samp_N") ///
       caption("intervals not including population mean: `tot'") 

    if "`2'" != "" {
      sleep 1000
    }
    mac shift
  }

end

exit
