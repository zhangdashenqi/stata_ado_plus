
*! fastmic.ado 1.0.0 17th March 2009, R.Froud. 
*  This program reports minimally important change (MIC) thresholds using 45 degree tangent line intersection 
*  and the smallest residual sum of sensitivity ans specificity. 


capture program drop fastmic

version 10.1

program define fastmic, rclass
                syntax varlist(min=2 max=2 numeric)[, scale(real 0)] 
                return local varname `varlist'
			local ref: word 1 of `varlist'
			local dv: word 2 of `varlist'
                quietly {
				capture drop se1 sp1 gap1 gap thresh emg emg1
				logistic `ref' `dv'
				lsens, gensens(se1) genspec(sp1)
				gen gap1=se1-sp1
				gen gap=sqrt(gap1^2)
				gen  thresh= `dv' + `scale'
				sort gap
                        return scalar mic = thresh in 1/1
				gen emg1 = ((1-se1)+(1-sp1)) 
				gen emg = sqrt(emg1^2)
				sort emg
				return scalar emgo = thresh in 1/1				
                }
		   display in smcl as text "the MIC calculated using a 45 degree tangent line intersection is " as result %05.3f return(mic)
		 display in smcl as text "the MIC calculated using the smallest sum of residual sensitivity and specificity is " as result %05.3f return(emgo) 
		display in smcl as text "use bootstrap for Conf. Intervals"
	roctab `ref' `dv'
	capture drop se1 sp1 gap1 gap thresh emg emg1
        end

