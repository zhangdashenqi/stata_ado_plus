/*******************************************************************************

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								   
                    * These software come with no warranty *
	
	
	This program check the supplementary software for Ketchup package. The 
	software are downloaded from http://www.stata-blog.com/ and are Pandoc,
	Princexml, and wkhtmltopdf 
	
	Ketchup version 1.3  September, 2014 
	Ketchup version 1.4  October, 2014 
	*/

	
	program define ketchupcheck
	version 11
	
	*save the current working directory
	qui global location "`c(pwd)'"
	
	********************************************************************
	*PANDOC SOFTWARE INSTALLATION
	********************************************************************
	
	/* MICROSOFT WINDOWS */
	if "`c(os)'"=="Windows" & "$pandoc" == "" {
			
			*Search for Pandoc			
			cap quietly findfile pandoc.exe, path("`c(sysdir_plus)'Weaver\Pandoc")
			
			if "`r(fn)'" ~= "" {
					*save the current working directory
					qui local sub "`c(pwd)'"
		
					*GETTING THE PATH TO PANDOC
					qui cd "`c(sysdir_plus)'Weaver\Pandoc"
					local d : pwd
					global pandoc : di "`d'\pandoc.exe"
					
					*GO BACK TO THE WORKING DIRECTORY
					qui cd "`sub'"
					}
			
			if "`r(fn)'" == "" {
					ketchuppandoc
					local weaverpandoc weaverpandoc
					}		
			}
		
	
	/* MACINTOSH */
	if "`c(os)'" == "MacOSX" & "$pandoc" == "" {	
			
			*Search for Pandoc			
			cap quietly findfile pandoc, path("`c(sysdir_plus)'Weaver/Pandoc")
			
			if "`r(fn)'" ~= "" {
					
					*save the current working directory
					qui local sub "`c(pwd)'"
		
					*GETTING THE PATH TO PANDOC
					qui cd "`c(sysdir_plus)'/Weaver/Pandoc"
					local d : pwd
					global pandoc : di "`d'/pandoc"
					
					*GO BACK TO THE WORKING DIRECTORY
					qui cd "`sub'"
					}
			
			if "`r(fn)'" == "" {
					ketchuppandoc
					local weaverpandoc weaverpandoc
					}				
			
			}
		
	


	/* UNIX */
	if "`c(os)'"=="Unix" & "$pandoc" == "" {
			
			*Search for Pandoc			
			cap quietly findfile pandoc, path("`c(sysdir_plus)'Weaver/Pandoc")
			
			if "`r(fn)'" ~= "" {
					
					*save the current working directory
					qui local sub "`c(pwd)'"
		
					*GETTING THE PATH TO PANDOC
					qui cd "`c(sysdir_plus)'/Weaver/Pandoc"
					local d : pwd
					global pandoc : di "`d'/pandoc"
					
					*GO BACK TO THE WORKING DIRECTORY
					qui cd "`sub'"
					}
			
			if "`r(fn)'" == "" {
					ketchuppandoc
					local weaverpandoc weaverpandoc
					}	
			}
	
	
	
	
	
	
	
	
	
	********************************************************************
	*PRINCE SOFTWARE INSTALLATION
	********************************************************************
	
	if "`c(os)'"=="Windows" {
		
			if "$printer" == "prince" & "$setpath" == "" | ///
			"$printer" == "" & "$setpath" == "" {	
			
					*Search for Prince
					cap quietly findfile prince.exe, path("`c(sysdir_plus)'Weaver/Prince/Engine/bin/")
					if "`r(fn)'" ~= "" {
							*save the current working directory
							qui local sub "`c(pwd)'"
		
							*GETTING THE PATH TO PANDOC
							qui cd "`c(sysdir_plus)'Weaver/Prince/Engine/bin"
							local d : pwd
							global setpath : di "`d'\prince.exe"
					
							*GO BACK TO THE WORKING DIRECTORY
							qui cd "`sub'"

							}

					*If Prince does not exist, run weaverprince program
					if "`r(fn)'" == "" {
					
							if "`weaverpandoc'" == "weaverpandoc"	qui ketchupprince
							if "`weaverpandoc'" != "weaverpandoc"	ketchupprince	
					
							cap quietly findfile prince.exe, path("`c(sysdir_plus)'Weaver/Prince/Engine/bin/")
							*save the current working directory
							qui local sub "`c(pwd)'"
		
							*GETTING THE PATH TO PANDOC
							qui cd "`c(sysdir_plus)'Weaver/Prince/Engine/bin"
							local d : pwd
							global setpath : di "`d'\prince.exe"
					
							*GO BACK TO THE WORKING DIRECTORY
							qui cd "`sub'"
					
							* Create a marker
							local weaverprince weaverprince
							}
					}
			}		
		
	
	
	if "`c(os)'"=="MacOSX" {
		
			if "$printer" == "prince" & "$setpath" == "" | ///
			"$printer" == "" & "$setpath" == "" {	
			
					*Search for Pandoc
					cap quietly findfile prince, path("`c(sysdir_plus)'Weaver/Prince/bin/")
					if "`r(fn)'" ~= "" {
							*save the current working directory
							qui local sub "`c(pwd)'"
		
							*GETTING THE PATH TO PANDOC
							qui cd "`c(sysdir_plus)'/Weaver/Prince/bin"
							local d : pwd
							global setpath : di "`d'/prince"
					
							*GO BACK TO THE WORKING DIRECTORY
							qui cd "`sub'"
							}
				
					*If Prince does not exist, run weaverprince program
					if "`r(fn)'" == "" {
							if "`weaverpandoc'" == "weaverpandoc"	qui ketchupprince
							if "`weaverpandoc'" != "weaverpandoc"	ketchupprince
					
							*save the current working directory
							qui local sub "`c(pwd)'"
		
							*GETTING THE PATH TO PANDOC
							qui cd "`c(sysdir_plus)'/Weaver/Prince/bin"
							local d : pwd
							global setpath : di "`d'/prince"
					
							*GO BACK TO THE WORKING DIRECTORY
							qui cd "`sub'"
					
							* Create a marker
							local weaverprince weaverprince
							}
					}	
			}
		
		

	
	if "`c(os)'"=="Unix" {
			
			if "$printer" == "prince" & "$setpath" == "" | ///
			"$printer" == "" & "$setpath" == "" {	
		
					*Search for Prince
					cap quietly findfile prince, path("`c(sysdir_plus)'Weaver/Prince/bin/")
					if "`r(fn)'" ~= "" {
							*save the current working directory
							qui local sub "`c(pwd)'"
		
							*GETTING THE PATH TO PANDOC
							qui cd "`c(sysdir_plus)'/Weaver/Prince/bin"
							local d : pwd
							global setpath : di "`d'/prince"
					
							*GO BACK TO THE WORKING DIRECTORY
							qui cd "`sub'"
							}
				
					*If Prince does not exist, run weaverprince program
				
					if "`r(fn)'" == "" {
							if "`weaverpandoc'" == "weaverpandoc"	qui ketchupprince
							if "`weaverpandoc'" != "weaverpandoc"	ketchupprince
					
							if "`r(fn)'" ~= "" {
							*save the current working directory
							qui local sub "`c(pwd)'"
		
							*GETTING THE PATH TO PANDOC
							qui cd "`c(sysdir_plus)'/Weaver/Prince/bin"
							local d : pwd
							global setpath : di "`d'/prince"
					
							*GO BACK TO THE WORKING DIRECTORY
							qui cd "`sub'"
							}
					
							* Create a marker
							local weaverprince weaverprince
							}
					}
			}

	
	
	
	
	
	
	
	
	
	
	
	********************************************************************
	*wkhtmltopdf SOFTWARE INSTALLATION
	********************************************************************
	
	if "`c(os)'"=="Windows" {
			
			if "$printer" == "wkhtmltopdf" & "$setpath" == "" | ///
			"$printer" == "wk" & "$setpath" == "" {
		
					*Search for wkhtmltopdf
					cap quietly findfile wkhtmltopdf.exe, path("`c(sysdir_plus)'Weaver\wkhtmltopdf\bin\")
					if "`r(fn)'" ~= "" {
							*save the current working directory
							qui local sub "`c(pwd)'"
		
							*GETTING THE PATH TO PANDOC
							qui cd "`c(sysdir_plus)'/Weaver/wkhtmltopdf/bin"
							local d : pwd
							global setpath : di "`d'/wkhtmltopdf.exe"
					
							*GO BACK TO THE WORKING DIRECTORY
							qui cd "`sub'"
							}
				
					*If wkhtmltopdf does not exist, run weaverwkhtmltopdf program
				
					if "`r(fn)'" == "" {
				
							if "`weaverpandoc'" == "weaverpandoc"	| ///
							"`weaverprince'" == "weaverprince" qui ketchupwkhtmltopdf
					
							if "`weaverpandoc'" != "weaverpandoc"	& ///
							"`weaverprince'" != "weaverprince" ketchupwkhtmltopdf
					
							qui local sub "`c(pwd)'"
							qui cd "`c(sysdir_plus)'/Weaver/wkhtmltopdf/bin"
							local d : pwd
							global setpath : di "`d'/wkhtmltopdf.exe"
							qui cd "`sub'"
							}
					}	
			}
		
		
	
	if "`c(os)'"=="MacOSX" {
			
			if "$printer" == "wkhtmltopdf" & "$setpath" == "" | ///
			"$printer" == "wk" & "$setpath" == "" {
		
					*Search for wkhtmltopdf
					cap quietly findfile wkhtmltopdf, path("`c(sysdir_plus)'Weaver/wkhtmltopdf/")
					if "`r(fn)'" ~= "" {
							qui local sub "`c(pwd)'"
							qui cd "`c(sysdir_plus)'/Weaver/wkhtmltopdf"
							local d : pwd
							global setpath : di "`d'/wkhtmltopdf"
							qui cd "`sub'"
							}
				
					*If wkhtmltopdf does not exist, run weaverwkhtmltopdf program
					if "`r(fn)'" == "" {
				
							if "`weaverpandoc'" == "weaverpandoc"	| ///
							"`weaverprince'" == "weaverprince" qui ketchupwkhtmltopdf
					
							if "`weaverpandoc'" != "weaverpandoc"	& ///
							"`weaverprince'" != "weaverprince" ketchupwkhtmltopdf
					
							qui local sub "`c(pwd)'"
							qui cd "`c(sysdir_plus)'/Weaver/wkhtmltopdf"
							local d : pwd
							global setpath : di "`d'/wkhtmltopdf"
							qui cd "`sub'"
							}
					}	
			}
		
		
	
	if "`c(os)'" == "Unix" {
			
			if "$printer" == "wkhtmltopdf" & "$setpath" == "" | ///
			"$printer" == "wk" & "$setpath" == "" {
		
					*Search for wkhtmltopdf
					cap quietly findfile wkhtmltopdf, path("`c(sysdir_plus)'Weaver/wkhtmltopdf/")
					if "`r(fn)'" ~= "" {
							qui local sub "`c(pwd)'"
							qui cd "`c(sysdir_plus)'/Weaver/wkhtmltopdf"
							local d : pwd
							global setpath : di "`d'/wkhtmltopdf"
							qui cd "`sub'"
							}
				
					*If wkhtmltopdf does not exist, run weaverwkhtmltopdf program
				
					if "`r(fn)'" == "" {	
							if "`weaverpandoc'" == "weaverpandoc"	| ///
							"`weaverprince'" == "weaverprince" qui ketchupwkhtmltopdf
					
							if "`weaverpandoc'" != "weaverpandoc"	& ///
							"`weaverprince'" != "weaverprince" ketchupwkhtmltopdf
					
							qui local sub "`c(pwd)'"
							qui cd "`c(sysdir_plus)'/Weaver/wkhtmltopdf"
							local d : pwd
							global setpath : di "`d'/wkhtmltopdf"
							qui cd "`sub'"
							}
					}		
			}
		
	

	
	*go back to the previous working directory
	qui cd "$location"
	macro drop location
	
	end
	
