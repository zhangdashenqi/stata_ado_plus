program _viblm_dcc
version 8.2
       args coeff inc plus pos  
       capture confirm number `coeff'
       if _rc ~=0 {
           window stopbox stop "You must enter a numeric value." "Please try again."
	 }
       capture confirm number `inc'
       if _rc ~=0 {
           window stopbox stop "Increment should be a positive number." "Please try again."
	 }
       if `inc' <=0 {
           window stopbox stop "Increment should be a positive number." "Please try again."
	}

        local bchange = `coeff' + (`plus')*`inc'
        local bchanges = string(`bchange', "%4.2f")
        ._viblm_dlg.main.ex_`pos'.setvalue  "`bchanges'" 

       _viblm_update 0

end
