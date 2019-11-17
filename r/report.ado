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
	
	/* ----     report     ---- */
	
	
	
	*create PDF report and opens it up. Also prints HTML to PDF independently
	*The export command can be used for specifying the name of the external html
	
	program define report
		version 11
		syntax [anything] [, Export(name) Printer(name) SETpath(str) ]
		

		
		********************************************************************
		*PREPARATION
		********************************************************************
		*save the printer, setpath, html, and pdf globals from Weaver.
		*this allows to print external html file, while weaving
		if "$printer" ~= "" global PR "$printer"
		if "$setpath" ~= "" global SP "$setpath"
		if "$htmldoc" ~= "" global HTML "$htmldoc"
		if "$pdfdoc" ~= "" global PDF "$pdfdoc"
		
		if "`printer'" ~= "" global printer `printer'
		
		if "`anything'" ~= "" {
				confirm file "`anything'"
				global htmldoc "`anything'"
				global pdfdoc "`anything'.pdf" 
				}	
				
		if "`export'"~="" {
				global pdfdoc `export'.pdf 
				}	
				
		/*check that printer and setpath both are used together */
       if "`printer'" == "" & "`setpath'" != "" {
                di as err `"If you specify the {bf:ptinter path}"' ///
				`" you should also use the {bf:printer(name) option }"'
                exit 198
				} 
				
				
		********************************************************************
		*CHECKING THE REQUIRED SOFTWARE
		********************************************************************
		reportcheck
		

		********************************************************************
		*DEFINING DOCUMENT FORMAT FOR WKHTMLTOPDF
		********************************************************************
		if "$format" == "landscape" {
				local add --orientation Landscape --margin-right 13mm ///
				--margin-left 6mm ///
				--margin-top 12mm ///
				--margin-bottom 6mm
				}
				
		if "$format" ~= "landscape" {
				local add ///
				--margin-right 13mm ///
				--margin-left 6mm 
				}			
				

		********************************************************************
		*EXPORTING PDF
		********************************************************************
		
		* Microsoft Windows
		if "`c(os)'"=="Windows" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						cap shell "$setpath" --no-network  --javascript ///
						"$htmldoc" -o "$pdfdoc"
						}		
						
				if "$printer" == "wkhtmltopdf" {
						shell "$setpath" ///
						--footer-center [page] --footer-font-size 10 ///
						`add' --javascript-delay 300 --enable-javascript ///
						--no-stop-slow-scripts "$htmldoc" "$pdfdoc"	
						}		
				}
				
				
		
		* Macintosh
		if "`c(os)'"=="MacOSX" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						cap shell "$setpath" --no-network  --javascript ///
						"$htmldoc" -o "$pdfdoc"	
						}		
						
				if "$printer" == "wkhtmltopdf" {
						shell "$setpath" ///
						--footer-center [page] --footer-font-size 10 ///
						`add' --javascript-delay 300 --enable-javascript ///
						--no-stop-slow-scripts "$htmldoc" "$pdfdoc"					
						}
				}
			
			
		
		* UNIX
		if "`c(os)'"=="Unix" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						cap shell "$setpath" --no-network  --javascript ///
						"$htmldoc" -o "$pdfdoc"	
						}		
						
				if "$printer" == "wkhtmltopdf" {
						shell "$setpath" ///
						--footer-center [page] --footer-font-size 10 ///
						`add' --javascript-delay 300 --enable-javascript ///
						--no-stop-slow-scripts "$htmldoc" "$pdfdoc"						
						}
				}
		
		
		
		********************************************************************
		*PRINT THE NOTIFICATION IN STATA WINDOW
		********************************************************************		
		
		*SEARCH FOR THE PDF
		cap quietly findfile "$pdfdoc"
		
		if "`r(fn)'" != "" {
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${pdfdoc}"'}}}"'
				}
		
		*IF THERE IS NO PDF, SEARCH FOR THE HTML DOCUMENT
		if "`r(fn)'" == "" {
				cap quietly findfile "$htmldoc"
				
				if "`r(fn)'" != "" {
						di as txt _newline(2)
						di as txt "| |     / /__  ____ __   _____  _____ "       
						di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
						di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
						di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
						`"{it:produced {bf:{browse `"${htmldoc}"'}} report}"'
						
						di as error `"{p}{bf:No PDF was generated. }"' ///
						`"This could be due to a problem in accessing the PDF Printer. "' ///
						`"Visit {browse "http://www.haghish.com/weaver"} for more "' ///
						`"information. Alternatively, you can print {browse `"${htmldoc}"'} "' ///
						`"to PDF from "your web browser or other software..."'
						}
				}
				
				
		
		********************************************************************
		*OPEN THE PDF DOCUMENT
		********************************************************************
		cap quietly findfile "$pdfdoc"
		
		if "`r(fn)'" != "" {
		
				if "`c(os)'"=="Windows" {
						winexec explorer "$pdfdoc"
						}
				
				if "`c(os)'"=="MacOSX" {
						shell open "$pdfdoc"
						}
				
				if "`c(os)'"=="Unix" {
						shell xdg-open "$pdfdoc"
						}	
				}
				
				
	
	
	*restore Weaver globals, if there is any
	if "$PR" ~= "" global printer "$PR"
	if "$SP" ~= "" global setpath "$SP"
	if "$PDF" ~= "" global pdfdoc "$PDF"
	if "$HTML" ~= "" global htmldoc "$HTML"
	
	macro drop PR
	macro drop SP
	macro drop PDF
	macro drop HTML
	
	end	
	
	
	
	
	
	
