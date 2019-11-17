
capture program drop trpredictm
program trpredictm
  version 10.0
local names : colfullnames e(b)

   syntax    ,[prefix(string)]                   ///
              [SCenario(string)]                  ///
              [Replace]                  ///
              [DEbug]                                  

     


   

   if "`prefix'"!="" {
	local prefix_string `prefix'
   }
  
   if "`scenario'"!="" {
	   local scenario_command `scenario'
	   local scenario_command_remain `scenario'
	   local scenario_covariate_number = wordcount("`scenario_command'")

   }     
	  
   if "`scenario'"=="" {
                            if ("`replace'"!="") {
                               capture drop `prefix_string'lny0
			       capture drop `prefix_string'y0
			       capture drop `prefix_string'mu
                               capture drop `prefix_string'lgtp
			       capture drop `prefix_string'p
			       capture drop `prefix_string'f
			       capture drop `prefix_string'S
			       capture drop `prefix_string'h
			    }
			    predict `prefix_string'lny0, equation(lny0)
		            quietly gen `prefix_string'y0=exp(`prefix_string'lny0)
			    predict `prefix_string'mu, equation(mu)
			    predict `prefix_string'lgtp, equation(lgtp)
		            quietly gen `prefix_string'p=exp(`prefix_string'lgtp)/(1+exp(`prefix_string'lgtp))



			    
			    quietly gen `prefix_string'f=exp(`prefix_string'lny0-.5*(ln(2*_pi*(_t^3))+(`prefix_string'y0+`prefix_string'mu*_t)^2/_t)+ln(`prefix_string'p))
                                        *qui gen `var_f0'=exp(ln(`_y0')-.5*(ln(2*_pi*(`var_time'^3))+(`_y0'+`_mu'*`var_time')^2/`var_time')+ln(`_p'))

			    quietly gen `prefix_string'S=exp(ln(`prefix_string'p*(normal((`prefix_string'mu*_t+`prefix_string'y0)/sqrt(_t))/*
										     */ -exp(-2*`prefix_string'y0*`prefix_string'mu)*normal((`prefix_string'mu*_t-`prefix_string'y0)/sqrt(_t)))+(1-`prefix_string'p)))




			    quietly gen `prefix_string'h=	`prefix_string'f/`prefix_string'S	 

				 


		            label var `prefix_string'lny0 "Prediction"
		            label var `prefix_string'y0 "Prediction"
		            label var `prefix_string'mu "Prediction"
		            label var `prefix_string'lgtp "Prediction"
		            label var `prefix_string'p "Prediction"
		            label var `prefix_string'f "Prediction"
		            label var `prefix_string'S "Prediction"
		            label var `prefix_string'h "Prediction"
   
   }
   else{
	   local number_scenario_covariate = wordcount("`scenario_command'")
	   while trim(`"`scenario_command_remain'"')!=""{

	     gettoken current_scenario_covariate scenario_command_remain: scenario_command_remain, parse("=")
	    
	     gettoken equal_sign scenario_command_remain: scenario_command_remain, parse("=")
	     
	     gettoken current_covariate_value scenario_command_remain: scenario_command_remain, parse(" ")
	   
	     local scenario_covariate_`current_scenario_covariate'=`current_covariate_value'
	     
	     if("`debug'"!=""){
	     di "scenario_covariate_`current_scenario_covariate':`current_covariate_value'"
	     }
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
		       mat current_coefficient=coefficient_vector[1,"`cur_group_str':`current_eb_covariate'"]        
		       local current_coefficient_value = current_coefficient[1,1]
		       
			
		       if("`cur_group_str'"=="lny0"){
		     

			 if (substr("`current_eb_covariate'",-5,5)!="_cons"){
			   if (trim("`scenario_covariate_`current_eb_covariate''")!=""){
	     
			    
					  
			      local lny0_reference=`lny0_reference'+ 1*`current_coefficient_value' *`scenario_covariate_`current_eb_covariate''
			 
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
			   if (trim("`scenario_covariate_`current_eb_covariate''")!=""){
	     
			    
					  
			      local mu_reference=`mu_reference'+ 1*`current_coefficient_value' *`scenario_covariate_`current_eb_covariate''
			      
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
			   if (trim("`scenario_covariate_`current_eb_covariate''")!=""){
	     
			    
					  
			      local lgtp_reference=`lgtp_reference'+ 1*`current_coefficient_value' *`scenario_covariate_`current_eb_covariate''
			      
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









	    local k = `k' + 1

	   }
	   
	  



	   local y0=exp(`lny0_reference')

	   local _y0=`y0'

	   local _mu=`mu_reference'

	   local _lgtp=`lgtp_reference'
	   local _p=exp(`_lgtp')/(1+exp(`_lgtp'))	     
	    


	   tempvar var_f0 var_S0 var_h0

	   if ("`replace'"!="") {
                               capture drop `prefix_string'lny0
			       capture drop `prefix_string'y0
			       capture drop `prefix_string'mu
                               capture drop `prefix_string'lgtp
			       capture drop `prefix_string'p
			       capture drop `prefix_string'f
			       capture drop `prefix_string'S
			       capture drop `prefix_string'h
	   }

	   quietly gen `prefix_string'lny0=`lny0_reference'
	   quietly gen `prefix_string'y0=`_y0'
	   quietly gen `prefix_string'mu=`_mu'
	   quietly gen `prefix_string'lgtp=`_lgtp'
	   quietly gen `prefix_string'p=`_p'


	   gen `prefix_string'f=exp(ln(`_y0')-.5*(ln(2*_pi*(_t^3))+(`_y0'+`_mu'*_t)^2/_t)+ln(`_p'))
                      * local f0=exp(ln(`_y0')-.5*(ln(2*_pi*(`_timevalue'^3))+(`_y0'+`_mu'*`_timevalue')^2/`_timevalue')+ln(`_p'))

	   gen `prefix_string'S=exp(ln(`_p'*(normal((`_mu'*_t+`_y0')/sqrt(_t))/*
										     */ -exp(-2*`_y0'*`_mu')*normal((`_mu'*_t-`_y0')/sqrt(_t)))+(1-`_p')))

                      *local S0=exp(ln(`_p'*(normal((`_mu'*`_timevalue'+`_y0')/sqrt(`_timevalue'))/*
											 */ -exp(-2*`_y0'*`_mu')*normal((`_mu'*`_timevalue'-`_y0')/sqrt(`_timevalue')))+(1-`_p')))

	   gen `prefix_string'h=`prefix_string'f/`prefix_string'S


	    label var `prefix_string'lny0 "Prediction"
	    label var `prefix_string'y0 "Prediction"
	    label var `prefix_string'mu "Prediction"
	    label var `prefix_string'lgtp "Prediction"
	    label var `prefix_string'p "Prediction"
	    label var `prefix_string'f "Prediction"
	    label var `prefix_string'S "Prediction"
	    label var `prefix_string'h "Prediction"


   }
    












end
