// lsq.mata 1.5 04.10.2007
// Mata libary for sq.pkg
// Ulrich Kohler and Magdalena Luniak, WZB
// Support: kohler@wz-berlin, luniak@wz-berlin.de


// 1.3 -> initial SJ version
// 1.4 -> Implement a Call for plugin by Brendan Halpan
// 1.5 -> mapping of sequences to the alphabet of natural numbers, no hashing
// 1.6 -> exact algorithm with full submatrix buggy. -> fixed


// Disclaimer
// ----------
//
// In the code below, those parts headed by the term "Magda-Code" are 
// based on the source code of TDA, written by Goetz Rohwer and Ulrich Poetter. 
// TDA is a very powerful program for Transitory Data Analysis. It is programmed 
// in C, and distrubuted as FREEWARE under the terms of the General Public License. It is
// downloadable from http://www.stat.ruhr-uni-bochum.de/tda.html.
//
// My understanding of the GPL is that you can freely change and redistribute the 
// respective parts of the programs, provided that you mention the authorship of 
// Goetz Rohwer and Ulrich Poetter, and that you publish the source code of the 
// code based on the parts headed with "Magda-Code". 
// 
// For Copyright issues pleae refer to the General Public License which can
// can be found on http://www.gnu.org/copyleft/gpl.html

//1.3 -> initial SJ version
//1.4 without hashing, mapping of sequences to the alphabet of natural numbers 


