
//version 1.0.0  
program vselect,rclass
version 11.1
syntax varlist [if] [in] [fweight  aweight  pweight] [,fix(varlist) BEST BACKward FORward r2adj aic aicc bic]
tempname prevest
capture estimates store `prevest'
//ensure fix and varlist don't contain same variables
local kv: word count `varlist'
local kf: word count `fix'
forvalues i=1/`kv' {
	forvalues j=1/`kf' {
		local wv: word `i' of `varlist'
		local wf: word `j' of `fix'
		capture assert `"`wv'"' != `"`wf'"'
		if(_rc != 0) {
			di as error "The Fixed variables overlap with the predictors/response."
			exit 198
		}
	}
}

if ("`best'" != "") {
	local x "backward forward c r2adj aic aicc bic"
	foreach lname of local x {
		capture assert "``lname''" == ""
		if (_rc != 0) {
			di as error ///
"Option best may not be specified with any other options"
			exit 198
		}
	}
	leaps_and_bounds `0'
	local k = rowsof(r(info))
	di ""
	di "Selected Predictors"
	di ""
	forvalues i = 1/`k' {
		if(`i' < 10) {
			di "`i'  : `r(best`i')'"
		}
		else {
			di "`i' : `r(best`i')'"
		}
		return local best`i' 	`"`r(best`i')'"'
	} 
	matrix a = r(info)
	return matrix info = a

return local fix `"`fix'"'
return local response `"`response'"'
capture estimates restore `prevest'
}
else {
	if (("`backward'" == "" & "`forward'" == "") | ///
("`backward'" != "" & "`forward'" != "")) {
		di as error ///
"Must specify exactly one of Best Subsets (best) or Stepwise (forward, backward)"
	}
	local x "`r2adj' `aic' `aicc' `bic'"
	local g: word count `x'
	capture assert `"`g'"' == "1"
	if (_rc != 0) {
		di as error ///
"May specify exactly 1 info. criteria when doing stepwise"
		exit 198
	}
	step_crit `0'
	return local predlist "`r(predlist)'"
}

end




program step_crit, rclass
version 11.1
syntax varlist [if] [in] [fweight  aweight  pweight] [,fix(varlist) BACKward FORward r2adj aic aicc bic]
qui {
if ( ("`backward'" == "" & "`forward'" == "") | ///
("`backward'" != "" & "`forward'" != "")) {
noi	di as error "must specify JUST 1 direction"
	exit 198
}

tokenize `varlist'
capture assert "`2'" != ""
if (_rc > 0) {
noi	di as error "varlist must have more than one predictor"
	exit 198
}


marksample touse
if(`"`fix'"'!= "") {
	markout `touse' `fix'
}

// count missing values 
tempvar ifindic
qui gen `ifindic' = 1 `if' `in'
qui replace `ifindic' = 0 if `ifindic' == .


qui count if `ifindic' == 1 & `touse'==0
local b = r(N)
if(`b' > 0) {
noi di as text `b' " Observations Containing Missing Predictor Values"
noi di
}

noi display  as text upper(`"`backward'`forward'"') " variable selection"
noi display  as text "Information Criteria: " upper(`"`r2adj'`aic'`aicc'`bic'"')
noi display ""


	//set depvar to be dependent variable
local depvar = "`1'"
	//and predlist to hold independent variables
local predlist: subinstr local varlist "`depvar'" "", word all
	//and npreds as an index of the number of our predictors
local npreds: word count `predlist'
tokenize predlist

qui reg `varlist' `fix' if `touse' [`weight' `exp']
//noi di e(rss)
//noi di e(df_r)
local totalmRSS = e(rss)/e(df_r)

if ("`forward'" != "") {
		//do forward elimination

		//prepredlist, hold predlist of previous iteration
	local prepredlist ""
		//list of predictors not used in previous iteration
	local prenirpredlist ""

		//no predictors initially in current
	local curpredlist ""
	local curnirpredlist "`predlist'"

		//preINFO, holds INFO of previous iteration
	local preINFO = .	
		//curINFO, holds INFO of current iteration
		//initialize curINFo with total regression
qui       reg `depvar' `fix' if `touse' [`weight' `exp']
       if ("`r2adj'" != "") {
                local curINFO = -e(r2_a)
       }
//	 else if ("`c'" != "") {
//		    local curINFO = e(rss)/`totalmRSS'-(e(N)-2*(e(df_m)+1))
//	 }
       else if ("`aic'" != "") {
                local curINFO = e(N)*ln(e(rss)/e(N)) + 2*(e(N) - e(df_r)) + (e(N) + e(N)*ln(2*_pi))
       }
       else if ("`aicc'" != "") {
                local curINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r)) + 2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1)  + (e(N) + e(N)*ln(2*_pi))
        }
       else if ("`bic'" != "") {
                local curINFO = e(N)*ln(e(rss)/e(N)) + ///
ln(e(N))*(e(N) - e(df_r))  + (e(N) + e(N)*ln(2*_pi))
       }
       else {
              noi  di as error "no information criteria specified"
                exit 198
       }
            

        local i = 0
        while (`curINFO' < `preINFO' & `i' < `npreds') {
                        //reinitialize pre s
                local preINFO = `curINFO'
                local prepredlist "`curpredlist'"
		local prenirpredlist "`curnirpredlist'"
                        //output previous iteration results to user
                noi di as text "{hline 78}"
                noi di "Stage `i' reg " subinstr(`"`depvar'"' + " " + ltrim(`"`fix'"') + " " + ltrim(`"`curpredlist'"'),"  ", " ",.) ///
 " : " upper(`"`r2adj'`aic'`aicc'`bic'"') " " %9.0g `curINFO'
		noi di as text "{hline 78}"
                local i = `i' + 1
                       //points to INFO for regression without variable at index
                        //updated as min for each new regression performed
                local minINFO = .
                local minINFOindex = ""
                        //search through curnirpredlist, doing regressions 
			//with variable at index
                        //update minINFO and minINFOindex
                foreach var of varlist `curnirpredlist' {

                        local tempcurpredlist "`curpredlist' `var'"
                        reg `depvar' `fix' `tempcurpredlist' if `touse' [`weight' `exp']

                        if ("`r2adj'" != "") {
                                local tempcurINFO = -e(r2_a)
                        }
	//			else if ("`c'" != "") {
	//				  local tempcurINFO = e(rss)/`totalmRSS'-(e(N)-2*(e(df_m)+1)) 
	//			}
                        else if ("`aic'" != "") {
                                local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r))  + (e(N) + e(N)*ln(2*_pi))
                        }
                        else if ("`aicc'" != "") {
                                local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r)) + 2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1)  + (e(N) + e(N)*ln(2*_pi))
                        }
                        else if ("`bic'" != "") {
                                local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
ln(e(N))*(e(N) - e(df_r))  + (e(N) + e(N)*ln(2*_pi))
                        }
                        if (`minINFO' > `tempcurINFO') {
                                local minINFO = `tempcurINFO'
                                local minINFOindex = "`var'"
                        }
                        //show user affect of addition
			  noi di upper(`"`r2adj'`aic'`aicc'`bic'"') " "_column(7) %-9.0g `tempcurINFO' ///
" :         add " %10s "`var'"   


               }
                        //update current to reflect search results
                local curINFO = `minINFO'
                local curpredlist "`curpredlist' `minINFOindex'" 
		local curnirpredlist: subinstr local curnirpredlist ///
