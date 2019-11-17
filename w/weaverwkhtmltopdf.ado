/*******************************************************************************

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								   
                    * These software come with no warranty *
	
	
	This program installs wkhtmltopdf software for Weaver package. The
	software are downloaded from http://www.stata-blog.com/ 			
	
	
	Weaver version 1.3  September, 2014
	Weaver version 1.4  October, 2014 
*******************************************************************************/
	
	
	
	
	program define weaverwkhtmltopdf
	version 11
	
	********************************************************************
	*MICROSOFT WINDOWS 32BIT & 64BIT
	********************************************************************
	if "`c(os)'" == "Windows" {
			
			*save the current working directory
			qui local location "`c(pwd)'"
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
	
			
			*DOWNLOAD WKHTMLTOPDF AND UNZIP IT
			cap qui copy "http://www.stata-blog.com/software/wkhtmltopdf_0.12.1.txt" ///
			"wkhtmltopdf_0.12.1.txt", replace
			
			if "`c(bit)'" == "32" {
					cap qui copy "http://www.stata-blog.com/software/Win/32bit/wkhtmltopdf.zip" ///
					"wkhtmltopdf.zip", replace
					}
			
			if "`c(bit)'" == "64" {
					cap qui copy "http://www.stata-blog.com/software/Win/64bit/wkhtmltopdf.zip" ///
					"wkhtmltopdf.zip", replace
					}
			
			cap qui unzipfile wkhtmltopdf, replace
			cap qui erase wkhtmltopdf.zip
			
			*GETTING THE PATH TO WKHTMLTOPDF
			cap qui cd wkhtmltopdf
			cap qui cd bin
			local d : pwd
			global setpath : di "`d'\wkhtmltopdf.exe"
		
			qui cd "`location'"
		
			}

		
		
	********************************************************************
	*MAC 32BIT & 64BIT
	********************************************************************
	if "`c(os)'" == "MacOSX" {
			
			*save the current working directory
			qui local location "`c(pwd)'"
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
			
			
			*DOWNLOAD WKHTMLTOPDF AND UNZIP IT
			cap qui copy "http://www.stata-blog.com/software/wkhtmltopdf_0.12.1.txt" ///
			"wkhtmltopdf_0.12.1.txt", replace
			
			cap qui copy "http://www.stata-blog.com/software/Mac/wkhtmltopdf.zip" ///
			"wkhtmltopdf.zip", replace
			
			cap qui unzipfile wkhtmltopdf, replace
			cap qui erase wkhtmltopdf.zip
			
			*GETTING THE PATH TO WKHTMLTOPDF
			cap qui cd wkhtmltopdf
			local d : pwd
			global setpath : di "`d'/wkhtmltopdf"
		
			qui cd "`location'"
		
			cap qui shell chmod +x "$setpath"
		
			}
		
		
	********************************************************************
	*UNIX 32BIT & 64BIT
	********************************************************************
	if "`c(os)'"=="Unix" & "`c(bit)'" == "32" {
			
			*save the current working directory
			qui local location "`c(pwd)'"
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
			
			
			*DOWNLOAD WKHTMLTOPDF AND UNZIP IT
			cap qui copy "http://www.stata-blog.com/software/wkhtmltopdf_0.12.1.txt" ///
			"wkhtmltopdf_0.12.1.txt", replace
			
			if "`c(bit)'" == "32" {
					cap qui copy "http://www.stata-blog.com/software/Unix/32bit/wkhtmltopdf.zip" ///
					"wkhtmltopdf.zip", replace
					}
			
			if "`c(bit)'" == "64" {
					cap qui copy "http://www.stata-blog.com/software/Unix/64bit/wkhtmltopdf.zip" ///
					"wkhtmltopdf.zip", replace
					}
			
			cap qui unzipfile wkhtmltopdf, replace
			cap qui erase wkhtmltopdf.zip
			
			
			*GETTING THE PATH TO WKHTMLTOPDF
			cap qui cd wkhtmltopdf
			local d : pwd
			global setpath : di "`d'/wkhtmltopdf"
		
			qui cd "`location'"
		
			cap qui shell chmod +x "$setpath"
		
			}
		
		
	
	end
	
	
	
	
