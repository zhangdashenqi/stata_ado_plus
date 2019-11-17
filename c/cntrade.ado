


 * Authors:
 * Chuntao Li, Ph.D. , Zhongnan Univ. of Econ. & Law (chtl@znufe.edu.cn)
 * Xuan Zhang, Ph.D., Zhongnan Univ. of Econ. & Law (zhangx@znufe.edu.cn)
 * January 30, 2014
 * Program written by Dr. Chuntao Li and Dr. Xuan Zhang
 * Used to download stock tradding data for listed Chinese Firms
 * Original Data Source: www.163.com 
 * Please do not use this code for commerical purpose
 capture program drop cntrade

 
 program define cntrade,rclass
  
 version 12.0
  syntax anything(name=tickers),  [ path(string)]
   * path, folder to save the downloaded file 
  
  local address http://quotes.money.163.com/service/chddata.html
  local field TCLOSE;HIGH;LOW;TOPEN;LCLOSE;CHG;PCHG;TURNOVER;VOTURNOVER;VATURNOVER;TCAP;MCAP
  
   
        local start 19900101
		local end: disp %dCYND date("`c(current_date)'","DMY")    
        
        if "`path'"~="" {
          capture mkdir `path'
                       } 
                                   
        if "`path'"=="" {
          local path `c(pwd)'
                  disp "`path'"
                       }                            
   
   foreach name in `tickers' {
   
   if length("`name'")>6 {
	   disp as error `"`name' is an invalid stock code"'
	   exit 601
	     } 


	 while length("`name'")<6 {
	   local name = "0"+"`name'"
	     }
	 
    if `name'>=600000 {
    	tempname csvfile
        qui capture copy "`address'?code=0`name'&start=`start'&end=`end'&fields=`field'\\`name'.csv"  `csvfile'.csv, replace
		 if _rc~=0 {
		 disp as error `"`name' is an invalid stock code"'
	     exit 601
		  }
        }
     else {
        qui capture copy "`address'?code=1`name'&start=`start'&end=`end'&fields=`field'\\`name'.csv"  `csvfile'.csv, replace
		 if _rc~=0 {
		 disp as error `"`name' is an invalid stock code"'
	     exit 601
		  }
              }
                    
    insheet using `csvfile'.csv, clear
    capture gen date = date(v1, "YMD")
	* cntrade  issues an error message if the stock code is not existing
	if _rc != 0 {
	disp as error `"`name' is an invalid stock code"'
	exit 601
	}
    drop v1 
    format date %dCY_N_D
    label var date "Trading Date"
    rename v2 stkcd 
    capture destring stkcd, replace force ignor(')
    label var stkcd "Stock Code"
    rename v3 stknme
    label var stknme "Stock Name"
    rename v4 clsprc 
    label var clsprc "Closing Price"
    drop if clsprc==0
    rename v5 hiprc 
    label var hiprc  "Highest Price"
    rename v6 lowprc 
    label var lowprc "Lowest Price"
    rename v7 opnprc
    label var opnprc "Opening Price"
    rename v10 rit 
    label var rit "Daily Return"
    rename v11 turnover
    label var turnover "Turnover rate"
    rename v12 volume
    label var volume "Trading Volume"
    rename v13 transaction
    label var transaction "Trading Amount in RMB"
    rename v14 mktcap
    label var mktcap "Total Market Capitalization"
    
    drop v8 v9 mcap*csv
    
    sort date 
    save  `"`path'/`name'"', replace
	erase `csvfile'.csv
	
	
    }


 end 

          
 
