*! version 1.3.0 , may 98, Guy van Melle
*!
*! syntax:	hlTex  
*!
*! puts following texts in globals on graph 
*!
*! hlText1 hlText2 hlTexb1 hlTexb2 hlTextc hlTextl hlTextr
*!    top1    top2    bot1    bot2    corn    left   right
*!
*! called after <gph open> ---> a simple wrapper: <addtex [savefile]> 
*!
*! obeys magnification in $hlMmag (default 100)
*!
*! enhancements:	
*!
*!  1. individual mags for each text: 
*!     --> may start any text with mag(#) e.g. mag(110) or mag(60)
*!  2. may shift top and bot texts to the right (normally left-aligned)
*!     --> may follow mag() with shr(#) (# is approx the % shift)
*!  3. may shift left or right texts down (normally started on top line)
*!     --> isolated dots mean skip a line
*!  4. may present <legend> left or right 
*!     --> sym(list) contains the list of symbols
*!
*-------------
prog def hlTex
*-------------
*
  loc tmag=real("0$hlMag")
  if `tmag'==. | `tmag'==0 { glo hlMag 100 }
  if "$S_G1"=="" {
	loc txh 923
	loc txw 444
  }
  else {
	parse "$S_G1", parse(",")
	loc txh `9'
	loc txw `11'
  }
  gph pen 1
  loc dx= 400	/* away from each side */
*
* top: left align, shift if shr(#) ---
*
  loc y 0
  loc j 0
  while `j'<2 {
	loc j=`j'+1	  	
	loc tx ${hlText`j'}
	if "`tx'" != "" {
		goget "`tx'"
		gph font $S_1 $S_2		
		loc y= `y' + $S_1 * 1.5
		loc x=`dx' + $S_4 * 320
		gph text `y' `x' 0 -1 $S_3
	}
  }
*
* bottom: left align, shift if shr(#) ---
*
  loc y 23000
  loc j 0
  while `j'<2 {
	loc j=`j'+1	  
	loc tx ${hlTexb`j'}
	if "`tx'" != "" {
		goget "`tx'"	
		gph font $S_1 $S_2		
		loc y= `y'- $S_1 * 1.5
		loc x=`dx'+ $S_4 * 320
		gph text `y' `x' 0 -1 $S_3
	}
  }
*
* left and right (stack parsed words, if sym() glue legend symbols, nosho) ---
*
  loc nosho ~
  loc j 0
  while `j'<2 {
	loc j=`j'+1
	loc s= substr("lr",`j',1) 	/* left, right */
	loc tx ${hlTex`s'}
	if "`tx'" != "" {		
		loc y= 500		
		loc x= `dx'*(`j'==1)+(32000-`dx')*(`j'==2)
		loc a= (-1)^`j'
		goget "`tx'"	
		gph font $S_1 $S_2		
		loc dy = $S_1 * 1.5
		parse "$S_3", parse(" ")
		loc k 0
		while "`1'"!="" {
			loc y=`y'+`dy'
			if "`1'"!="." {
				if "$S_5"=="" {
					gph text `y' `x' 0 `a' `1'
				}
				else {
					loc k=`k'+1
					loc tx= substr("$S_5",`k',1)
					if "`tx'"=="`nosho'" { loc tx }
					if `j'==1 { loc tx= "`tx' `1'" }
					else      { loc tx= "`1' `tx'" }
					gph text `y' `x' 0 `a' `tx'
				}
			}
			mac shift
		}
	}
  }
*
* corner
*
  if "$hlTexc"!="" {
	goget "$hlTexc"
	gph font $S_1 $S_2		
	loc y=23000-`dx'
	loc x=32000-`dx'
	gph text `y' `x' 0 1 $S_3
  }  
*
* restore font
*
  gph font `txh' `txw'		
end
*--------------
prog def goget
*
	loc tx "`1'"
	loc mag=$hlMag
	if upper(substr("`tx'",1,4))=="MAG(" {
		loc tx= substr("`tx'",5,.)
		loc p =  index("`tx'",")")
		loc m = real(substr("`tx'",1,`p'-1))
		loc tx= substr("`tx'",`p'+1,.)
		if `m'>0 & `m'<. { loc mag `m' }
	}
	loc sh=index("`tx'","shr(")
	if `sh' {
		loc tx= substr("`tx'",`sh'+4,.)
		loc q =  index("`tx'",")")
		loc m = real(substr("`tx'",1,`q'-1))
		loc tx= substr("`tx'",`q'+1,.)
		if `m'>0 & `m'<. { loc sh `m' }
	}
	loc sy=index("`tx'","sym(")
	if `sy' {
		loc tx= substr("`tx'",`sy'+4,.)
		loc q =  index("`tx'",")")
		loc sy= substr("`tx'",1,`q'-1)
		loc tx= substr("`tx'",`q'+1,.)
	}
	else { loc sy }
	glo S_1= round(9.23*`mag',1) /* see gph fonts */
	glo S_2= round(4.44*`mag',1)
	glo S_3 `tx'
	glo S_4 `sh'
	glo S_5 `sy'
end
