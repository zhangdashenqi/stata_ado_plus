/*******************************************************************************

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								   
                    * These software come with no warranty *
	
	
	This program installs Prince software for Ketchup package. The
	software are downloaded from http://www.stata-blog.com/ 			
	
	Ketchup version 1.0  August, 2014
	Ketchup version 1.1  August, 2014
	Ketchup version 1.2  August, 2014
	Ketchup version 1.3  September, 2014 
	Ketchup version 1.4  October, 2014
	*/
	
	
	
	
	program define ketchupprince
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
			
			*DOWNLOAD PRINCE AND UNZIP IT
			cap qui copy "http://www.stata-blog.com/software/prince_9.0-5.txt" ///
			"prince_9.0-5.txt", replace
			
			cap qui copy "http://www.stata-blog.com/software/Win/Prince.zip" ///
			"Prince.zip", replace
			
			cap qui unzipfile Prince, replace
			cap qui erase Prince.zip
			
			*GETTING THE PATH TO PRINCE
			cap qui cd Prince
			cap qui cd Engine
			cap qui cd bin
			local d : pwd
			global setpath : di "`d'\prince.exe"
			
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
			
			cap qui copy "http://www.stata-blog.com/software/prince_9.0-5.txt" ///
			"prince_9.0-5.txt", replace
		
			cap qui copy "http://www.stata-blog.com/software/Mac/Prince.zip" ///
			"Prince.zip", replace
		
			cap qui unzipfile Prince, replace
			cap qui erase Prince.zip
		
			*GETTING THE PATH TO PRINCE
			cap qui cd Prince
			cap qui cd bin
			local d : pwd
			global setpath : di "`d'\prince"
			
			cap qui shell chmod +x "$setpath"
		
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
			
			cap qui copy "http://www.stata-blog.com/software/prince_9.0-5.txt" ///
			"prince_9.0-5.txt", replace
			
			
			if "`c(bit)'" == "32" {
					cap qui copy "http://www.stata-blog.com/software/Unix/32bit/Prince.zip" ///
					"Prince.zip", replace
					}
			
			if "`c(bit)'" == "64" {
					cap qui copy "http://www.stata-blog.com/software/Unix/64bit/Prince.zip" ///
					"Prince.zip", replace
					}
					
			
		
			cap qui unzipfile Prince, replace
			cap qui erase Prince.zip
			
			*GETTING THE PATH TO PRINCE
			cap qui cd Prince
			cap qui cd bin
			local d : pwd
			global setpath : di "`d'\prince"
			
			cap qui shell chmod +x "$setpath"
			
			}
		

	
	end
	
	
	
	
