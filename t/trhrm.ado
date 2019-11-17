
capture program drop trhrm
program trhrm
  version 10.0
local names : colfullnames e(b)

   syntax    ,Var(varlist max=1)                   ///
              [SCenario(string)]                  ///
              Timevalue(numlist)                   ///
              [graph(string)]    ///
              [graphopt(string)]                  ///
	      [ci]               ///
	      [BOOTstrap(integer 2000)]               ///
	      Level(cilevel)     ///
	      [Keep]     ///
	      [PREfix(string)]     ///
	      [y1]               ///
              [DEbug]                                             

     



   local all_dummies "`_dta[__xi__Vars__To__Drop__]'"
   local dummy_list ""
   foreach cur_dummy of local all_dummies {
        local dummy_label: variable label `cur_dummy'
	tokenize "`dummy_label'", parse("==")
	if ("`1'"=="`var'") {
           local dummy_list "`dummy_list' `cur_dummy'"

	}

        
   } 

   if trim("`var'")=="" {
     exit
   }
   else{
     local hr `var'

   }



   if trim("`hr'")=="" {
  	  exit
   } 
  
   if "`scenario'"!="" {
	   local scenario_command `scenario'
	   local scenario_command_remain `scenario'
	   local scenario_covariate_number = wordcount("`scenario_command'")

   }     


   if "`prefix'"!="" {
	local prefix_string `prefix'
   }

   if "`graph'"!="" {
     if ("`graph'"!="hz" & "`graph'"!="sv" & "`graph'"!="ds" & "`graph'"!="hr"){
       
       error 197
     
     }


   }       

   local number_scenario_covariate = wordcount("`scenario_command'")
   while trim(`"`scenario_command_remain'"')!=""{

     gettoken current_scenario_covariate scenario_command_remain: scenario_command_remain, parse("=")
    
     gettoken equal_sign scenario_command_remain: scenario_command_remain, parse("=")
     
     gettoken current_covariate_value scenario_command_remain: scenario_command_remain, parse(" ")
   
     local s_c_`current_scenario_covariate'=`current_covariate_value'
     
     if("`debug'"!=""){
     di "s_c_`current_scenario_covariate':`current_covariate_value'"
     }
   }   

   local number_scenario_covariate = wordcount("`scenario_command'")
   forvalues i = 1(1)`number_scenario_covariate' {

     local current_scenario = word("`scenario_command'",`i')
     gettoken current_scenario_covariate scenario_command_remain: current_scenario, parse("= ")
    
     gettoken equal_sign current_covariate_value: scenario_command_remain, parse("= ")
   
     local s_c_`current_scenario_covariate'=`current_covariate_value'
     
   }

   mat coefficient_vector=e(b)
   local colnames_all_remain : colfullnames e(b)
   if("`debug'"!=""){
   mat li e(b)
   }
   


   local number_colnames_all = wordcount("`colnames_all'")
   
   local k=1
   while trim(`"`colnames_all_remain'"')!=""{
   

   
            gettoken cur_group_str colnames_all_remain: colnames_all_remain, parse(":")
    
            gettoken colon_sign colnames_all_remain: colnames_all_remain, parse(":")
     
            gettoken current_eb_covariate colnames_all_remain: colnames_all_remain, parse(" ")
   

            if("`debug'"!=""){
            di "-------------------------" "`k':`cur_group_str'-`current_eb_covariate'"  "-----------------------------"       
            }
	    local is_interesting_dummy = 0
            foreach x of local dummy_list {
                if("`current_eb_covariate'"=="`x'"){
                  local is_interesting_dummy = 1
		}
            }	    
            if(`is_interesting_dummy'==0){
            
               mat current_coefficient=coefficient_vector[1,"`cur_group_str':`current_eb_covariate'"]        
               local current_coefficient_value = current_coefficient[1,1]
               
                
               if("`cur_group_str'"=="lny0"){
             

                 if (substr("`current_eb_covariate'",-5,5)!="_cons"){
                   if (trim("`s_c_`current_eb_covariate''")!=""){
     
                    
                                  
                      local lny0_reference=`lny0_reference'+ 1*`current_coefficient_value' *`s_c_`current_eb_covariate''
                 
                   }
                   else {
                      di as error "need to specify scenario value for `current_eb_covariate'"
                      error 197
                   }
                 }
                 else{
                 
                                                    
                   local lny0_reference=`lny0_reference'+ 1*`current_coefficient_value'
                 }
              
                if("`debug'"!=""){
                di "lny0_reference:`lny0_reference'".
                }
               }
               
               else if("`cur_group_str'"=="mu"){
             

                 if (substr("`current_eb_covariate'",-5,5)!="_cons"){
                   if (trim("`s_c_`current_eb_covariate''")!=""){
     
                    
                                  
                      local mu_reference=`mu_reference'+ 1*`current_coefficient_value' *`s_c_`current_eb_covariate''
                      
                   }
                   else {
                      di as error "need to specify scenario value for `current_eb_covariate'"
                      error 197
                   }
                 }
                 else{
                 
                                                    
                   local mu_reference=`mu_reference'+ 1*`current_coefficient_value'
                 }
              
                if("`debug'"!=""){
                di "mu_reference:`mu_reference'"
                }
               }

               else if("`cur_group_str'"=="lgtp"){
             

                 if (substr("`current_eb_covariate'",-5,5)!="_cons"){
                   if (trim("`s_c_`current_eb_covariate''")!=""){
     
                    
                                  
                      local lgtp_reference=`lgtp_reference'+ 1*`current_coefficient_value' *`s_c_`current_eb_covariate''
                      
                   }
                   else {
                      di as error "need to specify scenario value for `current_eb_covariate'"
                      error 197
                   }
                 }
                 else{
                 
                                                    
                   local lgtp_reference=`lgtp_reference'+ 1*`current_coefficient_value'
                 }
              
                if("`debug'"!=""){
                di "lgtp_reference:`lgtp_reference'"
                }
               }
            


            }
            else{
              *di "***`cur_group_str'-`current_eb_covariate'"    
            }



    local k = `k' + 1

   }
   
  



   
   foreach dummy_var_interest of varlist `dummy_list' {

             
      local c_m_`dummy_var_interest'=""     
      local c_l_`dummy_var_interest'=""    
      local c_lp_`dummy_var_interest'=""    
      





      
      
      local colnames_all_remain : colfullnames e(b)
      while trim(`"`colnames_all_remain'"')!=""{
          
            gettoken cur_group_str colnames_all_remain: colnames_all_remain, parse(":")
    
            gettoken colon_sign colnames_all_remain: colnames_all_remain, parse(":")
     
            gettoken current_eb_covariate colnames_all_remain: colnames_all_remain, parse(" ")
            
            if("`debug'"!=""){
            di "ttttttttest:`current_eb_covariate'" 
            }         
            if(strpos("`current_eb_covariate'","`dummy_var_interest'")!=0){
                 
               if("`cur_group_str'"=="lny0"){
               
                  mat dummy_coefficient=coefficient_vector[1,"`cur_group_str':`current_eb_covariate'"] 
                  local dummy_coefficient_value = dummy_coefficient[1,1]               
             
                  local c_l_`dummy_var_interest' = `dummy_coefficient_value'   
                  if("`debug'"!=""){
                  di  "c_l_`dummy_var_interest':`c_l_`dummy_var_interest''"      
                  }
               }               
               else if("`cur_group_str'"=="mu"){
               
                  mat dummy_coefficient=coefficient_vector[1,"`cur_group_str':`current_eb_covariate'"] 
                  local dummy_coefficient_value = dummy_coefficient[1,1]               
             

                  local c_m_`dummy_var_interest' = `dummy_coefficient_value'
                  if("`debug'"!=""){
                  di  "c_m_`dummy_var_interest':`c_m_`dummy_var_interest''"                   
                  }
               }
               else if("`cur_group_str'"=="lgtp"){
               
                  mat dummy_coefficient=coefficient_vector[1,"`cur_group_str':`current_eb_covariate'"] 
                  local dummy_coefficient_value = dummy_coefficient[1,1]               
             

                  local c_lp_`dummy_var_interest' = `dummy_coefficient_value'
                  if("`debug'"!=""){
                  di  "c_lp_`dummy_var_interest':`c_lp_`dummy_var_interest''"                   
                  }
               }
 


              
                           
            }

           
          
      }



      
      if (trim("`c_l_`dummy_var_interest''")==""){                 
        local l_`dummy_var_interest' =`lny0_reference'
      }
      else{
  
        local l_`dummy_var_interest' =`lny0_reference'+ 1*`c_l_`dummy_var_interest''          
      }


      if (trim("`c_m_`dummy_var_interest''")==""){                 
        local m_`dummy_var_interest' =`mu_reference'
      }
      else{
        local m_`dummy_var_interest' =`mu_reference'+ 1*`c_m_`dummy_var_interest''          
      }
      if("`debug'"!=""){
	      di "l_`dummy_var_interest':`l_`dummy_var_interest''"
	      di "m_`dummy_var_interest':`m_`dummy_var_interest''"
      }
  
                  

      if (trim("`c_lp_`dummy_var_interest''")==""){                 
        local lp_`dummy_var_interest' =`lgtp_reference'
      }
      else{
        local lp_`dummy_var_interest' =`lgtp_reference'+ 1*`c_lp_`dummy_var_interest''          
      }
      if("`debug'"!=""){
	      di "l_`dummy_var_interest':`l_`dummy_var_interest''"
	      di "m_`dummy_var_interest':`m_`dummy_var_interest''"
	      di "lp_`dummy_var_interest':`lp_`dummy_var_interest''"
      }


















                                    

   }
    






