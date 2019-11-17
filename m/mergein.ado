*! mergein--a more automated merge procedure
*! version 1.0      Robert Farmer      (STB-29: dm38)
program define mergein
        version 3.1

        if "`1'" == "" {
           display "SYNTAX:  mergein  mergvar mergeset {mergeset var}.  QUITTING WITH NO ACTION "
           pause
           exit
        }
        if "`2'" == "" {
           display "SYNTAX:  mergein `1' mergeset {mergeset var}.  QUITTING WITH NO ACTION "
           pause
           exit
        }
        capture confirm variable `1'
        if _rc ~= 0 {
           display "`1' IS APPARENTLY NOT A VARIABLE.  QUITTING WITH NO ACTION"
           pause
           exit
        }
        capture confirm file `2'.dta
           if _rc ~= 0 {
           display "`2' IS APPARENTLY NOT A STATA DATASET.  QUITTING WITH NO ACTION"
           pause
           exit
        }

        local curname = "$S_FN"
        capture save mergein,replace
        capture drop _xxx_rmf
        capture drop _yyy_rmf

        capture bringin `2'
        if "`3'" > "" & "`3'" ~= "`1'" {
           local merge1 = "`3'"
           local mrg_var = "_xxx_rmf"
           capture confirm variable `1'
           if _rc == 0 {
              rename `1' _yyy_rmf
            }
        }
        else {
           local merge1 = "`1'"
           local mrg_var = ""
        }

        capture confirm variable `merge1'
        if _rc ~= 0 {
           display "`merge1' IS APPARENTLY NOT A VARIABLE in `2'.  QUITTING WITH NO ACTION"
           pause
           capture bringin mergein
           local setnum = 0
        }
        else {
           local setnum = 1
           sort `merge1'
           capture drop _merge
           capture save `2',replace
        }

        while `setnum' ~= 0 {
           if `setnum' == 1 {
              local mtype = ""
           }
           if `setnum' == 2 {
              local mtype = "vars"
           }
           if `setnum' == 3 {
              local mtype = "obs"
           }
           capture bringin mergein `mtype'
           if "`mrg_var'" > "" {
              capture confirm variable `merge1'
              if _rc == 0 {
                 capture rename `merge1' `mrg_var'
              }
           }
           capture rename `1' `merge1'
           local mstrsrt:sortedby
           sort `merge1'
           capture drop _merge
           capture merge `merge1' using `2'
           if _rc ~= 0 {
              local setnum = `setnum' + 1
           }
           else {
              local setnum = 0
           }
           if `setnum' == 4 {
              display "MERGEIN cannot merge `curname' and `2'.dta."
              display "If `2'.dta is much larger than `curname'"
              display "try to merge `2'.dta and `curname'."
              display "Quitting with no action."
              pause
              capture bringin mergein
              !del mergein.dta
              local setnum = 0
           }
        }

        global S_FN "`curname'"
        capture rename `merge1' `1'
        if "`mrg_var'" > "" {
           capture rename `mrg_var' `merge1'
        }
        capture sort `mstrsrt'
        capture confirm variable _yyy_rmf
        if _rc == 0 {
           local chgnme = substr("`1'",1,6)
           local chgndx = 0
           while _rc == 0 {
              local chgndx = `chgndx' + 1
              local xchg = "`chgnme'"+string(`chgndx')
              capture confirm variable `xchg'
           }
           rename _yyy_rmf `xchg'
        }
        capture drop _xxx_rmf
        !del mergein.dta

exit
end

*! bringin--use large data sets automatically
*! version 1.0      Robert Farmer      (dm21: STB-22)
program define bringin
    pause on
    version 3.0
        if "`1'" == "" {
             display "SYNTAX:   bringin filename [(nothing)| vars | obs].  Quitting with no action."
             pause
             exit
        }
        local obs = index("`1'",",") - 1
        if `obs' > 0 {
           local 1 = substr("`1'",1,`obs')
        }
        capture confirm file `1'.dta
        if _rc ~= 0 {
           display "`1' is apparently not a STATA dataset.  Quitting with no action"
           pause
           exit
       }
        quietly describe using `1', detail short
        local obs = _result(1)
        local var = _result(2)
        local width = _result(3)
	local os = _result(4)
	local vs = _result(5)
	local ws = _result(6)
	if `width'*`obs' > `ws'*`os'-10000 { 
		di _col(8) in red "insufficient total memory" 
		exit
	}
capture bmemsize using `1'
if "`2'" ~= "" {
   if "`2'" == "obs" {
     local xxx  = substr("$F6",11,index("$F6","width")-11)
     local yyy  = substr("$F6",index("$F6","width ")+6,length("$F6")-(index("$F6","width ")+6))
   }
   if "`2'" == "vars" {
     local xxx  = substr("$F5",11,index("$F5","width")-11)
     local yyy  = substr("$F5",index("$F5","width ")+6,length("$F5")-(index("$F5","width ")+6))
   }
}
else {
     local xxx  = substr("$F4",11,index("$F4","width")-11)
     local yyy  = substr("$F4",index("$F4","width ")+6,length("$F4")-(index("$F4","width ")+6))
}
     clear
     set maxvar `xxx' width `yyy'
     use `1'
     exit
end
