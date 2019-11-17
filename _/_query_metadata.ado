*******************************************************************************
*! v 13.4  01jul2014               by Joao Pedro Azevedo                        *
*******************************************************************************

program def _query_metadata, rclass

version 9.0

    syntax , INDICATOR(string)

    quietly {

        if ("`indicator'" != "") {
            local indicator1 = word("`indicator'",1)
            local indicator2 = subinstr("`indicator'","`indicator1'","",.)
            local indicator2 = trim(subinstr("`indicator2'","-","",.))
            if ("`indicator2'" == "") {
                local indicator2 "`indicator1'"
            }
        }


        local skipnumber = 2
        local trimnumber = 4

        tempfile in out source
        tempfile out3 source3
        tempname in2 out2 in_tmp saving source1 source2

        capture : copy "http://api.worldbank.org/indicators/`indicator1'" `in', text replace
        local rc4 = _rc
        if (`rc4' != 0) {
            noi di ""
            noi dis as text `"{p 4 4 2} (1) Please check your internet connection by {browse "http://data.worldbank.org/" :clicking here}, if does not work please check with your internet provider or IT support, otherwise... {p_end}"'
            noi dis as text `"{p 4 4 2} (2) Please check your access to the World Bank API by {browse "http://api.worldbank.org/indicator" :clicking here}, if does not work please check with your firewall settings or internet provider or IT support.  {p_end}"'
            noi dis as text `"{p 4 4 2} (3) Please consider ajusting your Stata timeout parameters. For more details see {help netio}. {p_end}
            noi dis as text `"{p 4 4 2} (4) Please send us an email to report this error by {browse "mailto:data@worldbank.org, ?subject= wbopendata query error `rc4' at `c(current_date)' `c(current_time)': `queryspec' "  :clicking here} or writing to:  {p_end}"'
            noi dis as result "{p 12 4 2} email: " as input "data@worldbank.org  {p_end}"
            noi dis as result "{p 12 4 2} subject: " as input `"wbopendata query error `rc4' at `c(current_date)' `c(current_time)': `queryspec'  {p_end}"'
            noi di ""
            exit `rc4'
            break
        }

    *========================begin trim do file===========================================

        filefilter `in'  `in_tmp' , from("\LQ")         to("") replace
        filefilter `in_tmp' `in'  , from("\RQ")         to("") replace
        filefilter `in'  `in_tmp' , from("\Q")          to("") replace
        filefilter `in_tmp' `in'  , from("\Q")          to("") replace


        file open `in2'     using `in'      , read
        file open `out2'    using `out'     , write text replace
        file open `source2' using `source'  , write text replace


        file read `in2' line
        local l = 0
             while !r(eof) {
                  local ++l
                  file read `in2' line
                  if(`l'>`skipnumber') {
                    file write `out2' `"`line'"' _n
                    if ("`line'" != "") {
                        local line = subinstr(`"`line'"', `"""', "", .)
                        if (strmatch("`line'", "*<wb:name>*")==1) {
                            local labvar = "`line'"
                            local labvar = trim(subinstr("`labvar'","<wb:name>","",.))
                            local labvar = subinstr("`labvar'","</wb:name>","",.)
                        }
                        if (strmatch("`line'", "*<wb:source id=*")==1) {
                            file write `source2' `"`line'"' _n
                        }
                    }
                  }
            }
        file close `in2'
        file close `out2'
        file close `source2'

        file open `in2'  using `out' , read
        file open `out2' using `in', write text replace


        local i = 0
            while `i' < `l'- `trimnumber'-`skipnumber' {
             local ++i
             file read `in2' line
             file write `out2' `"`line'"' _n
           }
        file close `out2'
        file close `in2'

    *========================end trim do file===========================================

      	file open `in2'  using `in' , read
        file open `out2' using "`out'", write replace
    	file read `in2' line

        file write `out2' "{smcl}"  _n
        file write `out2' "{txt}"   _n
        file write `out2' "{hline}" _n

        local l = 0
      	while !r(eof) {
            local l = `l'+1
      	   	file write `out2' `"`macval(line)'"' _n
        	file read `in2' line
       	}

        file close `out2'

        filefilter `out' `out3' , from("<wb:name>")                  to("{p 4 4 2}{cmd:Name:} ")
        filefilter `out3' `out' , from("</wb:name>")                 to("{p_end} \r  {hline}")                         replace
        filefilter `out' `out3'  , from("<wb:source id=1>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=2>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=3>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=4>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=5>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=6>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=7>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=8>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=9>")      to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=10>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=11>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=12>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=13>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=14>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=15>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=16>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=17>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=18>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=19>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=20>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=21>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=22>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=23>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=24>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=25>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=26>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=27>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=28>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=29>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=30>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=31>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=32>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=33>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=34>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=35>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=36>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=37>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out3' `out'  , from("<wb:source id=38>")     to("{p 4 4 2}{cmd:Source:} ")                  replace
        filefilter `out' `out3'  , from("<wb:source id=39>")     to("{p 4 4 2}{cmd:Source:} ")                  replace

        filefilter `out3' `out'   , from("</wb:source>")              to("{p_end} \r {hline}")                           replace
        filefilter `out' `out3'   , from("<wb:sourceNote>")           to("{p 4 4 2}{cmd:Source Note:} ")                 replace
        filefilter `out3' `out'   , from("</wb:sourceNote>")          to("{p_end} \r {hline}")                           replace
        filefilter `out' `out3'   , from("<wb:sourceNote />")         to("")                                                 replace
        filefilter `out3' `out'   , from("<wb:sourceOrganization />") to("")                                                 replace
        filefilter `out' `out3'   , from("<wb:sourceOrganization>")   to("{p 4 4 2}{cmd:Source Organization:} ")             replace
        filefilter `out3' `out'   , from("</wb:sourceOrganization>")  to("{p_end} \r {hline}")                               replace
        filefilter `out' `out3'   , from("<wb:topics>")               to("")                                                 replace
        filefilter `out3' `out'   , from("</wb:topic>")               to("{p_end} \r {hline}")                               replace

        filefilter `out' `out3'   , from("<wb:topic id=1>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=2>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=3>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=4>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=5>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=6>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=7>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=8>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=9>")       to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=10>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=11>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=12>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=13>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=14>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=15>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=16>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=17>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=18>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=19>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out3' `out'   , from("<wb:topic id=20>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace
        filefilter `out' `out3'   , from("<wb:topic id=21>")      to("{p 4 4 2}{cmd:Topics:} ")                         replace

        filefilter `out3' `out'   , from("&amp;")                     to("&")                                               replace
        filefilter `out' `out3'   , from("http://")                   to("{browse \Qhttp://")                            replace
        filefilter `out3' `out'   , from(".htm")                      to(".htm\Q}")                                          replace

        filefilter `source' `source3'  , from("<wb:source id=1>")      to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=2>")      to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=3>")      to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=4>")      to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=5>")      to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=6>")      to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=7>")      to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=8>")      to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=9>")      to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=10>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=11>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=12>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=13>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=14>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=15>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=16>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=17>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=18>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=19>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=20>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=21>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=22>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=23>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=24>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=25>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=26>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=27>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=28>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=29>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=30>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=31>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=32>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=33>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=34>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=35>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=36>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=37>")     to("")                  replace
        filefilter `source3' `source'  , from("<wb:source id=38>")     to("")                  replace
        filefilter `source' `source3'  , from("<wb:source id=39>")     to("")                  replace
        filefilter `source3' `source'  , from("</wb:source>")              to("")                  replace
    }

        noi di ""
        noi di ""
        noi di ""
        noi di as text "Metadata: " as res "`indicator1'"
        noi type `out', smcl
        noi di ""
        noi di ""

        file open `source2'  using `source' , read
        file read `source2' line
        file close `source2'

        local line = trim("`line'")

        return local source         "`line'"
        return local varlabel       "`labvar'"
        return local indicator      "`indicator1'"

end