if(trim("`graph'")!="" | trim("`keep'")!=""){
	tempvar XCat
        quietly: tab `var',gen(`XCat')
  

	local numcat=r(r)
	local i 1
	while `i'<=`numcat' {
                tempvar label`i'
		local `label`i'' : variable label `XCat'`i'
		local i=`i'+1
	}
	local i 1
	tempvar vlbl_reference
	local `vlbl_reference'="``label`i'''"
	local i=`i'+1
	foreach dummy_var_interest of varlist `dummy_list' {

		tempvar vlb_`dummy_var_interest'
		local `vlb_`dummy_var_interest''="``label`i'''"
		local i=`i'+1
	}      

}



local num_timevalue=0
foreach _timevalue of local timevalue{
 local num_timevalue=`num_timevalue'+1
}

if("`graph'"=="hr" | trim("`keep'")!=""){    
	if `num_timevalue' > _N { 
		 quietly: set obs `num_timevalue'
	}

}

if("`ci'"==""){

	   local i_hr=1
	   tempvar hr_t
	   quietly: gen `hr_t'=.
	   label variable `hr_t' `"Specified Time Value"'
	   foreach dummy_var_interest of varlist `dummy_list' {
		tempvar hrv_`dummy_var_interest' 
		quietly: gen `hrv_`dummy_var_interest''=. 
		label variable `hrv_`dummy_var_interest'' `"HR(``vlb_`dummy_var_interest''' v.s. ``vlbl_reference'')"'
	   }
           set more 0
	   foreach _timevalue of local timevalue{




		   local y0=exp(`lny0_reference')

		   local _y0=`y0'

		   local _mu=`mu_reference'

		   local _lgtp=`lgtp_reference'
                   local _p=exp(`_lgtp')/(1+exp(`_lgtp'))



		   local f0=exp(ln(`_y0')-.5*(ln(2*_pi*(`_timevalue'^3))+(`_y0'+`_mu'*`_timevalue')^2/`_timevalue')+ln(`_p'))


		   local S0=exp(ln(`_p'*(normal((`_mu'*`_timevalue'+`_y0')/sqrt(`_timevalue'))/*
											 */ -exp(-2*`_y0'*`_mu')*normal((`_mu'*`_timevalue'-`_y0')/sqrt(`_timevalue')))+(1-`_p')))

		   local h0=`f0'/`S0'


		   quietly: replace `hr_t'=`_timevalue' if _n==`i_hr'



		   foreach dummy_var_interest of varlist `dummy_list' {





			   local y0_`dummy_var_interest'=exp(`l_`dummy_var_interest'')

			   local _y0_`dummy_var_interest'=`y0_`dummy_var_interest''

			   local _m_`dummy_var_interest'=`m_`dummy_var_interest''

			   local _lp_`dummy_var_interest'=`lp_`dummy_var_interest''

			   local _p_`dummy_var_interest'=exp(`_lp_`dummy_var_interest'')/(1+exp(`_lp_`dummy_var_interest''))


			   local f_`dummy_var_interest'=exp(ln(`_y0_`dummy_var_interest'')-.5*(ln(2*_pi*(`_timevalue'^3))+(`_y0_`dummy_var_interest''+`_m_`dummy_var_interest''*`_timevalue')^2/`_timevalue')+ln(`_p_`dummy_var_interest''))

			   local S_`dummy_var_interest'=exp(ln(`_p_`dummy_var_interest''*(normal((`_m_`dummy_var_interest''*`_timevalue'+`_y0_`dummy_var_interest'')/sqrt(`_timevalue'))/*
																			       */ -exp(-2*`_y0_`dummy_var_interest''*`_m_`dummy_var_interest'')*normal((`_m_`dummy_var_interest''*`_timevalue'-`_y0_`dummy_var_interest'')/sqrt(`_timevalue')))+(1-`_p_`dummy_var_interest'')))


			   local h_`dummy_var_interest'=`f_`dummy_var_interest''/`S_`dummy_var_interest''

			   local hr_`dummy_var_interest'=`h_`dummy_var_interest''/`h0'


			   quietly: replace `hrv_`dummy_var_interest''=`hr_`dummy_var_interest'' if _n==`i_hr'

		   }

		   local timetype="Time"

	           di ""
		   di as text "Hazard Ratio for Scenario " as result "`scenario'"  as text ", at `timetype'  =  " as result "`_timevalue'"
		   di as text "{hline 15}{c TT}{hline 13}"
		   di as text "           var {c |} Hazard Ratio" 
		   di as text "{hline 15}{c +}{hline 13}"

		   local loop=0
		   foreach dummy_var_interest of varlist `dummy_list' {
			   if(`loop'!=0){
				   di as text "{hline 15}{c +}{hline 13}"  
			   } 
			   di as text %15s abbrev("`dummy_var_interest'",15) "{c |}" as result %13.0g `hr_`dummy_var_interest''
				   local loop=`loop'+1         
		   }
		   di as text "{hline 15}{c BT}{hline 13}"  



		   local i_hr = `i_hr' + 1
	   }

           if("`graph'"=="hr"){

		local num_dummy_var_interest=0
		foreach dummy_var_interest of varlist `dummy_list' {
		 local num_dummy_var_interest=`num_dummy_var_interest'+1
		}
                
		local combine_command ""
		foreach dummy_var_interest of varlist `dummy_list' {
			   local line_command ""
			   if("`y1'"==""){
			     local line_command `line_command' (connected `hrv_`dummy_var_interest'' `hr_t', sort ) 
			   }
			   else{
			     local line_command `line_command' (connected `hrv_`dummy_var_interest'' `hr_t', sort yline(1,lpattern(shortdash)) ymtick(1) ymlabel(1)) 

			   }

			   graph twoway `line_command',name(HazardRatio`dummy_var_interest',replace) subtitle(`"``vlb_`dummy_var_interest''' v.s. ``vlbl_reference''"') ytitle("Estimated Hazard Ratio")
			   local combine_command `combine_command' HazardRatio`dummy_var_interest'
		}
		if(`num_dummy_var_interest'>1){
		  gr combine `combine_command',ycommon name(HazardRatioComparison,replace)
		}
		
	   }


           if("`keep'"=="keep"){
		   capture drop `prefix_string'hr_t
		   rename `hr_t' `prefix_string'hr_t
		   foreach dummy_var_interest of varlist `dummy_list' {
			capture drop `prefix_string'hr`dummy_var_interest' 
			rename `hrv_`dummy_var_interest'' `prefix_string'hr`dummy_var_interest' 
		   }
	   } 
 
}
else {







 


 


 







   if("`debug'"!=""){
      di "***********&&&&&&&&&&&&&************"
   }

   mat coefficient_vector=e(b)
   local colnames_all_remain : colfullnames e(b)
   if("`debug'"!=""){
   mat li e(b)
   di "here:`colnames_all_remain'"
   }
   local flag_lny0=0
   local flag_mu=0
   local flag_lgtp=0
   local k=1
   while trim(`"`colnames_all_remain'"')!=""{
   

            gettoken cur_group_str colnames_all_remain: colnames_all_remain, parse(":")
    
            gettoken colon_sign colnames_all_remain: colnames_all_remain, parse(":")
     
            gettoken current_eb_covariate colnames_all_remain: colnames_all_remain, parse(" ")
   

            if("`debug'"!=""){
            di "-------------------------" "`k':`cur_group_str'-`current_eb_covariate'"  "-----------------------------"       
            }

	    local is_interesting_dummy = 0
            foreach x of local dummy_list {
                if("`current_eb_covariate'"=="`x'"){
                  local is_interesting_dummy = 1
		}
            }
            if(`is_interesting_dummy'==0){
            
            
               mat current_coefficient=coefficient_vector[1,"`cur_group_str':`current_eb_covariate'"]        
               
                
               if("`cur_group_str'"=="lny0"){
             

                 if (substr("`current_eb_covariate'",-5,5)!="_cons"){
                   if (trim("`s_c_`current_eb_covariate''")!=""){
     
                    

		      if ("`flag_lny0'"== "0"){
                        local flag_lny0=1

		        local lny0_reference_bc = "_b[`cur_group_str':`current_eb_covariate']*`s_c_`current_eb_covariate''"
                      }
                      else if ("`flag_lny0'"== "1"){

		        local lny0_reference_bc = "`lny0_reference_bc'+_b[`cur_group_str':`current_eb_covariate']*`s_c_`current_eb_covariate''"
                      }

                       
                 
                   }
                   else {
                      di as error "need to specify scenario value for `current_eb_covariate'"
                      error 197
                   }
                 }
                 else{
                 

		   if ("`flag_lny0'"== "0"){
			   local flag_lny0=1

				   local lny0_reference_bc = "_b[`cur_group_str':`current_eb_covariate']"
		   }
		   else if ("`flag_lny0'"== "1"){

			   local lny0_reference_bc = "`lny0_reference_bc'+_b[`cur_group_str':`current_eb_covariate']"
		   }

                 }
              
                if("`debug'"!=""){
			di "lny0_reference:`lny0_reference'".
                }

		if("`debug'"!=""){
			di "lny0_reference_bc:`lny0_reference_bc'"
		}   
               }
           

               else if("`cur_group_str'"=="mu"){
 
                 if (substr("`current_eb_covariate'",-5,5)!="_cons"){
                   if (trim("`s_c_`current_eb_covariate''")!=""){
     

		      if ("`flag_mu'"== "0"){
                        local flag_mu=1

		        local mu_reference_bc = "_b[`cur_group_str':`current_eb_covariate']*`s_c_`current_eb_covariate''"
                      }
                      else if ("`flag_mu'"== "1"){

		        local mu_reference_bc = "`mu_reference_bc'+_b[`cur_group_str':`current_eb_covariate']*`s_c_`current_eb_covariate''"
                      }

                       
                 
                   }
                   else {
                      di as error "need to specify scenario value for `current_eb_covariate'"
                      error 197
                   }
                 }
                 else{
                 

		   if ("`flag_mu'"== "0"){
			   local flag_mu=1

				   local mu_reference_bc = "_b[`cur_group_str':`current_eb_covariate']"
		   }
		   else if ("`flag_mu'"== "1"){

			   local mu_reference_bc = "`mu_reference_bc'+_b[`cur_group_str':`current_eb_covariate']"
		   }

                 }
              
                if("`debug'"!=""){
			di "mu_reference:`mu_reference'".
                }            
		if("`debug'"!=""){
			di "mu_reference_bc:`mu_reference_bc'"
		}   

               }

            





               else if("`cur_group_str'"=="lgtp"){
 
                 if (substr("`current_eb_covariate'",-5,5)!="_cons"){
                   if (trim("`s_c_`current_eb_covariate''")!=""){
     

		      if ("`flag_lgtp'"== "0"){
                        local flag_lgtp=1

		        local lgtp_reference_bc = "_b[`cur_group_str':`current_eb_covariate']*`s_c_`current_eb_covariate''"
                        
                      }
                      else if ("`flag_lgtp'"== "1"){

		        local lgtp_reference_bc = "`lgtp_reference_bc'+_b[`cur_group_str':`current_eb_covariate']*`s_c_`current_eb_covariate''"
                      }

                      
                 
                   }
                   else {
                      di as error "need to specify scenario value for `current_eb_covariate'"
                      error 197
                   }
                 }
                 else{
                 

		   if ("`flag_lgtp'"== "0"){
			   local flag_lgtp=1

				   local lgtp_reference_bc = "_b[`cur_group_str':`current_eb_covariate']"
		   }
		   else if ("`flag_lgtp'"== "1"){

			   local lgtp_reference_bc = "lgtp_reference_bc'+_b[`cur_group_str':`current_eb_covariate']"
		   }

                 }
               
                 local p_reference_bc="exp(`lgtp_reference_bc')/(1+exp(`lgtp_reference_bc'))"  

                if("`debug'"!=""){
			di "lgtp_reference:`lgtp_reference'".
                }            
		if("`debug'"!=""){
			di "p_reference_bc:`p_reference_bc'"
		}   

               }


            }
            else{
              *di "***`cur_group_str'-`current_eb_covariate'"    
            }



	    local k = `k' + 1

   }




   local last_para "`e(stthregm_para)'"



   local i_hr=1
   tempvar hr_t
   quietly: gen `hr_t'=.
   label variable `hr_t' `"Specified Time Value"'
   foreach dummy_var_interest of varlist `dummy_list' {
	tempvar hrv_`dummy_var_interest' hrl_`dummy_var_interest' hru_`dummy_var_interest'
	quietly: gen `hrv_`dummy_var_interest''=. 
	quietly: gen `hrl_`dummy_var_interest''=. 
	quietly: gen `hru_`dummy_var_interest''=. 
	label variable `hrv_`dummy_var_interest'' `"HR(``vlb_`dummy_var_interest''' v.s. ``vlbl_reference'')"'
	label variable `hrl_`dummy_var_interest'' `"Upper Limit"'
	label variable `hru_`dummy_var_interest'' `"Lower Limit"'
   }




   foreach _timevalue of local timevalue{

	   local bc_h0 (exp(ln(exp((`lny0_reference_bc')))-.5*(ln(2*_pi*(`_timevalue'^3))+(exp((`lny0_reference_bc'))+(`mu_reference_bc')*`_timevalue')^2/`_timevalue')+ln(`p_reference_bc')))/(exp(ln(`p_reference_bc'*(normal(((`mu_reference_bc')*`_timevalue'+exp((`lny0_reference_bc')))/sqrt(`_timevalue'))/*
     */ -exp(-2*exp((`lny0_reference_bc'))*(`mu_reference_bc'))*normal(((`mu_reference_bc')*`_timevalue'-exp((`lny0_reference_bc')))/sqrt(`_timevalue')))+(1-`p_reference_bc'))))
           *di "bc_h0:`bc_h0'"



	   local colnames_all : colfullnames e(b)






	   quietly: replace `hr_t'=`_timevalue' if _n==`i_hr'

	   foreach dummy_var_interest of varlist `dummy_list' {
			   local l_b_`dummy_var_interest'="`lny0_reference_bc'"
			   local m_b_`dummy_var_interest'="`mu_reference_bc'"
                           local lp_b_`dummy_var_interest'="`lgtp_reference_bc'"



			   local colnames_all_remain="`colnames_all'"
			   while trim(`"`colnames_all_remain'"')!=""{

				           gettoken cur_group_str colnames_all_remain: colnames_all_remain, parse(":")

					   gettoken colon_sign colnames_all_remain: colnames_all_remain, parse(":")

					   gettoken current_eb_covariate colnames_all_remain: colnames_all_remain, parse(" ")

					   if("`debug'"!=""){
						   *di "lalalalalal:`current_eb_covariate'" 
					   }         

					   if(strpos("`current_eb_covariate'","`dummy_var_interest'")!=0){


						   if("`cur_group_str'"=="lny0"){

							   local l_b_`dummy_var_interest'="`lny0_reference_bc'+_b[`cur_group_str':`current_eb_covariate']"
							   if("`debug'"!=""){
								   di  "xxxxxxx:l_b_`dummy_var_interest':`l_b_`dummy_var_interest''"      
							   }




						   }               
						   else if("`cur_group_str'"=="mu"){

							   local m_b_`dummy_var_interest'="`mu_reference_bc'+_b[`cur_group_str':`current_eb_covariate']"
							   if("`debug'"!=""){
								   di  "yyyyyyy:m_b_`dummy_var_interest':`m_b_`dummy_var_interest''"      
							   }
						   }
						   else if("`cur_group_str'"=="lgtp"){

							   local lp_b_`dummy_var_interest'="`lgtp_reference_bc'+_b[`cur_group_str':`current_eb_covariate']"
							   local p_bc_`dummy_var_interest'="exp(`lp_b_`dummy_var_interest'')/(1+exp(`lp_b_`dummy_var_interest''))" 
							   if("`debug'"!=""){
								   di  "yyyyyyy:lp_b_`dummy_var_interest':`lp_b_`dummy_var_interest''"   
								   di  "yyyyyyy:p_bc_`dummy_var_interest':`p_bc_`dummy_var_interest''"   
   
							   }
						   }
					   }
		 	    }


			    local b_h_`dummy_var_interest' (exp(ln(exp((`l_b_`dummy_var_interest'')))-.5*(ln(2*_pi*(`_timevalue'^3))+(exp((`l_b_`dummy_var_interest''))+(`m_b_`dummy_var_interest'')*`_timevalue')^2/`_timevalue')+ln(`p_bc_`dummy_var_interest'')))/(exp(ln(`p_bc_`dummy_var_interest''*(normal(((`m_b_`dummy_var_interest'')*`_timevalue'+exp((`l_b_`dummy_var_interest'')))/sqrt(`_timevalue'))/*
     */ -exp(-2*exp((`l_b_`dummy_var_interest''))*(`m_b_`dummy_var_interest''))*normal(((`m_b_`dummy_var_interest'')*`_timevalue'-exp((`l_b_`dummy_var_interest'')))/sqrt(`_timevalue')))+(1-`p_bc_`dummy_var_interest''))))
			    if("`debug'"!=""){
				    di  "zzzzzzzz: b_h_`dummy_var_interest':`b_h_`dummy_var_interest''"      
			    }   
			    di ""
			    di ""
			    trbootstrap hr=((`b_h_`dummy_var_interest'')/(`bc_h0')), reps(`bootstrap') level(`level'): stthregm `last_para'
		            mat observed_stat_vector=e(b)
			    local h_b_`dummy_var_interest'=observed_stat_vector[1,1]
			    mat persentile_ci_vector=e(ci_percentile)
			    local h_l_`dummy_var_interest'=persentile_ci_vector[1,1]
			    local h_u_`dummy_var_interest'=persentile_ci_vector[2,1]


			    quietly: replace `hrv_`dummy_var_interest''=`h_b_`dummy_var_interest'' if _n==`i_hr'
			    quietly: replace `hrl_`dummy_var_interest''=`h_l_`dummy_var_interest'' if _n==`i_hr'
			    quietly: replace `hru_`dummy_var_interest''=`h_u_`dummy_var_interest'' if _n==`i_hr'


	   }





	   quietly:stthregm `last_para'





	   local timetype="Time"

           di as text ""
	   di as text "Hazard Ratio for Scenario " as result "`scenario'"  as text ", at `timetype'  =  " as result "`_timevalue'"
	   di as text "{hline 15}{c TT}{hline 14}{c TT}{hline 22}"
	   di as text "           var {c |} Hazard Ratio {c |} [`level'% Percentile C.I.] " 
	   di as text "{hline 15}{c +}{hline 14}{c +}{hline 22}"




	   local loop=0
	   foreach dummy_var_interest of varlist `dummy_list' {
		   if(`loop'!=0){
			   di as text "{hline 15}{c +}{hline 14}{c +}{hline 22}" 
		   } 
		   di as text %15s abbrev("`dummy_var_interest'",15) "{c |}" as result %13.0g `h_b_`dummy_var_interest'' as text " {c |}" as result %10.0g `h_l_`dummy_var_interest'' as text "  " as result %10.0g `h_u_`dummy_var_interest''  
			   local loop=`loop'+1         
	   }
	   di as text "{hline 15}{c BT}{hline 14}{c BT}{hline 22}"  




	   local i_hr = `i_hr' + 1
   }

	   if("`graph'"=="hr"){







		local num_dummy_var_interest=0
		foreach dummy_var_interest of varlist `dummy_list' {
		 local num_dummy_var_interest=`num_dummy_var_interest'+1
		}
                
		local combine_command ""
		foreach dummy_var_interest of varlist `dummy_list' {
			   local line_command ""
			   if("`y1'"==""){
				   local line_command ""
				   local line_command `line_command' (rcap `hrl_`dummy_var_interest'' `hru_`dummy_var_interest'' `hr_t', sort)
				   local line_command `line_command' (connected `hrv_`dummy_var_interest'' `hr_t', sort ) 

			   }
			   else{
				   local line_command ""
				   local line_command `line_command' (rcap `hrl_`dummy_var_interest'' `hru_`dummy_var_interest'' `hr_t', sort)
				   local line_command `line_command' (connected `hrv_`dummy_var_interest'' `hr_t', sort yline(1,lpattern(shortdash)) ymtick(1) ymlabel(1)) 

			   }

			   graph twoway `line_command',name(HazardRatio`dummy_var_interest',replace) ytitle("Estimated Hazard Ratio")
			   local combine_command `combine_command' HazardRatio`dummy_var_interest'
		}

		if(`num_dummy_var_interest'>1){
		  gr combine `combine_command',ycommon  name(HazardRatioComparison,replace)
		}
		





	   } 

	   if("`keep'"=="keep"){


		   capture drop `prefix_string'hr_t 
		   rename `hr_t' `prefix_string'hr_t
		   foreach dummy_var_interest of varlist `dummy_list' {
			capture drop `prefix_string'hr`dummy_var_interest' `prefix_string'hrll`dummy_var_interest' `prefix_string'hrul`dummy_var_interest'
			rename `hrv_`dummy_var_interest'' `prefix_string'hr`dummy_var_interest' 
			rename `hrl_`dummy_var_interest'' `prefix_string'hrll`dummy_var_interest' 
			rename `hru_`dummy_var_interest'' `prefix_string'hrul`dummy_var_interest' 
		   }
	   }


 

}


















   if ("`graph'"=="hz" | "`graph'"=="sv" | "`graph'"=="ds"){
     
        if("`debug'"!=""){
		      di "not analytical time"
        }
        
        tempvar var_time 
         

        qui gen `var_time'= _t        


        label variable `var_time' "Analysis Time"

        if(trim("`ci'")!=""){

	   local y0=exp(`lny0_reference')

	   local _y0=`y0'

	   local _mu=`mu_reference'

	   local _lgtp=`lgtp_reference'
	   local _p=exp(`_lgtp')/(1+exp(`_lgtp'))
	   foreach dummy_var_interest of varlist `dummy_list' {

		   local y0_`dummy_var_interest'=exp(`l_`dummy_var_interest'')

		   local _y0_`dummy_var_interest'=`y0_`dummy_var_interest''

		   local _m_`dummy_var_interest'=`m_`dummy_var_interest''

		   local _lp_`dummy_var_interest'=`lp_`dummy_var_interest''

		   local _p_`dummy_var_interest'=exp(`_lp_`dummy_var_interest'')/(1+exp(`_lp_`dummy_var_interest''))
	   }
        }


        tempvar var_f0 var_S0 var_h0
        qui gen `var_f0'=exp(ln(`_y0')-.5*(ln(2*_pi*(`var_time'^3))+(`_y0'+`_mu'*`var_time')^2/`var_time')+ln(`_p'))
  

        qui gen `var_S0'=exp(ln(`_p'*(normal((`_mu'*`var_time'+`_y0')/sqrt(`var_time'))/*
											 */ -exp(-2*`_y0'*`_mu')*normal((`_mu'*`var_time'-`_y0')/sqrt(`var_time')))+(1-`_p')))
         
        qui gen `var_h0'=`var_f0'/`var_S0'
   
     
     
   
        if("`graph'"=="hz"){    
				 label variable `var_h0' `"``vlbl_reference''"' 
				 local line_command `var_h0' `var_time'
				 local graphoption_command `"title(Hazard Function) ytitle(Estimated h(t)) name(hazard,replace)"'
				 local name_command `"name(hazard,replace)"'
        }
        else if ("`graph'"=="sv"){
				 label variable `var_S0' `"``vlbl_reference''"'
				 local line_command `var_S0' `var_time'     
				 local graphoption_command `" title(Survival Function) ytitle(Estimated S(t)) name(survival,replace)"'
				 local name_command `"name(survival,replace)"'
        }
        else if ("`graph'"=="ds"){
				 label variable `var_f0' `"``vlbl_reference''"'
				 local line_command `var_f0' `var_time'        
				 local graphoption_command `"title(Probability Density Function) ytitle(Estimated f(t)) name(density,replace)"'
				 local name_command `"name(density,replace)"'
        }   
        

        if ("`graphopt'"==""){ 
		         foreach dummy_var_interest of varlist `dummy_list' {
		   
								tempvar v_f_`dummy_var_interest' v_S_`dummy_var_interest' v_h_`dummy_var_interest'
									        
					
					
			                                        qui gen `v_f_`dummy_var_interest''=exp(ln(`_y0_`dummy_var_interest'')-.5*(ln(2*_pi*(`var_time'^3))+(`_y0_`dummy_var_interest''+`_m_`dummy_var_interest''*`var_time')^2/`var_time')+ln(`_p_`dummy_var_interest''))

								*qui gen `v_f_`dummy_var_interest''=exp((ln(`_y0_`dummy_var_interest'')-.5*(ln(2*_pi*(`var_time'^3))+(`_y0_`dummy_var_interest''+`_m_`dummy_var_interest''*`var_time')^2/`var_time')))
								  

								qui gen `v_S_`dummy_var_interest''=exp(ln(`_p_`dummy_var_interest''*(normal((`_m_`dummy_var_interest''*`var_time'+`_y0_`dummy_var_interest'')/sqrt(`var_time'))/*
																			       */ -exp(-2*`_y0_`dummy_var_interest''*`_m_`dummy_var_interest'')*normal((`_m_`dummy_var_interest''*`var_time'-`_y0_`dummy_var_interest'')/sqrt(`var_time')))+(1-`_p_`dummy_var_interest'')))

								*qui gen `v_S_`dummy_var_interest''=exp(ln(normal((`_m_`dummy_var_interest''*`var_time'+`_y0_`dummy_var_interest'')/sqrt(`var_time'))/*
											   */ -exp(-2*`_y0_`dummy_var_interest''*`_m_`dummy_var_interest'')*normal((`_m_`dummy_var_interest''*`var_time'-`_y0_`dummy_var_interest'')/sqrt(`var_time'))))
								         
								qui gen `v_h_`dummy_var_interest''=`v_f_`dummy_var_interest''/`v_S_`dummy_var_interest''
						           
							  if("`graph'"=="hz"){     
									 label variable `v_h_`dummy_var_interest'' `"``vlb_`dummy_var_interest'''"'
									 local line_command `line_command' || line `v_h_`dummy_var_interest'' `var_time' 
							  }
							  else if ("`graph'"=="sv"){
									 label variable `v_S_`dummy_var_interest'' `"``vlb_`dummy_var_interest'''"'
									 local line_command `line_command' || line `v_S_`dummy_var_interest'' `var_time'        
							  }
							  else if ("`graph'"=="ds"){
									 label variable `v_f_`dummy_var_interest'' `"``vlb_`dummy_var_interest'''"'
									 local line_command `line_command' || line `v_f_`dummy_var_interest'' `var_time'           
							  }   
		
		        }
		
		
		        preserve
		        sort `var_time' 
		
		
		        
		        line `line_command',`graphoption_command'
		        restore
		    }   
        else{
		        foreach dummy_var_interest of varlist `dummy_list' {
		   
								tempvar v_f_`dummy_var_interest' v_S_`dummy_var_interest' v_h_`dummy_var_interest'
									        
					
					

                                                                qui gen `v_f_`dummy_var_interest''=exp(ln(`_y0_`dummy_var_interest'')-.5*(ln(2*_pi*(`var_time'^3))+(`_y0_`dummy_var_interest''+`_m_`dummy_var_interest''*`var_time')^2/`var_time')+ln(`_p_`dummy_var_interest''))


								qui gen `v_S_`dummy_var_interest''=exp(ln(`_p_`dummy_var_interest''*(normal((`_m_`dummy_var_interest''*`var_time'+`_y0_`dummy_var_interest'')/sqrt(`var_time'))/*
																			       */ -exp(-2*`_y0_`dummy_var_interest''*`_m_`dummy_var_interest'')*normal((`_m_`dummy_var_interest''*`var_time'-`_y0_`dummy_var_interest'')/sqrt(`var_time')))+(1-`_p_`dummy_var_interest'')))




								qui gen `v_h_`dummy_var_interest''=`v_f_`dummy_var_interest''/`v_S_`dummy_var_interest''
						           
							  if("`graph'"=="hz"){     
									 label variable `v_h_`dummy_var_interest'' `"``vlb_`dummy_var_interest'''"'
									 local line_command `line_command' || line `v_h_`dummy_var_interest'' `var_time'  
							  }
							  else if ("`graph'"=="sv"){
									 label variable `v_S_`dummy_var_interest'' `"``vlb_`dummy_var_interest'''"'
									 local line_command `line_command' || line `v_S_`dummy_var_interest'' `var_time'            
							  }
							  else if ("`graph'"=="ds"){
									 label variable `v_f_`dummy_var_interest'' `"``vlb_`dummy_var_interest'''"'
									 local line_command `line_command' || line `v_f_`dummy_var_interest'' `var_time'            
							  }   
		
		        }
		
		
		        preserve
		        sort `var_time' 
		
		
		        
		        line `line_command', `graphopt' `name_command'
		        restore        	
        	
        }
   }










     
       
       
     

     



end
