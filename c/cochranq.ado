*! version 1.3.1 27apr2017 by alexis dot dinno at pdx dot edu
*! perform Cochran's Q test for stochastic dominance in blocked binary data 

*   Copyright Notice
*   cochranq and cochranq.ado are Copyright (c) 2014-2017 Alexis Dinno
*
*   This file is part of cochranq.
*
*   cochranq is free software ; you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation; either version 2 of the License, or
*   (at your option) at any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program (paran.copying); if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

* Syntax:  cochranq varname blockid groupid [if exp] [in range],  
*                   [ma(method) noqtest nolabel wrap list level(#) es(method) 
*                   copyleft]

program define cochranq

  if int(_caller())<8 {
    di in r "cochranq- does not support this version of Stata." _newline
    di as txt "Requests for a version compatible with versions of STATA earlier than v8 are "
    di as txt "untenable since I do not have access to the software." _newline 
    di as txt "All requests are welcome and will be considered."
    exit
    }
   else if int(_caller())<14 {
    cochranq8 `0'
    }
   else cochranq14 `0'
end


program define cochranq8, rclass sort
  version 8
  syntax varlist(min=3 max=3 numeric fv) [if] [in] [fweight/], [ma(string) /*
*/               NOQTEST NOLABEL WRAP LIST level(cilevel) es(string) copyleft]

  tokenize `varlist'

* display the copyleft information if requested

  if "`copyleft'" == "copyleft" {
    noisily {
      di _newline "Copyright Notice"
      di "cochranq and cochranq.ado are Copyright (c) 2014-2017 alexis dinno" _newline
      di "This file is part of cochranq." _newline
      di "cochranq is free software ; you can redistribute it and/or modify"
      di "it under the terms of the GNU General Public License as published by"
      di "the Free Software Foundation; either version 2 of the License, or"
      di "(at your option) at any later version." _newline
      di "This program is distributed in the hope that it will be useful,"
      di "but WITHOUT ANY WARRANTY; without even the implied warranty of"
      di "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
      di "GNU General Public License for more details." _newline
      di "You should have received a copy of the GNU General Public License"
      di "along with this program (cochranq.copying); if not, write to the Free Software"
      di "Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA" _newline
      }
    }

  * Validate ma
  if (lower("`ma'") == "" ) {
    local ma = "none"
    }
  if (lower("`ma'") != "none" & lower("`ma'") != "bonferroni" & lower("`ma'") != "sidak" & lower("`ma'") != "holm" & lower("`ma'") != "hs" & lower("`ma'") != "hochberg" & lower("`ma'") != "bh" & lower("`ma'") != "by") {
    noi: di as err "option ma() must be one of none, bonferroni, sidak, hs, hochberg, bh, or by"
    exit 198
    }
  if (lower("`ma'")=="none") {
    local Name = "No adjustment"
    }
  if (lower("`ma'")=="bonferroni") {
    local Name = "Bonferroni"
    }
  if (lower("`ma'")=="sidak") {
    local Name = "Sid{c a'}k"
    }
  if (lower("`ma'")=="holm") {
    local Name = "Holm"
    }
  if (lower("`ma'")=="hochberg") {
    local Name = "Hochberg"
    }
  if (lower("`ma'")=="hs") {
    local Name = "Holm-Sid{c a'}k"
    }
  if (lower("`ma'")=="bh") {
    local Name = "Benjamini-Hochberg"
    }
  if (lower("`ma'")=="by") {
    local Name = "Benjamini-Yekutieli"
    }

  * Validate es
  if (lower("`es'") == "" ) {
    local es = "none"
    }
  if (lower("`es'") != "none" & lower("`es'") != "scm" & lower("`es'") != "bjm") {
    noi: di as err "option es() must be one of none, scm, bjm"
    exit 198
    }
   
  * validate nominal outcome
  qui: inspect `1'
  if (r(N_unique) != 2 | (`1' != 1 & `1' ! = 0)) {
    noi: di as err "the score variable must be nominal data coded 0/1"
    exit 450
    }

  * Validate blockid and groupid
  preserve
    qui: egen _block = group(`2') `if' `in'
    qui: tab _block `if' `in', nofreq
    local b = r(r)
    qui: egen _group = group(`3') `if' `in'
    qui: tab _group `if' `in', nofreq
    local k = r(r)
    forvalues i = 1(1)`b' {
      qui: count if _block == `i'
      if (r(N) != `k') {
        di as err "the number of groups is not the same for each block"
        exit 459
        }
      }
    if ("`weight'" == "fweight") {
      local equals = "="
      }
    if ("`weight'" != "fweight") {
      local equals = " "
      }
    quietly {
      sum(`1') `if' `in' [`weight' `equals' `exp'], meanonly
      local Total = r(sum)
      local Tbar = `Total'/`k'
      mata: numerator = rangen(.,.,`k')
      forvalues j = 1(1)`k' {
        sum(`1') if _group == `j' [`weight' `equals' `exp']
        local Tj = r(sum)
        mata: numerator[`j'] = (`Tj' - `Tbar')^2
        }
      mata: st_numscalar("_numerator", sum(numerator))
      }
    qui: _A 1 `1' _block `weight' `exp'
    local A1 = r(Am)
    qui: _A 2 `1' _block `weight' `exp'
    local A2 = r(Am)
    qui: _A 3 `1' _block `weight' `exp'
    local A3  = r(Am)
    qui: _A 4 `1' _block `weight' `exp'
    local A4  = r(Am)
    qui: _A 5 `1' _block `weight' `exp'
    local A5  = r(Am)
    qui: _A 6 `1' _block `weight' `exp'
    local A6  = r(Am)
    local Q = `k'*(`k'-1)*_numerator/(`k'*`A1' - `A2')
    local muQ = `k'-1
    local B1  = (`k'^2)*((`A1'^2) - `A2') - (2*`k'*((`A1'*`A2') - `A3')) + ((`A2'^2) - `A4')
    local B2  = (`k'^4)*(`A1'^2-`A2') - 6*(`k'^3)*((`A1'*`A2') - `A3') + (`k'^2)*((4*`A1'*`A3')+(9*(`A2'^2))-(13*`A4')) - (12*`k'*((`A2'*`A3')-`A5')) + (4*((`A3'^2)-`A6'))
    local B3  = ((`k'^3)*((`A1'^3)-(3*`A1'*`A2') + (2*`A3'))) - (3*(`k'^2)*(((`A1'^2)*`A2') - (2*`A1'*`A3') - (`A2'^2) + (2*`A4'))) + (3*`k'*((`A1'*(`A2'^2)) - (`A1'*`A4') - (2*`A2'*`A3') + (2*`A5'))) - ((`A2'^3) - (3*`A2'*`A4') +(2*`A6'))
    if (`k' == 2) {
      local K3  = ((4*(`k'-1))/(((`k'*`A1')-`A2')^3))*(2*`B3')
      }
    if (`k' >= 3) {
      local K3  = ((4*(`k'-1))/(((`k'*`A1')-`A2')^3))*(((`k'-1)/(`k'-2))*`B2'+2*`B3')
      }
    local s2Q = (2*`muQ'*`B1')/(((`k'*`A1')-`A2')^2)
    local gQ  = `K3'/(sqrt(`s2Q')^3)
    local Z   = (`Q' - `muQ')/sqrt(`s2Q')
    qui: _pPIII `Z' `gQ'
    local p2 = 1- r(p)
    if (`Q' < 10) {
      local Qformat = "%7.4f"
      } 
    if (`Q' >= 10 & `Q' < 100) {
      local Qformat = "%8.4f"
      } 
    if (`Q' >= 100) {
      local Qformat = "%9.4f"
      } 
    if (`gQ' < 10) {
      local gQformat = "%7.4f"
      } 
    if (`gQ' >= 10 & `Q' < 100) {
      local gQformat = "%8.4f"
      } 
    if (`gQ' >= 100) {
      local gQformat = "%9.4f"
      } 
    if (`Z' < 10) {
      local Zformat = "%7.4f"
      } 
    if (`Z' >= 10 & `Q' < 100) {
      local Zformat = "%8.4f"
      } 
    if (`Z' >= 100) {
      local Zformat = "%9.4f"
      } 
    qui: ds `1'
    local blockname = r(varlist)

    if (lower("`es'")=="bjm") {
      qui: egen _score = group(`1') `if' `in'
      mkmat _score _block _group, matrix(X)
      qui: drop _score
      local delta = 0
      forvalues i = 1/`k' {
        forvalues j = 1/`=`b'-1' {
          forvalue l = `=`j'+1'/`b' {
            local delta = `delta' + abs(X[`= `b'*(`i'-1) + `j'',1] - X[`=`b'*(`i'-1) + `l'',1])
            }
          }
        }
      local delta = `delta' / ( `k' * (`b'*(`b'-1)/2) )
      local mudelta = 0
      local p_i =0
      local SUMp_i = 0
      local SUMvarp_i = 0
      forvalues i = 1/`=`k'*`b'' {
        local SUMp_i = `SUMp_i' + `1'[`i']
        }
      forvalues i = 1/`b' {
        forvalues j = 1/`k' {
          local p_i = `p_i' + `1'[`=`i'+ `b'*(`j'-1)']
          }
        local p_i = `p_i'/`k'
        local SUMvarp_i = `SUMvarp_i' + (`p_i'*(1-`p_i'))
        local p_i = 0
        }
      local SUMp_i = `SUMp_i'/`k'
      local mudelta = (2/(`b'*(`b'-1))) * ( (`SUMp_i'*(`b'-`SUMp_i')) - `SUMvarp_i')
      qui: matrix drop X
      }
      qui: drop _block _group

    if ("`noqtest'" == "") {
      if "`nolabel'" == "" {
        local nl = 0
        local labelname : value label `2'
        if ("`labelname'" == "") {
          local nl = 1
          }
         else {
          mata: st_vlload("`labelname'", values = ., text = "")
          mata: st_local("testvalue", strofreal(length(values)))
          }
        if ("`testvalue'"!="`b'") {
          di as res _newline "Warning: {it:`3'} values are unlabeled or incompletely labeled, option nolabel implicit" _newline
          local nl = 1
          }
        }
      if "`nolabel'" == "nolabel" {
        local nl = 1
        }
      noi: di _newline as txt "Cochran's Q test for stochastic dominance in blocked binary data" _newline
      noisily _cochranqheader `2'
      forvalues i = 1/`b' {
        noi: _cochranqbody `if', index(`i') blockvar(`2') scorevar(`1') nl(`nl') weight(`weight') exp(`exp')
        }
      noi: _cochranqfooter `2'
      noi: di _newline as txt "Cochran's Q =" as res `Qformat' `Q' as txt " with df = " as res `k'-1 _newline
      if (lower("`es'") == "scm") {
        noi: di as text "Maximum-corrected effect size {it:Q}/[{it:b}({it:k}-1)] = " as res %-7.4f `=`Q'/(`b'*(`k'-1))' _newline as text "  (per Serlin, Carr and Marascuillo)"  
        }
      if (lower("`es'") == "bjm") {
        noi: di as text "Chance-corrected effect size {it:R} = " as res %-7.4f `=1 - (`delta'/`mudelta')' _newline as text "  (per Berry, Johnston and Mielke)"  
        }
      noi: di _newline as txt "Asymptotic test:"
      noi: di " P(Q >=" as res `Qformat' `Q' as txt ") =" as res %7.4f  1 - chi2(`k'-1,`Q')
      noi: di _newline as txt "Non-asymptotic test:" 
      noi: di as txt "    Z =" as res `Zformat' `Z' 
      noi: di as txt "gamma =" as res `gQformat' `gQ' 
      noi: di as txt " P(Q >=" as res `Qformat' `Q' as txt ") =" as res %7.4f `p2'
      }

      if "`noqtest'" == "noqtest" {
        if "`nolabel'" == "" {
          local nl = 0
          local labelname : value label `3'
          if ("`labelname'" == "") {
            local nl = 1
            }
           else {
            mata: st_vlload("`labelname'", values = ., text = "")
            mata: st_local("testvalue", strofreal(length(values)))
            }
          if ("`testvalue'"!="`k'") {
            di as res _newline "Warning: {it:`3'} values are unlabeled or incompletely labeled, option nolabel implicit" _newline
            local nl = 1
            }
          }
        if "`nolabel'" == "nolabel" {
          local nl = 1
          }
		}

    di _newline as txt %~76s "Comparison of `1' by `3'"
    di as txt %~76s "(`Name')"
    local colhead = ""
    local kminusone = `k'-1
    capture confirm numeric variable `3'
    if (!_rc) {
      local groupisnum = 1
      }
     else {
      local groupisnum = 0
      }
    qui: levelsof `3'
    local groupvalues = r(levels)
    local m = `k'*(`k'-1)/2
    matrix X2 = J(1,`m',0)
    matrix P = J(1,`m',0)
    matrix naP = J(1,`m',0)
    matrix Reject   = J(1,`m',0)
    matrix naReject = J(1,`m',0)
    if ("`weight'" == "") {
      local fweight = ""
      }
    if ("`weight'" != "") {
      local fweight = "[fw = `exp']"
      }
    
    forvalues i = 2/`k' {
      local iminusone = `i'-1
      forvalues j = 1/`iminusone' {
		local itest = word("`groupvalues'",`i')
		local jtest = word("`groupvalues'",`j')
	    if ("`if'" != "") {
          capture _cochranq `1' `2' `3' `if' & (`3' == `itest' | `3' == `jtest') `fweight'
          if (_rc == 2000) {
            local x2 = .
            local p = .
            local nap = .
            }
          if (_rc != 2000) {
            qui: _cochranq `1' `2' `3' `if' & (`3' == `itest' | `3' == `jtest') `fweight'
            local x2 = r(Q)
            local p = r(p_asymp)
            local nap = r(p_nonasymp)
            }
          }
        if ("`if'" == "") {
          capture _cochranq `1' `2' `3' if (`3' == `itest' | `3' == `jtest') `fweight'
          if (_rc == 2000) {
            local x2 = .
            local p = .
            local nap = .
            }
          if (_rc != 2000) {
            qui: _cochranq `1' `2' `3' if (`3' == `itest' | `3' == `jtest') `fweight'
            local x2 = r(Q)
            local p = r(p_asymp)
            local nap = r(p_nonasymp)
            }
          }

        * Static multiple comparisons adjustments
        if (lower("`ma'") == "bonferroni") {
          if (`p' != .) {
            local p = min(1,`p'*`m')
            }
          if (`nap' != .) {
            local nap = min(1,`nap'*`m')
            }
          }
        if (lower("`ma'") == "sidak") {
          if (`p' != .) {
            local p = min(1,1 - (1-`p')^`m')
            }
          if (`nap' != .) {
            local nap = min(1,1 - (1-`nap')^`m')
            }
          }
        local index = ((`i'-2)*(`i'-1)/2) + `j'
        matrix X2[1,`index'] = `x2'
        matrix P[1,`index'] = `p'
        matrix naP[1,`index'] = `nap'
        local alpha = (100 - `level')/100
		if el(P,1,`index') <= `alpha'/2 {
		  matrix Reject[1,`index'] = 1
		  }
		if el(naP,1,`index') <= `alpha'/2 {
		  matrix naReject[1,`index'] = 1
		  }
        }
      }
    * Sequential multiple comparrisons adjustments
    quietly {
      local alpha = (100 - `level')/100
      if (lower("`ma'")=="holm") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps   = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort   = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust = (`m'-numbermissing)+1-`i'
          local naadjust = (`m'-nanumbermissing)+1-`i'
          mata: Psort[1,`i']   = min((1,Psort[1,`i']   :* `adjust' ))  *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust')) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = 1/`m' {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' > 1) {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) & Psort[3,`i'-1]   != 0
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) & naPsort[3,`i'-1] != 0
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="hs") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust = (`m'-numbermissing)+1-`i'
          local naadjust = (`m'-numbermissing)+1-`i'
          mata: Psort[1,`i']   = min((1,(1 - ((1 - Psort[1,`i'])   :^ `adjust'   )))) *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,(1 - ((1 - naPsort[1,`i']) :^ `naadjust' )))) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = 1/`m' {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' > 1) {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) & Psort[3,`i'-1]   != 0
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) & naPsort[3,`i'-1] != 0
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="hochberg") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps   = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort   = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust = (`m'-numbermissing)+1-`i'
          local naadjust = (`m'-nanumbermissing)+1-`i'
          mata: Psort[1,`i']   = min((1,Psort[1,`i']   :* `adjust' ))  *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust')) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = `m'(-1)1 {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' < `m') {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) | Psort[3,`i'+1] == 1
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) | naPsort[3,`i'+1] == 1
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="bh") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust   = (`m'-numbermissing)/`i'
          local naadjust = (`m'-nanumbermissing)/`i'
          mata: Psort[1,`i'] = min((1, Psort[1,`i']    :*  `adjust'))    *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust' )) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = `m'(-1)1 {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' < `m') {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) | Psort[3,`i'+1] == 1
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) | naPsort[3,`i'+1] == 1
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="by") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        local C = 0
        forvalues i=1/`m' {
          local C = `C' + 1/`i'
          }
        forvalues i = 1/`m' {
          local adjust   = (`m'-numbermissing)*`C'/`i'
          local naadjust = (`m'-nanumbermissing)*`C'/`i'
          mata: Psort[1,`i']   = min((1, Psort[1,`i']  :* `adjust' ))   *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust' )) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = `m'(-1)1 {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' < `m') {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) | Psort[3,`i'+1]   == 1
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) | naPsort[3,`i'+1] == 1
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      }

********************************************************************************
*** OUTPUT
********************************************************************************
  * Need to determine how many tables (reps) to output
  local reps = int((`k'-1)/6)
  local laststart = `reps'*6 + 1

  * Replication loop for >7 groups, no wrap
  if ("`wrap'"=="") {
    if (`k' > 7) {
      forvalues rep = 1/`reps' {
        local colstart = (6*`rep')-5
        local colstop  = 6*`rep'
        if (`nl' == 0) {
          local nolabel = ""
          }
        if (`nl' == 1) {
          local nolabel = "nolabel"
          }
        _mcheader `3' `colstart' `colstop' "`nolabel'" `groupisnum'
        * Table body
        local start = `colstart'+1
        forvalues i = `start'/`k' {
          local colstop = min(`i'-1,6*`rep')
          if (`nl' == 0) {
            local nolabel = ""
            }
          if (`nl' == 1) {
            local nolabel = "nolabel"
            }
          _mcx2table `3' `i' X2 `colstart' `colstop' "`nolabel'" `groupisnum' 
          if (`i' < `k') {
            _mcptable `i' P `colstart' `colstop' Reject 1 0
            _mcptable `i' naP `colstart' `colstop' naReject 0 1
            }
           else {
            _mcptable `i' P `colstart' `colstop' Reject 1 0
            _mcptable `i' naP `colstart' `colstop' naReject 1 1
            }
          }
        }
      * End of table
      if (`laststart' < `k') {
        if (`nl' == 0) {
          local nolabel = ""
          }
        if (`nl' == 1) {
          local nolabel = "nolabel"
          }
        _mcheader `3' `laststart' `kminusone' "`nolabel'" `groupisnum'
        * Table body
        local start = `laststart'+1
        forvalues i = `start'/`k' {
          if (`nl' == 0) {
            local nolabel = ""
            }
          if (`nl' == 1) {
            local nolabel = "nolabel"
            }
          _mcx2table `3' `i' X2 `laststart' `kminusone' "`nolabel'" `groupisnum' 
          if (`i' < `k') {
            _mcptable `i' P `laststart' `kminusone' Reject 1 0
            _mcptable `i' naP `laststart' `kminusone' naReject 0 1
            }
           else {
            _mcptable `i' P `laststart' `kminusone' Reject 1 0
            _mcptable `i' naP `laststart' `kminusone' naReject 1 1
            }
          }
        }
      }

    * Replication loop for <=7 groups
    if (`k' <= 7) {
      if (`nl' == 0) {
        local nolabel = ""
        }
      if (`nl' == 1) {
        local nolabel = "nolabel"
        }
      _mcheader `3' 1 `kminusone' "`nolabel'" `groupisnum'
      * Table body
      forvalues i = 2/`k' {
        local colstop  = `i'-1
        if (`nl' == 0) {
          local nolabel = ""
          }
        if (`nl' == 1) {
          local nolabel = "nolabel"
          }
        _mcx2table `3' `i' X2 1 `colstop' "`nolabel'" `groupisnum' 
        if (`i' < `k') {
          _mcptable `i' P 1 `colstop' Reject 1 0
          _mcptable `i' naP 1 `colstop' naReject 0 1
          }
         else {
          _mcptable `i' P 1 `colstop' Reject 1 0
          _mcptable `i' naP 1 `colstop' naReject 1 1
          }
        }
      }
    }

  * Replication loop for >7 groups, with wrap
  if ("`wrap'"=="wrap") {
    if (`nl' == 0) {
      local nolabel = ""
      }
    if (`nl' == 1) {
      local nolabel = "nolabel"
      }
    _mcheader `3' 1 `kminusone' "`nolabel'" `groupisnum'
    * Table body
    forvalues i = 2/`k' {
      local colstop  = `i'-1
      if (`nl' == 0) {
        local nolabel = ""
        }
      if (`nl' == 1) {
        local nolabel = "nolabel"
        }
      _mcx2table `3' `i' X2 1 `colstop' "`nolabel'" `groupisnum' 
      if (`i' < `k') {
        _mcptable `i' P 1 `colstop' Reject 1 0
        _mcptable `i' naP 1 `colstop' naReject 0 1
        }
       else {
        _mcptable `i' P 1 `colstop' Reject 1 0
        _mcptable `i' naP 1 `colstop' naReject 1 1
        }
      }
    }

  * Output pairwise comparisons as a list if requested.
  if ("`list'"=="list") {
    _cochranqlist `3' X2 naP naReject `k' "`ma'" "`nolabel'"
	}

  * Output level of significance
  local alpha = (100 - `level')/100
  if length("`level'") > 2 {
    local precision = length("`level'") - 1
	}
   else {
    local precision = 2
	}
  di _newline as text "alpha = " as res %6.`precision'f `alpha'

  restore

  * Saves
  ret matrix P_nonasymp  = naP 
  ret matrix P_asymp     = P
  ret matrix X2          = X2
  ret scalar gamma       = `gQ'
  ret scalar Z           = `Z'
  ret scalar p_nonasymp  = `p2'
  ret scalar p_asymp     = 1 - chi2(`kminusone',`Q')
  ret scalar df          = `kminusone'
  ret scalar k           = `k'
  ret scalar b           = `b'
  ret scalar Q           = `Q'

  end

  
program define cochranq14, rclass sort
  version 14
  syntax varlist(min=3 max=3 numeric fv) [if] [in] [fweight/], [ma(string) /*
*/               NOQTEST NOLABEL WRAP LIST level(cilevel) es(string) copyleft]

  tokenize `varlist'

* display the copyleft information if requested

  if "`copyleft'" == "copyleft" {
    noisily {
      di _newline "Copyright Notice"
      di "cochranq and cochranq.ado are Copyright (c) 2014-2017 alexis dinno" _newline
      di "This file is part of cochranq." _newline
      di "cochranq is free software ; you can redistribute it and/or modify"
      di "it under the terms of the GNU General Public License as published by"
      di "the Free Software Foundation; either version 2 of the License, or"
      di "(at your option) at any later version." _newline
      di "This program is distributed in the hope that it will be useful,"
      di "but WITHOUT ANY WARRANTY; without even the implied warranty of"
      di "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
      di "GNU General Public License for more details." _newline
      di "You should have received a copy of the GNU General Public License"
      di "along with this program (cochranq.copying); if not, write to the Free Software"
      di "Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA" _newline
      }
    }

  * Validate ma
  if (lower("`ma'") == "" ) {
    local ma = "none"
    }
  if (lower("`ma'") != "none" & lower("`ma'") != "bonferroni" & lower("`ma'") != "sidak" & lower("`ma'") != "holm" & lower("`ma'") != "hs" & lower("`ma'") != "hochberg" & lower("`ma'") != "bh" & lower("`ma'") != "by") {
    noi: di as err "option ma() must be one of none, bonferroni, sidak, hs, hochberg, bh, or by"
    exit 198
    }
  if (lower("`ma'")=="none") {
    local Name = "No adjustment"
    }
  if (lower("`ma'")=="bonferroni") {
    local Name = "Bonferroni"
    }
  if (lower("`ma'")=="sidak") {
    local Name = "Sid{c a'}k"
    }
  if (lower("`ma'")=="holm") {
    local Name = "Holm"
    }
  if (lower("`ma'")=="hochberg") {
    local Name = "Hochberg"
    }
  if (lower("`ma'")=="hs") {
    local Name = "Holm-Sid{c a'}k"
    }
  if (lower("`ma'")=="bh") {
    local Name = "Benjamini-Hochberg"
    }
  if (lower("`ma'")=="by") {
    local Name = "Benjamini-Yekutieli"
    }

  * Validate es
  if (lower("`es'") == "" ) {
    local es = "none"
    }
  if (lower("`es'") != "none" & lower("`es'") != "scm" & lower("`es'") != "bjm") {
    noi: di as err "option es() must be one of none, scm, bjm"
    exit 198
    }
   
  * validate nominal outcome
  qui: inspect `1'
  if (r(N_unique) != 2 | (`1' != 1 & `1' ! = 0)) {
    noi: di as err "the score variable must be nominal data coded 0/1"
    exit 450
    }

  * Validate blockid and groupid
  preserve
    qui: egen _block = group(`2') `if' `in'
    qui: tab _block `if' `in', nofreq
    local b = r(r)
    qui: egen _group = group(`3') `if' `in'
    qui: tab _group `if' `in', nofreq
    local k = r(r)
    forvalues i = 1(1)`b' {
      qui: count if _block == `i'
      if (r(N) != `k') {
        di as err "the number of groups is not the same for each block"
        exit 459
        }
      }
    if ("`weight'" == "fweight") {
      local equals = "="
      }
    if ("`weight'" != "fweight") {
      local equals = " "
      }
    quietly {
      sum(`1') `if' `in' [`weight' `equals' `exp'], meanonly
      local Total = r(sum)
      local Tbar = `Total'/`k'
      mata: numerator = rangen(.,.,`k')
      forvalues j = 1(1)`k' {
        sum(`1') if _group == `j' [`weight' `equals' `exp']
        local Tj = r(sum)
        mata: numerator[`j'] = (`Tj' - `Tbar')^2
        }
      mata: st_numscalar("_numerator", sum(numerator))
      }
    qui: _A 1 `1' _block `weight' `exp'
    local A1 = r(Am)
    qui: _A 2 `1' _block `weight' `exp'
    local A2 = r(Am)
    qui: _A 3 `1' _block `weight' `exp'
    local A3  = r(Am)
    qui: _A 4 `1' _block `weight' `exp'
    local A4  = r(Am)
    qui: _A 5 `1' _block `weight' `exp'
    local A5  = r(Am)
    qui: _A 6 `1' _block `weight' `exp'
    local A6  = r(Am)
    local Q = `k'*(`k'-1)*_numerator/(`k'*`A1' - `A2')
    local muQ = `k'-1
    local B1  = (`k'^2)*((`A1'^2) - `A2') - (2*`k'*((`A1'*`A2') - `A3')) + ((`A2'^2) - `A4')
    local B2  = (`k'^4)*(`A1'^2-`A2') - 6*(`k'^3)*((`A1'*`A2') - `A3') + (`k'^2)*((4*`A1'*`A3')+(9*(`A2'^2))-(13*`A4')) - (12*`k'*((`A2'*`A3')-`A5')) + (4*((`A3'^2)-`A6'))
    local B3  = ((`k'^3)*((`A1'^3)-(3*`A1'*`A2') + (2*`A3'))) - (3*(`k'^2)*(((`A1'^2)*`A2') - (2*`A1'*`A3') - (`A2'^2) + (2*`A4'))) + (3*`k'*((`A1'*(`A2'^2)) - (`A1'*`A4') - (2*`A2'*`A3') + (2*`A5'))) - ((`A2'^3) - (3*`A2'*`A4') +(2*`A6'))
    if (`k' == 2) {
      local K3  = ((4*(`k'-1))/(((`k'*`A1')-`A2')^3))*(2*`B3')
      }
    if (`k' >= 3) {
      local K3  = ((4*(`k'-1))/(((`k'*`A1')-`A2')^3))*(((`k'-1)/(`k'-2))*`B2'+2*`B3')
      }
    local s2Q = (2*`muQ'*`B1')/(((`k'*`A1')-`A2')^2)
    local gQ  = `K3'/(sqrt(`s2Q')^3)
    local Z   = (`Q' - `muQ')/sqrt(`s2Q')
    qui: _pPIII `Z' `gQ'
    local p2 = 1- r(p)
    if (`Q' < 10) {
      local Qformat = "%7.4f"
      } 
    if (`Q' >= 10 & `Q' < 100) {
      local Qformat = "%8.4f"
      } 
    if (`Q' >= 100) {
      local Qformat = "%9.4f"
      } 
    if (`gQ' < 10) {
      local gQformat = "%7.4f"
      } 
    if (`gQ' >= 10 & `Q' < 100) {
      local gQformat = "%8.4f"
      } 
    if (`gQ' >= 100) {
      local gQformat = "%9.4f"
      } 
    if (`Z' < 10) {
      local Zformat = "%7.4f"
      } 
    if (`Z' >= 10 & `Q' < 100) {
      local Zformat = "%8.4f"
      } 
    if (`Z' >= 100) {
      local Zformat = "%9.4f"
      } 
    qui: ds `1'
    local blockname = r(varlist)

    if (lower("`es'")=="bjm") {
      qui: egen _score = group(`1') `if' `in'
      mkmat _score _block _group, matrix(X)
      qui: drop _score
      local delta = 0
      forvalues i = 1/`k' {
        forvalues j = 1/`=`b'-1' {
          forvalue l = `=`j'+1'/`b' {
            local delta = `delta' + abs(X[`= `b'*(`i'-1) + `j'',1] - X[`=`b'*(`i'-1) + `l'',1])
            }
          }
        }
      local delta = `delta' / ( `k' * (`b'*(`b'-1)/2) )
      local mudelta = 0
      local p_i =0
      local SUMp_i = 0
      local SUMvarp_i = 0
      forvalues i = 1/`=`k'*`b'' {
        local SUMp_i = `SUMp_i' + `1'[`i']
        }
      forvalues i = 1/`b' {
        forvalues j = 1/`k' {
          local p_i = `p_i' + `1'[`=`i'+ `b'*(`j'-1)']
          }
        local p_i = `p_i'/`k'
        local SUMvarp_i = `SUMvarp_i' + (`p_i'*(1-`p_i'))
        local p_i = 0
        }
      local SUMp_i = `SUMp_i'/`k'
      local mudelta = (2/(`b'*(`b'-1))) * ( (`SUMp_i'*(`b'-`SUMp_i')) - `SUMvarp_i')
      qui: matrix drop X
      }
      qui: drop _block _group

    if ("`noqtest'" == "") {
      if "`nolabel'" == "" {
        local nl = 0
        local labelname : value label `2'
        if ("`labelname'" == "") {
          local nl = 1
          }
         else {
          mata: st_vlload("`labelname'", values = ., text = "")
          mata: st_local("testvalue", strofreal(length(values)))
          }
        if ("`testvalue'"!="`b'") {
          di as res _newline "Warning: {it:`3'} values are unlabeled or incompletely labeled, option nolabel implicit" _newline
          local nl = 1
          }
        }
      if "`nolabel'" == "nolabel" {
        local nl = 1
        }
      noi: di _newline as txt "Cochran's Q test for stochastic dominance in blocked binary data" _newline
      noisily _cochranqheader `2'
      forvalues i = 1/`b' {
        noi: _cochranqbody `if', index(`i') blockvar(`2') scorevar(`1') nl(`nl') weight(`weight') exp(`exp')
        }
      noi: _cochranqfooter `2'
      noi: di _newline as txt "Cochran's Q =" as res `Qformat' `Q' as txt " with df = " as res `k'-1 _newline
      if (lower("`es'") == "scm") {
        noi: di as text "Maximum-corrected effect size {it:Q}/[{it:b}({it:k}-1)] = " as res %-7.4f `=`Q'/(`b'*(`k'-1))' _newline as text "  (per Serlin, Carr and Marascuillo)"  
        }
      if (lower("`es'") == "bjm") {
        noi: di as text "Chance-corrected effect size {it:R} = " as res %-7.4f `=1 - (`delta'/`mudelta')' _newline as text "  (per Berry, Johnston and Mielke)"  
        }
      noi: di _newline as txt "Asymptotic test:"
      noi: di " P(Q >=" as res `Qformat' `Q' as txt ") =" as res %7.4f  1 - chi2(`k'-1,`Q')
      noi: di _newline as txt "Non-asymptotic test:" 
      noi: di as txt "    Z =" as res `Zformat' `Z' 
      noi: di as txt "gamma =" as res `gQformat' `gQ' 
      noi: di as txt " P(Q >=" as res `Qformat' `Q' as txt ") =" as res %7.4f `p2'
      }

      if "`noqtest'" == "noqtest" {
        if "`nolabel'" == "" {
          local nl = 0
          local labelname : value label `3'
          if ("`labelname'" == "") {
            local nl = 1
            }
           else {
            mata: st_vlload("`labelname'", values = ., text = "")
            mata: st_local("testvalue", strofreal(length(values)))
            }
          if ("`testvalue'"!="`k'") {
            di as res _newline "Warning: {it:`3'} values are unlabeled or incompletely labeled, option nolabel implicit" _newline
            local nl = 1
            }
          }
        if "`nolabel'" == "nolabel" {
          local nl = 1
          }
		}

    di _newline as txt %~76s "Comparison of `1' by `3'"
    di as txt %~76s "(`Name')"
    local colhead = ""
    local kminusone = `k'-1
    capture confirm numeric variable `3'
    if (!_rc) {
      local groupisnum = 1
      }
     else {
      local groupisnum = 0
      }
    qui: levelsof `3'
    local groupvalues = r(levels)
    local m = `k'*(`k'-1)/2
    matrix X2 = J(1,`m',0)
    matrix P = J(1,`m',0)
    matrix naP = J(1,`m',0)
    matrix Reject   = J(1,`m',0)
    matrix naReject = J(1,`m',0)
    if ("`weight'" == "") {
      local fweight = ""
      }
    if ("`weight'" != "") {
      local fweight = "[fw = `exp']"
      }
    
    forvalues i = 2/`k' {
      local iminusone = `i'-1
      forvalues j = 1/`iminusone' {
		local itest = word("`groupvalues'",`i')
		local jtest = word("`groupvalues'",`j')
	    if ("`if'" != "") {
          capture _cochranq `1' `2' `3' `if' & (`3' == `itest' | `3' == `jtest') `fweight'
          if (_rc == 2000) {
            local x2 = .
            local p = .
            local nap = .
            }
          if (_rc != 2000) {
            qui: _cochranq `1' `2' `3' `if' & (`3' == `itest' | `3' == `jtest') `fweight'
            local x2 = r(Q)
            local p = r(p_asymp)
            local nap = r(p_nonasymp)
            }
          }
        if ("`if'" == "") {
          capture _cochranq `1' `2' `3' if (`3' == `itest' | `3' == `jtest') `fweight'
          if (_rc == 2000) {
            local x2 = .
            local p = .
            local nap = .
            }
          if (_rc != 2000) {
            qui: _cochranq `1' `2' `3' if (`3' == `itest' | `3' == `jtest') `fweight'
            local x2 = r(Q)
            local p = r(p_asymp)
            local nap = r(p_nonasymp)
            }
          }

        * Static multiple comparisons adjustments
        if (lower("`ma'") == "bonferroni") {
          if (`p' != .) {
            local p = min(1,`p'*`m')
            }
          if (`nap' != .) {
            local nap = min(1,`nap'*`m')
            }
          }
        if (lower("`ma'") == "sidak") {
          if (`p' != .) {
            local p = min(1,1 - (1-`p')^`m')
            }
          if (`nap' != .) {
            local nap = min(1,1 - (1-`nap')^`m')
            }
          }
        local index = ((`i'-2)*(`i'-1)/2) + `j'
        matrix X2[1,`index'] = `x2'
        matrix P[1,`index'] = `p'
        matrix naP[1,`index'] = `nap'
        local alpha = (100 - `level')/100
		if el(P,1,`index') <= `alpha'/2 {
		  matrix Reject[1,`index'] = 1
		  }
		if el(naP,1,`index') <= `alpha'/2 {
		  matrix naReject[1,`index'] = 1
		  }
        }
      }
    * Sequential multiple comparrisons adjustments
    quietly {
      local alpha = (100 - `level')/100
      if (lower("`ma'")=="holm") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps   = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort   = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust = (`m'-numbermissing)+1-`i'
          local naadjust = (`m'-nanumbermissing)+1-`i'
          mata: Psort[1,`i']   = min((1,Psort[1,`i']   :* `adjust' ))  *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust')) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = 1/`m' {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' > 1) {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) & Psort[3,`i'-1]   != 0
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) & naPsort[3,`i'-1] != 0
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="hs") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust = (`m'-numbermissing)+1-`i'
          local naadjust = (`m'-numbermissing)+1-`i'
          mata: Psort[1,`i']   = min((1,(1 - ((1 - Psort[1,`i'])   :^ `adjust'   )))) *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,(1 - ((1 - naPsort[1,`i']) :^ `naadjust' )))) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = 1/`m' {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' > 1) {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) & Psort[3,`i'-1]   != 0
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) & naPsort[3,`i'-1] != 0
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="hochberg") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps   = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort   = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust = (`m'-numbermissing)+1-`i'
          local naadjust = (`m'-nanumbermissing)+1-`i'
          mata: Psort[1,`i']   = min((1,Psort[1,`i']   :* `adjust' ))  *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust')) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = `m'(-1)1 {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' < `m') {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) | Psort[3,`i'+1] == 1
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) | naPsort[3,`i'+1] == 1
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="bh") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        forvalues i = 1/`m' {
          local adjust   = (`m'-numbermissing)/`i'
          local naadjust = (`m'-nanumbermissing)/`i'
          mata: Psort[1,`i'] = min((1, Psort[1,`i']    :*  `adjust'))    *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust' )) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = `m'(-1)1 {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' < `m') {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) | Psort[3,`i'+1] == 1
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) | naPsort[3,`i'+1] == 1
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      if (lower("`ma'")=="by") {
        matrix Reject   = J(1,`m',0)
        matrix naReject = J(1,`m',0)
        mata: Ps = st_matrix("P")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: naPs = st_matrix("naP")\range(1,`m',1)'\rangen(0,0,`m')'
        mata: Psort = sort(Ps',1)'
        mata: naPsort = sort(naPs',1)'
        mata: numbermissing = missing(Ps[1,])
        mata: nanumbermissing = missing(naPs[1,])
        mata: st_numscalar("numbermissing", numbermissing)
        mata: st_numscalar("nanumbermissing", nanumbermissing)
        local C = 0
        forvalues i=1/`m' {
          local C = `C' + 1/`i'
          }
        forvalues i = 1/`m' {
          local adjust   = (`m'-numbermissing)*`C'/`i'
          local naadjust = (`m'-nanumbermissing)*`C'/`i'
          mata: Psort[1,`i']   = min((1, Psort[1,`i']  :* `adjust' ))   *(Psort[1,`i']/Psort[1,`i'])
          mata: naPsort[1,`i'] = min((1,naPsort[1,`i'] :* `naadjust' )) *(naPsort[1,`i']/naPsort[1,`i'])
          }
        forvalues i = `m'(-1)1 {
          if (`i' == 1) {
            mata: Psort[3,`i']   = Psort[1,`i']   <= `alpha'/2
            mata: naPsort[3,`i'] = naPsort[1,`i'] <= `alpha'/2
            }
          if (`i' < `m') {
            mata: Psort[3,`i']   = (Psort[1,`i']   <= `alpha'/2) | Psort[3,`i'+1]   == 1
            mata: naPsort[3,`i'] = (naPsort[1,`i'] <= `alpha'/2) | naPsort[3,`i'+1] == 1
            }
          }
        mata: Psort = sort(Psort',2)'
        mata: naPsort = sort(naPsort',2)'
        mata: st_matrix("P",Psort[1,])
        mata: st_matrix("naP",naPsort[1,])
        mata: st_matrix("Reject",Psort[3,])
        mata: st_matrix("naReject",naPsort[3,])
        }
      }

********************************************************************************
*** OUTPUT
********************************************************************************
  * Need to determine how many tables (reps) to output
  local reps = int((`k'-1)/6)
  local laststart = `reps'*6 + 1

  * Replication loop for >7 groups, no wrap
  if ("`wrap'"=="") {
    if (`k' > 7) {
      forvalues rep = 1/`reps' {
        local colstart = (6*`rep')-5
        local colstop  = 6*`rep'
        if (`nl' == 0) {
          local nolabel = ""
          }
        if (`nl' == 1) {
          local nolabel = "nolabel"
          }
        _mcheader `3' `colstart' `colstop' "`nolabel'" `groupisnum'
        * Table body
        local start = `colstart'+1
        forvalues i = `start'/`k' {
          local colstop = min(`i'-1,6*`rep')
          if (`nl' == 0) {
            local nolabel = ""
            }
          if (`nl' == 1) {
            local nolabel = "nolabel"
            }
          _mcx2table `3' `i' X2 `colstart' `colstop' "`nolabel'" `groupisnum' 
          if (`i' < `k') {
            _mcptable `i' P `colstart' `colstop' Reject 1 0
            _mcptable `i' naP `colstart' `colstop' naReject 0 1
            }
           else {
            _mcptable `i' P `colstart' `colstop' Reject 1 0
            _mcptable `i' naP `colstart' `colstop' naReject 1 1
            }
          }
        }
      * End of table
      if (`laststart' < `k') {
        if (`nl' == 0) {
          local nolabel = ""
          }
        if (`nl' == 1) {
          local nolabel = "nolabel"
          }
        _mcheader `3' `laststart' `kminusone' "`nolabel'" `groupisnum'
        * Table body
        local start = `laststart'+1
        forvalues i = `start'/`k' {
          if (`nl' == 0) {
            local nolabel = ""
            }
          if (`nl' == 1) {
            local nolabel = "nolabel"
            }
          _mcx2table `3' `i' X2 `laststart' `kminusone' "`nolabel'" `groupisnum' 
          if (`i' < `k') {
            _mcptable `i' P `laststart' `kminusone' Reject 1 0
            _mcptable `i' naP `laststart' `kminusone' naReject 0 1
            }
           else {
            _mcptable `i' P `laststart' `kminusone' Reject 1 0
            _mcptable `i' naP `laststart' `kminusone' naReject 1 1
            }
          }
        }
      }

    * Replication loop for <=7 groups
    if (`k' <= 7) {
      if (`nl' == 0) {
        local nolabel = ""
        }
      if (`nl' == 1) {
        local nolabel = "nolabel"
        }
      _mcheader `3' 1 `kminusone' "`nolabel'" `groupisnum'
      * Table body
      forvalues i = 2/`k' {
        local colstop  = `i'-1
        if (`nl' == 0) {
          local nolabel = ""
          }
        if (`nl' == 1) {
          local nolabel = "nolabel"
          }
        _mcx2table `3' `i' X2 1 `colstop' "`nolabel'" `groupisnum' 
        if (`i' < `k') {
          _mcptable `i' P 1 `colstop' Reject 1 0
          _mcptable `i' naP 1 `colstop' naReject 0 1
          }
         else {
          _mcptable `i' P 1 `colstop' Reject 1 0
          _mcptable `i' naP 1 `colstop' naReject 1 1
          }
        }
      }
    }

  * Replication loop for >7 groups, with wrap
  if ("`wrap'"=="wrap") {
    if (`nl' == 0) {
      local nolabel = ""
      }
    if (`nl' == 1) {
      local nolabel = "nolabel"
      }
    _mcheader `3' 1 `kminusone' "`nolabel'" `groupisnum'
    * Table body
    forvalues i = 2/`k' {
      local colstop  = `i'-1
      if (`nl' == 0) {
        local nolabel = ""
        }
      if (`nl' == 1) {
        local nolabel = "nolabel"
        }
      _mcx2table `3' `i' X2 1 `colstop' "`nolabel'" `groupisnum' 
      if (`i' < `k') {
        _mcptable `i' P 1 `colstop' Reject 1 0
        _mcptable `i' naP 1 `colstop' naReject 0 1
        }
       else {
        _mcptable `i' P 1 `colstop' Reject 1 0
        _mcptable `i' naP 1 `colstop' naReject 1 1
        }
      }
    }

  * Output pairwise comparisons as a list if requested.
  if ("`list'"=="list") {
    _cochranqlist `3' X2 naP naReject `k' "`ma'" "`nolabel'"
	}

  * Output level of significance
  local alpha = (100 - `level')/100
  if ustrlen("`level'") > 2 {
    local precision = ustrlen("`level'") - 1
	}
   else {
    local precision = 2
	}
  di _newline as text "alpha = " as res %6.`precision'f `alpha'

  restore

  * Saves
  ret matrix P_nonasymp  = naP 
  ret matrix P_asymp     = P
  ret matrix X2          = X2
  ret scalar gamma       = `gQ'
  ret scalar Z           = `Z'
  ret scalar p_nonasymp  = `p2'
  ret scalar p_asymp     = 1 - chi2(`kminusone',`Q')
  ret scalar df          = `kminusone'
  ret scalar k           = `k'
  ret scalar b           = `b'
  ret scalar Q           = `Q'

  end
  
  
program define _cochranqheader
/*
    This program displays Cochran's Q test table header.

    Syntax:
            _cochranqheader blockvar
*/
  args blockvar

  local blockname: var l `blockvar'
  if ("`blockname'" != "") {
    local blockname = substr("`blockname'",1,16)
    }
  if ("`blockname'" == "") {
    qui: ds `blockvar' 
    local blockname = r(varlist)
    local blockname = substr("`blockname'",1,16)
    }
  local blockhead = "`blockname' "
  local blocknamelength = max(8, length("`blockhead'")+1)
  local blockpad = max(0,8 - length("`blockhead'"))

  di as txt "{c TLC}{hline `blocknamelength'}{c TT}{hline 7}{c TT}{hline 7}{c TRC}"
  di as txt "{c |}{dup `blockpad': } `blockhead'{c |}  Obs  {c |}  Sum  {c |}"
  di as txt "{c LT}{hline `blocknamelength'}{c +}{hline 7}{c +}{hline 7}{c RT}"
  end

program define _cochranqbody
/*
    This program displays Cochran's Q test table body.

    Syntax:
            _cochranqheader index blockvar scorevar nl weight exp
*/
  syntax [if/] , index(integer) blockvar(varname) scorevar(varname) nl(integer) [weight(string) exp(varname)]
*  args index blockvar scorevar nl weight exp

  local blockname: var l `blockvar'
  if ("`blockname'" != "") {
    local blockname = substr("`blockname'",1,16)
    }
  if ("`blockname'" == "") {
    qui: ds `blockvar' 
    local blockname = r(varlist)
    local blockname = substr("`blockname'",1,16)
    }
  local blockhead = "`blockname' "
  local blocknamelength = max(8, length("`blockhead'"))

  if ("`if'" != "") {
    local if = "& `if'"
    }
  if ("`weight'" == "fweight") {
    mkmat `scorevar' `exp' if `blockvar' == `index' `if', matrix(Data)
    mata: Data = st_matrix("Data")
    mata: Nobs = Data[1,2]
    mata: Sum  = sum(Data[,1])*Nobs
    }
  if ("`weight'" != "fweight") {
    mkmat `scorevar' if `blockvar' == `index' `if', matrix(Data)
    mata: Data = st_matrix("Data")
    mata: Nobs = 1
    mata: Sum  = sum(Data[,1])
    }
  mata: st_numscalar("_Nobs",Nobs)
  local Nobs = _Nobs
  mata: st_numscalar("_Sum",Sum)
  local Sum = _Sum
  qui: levelsof `blockvar'
  local blocks = r(levels)

  * Row headers
  if (`nl'==0) {
    local blocklab: label (`blockvar') `index' 16, strict
    di as txt "{c |}"  %`blocknamelength's "`blocklab'"   _continue
    }
  if (`nl'==1) {
    di as txt "{c |}"  %`blocknamelength's substr(word("`blocks'",`index'),1,16)  _continue
    }
  di as txt" {c |}" as res "{center 7: `Nobs'}" as txt "{c |}" as res "{center 7: `Sum'}" as txt "{c |}" _continue
  di
  end

program define _cochranqfooter
/*
    This program displays Cochran's Q test table footer.

    Syntax:
            _cochranqheader blockvar
*/
  args blockvar

  local blockname: var l `blockvar'
  if ("`blockname'" != "") {
    local blockname = substr("`blockname'",1,16)
    }
  if ("`blockname'" == "") {
    qui: ds `blockvar' 
    local blockname = r(varlist)
    local blockname = substr("`blockname'",1,16)
    }
  local blockhead = "`blockname' "
  local blocknamelength = max(9, length("`blockhead'")+1)

  di as txt "{c BLC}{hline `blocknamelength'}{c BT}{hline 7}{c BT}{hline 7}{c BRC}"
  end

program define _A, rclass
/*
    This program returns the function Am(scorevar, blockvar, groupvar) 
    (equation [2] from Mielke and Berry, 1995).
    
    Syntax:
            _Am m scorevar blockvar weight exp
*/

  args m scorevar blockvar weight exp
  quietly {
    sum `blockvar'
    local b = r(max)
    }
  mata: Am  = rangen(.,.,`b')
  forvalues i = 1(1)`b' {
    if ("`weight'" == "fweight") {
      mkmat `scorevar' `exp' if `blockvar' == `i', matrix(AmData)
      mata: AmData = st_matrix("AmData")
      mata: Am[`i'] = sum(AmData[,1])^`m'*AmData[1,2]
      }
    if ("`weight'" != "fweight") {
      mkmat `scorevar' if `blockvar' == `i', matrix(AmData)
      mata: AmData = st_matrix("AmData")
      mata: Am[`i'] = sum(AmData[,1])^`m'
      }
    }
  mata: st_numscalar("_Am",sum(Am))
  ret scalar Am = _Am
  end

program define _pPIII, rclass
/*
    This program returns the cumulative distribution of the Pearson Type III
    distribution variation described in Mielke and Berry (1995), equation [17] 
    from -2/gQ to w.
    
    Syntax:
            _pPIII w gQ
*/

  args w gQ
  preserve
  quietly {
    range _x -2/`gQ' `w' 1000
    gen _y = (((2/`gQ')^((4)/(`gQ'^2)))/(exp(lngamma(4/(`gQ'^2))))) * (((2+(`gQ'*_x))/(`gQ'))^((4-(`gQ'^2))/(`gQ'^2))) * exp((-2*(2 + (`gQ'*_x)))/(`gQ'^2))
    integ _y _x
    }
  restore
  ret scalar p = r(integral)
  end

program define _mcheader
/*
    This program displays multiple comparison table headers.

    Syntax:
            _mcheader groupvar colstart colstop nolabel groupisnum
*/
  args groupvar colstart colstop nolabel groupisnum

  di as txt "Row vs.  {c |}"
  di as txt "Column   {c |}" _continue
  qui: levelsof `groupvar'
  local groupvalues = r(levels)
  forvalues col = `colstart'/`colstop' {
    if (lower("`nolabel'")=="") {
      local labelname : value label `groupvar'
      if ("`labelname'") != "" {
        local vallab = substr("`:label `labelname' `:word `col' of `groupvalues'''",1,8)
        local pad = 8-length("`vallab'")
        local colhead = "{dup `pad': }`vallab'"
        if ("`vallab'" == "") {
          local colhead = ""
          local nolabel = "nolabel"
          }
        }
       else {
        local nolabel = "nolabel"
        }
      }
    if (lower("`nolabel'")=="nolabel") {
      if (`groupisnum' == 0) {
        local pad = max(0,8-length(substr(`groupvar'[`col'],1,8)))
        local colhead = "   {dup `pad': }"+ substr(`groupvar'[`col'],1,8)
        }
      if (`groupisnum' == 1) {
        local pad = max(0,8-length(substr(word("`groupvalues'",`col'),1,8)))
        local colhead = "   {dup `pad': }"+ substr(word("`groupvalues'",`col'),1,8)
        }
      }
    di as txt "   " %8s "`colhead'" _continue
    }
  di  
  local separatorlength = 10 + 11*(`colstop'-`colstart')+1
  di as txt "{hline 9}{c +}{hline `separatorlength'}"
      
  end

program define _mcx2table
/*
    This program displays multiple comparisons chi-sq values.

    Syntax:
            _mcx2table groupvar index X2 colstart colstop nolabel groupisnum
*/
  args groupvar index X2 colstart colstop nolabel groupisnum

  qui: levelsof `groupvar'
  local groupvalues = r(levels)


  * Row headers
  if (lower("`nolabel'")=="") {
    local labelname : value label `groupvar'
    if ("`labelname'") != "" {
        local vallab = substr("`:label `labelname' `:word `index' of `groupvalues'''",1,8)
      di as txt %8s "`vallab'" " {c |}"   _continue
      }
     else {
      local nolabel = "nolabel"
      }
    }
  if (lower("`nolabel'")=="nolabel") {
    if (`groupisnum' == 0) {
      di as txt %8s substr(`groupvar'[`index'],1,8) " {c |}"   _continue
      }
    if (`groupisnum' == 1) {
      di as txt %8s substr(word("`groupvalues'",`index'),1,8) " {c |}"   _continue
      }
    }

  * Table chi-sq entries
  forvalues i = `colstart'/`colstop' {
    di as res "  " %9.6f el(matrix(`X2'),1,((`index'-2)*(`index'-1))/2 + `i') _continue
    }
  di
  end
  
program define _mcptable
/*
    This program displays multiple comparisons p values.

    Syntax:
            _mcptable index P colstart colstop Reject last
*/
  args index P colstart colstop Reject last na

  * Row header
    if (`na' == 0) {
      di as txt "         {c |}" _continue
      }
    if (`na' == 1) {
      di as txt "      na {c |}" _continue
      }

  * Table p entries
  forvalues i = `colstart'/`colstop' {
    if ( el(`Reject',1,((`index'-2)*(`index'-1))/2 + `i') == 0) {
      di as res "    " %7.4f el(matrix(`P'),1,((`index'-2)*(`index'-1))/2 + `i') _continue
      }
     else {
      di as res "    {ul on}" %7.4f el(matrix(`P'),1,((`index'-2)*(`index'-1))/2 + `i') "{ul off}" _continue
      }
    }
  di

  * Close out with another blank row header
  if (`last' == 0) {
    di as txt "         {c |}"
    }
  end

program define _cochranq, rclass sort
  syntax varlist(min=3 max=3 numeric fv) [if] [in] [fweight/]

  tokenize `varlist'

  preserve
*  noi: di _newline as red "1: `1'   2: `2'   3: `3'   if: `if'   in: `in'"
    qui: egen _block = group(`2') `if' `in'
    qui: tab _block `if' `in', nofreq
    local b = r(r)
    qui: egen _group = group(`3') `if' `in'
    local k = 2
    if ("`weight'" == "fweight") {
      local equals = "="
      }
    if ("`weight'" != "fweight") {
      local equals = " "
      }
    quietly {
      sum(`1') `if' `in' [`weight' `equals' `exp'], meanonly
      local Total = r(sum)
      local Tbar = `Total'/`k'
      mata: numerator = rangen(.,.,`k')
      forvalues j = 1(1)`k' {
        sum(`1') if _group == `j' [`weight' `equals' `exp']
        local Tj = r(sum)
        mata: numerator[`j'] = (`Tj' - `Tbar')^2
        }
      mata: st_numscalar("_numerator", sum(numerator))
      drop _group
      }
    qui: _A 1 `1' _block `weight' `exp'
    local A1 = r(Am)
    qui: _A 2 `1' _block `weight' `exp'
    local A2 = r(Am)
    qui: _A 3 `1' _block `weight' `exp'
    local A3  = r(Am)
    qui: _A 4 `1' _block `weight' `exp'
    local A4  = r(Am)
    qui: _A 5 `1' _block `weight' `exp'
    local A5  = r(Am)
    qui: _A 6 `1' _block `weight' `exp'
    local A6  = r(Am)
    drop _block
    local Q = `k'*(`k'-1)*_numerator/(`k'*`A1' - `A2')
    local muQ = `k'-1
    local B1  = (`k'^2)*((`A1'^2) - `A2') - (2*`k'*((`A1'*`A2') - `A3')) + ((`A2'^2) - `A4')
    local B2  = (`k'^4)*(`A1'^2-`A2') - 6*(`k'^3)*((`A1'*`A2') - `A3') + (`k'^2)*((4*`A1'*`A3')+(9*(`A2'^2))-(13*`A4')) - (12*`k'*((`A2'*`A3')-`A5')) + (4*((`A3'^2)-`A6'))
    local B3  = ((`k'^3)*((`A1'^3)-(3*`A1'*`A2') + (2*`A3'))) - (3*(`k'^2)*(((`A1'^2)*`A2') - (2*`A1'*`A3') - (`A2'^2) + (2*`A4'))) + (3*`k'*((`A1'*(`A2'^2)) - (`A1'*`A4') - (2*`A2'*`A3') + (2*`A5'))) - ((`A2'^3) - (3*`A2'*`A4') +(2*`A6'))
    if (`k' == 2) {
    local K3  = ((4*(`k'-1))/(((`k'*`A1')-`A2')^3))*(2*`B3')
      }
    if (`k' >= 3) {
    local K3  = ((4*(`k'-1))/(((`k'*`A1')-`A2')^3))*(((`k'-1)/(`k'-2))*`B2'+2*`B3')
      }
    local s2Q = (2*`muQ'*`B1')/(((`k'*`A1')-`A2')^2)
    local gQ  = `K3'/(sqrt(`s2Q')^3)
    local Z   = (`Q' - `muQ')/sqrt(`s2Q')
    qui: _pPIII `Z' `gQ'
    local p2 = 1- r(p)

  restore

  * Saves
  ret scalar Z           = `Z'
  ret scalar p_nonasymp  = `p2'
  ret scalar p_asymp     = 1 - chi2(`k'-1,`Q')
  ret scalar df          = `k'-1
  ret scalar Q           = `Q'

  end

  program define _cochranqlist
/*
    This program displays Cochran's test z and p values as a list.

    Syntax:
            _cochranqlist groupvar X2 naP naReject k ma nolabel 
*/
    if int(_caller())<8 {
      exit
      }
     else if int(_caller())<14 {
      _cochranqlist8 `0'
      }
     else _cochranqlist14 `0'
  end

  program define _cochranqlist8
  
  args groupvar X2 naP naReject k ma nolabel

  qui: levelsof `groupvar'
  local groupvalues = r(levels)
  * Output list header, depending on whether the ma option is used
  if (lower("`ma'")=="none" || "`ma'"=="") {
    noi: di as text _newline "List of pairwise comparisons: chi-square statistic (non-asymptotic p-value)"
    }
   else {
	noi: di as text _newline "List of pairwise comparisons: chi-square statistic (adjusted non-asymptotic p-value)"
    }

  * flag whether any rejections occur
  local maxreject = 0
  forvalues i = 1(1)`k' {
    if el(`naReject',1,`i') == 1 {
	  local maxreject = 1
	  }
	}
	
	
  * Validate labels
    if (lower("`nolabel'")=="") {
     forvalues i = 1(1)`k' {
       local testlab: label (`groupvar') `i', strict	   
       if ("`testlab'" == "") {
         local nolabel = "nolabel"
         }
	   }
     }

  * List headers
  if (lower("`nolabel'")=="") {
    * get the labelname for the group labels 
    local labelname : value label `groupvar'
    if ("`labelname'") != "" {
      * get the length of the largest group label (whether explicitly labeled or not)
      local firstlongest = 1
      forvalues i = 1(1)`k' {
	    * get the length of the ith value label
        local currentlength = length("`:label `labelname' `:word `i' of `groupvalues'''")
		if `currentlength' > `firstlongest' {
		  local firstlongest = `currentlength'
		  }
        }
      * get the secondlongest group label length (whether explicitly labeled or not)
      local secondlongest = 1
      forvalues i = 1(1)`k' {
	    * get the length of the ith value label
        local currentlength = length("`:label `labelname' `:word `i' of `groupvalues'''")
		if `currentlength' < `firstlongest' & `currentlength' > `secondlongest' {
		  local secondlongest = `currentlength'
		  }
        }
      * replace secondlongest if the value of firstlongest appears twice
	  local twice = 0
      forvalues i = 1(1)`k' {
        local currentlength = length("`:label `labelname' `:word `i' of `groupvalues'''")
		if `currentlength' == `firstlongest' {
		  local twice = `twice' + 1
		  }
		if `twice' == 2 {
		  local secondlongest = `firstlongest'
		  }
	    }
	  
      * stringlength will be the sum of the two largest values in lengths plus 6
      local stringlength = `firstlongest' + `secondlongest' + 8
	  * output underline length, dependent upon group labels
	  local underline = `stringlength' - 2
	  noi: di as text "{hline `underline'}{c TT}{hline 19}{hline `maxreject'}"

	  * Start listing output!
	  local index = 0
	  forvalues i = 2(1)`k' {
	    local jmax = `i'-1
	    forvalues j = 1(1)`jmax' {
		  local index = `index' + 1
		  local labeli = "`:label `labelname' `:word `i' of `groupvalues'''"
		  local labelj = "`:label `labelname' `:word `j' of `groupvalues'''"
		  local bufferlength = max(`stringlength' - (length("`labeli'") + length("`labelj'") + 6) - 2,0)
          if "`rmc'" == "" {
		    noi: di as text "`labelj' vs. `labeli'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naP'),1,`index') as text ")" _continue
          }
          if "`rmc'" == "rmc" {
		    noi: di as text "`labeli' vs. `labelj'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naaP'),1,`index') as text ")" _continue
          }
          if el(`naReject',1,`index') == 1 {
		    noi: di as res "*" _continue
		    }
		  noi: di
		  }
		}
      }
     else {
      local nolabel = "nolabel"
      }
    }
  if (lower("`nolabel'")=="nolabel") {
    * get the lengths of the two largest group numbers
    local firstlongest = 1
    local secondlongest = 1
    forvalues i = 1(1)`k' {
    * get the length of the ith value label
      local currentlength = floor(log10(real(word("`groupvalues'",`i')))) + 1
	if `currentlength' > `firstlongest' {
	  local firstlongest = `currentlength'
	  }
	if `currentlength' < `firstlongest' & `currentlength' > `secondlongest' {
	  local secondlongest = `currentlength'
	  }
      }
    * replace secondlongest if the value of firstlongest appears twice
    local twice = 0
    forvalues i = 1(1)`k' {
      local currentlength = floor(log10(real(word("`groupvalues'",`i')))) + 1
	  if `currentlength' == `firstlongest' {
	    local twice = `twice' + 1
	    }
	  if `twice' == 2 {
	    local secondlongest = `firstlongest'
	    }
      }
  
    * stringlength will be the sum of the two largest values in lengths plus 6
    local stringlength = `firstlongest' + `secondlongest' + 8
	* output underline length, dependent upon group labels
    local underline = `stringlength' - 2
	noi: di as text "{hline `underline'}{c TT}{hline 19}{hline `maxreject'}"

    * Start listing output!
    local index = 0
    forvalues i = 2(1)`k' {
      local jmax = `i'-1
      forvalues j = 1(1)`jmax' {
	    local index = `index' + 1
	    local labeli = word("`groupvalues'",`i')
	    local labelj = word("`groupvalues'",`j')
	    local bufferlength = max(`stringlength' - (floor(log10(`labeli')) + floor(log10(`labelj')) + 8) - 2,0)
        if "`rmc'" == "" {
	      noi: di as text "`labelj' vs. `labeli'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naP'),1,`index') as text ")" _continue
          }
        if "`rmc'" == "rmc" {
	      noi: di as text "`labeli' vs. `labelj'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naP'),1,`index') as text ")" _continue
          }
        if el(`naReject',1,`index') == 1 {
	      noi: di as res "*" _continue
	      }
	    noi: di
	    }
	  }
    }
  end
  
  
  program define _cochranqlist14
  
  args groupvar X2 naP naReject k ma nolabel

  qui: levelsof `groupvar'
  local groupvalues = r(levels)
  * Output list header, depending on whether the ma option is used
  if (lower("`ma'")=="none" || "`ma'"=="") {
    noi: di as text _newline "List of pairwise comparisons: chi-square statistic (non-asymptotic p-value)"
    }
   else {
	noi: di as text _newline "List of pairwise comparisons: chi-square statistic (adjusted non-asymptotic p-value)"
    }

  * flag whether any rejections occur
  local maxreject = 0
  forvalues i = 1(1)`k' {
    if el(`naReject',1,`i') == 1 {
	  local maxreject = 1
	  }
	}
	
	
  * Validate labels
    if (lower("`nolabel'")=="") {
     forvalues i = 1(1)`k' {
       local testlab: label (`groupvar') `i', strict	   
       if ("`testlab'" == "") {
         local nolabel = "nolabel"
         }
	   }
     }

  * List headers
  if (lower("`nolabel'")=="") {
    * get the labelname for the group labels 
    local labelname : value label `groupvar'
    if ("`labelname'") != "" {
      * get the length of the largest group label (whether explicitly labeled or not)
      local firstlongest = 1
      forvalues i = 1(1)`k' {
	    * get the length of the ith value label
        local currentlength = ustrlen("`:label `labelname' `:word `i' of `groupvalues'''")
		if `currentlength' > `firstlongest' {
		  local firstlongest = `currentlength'
		  }
        }
      * get the secondlongest group label length (whether explicitly labeled or not)
      local secondlongest = 1
      forvalues i = 1(1)`k' {
	    * get the length of the ith value label
        local currentlength = ustrlen("`:label `labelname' `:word `i' of `groupvalues'''")
		if `currentlength' < `firstlongest' & `currentlength' > `secondlongest' {
		  local secondlongest = `currentlength'
		  }
        }
      * replace secondlongest if the value of firstlongest appears twice
	  local twice = 0
      forvalues i = 1(1)`k' {
        local currentlength = ustrlen("`:label `labelname' `:word `i' of `groupvalues'''")
		if `currentlength' == `firstlongest' {
		  local twice = `twice' + 1
		  }
		if `twice' == 2 {
		  local secondlongest = `firstlongest'
		  }
	    }
	  
      * stringlength will be the sum of the two largest values in lengths plus 6
      local stringlength = `firstlongest' + `secondlongest' + 8
	  * output underline length, dependent upon group labels
	  local underline = `stringlength' - 2
	  noi: di as text "{hline `underline'}{c TT}{hline 19}{hline `maxreject'}"

	  * Start listing output!
	  local index = 0
	  forvalues i = 2(1)`k' {
	    local jmax = `i'-1
	    forvalues j = 1(1)`jmax' {
		  local index = `index' + 1
		  local labeli = "`:label `labelname' `:word `i' of `groupvalues'''"
		  local labelj = "`:label `labelname' `:word `j' of `groupvalues'''"
		  local bufferlength = max(`stringlength' - (ustrlen("`labeli'") + ustrlen("`labelj'") + 6) - 2,0)
          if "`rmc'" == "" {
		    noi: di as text "`labelj' vs. `labeli'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naP'),1,`index') as text ")" _continue
          }
          if "`rmc'" == "rmc" {
		    noi: di as text "`labeli' vs. `labelj'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naaP'),1,`index') as text ")" _continue
          }
          if el(`naReject',1,`index') == 1 {
		    noi: di as res "*" _continue
		    }
		  noi: di
		  }
		}
      }
     else {
      local nolabel = "nolabel"
      }
    }
  if (lower("`nolabel'")=="nolabel") {
    * get the lengths of the two largest group numbers
    local firstlongest = 1
    local secondlongest = 1
    forvalues i = 1(1)`k' {
    * get the length of the ith value label
      local currentlength = floor(log10(real(word("`groupvalues'",`i')))) + 1
	if `currentlength' > `firstlongest' {
	  local firstlongest = `currentlength'
	  }
	if `currentlength' < `firstlongest' & `currentlength' > `secondlongest' {
	  local secondlongest = `currentlength'
	  }
      }
    * replace secondlongest if the value of firstlongest appears twice
    local twice = 0
    forvalues i = 1(1)`k' {
      local currentlength = floor(log10(real(word("`groupvalues'",`i')))) + 1
	  if `currentlength' == `firstlongest' {
	    local twice = `twice' + 1
	    }
	  if `twice' == 2 {
	    local secondlongest = `firstlongest'
	    }
      }
  
    * stringlength will be the sum of the two largest values in lengths plus 6
    local stringlength = `firstlongest' + `secondlongest' + 8
	* output underline length, dependent upon group labels
    local underline = `stringlength' - 2
	noi: di as text "{hline `underline'}{c TT}{hline 19}{hline `maxreject'}"

    * Start listing output!
    local index = 0
    forvalues i = 2(1)`k' {
      local jmax = `i'-1
      forvalues j = 1(1)`jmax' {
	    local index = `index' + 1
	    local labeli = word("`groupvalues'",`i')
	    local labelj = word("`groupvalues'",`j')
	    local bufferlength = max(`stringlength' - (floor(log10(`labeli')) + floor(log10(`labelj')) + 8) - 2,0)
        if "`rmc'" == "" {
	      noi: di as text "`labelj' vs. `labeli'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naP'),1,`index') as text ")" _continue
          }
        if "`rmc'" == "rmc" {
	      noi: di as text "`labeli' vs. `labelj'{dup `bufferlength': } {c |} " as res %9.6f el(matrix(`X2'),1,`index') as text " (" as res %6.4f el(matrix(`naP'),1,`index') as text ")" _continue
          }
        if el(`naReject',1,`index') == 1 {
	      noi: di as res "*" _continue
	      }
	    noi: di
	    }
	  }
    }
  end
