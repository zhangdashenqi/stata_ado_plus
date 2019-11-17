

 prog drop _all
 program define cnstock
 version 14.0
 syntax anything(name=exchange), [ path(string)]

 clear  
 set more off


	if "`path'"~="" {
			capture mkdir `"`path'"'
			} 
                                   
	if "`path'"=="" {
			local path `c(pwd)'
	        disp `"`path'"'
			} 
	if "`exchange'"== "all" {
			local exchange SHA SZM SZSM SZGE SHB SZB
			}
 foreach name in `exchange'{
	if "`name'" == "SHA" local c "11"
	else if "`name'" == "SZM" local c "12"
	else if "`name'" == "SZSM" local c "13"
	else if "`name'" == "SZGE" local c "14"
	else if "`name'" == "SHB" local c "15"
	else if "`name'" == "SZB" local c "16"
	else {
		disp as error `"`name' is an invalid exchange"'
		exit 601
         }
  

quietly {
	infix strL v 1-100000 using "http://quote.cfi.cn/stockList.aspx?t=`c'",clear
	keep if index(v,"<div id='divcontent' runat=")
	split v,p("</a></td>")
	drop v
	gen id=_n
	cap reshape long v, i(id) j(vv) 
	drop id vv
	gen stknm=ustrregexs(1) if ustrregexm(v,`".html">(.*?)\(\d"')
	gen stkcd=ustrregexs(1) if ustrregexm(v,"\((.*?)\)")
    drop v
	keep if ustrregexm(stkcd,"^000") == 1 | ustrregexm(stkcd,"^001") == 1 | ustrregexm(stkcd,"^002") == 1 | ustrregexm(stkcd,"^2") == 1 | ustrregexm(stkcd,"^3") == 1 | ustrregexm(stkcd,"^6") == 1 |ustrregexm(stkcd,"^9") == 1 
	destring stkcd,replace
	format stkcd %06.0f
	save `"`path'/`name'.dta"',replace
	}
	}
clear
foreach name in `exchange' {
	append using `"`path'/`name'.dta"'
	erase `"`path'/`name'.dta"'
	}
 
 label var stkcd stockcode
 label var stknm stockname
 di "You've got the stock names and stock codes from `exchange'"
 
 save `"`path'/cnstock.dta"',replace
 
 end
