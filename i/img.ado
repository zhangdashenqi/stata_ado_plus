/*******************************************************************************

							  Stata Weaver Package
					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de

		
                  The Weaver Package comes with no warranty    	
				  
				  
	Weaver version 1.0  August, 2014
	Weaver version 1.1  August, 2014
	Weaver version 1.2  August, 2014
	Weaver version 1.3  September, 2014 
	Weaver version 1.4  October, 2014 
*******************************************************************************/
	
	/* ----     img     ---- */
		
	* importing graphs and images into the report.
	program define img
        version 11
        syntax anything, [Width(numlist max=1 >0 <=1000)] ///
		[Height(numlist max=1 int >0 <=1000)] [left|center|right]
		
		if "$weaver" != "" {
		
				cap confirm file `"$weaver"'
		
				tempname canvas
				file open `canvas' using `"$weaver"', write text append
		

				if "$format" == "normal" & missing("`width'") {
						local width 694
						}
		
				if "$format" == "normal" & missing("`height'") {
						local height 494
						}
		
				if "$format" == "landscape" & missing("`width'") {
						local width 1020
						}
		
				if "$format" == "landscape" & missing("`height'") {
						local height 694
						}
		
		
				if 	"$format" == "normal" & `width' > 694 {
						display as error "image width cannot be more than 694 " ///
						"pixles, unless you choose the {help landscape} option " ///
						"from the {help weave} command"
						exit 198
						}
				
				if 	"$format" == "normal" & `height' > 1000 {
						display as error "image height cannot be more than 1000 pixles"
						exit 198
						}
				
				if 	"$format" == "landscape" & `width' > 1020 {
						display as error "image width cannot be more than 1000 pixles"
						exit 198
						}
				
				if 	"$format" == "landscape" & `height' > 694 {
						display as error "image height cannot be more than 694 " ///
						"pixles, unless you {bf:remove} the {help landscape} " ///
						"option from the {help weave} command"
						exit 198
						}			
		

				*check that only one of the align options is selected
				if "`left'" == "left" & "`center'" == "center" | ///
				"`left'" == "left" & "`right'" == "right" | ///
				"`center'" == "center" & "`right'" == "right" {
		
						di as err `"only one of the {bf:left}, "' ///
						`"{bf:center}, or {bf:right} can be applied"'
						exit 198
						}
		
				*defining the default image alignment
				if missing("`left'") & missing("`center'") & missing("`right'") {
						local left left
						}
		
				if "`left'" == "left" {
						file write `canvas' `"<img rel="zoom"  src="`anything'" "' ///
						`"width="`width'" height="`height'" >"' _newline 
						}
   
				if "`center'" == "center" {
						file write `canvas' `"<img rel="zoom"  src="`anything'" "' ///
						`"class="center"   width="`width'" height="`height'" >"' _newline 
						}
		
				if "`right'" == "right" {
						file write `canvas' `"<img rel="zoom"  src="`anything'" "' ///
						`"align="`right'"  width="`width'" height="`height'" >"' _newline 
						}
				
				}
		
		
		
		
		/* FOR KETCHUP PACKAGE */
		if "$weaver" == "" {
				
				if missing("`width'") {
						local width 694
						}
		
				if missing("`height'") {
						local height 494
						}
				
				if 	`width' > 694 {
						display as error "image width cannot be more than 694 pixles"
						exit 198
						}
				
				if 	`height' > 1000 {
						display as error "image height cannot be more than 1000 pixles"
						exit 198
						}
						
				
				*check that only one of the align options is selected
				if "`left'" == "left" & "`center'" == "center" | ///
				"`left'" == "left" & "`right'" == "right" | ///
				"`center'" == "center" & "`right'" == "right" {
						
						di as err `"only one of the {bf:left}, "' ///
						`"{bf:center}, or {bf:right} can be applied"'
						exit 198
						}
				
				*defining the default image alignment
				if missing("`left'") & missing("`center'") & missing("`right'") {
						local left left
						}
		
				if "`left'" == "left" {
						noisily display as text `"><img rel="zoom"  src="`anything'" "' ///
						`"width="`width'" height="`height'" >"' _newline 
						}
   
				if "`center'" == "center" {
						noisily display `"><img rel="zoom"  src="`anything'" "' ///
						`"class="center"   width="`width'" height="`height'" >"' _newline 
						}
		
				if "`right'" == "right" {
						noisily display `"><img rel="zoom"  src="`anything'" "' ///
						`"align="`right'"  width="`width'" height="`height'" >"' _newline 
						}
					
				} 
		
	end
	
