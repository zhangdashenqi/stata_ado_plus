*!version 7.3.0  09Jun2017  

capture program drop rdrobust 
program define rdrobust, eclass
	syntax anything [if] [in] [, c(real 0) fuzzy(string) deriv(real 0) p(real 1) q(real 0) h(string) b(string) rho(real 0) covs(string) kernel(string) weights(string) bwselect(string) vce(string) level(real 95) all scalepar(real 1) scaleregul(real 1) nochecks]
	*disp in yellow "Preparing data." 
	marksample touse
	preserve
	qui keep if `touse'
	tokenize "`anything'"
	local y `1'
	local x `2'
	local kernel   = lower("`kernel'")
	local bwselect = lower("`bwselect'")
	*local vce      = lower("`vce'")
	
	******************** Set VCE ***************************
	local nnmatch = 3
	tokenize `vce'	
	local w : word count `vce'
	if `w' == 1 {
		local vce_select `"`1'"'
	}
	if `w' == 2 {
		local vce_select `"`1'"'
		if ("`vce_select'"=="nn")      local nnmatch     `"`2'"'
		if ("`vce_select'"=="cluster" | "`vce_select'"=="nncluster") local clustvar `"`2'"'	
	}
	if `w' == 3 {
		local vce_select `"`1'"'
		local clustvar   `"`2'"'
		local nnmatch    `"`3'"'
		if ("`vce_select'"!="cluster" & "`vce_select'"!="nncluster") di as error  "{err}{cmd:vce()} incorrectly specified"  
	}
	if `w' > 3 {
		di as error  "{err}{cmd:vce()} incorrectly specified"  
		exit 125
	}
	
	local vce_type = "NN"
	if ("`vce_select'"=="hc0")     		 local vce_type = "HC0"
	if ("`vce_select'"=="hc1")      	 local vce_type = "HC1"
	if ("`vce_select'"=="hc2")      	 local vce_type = "HC2"
	if ("`vce_select'"=="hc3")      	 local vce_type = "HC3"
	if ("`vce_select'"=="cluster")  	 local vce_type = "Cluster"
	if ("`vce_select'"=="nncluster") 	 local vce_type = "NNcluster"

	if ("`vce_select'"=="cluster" | "`vce_select'"=="nncluster") local cluster = "cluster"
	if ("`vce_select'"=="cluster")       local vce_select = "hc0"
	if ("`vce_select'"=="nncluster")     local vce_select = "nn"
	if ("`vce_select'"=="")              local vce_select = "nn"

	******************** Set BW ***************************
	tokenize `h'	
	local w : word count `h'
	if `w' == 1 {
		local h_l `"`1'"'
		local h_r `"`1'"'
	}
	if `w' == 2 {
		local h_l `"`1'"'
		local h_r `"`2'"'
	}
	if `w' >= 3 {
		di as error  "{err}{cmd:h()} only accepts two inputs"  
		exit 125
	}
	
	tokenize `b'	
	local w : word count `b'
	if `w' == 1 {
		local b_l `"`1'"'
		local b_r `"`1'"'
	}
	if `w' == 2 {
		local b_l `"`1'"'
		local b_r `"`2'"'
	}
	if `w' >= 3 {
		di as error  "{err}{cmd:b()} only accepts two inputs"  
		exit 125
	}
	******************** Set Fuzzy***************************
	tokenize `fuzzy'	
	local w : word count `fuzzy'
	if `w' == 1 {
		local fuzzyvar `"`1'"'
	}
	if `w' == 2 {
		local fuzzyvar `"`1'"'
		local sharpbw  `"`2'"'
		if `"`2'"' != "sharpbw" {
			di as error  "{err}fuzzy() only accepts sharpbw as a second input" 
			exit 125
		}
	}
	if `w' >= 3 {
		di as error  "{err}{cmd:fuzzy()} only accepts two inputs"  
		exit 125
	}
	************************************************************
	
	
	qui drop if `y'==. | `x'==.
	if ("`fuzzy'"~="")   qui drop if `fuzzyvar'==.
	if ("`cluster'"!="") qui drop if `clustvar'==.
	if ("`covs'"~="") {
		qui ds `covs'
		local covs_list = r(varlist)
		foreach z in `covs_list' {
			qui drop if `z'==.
		}
		local ncovs : word count `covs_list'
		qui reg `y' `x' `covs'
		if (e(rank)<(`ncovs'+ 2)) {
			di as error  "{err}Multicollinearity issue detected in {cmd:covs}. Please rescale and/or remove redundant covariates"  
			*exit 125
		}
	}
	
	qui su `x'
	local x_min = r(min)
	local x_max = r(max)
	local N = r(N)
	qui su `x'  if `x'<`c', d
	local N_l = r(N)
	local range_l = abs(r(max)-r(min))
	qui su `x'  if `x'>=`c', d
	local N_r = r(N)
	local range_r = abs(r(max)-r(min))
	local N = `N_r' + `N_l'
	if ("`deriv'">"0" & "`p'"=="1" & "`q'"=="0") local p = `deriv'+1
	if ("`q'"=="0") local q = `p'+1

	**************************** BEGIN ERROR CHECKING ************************************************
	if ("`nochecks'"=="") {
			if (`c'<=`x_min' | `c'>=`x_max'){
			 di as error  "{err}{cmd:c()} should be set within the range of `x'"  
			 exit 125
			}
			
			if (`N_l'<10 | `N_r'<10){
			 di as error  "{err}Not enough observations to perform calculations"  
			 exit 2001
			}
			
			if ("`kernel'"~="uni" & "`kernel'"~="uniform" & "`kernel'"~="tri" & "`kernel'"~="triangular" & "`kernel'"~="epa" & "`kernel'"~="epanechnikov" & "`kernel'"~="" ){
			 di as error  "{err}{cmd:kernel()} incorrectly specified"  
			 exit 7
			}

			if ("`bwselect'"=="CCT" | "`bwselect'"=="IK" | "`bwselect'"=="CV" |"`bwselect'"=="cct" | "`bwselect'"=="ik" | "`bwselect'"=="cv"){
				di as error  "{err}{cmd:bwselect()} options IK, CCT and CV have been depricated. Please see help for new options"  
				exit 7
			}
	
			if  ("`bwselect'"!="mserd" & "`bwselect'"!="msetwo" & "`bwselect'"!="msesum" & "`bwselect'"!="msecomb1" & "`bwselect'"!="msecomb2"  & "`bwselect'"!="cerrd" & "`bwselect'"!="certwo" & "`bwselect'"!="cersum" & "`bwselect'"!="cercomb1" & "`bwselect'"!="cercomb2" & "`bwselect'"~=""){
				di as error  "{err}{cmd:bwselect()} incorrectly specified"  
				exit 7
			}

			if ("`vce_select'"~="nn" & "`vce_select'"~="" & "`vce_select'"~="cluster" & "`vce_select'"~="nncluster" & "`vce_select'"~="hc1" & "`vce_select'"~="hc2" & "`vce_select'"~="hc3" & "`vce_select'"~="hc0"){ 
			 di as error  "{err}{cmd:vce()} incorrectly specified"  
			 exit 7
			}

			if ("`p'"<"0" | "`q'"<="0" | "`deriv'"<"0" | "`nnmatch'"<="0" ){
			 di as error  "{err}{cmd:p()}, {cmd:q()}, {cmd:deriv()}, {cmd:nnmatch()} should be positive"  
			 exit 411
			}
				
			if ("`p'">="`q'" & "`q'">"0"){
			 di as error  "{err}{cmd:q()} should be higher than {cmd:p()}"  
			 exit 125
			}
			
			if ("`deriv'">"`p'" & "`deriv'">"0" ){
			 di as error  "{err}{cmd:deriv()} can not be higher than {cmd:p()}"  
			 exit 125
			}

			if ("`p'">"0" ) {
				local p_round = round(`p')/`p'
				local q_round = round(`q')/`q'
				local d_round = round(`deriv'+1)/(`deriv'+1)
				local m_round = round(`nnmatch')/`nnmatch'

				if (`p_round'!=1 | `q_round'!=1 |`d_round'!=1 |`m_round'!=1 ){
				 di as error  "{err}{cmd:p()}, {cmd:q()}, {cmd:deriv()} and {cmd:nnmatch()} should be integers"  
				 exit 126
				}
			}
			if (`level'>100 | `level'<=0){
			 di as error  "{err}{cmd:level()}should be set between 0 and 100"  
			 exit 125
			}
	}
	*********************** END ERROR CHECKING ************************************************************
		
	if ("`h'"!="") local bwselect = "Manual"
	if ("`b_l'"=="" & "`b_r'"=="" & "`h_l'"!="" & "`h_r'"!="") {
		local b_r = `h_r'
		local b_l = `h_l'
	}
	
	if ("`bwselect'"=="")   local bwselect= "mserd"
	if ( "`h'"==""  ) {
		*disp in ye "Computing bandwidth selectors."
		qui rdbwselect `y' `x', c(`c') covs(`covs') deriv(`deriv') fuzzy(`fuzzy') p(`p') q(`q') kernel(`kernel') weights(`weights') vce(`vce') bwselect(`bwselect') scaleregul(`scaleregul') nochecks
		if	("`bwselect'"=="msetwo" | "`bwselect'"=="certwo" | "`bwselect'"=="msecomb2" | "`bwselect'"=="cercomb2") {
				local h_r = e(h_`bwselect'_r)
				local h_l = e(h_`bwselect'_l)
				local b_r = e(b_`bwselect'_r)
				local b_l = e(b_`bwselect'_l)
			}
		else {
				local h_r = e(h_`bwselect')
				local h_l = e(h_`bwselect')
				local b_r = e(b_`bwselect')
				local b_l = e(b_`bwselect')
		}
		if ("`h_r'"=="0" | "`h_r'"==".") {
			di as error  "{err}{cmd:rdrobust()} not able to compute the loc. poly. bandwidth (h) above the threshold. Please run {cmd:rdbwselect()} for more information}"  
			exit 125
		}	
		if ("`h_l'"=="0" | "`h_l'"==".") {
			di as error  "{err}{cmd:rdrobust()} not able to compute the loc. poly. bandwidth (h) below the threshold. Please run {cmd:rdbwselect()} for more information}"  
			exit 125
		}
		if ("`b_r'"=="0" | "`b_r'"==".") {
			di as error  "{err}{cmd:rdrobust()} not able to compute the bias bandwidth (b) above the threshold. Please run {cmd:rdbwselect()} for more information}"  
			exit 125
		}
		if ("`b_l'"=="0" | "`b_l'"==".") {
			di as error  "{err}{cmd:rdrobust()} not able to compute the bias bandwidth (b) below the threshold. Please run {cmd:rdbwselect()} for more information}"  
			exit 125
		}
	}

	if ("`rho'">"0")  {
		local b_l = `h_l'/`rho'
		local b_r = `h_r'/`rho'
	}
	
	if      ("`kernel'"=="epanechnikov" | "`kernel'"=="epa") local kernel_type = "Epanechnikov"
	else if ("`kernel'"=="uniform"      | "`kernel'"=="uni") local kernel_type = "Uniform"
	else                                                     local kernel_type = "Triangular"

	if ("`vce_select'"=="nn") {
		sort `x', stable
		tempvar dups dupsid
		by `x': generate dups = _N
		by `x': generate dupsid = _n
	}

	mata{
		Y = st_data(.,("`y'"), 0);	X = st_data(.,("`x'"), 0)
		
		X_l = select(X,X:<`c');	X_r = select(X,X:>=`c')
		Y_l = select(Y,X:<`c');	Y_r = select(Y,X:>=`c')
		N_l = length(X_l);		N_r = length(X_r)
		h_l = strtoreal("`h_l'"); h_r = strtoreal("`h_r'")
		b_l = strtoreal("`b_l'"); b_r = strtoreal("`b_r'")
		w_h_l = rdrobust_kweight(X_l,`c',h_l,"`kernel'");	w_h_r = rdrobust_kweight(X_r,`c',h_r,"`kernel'")
		w_b_l = rdrobust_kweight(X_l,`c',b_l,"`kernel'");	w_b_r = rdrobust_kweight(X_r,`c',b_r,"`kernel'")
		
		if ("`weights'"~="") {
			fw = st_data(.,("`weights'"), 0)
			fw_l = select(fw,X:<`c');	fw_r = select(fw,X:>=`c')
			w_h_l = fw_l:*w_h_l;	w_h_r = fw_r:*w_h_r
			w_b_l = fw_l:*w_b_l;	w_b_r = fw_r:*w_b_r			
		}
		
		ind_h_l = selectindex(w_h_l:> 0);		ind_h_r = selectindex(w_h_r:> 0)
		ind_b_l = selectindex(w_b_l:> 0);		ind_b_r = selectindex(w_b_r:> 0)
		N_h_l = length(ind_h_l);	N_b_l = length(ind_b_l)
		N_h_r = length(ind_h_r);	N_b_r = length(ind_b_r)
		
		if (N_h_l<5 | N_h_r<5 | N_b_l<5 | N_b_r<5){
		 display("{err}Not enough observations to perform calculations")
		 exit(1)
		}
		
		ind_l = ind_b_l; ind_r = ind_b_r
		if (h_l>b_l) {
			ind_l = ind_h_l   
		}
		if (h_r>b_r) {
			ind_r = ind_h_r   
		}
		eN_l = length(ind_l); eN_r = length(ind_r)
		eY_l  = Y_l[ind_l];	eY_r  = Y_r[ind_r]
		eX_l  = X_l[ind_l];	eX_r  = X_r[ind_r]
		W_h_l = w_h_l[ind_l];	W_h_r = w_h_r[ind_r]
		W_b_l = w_b_l[ind_l];	W_b_r = w_b_r[ind_r]
		
		edups_l = edups_r = edupsid_l= edupsid_r = 0	
		if ("`vce_select'"=="nn") {
			dups      = st_data(.,("dups"), 0); dupsid    = st_data(.,("dupsid"), 0)
			dups_l    = select(dups,X:<`c');    dups_r    = select(dups,X:>=`c')
			dupsid_l  = select(dupsid,X:<`c');  dupsid_r  = select(dupsid,X:>=`c')
			edups_l   = dups_l[ind_l];	  	    edups_r   = dups_r[ind_r]
			edupsid_l = dupsid_l[ind_l];	    edupsid_r = dupsid_r[ind_r]
		}
		
		u_l = (eX_l:-`c')/h_l;	u_r = (eX_r:-`c')/h_r;
		R_q_l = J(length(ind_l),(`q'+1),.); R_q_r = J(length(ind_r),(`q'+1),.)
			for (j=1; j<=(`q'+1); j++)  {
				R_q_l[.,j] = (eX_l:-`c'):^(j-1);  R_q_r[.,j] = (eX_r:-`c'):^(j-1)
			}
		R_p_l = R_q_l[,1::(`p'+1)]; R_p_r = R_q_r[,1::(`p'+1)]
		dZ = dC = 0
		dZ=dT=Z_l=Z_r=T_l=T_r=g_l=g_r=eT_l=eT_r=eZ_l=eZ_r=0
	
		**************************************************************************************************************************************************
		*display("Computing RD estimates.")
		**************************************************************************************************************************************************
		L_l = quadcross(R_p_l:*W_h_l,u_l:^(`p'+1)); L_r = quadcross(R_p_r:*W_h_r,u_r:^(`p'+1)) 
		invG_q_l  = cholinv(quadcross(R_q_l,W_b_l,R_q_l));	invG_q_r  = cholinv(quadcross(R_q_r,W_b_r,R_q_r))
		invG_p_l  = cholinv(quadcross(R_p_l,W_h_l,R_p_l));	invG_p_r  = cholinv(quadcross(R_p_r,W_h_r,R_p_r)) /* can be obtained from q: (before inverse) */
		
		if (rank(invG_p_l)==. | rank(invG_p_r)==. | rank(invG_q_l)==. | rank(invG_q_r)==. ){
		display("{err}Invertibility problem: check variability of running variable around cutoff")
		exit(1)
		}
		
		e_p1 = J((`q'+1),1,0); e_p1[`p'+2]=1
		e_v  = J((`p'+1),1,0); e_v[`deriv'+1]=1
		Q_q_l = ((R_p_l:*W_h_l)' - h_l^(`p'+1)*(L_l*e_p1')*((invG_q_l*R_q_l')':*W_b_l)')'
		Q_q_r = ((R_p_r:*W_h_r)' - h_r^(`p'+1)*(L_r*e_p1')*((invG_q_r*R_q_r')':*W_b_r)')'
		D_l = eY_l; D_r = eY_r
		indC_l=indC_r=eC_l=eC_r=0
		
		if ("`fuzzy'"~="") {
				T    = st_data(.,("`fuzzyvar'"), 0);	dT = 1
				T_l  = select(T,X:<`c');  eT_l  = T_l[ind_l]
				T_r  = select(T,X:>=`c'); eT_r  = T_r[ind_r]
				D_l  = D_l,eT_l; D_r = D_r,eT_r
				if (variance(T_l)==0 | variance(T_r)==0 )	st_local("perf_comp","perf_comp")
		}
		
		if ("`covs'"~="") {
				Z    = st_data(.,tokens("`covs'"), 0); dZ = cols(Z)
				Z_l  = select(Z,X:<`c');	eZ_l = Z_l[ind_l,]
				Z_r  = select(Z,X:>=`c');	eZ_r = Z_r[ind_r,]
				D_l  = D_l,eZ_l; D_r = D_r,eZ_r
				U_p_l = quadcross(R_p_l:*W_h_l,D_l); U_p_r = quadcross(R_p_r:*W_h_r,D_r)
		}
		
		if ("`cluster'"~="") {
				C  = st_data(.,("`clustvar'"), 0); dC=1
				C_l  = select(C,X:<`c'); C_r  = select(C,X:>=`c')
				eC_l  = C_l[ind_l];	     eC_r  = C_r[ind_r]
				indC_l = order(eC_l,1);  indC_r = order(eC_r,1) 
				g_l = rows(panelsetup(eC_l[indC_l],1));	g_r = rows(panelsetup(eC_r[indC_r],1))
		}
		
		beta_p_l = invG_p_l*quadcross(R_p_l:*W_h_l,D_l); beta_q_l = invG_q_l*quadcross(R_q_l:*W_b_l,D_l); beta_bc_l = invG_p_l*quadcross(Q_q_l,D_l) 
		beta_p_r = invG_p_r*quadcross(R_p_r:*W_h_r,D_r); beta_q_r = invG_q_r*quadcross(R_q_r:*W_b_r,D_r); beta_bc_r = invG_p_r*quadcross(Q_q_r,D_r)
		beta_p  = beta_p_r  - beta_p_l
		beta_q  = beta_q_r  - beta_q_l
		beta_bc = beta_bc_r - beta_bc_l
		
		if (dZ==0) {
		
				tau_cl = tau_Y_cl = `scalepar'*factorial(`deriv')*beta_p[(`deriv'+1),1]
				tau_bc = tau_Y_bc = `scalepar'*factorial(`deriv')*beta_bc[(`deriv'+1),1]
				s_Y = 1
				
				tau_Y_cl_l = `scalepar'*factorial(`deriv')*beta_p_l[(`deriv'+1),1]
				tau_Y_cl_r = `scalepar'*factorial(`deriv')*beta_p_r[(`deriv'+1),1]
				tau_Y_bc_l = `scalepar'*factorial(`deriv')*beta_bc_l[(`deriv'+1),1]
				tau_Y_bc_r = `scalepar'*factorial(`deriv')*beta_bc_r[(`deriv'+1),1]
				
				bias_l = tau_Y_cl_l-tau_Y_bc_l
				bias_r = tau_Y_cl_r-tau_Y_bc_r 
				
				if (dT>0) {
					tau_T_cl =  factorial(`deriv')*beta_p[(`deriv'+1),2]
					tau_T_bc = 	factorial(`deriv')*beta_bc[(`deriv'+1),2]
					s_Y = (1/tau_T_cl \ -(tau_Y_cl/tau_T_cl^2))
					B_F = tau_Y_cl-tau_Y_bc \ tau_T_cl-tau_T_bc
					tau_cl = tau_Y_cl/tau_T_cl
					tau_bc = tau_cl - s_Y'*B_F
					sV_T = 0 \ 1
										
					tau_T_cl_l =  factorial(`deriv')*beta_p_l[(`deriv'+1),2]
					tau_T_cl_r =  factorial(`deriv')*beta_p_r[(`deriv'+1),2]
					tau_T_bc_l =  factorial(`deriv')*beta_bc_l[(`deriv'+1),2]
					tau_T_bc_r =  factorial(`deriv')*beta_bc_r[(`deriv'+1),2]
					
					B_F_l = tau_Y_cl_l-tau_Y_bc_l \ tau_T_cl_l-tau_T_bc_l
					B_F_r = tau_Y_cl_r-tau_Y_bc_r \ tau_T_cl_r-tau_T_bc_r
					
					bias_l = s_Y'*B_F_l
					bias_r = s_Y'*B_F_r
					
				}	
		}
		
		if (dZ>0) {	
			ZWD_p_l  = quadcross(eZ_l,W_h_l,D_l)
			ZWD_p_r  = quadcross(eZ_r,W_h_r,D_r)
			colsZ = (2+dT)::(2+dT+dZ-1)
			UiGU_p_l =  quadcross(U_p_l[,colsZ],invG_p_l*U_p_l) 
			UiGU_p_r =  quadcross(U_p_r[,colsZ],invG_p_r*U_p_r) 
			ZWZ_p_l = ZWD_p_l[,colsZ] - UiGU_p_l[,colsZ] 
			ZWZ_p_r = ZWD_p_r[,colsZ] - UiGU_p_r[,colsZ]     
			ZWY_p_l = ZWD_p_l[,1::1+dT] - UiGU_p_l[,1::1+dT] 
			ZWY_p_r = ZWD_p_r[,1::1+dT] - UiGU_p_r[,1::1+dT]     
			ZWZ_p = ZWZ_p_r + ZWZ_p_l
			ZWY_p = ZWY_p_r + ZWY_p_l
			gamma_p = cholinv(ZWZ_p)*ZWY_p
			s_Y = (1 \  -gamma_p[,1])
			
			if (dT==0) {
				tau_cl = s_Y'*beta_p[(`deriv'+1),]'
				tau_bc = s_Y'*beta_bc[(`deriv'+1),]'
				
				tau_Y_cl_l = s_Y'*beta_p_l[(`deriv'+1),]'
				tau_Y_cl_r = s_Y'*beta_p_r[(`deriv'+1),]'
				tau_Y_bc_l = s_Y'*beta_bc_l[(`deriv'+1),]'
				tau_Y_bc_r = s_Y'*beta_bc_r[(`deriv'+1),]'
				
				bias_l = tau_Y_cl_l-tau_Y_bc_l
				bias_r = tau_Y_cl_r-tau_Y_bc_r 
				
			}
			
			if (dT>0) {
					s_T  = 1 \ -gamma_p[,2]
					sV_T = (0 \ 1 \ -gamma_p[,2] )
					tau_Y_cl = factorial(`deriv')*s_Y'*vec((beta_p[(`deriv'+1),1],beta_p[(`deriv'+1),colsZ]))
					tau_T_cl = factorial(`deriv')*s_T'*vec((beta_p[(`deriv'+1),2],beta_p[(`deriv'+1),colsZ]))
					tau_Y_bc = factorial(`deriv')*s_Y'*vec((beta_bc[(`deriv'+1),1],beta_bc[(`deriv'+1),colsZ]))
					tau_T_bc = factorial(`deriv')*s_T'*vec((beta_bc[(`deriv'+1),2],beta_bc[(`deriv'+1),colsZ]))
			
					tau_Y_cl_l = factorial(`deriv')*s_Y'*vec((beta_p_l[(`deriv'+1),1], beta_p_l[(`deriv'+1),colsZ]))
					tau_Y_cl_r = factorial(`deriv')*s_Y'*vec((beta_p_r[(`deriv'+1),2], beta_p_r[(`deriv'+1),colsZ]))
					tau_Y_bc_l = factorial(`deriv')*s_Y'*vec((beta_bc_l[(`deriv'+1),1],beta_bc_l[(`deriv'+1),colsZ]))
					tau_Y_bc_r = factorial(`deriv')*s_Y'*vec((beta_bc_r[(`deriv'+1),2],beta_bc_r[(`deriv'+1),colsZ]))
					
					tau_T_cl_l = factorial(`deriv')*s_T'*vec((beta_p_l[(`deriv'+1),1], beta_p_l[(`deriv'+1),colsZ]))
					tau_T_cl_r = factorial(`deriv')*s_T'*vec((beta_p_r[(`deriv'+1),2], beta_p_r[(`deriv'+1),colsZ]))
					tau_T_bc_l = factorial(`deriv')*s_T'*vec((beta_bc_l[(`deriv'+1),1],beta_bc_l[(`deriv'+1),colsZ]))
					tau_T_bc_r = factorial(`deriv')*s_T'*vec((beta_bc_r[(`deriv'+1),2],beta_bc_r[(`deriv'+1),colsZ]))
					
					
					B_F = tau_Y_cl-tau_Y_bc \ tau_T_cl-tau_T_bc
					s_Y = 1/tau_T_cl \ -(tau_Y_cl/tau_T_cl^2)
					tau_cl = tau_Y_cl/tau_T_cl
					tau_bc = tau_cl - s_Y'*B_F
					
					B_F_l = tau_Y_cl_l-tau_Y_bc_l \ tau_T_cl_l-tau_T_bc_l
					B_F_r = tau_Y_cl_r-tau_Y_bc_r \ tau_T_cl_r-tau_T_bc_r
					
					bias_l = s_Y'*B_F_l
					bias_r = s_Y'*B_F_r
					
					s_Y = (1/tau_T_cl \ -(tau_Y_cl/tau_T_cl^2) \ -(1/tau_T_cl)*gamma_p[,1] + (tau_Y_cl/tau_T_cl^2)*gamma_p[,2])

					
			}
		}
			
		**************************************************************************************************************************************************
		*display("Computing variance-covariance matrix.")
		**************************************************************************************************************************************************
		hii_l=hii_r=predicts_p_l=predicts_p_r=predicts_q_l=predicts_q_r=0
		if ("`vce_select'"=="hc0" | "`vce_select'"=="hc1" | "`vce_select'"=="hc2" | "`vce_select'"=="hc3") {
			predicts_p_l=R_p_l*beta_p_l
			predicts_p_r=R_p_r*beta_p_r
			predicts_q_l=R_q_l*beta_q_l
			predicts_q_r=R_q_r*beta_q_r
			if ("`vce_select'"=="hc2" | "`vce_select'"=="hc3") {
				hii_l=J(length(ind_l),1,.)	
					for (i=1; i<=length(ind_l); i++) {
						hii_l[i] = R_p_l[i,]*invG_p_l*(R_p_l:*W_h_l)[i,]'
				}
				hii_r=J(length(ind_r),1,.)	
					for (i=1; i<=length(ind_r); i++) {
						hii_r[i] = R_p_r[i,]*invG_p_r*(R_p_r:*W_h_r)[i,]'
				}
			}
		}
			
		res_h_l = rdrobust_res(eX_l, eY_l, eT_l, eZ_l, predicts_p_l, hii_l, "`vce_select'", `nnmatch', edups_l, edupsid_l, `p'+1)
		res_h_r = rdrobust_res(eX_r, eY_r, eT_r, eZ_r, predicts_p_r, hii_r, "`vce_select'", `nnmatch', edups_r, edupsid_r, `p'+1)
		if ("`vce_select'"=="nn") {
				res_b_l = res_h_l;	res_b_r = res_h_r
		}
		else {
				res_b_l = rdrobust_res(eX_l, eY_l, eT_l, eZ_l, predicts_q_l, hii_l, "`vce_select'", `nnmatch', edups_l, edupsid_l, `q'+1)
				res_b_r = rdrobust_res(eX_r, eY_r, eT_r, eZ_r, predicts_q_r, hii_r, "`vce_select'", `nnmatch', edups_r, edupsid_r, `q'+1)
		}

		V_Y_cl_l = invG_p_l*rdrobust_vce(dT+dZ, s_Y, R_p_l:*W_h_l, res_h_l, eC_l, indC_l)*invG_p_l
		V_Y_cl_r = invG_p_r*rdrobust_vce(dT+dZ, s_Y, R_p_r:*W_h_r, res_h_r, eC_r, indC_r)*invG_p_r
		V_Y_bc_l = invG_p_l*rdrobust_vce(dT+dZ, s_Y, Q_q_l, res_b_l, eC_l, indC_l)*invG_p_l
		V_Y_bc_r = invG_p_r*rdrobust_vce(dT+dZ, s_Y, Q_q_r, res_b_r, eC_r, indC_r)*invG_p_r
		V_tau_cl = factorial(`deriv')^2*(V_Y_cl_l+V_Y_cl_r)[`deriv'+1,`deriv'+1]
		V_tau_rb = factorial(`deriv')^2*(V_Y_bc_l+V_Y_bc_r)[`deriv'+1,`deriv'+1]
		se_tau_cl = (`scalepar')*sqrt(V_tau_cl);	se_tau_rb = (`scalepar')*sqrt(V_tau_rb)

		if ("`fuzzy'"!="") {
			V_T_cl_l = invG_p_l*rdrobust_vce(dT+dZ, sV_T, R_p_l:*W_h_l, res_h_l, eC_l, indC_l)*invG_p_l
			V_T_cl_r = invG_p_r*rdrobust_vce(dT+dZ, sV_T, R_p_r:*W_h_r, res_h_r, eC_r, indC_r)*invG_p_r
			V_T_bc_l = invG_p_l*rdrobust_vce(dT+dZ, sV_T, Q_q_l, res_b_l, eC_l, indC_l)*invG_p_l
			V_T_bc_r = invG_p_r*rdrobust_vce(dT+dZ, sV_T, Q_q_r, res_b_r, eC_r, indC_r)*invG_p_r
			V_T_cl = factorial(`deriv')^2*(V_T_cl_l+V_T_cl_r)[`deriv'+1,`deriv'+1]
			V_T_rb = factorial(`deriv')^2*(V_T_bc_l+V_T_bc_r)[`deriv'+1,`deriv'+1]
			se_tau_T_cl = sqrt(V_T_cl);	se_tau_T_rb = sqrt(V_T_rb)
		}
		
		*display("Estimation completed.") 
		*quant = -invnormal(abs((1-(`level'/100))/2))
		st_numscalar("quant", -invnormal(abs((1-(`level'/100))/2)))
		st_numscalar("N_l",   N_l);     st_numscalar("N_r",   N_r)
		st_numscalar("N_h_l", N_h_l);	st_numscalar("N_b_l", N_b_l)
		st_numscalar("N_h_r", N_h_r);	st_numscalar("N_b_r", N_b_r)
		st_numscalar("tau_cl", tau_cl); st_numscalar("se_tau_cl", se_tau_cl)
		st_numscalar("tau_bc", tau_bc);	st_numscalar("se_tau_rb", se_tau_rb)
		*st_numscalar("tau_Y_cl_r", tau_Y_cl_r); st_numscalar("tau_Y_cl_l", tau_Y_cl_l)
		*st_numscalar("tau_Y_bc_r", tau_Y_bc_r);	st_numscalar("tau_Y_bc_l", tau_Y_bc_l)
		st_numscalar("bias_l", bias_l);  st_numscalar("bias_r", bias_r)
		st_matrix("beta_p_r", beta_p_r); st_matrix("beta_p_l", beta_p_l)
		st_matrix("beta_q_r", beta_q_r); st_matrix("beta_q_l", beta_q_l)
		st_numscalar("g_l",  g_l);       st_numscalar("g_r",   g_r)
		st_matrix("b", (tau_cl))
		st_matrix("V", (V_tau_cl))
		st_matrix("V_Y_cl_r", V_Y_cl_r); st_matrix("V_Y_cl_l", V_Y_cl_l)
		st_matrix("V_Y_bc_r", V_Y_bc_r); st_matrix("V_Y_bc_l", V_Y_bc_l)

		if ("`all'"~="") {
			st_matrix("b", (tau_cl,tau_bc,tau_bc))
			st_matrix("V", (V_tau_cl,0,0 \ 0,V_tau_cl,0 \0,0,V_tau_rb))
		}		
		
		if ("`fuzzy'"!="") {
			st_numscalar("tau_T_cl", tau_T_cl); st_numscalar("se_tau_T_cl", se_tau_T_cl)
			st_numscalar("tau_T_bc", tau_T_bc);	st_numscalar("se_tau_T_rb", se_tau_T_rb)	
			
			*st_numscalar("tau_T_cl_r", tau_T_cl_r); st_numscalar("tau_T_cl_l", tau_T_cl_l)
			*st_numscalar("tau_T_bc_r", tau_T_bc_r);	st_numscalar("tau_T_bc_l", tau_T_bc_l)
		}
	}
	
	************************************************
	********* OUTPUT TABLE *************************
	************************************************
	local rho_l = `h_l'/`b_l'
	local rho_r = `h_r'/`b_r'

	disp ""
	if "`fuzzy'"=="" {
		if ("`covs'"=="") {
			if      ("`deriv'"=="0") disp "Sharp RD estimates using local polynomial regression." 
			else if ("`deriv'"=="1") disp "Sharp kink RD estimates using local polynomial regression."	
			else                     disp "Sharp RD estimates using local polynomial regression. Derivative of order " `deriv' "."	
		}
		else {
			if      ("`deriv'"=="0") disp "Covariate-adjusted sharp RD estimates using local polynomial regression." 
			else if ("`deriv'"=="1") disp "Covariate-adjusted sharp kink RD estimates using local polynomial regression."	
			else                     disp "Covariate-adjusted sharp RD estimates using local polynomial regression. Derivative of order " `deriv' "."	
		}
	}
	else {
		if ("`covs'"=="") {
			if      ("`deriv'"=="0") disp "Fuzzy RD estimates using local polynomial regression." 
			else if ("`deriv'"=="1") disp "Fuzzy kink RD estimates using local polynomial regression."	
			else                     disp "Fuzzy RD estimates using local polynomial regression. Derivative of order " `deriv' "."	
		}
		else {
			if      ("`deriv'"=="0") disp "Covariate-adjusted sharp RD estimates using local polynomial regression." 
			else if ("`deriv'"=="1") disp "Covariate-adjusted sharp kink RD estimates using local polynomial regression."	
			else                     disp "Covariate-adjusted sharp RD estimates using local polynomial regression. Derivative of order " `deriv' "."			
		}
	}

	disp ""
	disp in smcl in gr "{ralign 18: Cutoff c = `c'}"        _col(19) " {c |} " _col(21) in gr "Left of " in yellow "c"  _col(33) in gr "Right of " in yellow "c"         _col(55) in gr "Number of obs = "  in yellow %10.0f `N_l'+`N_r'
	disp in smcl in gr "{hline 19}{c +}{hline 22}"                                                                                                                       _col(55) in gr "BW type       = "  in yellow "{ralign 10:`bwselect'}" 
	disp in smcl in gr "{ralign 18:Number of obs}"          _col(19) " {c |} " _col(21) as result %9.0f N_l             _col(34) %9.0f  N_r                              _col(55) in gr "Kernel        = "  in yellow "{ralign 10:`kernel_type'}" 
	disp in smcl in gr "{ralign 18:Eff. Number of obs}"     _col(19) " {c |} " _col(21) as result %9.0f N_h_l           _col(34) %9.0f  N_h_r                            _col(55) in gr "VCE method    = "  in yellow "{ralign 10:`vce_type'}" 
	disp in smcl in gr "{ralign 18:Order est. (p)}"         _col(19) " {c |} " _col(21) as result %9.0f `p'             _col(34) %9.0f  `p'         
	disp in smcl in gr "{ralign 18:Order bias (q)}"         _col(19) " {c |} " _col(21) as result %9.0f `q'             _col(34) %9.0f  `q'                              
	disp in smcl in gr "{ralign 18:BW est. (h)}"            _col(19) " {c |} " _col(21) as result %9.3f `h_l'           _col(34) %9.3f  `h_r'                                   
	disp in smcl in gr "{ralign 18:BW bias (b)}"            _col(19) " {c |} " _col(21) as result %9.3f `b_l'           _col(34) %9.3f  `b_r'
	disp in smcl in gr "{ralign 18:rho (h/b)}"              _col(19) " {c |} " _col(21) as result %9.3f `rho_l'         _col(34) %9.3f  `rho_r'
	if ("`cluster'"!="") {
		disp in smcl in gr "{ralign 18:Number of clusters}" _col(19) " {c |} " _col(21) as result %9.0f g_l             _col(34) %9.0f  g_r                         
	}
	disp ""
			

	if ("`fuzzy'"~="") {
		disp in yellow "First-stage estimates. Outcome: `fuzzyvar'. Running variable: `x'."
		disp in smcl in gr "{hline 19}{c TT}{hline 60}"
	    disp in smcl in gr "{ralign 18:Method}"  _col(19) " {c |} " _col(24) "Coef."  _col(33) `"Std. Err."'   _col(46) "z"    _col(52) "P>|z|"   _col(61) `"[`level'% Conf. Interval]"'
		disp in smcl in gr "{hline 19}{c +}{hline 60}"
		
		if ("`all'"=="") {
		*disp ""
			disp in smcl in gr "{ralign 18:Conventional}"      _col(19) " {c |} " _col(22) in ye %7.0g tau_T_cl _col(33) %7.0g se_tau_T_cl _col(43) %5.4f tau_T_cl/se_tau_T_cl _col(52) %5.3f  2*normal(-abs(tau_T_cl/se_tau_T_cl))  _col(60) %8.0g  tau_T_cl - quant*se_tau_T_cl _col(73) %8.0g tau_T_cl + quant*se_tau_T_cl 
			disp in smcl in gr "{ralign 18:Robust}"            _col(19) " {c |} " _col(22) in ye %7.0g "    -"  _col(33) %7.0g "    -"     _col(43) %5.4f tau_T_bc/se_tau_T_rb _col(52) %5.3f  2*normal(-abs(tau_T_bc/se_tau_T_rb))  _col(60) %8.0g  tau_T_bc - quant*se_tau_T_rb _col(73) %8.0g tau_T_bc + quant*se_tau_T_rb  
		}
		else {
			disp in smcl in gr "{ralign 18:Conventional}"      _col(19) " {c |} " _col(22) in ye %7.0g tau_T_cl _col(33) %7.0g se_tau_T_cl _col(43) %5.4f tau_T_cl/se_tau_T_cl _col(52) %5.3f  2*normal(-abs(tau_T_cl/se_tau_T_cl)) _col(60) %8.0g  tau_T_cl - quant*se_tau_T_cl _col(73) %8.0g tau_T_cl + quant*se_tau_T_cl  
			disp in smcl in gr "{ralign 18:Bias-corrected}"    _col(19) " {c |} " _col(22) in ye %7.0g tau_T_bc _col(33) %7.0g se_tau_T_cl _col(43) %5.4f tau_T_bc/se_tau_T_cl _col(52) %5.3f  2*normal(-abs(tau_T_bc/se_tau_T_cl)) _col(60) %8.0g  tau_T_bc - quant*se_tau_T_cl _col(73) %8.0g tau_T_bc + quant*se_tau_T_cl 
			disp in smcl in gr "{ralign 18:Robust}"            _col(19) " {c |} " _col(22) in ye %7.0g tau_T_bc _col(33) %7.0g se_tau_T_rb _col(43) %5.4f tau_T_bc/se_tau_T_rb _col(52) %5.3f  2*normal(-abs(tau_T_bc/se_tau_T_rb)) _col(60) %8.0g  tau_T_bc - quant*se_tau_T_rb _col(73) %8.0g tau_T_bc + quant*se_tau_T_rb 
		}
			disp in smcl in gr "{hline 19}{c BT}{hline 60}"
			disp ""
	}
	
	if ("`fuzzy'"=="") disp           "Outcome: `y'. Running variable: `x'."
	else               disp in yellow "Treatment effect estimates. Outcome: `y'. Running variable: `x'. Treatment Status: `fuzzyvar'."
		
	disp in smcl in gr "{hline 19}{c TT}{hline 60}"
	disp in smcl in gr "{ralign 18:Method}"             _col(19) " {c |} " _col(24) "Coef."               _col(33) `"Std. Err."'    _col(46) "z"                    _col(52) "P>|z|"                                  _col(61) `"[`level'% Conf. Interval]"'
	disp in smcl in gr "{hline 19}{c +}{hline 60}"

	if ("`all'"=="") {
		disp in smcl in gr "{ralign 18:Conventional}"   _col(19) " {c |} " _col(22) in ye %7.0g tau_cl    _col(33) %7.0g se_tau_cl  _col(43) %5.4f tau_cl/se_tau_cl _col(52) %5.3f  2*normal(-abs(tau_cl/se_tau_cl))  _col(60) %8.0g tau_cl - quant*se_tau_cl _col(73) %8.0g tau_cl + quant*se_tau_cl 
		disp in smcl in gr "{ralign 18:Robust}"         _col(19) " {c |} " _col(22) in ye %7.0g "    -"   _col(33) %7.0g "    -"    _col(43) %5.4f tau_bc/se_tau_rb _col(52) %5.3f  2*normal(-abs(tau_bc/se_tau_rb))  _col(60) %8.0g tau_bc - quant*se_tau_rb _col(73) %8.0g tau_bc + quant*se_tau_rb  
	}
	else {
		disp in smcl in gr "{ralign 18:Conventional}"   _col(19) " {c |} " _col(22) in ye %7.0g tau_cl    _col(33) %7.0g se_tau_cl _col(43) %5.4f tau_cl/se_tau_cl _col(52) %5.3f  2*normal(-abs(tau_cl/se_tau_cl)) _col(60) %8.0g  tau_cl - quant*se_tau_cl _col(73) %8.0g tau_cl + quant*se_tau_cl  
		disp in smcl in gr "{ralign 18:Bias-corrected}" _col(19) " {c |} " _col(22) in ye %7.0g tau_bc    _col(33) %7.0g se_tau_cl _col(43) %5.4f tau_bc/se_tau_cl _col(52) %5.3f  2*normal(-abs(tau_bc/se_tau_cl)) _col(60) %8.0g  tau_bc - quant*se_tau_cl _col(73) %8.0g tau_bc + quant*se_tau_cl  
		disp in smcl in gr "{ralign 18:Robust}"         _col(19) " {c |} " _col(22) in ye %7.0g tau_bc    _col(33) %7.0g se_tau_rb _col(43) %5.4f tau_bc/se_tau_rb _col(52) %5.3f  2*normal(-abs(tau_bc/se_tau_rb)) _col(60) %8.0g  tau_bc - quant*se_tau_rb _col(73) %8.0g tau_bc + quant*se_tau_rb  
	}
		disp in smcl in gr "{hline 19}{c BT}{hline 60}"

	if ("`covs'"!="")        disp "Covariate-adjusted estimates. Additional covariates included: `ncovs'"
	if ("`cluster'"!="")     disp "Std. Err. adjusted for clusters in " "`clustvar'"
	if ("`scalepar'"!="1")   disp "Scale parameter: " `scalepar' 
	if ("`scaleregul'"!="1") disp "Scale regularization: " `scaleregul'
	
	if ("`nowarnings'"!="") {
		if (`h_l'>=`range_l' | `h_r'>=`range_r') disp in red "WARNING: bandwidth {it:h} greater than the range of the data."
		if (`b_l'>=`range_l' | `b_r'>=`range_r') disp in red "WARNING: bandwidth {it:b} greater than the range of the data."
		if (N_h_l<20 | N_h_r<20) 				 disp in red "WARNING: bandwidth {it:h} too low."
		if (N_b_l<20 | N_b_r<20) 				 disp in red "WARNING: bandwidth {it:b} too low."
		if ("`sharpbw'"~="")   					 disp in red "WARNING: bandwidths automatically computed for sharp RD estimation."
		if ("`perf_comp'"~="")   				 disp in red "WARNING: bandwidths automatically computed for sharp RD estimation because perfect compliance was detected on at least one side of the threshold."
	}
	
	local ci_l_rb = round(tau_bc - quant*se_tau_rb,0.001)
	local ci_r_rb = round(tau_bc + quant*se_tau_rb,0.001)

	matrix rownames V = RD_Estimate
	matrix colnames V = RD_Estimate
	matrix colnames b = RD_Estimate
	
	local tempo: colfullnames V
	matrix rownames V = `tempo'
	
	if ("`all'"~="") {
		matrix rownames V = Conventional Bias-corrected Robust
		matrix colnames V = Conventional Bias-corrected Robust
		matrix colnames b = Conventional Bias-corrected Robust
	}
		
	restore

	ereturn clear
	cap ereturn post b V
	ereturn scalar N = `N'
	ereturn scalar N_l = N_l
	ereturn scalar N_r = N_r
	ereturn scalar N_h_l = N_h_l
	ereturn scalar N_h_r = N_h_r
	ereturn scalar N_b_l = N_b_l
	ereturn scalar N_b_r = N_b_r
	ereturn scalar c = `c'
	ereturn scalar p = `p'
	ereturn scalar q = `q'
	ereturn scalar h_l = `h_l'
	ereturn scalar h_r = `h_r'
	ereturn scalar b_l = `b_l'
	ereturn scalar b_r = `b_r'
	ereturn scalar level = `level'
	ereturn scalar tau_cl   = tau_cl
	ereturn scalar tau_bc   = tau_bc
	*ereturn scalar tau_Y_cl_l = tau_Y_cl_l
	*ereturn scalar tau_Y_cl_r = tau_Y_cl_r
	*ereturn scalar tau_Y_bc_l = tau_Y_bc_l
	*ereturn scalar tau_Y_bc_r = tau_Y_bc_r
	ereturn scalar bias_l = bias_l
	ereturn scalar bias_r = bias_r
	ereturn scalar se_tau_cl = se_tau_cl
	ereturn scalar se_tau_rb = se_tau_rb
	ereturn scalar ci_l_cl = tau_cl - quant*se_tau_cl
	ereturn scalar ci_r_cl = tau_cl + quant*se_tau_cl
	ereturn scalar pv_cl = 2*normal(-abs(tau_cl/se_tau_cl))
	ereturn scalar ci_l_rb = tau_bc - quant*se_tau_rb
	ereturn scalar ci_r_rb = tau_bc + quant*se_tau_rb
	ereturn scalar pv_rb = 2*normal(-abs(tau_bc/se_tau_rb))
	
	if ("`fuzzy'"!="") {
		ereturn scalar tau_T_cl  = tau_T_cl
		ereturn scalar tau_T_bc  = tau_T_bc
		ereturn scalar se_tau_T_cl   = se_tau_T_cl
		ereturn scalar se_tau_T_rb   = se_tau_T_rb
		
		*ereturn scalar tau_T_cl_l = tau_T_cl_l
		*ereturn scalar tau_T_cl_r = tau_T_cl_r
		*ereturn scalar tau_T_bc_l = tau_T_bc_l
		*ereturn scalar tau_T_bc_r = tau_T_bc_r
	}
	
	ereturn matrix beta_p_r = beta_p_r
	ereturn matrix beta_p_l = beta_p_l
	ereturn matrix V_cl_l = V_Y_cl_l 
	ereturn matrix V_cl_r = V_Y_cl_r 
	ereturn matrix V_rb_l = V_Y_bc_l 
	ereturn matrix V_rb_r = V_Y_bc_r 
	
	ereturn local ci_rb  [`ci_l_rb' , `ci_r_rb']
	ereturn local kernel = "`kernel_type'"
	ereturn local bwselect = "`bwselect'"
	ereturn local vce_select = "`vce_type'"
	if ("`covs'"!="")    ereturn local covs "`covs'"
	if ("`cluster'"!="") ereturn local clustvar "`clustvar'"
	ereturn local outcomevar "`y'"
	ereturn local runningvar "`x'"
	ereturn local depvar "`y'"
	ereturn local cmd "rdrobust"
	
	mata mata clear
 
end
	





