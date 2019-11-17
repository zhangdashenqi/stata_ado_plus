*!version 5.7  03Sep2014 

capture program drop rdbinselect
program define rdbinselect, eclass
	syntax anything [if] [, c(real 0) p(real 4) binselect(string) scale(real 1) scalel(real 1) scaler(real 1) numbinl(real 1) numbinr(real 1) lowerend(string) upperend(string) generate(string) hide * graph_options(string) ]

	marksample touse

	tokenize "`anything'"
	local y `1'
	local x `2'
	
	tokenize `generate'	
	local w : word count `generate'
	if `w' == 1 {
		confirm new var `1'	
		local genid `"`1'"'
		local nsave 1
	}
	if `w' == 2 {
		confirm new var `1'	
		confirm new var `2'
		local genid `"`1'"'
		local genmeanx `"`2'"'
		local nsave 2
	}
	if `w' == 3 {
		confirm new var `1'	
		confirm new var `2'
		confirm new var `3'
		local genid    `"`1'"'
		local genmeanx `"`2'"'
		local genmeany `"`3'"'
		local nsave 3
	}

	tempvar x_l x_r y_l y_r orig_order miss sample
	qui gen `orig_order' = _n

	if "`lowerend'"!="" {
		local x_low = "`lowerend'"
	}
	if "`upperend'"!="" {
		local x_upp = "`upperend'"
	}

	qui gen `sample'=.
	
	if ("`lowerend'"=="" & "`upperend'"=="") {
		qui replace `sample'=_n if `y'!=. & `x'!=. & `touse'
	}
	else if ("`lowerend'"!="" & "`upperend'"=="") {
		qui replace `sample'=_n if `y'!=. & `x'!=. & `x'>=`x_low' & `touse'
	}
	else if ("`lowerend'"=="" & "`upperend'"!="") {
		qui replace `sample'=_n if `y'!=. & `x'!=. & `x'<=`x_upp' & `touse'
	}
	else if ("`lowerend'"!="" & "`upperend'"!="") {
		qui replace `sample'=_n if `y'!=. & `x'!=. & `x'>=`x_low' & `x'<=`x_upp' & `touse'
	}
	
	qui count
	local size=r(N)

	preserve

	sort `sample' `y' `x'
	qui keep if `touse'
	qui drop if `sample'==.
	qui gen `x_l' = `x' if `x'<`c'
	qui gen `y_l' = `y' if `x'<`c'
	qui gen `x_r' = `x' if `x'>=`c'
	qui gen `y_r' = `y' if `x'>=`c'

	qui su `x'
	local x_min = r(min)
	local x_max = r(max)
	qui su `x_l' 
	local range_l = abs(r(max) - r(min))
	local n_l = r(N)
	qui su `x_r' 
	local range_r = abs(r(max) - r(min))
	local n_r = r(N)
	
	qui su `y_l' 
	local var_l = r(sd)
	qui su `y_r' 
	local var_r = r(sd)
	
	**************************** ERRORS
	if (`c'<=`x_min' | `c'>=`x_max'){
	 di "{err}{cmd:c()} should be set within the range of `x'"  
	 exit 125
	}

	if ("`p'"<"0" ){
	 di "{err}{cmd:p()} should be a positive integer"  
	 exit 411
	}

	if ( "`scale'"<="0" | "`scalel'"<="0" | "`scaler'"<="0" | "`numbinl'"<="0" | "`numbinr'"<="0"){
	 di "{err}{cmd:scale()}, {cmd:scalel()}, {cmd:scaler()}, {cmd:numbinl()} and {cmd:numbinr()} should be positive integers"  
	 exit 411
	}

	if ( ("`scale'"!="1" & "`scalel'"!="1") |  ("`scale'"!="1" & "`scaler'"!="1")){
	     di "{err}{cmd:scale()} cannot be combined with either {cmd:scalel()} or {cmd:scaler()}"
         exit 498
	}
	
	if ( ("`scale'"!="1" | "`scalel'"!="1" | "`scaler'"!="1") &  ("`numbinl'"!="1" | "`numbinr'"!="1")){
	     di "{err}{cmd:scale()}, {cmd:scalel()} and {cmd:scaler()} cannot be combined with either {cmd:numbinl()} or {cmd:numbinr()}"
         exit 498
	}
	
	local p_round   = round(`p')/`p'
	local p_scale   = round(`scale')/`scale'
	local p_scalel  = round(`scalel')/`scalel'
	local p_scaler  = round(`scaler')/`scaler'
	local p_numbinl = round(`numbinl')/`numbinl'
	local p_numbinr = round(`numbinr')/`numbinr'

	*if (`p_round'!=1 | `p_scale'!=1 | `p_scalel'!=1 | `p_scaler'!=1 | `p_numbinl'!=1 | `p_numbinr'!=1 ) {
	if ( `p_scale'!=1 | `p_scalel'!=1 | `p_scaler'!=1 | `p_numbinl'!=1 | `p_numbinr'!=1 ) {
		 di "{err}{cmd:p()}, {cmd:scale()}, {cmd:scalel()}, {cmd:scaler()}, {cmd:numbinl()} and {cmd:numbinr()} should be integers"  
	 exit 126
	}

	if ((`numbinl'!=1 & `numbinr'==1 ) | (`numbinr'!=1 & `numbinl'==1 )) {
	     di "{err}both {cmd:numbinl()} and {cmd:numbinr()} should be set"
         exit 498
	}
	
	
	if ( `scale'>1 & `scalel'==1 & `scaler'==1){
		local scalel = `scale'
		local scaler = `scale'
	}
	
	mata{
	
	y_l = st_data(.,("`y_l'"), 0)
	x_l = st_data(.,("`x_l'"), 0)
	y_r = st_data(.,("`y_r'"), 0)
	x_r = st_data(.,("`x_r'"), 0)
		
	allsample=`size'
	usesample=`n_l'+`n_r'
	p1 = `p' + 1
	n=`n'
	c=`c'
	x_min = `x_min'
	x_max = `x_max'
	n = usesample
	numbinl=`numbinl'
	numbinr=`numbinr'
	
	rp_l = J(`n_l',p1,.)
	rp_r = J(`n_r',p1,.)
	for (j=1; j<=p1; j++) {
		rp_l[.,j] = x_l:^(j-1)
		rp_r[.,j] = x_r:^(j-1)
	}
	gamma_p1_l = invsym(cross(rp_l,rp_l))*cross(rp_l,y_l)		
	gamma_p2_l = invsym(cross(rp_l,rp_l))*cross(rp_l,y_l:^2)	
	gamma_p1_r = invsym(cross(rp_r,rp_r))*cross(rp_r,y_r)		
	gamma_p2_r = invsym(cross(rp_r,rp_r))*cross(rp_r,y_r:^2)
		
	*** Bias w/sample
	mu0_p1_l = rp_l*gamma_p1_l
	mu0_p1_r = rp_r*gamma_p1_r
	mu0_p2_l = rp_l*gamma_p2_l
	mu0_p2_r = rp_r*gamma_p2_r
	drp_l = J(`n_l',`p',.)
	drp_r = J(`n_r',`p',.)
	for (j=1; j<=`p'; j++) {
		drp_l[.,j] = j*x_l:^(j-1)
		drp_r[.,j] = j*x_r:^(j-1)
	}
	
	
	if (numbinl==1 & numbinr==1 ) {

	ind_l=ind_r=w=0
	order = minindex(x_l, `n_l', ind_l, w)
	x_i_l = x_l[ind_l] 
	y_i_l = y_l[ind_l]
	
	order = minindex(x_r, `n_r', ind_r, w)
	x_i_r = x_r[ind_r] 
	y_i_r = y_r[ind_r]
	
    dxi_l=(x_i_l[2::length(x_i_l)]-x_i_l[1::(length(x_i_l)-1)])
	dxi_r=(x_i_r[2::length(x_i_r)]-x_i_r[1::(length(x_i_r)-1)])
	dyi_l=(y_i_l[2::length(y_i_l)]-y_i_l[1::(length(y_i_l)-1)])
	dyi_r=(y_i_r[2::length(y_i_r)]-y_i_r[1::(length(y_i_r)-1)])
	
	x_bar_i_l = (x_i_l[2::length(x_i_l)]+x_i_l[1::(length(x_i_l)-1)])/2
	x_bar_i_r = (x_i_r[2::length(x_i_r)]+x_i_r[1::(length(x_i_r)-1)])/2
	
	drp_i_l = J(`n_l'-1,`p',.)
	drp_i_r = J(`n_r'-1,`p',.)
	rp_i_l  = J(`n_l'-1,p1,.)
	rp_i_r  = J(`n_r'-1,p1,.)
	           
    for (j=1; j<=p1; j++) {
     rp_i_l[.,j] = x_bar_i_l:^(j-1)
     rp_i_r[.,j] = x_bar_i_r:^(j-1)
   }
  
  if (`p'>0 ) {
   for (j=1; j<=`p'; j++) {
     drp_i_l[.,j] = j*x_bar_i_l:^(j-1)
     drp_i_r[.,j] = j*x_bar_i_r:^(j-1)
   }
   mu1_i_hat_l = drp_i_l*(gamma_p1_l[2::p1])
   mu1_i_hat_r = drp_i_r*(gamma_p1_r[2::p1])
   }
   else if (`p'==0){
   drp_i_l=0
   drp_i_r=0
   mu1_i_hat_l = 0
   mu1_i_hat_r = 0
   }
   
   mu0_i_hat_l = rp_i_l*gamma_p1_l
   mu0_i_hat_r = rp_i_r*gamma_p1_r
   mu2_i_hat_l = rp_i_l*gamma_p2_l
   mu2_i_hat_r = rp_i_r*gamma_p2_r
   sigma2_hat_ul = mu2_i_hat_l - mu0_i_hat_l:^2
   sigma2_hat_ur = mu2_i_hat_r - mu0_i_hat_r:^2
	
   * J.es.hat
   V_es_hat_l = (n/(4*(c-x_min)))*sum(dxi_l:^2:*dyi_l:^2)
   V_es_hat_r = (n/(4*(x_max-c)))*sum(dxi_r:^2:*dyi_r:^2)
   B_es_hat_l = ((c-x_min)^2/12)*sum(dxi_l:*mu1_i_hat_l:^2)
   B_es_hat_r = ((x_max-c)^2/12)*sum(dxi_r:*mu1_i_hat_r:^2)
   C_es_hat_l = (2*B_es_hat_l)/V_es_hat_l
   C_es_hat_r = (2*B_es_hat_r)/V_es_hat_r
   J_es_hat_l = floor((C_es_hat_l*n)^(1/3))
   J_es_hat_r = floor((C_es_hat_r*n)^(1/3))
	 
   * J.es.hat.2
   V_es_chk_l = (n/(2*(c-x_min)))*sum(dxi_l:^2:*sigma2_hat_ul)
   V_es_chk_r = (n/(2*(x_max-c)))*sum(dxi_r:^2:*sigma2_hat_ur)
   C_es_chk_l = (2*B_es_hat_l)/V_es_chk_l
   C_es_chk_r = (2*B_es_hat_r)/V_es_chk_r
   J_es_chk_l = floor((C_es_chk_l*n)^(1/3))
   J_es_chk_r = floor((C_es_chk_r*n)^(1/3))
  
   * J.es.hat.w
   B_es_hatw_l = ((c-x_min)^2/(12*n))*sum(mu1_i_hat_l:^2)
   B_es_hatw_r = ((x_max-c)^2/(12*n))*sum(mu1_i_hat_r:^2)
   V_es_hatw_l = (0.5/(c-x_min))*sum(dxi_l:*dyi_l:^2)
   V_es_hatw_r = (0.5/(x_max-c))*sum(dxi_r:*dyi_r:^2)
   C_es_hatw_l = (2*B_es_hatw_l)/V_es_hatw_l
   C_es_hatw_r = (2*B_es_hatw_r)/V_es_hatw_r
   J_es_hatw_l = floor((C_es_hatw_l*n)^(1/3))
   J_es_hatw_r = floor((C_es_hatw_r*n)^(1/3))
   
   * J.qs.hat
   V_qs_hat_l = (n/(2*`n_l'))*sum(dxi_l:*dyi_l:^2)
   V_qs_hat_r = (n/(2*`n_r'))*sum(dxi_r:*dyi_r:^2)
   B_qs_hat_l = (`n_l'^2/72)*sum(dxi_l:^3:*mu1_i_hat_l:^2)
   B_qs_hat_r = (`n_r'^2/72)*sum(dxi_r:^3:*mu1_i_hat_r:^2)
   C_qs_hat_l = (2*B_qs_hat_l)/V_es_hat_l
   C_qs_hat_r = (2*B_qs_hat_r)/V_es_hat_r
   J_qs_hat_l = floor((C_qs_hat_l*n)^(1/3))
   J_qs_hat_r = floor((C_qs_hat_r*n)^(1/3))
   
   * J.qs.ht.2
   V_qs_chk_l = (n/`n_l')*sum(dxi_l:*sigma2_hat_ul)
   V_qs_chk_r = (n/`n_r')*sum(dxi_r:*sigma2_hat_ur)
   C_qs_chk_l = (2*B_qs_hat_l)/V_qs_chk_l
   C_qs_chk_r = (2*B_qs_hat_r)/V_qs_chk_r
   J_qs_chk_l = floor((C_qs_chk_l*n)^(1/3))
   J_qs_chk_r = floor((C_qs_chk_r*n)^(1/3))
   
   * J.qs.ht.w
   V_qs_hatw_l = (1/(2*`n_l'))*sum(dxi_l:^0:*dyi_l:^2)
   V_qs_hatw_r = (1/(2*`n_r'))*sum(dxi_r:^0:*dyi_r:^2)
   B_qs_hatw_l = (`n_l'^1/48)*sum(dxi_l:^2:*mu1_i_hat_l:^2)
   B_qs_hatw_r = (`n_r'^1/48)*sum(dxi_r:^2:*mu1_i_hat_r:^2)
   C_qs_hatw_l = (2*B_qs_hatw_l)/V_es_hatw_l
   C_qs_hatw_r = (2*B_qs_hatw_r)/V_es_hatw_r
   J_qs_hatw_l = floor((C_qs_hatw_l*n)^(1/3))
   J_qs_hatw_r = floor((C_qs_hatw_r*n)^(1/3))
      
	  
	if ("`binselect'"=="es" | "`binselect'"=="" ) {
		J_star_l_orig = J_es_hat_l
		J_star_r_orig = J_es_hat_r
	}
	
	if ("`binselect'"=="espr" ) {
		J_star_l_orig = J_es_chk_l
		J_star_r_orig = J_es_chk_r
	}
	
	if ("`binselect'"=="esdw" ) {
		J_star_l_orig = J_es_hatw_l
		J_star_r_orig = J_es_hatw_r
	}
	
	if ("`binselect'"=="qs" ) {
		J_star_l_orig = J_qs_hat_l
		J_star_r_orig = J_qs_hat_r
	}
	
	if ("`binselect'"=="qspr" ) {
		J_star_l_orig = J_qs_chk_l
		J_star_r_orig = J_qs_chk_r
	}
	
	if ("`binselect'"=="qsdw" ) {
		J_star_l_orig = J_qs_hatw_l
		J_star_r_orig = J_qs_hatw_r
	}
	st_numscalar("J_es_hat_l", J_es_hat_l)
	st_numscalar("J_es_hat_r", J_es_hat_r)
	st_numscalar("J_qs_hat_l", J_qs_hat_l)
	st_numscalar("J_qs_hat_r", J_qs_hat_r)
	st_numscalar("J_es_chk_l", J_es_chk_l)
	st_numscalar("J_es_chk_r", J_es_chk_r)
	st_numscalar("J_qs_chk_l", J_qs_chk_l)
	st_numscalar("J_qs_chk_r", J_qs_chk_r)
	st_numscalar("J_es_hatw_l", J_es_hatw_l)
	st_numscalar("J_es_hatw_r", J_es_hatw_r)
	st_numscalar("J_qs_hatw_l", J_qs_hatw_l)
	st_numscalar("J_qs_hatw_r", J_qs_hatw_r)
	}
	else {
	J_star_l = numbinl
	J_star_r = numbinr
	J_star_l = J_star_l
	J_star_r = J_star_r
	J_star_l_orig = J_star_l
	J_star_r_orig = J_star_r
	}
	
	if (`var_l'==0) {
		J_star_l = 1
		J_star_l_orig = 1
	}
	if (`var_r'==0) {
		J_star_r = 1
		J_star_r_orig = 1
	}

	J_star_l = round(`scalel'*J_star_l_orig)
	J_star_r = round(`scaler'*J_star_r_orig)

	st_numscalar("J_star_l", J_star_l)
	st_numscalar("J_star_r", J_star_r)
	st_numscalar("J_star_l_orig", J_star_l_orig)
	st_numscalar("J_star_r_orig", J_star_r_orig)
	


	
	*st_numscalar("J_star_l", J_star_l[1,1])
	*st_numscalar("J_star_r", J_star_r[1,1])
	*st_numscalar("J_star_l_orig", J_star_l_orig[1,1])
	*st_numscalar("J_star_r_orig", J_star_r_orig[1,1])
	
	*st_numscalar("J_es_hat_l", J_es_hat_l[1,1])
	*st_numscalar("J_es_hat_r", J_es_hat_r[1,1])
	*st_numscalar("J_qs_hat_l", J_qs_hat_l[1,1])
	*st_numscalar("J_qs_hat_r", J_qs_hat_r[1,1])
	*st_numscalar("J_es_chk_l", J_es_chk_l[1,1])
	*st_numscalar("J_es_chk_r", J_es_chk_r[1,1])
	*st_numscalar("J_qs_chk_l", J_qs_chk_l[1,1])
	*st_numscalar("J_qs_chk_r", J_qs_chk_r[1,1])
	*st_numscalar("J_es_hatw_l", J_es_hatw_l[1,1])
	*st_numscalar("J_es_hatw_r", J_es_hatw_r[1,1])
	*st_numscalar("J_qs_hatw_l", J_qs_hatw_l[1,1])
	*st_numscalar("J_qs_hatw_r", J_qs_hatw_r[1,1])

	}
	

	qui gen bin_x =.

	***** ES Bins
	if ("`binselect'"=="es" | "`binselect'"=="espr"  | "`binselect'"=="esdw" | "`binselect'"=="" ) {
		local jump_l = `range_l'/J_star_l
		qui su `x_l'
		local x_min = r(min)
		local x_max = r(max)
		qui replace bin_x = -J_star_l  if `x_l' <= (`x_min' + `jump_l') & `x_l'!=. & `y_l'!=.
		qui replace bin_x = -1         if `x_l' >= (`x_max' - `jump_l') & `x_l'!=. & `y_l'!=.
		local K = J_star_l-1
		forvalues k = 2 (1) `K' {
			qui replace bin_x = -J_star_l+`k'-1 if  `x_l' <= `x_min'+`k'*`jump_l' & `x_l' >= `x_min'+(`k'-1)*`jump_l' & `x_l'!=. & `y_l'!=.
		}

		local jump_r = `range_r'/J_star_r
		qui su `x_r'
		local x_min = r(min)
		local x_max = r(max)
		qui replace bin_x = 1        if `x_r' <= (`x_min' + `jump_r') & `x_r'!=. & `y_r'!=.
		qui replace bin_x = J_star_r if `x_r' >= (`x_max' - `jump_r') & `x_r'!=. & `y_r'!=.
		local K = J_star_r-1
		forvalues k = 2 (1) `K' {
			qui replace bin_x = `k' if  `x_r' <= `x_min'+`k'*`jump_r' & `x_r' >= `x_min'+(`k'-1)*`jump_r' & `x_r'!=. & `y_r'!=.
		}
	local binselect_type="Evenly spaced"
	}
		else if ("`binselect'"=="qs" | "`binselect'"=="qspr" |"`binselect'"=="qsdw" ) {
			local J_l = J_star_l
			xtile binx_l = `x_l' , nq(`J_l')
			local J_r = J_star_r
			xtile binx_r = `x_r' , nq(`J_r')
			qui replace binx_l=binx_l-`J_l'-1
			qui replace bin_x=binx_l if `x_l'!=.
			qui replace bin_x=binx_r if `x_r'!=.
			local binselect_type="Quantile spaced"
	}
	
	qui egen bin_ymean=mean(`y'), by(bin_x)
	qui egen bin_xmax=max(`x'), by(bin_x)
	qui egen bin_xmin=min(`x'), by(bin_x)
	qui gen bin_xmean=(bin_xmax+bin_xmin)/2 
	
	mata{
	x_sup = x_l \ x_r
	y_hat = mu0_p1_l \ mu0_p1_r
	bin_x     = st_data(.,("bin_x"), 0)
	bin_xmean = st_data(.,("bin_xmean"), 0)
	bin_ymean = st_data(.,("bin_ymean"), 0)
	st_store(., st_addvar("float", "x_sup"), x_sup)
	st_store(., st_addvar("float", "y_hat"), y_hat)
	st_matrix("gamma_p1_l", gamma_p1_l)
	st_matrix("gamma_p1_r", gamma_p1_r)
	}

	ereturn clear
	ereturn scalar J_star_l         = J_star_l
	ereturn scalar J_star_r         = J_star_r
	ereturn scalar J_star_l_orig    = J_star_l_orig
	ereturn scalar J_star_r_orig    = J_star_r_orig
	ereturn scalar binlength_l      = `range_l'/J_star_l
	ereturn scalar binlength_r      = `range_r'/J_star_r
	ereturn scalar binlength_l_orig = `range_l'/J_star_l_orig
	ereturn scalar binlength_r_orig = `range_r'/J_star_r_orig
	ereturn matrix gamma_p1_l = gamma_p1_l
	ereturn matrix gamma_p1_r = gamma_p1_r
	*ereturn scalar J_es_hat_l = J_es_hat_l
	*ereturn scalar J_es_hat_r = J_es_hat_r
	*ereturn scalar J_qs_hat_l = J_qs_hat_l
	*ereturn scalar J_qs_hat_r = J_qs_hat_r
	*ereturn scalar J_es_chk_l = J_es_chk_l
	*ereturn scalar J_es_chk_r = J_es_chk_r
	*ereturn scalar J_qs_chk_l = J_qs_chk_l
	*ereturn scalar J_qs_chk_r = J_qs_chk_r
	*ereturn scalar J_es_hat_dw_l = J_es_hatw_l
	*ereturn scalar J_es_hat_dw_r = J_es_hatw_r
	*ereturn scalar J_qs_hat_dw_l = J_qs_hatw_l
	*ereturn scalar J_qs_hat_dw_r = J_qs_hatw_r
	cap drop x_sup_l
	cap drop x_sup_r
	cap drop y_hat_l 
	cap drop y_hat_r
	
	disp ""
	disp in smcl in gr "Number of bins for RD estimates - Method: " "`binselect_type'"
	disp ""
	disp in smcl in gr "{ralign 17: Cutoff c = `c'}"  _col(18) " {c |} " _col(19) in gr "Left of " in yellow "c"        _col(35) in gr "Right of " in yellow "c" 
	disp in smcl in gr "{hline 18}{c +}{hline 30}"                                                                                
	disp in smcl in gr "{ralign 17:Number of obs}"   _col(18) " {c |} " _col(18) as result %7.0f `n_l'                 _col(38) %7.0f  `n_r'
	disp in smcl in gr "{ralign 17:Poly. order}"     _col(18) " {c |} " _col(18) as result %7.0f `p'                   _col(38) %7.0f  `p'
	disp in smcl in gr "{ralign 17:Number of bins}"  _col(18) " {c |} " _col(18) as result %7.0f e(J_star_l_orig)      _col(38) %7.0f  e(J_star_r_orig)
	disp in smcl in gr "{ralign 17:Bin length}"      _col(18) " {c |} " _col(18) as result %7.3f e(binlength_l_orig)   _col(38) %7.3f  e(binlength_r_orig)
	if ("`scale'"~="1" | "`scalel'"~="1" | "`scaler'"~="1") {
		disp in smcl in gr "{hline 18}{c +}{hline 30}"                                                                                
		disp in smcl in gr "{ralign 17:Scale}"           _col(18) " {c |} " _col(18) as result %7.0f `scalel'              _col(38) %7.0f  `scaler'
		disp in smcl in gr "{ralign 17:Number of bins}"  _col(18) " {c |} " _col(18) as result %7.0f e(J_star_l)           _col(38) %7.0f  e(J_star_r)
		disp in smcl in gr "{ralign 17:Bin length}"      _col(18) " {c |} " _col(18) as result %7.3f e(binlength_l)        _col(38) %7.3f  e(binlength_r)
	}
	disp ""
	if ("`hide'"=="") {
		twoway (scatter bin_ymean bin_xmean, sort msize(small)  mcolor(gs10)) (line y_hat x_sup if x_sup<`c', lcolor(black) sort lwidth(medthin) lpattern(solid) ) (line y_hat x_sup if x_sup>=`c', lcolor(black) sort lwidth(medthin) lpattern(solid) )  , ///
		xline(`c', lcolor(black) lwidth(medthin)) xscale(r(`x_low' `x_up')) title("Regression function fit", color(gs0))  ///
		legend(cols(2) order(1 "Sample average within bin" 2 "`p'th order global polynomial" )) `graph_options'
	}
	
	*xtitle("`x'") ytitle("`y'")
	*
	*if "`savefig'" != "" {
	*saving("Fig1.gph", replace)
	*}
	restore
	sort `sample'

	mata{

	if ("`nsave'"=="1") {
		if (allsample!=usesample){
			miss = J(allsample-usesample,1, .)
			bin_x=(bin_x',miss')'
	}

	st_store(., st_addvar("float", "`genid'"), bin_x)
	}

	if ("`nsave'"=="2") {
		if (allsample!=usesample){
			miss = J(allsample-usesample,1, .)
			bin_x=(bin_x',miss')'
			bin_xmean=(bin_xmean',miss')'
		}
		st_store(., st_addvar("float", "`genid'"),    bin_x )
		st_store(., st_addvar("float", "`genmeanx'"), bin_xmean )
	}

	if ("`nsave'"=="3") {
		if (allsample!=usesample){
			miss = J(allsample-usesample,1, .)
			bin_x=(bin_x',miss')'
			bin_xmean=(bin_xmean',miss')'
			bin_ymean=(bin_ymean',miss')'
		}
		st_store(., st_addvar("float", "`genid'"), bin_x )
		st_store(., st_addvar("float", "`genmeanx'"), bin_xmean )
		st_store(., st_addvar("float", "`genmeany'"), bin_ymean )
		}
	}
	sort `orig_order'
	qui drop `sample' `orig_order'
	mata mata clear

end


 