version 9.1
mata:
	mata clear
	mata set matastrict on


	// ---------------------------------------------------------------
	// Caller for the Needleman-Wunsch Algorithm for reference-sequence
	void sqomref(
		string scalar varlist, 
		real scalar indelcost, 
		string scalar standard, 
		real scalar k, 
		real scalar subcost)
	
	{ 
		// Initialize variables
		real matrix X        // Data-Matrix
		real colvector D     // Distance-Variable
		real rowvector R     // 1st Selected Sequence (Row of Levensthein)
		real rowvector C     // Reference-Sequence (Col of Levensthein)
		real scalar i 
		real scalar j 
		
		// View on sequence data in wide format
		st_view(X=.,.,tokens(varlist)) 
		
		// Reference sequence
		C = X[rows(X),1..sqlength(X[rows(X),.])]
		
		// Initialize distance matrix
		D = J(rows(X),1,0) 
		
		// Call NeedlemanWunsch with fixed subcosts (the default)
		if (subcost>0) { 
			for (i=1;i<=rows(X)-1;i++) { 
              R = X[i,1..sqlength(X[i,.])]
				if (k==0) {
					D[i,1] = needlemanwunschexactfixed(
						R,C,indelcost,standard,subcost)
				}
				else {
					D[i,1] = needlemanwunschapproxfixed(
						R,C,indelcost,k,standard,subcost)
				}
			}
			D = (standard=="longest" ? D:/(cols(X)) : D )
			st_addvar("float","_SQdist")
			st_store(.,"_SQdist",D)
		}
		
		// Call NeedlemanWunsch with rawdistance
		else if (subcost==-1) {
			for (i=1;i<=rows(X)-1;i++) {
              R = X[i,1..sqlength(X[i,.])] 
				if (k==0) {
					D[i,1] = needlemanwunschexactrawdist(
						R,C,indelcost,standard)
				}
				else {
					D[i,1] = needlemanwunschapproxrawdist(
						R,C,indelcost,k,standard)
				}        
			}
			D = (standard=="longest" ? D:/(cols(X)) : D )
      st_addvar("float","_SQdist")
			st_store(.,"_SQdist",D)
		}
		
		// Call NeedlemanWunsch with full subcost-matrix
		else if (subcost == 0) {
			
			// Initialize material for hashing
			real matrix SQsubcost
			SQsubcost = st_matrix("SQsubcost")
			
      for (i=1;i<=rows(X)-1;i++) {
				R = X[i,1..sqlength(X[i,.])]
				if (k==0) {
					D[i,1] = needlemanwunschexactmatrix(
						R,C,indelcost, SQsubcost,standard)
				}    
				else {
					D[i,1] = needlemanwunschapproxmatrix(
						R,C,indelcost,k,standard,SQsubcost)
				}
      }
			D = (standard=="longest" ? D:/(cols(X)) : D )
			st_addvar("float","_SQdist")
			st_store(.,"_SQdist",D)
		}
	}
	
	
	// ---------------------------------------------------------------
	// Caller for the Needleman-Wunsch Algorithm for full distance Matrix
	void sqomfull(
		string scalar varlist, 
		real scalar indelcost, 
		string scalar standard, 
  real scalar k, 
		real scalar subcost)
	
	{ 
		// Initialize variables
		real matrix X        // Data-Matrix
		real matrix D        // Distance-Matrix
		real rowvector R     // 1st Selected Sequence (Row of Levensthein)
		real rowvector C     // 2nd Selected Sequence (Col of Levensthein)
		real scalar i 
		real scalar j 
		
    
		// View on sequence data in wide format
		st_view(X=.,.,tokens(varlist)) 
		
		// Initialize distance matrix
		D = J(rows(X),rows(X),0) 
		
		// Call NeedlemanWunsch with fixed subcosts (the default)
		if (subcost>0) { 
			for (i=1;i<=rows(X)-1;i++) { 
				for (j=i+1;j<=rows(X);j++) { 
					R = X[i,1..sqlength(X[i,.])]
              C = X[j,1..sqlength(X[j,.])]
					if (k==0) {
						D[j,i] = needlemanwunschexactfixed(
							R,C,indelcost,standard,subcost)
					}
					else {
						D[j,i] = needlemanwunschapproxfixed(
							R,C,indelcost,k,standard,subcost)
					}
				}
			}
			D = (standard=="longest" ? D:/(cols(X)) : D )
			st_matrix("SQdist",(makesymmetric(D)))
  }
		
		// Call NeedlemanWunsch with rawdistance
		else if (subcost==-1) {
			for (i=1;i<=rows(X)-1;i++) {
				for (j=i+1;j<=rows(X);j++) {
					R = X[i,1..sqlength(X[i,.])] 
					C = X[j,1..sqlength(X[j,.])]
					if (k==0) {
						D[j,i] = needlemanwunschexactrawdist(
							R,C,indelcost,standard)
					}
					else {
						D[j,i] = needlemanwunschapproxrawdist(
							R,C,indelcost,k,standard)
					}        
				}
			}
			st_matrix("SQdist",(makesymmetric(D)))
		}

		// Call NeedlemanWunsch with full subcost-matrix
		else if (subcost == 0) {
			
			// Initialize material for hashing
			real matrix SQsubcost
			SQsubcost = st_matrix("SQsubcost")
            
			for (i=1;i<=rows(X)-1;i++) {
				for (j=i+1;j<=rows(X);j++) {
					R = X[i,1..sqlength(X[i,.])]
					C = X[j,1..sqlength(X[j,.])]
					if (k==0) {
						D[j,i] = needlemanwunschexactmatrix(
							R,C,indelcost,SQsubcost,standard)
					}    
					else {
						D[j,i] = needlemanwunschapproxmatrix(
							R,C,indelcost,k,standard,SQsubcost)
					}
				}
			}
			st_matrix("SQdist",(makesymmetric(D)))
		}
	}
	
	// ---------------------------------------------------------------
	// "Exact" Needleman-Wunsch Algorithm with fixed subcosts
	real scalar needlemanwunschexactfixed(
		real rowvector R, 
		real rowvector C, 
		real scalar indelcost, 
		string scalar standard, 
		real scalar subcost)
	
	{
		// Initializations
		real matrix L       // Levensthein-Matrix
		real rowvector M    // Vector of Values to be Minimized
		real scalar i
		real scalar j
        
		// Levensthein-Matrix
		L = J(cols(R)+1,cols(C)+1,0)
		
		// Initialize First Row/Col of Levensthein
		for (i=2;i<=cols(R)+1;i++) {
			L[i,1]=L[i-1,1]+indelcost
		}
		for (j=2;j<=cols(C)+1;j++) {
			L[1,j]=L[1,j-1]+indelcost
		}
        
		// Step thru the Levensthein 
		for (i=2;i<=cols(R)+1;i++) {
			for (j=2;j<=cols(C)+1;j++) {
				M = L[i-1,j-1]+ (R[1,i-1]==C[1,j-1]? 0 : subcost),
                L[i-1,j]+indelcost,
                L[i,j-1]+indelcost
				L[i,j]=min(M)
			}
		}
		return((L[cols(R)+1,cols(C)+1])/(standard=="longer" ? 
				max((cols(R),cols(C))):
				1)
			)
	}
	
	
	// ---------------------------------------------------------------
	// "Exact" Needleman-Wunsch Algorithm with rawdistance-subcosts
	real scalar needlemanwunschexactrawdist(
		real rowvector R, 
		real rowvector C, 
		real scalar indelcost, 
		string scalar standard)
	
	{
		// Initializations
		real matrix L       // Levensthein-Matrix
		real rowvector M    // Vector of Values to be Minimized
		real scalar i
		real scalar j
		
		// Initialize Levensthein-Matrix
		L = J(cols(R)+1,cols(C)+1,0)
		
		// Initialize First Row/Col of Levensthein
		for (i=2;i<=cols(R)+1;i++) {
			L[i,1]=L[i-1,1]+indelcost
		}
		for (j=2;j<=cols(C)+1;j++) {
			L[1,j]=L[1,j-1]+indelcost
		}
        
		// Step thru the Levensthein 
		for (i=2;i<=cols(R)+1;i++) {
			for (j=2;j<=cols(C)+1;j++) {
				M = L[i-1,j-1]+ abs(R[1,i-1]-C[1,j-1]),
                L[i-1,j]+indelcost,
                L[i,j-1]+indelcost
				L[i,j]=min(M)
			}
		}
		return((L[cols(R)+1,cols(C)+1])/(standard=="longer" ? 
            max((cols(R),cols(C))):
				1)
			)
	}
	
	// ---------------------------------------------------------------
	// "Exact" Needleman-Wunsch Algorithm with Subcost Matrix
	real scalar needlemanwunschexactmatrix(
		real rowvector R, 
  real rowvector C, 
		real scalar indelcost,
		real matrix SQsubcost,
		string scalar standard)
	
	{
		
		// Initializations
		real matrix L       // Levensthein-Matrix
		real rowvector M    // Vector of Values to be Minimized
		real scalar i
		real scalar j
        
		// Initialize Levensthein-Matrix
		L = J(cols(R)+1,cols(C)+1,0)
		
		// Initialize First Row/Col of Levensthein
		for (i=2;i<=cols(R)+1;i++) {
			L[i,1]=L[i-1,1]+indelcost
		}
		for (j=2;j<=cols(C)+1;j++) {
			L[1,j]=L[1,j-1]+indelcost
		}
        
		// Step thru the Levensthein 
		for (i=2;i<=cols(R)+1;i++) {
			for (j=2;j<=cols(C)+1;j++) {
				M = L[i-1,j-1]+ SQsubcost[R[1,i-1],C[1,j-1]],      
                L[i-1,j]+indelcost,
                L[i,j-1]+indelcost
				L[i,j]=min(M)
			}
		}
		return((L[cols(R)+1,cols(C)+1])/(standard=="longer" ? 
				max((cols(R),cols(C))):
				1)
			)
	}
	
	// ---------------------------------------------------------------
	// Approx-Needlman Wunsch with fixed subcost (Magda Code)
	real scalar needlemanwunschapproxfixed(
		real rowvector R, 
		real rowvector C, 
		real scalar indelcost, 
		real scalar paramK, 
		string scalar standard, 
		real scalar subcost)
	
	{
		// Initializations
		real scalar distance            // return value
		distance = 0
		
		// Auxiliary Variables
		real scalar inser            
		real scalar del                 
		real scalar help1               
		real scalar help2               
		real scalar help3               
		real scalar index1              
		real scalar index2              
		real scalar i
		real scalar j
		
		// Length of sequences
		real scalar iLength
		real scalar jLength
		iLength = sqlength(R)
		jLength = sqlength(C)
		
		// Dimension of Levensthein-matrix
		real scalar matrixDim
		real vector v
		v = iLength, jLength
		matrixDim = max(v)+1
		
		// Boundary of Levensthein-matrix
		real scalar bound
		bound = (iLength/jLength + jLength/iLength)/sqrt(iLength*iLength+jLength*jLength)
		bound = paramK * bound / sqrt(2)
		
		// Initialisation of Levensthein-matrix
		// Note: Levensthein as vector and initialized with infinity
		real matrix L
		L = J(matrixDim*matrixDim, 1, .)
		L[1,1]=0
		for(i=1; i<matrixDim; i++) {
			L[i+1,1]=L[i,1] + indelcost
        if(i<matrixDim) {
				L[i*matrixDim+1,1]=L[((i-1)*matrixDim)+1,1] + indelcost
			}
		}
		
		// Control variables for loop over second sequence
		real scalar j1
		real scalar j2
		real scalar j3
		
		j1=1
		j2=jLength +1
		j3=jLength +1
		
    // 1. loop: the first sequence
		for(i=1; i<iLength+1; i++) {
			help1 = (i)/iLength
			help2 = (jLength+1)*(help1-bound)
			help3 = (jLength+1)*(help1+bound)
			
			// Values of control variables for loop for the second sequence
			if(help2 <= 2) {
				j1 = 1
			}
			else {
				j1 = floor(help2)
			}

			if(help3>=jLength+1) {
				j2 = jLength +1
			}
			else {
				j2 = floor(help3)
			}
			
			// Coordinates for Levensthein-matrix(vector)
			index1 = (i-1)*matrixDim + j1
			index2 = index1 + matrixDim
			
			// 2. loop: the second sequence
			for(j=j1; j<j2; j++) {
				
				// Substitution
				distance = (R[1,i]==C[1,j]? 0 : subcost)
				distance = distance + L[index1, 1]
				index1++
				
				// Insertion
				if(j>j1 || j==1) {
					inser = indelcost + L[index2, 1]
					if(distance>inser) {
						distance= inser
					}
				}
				index2++
				
				// Deletion
				if(j<j3) {
					del = indelcost+L[index1, 1]
					if(distance>del) {
						distance=del
					}
					L[index2,1]=distance
				}
				j3=j2
			}
		}
		return(distance/(standard=="longer" ? max((cols(R),cols(C))):1))
	}
	
    
	// ---------------------------------------------------------------
	// Approx-Needlman Wunsch with rawdistance (Magda Code)
	real scalar needlemanwunschapproxrawdist(
		real rowvector R, 
		real rowvector C, 
		real scalar indelcost, 
		real scalar paramK, 
		string scalar standard)
	
	{
		// Initializations
		real scalar distance            //return value
		distance = 0
		
		// Auxiliary variables
		real scalar inser               
		real scalar del                 
		real scalar help1               
		real scalar help2               
		real scalar help3               
		real scalar index1              
		real scalar index2              
		real scalar i
		real scalar j
		
		// Length of sequences
		real scalar iLength
		real scalar jLength
		iLength = sqlength(R)
		jLength = sqlength(C)
		
		//Dimension of Levensthein-matrix
		real scalar matrixDim
		real vector v
		v = iLength, jLength
		matrixDim = max(v)+1
		
		//Boundary of Levensthein-matrix
		real scalar bound
		bound = (iLength/jLength + jLength/iLength)/sqrt(iLength*iLength+jLength*jLength)
		bound = paramK * bound / sqrt(2)
		
		// Initialisation of Levensthein-matrix
		// Note: Levensthein as vector and initialized with infinity
    real matrix L
		L = J(matrixDim*matrixDim, 1, .)
		L[1,1]=0
		for(i=1; i<matrixDim; i++) {
			L[i+1,1]=L[i,1] + indelcost
			if(i<matrixDim) {
				L[i*matrixDim+1,1]=L[((i-1)*matrixDim)+1,1] + indelcost
			}
		}
		
		// Control variables for loop over second sequence
		real scalar j1
		real scalar j2
		real scalar j3
		
		j1=1
		j2=jLength +1
		j3=jLength +1
		
		// 1. loop: the first sequence
		for(i=1; i<iLength+1; i++) {
			help1 = (i)/iLength
			help2 = (jLength+1)*(help1-bound)
			help3 = (jLength+1)*(help1+bound)
			
			// Values of control variables for loop for the second sequence
			if(help2 <= 2) {
                j1 = 1
            }
			else {
                j1 = floor(help2)
            }
			
			if(help3>=jLength+1) {
                j2 = jLength +1
            }
			else {
                j2 = floor(help3)
            }
			
			// Coordinates for Levensthein-matrix(vector)
			index1 = (i-1)*matrixDim + j1
			index2 = index1 + matrixDim
			
			//2. loop: the second sequence
			for(j=j1; j<j2; j++) {
				
				// Substitution 
				distance = abs(R[1,i]-C[1,j])
				distance = distance + L[index1, 1]
                index1++
				
				// Insertion
				if(j>j1 || j==1) {
					inser = indelcost + L[index2, 1]
					if(distance>inser) {
						distance= inser
					}
                }
                index2++
				
                // Deletion
                if(j<j3) {
					del = indelcost+L[index1, 1]
					if(distance>del) {
						distance=del
					}
					L[index2,1]=distance
				}
				j3=j2
			}
		}
		return(distance/(standard=="longer" ? max((cols(R),cols(C))):1))
	}
	
	
	// ---------------------------------------------------------------
	// Approx-Needlman Wunsch with full subcost matrix (Magda Code)
	real scalar needlemanwunschapproxmatrix(
		real rowvector R, 
		real rowvector C, 
		real scalar indelcost, 
		real scalar paramK, 
		string scalar standard,
		real matrix SQsubcost
		)
	
	{
		// Initializations
		real scalar distance            //return value
		distance = 0
		
		// Auxiliary variables
		real scalar inser               
		real scalar del                 
		real scalar help1               
		real scalar help2               
		real scalar help3               
		real scalar index1              
		real scalar index2              
		real scalar i
		real scalar j
		
		// Length of sequences
		real scalar iLength
		real scalar jLength
		iLength = sqlength(R)
		jLength = sqlength(C)
		
		//Dimension of Levensthein-matrix
		real scalar matrixDim
		real vector v
		v = iLength, jLength
		matrixDim = max(v)+1
		
		//Boundary of Levensthein-matrix
		real scalar bound
		bound = (iLength/jLength + jLength/iLength)/sqrt(iLength*iLength+jLength*jLength)
		bound = paramK * bound / sqrt(2)
		
		// Initialisation of Levensthein-matrix
		// Note: Levensthein as vector and initialized with infinity
		real matrix L
		L = J(matrixDim*matrixDim, 1, .)
		L[1,1]=0
		for(i=1; i<matrixDim; i++) {
			L[i+1,1]=L[i,1] + indelcost
			if(i<matrixDim) {
				L[i*matrixDim+1,1]=L[((i-1)*matrixDim)+1,1] + indelcost
			}
		}
		
		// Control variables for loop over second sequence
		real scalar j1
		real scalar j2
		real scalar j3
		
		j1=1
		j2=jLength +1
		j3=jLength +1
		
		// 1. loop: the first sequence
		for(i=1; i<iLength+1; i++) {
			help1 = (i)/iLength
			help2 = (jLength+1)*(help1-bound)
			help3 = (jLength+1)*(help1+bound)
			
			// Values of control variables for loop for the second sequence
			if(help2 <= 2) {
                j1 = 1
            }
			else {
                j1 = floor(help2)
            }
			
			if(help3>=jLength+1) {
                j2 = jLength +1
            }
			else {
                j2 = floor(help3)
            }
			
			// Coordinates for Levensthein-matrix(vector)
			index1 = (i-1)*matrixDim + j1
			index2 = index1 + matrixDim
			
			// 2. loop: the second sequence
			for(j=j1; j<j2; j++) {
				
				// Substitution 
                distance = SQsubcost[R[1,i],C[1,j]]  				
                distance = distance + L[index1, 1]
                index1++
				
				// Insertion
				if(j>j1 || j==1) {
					inser = indelcost + L[index2, 1]
					if(distance>inser) {
						distance= inser
					}
                }
                index2++
				
                // Deletion
                if(j<j3) {
					del = indelcost+L[index1, 1]
					if(distance>del) {
						distance=del
					}
					L[index2,1]=distance
				}
				j3=j2
			}
		}
		return(distance/(standard=="longer" ? max((cols(R),cols(C))):1))
	}
	
	
	// ---------------------------------------------------------------
	// Extract the sequence-length
	real scalar sqlength(transmorphic rowvector X)
	
	{
		real scalar i 
		real scalar col
		
		for (i=1;i<=cols(X);i++) {
			if (X[1,i] != missingof(X))  col=i 
		}
		return(col)
	}
	
	// -----------------------------------------------------------------
	// Save Distance Matrix
	void sqomsave(string Dname)
	{
		real matrix D
		real scalar fh
		
		D=st_matrix("SQdist")

		fh = fopen(Dname, "w")
		fputmatrix(fh, D)
		fclose(fh)
	}


	// Push Distance Matrix from file to SQdist
	void sqompush(string Dname)
	{
		real matrix D
		real scalar fh
		
		fh = fopen(Dname, "r")
		D = fgetmatrix(fh)
		fclose(fh)

		st_matrix("SQdist",D)

	}


	// Compile into a libary
	mata mlib create lsq, replace
	mata mlib add lsq                   ///
	  sqomref() sqomfull()              /// <- Callers
	  needlemanwunschexactfixed()       /// <- Exact NW with fixed subcost 
	  needlemanwunschexactrawdist()     /// <- Exact NW with rawdist       
	  needlemanwunschexactmatrix()      /// <- Exact NW with subcost matrix
	  needlemanwunschapproxfixed()      /// <- Approx. NW with fixed subcost 
	  needlemanwunschapproxrawdist()    ///	<- Approx. NW with rawdist       
	  needlemanwunschapproxmatrix()     /// <- Approx. NW with subcost matrix
	  sqlength()                        /// <- Extract Sequence Length
	  sqomsave()                          /// <- Save Distance to file
	  sqompush()                          /// <- Retrive Distance from file
	

  mata mlib index
    
end
exit
    
Support:
kohler@wz-berlin.de