"`minINFOindex'" "", word all
	}
                //output optimal results as estimates
        noi di ""
        noi di "Final Model"
noi reg `depvar' `fix' `prepredlist' if `touse' [`weight' `exp']
return local predlist `prepredlist'
}

if ("`backward'" != "") {
		//do backward elimination

		//prepredlist, hold predlist of previous iteration
	local prepredlist ""
		//all predictors initially in
	local curpredlist "`predlist'"

		//preINFO, holds INFO of previous iteration 
	local preINFO = .
		//curINFO, holds INFO of current iteration
		//initialize curINFO with total regression
	reg `varlist' `fix' if `touse' [`weight' `exp']
	if ("`r2adj'" != "") {
		local curINFO = -e(r2_a)
	}
//	else if ("`c'" != "") {
//		noi di "s^2 " `totalmRSS'
//		noi di "Penalty " (-(e(N)-2*(e(df_m)+1)))
//		noi di "RSS " e(rss)
  //  	      local curINFO = e(rss)/`totalmRSS'-(e(N)-2*(e(df_m)+1))
//	}
	else if ("`aic'" != "") {
		local curINFO = e(N)*ln(e(rss)/e(N)) + 2*(e(N) - e(df_r))  + (e(N) + e(N)*ln(2*_pi))
	}
	else if ("`aicc'" != "") {
		local curINFO = e(N)*ln(e(rss)/e(N)) + 2*(e(N) - e(df_r)) + ///
2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1)  + (e(N) + e(N)*ln(2*_pi))
	}
	else if ("`bic'" != "") {
		local curINFO = e(N)*ln(e(rss)/e(N)) + ln(e(N))*(e(N) - e(df_r)) + (e(N) + e(N)*ln(2*_pi))
	}
	else {
		di as error "no information criteria specified"
		exit 198
	}


	local i = 0

	while (`curINFO' < `preINFO' & `i' < `npreds') {
	
			//reinitialize preINFO
		local preINFO = `curINFO'
			//retinitialzie predpredlist
		local prepredlist "`curpredlist'"

			//output previous iteration results to user 
                noi di as text "{hline 78}"
		noi di "Stage `i' reg " subinstr(`"`depvar'"' + " " + ltrim(`"`fix'"') + " " + ltrim(`"`curpredlist'"'),"  ", " ",.)  ///
" : "  upper(`"`r2adj'`aic'`aicc'`bic'"') " " %9.0g `curINFO'
                noi di as text "{hline 78}"

		local i = `i' + 1

			//points to INFO for regression without variable 
			//at index
			//updated as min for each new regression performed
		local minINFO = .
		local minINFOindex = ""
			//search through curpredlist, doing regressions 
			//without variable at index
			//update minINFO and minINFOindex
		foreach var of varlist `curpredlist' {

                        local tempcurpredlist: subinstr local curpredlist ///
"`var'" "", word all
                        reg `depvar' `fix' `tempcurpredlist' if `touse' [`weight' `exp']

			if ("`r2adj'" != "") {
		        	local tempcurINFO = -e(r2_a)
			}
