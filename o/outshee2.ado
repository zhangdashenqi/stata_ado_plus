*! version 1.0, 12Jul2000, J.Hendrickx@mailbox.kun.nl  (STB-61: dm73.3)
/*
Enhanced outsheet, appends a number to "filename" if it already exists.
This stops after 20 attempts, in that cases something is wrong or the user 
needs to clean out his/her directory/folder.

Direct comments to: 

John Hendrickx <J.Hendrickx@mailbox.kun.nl>
Nijmegen Business School
University of Nijmegen
P.O. Box 9108
6500 HK Nijmegen
The Netherlands 

Available at
http://baserv.uci.kun.nl/~johnh/desmat/stata/

Version 1.0, July 12 2000
*/

program define outshee2
  version 6

  syntax [varlist] using/ [if] [in] [, noNames noLabel noQuote Comma REPLACE ]

  #delimit ;
  capture noisily outsheet `varlist' using `using' `if' `in' ,
    `names' `label' `quote' `comma' `replace';
  #delimit cr

  * if file already exists ...
  if _rc == 602 { 
    * remove file extension, if present
    gettoken outbase : using, parse(".")
    if "$_OSDTL" == "3.1" {
      * use only the first six characters under Windows 3.1
      local outbase=substr("`outbase'",1,6)
    }
    local i 0
    while _rc ~= 0 & `i' < 20 {
      local i=`i'+1
      #delimit ;
      capture noisily outsheet `varlist' using `outbase'`i' `if' `in' ,
        `names' `label' `quote' `comma' `replace';
      #delimit cr
    }
    if _rc == 0 {
      display "Data were written to `outbase'`i'.out"
    }
    else {
      display "Unable to write data after `i' attempts"
    }
  }
  else if _rc ~= 0 {
    display `"Error when attempting "outsheet using `using'": rc="' _rc
  }
end
