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

	/* ----     weavend    ---- */

	program define weavend
        version 11
		
		/* checking that the Weaver is currently weaving a canvas */
        if "$weaver" == "" {
                di as err "Oops! You can't close the Weaver because you " ///
				"haven't been weaving anything! Begin weaving by using " ///
				"{stata weave} command. See {help weaver} package for help."
                exit 111
				}
		
        
		else { 
			cap confirm file `"$weaver"'
                
			if _rc == 0 {
				tempname canvas         
                file open `canvas' using `"$weaver"', write text append 
 
		

		file write `canvas' _newline(2) "<!-- Markdown Syntax  -->" _newline(2) ///
"<script>" _newline ///
		_newline ///
		_skip(4) "(function() {" _newline ///
		_skip(4) "document.body.innerHTML = document.body.innerHTML" _newline ///
				_skip(8) ".replace(/<results><\/results>/g, '')" _newline ///
				_skip(8) ".replace(/<\/result><result>/g, '')" _newline ///
				/// defining the H1, H2, H3, H4 symbols
				_skip(8) ".replace(/\*----/g, '<h4>')" _newline ///
				_skip(8) ".replace(/----\*/g, '</h4><p>')" _newline ///
				_skip(8) ".replace(/\*---/g, '<h3>')" _newline ///
				_skip(8) ".replace(/---\*/g, '</h3><p>')" _newline ///
				_skip(8) ".replace(/\*--/g, '<h2>')" _newline ///
				_skip(8) ".replace(/--\*/g, '</h2><p>')" _newline ///
				_skip(8) ".replace(/\*-/g, '<h1>')" _newline ///
				_skip(8) ".replace(/-\*/g, '</h1><p>')" _newline ///
				/// break and pagebreak
				_skip(8) ".replace(/page-break/g, '<div class="`"""'"pagebreak"`"""'" ></div>')" _newline ///
				_skip(8) ".replace(/line-break/g, '<br />')" _newline ///
				/// text decoration
				_skip(8) ".replace(/#___/g, '<strong><em>')" _newline ///
				_skip(8) ".replace(/___#/g, '</em></strong>')" _newline ///
				_skip(8) ".replace(/#__/g, '<strong>')" _newline ///
				_skip(8) ".replace(/__#/g, '</strong>')"  _newline ///
				_skip(8) ".replace(/#_/g, '<em>')" _newline ///
				_skip(8) ".replace(/_#/g, '</em>')" _newline ///
				_skip(8) ".replace(/#\*_/g, '<u>')" _newline ///
				_skip(8) ".replace(/_\*#/g, '</u>')" _newline ///
				/// link codes
				_skip(8) ".replace(/\[--/g, '<a href=')" _newline ///
				_skip(8) ".replace(/\--]\[-/g, ' >')" _newline ///
				_skip(8) ".replace(/-\]/g, '</a>')" _newline ///
				_skip(8) ".replace(/\[#\]/g, '</span>')" _newline ///
				/// background colors
				_skip(8) ".replace(/\[-yellow\]/g, '<span style="`"""'"background-color:#FAE768"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-green\]/g, '<span style="`"""'"background-color:#CBEF66"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-blue\]/g, '<span style="`"""'"background-color:#ABC5F6"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-pink\]/g, '<span style="`"""'"background-color:#F1A8D0"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-purple\]/g, '<span style="`"""'"background-color:#D6ABEF"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-gray\]/g, '<span style="`"""'"background-color:#D6D6D6"`"""'">')" _newline ///
				/// font colors
				_skip(8) ".replace(/\[blue\]/g, '<span style="`"""'"color:#00F"`"""'">')" _newline ///
				_skip(8) ".replace(/\[pink\]/g, '<span style="`"""'"color:#FF0080"`"""'">')" _newline ///
				_skip(8) ".replace(/\[purple\]/g, '<span style="`"""'"color:#8000FF"`"""'">')" _newline ///
				_skip(8) ".replace(/\[green\]/g, '<span style="`"""'"color:#408000"`"""'">')" _newline ///
				_skip(8) ".replace(/\[orange\]/g, '<span style="`"""'"color:#FF8000"`"""'">')" _newline ///
				_skip(8) ".replace(/\[red\]/g, '<span style="`"""'"color:#F00"`"""'">')" _newline ///
				/// text positionning 
				_skip(8) ".replace(/\[center\]/g, '<span style="`"""'"display:block; text-align:center"`"""'">')" _newline ///
				_skip(8) ".replace(/\[right\]/g, '<span style="`"""'"display:block; text-align:right"`"""'">')" _newline ///
		_skip(4) "})();" ///
"</script>" _newline(2)


	   
				file write `canvas' _n "</body>" _n  
				file write `canvas' _n "</html>" _n             
        }
    }
	
	
	
	
	
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
						shell $setpath ///
						--footer-center [page] --footer-font-size 10 ///
						`add' ///
						"$htmldoc" "$pdfdoc"
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
			
			
		
		*UNIX
		if "`c(os)'"=="Unix" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						cap shell "$setpath" --no-network  --javascript ///
						"$htmldoc" -o "$pdfdoc"	
						}		
						
				if "$printer" == "wkhtmltopdf" {
						shell "$setpath" ///
						--footer-center [page] --footer-font-size 10 ///
						`add' ///
						"$htmldoc" "$pdfdoc"					
						}
				}
		
		
		********************************************************************
		*REMOVE HTMLDOC, IF SPECIFIED
		********************************************************************
		if "$erase"=="erase" {
				cap erase $htmldoc
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
				if "$erase"~="erase" {
						di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
						`"{it:produced {bf:{browse `"${pdfdoc}"'}} and {bf:{browse `"${htmldoc}"'}} reports}"'
						}
				
				if "$erase"=="erase" {
						di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
						`"{it:produced {bf:{browse `"${pdfdoc}"'}}}"'
						}
				}
		
		*IF THERE IS NO PDF, SEARCH FOR THE HTML DOCUMENT
		if "`r(fn)'" == "" & "$erase"~="erase" {
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
		
		
		********************************************************************
		*RESTORE
		********************************************************************
		
		*restore the original scheme
		cap set scheme $savescheme
		
		macro drop weaver
		macro drop format
		macro drop erase
		macro drop style
		macro drop savescheme
		macro drop printer
		macro drop setpath
		macro drop htmldoc
		macro drop pdfdoc
		macro drop pandoc
		
		
		********************************************************************
		*CHECK WEAVER VERSION
		********************************************************************
		weaverversion
		
	end

