*! version 1.0.4  02jun2016
*! version 1.0.3  25oct2015
*! version 1.0.2  11sep2015
*! version 1.0.1  03jul2015
*! version 1.0.0  01jun2015
/*
-sfkk-
version 1.0.0 
June 1, 2015
Program Author: Dr. Mustafa Ugur Karakaplan
E-mail: mukarakaplan@yahoo.com
Website: www.mukarakaplan.com

Recommended Citations:

The following two citations are recommended for referring to the sfkk program
package and the underlying econometric methodology:

Karakaplan, Mustafa U. (2015) "sfkk: Stata Module for Endogenous Stochastic 
Frontier Models in the Style of Karakaplan and Kutlu (2015)" Available at 
Boston College, Department of Economics, Statistical Software Components (SSC)
S458029: http://econpapers.repec.org/software/bocbocode/S458029.htm . Also 
available at www.mukarakaplan.com

Karakaplan, Mustafa U. and Kutlu, Levent (2013) "Handling Endogeneity in 
Stochastic Frontier Analysis" Available at www.mukarakaplan.com
*/

program sfkk_ml

		args todo b lnf

		// ml evaluations
		tempvar xb lnsigu2 lnsigw2
		
		mleval `xb' = `b', eq(1)
		forvalues j = 1/$p {
			tempvar zd`j' 
			tempname eta`j'
			mleval `zd`j'' = `b', eq(`=`j'*2')
			mleval `eta`j'' =  `b', eq(`=`j'*2+1') scalar
		}
		mleval `lnsigu2' = `b', eq(`=$p*2+2')
		mleval `lnsigw2' = `b', eq(`=$p*2+3')
		forvalues j = 1/`=($p*($p+1))/2' {
			tempname le`j'
			mleval `le`j'' = `b', eq(`=$p*2+3+`j'') scalar
		}
	

		// other variables and matrices	
		local epsilons = ""
		tempvar ei sigs2 lambda term1 
		tempname OM  EPS term2 lnsigw2c
		scalar `lnsigw2c' = `b'[1,colnumb(`b',"lnsig2w:_cons")]
		quietly gen double `term1' = 0 
		forvalues j = 1/$p {
			tempvar epsilon`j'				
			quietly gen double `epsilon`j'' = `=word("$ML_y",`=1+`j'')' - `zd`j'' 
			local epsilons = "`epsilons'"+"`epsilon`j'' "
			quietly replace `term1' = `term1' +  (1/sqrt(exp(`lnsigw2c'))) * scalar(`eta`j'') * `epsilon`j'' 
		}
		quietly gen double `ei' = $ML_y1 - `xb' - sqrt(exp(`lnsigw2')) * `term1'  
		quietly gen double `sigs2' = exp(`lnsigw2') + exp(`lnsigu2') 			  
		quietly gen double `lambda' = sqrt(exp(`lnsigu2')) / sqrt(exp(`lnsigw2')) 
		
		if ($p==1) local L = "scalar(`le1')"
		else if ($p==2) local L = "scalar(`le1'),0 \ scalar(`le2'), scalar(`le3')"
		else if ($p==3) local L = "scalar(`le1'),0,0 \ scalar(`le2'), scalar(`le3'),0 \ scalar(`le4'),scalar(`le5'),scalar(`le6')"
		else if ($p>3) {
			local count=0
			forvalues i = 1/$p {
				forvalues j = 1/$p {
					if (`i'>=`j') {
						local count = `count' + 1
						if (`i'==$p & `j'==$p) local L = "`L'scalar(`le`count'')" 
						else local L = "`L'scalar(`le`count''), "					
					}
					else {
						if (`j'!=$p) local L = "`L'0, "
						if (`j'==$p) local L = "`L'0\ "
					}				
				}
			}		
		}
		quietly matrix `OM' = (`L') * (`L')'				
		quietly mkmat `epsilons', matrix(`EPS')
		capture matrix `term2' = inv(`OM') * `EPS'' * `EPS'
			
		// ml function
		if $fastroute == 1 {
			capture replace `lnf' = 0.5 * (ln(2/_pi) - ln(`sigs2') - (`ei'^2/`sigs2')) /*
					*/ + ln(normal((-$prod * `lambda' * `ei') / sqrt(`sigs2'))) /*
					*/ + 0.5 * (-$p * ln(2*_pi) - ln(det(`OM')) - (trace(`term2')/_N))
			}
		else {
			capture mlsum   `lnf' = 0.5 * (ln(2/_pi) - ln(`sigs2') - (`ei'^2/`sigs2')) /*
					*/ + ln(normal((-$prod * `lambda' * `ei') / sqrt(`sigs2'))) /*
					*/ + 0.5 * (-$p * ln(2*_pi) - ln(det(`OM')) - (trace(`term2')/_N))
			}

end 
