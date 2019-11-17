
capture program drop rsample
program define rsample

syntax anything [, Left(real -2) Right(real 2) Bins(integer 1000) Size(integer 5000) Plot(integer 1)]

if `left'>`right' {
display as error "Left-bound must be smaller than right-bound."
exit 198
}

if (`plot' !=1 & `plot' !=0) {
	display as error "Option Plot() is binary: specify 1 to view results in a histogram, 0 for no graphical view."
	exit 198
}

if _N==0 {
set obs `size'
}
global bins =  `bins'   
if  `bins'>_N {
	display as text "Bin size was automatically specified smaller than the sample size."
	global bins =  _N/5
}
global myN  = _N



display as text "pdf function is: " as result "`anything'"
display as text "left bound is: " as result `left'
display as text "right bound is: " as result `right'
display as text "bin size is:" as result $bins
display as text "sample size is:" as result _N


/*** 1. GENERATE THE x SUPPORT ***/
capture drop x
range x `left' `right'

/*** 2. GENERATE u WITH UNIFORM DISTRIBUTION ***/
capture drop u
qui gen u = runiform()
capture drop u_bins
qui gen u_bins = round(u,1/$bins)					

/*** 3. GENERATE pdf AND cdf ON SUPPORT OF x ***/
capture drop 	my_pdf_noscale
capture drop 	my_cdf_noscale
capture drop 	my_pdf
capture drop 	my_cdf

qui gen	my_pdf_noscale	= `anything'


capture drop 	sign_check
qui gen	sign_check= sum(round((1+sign(my_pdf_noscale))/2))

if (sign_check[_N]==_N) {		

	/*** 3.1. RESCALE cdf TO CONVERGE TO 1 ***/					
	qui integ 	my_pdf_noscale	x, 	gen(my_cdf_noscale)		
	qui gen		my_pdf		=	my_pdf_noscale/r(integral) 	
	qui gen		my_cdf		=	my_cdf_noscale/r(integral) 	
        display as text "The pdf integrates to " as result round(`r(integral)',0.001) as text ", this is the rescaling factor."


	/*** 3.2. DISCRETIZE cdf ON [0,1] SUPPORT  ***/
	capture drop cdf_bins
	qui gen cdf_bins=round(my_cdf,1/$bins)				


	/*** 3.3. ASSIGN VALUES OF u TO x USING THE INVERSE METHOD ***/
	capture 	drop 	my_x
	qui gen 		my_x 	=	.
	forvalues j=1(1)$myN{
		qui replace my_x = x[`j'] if cdf_bins[`j']==u_bins
		}

	/*** 3.4. PLOT HISTOGRAM  ***/
	if `plot'==1 {
		label variable my_pdf "theoretical pdf"
        	label variable my_x "values"
		qui histogram my_x, bin(100) addplot(line my_pdf x) legend(on label(1 "random sample"))
		}
	drop x  u u_bins my_pdf_noscale sign_check my_cdf_noscale my_pdf my_cdf cdf_bins
        capture drop rsample
	rename my_x rsample
	display ""
	display "Random sample has been generated into variable" as result " rsample."
	}


else {		
	display as error "Distribution function must be positive!"
        }

macro drop bins
macro drop myN

end
exit


end
exit
