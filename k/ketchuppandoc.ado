/*******************************************************************************

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								   
                    * These software come with no warranty *
	
	
	This program installs Pandoc software for Ketchup package. The
	software are downloaded from http://www.stata-blog.com/ 			
	
	Ketchup version 1.3  September, 2014 
	Ketchup version 1.4  October, 2014 
	*/


	program define ketchuppandoc
	version 11
	
	********************************************************************
	*MICROSOFT WINDOWS 32BIT & 64BIT
	********************************************************************
	if "`c(os)'" == "Windows" {
			
			*save the current working directory
			qui local location "`c(pwd)'"
		
			*CREATE WEAVER DIRECTORY
			qui cd "`c(sysdir_plus)'"
			cap qui mkdir Weaver
			qui cd Weaver
			local d : pwd
			
			di _n
			di as txt ///
			" ____  _                      __        __    _ _   " _n ///
			"|  _ \| | ___  __ _ ___  ___  \ \      / /_ _(_) |_ " _n ///
			"| |_) | |/ _ \/ _` / __|/ _ \  \ \ /\ / / _` | | __|" _n ///
			"|  __/| |  __/ (_| \__ \  __/   \ V  V / (_| | | |_ " _n ///
			"|_|   |_|\___|\__,_|___/\___|    \_/\_/ \__,_|_|\__|" _n 
			
			di as txt "{p}Required software packages are getting installed " ///
			"in {browse `d'} directory. make sure you are " ///
			"connected to internet. This may take a while..." _n(4)
			
			
			*DOWNLOAD PANDOC AND UNZIP IT
			cap qui copy "http://www.stata-blog.com/software/pandoc_1.13.1.txt" ///
			"pandoc_1.13.1.txt", replace
			
			cap qui copy "http://www.stata-blog.com/software/Win/Pandoc.zip" ///
			"Pandoc.zip", replace
			
			cap qui unzipfile Pandoc, replace
			cap qui erase Pandoc.zip
			
			*GETTING THE PATH TO PANDOC
			cap qui cd Pandoc
			local d : pwd
			global pandoc : di "`d'\pandoc.exe"
			
			qui cd "`location'"
		
			}
		
		
	********************************************************************
	*MAC 32BIT & 64BIT
	********************************************************************
	if "`c(os)'" == "MacOSX" {
			
			*save the current working directory
			qui local location "`c(pwd)'"
		
			*CREATE WEAVER DIRECTORY
			qui cd "`c(sysdir_plus)'"
			cap qui mkdir Weaver
			qui cd Weaver
			local d : pwd
			
			di _n
			di as txt ///
			" ____  _                      __        __    _ _   " _n ///
			"|  _ \| | ___  __ _ ___  ___  \ \      / /_ _(_) |_ " _n ///
			"| |_) | |/ _ \/ _` / __|/ _ \  \ \ /\ / / _` | | __|" _n ///
			"|  __/| |  __/ (_| \__ \  __/   \ V  V / (_| | | |_ " _n ///
			"|_|   |_|\___|\__,_|___/\___|    \_/\_/ \__,_|_|\__|" _n 
			
			di as txt "{p}Required software packages are getting installed " ///
			"in {browse `d'} directory. make sure you are " ///
			"connected to internet. This may take a while..." _n(4)
			
			*DOWNLOAD PANDOC AND UNZIP IT
			cap qui copy "http://www.stata-blog.com/software/pandoc_1.13.1.txt" ///
			"pandoc_1.13.1.txt", replace
			cap qui copy "http://www.stata-blog.com/software/Mac/Pandoc.zip" ///
			"Pandoc.zip", replace
			cap qui unzipfile Pandoc, replace
			cap qui erase Pandoc.zip
			
			*GETTING THE PATH TO PANDOC
			cap qui cd Pandoc
			local d : pwd
			global pandoc : di "`d'/pandoc"
			
			*CHANGE CHMOD 
			cap qui shell chmod +x "$pandoc"
			
			}
		
		
	********************************************************************
	*UNIX 32BIT & 64BIT
	********************************************************************
	if "`c(os)'"=="Unix" {
			
			*save the current working directory
			qui local location "`c(pwd)'"
		
			*CREATE WEAVER DIRECTORY
			qui cd "`c(sysdir_plus)'"
			cap qui mkdir Weaver
			qui cd Weaver
			local d : pwd
			
			
			di _n
			di as txt ///
			" ____  _                      __        __    _ _   " _n ///
			"|  _ \| | ___  __ _ ___  ___  \ \      / /_ _(_) |_ " _n ///
			"| |_) | |/ _ \/ _` / __|/ _ \  \ \ /\ / / _` | | __|" _n ///
			"|  __/| |  __/ (_| \__ \  __/   \ V  V / (_| | | |_ " _n ///
			"|_|   |_|\___|\__,_|___/\___|    \_/\_/ \__,_|_|\__|" _n 
		
			di as txt "{p}Required software packages are getting installed " ///
			"in {browse `d'} directory. make sure you are " ///
			"connected to internet. This may take a while..." _n(4)
		
			*DOWNLOAD PANDOC AND UNZIP IT
			cap qui copy "http://www.stata-blog.com/software/pandoc_1.13.1.txt" ///
			"pandoc_1.13.1.txt", replace
			
			if "`c(bit)'" == "32" {
					cap qui copy "http://www.stata-blog.com/software/Unix/32bit/Pandoc.zip" ///
					"Pandoc.zip", replace
					}
			
			if "`c(bit)'" == "64" {
					cap qui copy "http://www.stata-blog.com/software/Unix/64bit/Pandoc.zip" ///
					"Pandoc.zip", replace
					}
					
			
			cap qui unzipfile Pandoc, replace
			cap qui erase Pandoc.zip
		
			*GETTING THE PATH TO PANDOC
			cap qui cd Pandoc
			local d : pwd
			global pandoc : di "`d'/pandoc"
		
			*CHANGE CHMOD 
			cap qui shell chmod +x "$pandoc"
		
			*GO BACK TO THE WORKING DIRECTORY
			qui cd "`location'"		
			}
	
	end
