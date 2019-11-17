*! version 1.0 dec14 2006
program define dirdes 
  syntax [anything(name=prefix)] [, n(int 0) SAVing(string asis) REPLACE]
  preserve
  clear

     tempfile allcase
     tempfile uppercase

 
  if "$S_OS" =="Windows" {
  	quietly shell ls `prefix'*.dta >`allcase'
      quietly insheet filename using `allcase', nonames clear

  } /*end of windows*/
 
  else { /*non-windows*/

     quietly  shell ls `prefix'*.DTA > `uppercase'
      
     file open u using `uppercase', read
        capture file seek u 1
        file close u
        local test = _rc
        if `test' == 0 {
           quietly insheet filename using `uppercase', nonames clear
           quietly save `uppercase', replace
                       }     
     
     quietly  shell ls `prefix'*.dta > `allcase'
       file open ac using `allcase', read
        capture file seek ac 1
        file close ac
        local test2 = _rc
        if `test2' == 0 {
           quietly insheet filename using `allcase', nonames clear
           if `test' == 0  {
           append using `uppercase'
                            }     
   	                    }
   	     else { /*test2 is not zero, meaning that allcase is empty*/
   	      if `test' == 0 {
   	      use `uppercase', clear
   	                     }
   	      else {
             display "No stata data files are found in this directory."
             exit
              }
           } /*end of else*/
         
   	                    
     } /*end of non-windows*/
     
     capture drop if filename ==.
     capture drop if filename ==""
  	quietly gen nobs =.
  	quietly gen nvar =.
    
    local obsno=1

  while `obsno' <= _N {
	local cfile = filename[`obsno']
  capture quietly describe using "`cfile'"
  quietly replace nobs=r(N) in `obsno'
  quietly replace nvar=r(k) in `obsno'
  local obsno = `obsno' + 1
	}
  
  quietly count
  if `n'!=0 {
  if (`n' <=r(N) ) {
  display in yellow "First `n' files:"
  list in 1/`n', clean
 		 }
  else {
  display in yellow "The number of files is less than `n'."
  list in 1/`r(N)', clean	 
       }
   }
  else {
  list, clean
	}

if ("`saving'" != "") {
 if (`n' ~=0 & `n'<=r(N)) {
  quietly drop if _n >`n'
   save `saving', `replace'
	           	}
 if (`n' ~= 0 & `n' >r(N) ) {
    display in hellow "The number of files is less than `n'."
    save `saving', `replace'
                }
  if (`n'==0) {
     save `saving', `replace'
                }
      }	           	

restore
end


