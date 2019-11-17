* Version 3.2 - 21 June 2013
* By J.A.F. Machado, Paulo M.D.C Parente and J.M.C. Santos Silva 
* Please email jmcss@essex.ac.uk for help and support

* The software is provided as is, without warranty of any kind, express or implied, including 
* but not limited to the warranties of merchantability, fitness for a particular purpose and 
* noninfringement. In no event shall the authors be liable for any claim, damages or other 
* liability, whether in an action of contract, tort or otherwise, arising from, out of or in 
* connection with the software or the use or other dealings in the software.


program define qreg2, eclass                                                                       
version 11.0                                                                                       

                        
syntax varlist(numeric min=1) [if] [in] [fweight] [,  Quantile(real .5) NORobust NOTest mss(string) WLSiter(integer 1) Cluster(string)]           
marksample touse 
tempname  _e _ep50 _hsi _dens _rhs _y _gv _id _g _w _f _f2 _check _fw A D Vm phi sphi sphi2 numt ct tt _oldsort
gettoken _y _rhs: varlist
unab _rhs :  `_rhs'
if "`weight'"=="" qui g `_fw'=1 if `touse'
else qui g `_fw' `exp' if `touse'


if ("`norobust'" == "norobust")&("`cluster'"~="") {
di as error "Options cluster and nonrobust are not compatible"
exit
}
if ("`weight'"~="")&("`cluster'"~="") {
di as error "Options cluster and weights are not compatible"
exit
}

_rmcoll `_rhs' if `touse', forcedrop
local _rhss "`r(varlist)'"
qui qreg `_y' `_rhss' if `touse' [fweight=`_fw'], quantile(`quantile') wls(`wlsiter') 
local _eta=e(q)
qui predict double `_f' if (`touse'), xb
qui predict double `_e' if (`touse'), res

