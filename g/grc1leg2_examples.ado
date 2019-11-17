*!Version 1.0.1 11Apr2016 by Mead Over, Center for Global Development
*! Companion program to be executed by the help file: grc1leg2.sthlp
program grc1leg2_examples
	version 8.2
	if (_caller() < 8.2)  version 8
	else		      version 8.2

	set more off
	`0'
	
	capture prog drop grc1leg2
end

program Msg
	di as txt
	di as txt "-> " as res `"`0'"'
end

program Xeq
	di as txt
	di as txt `"-> "' as res _asis `"`0'"'
	`0'
end

program define NewFile 
	args fn
	capture confirm new file `fn'
	if _rc {
		di as txt "{p 0 2 2}"
		di "Example cannot be run because you already have a"
		di "file named {res:`fn'}"
		di "{p_end}"
		error 602
	}
end

program define NewName 
	args fn
	capture graph rename `fn' `fn'
	if _rc==0 {
		di as txt "{p 0 2 2}"
		di "Example cannot be run because you already have a"
		di "graph in memory named {res:`fn'}."
		di "Either drop this graph or simply click {stata graph drop _all}."
		di "{p_end}"
		di as err _n "graph `fn' already exists"
		exit 110
	}
end

**************************Begin Mead's Hacks***************************
program setup
	capture sysuse auto
	if _rc~=0 {
		Msg sysuse auto
		di as err "no; data in memory would be lost"
		di as err "First {stata clear:clear} your memory before running these examples"
		exit
	}
	foreach name in  ///
		grby3 grby5   ///
		grcomb3 grcomb5  ///
		panel1 panel2 panel3 ///
		grc13woxtob1 grc13 grc18  {
		
		NewName `name'
	}

	set more off
	Xeq sysuse auto
	Xeq gen byte qual = 1*(rep78<3)+2*(rep78==3)+3*(rep78>=4)
	Xeq lab def qual 1 "Low Score"  2  "Medium"  3  "High Score"
	Xeq lab value qual qual
	Xeq lab var qual "Quality: Mapping of rep78 into trichotomy"
	Xeq tab qual rep78
end

program grby3
*	NewName grby3  //  Checks for whether graphs exist have been moved to -setup-
	Xeq twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight ),  ///
			legend(col(1)) ///
			by(qual,  ///
				legend(pos(0) at(4))  ///
				title("Three panels, with legend in a hole")  ///
				subtitle("Use -twoway ..., by()- with -at(4) pos(5)-") ///
			)  ///
		name(grby3, replace)
end

program grby5
*	NewName grby5
	Xeq twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight ),  ///
			legend(col(1)) ///
			by(rep78,  ///
				legend(pos(0) at(6))  ///
				title("Five panels, with legend in a hole")  ///
				subtitle("Use -twoway ..., by()- with -at(6) pos(0)-") ///
			)   ///
		name(grby5, replace)

end

program make3panels
*	NewName panel1
*	NewName panel2
*	NewName panel3
	
	Xeq set graph off
	
	Xeq twoway  ///
		(scatter mpg weight if qual==1)  ///
		(lfit mpg weight if qual==1),  ///
			subtitle("Low Score")  ///
			legend(col(1) off) ///  The -col(1)- option is used by -grc1leg2-
			name(panel1, replace)

	Xeq twoway  ///
		(scatter mpg weight if qual==2)  ///
		(lfit mpg weight if qual==2),  ///
			subtitle("Medium")  ///
			legend(off) ///
			name(panel2, replace)

	Xeq twoway  ///
		(scatter mpg weight if qual==3)  ///
		(lfit mpg weight if qual==3),  ///
			subtitle("High Score")  ///
			legend(col(1) ring(0) pos(5) xoffset(40) )  ///
			name(panel3, replace)

	Xeq set graph on
	Xeq graph dir, memory // These named graphs are now in memory
end

program grcomb3
*	NewName grcomb3

	Xeq gr combine panel1 panel2 panel3,  ///
		xcommon ycommon      ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -gr combine ... `altshrinktitle', having specified"  ///
			"-ring(0) pos(5) xoffset(40)- on the last graph")  ///
		name(grcomb3, replace) 
	
end


program grcomb5
*	NewName grcomb5

	Xeq gr combine panel1 panel2 panel1 panel2 panel3,  ///
		xcommon ycommon      ///
		title("Five panels, with legend in a hole")  ///
		subtitle("Use -gr combine ... `altshrinktitle', having specified"  ///
			"-ring(0) pos(5) xoffset(40)- on the last graph")  ///
		name(grcomb5, replace) 
	
end

program grcomb8
*	NewName grcomb8

	Xeq gr combine panel1 panel2 panel1 panel3 panel1 panel2 panel1 panel2,  ///
		xcommon ycommon holes(5)    ///
		title("Eight panels, with legend in the middle")  ///
		subtitle("Use -gr combine ... `altshrinktitle', having specified"  ///
			"-ring(0) pos(5) xoffset(40)- on the fourth graph")  ///
		b1title("Weight")  ///
		name(grcomb8, replace) 

end

program grc13woxtob1
*	NewName grc13woxtob1

	Xeq grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5) legendfrom(panel1)    ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- `altshrinktitle'" /// 
			"without the option -xtob1title-")  ///
		name(grc13woxtob1, replace)

end

program grc13
*	NewName grc13

	Xeq grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5) legendfrom(panel1)    ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- `altshrinktitle'" /// 
			"with the option -xtob1title-")  ///
		xtob1title  ///
		name(grc13, replace)

end

program grc13lsize
*	NewName grc13lsize

	Xeq grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5) legendfrom(panel1)    ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)- `altshrinktitle'" /// 
			"with the option -xtob1title-")  ///
		xtob1title  lsize(large) ///
		name(grc13size, replace)

end

program grc18
*	NewName grc18

	Xeq grc1leg2 panel1 panel2 panel1 panel3 panel1 panel2 panel1 panel3,  ///
		xcommon ycommon ring(0) pos(0) holes(5) legendfrom(panel1)    ///
		title("Eight panels: with legend in middle")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(0) holes(5)-  "  ///
			"with the option -xtob1title-")  ///
		xtob1title  ///
		name(grc18, replace)

end
*	Version 1.0.0 by Mead Over 1Apr2016
*		Based on Stata's gr_example2.ado, version 1.4.4  27aug2014
*	Version 1.0.1 11Apr2016: Adds the program -grc13lsize-