//			if ("`c'" != "") {
//	  		      local tempcurINFO = e(rss)/`totalmRSS'-(e(N)-2*(e(df_m)+1))
//
//			}
			else if ("`aic'" != "") {
			        local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r))  + (e(N) + e(N)*ln(2*_pi))
			}
			else if ("`aicc'" != "") {
			        local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
2*(e(N) - e(df_r)) + 2*(e(df_m)+2)*(e(df_m)+3)/(e(N)-(e(df_m) + 2) - 1) + (e(N) + e(N)*ln(2*_pi))
			}
			else if ("`bic'" != "") {
			        local tempcurINFO = e(N)*ln(e(rss)/e(N)) + ///
ln(e(N))*(e(N) - e(df_r)) + (e(N) + e(N)*ln(2*_pi))
			}
			if (`minINFO' > `tempcurINFO') {
				local minINFO = `tempcurINFO'
				local minINFOindex = "`var'"
			}
			//show user affect of removal
			  noi di upper(`"`r2adj'`aic'`aicc'`bic'"') " " _column(7) %-9.0g `tempcurINFO' ///
" :         remove " %10s "`var'"   


		}

			//update current to reflect search results
		local curINFO = `minINFO'
		local curpredlist: subinstr local curpredlist ///
"`minINFOindex'" "", word all
	}

		//output optimal results as estimates
	noi di ""
	noi di "Final Model"
noi reg `depvar' `fix' `prepredlist' if `touse' [`weight' `exp']
return local predlist `prepredlist'
}
}

end


//returns
//r(N)				scalar, number of observations in sample
//r(sample)			macro, conditional for being in sample (if , in)
//					for example, replace x = 2 `rsample'
//r(info)			matrix of information criteria 
//				(row # = predictor #)
//r(best1) ... r(bestN)		macros giving the best 1,...,N predictor models
//leaps_and_bounds.ado
program leaps_and_bounds, rclass
version 11.1
syntax varlist [if] [in] [fweight  aweight  pweight] [,fix(varlist) best]

//tempname prevest
preserve
//capture estimates store `prevest'
//noi display as text "Best Subset Variable Selection"
//noi display  as text "via Leaps & Bounds"
//noi display ""
//noi display  as text "`0'"
//noi display ""
marksample touse
if(`"`fix'"'!= "") {
	markout `touse' `fix'
}


// count missing values 
tempvar ifindic
qui gen `ifindic' = 1 `if' `in'
qui replace `ifindic' = 0 if `ifindic' == .

qui count if `ifindic' == 1 & `touse'==0
local b = r(N)
if(`b' > 0) {
	noi di as text `b' " Observations Containing Missing Predictor Values"
	noi di
}

