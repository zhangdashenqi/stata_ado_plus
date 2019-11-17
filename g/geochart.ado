* Google Geochart wrapper for Stata
* Create interactive web pages with maps plotting Stata data
* 1.0.0 Sergiy Radyakin, Economist, Research Department (DECRG) The World Bank, 22 April 2013


program define geochart
  version 9.0
  syntax varlist , save(string) [ nostart replace ///
                   title(string) note(string) ///
		   region(string) width(real 556) height(real 347) ///
		   colorlow(string) colorhigh(string) ]
  
  local outcome : word 1 of `varlist'
  local country : word 2 of `varlist'
  
  if (`"`region'"'!="") local region ", region: '`region''" 
  else local region ""
  
  if (`"`colorlow'"'=="") local colorlow "green" 
  if (`"`colorhigh'"'=="") local colorhigh "red"

  if (`"`replace'"'=="replace") capture erase `"`save'"' 

  mata geochart()
  
  display `"`nostart'"'
  
  if (`"`start'"'=="") {

    display as text "Starting: " as result "`save'"

    if (c(os) == "Windows") {
      shell "`save'"
    }

    if (c(os) == "MacOSX") {
      shell open "`save'"
    }

    if (c(os) == "Unix") {
      shell xdg-open "`save'"
    }

  }

end

*** END OF FILE
