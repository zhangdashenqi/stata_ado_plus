!* version 1.0 -- 4/6/07 -- pbe
!* version .95 -- 10/4/06, 9/6/06 -- pbe
program define fpower, rclass
version 9.2

/*------------------------------------------------------------------*/
/*    Based on the SAS macro program, FPOWER.SAS (version 1.2)      */
/*    Created 1990, revised 1995                                    */
/*    SAS author:  Michael Friendly   <FRIENDLY@YorkU.CA>           */
/*------------------------------------------------------------------*/

/*------------------------------------------------------------------*/
/*    delta = (largest-smallest)/sigma                              */
/*    where delta = .25 small, .75 medium, 1.25 large               */
/*                                                                  */
/*    a --          Levels of factor A (no default)                 */
/*    b --          Levels of crossed factor B (default=1)          */
/*    c --          Levels of crossed factor C (default=1)          */
/*    For more than 3 factors, make C=product of # of               */
/*        levels of factors D, E, ...                               */
/*    r --        Levels of repeated measure factor (default=1)     */
/*    alpha -- Significance level of test of factor A (default=.05) */
/*    rho --      Intraclass correlation for repeated (default=0)   */
/*------------------------------------------------------------------*/

syntax , a(integer) [ b(integer 1) c(integer 1) r(integer 1) ///
         rho(real 0) alpha(real .05) delta(real .25) n(integer 1) ///
         graph ]

/* tempvar n errdf */

local trtdf = `a' - 1
local prob = 1 - `alpha'

preserve 

clear

  quietly: {
    set obs 27
    gen nobs = _n + 1
    replace nobs = _n*2 - 8 in 10/14
    replace nobs = _n*5 - 50 in 15/22
    replace nobs =  75 in 23
    replace nobs = 100 in 24
    replace nobs = 125 in 25
    replace nobs = 150 in 26
    replace nobs = `n' in 27
  }
  if nobs == 1 in l {
    drop in l
  }

generate nc = nobs*`b'*`c'*`r'*`delta'^2/(2*(1+(`r'-1)*`rho'))

generate errdf = (`a'*`b'*`c'*(nobs-1))
generate fcrit = invF(`trtdf', errdf, `prob')
display
display as txt "a = ", `a', "  b = ", `b', "  c = ", `c', "  r = ", `r', "  rho = ", `rho', "  delta = ", `delta'

generate power = nFtail(`trtdf', errdf, nc, fcrit)
quietly replace power=1 if nc>140

clist nobs power, noobs

if "`graph'"~="" {
    twoway line power nobs, yline(.8) scheme(s1mono) ///
           title("Power Graph -- delta = `delta'")
}

drop nobs nc errdf fcrit power

end

