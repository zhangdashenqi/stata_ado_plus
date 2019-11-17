*! xtcontinue 1.0 
*! Lian Yu-Jun, Sun Yat-Sen University  2009-08-09
*! Email: arlionn@163.com
*! based on -onespell-


  program define xtcontinue, rclass
  version 10
  
  syntax varlist, Minimum(numlist max=1 >0) Generate(string) [Block(string)]
  
  quietly { 
           capture confirm new var `generate' 
           if _rc { 
                   di as err "generate() invalid" 
                   exit _rc 
           } 

           marksample touse 
           tsset 
           local panel `r(panelvar)' 
           local time `r(timevar)' 
           markout `touse' `panel' `time' 
           count if `touse' 
           if r(N) == 0 error 2000 
           
           
                      
           if "`block'" != ""{
                Ö´ÐÐonespell
           } 
           else{
                Ö´ÐÐ xtpattern
           }          

           
           
           
           
  } 
     
   
   qui capture tsset
   capture confirm e `r(panelvar)'
   if ( _rc != 0 ) {
     dis as error "You must {help tsset} your data before using {cmd:xtbalance},
> see help {help xtbalance}."
     exit
   }
   
   qui tsset
   local id   "`r(panelvar)'"
   local t    "`r(timevar)'" 