if "`norobust'" ~= "norobust"{
qui local _hs=(invnormal(0.975)^(2/3))*(((1.5*((normalden(invnormal(`_eta')))^2))/(2*((invnormal(`_eta'))^2) + 1))^(1/3))                                       
qui su `_e' [fweight=`_fw'] if (`touse'),d
qui g double `_ep50'=abs(`_e'-r(p50)) if (`touse')
qui su `_ep50' [fweight=`_fw'] if (`touse'),d
if (`_eta'+`_hs'*(r(N)^(-1/3)))>1|(`_eta'-`_hs'*(r(N)^(-1/3)))<0{
di as error "Cannot compute bandwidth; too few observations?"
exit
}
qui g double `_hsi'=r(p50)*(invnormal(`_eta'+`_hs'*(r(N)^(-1/3)))-invnormal(`_eta'-`_hs'*(r(N)^(-1/3))))   if (`touse')
qui g double `_dens'=sqrt((`_fw')*(abs(`_e')<`_hsi')/(2*`_hsi'))  if (`touse')
qui g `_w' = sqrt(`_fw')*(`_eta'-(`_e'<=0)) if `touse'
qui g `_gv'=_n if `touse'
if "`cluster'"=="" qui g `_id'=_n  if `touse'
****
else qui g `_id'=`cluster'*sqrt(`_fw') if `touse'
****~
qui g `_oldsort'=_n
sort `_id'  

matrix opaccum `A' = `_rhss' if `touse', group(`_id') opvar(`_w')  
sort `_gv'  
matrix opaccum `D' = `_rhss' if `touse', group(`_gv') opvar(`_dens')  
matrix `Vm'=invsym(`D')*`A'*invsym(`D') 
ereturn repost  V = `Vm'
sort `_oldsort'
} 

*** Display results ======================================================
di 
if `_eta'==0.5 {
di as txt "Median regression"
} 
else {
di as txt `_eta' " Quantile regression"
}

qui corr `_f' `_y' [fweight=`_fw'] if (`touse')
di as text "R-squared = " _continue
di as result r(rho)^2
local r_2=r(rho)^2

di as txt "Number of obs = "  _continue
di as result    e(N)
local enne=e(N)

qui g double `_check'=`_e'*(`_eta'-(`_e'<=0)) if (`touse')
qui su `_check' [fweight=`_fw'] if (`touse')
di  as text "Objective function = " _continue
di as result r(mean)
local check=r(mean)

di
if "`norobust'" == "norobust" {
di as txt "                     Standard errors valid with i.i.d. errors"
}
else {                            
if "`cluster'" ~= "" {
qui by `cluster', sort: egen `ct'=count(1) if (`touse')
qui by `cluster', sort: egen `tt'=seq() if (`touse')
qui count if `tt'==1
di as txt "Standard errors adjusted for " _continue" 
di as result r(N) _continue
local clust=r(N)
di as txt " clusters in `cluster'"
}
else {
di as txt "                     Heteroskedasticity robust standard errors"
}   
}
ereturn display

tempname oldest
_est hold `oldest'

*** Do MSS ===============================================================
if ("`notest'" == "")&("`cluster'"=="") {
local empty=0

if "`mss'"==""{
local empty=1
qui g double `_f2'= `_f'^2 if  (`touse')
local mss "`mss' `_f' `_f2'"
}
local _k : word count `mss'
qui reg  `_check' `mss' [fweight=`_fw'] if  (`touse')
local MSS=e(N)*e(r2)
di 
di as txt "Machado-Santos Silva test for heteroskedasticity"
di as txt "         Ho: Constant variance"
di as txt "         Variables: " _continue
if `empty'==1 {
di as result "Fitted values of `_y' and its squares"
}
else di as result "`mss'"
di
di as txt "         chi2(" _continue
di as result `_k' _continue
di as txt ")" _continue
di _column(23) "=  " _continue
di %6.3f as result `MSS'
di as txt "         Prob > chi2  =  " _continue
di %6.3f as result chi2tail(`_k',`MSS') 
}
_est unhold `oldest'

*** Do PSS ===============================================================
if ("`notest'" == "")&("`cluster'"~="")  {
if (`clust'<`enne') {
qui g double `phi'=`_eta'-(`_e'<0) if (`touse')
qui egen `sphi'=sum(`phi') if (`touse'), by(`cluster')
qui egen `sphi2'=sum(`phi'^2) if (`touse'), by(`cluster')
qui g double `numt'=(`sphi'^2-`sphi2')/sqrt(2*(`_eta'^2)*((1-`_eta')^2)*`ct'*(`ct'-1)) if ((`touse')&(`tt'==1)&(`ct'>1))
qui su `numt' if ((`touse')&(`tt'==1)&(`ct'>1))
qui local PSS=r(mean)*sqrt(r(N))

di 
di as txt "Parente-Santos Silva test for intra-cluster correlation"
di as txt "         Ho: No intra-cluster correlation"
di
di as txt "            T" _continue
di _column(17) "=  " _continue
di %6.3f as result `PSS'
di as txt "         P>|T|  =  " _continue
di %6.3f as result 2*normal(-abs(`PSS')) 
}
}
*** Return results ========================================================
ereturn local cmd "qreg2"
if ("`notest'" == "")&("`cluster'"=="")  {
ereturn scalar mss_chi2 = `MSS'
ereturn scalar mss_df = `_k'
ereturn scalar mss_p = chi2tail(`_k',`MSS')
}
if ("`notest'" == "")&("`cluster'"~="")  {
if (`clust'<`enne') {
ereturn scalar pss_t = `PSS'
ereturn scalar pss_p = 2*normal(-abs(`PSS'))
}
}
ereturn scalar obj_func = `check'
ereturn scalar r2 = `r_2'


if "`weight'"!="" ereturn local wexp "`exp'"
else              {
ereturn local wexp "`exp'"
ereturn local wtype "" 
}

end


 




