*! 28mar2012       JP Azevedo
*
* 11nov2008       JP Azevedo
*  if
* 18may2008       JP Azevedo
*  multiple values
* 28apr2008       JP Azevedo

program define _matchval, rclass

    version 8.0

    syntax varlist [if] [in], NNVal(string)  gen(string) [NNLabels(string) GENLabel(string) RETurn(string) RVAR(string)]
    tokenize `varlist'
    tempvar tmp0 rownonmiss

quietly {

    if ("`nnlabels'" != "") | ("`genlabel'" != "") {
        loc v = wordcount("`nnval'")
        loc n = wordcount("`nnlabels'")
        if (`v' != `n') {
            di as err "if the option nnlabels is selected, the number of values and labels have to be the same."
            exit 198
        }
        if ("`genlabel'" == "") {
            di as err "the name of the label variable must be specified."
            exit 198
        }
        if ("`nnlabels'" == "") {
            di as err "the value of the label variable must be specified."
            exit 198
        }
        if (("`return'" != "") & ("`rvar'" == "")) | (("`return'" == "") & ("`rvar'" != ""))  {
            di as err "both return rvar have to be jointly specified."
            exit 198
        }
    }

    gen `tmp0' = round(`1'*1000000) `if'  `in'

    sum `varlist'
    local N = r(N)

    loc l =1
    foreach nn of numlist `nnval' {

            tempvar tmp`l' gen`l' genlabel`l' ren`l'

            gen `gen`l''= .

            loc value = round(`nn'*1000000)
            gen double `tmp`l'' = round(abs(`tmp0'-`value'))
            qui sum `tmp`l''
            loc min = `r(min)'
            replace `gen`l'' = `nn' if `tmp`l'' == `min'

            if ("`nnlabels'" != "") {
				gen `genlabel`l'' = ""
                loc lab = word("`nnlabels'",`l')
                replace `genlabel`l'' = "`lab'"  if `tmp`l'' == `min'
            }

            if ("`return'" != "") {
                gen `ren`l''= .
                sum `return' if `tmp`l'' == `min'
                replace `ren`l'' = r(mean) if `tmp`l'' == `min'
            }

            qui sum `gen`l''

            qui if (`r(N)' > 1) {

                tempvar order`l' dups`l'
                gen `order`l'' = _n
                bysort `gen`l'' : gen `dups`l'' = _n if `gen`l'' != .
                sum `dups`l'', d
                loc p50 = int(`r(p50)')
                replace `gen`l'' = . if `dups`l'' != `p50'

                if ("`nnlabels'" != "") {
                    replace `genlabel`l'' = "" if `dups`l'' != `p50'
                }

                if ("`return'" != "") {
                    replace `ren`l'' = . if `dups`l'' != `p50'
                }

                sort `order`l''
            }
            local gennames "`gennames'  `gen`l''"
            local genlabelnames "`genlabelnames'  `genlabel`l''"
            local retnames "`retnames'  `ren`l''"
            loc l =1+`l'
    }

    egen `gen' =  rowmax(`gennames')
    egen `rvar'=  rowmax(`retnames')
	
    if ("`nnlabels'" != "") {

		egen `rownonmiss' = rownonmiss(`gennames')
		
		loc l = 1
		foreach nnn in `nnlabels' {
            forvalues i=1(1)`N' {
   			    local val = `genlabel`l'' in `i'
                local valf = trim("`val' `valf'")
            }
  			replace `genlabel`l'' = ","+"`valf'"  if `genlabel`l'' != ""
            local valf ""
    		loc l = `l'+1
		}
		
        egen `genlabel' = concat(`genlabelnames')
		replace `genlabel' = trim(`genlabel')

        forvalues i=1(1)`N' {
            local val = `genlabel' in `i'
            if ("`val'" != "") {
                local val = substr("`val'",2,.)
    			replace `genlabel'  = "`val'"  in `i'
            }

        }
    }
}
end
