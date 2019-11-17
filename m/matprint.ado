*! Part of package matrixtools v. 0.2
*! Support: Niels Henrik Bruun, nhbr@ph.au.dk
* 2017-01-06 Rewritten 
program define matprint
	version 12.1
	syntax anything(name=matrixexpression) [using/]/*
		*/[,/*
			*/Style(string) /*
			*/Decimals(string) /*
			*/TItle(string) /*
			*/TOp(string) /*
			*/Undertop(string) /*
			*/Bottom(string) /*
			*/Replace /*
			*/noEqstrip /*
			*/Hidesmall(integer 0) /*
		*/]

	tempname matrixname
	matrix `matrixname' = `matrixexpression'

	capture mata: __decimals = `decimals'
	if _rc mata: __decimals = 2	
	if `=`hidesmall' <= 0' local hidesmall .
	
	// Returned lines lines are accessible from Mata in variable tbl
	mata: __lm = nhb_mt_labelmatrix()
	mata: __lm.from_matrix("`matrixname'")
	mata: __tbl = __lm.print(	"`style'",  __decimals, ///
								"`eqstrip'" == "", `hidesmall', ///
								"`title'", "`top'", "`undertop'", "`bottom'", ///
								"`using'", "`replace'" == "replace")
	capture mata: mata drop __decimals
	capture mata: mata drop __lm
	capture mata: mata drop __tbl
	end
