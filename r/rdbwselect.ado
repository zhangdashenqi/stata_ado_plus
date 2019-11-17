*!version 7.3.0  09Jun2017  
 
capture program drop rdbwselect
program define rdbwselect, eclass
	syntax anything [if] [in] [, c(real 0) fuzzy(string) deriv(real 0) p(real 1) q(real 0) covs(string) kernel(string) weights(string) bwselect(string) vce(string) scaleregul(real 1) all nochecks  ]

	marksample touse
	preserve
	qui keep if `touse'
	tokenize "`anything'"
	local y `1'
	local x `2'
	local kernel   = lower("`kernel'")
	local bwselect = lower("`bwselect'")
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
		if ("`vce_select'"!="cluster" & "`vce_select'"!="nncluster" ) di as error "{err}{cmd:vce()} incorrectly specified"  
	}
	if `w' > 3 {
		di as error "{err}{cmd:vce()} incorrectly specified"  
		exit 125
	}
	
	local vce_type = "NN"
	if ("`vce_select'"=="hc0")       local vce_type = "HC0"
	if ("`vce_select'"=="hc1")       local vce_type = "HC1"
	if ("`vce_select'"=="hc2")       local vce_type = "HC2"
	if ("`vce_select'"=="hc3")       local vce_type = "HC3"
	if ("`vce_select'"=="cluster")   local vce_type = "Cluster"
	if ("`vce_select'"=="nncluster") local vce_type = "NNcluster"

	if ("`vce_select'"=="cluster" | "`vce_select'"=="nncluster") local cluster = "cluster"
	if ("`vce_select'"=="cluster")   local vce_select = "hc0"
	if ("`vce_select'"=="nncluster") local vce_select = "nn"
	if ("`vce_select'"=="")          local vce_select = "nn"
	
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
		di as error "{err}{cmd:fuzzy()} only accepts two inputs"  
		exit 125
	}
	************************************************************

			qui drop if `y'==. | `x'==.
			if ("`cluster'"!="") qui drop if `clustvar'==.
			if ("`fuzzy'"~="") {
				qui drop if `fuzzyvar'==.
				qui su `fuzzyvar'
				qui replace `fuzzyvar' = `fuzzyvar'/r(sd)
			}
			if ("`covs'"~="") {
				qui ds `covs'
				local covs_list = r(varlist)
				foreach z in `covs_list' {
					qui drop if `z'==.
					qui su `z'
					qui replace `z' = `z'/r(sd)
				}
				local ncovs: word count `covs_list'
				qui reg `y' `x' `covs'
				if (e(rank)<(`ncovs'+ 2)) {
					di as error "{err}Multicollinearity issue detected in {cmd:covs}. Please rescale and/or remove redundant covariates"  
					*exit 125
				}
			}
			
			*** reescaling *************
			qui su `y'
			local y_sd = r(sd)
			qui replace `y' = `y'/`y_sd'
			qui su `x'
			local x_sd = r(sd)
			qui replace `x' = `x'/`x_sd'
			local c_orig = `c'
			local c = `c'/`x_sd'
			*****************************
			qui su `x', d
			local x_min = r(min)
			local x_max = r(max)
			local N = r(N)
			local x_iq = r(p75)-r(p25)
			qui su `x'  if `x'<`c', d
			local x_l_min = `x_sd'*r(min)
			local x_l_max = `x_sd'*r(max)
			local N_l = r(N)
			local range_l = abs(`c'-r(min))
			local c_bw_l  = abs(r(p25))
			local x_iq_l = r(p75)-r(p25)
			local x_sd_l = r(sd)
			qui su `x'  if `x'>=`c', d
			local x_r_min = `x_sd'*r(min)
			local x_r_max = `x_sd'*r(max)
			local N_r = r(N)
			local range_r = abs(r(max)-`c')
			local c_bw_r  = abs(r(p75))
			local x_iq_r = r(p75)-r(p25)
			local x_sd_r = r(sd)
			if ("`deriv'">"0" & "`p'"=="1" & "`q'"=="0") local p = (`deriv'+1)
			if ("`q'"=="0")                              local q = (`p'+1)

			**************************** BEGIN ERROR CHECKING ************************************************
			if ("`nochecks'"=="") {
			if (`c'<=`x_min' | `c'>=`x_max'){
			 di as error "{err}{cmd:c()} should be set within the range of `x'"  
			 exit 125
			}
			
			if (`N_l'<10 | `N_r'<10){
			 di as error "{err}Not enough observations to perform calculations"  
			 exit 2001
			}
			
			if ("`kernel'"~="uni" & "`kernel'"~="uniform" & "`kernel'"~="tri" & "`kernel'"~="triangular" & "`kernel'"~="epa" & "`kernel'"~="epanechnikov" & "`kernel'"~="" ){
			 di as error "{err}{cmd:kernel()} incorrectly specified"  
			 exit 7
			}

			if ("`bwselect'"=="CCT" | "`bwselect'"=="IK" | "`bwselect'"=="CV" |"`bwselect'"=="cct" | "`bwselect'"=="ik" | "`bwselect'"=="cv"){
				di as error "{err}{cmd:bwselect()} options IK, CCT and CV have been depricated. Please see help for new options"  
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
			 di as error  "{err}{cmd:p()}, {cmd:q()}, {cmd:deriv()}, {cmd:nnmatch()} imson should be positive"  
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
		}
			
	if ("`kernel'"=="epanechnikov" | "`kernel'"=="epa") {
		local kernel_type = "Epanechnikov"
		local C_c = 2.34
	}
	else if ("`kernel'"=="uniform" | "`kernel'"=="uni") {
		local kernel_type = "Uniform"
		local C_c = 1.843
	}
	else {
		local kernel_type = "Triangular"
		local C_c = 2.576
	}
	
	if ("`vce_select'"=="nn") {
		sort `x', stable
		tempvar dups dupsid
		by `x': gen dups = _N
		by `x': gen dupsid = _n
	}

	mata{
	c = `c'
	p = `p'
	q = `q'
	nnmatch =  strtoreal("`nnmatch'")
	Y = st_data(.,("`y'"), 0);	X = st_data(.,("`x'"), 0)
	X_l = select(X,X:<c);	X_r = select(X,X:>=c)
	Y_l = select(Y,X:<c);	Y_r = select(Y,X:>=c)
	
	dZ=Z_l=Z_r=T_l=T_r=Cind_l=Cind_r=g_l=g_r=dups_l=dups_r=dupsid_l=dupsid_r=0

	if ("`vce_select'"=="nn") {
		dups      = st_data(.,("dups"), 0); dupsid    = st_data(.,("dupsid"), 0)
		dups_l    = select(dups,X:<`c');    dups_r    = select(dups,X:>=`c')
		dupsid_l  = select(dupsid,X:<`c');  dupsid_r  = select(dupsid,X:>=`c')
	}
	
	if ("`covs'"~="") {
		Z   = st_data(.,tokens("`covs'"), 0)
		dZ  = cols(Z)
		Z_l = select(Z,X:<c);	Z_r = select(Z,X:>=c)
	}
	
	if ("`fuzzy'"~="") {
		T   = st_data(.,("`fuzzyvar'"), 0)
		T_l = select(T,X:<c);	T_r = select(T,X:>=c)
		if (variance(T_l)==0 | variance(T_r)==0){
			T_l = T_r =0
			st_local("perf_comp","perf_comp")
		}
		if ("`sharpbw'"!=""){
			T_l = T_r =0
			st_local("sharpbw","sharpbw")
		}
	}
	
	C_l=C_r=0
	if ("`cluster'"!="") {
		C  = st_data(.,("`clustvar'"), 0)
		C_l  = select(C,X:<c); C_r  = select(C,X:>=c)
		indC_l = order(C_l,1);  indC_r = order(C_r,1) 
		g_l = rows(panelsetup(C_l[indC_l],1));	g_r = rows(panelsetup(C_r[indC_r],1))
		st_numscalar("g_l",  g_l);     st_numscalar("g_r",   g_r)
	}
	
	fw_l = fw_r = 0
	if ("`weights'"~="") {
		fw = st_data(.,("`weights'"), 0)
		fw_l = select(fw,X:<`c');	fw_r = select(fw,X:>=`c')
	}
	
	***********************************************************************
	c_bw = `C_c'*min((1,`x_iq'/1.349))*`N'^(-1/5)
	*c_bw_l = `C_c'*min((`x_sd_l',`x_iq_l'/1.349))*`N_l'^(-1/5)
	*c_bw_r = `C_c'*min((`x_sd_r',`x_iq_r'/1.349))*`N_r'^(-1/5)
	c_bw_l = c_bw_r = c_bw
	*display("Computing bandwidth selector.")
	*** Step 1: d_bw
	C_d_l = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, fw_l, c=c, o=q+1, nu=q+1, o_B=q+2, h_V=c_bw_l, h_B=`range_l', 0, "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
	C_d_r = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, fw_r, c=c, o=q+1, nu=q+1, o_B=q+2, h_V=c_bw_r, h_B=`range_r', 0, "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)
	
	*if (C_d_l[1]==. | C_d_l[2]==. | C_d_l[3]==.) C_d_l = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, c=c, o=q+1, nu=q+1, o_B=q+2, h_V=c_bw_l, h_B=`c_bw_l', 0, "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
	*if (C_d_r[1]==. | C_d_r[2]==. | C_d_r[3]==.) C_d_r = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, c=c, o=q+1, nu=q+1, o_B=q+2, h_V=c_bw_r, h_B=`c_bw_r', 0, "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)

		if (C_d_l[1]==. | C_d_l[2]==. | C_d_l[3]==.) {
				printf("{err}Invertibility problem in the computation of preliminary bandwidth below the threshold")  
		}
		if (C_d_r[1]==. | C_d_r[2]==. | C_d_r[3]==.) {
				printf("{err}Invertibility problem in the computation of preliminary bandwidth above the threshold")  
		}

		if (C_d_l[1]==0 | C_d_l[2]==0) {
				printf("{err}Not enough variability to compute the preliminary bandwidth below the threshold. Range defined by bandwidth: ")  
		}
		if (C_d_r[1]==0 | C_d_r[2]==0) {
				printf("{err}Not enough variability to compute the preliminary bandwidth above the threshold. Range defined by bandwidth: ")  
		}
		
	*** TWO
	if  ("`bwselect'"=="msetwo" |  "`bwselect'"=="certwo" | "`bwselect'"=="msecomb2" | "`bwselect'"=="cercomb2"  | "`all'"!="")  {		
		d_bw_l = (  C_d_l[1]              /   C_d_l[2]^2             )^C_d_l[4]
		d_bw_r = (  C_d_r[1]              /   C_d_r[2]^2             )^C_d_l[4]
		C_b_l  = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, fw_l, c=c, o=q, nu=p+1, o_B=q+1, h_V=c_bw_l, h_B=d_bw_l, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
		b_bw_l = (  C_b_l[1]              /   (C_b_l[2]^2 + `scaleregul'*C_b_l[3])        )^C_b_l[4]
		C_b_r  = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, fw_r, c=c, o=q, nu=p+1, o_B=q+1, h_V=c_bw_r, h_B=d_bw_r, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)
		b_bw_r = (  C_b_r[1]              /   (C_b_r[2]^2 + `scaleregul'*C_b_r[3])        )^C_b_l[4]
		C_h_l  = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, fw_l, c=c, o=p, nu=`deriv', o_B=q, h_V=c_bw_l, h_B=b_bw_l, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
		h_bw_l = (  C_h_l[1]              /   (C_h_l[2]^2 + `scaleregul'*C_h_l[3])         )^C_h_l[4]
		C_h_r  = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, fw_r, c=c, o=p, nu=`deriv', o_B=q, h_V=c_bw_r, h_B=b_bw_r, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)
		h_bw_r = (  C_h_r[1]              /   (C_h_r[2]^2 + `scaleregul'*C_h_r[3])         )^C_h_l[4]
		
		if (C_b_l[1]==0 | C_b_l[2]==0) {
				printf("{err}Not enough variability to compute the bias bandwidth (b) below the threshold. Range defined by bandwidth = %f\n", d_bw_l)  
		}
		if (C_b_r[1]==0 | C_b_r[2]==0) {
				printf("{err}Not enough variability to compute the bias bandwidth (b) above the threshold. Range defined by bandwidth = %f\n", d_bw_r)  
		}
		if (C_h_l[1]==0 | C_h_l[2]==0) {
				printf("{err}Not enough variability to compute the loc. poly. bandwidth (h) below the threshold. Range defined by bandwidth = %f\n", b_bw_l) 
		}	
		if (C_h_r[1]==0 | C_h_r[2]==0) {
				printf("{err}Not enough variability to compute the loc. poly. bandwidth (h) above the threshold. Range defined by bandwidth = %f\n", b_bw_r) 
		}

	}
	
	*** SUM
	if  ("`bwselect'"=="msesum" | "`bwselect'"=="cersum" |  "`bwselect'"=="msecomb1" | "`bwselect'"=="msecomb2" |  "`bwselect'"=="cercomb1" | "`bwselect'"=="cercomb2"  |  "`all'"!="")  {
		d_bw_s = ( (C_d_l[1] + C_d_r[1])  /  (C_d_r[2] + C_d_l[2])^2 )^C_d_l[4]
		C_b_l  = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, fw_l, c=c, o=q, nu=p+1, o_B=q+1, h_V=c_bw_l, h_B=d_bw_s, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
		C_b_r  = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, fw_r, c=c, o=q, nu=p+1, o_B=q+1, h_V=c_bw_r, h_B=d_bw_s, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)
		b_bw_s = ( (C_b_l[1] + C_b_r[1])  /  ((C_b_r[2] + C_b_l[2])^2 + `scaleregul'*(C_b_r[3]+C_b_l[3])) )^C_b_l[4]
		C_h_l  = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, fw_l, c=c, o=p, nu=`deriv', o_B=q, h_V=c_bw_l, h_B=b_bw_s, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
		C_h_r  = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, fw_r, c=c, o=p, nu=`deriv', o_B=q, h_V=c_bw_r, h_B=b_bw_s, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)
		h_bw_s = ( (C_h_l[1] + C_h_r[1])  /  ((C_h_r[2] + C_h_l[2])^2 + `scaleregul'*(C_h_r[3] + C_h_l[3])) )^C_h_l[4]
		
		if (C_b_l[1]==0 | C_b_l[2]==0) {
				printf("{err}Not enough variability to compute the bias bandwidth (b) below the threshold. Range defined by bandwidth = %f\n", d_bw_s)  
		}
		if (C_b_r[1]==0 | C_b_r[2]==0) {
				printf("{err}Not enough variability to compute the bias bandwidth (b) above the threshold. Range defined by bandwidth = %f\n", d_bw_s)  
		}
		if (C_h_l[1]==0 | C_h_l[2]==0) {
				printf("{err}Not enough variability to compute the loc. poly. bandwidth (h) below the threshold. Range defined by bandwidth = %f\n", b_bw_s) 
		}	
		if (C_h_r[1]==0 | C_h_r[2]==0) {
				printf("{err}Not enough variability to compute the loc. poly. bandwidth (h) above the threshold. Range defined by bandwidth = %f\n", b_bw_s) 
		}
		
	}
	*** RD
	if  ("`bwselect'"=="mserd" | "`bwselect'"=="cerrd" | "`bwselect'"=="msecomb1" | "`bwselect'"=="msecomb2" | "`bwselect'"=="cercomb1" | "`bwselect'"=="cercomb2" | "`bwselect'"=="" | "`all'"!="" ) {
		d_bw_d = ( (C_d_l[1] + C_d_r[1])  /  (C_d_r[2] - C_d_l[2])^2 )^C_d_l[4]
		C_b_l  = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, fw_l, c=c, o=q, nu=p+1, o_B=q+1, h_V=c_bw_l, h_B=d_bw_d, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
		C_b_r  = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, fw_r, c=c, o=q, nu=p+1, o_B=q+1, h_V=c_bw_r, h_B=d_bw_d, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)
		b_bw_d = ( (C_b_l[1] + C_b_r[1])  /  ((C_b_r[2] - C_b_l[2])^2 + `scaleregul'*(C_b_r[3] + C_b_l[3])) )^C_b_l[4]
		C_h_l  = rdrobust_bw(Y_l, X_l, T_l, Z_l, C_l, fw_l, c=c, o=p, nu=`deriv', o_B=q, h_V=c_bw_l, h_B=b_bw_d, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_l, dupsid_l)
		C_h_r  = rdrobust_bw(Y_r, X_r, T_r, Z_r, C_r, fw_r, c=c, o=p, nu=`deriv', o_B=q, h_V=c_bw_r, h_B=b_bw_d, `scaleregul', "`vce_select'", nnmatch, "`kernel'", dups_r, dupsid_r)
		h_bw_d = ( (C_h_l[1] + C_h_r[1])  /  ((C_h_r[2] - C_h_l[2])^2 + `scaleregul'*(C_h_r[3] + C_h_l[3])) )^C_h_l[4]
		
		
		if (C_b_l[1]==0 | C_b_l[2]==0) {
				printf("{err}Not enough variability to compute the bias bandwidth (b) below the threshold. Range defined by bandwidth = %f\n", d_bw_d)  
		}
		if (C_b_r[1]==0 | C_b_r[2]==0) {
				printf("{err}Not enough variability to compute the bias bandwidth (b) above the threshold. Range defined by bandwidth = %f\n", d_bw_d)  
		}
		if (C_h_l[1]==0 | C_h_l[2]==0) {
				printf("{err}Not enough variability to compute the loc. poly. bandwidth (h) below the threshold. Range defined by bandwidth = %f\n", b_bw_d) 
		}	
		if (C_h_r[1]==0 | C_h_r[2]==0) {
				 printf("{err}Not enough variability to compute the loc. poly. bandwidth (h) above the threshold. Range defined by bandwidth = %f\n", b_bw_d) 
		}
		
	}	
	
	if (C_b_l[1]==. | C_b_l[2]==. | C_b_l[3]==.) {
			printf("{err}Invertibility problem in the computation of bias bandwidth (b) below the threshold") 			
	}
	if (C_b_r[1]==. | C_b_r[2]==. | C_b_r[3]==.) {
			printf("{err}Invertibility problem in the computation of bias bandwidth (b) above the threshold")  
	}
	if (C_h_l[1]==. | C_h_l[2]==. | C_h_l[3]==.) {
			printf("{err}Invertibility problem in the computation of loc. poly. bandwidth (h) below the threshold") 
	}	
	if (C_h_r[1]==. | C_h_r[2]==. | C_h_r[3]==.) {
			printf("{err}Invertibility problem in the computation of loc. poly. bandwidth (h) above the threshold") 
	}	
	
	

	
	if  ("`bwselect'"=="mserd" | "`bwselect'"=="cerrd" | "`bwselect'"=="msecomb1" | "`bwselect'"=="msecomb2" | "`bwselect'"=="cercomb1" | "`bwselect'"=="cercomb2" | "`bwselect'"=="" | "`all'"!="" ) {
		h_mserd = `x_sd'*h_bw_d
		b_mserd = `x_sd'*b_bw_d
		st_numscalar("h_mserd", h_mserd); st_numscalar("b_mserd", b_mserd)
	}	
	if  ("`bwselect'"=="msesum" | "`bwselect'"=="cersum" |  "`bwselect'"=="msecomb1" | "`bwselect'"=="msecomb2" |  "`bwselect'"=="cercomb1" | "`bwselect'"=="cercomb2"  |  "`all'"!="")  {
		h_msesum = `x_sd'*h_bw_s
		b_msesum = `x_sd'*b_bw_s
		st_numscalar("h_msesum", h_msesum); st_numscalar("b_msesum", b_msesum)
		}
	if  ("`bwselect'"=="msetwo" |  "`bwselect'"=="certwo" | "`bwselect'"=="msecomb2" | "`bwselect'"=="cercomb2"  | "`all'"!="")  {		
		h_msetwo_l = `x_sd'*h_bw_l
		h_msetwo_r = `x_sd'*h_bw_r
		b_msetwo_l = `x_sd'*b_bw_l
		b_msetwo_r = `x_sd'*b_bw_r
		st_numscalar("h_msetwo_l", h_msetwo_l); st_numscalar("h_msetwo_r", h_msetwo_r)
		st_numscalar("b_msetwo_l", b_msetwo_l); st_numscalar("b_msetwo_r", b_msetwo_r)
		}
	if  ("`bwselect'"=="msecomb1" | "`bwselect'"=="cercomb1" | "`all'"!="" ) {
		h_msecomb1 = min((h_mserd,h_msesum))
		b_msecomb1 = min((b_mserd,b_msesum))
		st_numscalar("h_msecomb1", h_msecomb1);  st_numscalar("b_msecomb1", b_msecomb1) 
		}
	if  ("`bwselect'"=="msecomb2" | "`bwselect'"=="cercomb2" |  "`all'"!="" ) {
		h_msecomb2_l = (sort((h_mserd,h_msesum,h_msetwo_l)',1))[2]
		h_msecomb2_r = (sort((h_mserd,h_msesum,h_msetwo_r)',1))[2]
		b_msecomb2_l = (sort((b_mserd,b_msesum,b_msetwo_l)',1))[2]
		b_msecomb2_r = (sort((b_mserd,b_msesum,b_msetwo_r)',1))[2]
		st_numscalar("h_msecomb2_l", h_msecomb2_l); st_numscalar("h_msecomb2_r", h_msecomb2_r);
		st_numscalar("b_msecomb2_l", b_msecomb2_l); st_numscalar("b_msecomb2_r", b_msecomb2_r);
	}
		cer_h = `N'^(-(`p'/((3+`p')*(3+2*`p'))))
		
	if ("`cluster'"!="") {
		cer_h = (g_l+g_r)^(-(`p'/((3+`p')*(3+2*`p'))))
	}
		*cer_b = `N'^(-(`q'/((3+`q')*(3+2*`q'))))
		cer_b = 1
		
	if  ("`bwselect'"=="cerrd" | "`all'"!="" ){
		h_cerrd = h_mserd*cer_h
		b_cerrd = b_mserd*cer_b
		st_numscalar("h_cerrd", h_cerrd); st_numscalar("b_cerrd", b_cerrd)
		}
	if  ("`bwselect'"=="cersum" | "`all'"!="" ){
		h_cersum = h_msesum*cer_h
		b_cersum=  b_msesum*cer_b
		st_numscalar("h_cersum", h_cersum); st_numscalar("b_cersum", b_cersum)
		}
	if  ("`bwselect'"=="certwo" | "`all'"!="" ){
		h_certwo_l   = h_msetwo_l*cer_h
		h_certwo_r   = h_msetwo_r*cer_h
		b_certwo_l   = b_msetwo_l*cer_b
		b_certwo_r   = b_msetwo_r*cer_b
		st_numscalar("h_certwo_l", h_certwo_l); st_numscalar("h_certwo_r", h_certwo_r);
		st_numscalar("b_certwo_l", b_certwo_l); st_numscalar("b_certwo_r", b_certwo_r);
		}
	if  ("`bwselect'"=="cercomb1" | "`all'"!="" ){
		h_cercomb1 = h_msecomb1*cer_h
		b_cercomb1 = b_msecomb1*cer_b
		st_numscalar("h_cercomb1", h_cercomb1);	st_numscalar("b_cercomb1", b_cercomb1)
		}
	if  ("`bwselect'"=="cercomb2" | "`all'"!="" ){
		h_cercomb2_l = h_msecomb2_l*cer_h
		h_cercomb2_r = h_msecomb2_r*cer_h
		b_cercomb2_l = b_msecomb2_l*cer_b
		b_cercomb2_r = b_msecomb2_r*cer_b
		st_numscalar("h_cercomb2_l", h_cercomb2_l); st_numscalar("h_cercomb2_r", h_cercomb2_r);
		st_numscalar("b_cercomb2_l", b_cercomb2_l); st_numscalar("b_cercomb2_r", b_cercomb2_r);
	}

	
}

	*******************************************************************************
	disp ""
	if ("`fuzzy'"=="") {
		if ("`covs'"=="") {
			if      ("`deriv'"=="0") disp in yellow "Bandwidth estimators for sharp RD local polynomial regression." 
			else if ("`deriv'"=="1") disp in yellow "Bandwidth estimators for sharp kink RD local polynomial regression."	
			else                     disp in yellow "Bandwidth estimators for sharp RD local polynomial regression. Derivative of order " `deriv' "."	
		}
		else {
			if      ("`deriv'"=="0") disp in yellow "Bandwidth estimators for covariate-adjusted sharp RD local polynomial regression." 
			else if ("`deriv'"=="1") disp in yellow "Bandwidth estimators for covariate-adjusted sharp kink RD local polynomial regression."	
			else                     disp in yellow "Bandwidth estimators for covariate-adjusted sharp RD local polynomial regression. Derivative of order " `deriv' "."	
		}
	}
	else {
		if ("`covs'"=="") {
			if      ("`deriv'"=="0") disp in yellow "Bandwidth estimators for fuzzy RD local polynomial regression." 
			else if ("`deriv'"=="1") disp in yellow "Bandwidth estimators for fuzzy kink RD local polynomial regression."	
			else                     disp in yellow "Bandwidth estimators for fuzzy RD local polynomial regression. Derivative of order " `deriv' "."	
		}
		else {
			if      ("`deriv'"=="0") disp in yellow "Bandwidth estimators for covariate-adjusted fuzzy RD local polynomial regression." 
			else if ("`deriv'"=="1") disp in yellow "Bandwidth estimators for covariate-adjusted fuzzy kink RD local polynomial regression."	
			else                     disp in yellow "Bandwidth estimators for covariate-adjusted fuzzy RD local polynomial regression. Derivative of order " `deriv' "."	
		}
	}
	disp ""

	disp in smcl in gr "{ralign 18: Cutoff c = `c_orig'}"  _col(19) " {c |} " _col(21) in gr "Left of " in yellow "c"  _col(33) in gr "Right of " in yellow "c" _col(55) in gr "Number of obs = "  in yellow %10.0f `N_l'+`N_r'
	disp in smcl in gr "{hline 19}{c +}{hline 22}"                                                                                                              _col(55) in gr "Kernel        = "  in yellow "{ralign 10:`kernel_type'}" 
	disp in smcl in gr "{ralign 18:Number of obs}"         _col(19) " {c |} " _col(21) as result %9.0f `N_l'      _col(34) %9.0f  `N_r'                         _col(55) in gr "VCE method    = "  in yellow "{ralign 10:`vce_type'}" 
	disp in smcl in gr "{ralign 18:Min of `x'}"            _col(19) " {c |} " _col(21) as result %9.3f `x_l_min'  _col(34) %9.3f  `x_r_min'  
	disp in smcl in gr "{ralign 18:Max of `x'}"            _col(19) " {c |} " _col(21) as result %9.3f `x_l_max'  _col(34) %9.3f  `x_r_max'  
	disp in smcl in gr "{ralign 18:Order est. (p)}"        _col(19) " {c |} " _col(21) as result %9.0f `p'        _col(34) %9.0f  `p'                              
	disp in smcl in gr "{ralign 18:Order bias (q)}"        _col(19) " {c |} " _col(21) as result %9.0f `q'        _col(34) %9.0f  `q'  

	if ("`cluster'"!="") {
		disp in smcl in gr "{ralign 18:Number of clusters}" _col(19) " {c |} " _col(21) as result %9.0f g_l       _col(34) %9.0f  g_r                         
	}
				
			
	disp ""
	if ("`fuzzy'"=="") disp           "Outcome: `y'. Running variable: `x'."
	else               disp in yellow "Outcome: `y'. Running variable: `x'. Treatment Status: `fuzzyvar'."	
	disp in smcl in gr "{hline 19}{c TT}{hline 30}{c TT}{hline 29}"
	disp in smcl in gr _col(19) " {c |} "             _col(30) "BW est. (h)"    _col(50) " {c |} " _col(60) "BW bias (b)"  
	disp in smcl in gr "{ralign 18:Method}"        _col(19) " {c |} " _col(22) "Left of " in yellow "c" _col(40) in green "Right of " in yellow "c"  in green _col(50) " {c |} " _col(53)  "Left of " in yellow "c" _col(70) in green "Right of " in yellow "c" 
	disp in smcl in gr "{hline 19}{c +}{hline 30}{c +}{hline 29}" 
		
	if  ("`bwselect'"=="mserd" | "`bwselect'"=="" | "`all'"!="" ) {
		disp in smcl in gr "{ralign 18:mserd}"    _col(19) " {c |} " _col(22) as result %9.3f h_mserd  _col(41) %9.3f  h_mserd  in green _col(50) " {c |} " _col(51) as result %9.3f b_mserd  _col(71) %9.3f  b_mserd                                
	}
	if  ("`bwselect'"=="msetwo"  | "`all'"!="")  {		
		disp in smcl in gr "{ralign 18:msetwo}"   _col(19) " {c |} " _col(22) as result %9.3f h_msetwo_l _col(41) %9.3f  h_msetwo_r in green _col(50) " {c |} " _col(51) as result %9.3f b_msetwo_l           _col(71) %9.3f  b_msetwo_r                                
	}
	if  ("`bwselect'"=="msesum"  |  "`all'"!="")  {
		disp in smcl in gr "{ralign 18:msesum}"   _col(19) " {c |} " _col(22) as result %9.3f h_msesum _col(41) %9.3f  h_msesum  in green _col(50) " {c |} " _col(51) as result %9.3f b_msesum           _col(71) %9.3f  b_msesum                             
	}
	if  ("`bwselect'"=="msecomb1" | "`all'"!="" ) {
		disp in smcl in gr "{ralign 18:msecomb1}" _col(19) " {c |} " _col(22) as result %9.3f h_msecomb1 _col(41) %9.3f  h_msecomb1 in green _col(50) " {c |} " _col(51) as result %9.3f b_msecomb1           _col(71) %9.3f  b_msecomb1                                 
	}
	if  ("`bwselect'"=="msecomb2" |  "`all'"!="" ) {
		disp in smcl in gr "{ralign 18:msecomb2}" _col(19) " {c |} " _col(22) as result %9.3f h_msecomb2_l _col(41) %9.3f  h_msecomb2_r in green _col(50) " {c |} " _col(51) as result %9.3f b_msecomb2_l           _col(71) %9.3f  b_msecomb2_r                                  
	}
	if  ("`all'"!="" ) disp in smcl in gr "{hline 19}{c +}{hline 30}{c +}{hline 29}"
	if  ("`bwselect'"=="cerrd" | "`all'"!="" ){
		disp in smcl in gr "{ralign 18:cerrd}"    _col(19) " {c |} " _col(22) as result %9.3f h_cerrd _col(41) %9.3f  h_cerrd in green _col(50) " {c |} " _col(51) as result %9.3f b_cerrd           _col(71) %9.3f  b_cerrd                                
	}
	if  ("`bwselect'"=="certwo" | "`all'"!="" ){
		disp in smcl in gr "{ralign 18:certwo}"   _col(19) " {c |} " _col(22) as result %9.3f h_certwo_l _col(41) %9.3f  h_certwo_r in green _col(50) " {c |} " _col(51) as result %9.3f b_certwo_l           _col(71) %9.3f  b_certwo_r                                
	}
	if  ("`bwselect'"=="cersum" | "`all'"!="" ){
		disp in smcl in gr "{ralign 18:cersum}"   _col(19) " {c |} " _col(22) as result %9.3f h_cersum _col(41) %9.3f  h_cersum in green _col(50) " {c |} " _col(51) as result %9.3f b_cersum           _col(71) %9.3f  b_cersum                                
	}
	if  ("`bwselect'"=="cercomb1" | "`all'"!="" ){
		disp in smcl in gr "{ralign 18:cercomb1}" _col(19) " {c |} " _col(22) as result %9.3f h_cercomb1 _col(41) %9.3f  h_cercomb1 in green _col(50) " {c |} " _col(51) as result %9.3f b_cercomb1           _col(71) %9.3f  b_cercomb1                              
	}
	if  ("`bwselect'"=="cercomb2" | "`all'"!="" ){
		disp in smcl in gr "{ralign 18:cercomb2}" _col(19) " {c |} " _col(22) as result %9.3f h_cercomb2_l _col(41) %9.3f  h_cercomb2_r in green _col(50) " {c |} " _col(51) as result %9.3f b_cercomb2_l           _col(71) %9.3f  b_cercomb2_r                              
	}
	disp in smcl in gr "{hline 19}{c BT}{hline 30}{c BT}{hline 29}" 
   	if ("`covs'"!="")        disp "Covariate-adjusted estimates. Additional covariates included: `ncovs'"
	if ("`cluster'"!="")     disp "Std. Err. adjusted for clusters in " "`clustvar'"
	if ("`scaleregul'"!="1") disp "Scale regularization: " `scaleregul'
	if ("`sharpbw'"~="")   	 disp in red "WARNING: bandwidths automatically computed for sharp RD estimation."
	if ("`perf_comp'"~="")   disp in red "WARNING: bandwidths automatically computed for sharp RD estimation because perfect compliance was detected on at least one side of the threshold."

	restore
	ereturn clear
	ereturn scalar N_l = `N_l'
	ereturn scalar N_r = `N_r'
	ereturn scalar c = `c'
	ereturn scalar p = `p'
	ereturn scalar q = `q'
	ereturn local kernel = "`kernel_type'"
	ereturn local bwselect = "`bwselect'"
	ereturn local vce_select = "`vce_type'"
	if ("`covs'"!="")    ereturn local covs "`covs'"
	if ("`cluster'"!="") ereturn local clustvar "`clustvar'"
	ereturn local outcomevar "`y'"
	ereturn local runningvar "`x'"
	ereturn local depvar "`y'"
	ereturn local cmd "rdbwselect"

	if  ("`bwselect'"=="mserd" | "`bwselect'"=="" | "`all'"!="" ) {
		ereturn scalar h_mserd = h_mserd
		ereturn scalar b_mserd = b_mserd
		}
	if  ("`bwselect'"=="msesum"  |  "`all'"!="")  {
		ereturn scalar h_msesum = h_msesum
		ereturn scalar b_msesum = b_msesum
		}
	if  ("`bwselect'"=="msetwo"  | "`all'"!="")  {	
		ereturn scalar h_msetwo_l = h_msetwo_l
		ereturn scalar h_msetwo_r = h_msetwo_r
		ereturn scalar b_msetwo_l = b_msetwo_l
		ereturn scalar b_msetwo_r = b_msetwo_r
		}
	if  ("`bwselect'"=="msecomb1" | "`all'"!="" ) {
		ereturn scalar h_msecomb1 = h_msecomb1
		ereturn scalar b_msecomb1 = b_msecomb1
		}
	if  ("`bwselect'"=="msecomb2" | "`all'"!="" ) {
		ereturn scalar h_msecomb2_l = h_msecomb2_l
		ereturn scalar h_msecomb2_r = h_msecomb2_r
		ereturn scalar b_msecomb2_l = b_msecomb2_l
		ereturn scalar b_msecomb2_r = b_msecomb2_r
		}
	if  ("`bwselect'"=="cerrd" | "`all'"!="") {
		ereturn scalar h_cerrd = h_cerrd
		ereturn scalar b_cerrd = b_cerrd
		}
	if  ("`bwselect'"=="cersum" | "`all'"!="") {
		ereturn scalar h_cersum = h_cersum
		ereturn scalar b_cersum = b_cersum
		}
	if  ("`bwselect'"=="certwo" | "`all'"!="") {
		ereturn scalar h_certwo_l = h_certwo_l
		ereturn scalar h_certwo_r = h_certwo_r
		ereturn scalar b_certwo_l = b_certwo_l
		ereturn scalar b_certwo_r = b_certwo_r
		}
	if  ("`bwselect'"=="cercomb1" | "`all'"!="") {
		ereturn scalar h_cercomb1 = h_cercomb1
		ereturn scalar b_cercomb1 = b_cercomb1
		}
	if  ("`bwselect'"=="cercomb2" | "`all'"!="") {
		ereturn scalar h_cercomb2_l = h_cercomb2_l
		ereturn scalar h_cercomb2_r = h_cercomb2_r
		ereturn scalar b_cercomb2_l = b_cercomb2_l
		ereturn scalar b_cercomb2_r = b_cercomb2_r
	}
	
	mata mata clear 

end