tempvar weightvar
if(`"`weight'"' != "") {
//handle different types of weights
	if(`"`weight'"' == "fweight") {
// var(e) = sigma^2 * W^-1
// ith observation is average of ni equally variable observations
// so weight should be ni
		qui gen `weightvar' `exp'		
	}
	if(`"`weight'"' == "aweight" | `"`weight'"' == "pweight") {
// make sum to `n'
		qui gen `weightvar' `exp'	
		qui sum `weightvar'
		qui replace `weightvar' = r(N)*`weightvar'/(r(N)*r(mean))
	}
}
else {
qui 	gen `weightvar' = 1
}
qui keep if `touse' 
qui keep `varlist' `fix' `weightvar'

return scalar N = _N

//compressing things down for a moment
//don't want to mess up our earlier preserve
tempfile zefile
qui save `zefile', replace

local n : word count `varlist'
//not counting the response or fixed
local n = `n' - 1
tokenize `varlist'
local response "`1'"

//order predictors by influence on regression sum of squares
//1 is most influential
//2 second
//etc.

qui reg `varlist' `fix' 
local x: word count "`varlist'"

if (e(df_m) < `x') {
	di as error "design matrix not full rank"
	exit 198
}

forvalues i = 1/`n' {
	local j = `i' + 1
	qui test ``j'' = 0
	local var_`i'  "``j''" 
	local zef_`i' = -r(F) 
}
clear
qui set obs `n'
qui gen var = ""
qui gen zef = .
forvalues i = 1/`n' {
	qui replace var = "`var_`i''" if _n == `i'
	qui replace zef = `zef_`i'' if _n == `i'
}
sort zef
local ordlist = ""
forvalues i = 1/`n' {
	local a = var[`i']
	local ordlist "`ordlist' `a'" 
}
qui use `zefile', clear
//order `response' `ordlist'

local varlist "`response' `ordlist'"
local predlist "`ordlist'"


//  why? //variables are now properly ordered

noi di `"Response :             `response'"' 
noi di `"Fixed Predictors :     `fix'"'
noi di `"Selected Predictors:  `ordlist'"'
//tokenize "`ordlist'"

noi mata: leaps_bounds("`response'","`fix'","`ordlist'","`weightvar'")
//capture estimates restore `prevest'
restore
end



mata:
struct node {
		//first subset of predictors
        rowvector p1
		//second subset of predictors
        rowvector p2
		//points to child nodes - 
		//ith child has i-1 children
                //rules for getting predictors in children from previous work
                //first child of parent
                //      subset 1 = parent's subset 2 - last predictor
                //      subset 2 = parent's subset 2 - second to last predictor
		//nth child of parent
		//      subset 1 = (n-1)th child's subset 1 - last predictor
		//      subset 2 = parent's subset 2 - (n+1) to last predictor
        pointer (struct node scalar) rowvector children
		//point to parent node
        pointer (struct node scalar) scalar parent
                //rss of subset 1 regression
        real scalar p1rss
    		//X'X inverse for subset 1 regression
        real matrix p1i
                //rss of subset 2 regression
        real scalar p2rss
        	//X'X inverse for subset 2 regression
        real matrix p2i
}

//returns a permutation matrix that will shift ith row/column to end
real matrix pm(real scalar i, real scalar n) {
	if(i != n) {
		Y = ((I(i-1),J(i-1,n-(i-1),0)) \ (J(1,n-1,0),1))
		Y = (Y \ (I(n-1)[i::(n-1),1::(n-1)],J(n-i,1,0)))
		return(Y)
	}
	else {
		return(I(n))
	}
}

void leaps_bounds(string scalar response, string scalar fixlist,string scalar ordlist, string scalar weightvar) {

w = st_data(.,weightvar)
//wi = w:^(-1)

   /*
	//response
	Y = st_data(.,response)
	//fixed + predictors
	X = st_data(.,fixlist + " " + ordlist)
	w = st_data(.,weightvar)
	//put intercept constant on the left
	X = (J(rows(X),1,1),X[.,(2::cols(X))])		

	//initialize root
	struct node scalar root
	root.p2 = (1..(cols(X)-1))
	D = (Y,X)

	n = rows(X)
	tf = stringtoreal(fixcount)
	tk = stringtoreal(predcount)
	// Y n x 1
	// X n x (1+tf+tk)		f fixed, k predictors
	// w n x 1
	// (Y X)   n x (2+tf+tk)
	//cm = (Y,X)'*(W-1/2)(Y,X)
	//cm = cross(D,D)
	cm = cross(D
*/
/*
        real matrix cross(X, Z)
        real matrix cross(X, w, Z)
        real matrix cross(X, xc, Z, zc)
        real matrix cross(X, xc, w, Z, zc)
    where
                     X:  real matrix X
                    xc:  real scalar xc
                     w:  real vector w
                     Z:  real matrix Z
//                    zc:  real scalar zc
//Description
//    cross() makes calculations of the form
//                X'X 
//                X'Z 
//                X'diag(w)X
*/
n = rows(w)
tfixlist= tokens(fixlist)
tf = cols(tfixlist)
//printf("Fixed List" + fixlist+"\n")
//printf("Ordered List" + ordlist+"\n")
//printf("ordered list of predictors")
//printf(ordlist)
//slx = strlen(ordlist)
//printf("String Length of ordered list of predictors %9.0g",slx)
tordlist= tokens(ordlist)
tk = cols(tordlist)
//printf("tk %9.0g",tk)
//intercCol = J(n,1,1)
intercCol = st_addvar("byte", st_tempname())
st_store(.,intercCol,J(n,1,1))
if (tf > 0) {
D = st_data(.,(st_varindex(response), intercCol, st_varindex(tfixlist),st_varindex(tordlist))) 
}
else {
D = st_data(.,(st_varindex(response), intercCol, st_varindex(tordlist))) 
}
//cross matrix
// var = sigma^2 * W^-1
cm = cross(D,w,D)

	//best model matrix
	Best = J(tk,tk,.)
	//minRSS colvector
	minRSS = J(tk,1,.)
	minRSS_lag = J(tk,1,.)
	fixXtXn1 = invsym(cross(D[.,2..(2+tf)],w,D[.,2..(tf+2)]))
	fixBeta = fixXtXn1* cross(D[.,2..(tf+2)],w,D[.,1])
	constRSS = cross((D[.,1]-cross(D[.,2..(tf+2)]',fixBeta)),w,(D[.,1]-cross(D[.,2..(tf+2)]',fixBeta)))
	fiINTtINT1 = invsym(cross(D[.,2],w,D[.,2]))
//printf("cols %9.0g",cols(intBeta))
//printf("rows %9.0g",rows(intBeta))


//	intBeta = J(1,1,fiINTtINT1*cross(D[.,2],w,D[.,1]))
	intBeta =fiINTtINT1*cross(D[.,2],w,D[.,1])

//printf("cols %9.0g",cols(intBeta))
//printf("rows %9.0g",rows(intBeta))

	constRSSnofixed = cross((D[.,1]-cross(D[.,2]',intBeta)),w,(D[.,1]-cross(D[.,2]',intBeta)))
//	printf("Constant RSS (with Fixed) %9.0g\n",constRSS)
//	printf("SST no weight%9.0g\n",crossdev(D[1::n,1],mean(D[1::n,1]),D[1::n,1],mean(D[1::n,1])))
//	printf("SST weight%9.0g\n",crossdev(D[1::n,1],mean(D[1::n,1],w),D[1::n,1],mean(D[1::n,1],w)))
	
run = 0

	//start through the tree
	struct node scalar root
	root.p2 = (1..tk)
	traverse(&root,&Best,&minRSS,&cm,.,constRSS,0,0,&run,&minRSS_lag,tf,tk)
	
	stata("di")
	stata("di as text" + char(34) +  "Actual Regressions   " + ///
	char(34) + " as result  " +  strofreal(run))
	stata("di as text" + char(34) +  "Possible Regressions " + ///
	char(34) + " as result  " +  strofreal(2^rows(minRSS)))

	//models are ready now.
	stata("tokenize " + ordlist)

	// build model specification macros
	for(i=1;i<=cols(Best);i++) {
		for(j=1;j<=cols(Best);j++) {
			if (Best[i,j] != 0) {
	st_local("best" + strofreal(i), st_local("best" + strofreal(i)) ///
+ " " + st_local(strofreal(Best[i,j])))
			}
		}
	}


	
	//record information criteria 
	RSS = st_addvar("double",st_tempname())
	st_store((1::cols(Best)),RSS,minRSS)
	R2ADJ = st_addvar("double",st_tempname())
	temp = (1::rows(minRSS)):+tf
//printf("%9.0g",tf)
//	printf("%9.0g\n",rows(Y))
//	printf("%9.0g",n)
	temp = (-temp) :+ n :- 1
	temp = (temp :^ -1) :* (n - 1)
//	temp = (minRSS/constRSS) :* temp
// 	fixed predictors shouldn't be used in constRSS for R2adj calculation
	temp = (minRSS/constRSSnofixed):* temp
	temp = -temp :+ 1
	mataR2ADJ = temp
	st_store((1::cols(Best)),R2ADJ,temp)
	C = st_addvar("double",st_tempname())
	temp = (1::rows(minRSS)):+tf
//	s2 = (minRSS[rows(minRSS),1]/(n-rows(minRSS)-1))
s2 = (minRSS[rows(minRSS),1]/(n-rows(minRSS)-tf-1))
//	s2 = constRSS/(n-rows(minRSS)-1)
	temp2 = temp :+ 1
	temp2 = temp2 :* 2
	temp2 = temp2 :- n
	temp3 = (minRSS:/s2) 
	temp = temp2 :+ temp3
	mataC = temp
	st_store((1::cols(Best)),C,temp)
	AIC = st_addvar("double",st_tempname())
	temp = (1::rows(minRSS)) :+tf
	temp = (-temp) :+ n :- 1
	temp = n*ln(minRSS :/ n) + (((-temp) :+ n) :*2)   :+ (n + n*ln(2*pi()))
	st_store((1::cols(Best)),AIC,temp)
	mataAIC = temp
	AICC = st_addvar("double",st_tempname())
	temp2 = (1::rows(minRSS)) :+tf
	temp2 = ((temp2 :+ 2) :* (temp2 :+ 3) :* 2) :/ ///
	(((temp2 :+ 2) :* -1) :+ n :- 1)
	temp = temp  :+  temp2 :+ (n + n*ln(2*pi()))
	st_store((1::cols(Best)),AICC,temp)
	mataAICC = temp
	BIC = st_addvar("double",st_tempname())
	temp = (1::rows(minRSS)) :+ tf
	temp = (-temp) :+ n :- 1
	temp = n*ln(minRSS :/ n) + ln(n)*((-temp) :+ n) :+ (n + n*ln(2*pi()))
	st_store((1::cols(Best)),BIC,temp)
	mataBIC = temp

	vnRSS  = st_varname(RSS)
	stata("char " + vnRSS + "[varname] RSS")
	vnR2ADJ  = st_varname(R2ADJ)
	stata("char " + vnR2ADJ + "[varname] R2ADJ")
	vnC = st_varname(C)
	stata("char " + vnC + "[varname] C")
	vnAIC  = st_varname(AIC)
	stata("char " + vnAIC + "[varname] AIC")
	vnAICC  = st_varname(AICC)
	stata("char " + vnAICC + "[varname] AICC")
	vnBIC  = st_varname(BIC)
	stata("char " + vnBIC + "[varname] BIC")
	stata("format  "+  vnRSS + "-" + vnBIC + " %9.0g")

/*
	osort = st_addvar("long",st_tempname())
	st_store((1::rows(minRSS)),osort,(1::rows(minRSS)))
	vnosort = st_varname(osort)	
	stata("format  "+ vnosort + " %9.0g")
stata("l " + vnosort)
	negR2adj = st_addvar("double",st_tempname())
	st_store((1::rows(minRSS)),negR2adj,(1::rows(minRSS)))
	vnnegR2adj = st_varname(negR2adj)	
	
	stata("qui replace " +vnnegR2adj + "=-" + vnR2ADJ)
	stata("sort " + vnnegR2adj)
	stata("local tvR2ADJ = " + vnosort + "[1]")
	stata(`"di bib `tvR2ADJ'"')
	stata(`"local tvR2ADJ `"`tvR2ADJ' "' "')
	printf(`"local tvR2ADJ `"`tvR2ADJ' "' "')
	stata("sort " + vnC)
	stata("local tvC = " + vnosort + "[1]")
	stata(`"local tvC `"`tvC' "' "')
	stata("sort " + vnAIC)
	stata("local tvAIC = " + vnosort + "[1]")
	stata(`"local tvAIC `"`tvAIC' "' "')
	stata("sort " + vnAICC)
	stata("local tvAICC = " + vnosort + "[1]")
	stata(`"local tvAICC `"`tvAICC' "' "')
	stata("sort " + vnBIC)
	stata("local tvBIC = " + vnosort + "[1]")
	stata(`"local tvBIC `"`tvBIC' "' "')
	stata("sort " + vnosort)

	mataminR2ADJ = strtoreal(st_local(tvR2ADJ))
	mataminC = strtoreal(st_local(tvC))
	mataminAIC = strtoreal(st_local(tvAIC))
	mataminAICC = strtoreal(st_local(tvAICC))
	mataminBIC = strtoreal(st_local(tvBIC))
*/

w=0
i=0
maxindex(mataR2ADJ,1,matamaxR2ADJ,w)
minindex(mataC,1,mataminC,w)
minindex(mataAIC,1,mataminAIC,w)
minindex(mataAICC,1,mataminAICC,w)
minindex(mataBIC,1,mataminBIC,w)


	printf("\n Optimal Models Highlighted: \n\n")
	printf("   # Preds")
	printf("     R2ADJ")
	printf("         C")
	printf("       AIC")
	printf("      AICC")
	printf("       BIC\n")
	for(i=1; i <=cols(Best);i++) {
		//predictor size
		printf(" {result}%9.0g",i)
		if(matamaxR2ADJ==i) {
			printf(" {result}%9.0g",mataR2ADJ[i,1])
		}
		else {
			printf(" {text}%9.0g",mataR2ADJ[i,1])
		}	 		
		
		printf(" {text}%9.0g",mataC[i,1])

		if(mataminAIC==i) {
			printf(" {result}%9.0g",mataAIC[i,1])
		}
		else {
			printf(" {text}%9.0g",mataAIC[i,1])
		}	 		
		if(mataminAICC==i) {
			printf(" {result}%9.0g",mataAICC[i,1])
		}
		else {
			printf(" {text}%9.0g",mataAICC[i,1])
		}	 		
		if(mataminBIC==i) {
			printf(" {result}%9.0g",mataBIC[i,1])
		}
		else {
			printf(" {text}%9.0g",mataBIC[i,1])
		}	 		
		printf("\n")
	}		
	printf("\n")


//	stata(`"di "  # Preds""')   


//  R2ADJ         C       AIC      AICC       BIC""')
//for(i=1; i<=cols(Best);i++) {
//	stata(`"local a """')
//	stata(`"local a "`a' "' + vnosort + `"[1]"')
//	stata(`"if(`tvR2ADJ'=="' +strofreal(i)+`") local a \"`a' as text "' + vnR2ADJ + `"["' + strofreal(i)+ `"]"')
//	stata(`"if(`tvR2ADJ'!="' +strofreal(i)+`") local a \"`a' "' + vnR2ADJ + `"["' + strofreal(i)+ `"]"')
//}




//"123456789"

//            RSS      R2ADJ          C         AIC        AICC         BIC  
//  1.   .3544757   .8441085   3.949689     -29.397     -25.397   -28.79183  
//  2.    .282222   .8581535   3.921619   -29.67646   -21.67646   -28.76871  
//  3.   .1991799   .8832061    3.59073   -31.16132   -16.16132   -29.95098  
//  4.     .16682   .8826173   4.682428   -30.93425   -2.934251   -29.42133  
//  5.   .1425073   .8746562          6   -30.50947    25.49053   -28.69396  

//	printf("Full Model Information: \n\n")

//	printf("Fit/Information Criteria Values \n")


//	stata("l " + vnRSS + "-" + vnBIC +  " in 1/" + ///
//	strofreal(rows(minRSS)) + " , subvarname clean")

	for(i=1; i <= cols(Best);i++) {
		stata("return local best" + strofreal(i) + " " + char(34) + ///
	"`" + "best" + strofreal(i) + "'" + char(34) )
	}

	baba = st_tempname()
stata("mkmat " +  vnRSS + "-" + vnBIC + " in 1/" + strofreal(rows(minRSS)) + ///
",matrix(" + baba + ")")
stata("matrix colnames " + baba + "= RSS R2ADJ C AIC AICC BIC")
stata("return matrix info =" + baba)

}

//sn points current node,  we create nodes as we visit them in algorithm
//ONLY predictors of first and second subsets are initialized by parent traversal
//Best points to Best predictor list matrix (preds in row, padded with zeroes)
//minRSS points to the minimum RSS for predictor lists of size 1-p
//cm points to the correlation matrix of predictors and response 
//(including intercept)
	//cm = (Y,X)'*(Y,X)
//cn is the child index of current node
//constRSS is the RSS for the regression on the intercept and fixed
//depth is the node depth
//forward = 0 indicates tree is being initialized with the root or first level.
//run is the iteration number of the tree search/generation algorithm
//minRSSlag is the minRSS from the previous iteration
//tf number of fixed predictors
//	intercept is to the right of this
//tk number of predictors select on
void traverse(pointer(struct node scalar) scalar sn, ///
pointer(real matrix) scalar Best, ///
pointer(real colvector) scalar minRSS, pointer(real matrix) scalar cm, ///
real scalar cn, real scalar constRSS, real scalar depth, ///
real scalar forward, pointer (real scalar) scalar run, ///
pointer (real colvector) scalar minRSS_lag, real scalar tf, real scalar tk) {
// 1.  Create node *sn and its information

if(cn == .) {
//printf("Root")
	//Root

	//root node
	//subset 1 is empty
	(*sn).p1 = J(1,0,.)
	//subset 2 is all predictors
	(*sn).p1rss = constRSS
	//X'X inverse, remember first row & column have response in them	
	//and then intercept and fixed predictors

	(*sn).p2i = invsym((*cm)[(2::cols(*cm)),(2::cols(*cm))])
	(*sn).p2rss = (*cm)[1,1] - ///
	((*cm)[(2::cols(*cm)),1])'*((*sn).p2i)*((*cm)[(2::cols(*cm)),1])
	(*sn).p2 = (1..rows(*minRSS))
}
else {
	//Child Node

	//Do first subset 

                //ith child has i-1 children
                //rules for getting predictors in children from previous work
                //first child of parent
                //      subset 1 = parent's subset 2 - last predictor
                //      subset 2 = parent's subset 2 - second to last predictor
                //nth child of parent
                //      subset 1 = (n-1)th child's subset 1 - last predictor
                //      subset 2 = parent's subset 2 - (n+1) to last predictor


		//child node, predictor list already filled out
		//compute first subset's RSS and inverse
	if (cn == 1) {
		//first child
		//first subset predictors are from Parent second subset 
			//by removing last predictor
		//so inverse is taken by corr. 2.2 LBOT
		X = (*((*sn).parent)).p2i
//printf("Rows %9.0g\n",rows(X))
//printf("Cols %9.0g\n",cols(X))
		xn = cols(X)				
		(*sn).p1i = X[1::(xn-1),1::(xn-1)] - ///
X[1::(xn-1),xn]*X[xn,1::(xn-1)]/X[xn,xn]
		//and RSS is y'Wy - etc.  (remember that y,intercept start the matrix)
			//so adding two will make indices correspond correctly

//printf("%9.0g\n",cols(((2::(tf+2)),((*sn).p1 :+ (tf+2)))))
//printf("%9.0g\n",rows(((2::(tf+2)),((*sn).p1 :+ (tf+2)))))

//printf("Rows %9.0g\n",rows((*cm)[((2::(tf+2)),((*sn).p1 :+ (tf+2))),1]'))
//printf("Cols %9.0g\n",cols((*cm)[((2::(tf+2)),((*sn).p1 :+ (tf+2))),1]'))
//printf("Rows p1 inverse %9.0g\n",rows((*sn).p1i))
		(*sn).p1rss = (*cm)[1,1] - ///
(*cm)[((2..(tf+2)),((*sn).p1 :+ (tf+2))),1]' * ((*sn).p1i) * (*cm)[((2..(tf+2)),((*sn).p1 :+ (tf+2))),1]
	}
	else {
		//not first child
		//first subset predictors are from Parent second subset
			//by dropping the last (child # - 1) predictors
		//so inverse is direct application of corr. 2.2 LBOT
		X =(*((*sn).parent)).p2i
 		(*sn).p1i = 	X[1::(cols(X)-cn),1::(cols(X)-cn)] - ///
X[(1::(cols(X)-cn)),((cols(X)-cn+1)::cols(X))]* ///
invsym(X[((cols(X)-cn+1)::cols(X)),((cols(X)-cn+1)::cols(X))])* ///
X[((cols(X)-cn+1)::cols(X)),(1::(cols(X)-cn))]
		//and RSS is y'Wy - etc.  (remember that y,intercept and fixed start the matrix)
			//so adding two will make indices correspond correctly
		(*sn).p1rss = (*cm)[1,1] - ///
(*cm)[((2..(tf+2)),(*sn).p1 :+ (tf+2)),1]' * (*sn).p1i * (*cm)[((2..(tf+2)),(*sn).p1 :+ (tf+2)),1]
	}

	//Do second subset

	//check second subset
		//compute second subset's RSS and inverse 
	X = (*((*sn).parent)).p2i
	x = cols(X)
	Z = pm(x-cn,x)' * X * pm(x-cn,x)
	(*sn).p2i = Z[(1::(x-1)),(1::(x-1))] - ///
Z[(1::(x-1)),x]*Z[(1::(x-1)),x]'/Z[x,x]
	(*sn).p2rss = (*cm)[1,1] -  ///
(*cm)[((2..(tf+2)),(*sn).p2 :+ (tf+2)),1]' * (*sn).p2i * (*cm)[((2..(tf+2)),(*sn).p2 :+ (tf+2)),1]
}

colsp1= cols((*sn).p1)
//so first and second subset rss's are initialized
//update minRSS and Best
if (colsp1 > 0) {
if ((*minRSS)[cols((*sn).p1),1] > (*sn).p1rss) {
	(*minRSS)[cols((*sn).p1),1] = (*sn).p1rss
	(*Best)[cols((*sn).p1),1::(cols(*Best))] = ((*sn).p1,J(1,rows(*Best)-cols((*sn).p1),0))
}
//(*run) = (*run) + 1
}




//printf("%9.0g",(*minRSS)[cols((*sn).p2),1])
if ((*minRSS)[cols((*sn).p2),1] > (*sn).p2rss) {
        (*minRSS)[cols((*sn).p2),1] = (*sn).p2rss
        (*Best)[cols((*sn).p2),1..(cols(*Best))] = ((*sn).p2,J(1,rows(*Best)-cols((*sn).p2),0))
}
(*run) = (*run) + 1

//2.  
//create children of *sn
                //points to child nodes -
                //ith child has i-1 children
                //rules for getting predictors in children from previous work
                //first child of parent
                //      subset 1 = parent's subset 2 - last predictor
                //      subset 2 = parent's subset 2 - second to last predictor
                //nth child of parent
                //      subset 1 = (n-1)th child's subset 1 - last predictor
                //      subset 2 = parent's subset 2 - (n+1) to last predictor

struct node children
if(cn == .) {
children = node(1,cols((*sn).p2)-1)
(*sn).children = J(1,cols((*sn).p2)-1,NULL)
}
else if(cn > 1) {
	children  = node(1,cn-1)
	(*sn).children = J(1,cn-1,NULL)
}
if(cn != 1) {
		//we have children
		//first child predictor sets
	children[1,1].p1 = (*sn).p2[,(1::(cols((*sn).p2)-1))]
	if (cols((*sn).p2) > 2) {
		children[1,1].p2 = ///
(*sn).p2[,((1..(cols((*sn).p2)-2)),cols((*sn).p2))]
	}
	else	{
		children[1,1].p2 = (*sn).p2[,cols((*sn).p2)]
	}
		//and parent
	children[1,1].parent = sn
	((*sn).children)[1,1] = &(children[1,1])
		//remaining child predictor sets, and parent
	for(i=2;i<=cols(children)-1;i++) {
		children[1,i].p1 = ///
(children[1,i-1]).p1[,(1::(cols(children[1,i-1].p1)-1))]
		children[1,i].p2 = ///
(*sn).p2[,((1..(cols((*sn).p2)-(i+1))), ///
((cols((*sn).p2)-(i-1))..(cols((*sn).p2))))]
		children[1,i].parent = sn
	      ((*sn).children)[1,i] = &(children[1,i])
	}
	if (cols(children) > 1) {
		i = cols(children)
                children[1,i].p1 = ///
(children[1,i-1]).p1[,(1::(cols(children[1,i-1].p1)-1))]
		if(cols(children) == cols((*sn).p2)-1) {
			children[1,i].p2 = (*sn).p2[,(2::(cols((*sn).p2)))]
		}
		else {
	             children[1,i].p2 = ///
(*sn).p2[,((1..(cols((*sn).p2)-(i+1))), ///
((cols((*sn).p2)-(i-1))..(cols((*sn).p2))))]
		}
		children[1,i].parent = sn 
	        ((*sn).children)[1,i] = &(children[1,i])
	}
}

//things are setup, move to next stage


if(cn==.) {
// we are at root node, evaluate all child nodes
              for(i=1; i <= cols((*sn).children); i++) {
               traverse((*sn).children[1,i],Best,minRSS,cm,i,constRSS, ///
depth+1,forward,run,minRSS_lag,tf,tk)
              }
}
else {
	if (cols((*sn).children) > 0) { 	// we have children
	x = max((1, cols((*sn).p1)))
	if ( (*minRSS)[x,1] > (*sn).p2rss) {
		//we need to examine some of the descendants of the node
		//find the maximal k so that we can skip first k children 
		//of the node
		ktoplim = cols((*sn).p2)-cols((*sn).p1) - 1
		maxk = 0
		for(k = 1; k <= ktoplim-1; k++) {
			if (k > maxk & (*minRSS)[cols((*sn).p2)-k,1] != . ///
& (*minRSS)[cols((*sn).p2)-k,1] <= (*sn).p2rss  & ///
(*minRSS)[cols((*sn).p2)-k-1,1] != . & (*sn).p2rss < ///
(*minRSS)[cols((*sn).p2)-k-1,1]) {
				maxk = k
			}
		}
	        //handle k + 1 = cols((*sn).p2) case
            if (ktoplim > maxk & (*minRSS)[cols((*sn).p2)-ktoplim,1]  != . ///
& (*minRSS)[cols((*sn).p2)-ktoplim,1] <= (*sn).p2rss ///
			& (*sn).p2rss < constRSS) {
	                maxk = ktoplim
		}
		//we can skip the first maxk children of the node
		for (i=maxk+1; i <= cols((*sn).children); i++) {
			traverse((*sn).children[1,i],Best,minRSS,cm,i, ///
constRSS,depth+1,forward,run,minRSS_lag,tf,tk)
		}
	}
	//kill all pointers in children
	for (i=1; i <=cols((*sn).children);i++) {
		(*((*sn).children[1,i])).parent = NULL
        	((*sn).children)[1,i] = NULL
	}
}
}
}
end




