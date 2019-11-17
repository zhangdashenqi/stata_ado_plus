*! version 1.1.4  12apr2016, hacked by Mead Over
*! based on version 1.0.5  02jun2010, by Vince Wiggins
program grc1leg2
	version 12  //  added by MO
	syntax [anything] [, LEGendfrom(string)				///
			     POSition(string) RING(integer -1) SPAN	///
			     NAME(passthru) SAVing(string asis)   ///
				 XTOB1title XTItlefrom(string) LSize(string) * ]  //  options added by MO

	gr_setscheme , refscheme	// So we can have temporary styles

					// location and alignment in cell
	tempname clockpos
	if ("`position'" == "") local position 6
	.`clockpos' = .clockdir.new , style(`position')
	local location `.`clockpos'.relative_position'

	if `ring' > -1 {
		if (`ring' == 0) {
			local location "on"
			local ring ""
		}
		else	local ring "ring(`ring')"
	}
	else	local ring ""

	if "`span'" != "" {
		if "`location'" == "above" | "`location'" == "below" {
			local span spancols(all)
		}
		else	local span spanrows(all)
	}

					// allow legend to be from any graph
	if "`legendfrom'" != "" {			
		local lfrom : list posof "`legendfrom'" in anything
		if `lfrom' == 0 {
		    di as error `"`legendfrom' not found in graph name list"'  //  typo fixed by MO
		    exit 198
		}
	}
	else	local lfrom 1		// use graph 1 for legend by default

	graph combine `anything' , `options' `name' nodraw   // combine graphs


	if "`name'" != "" {				// get graph name
		local 0 `", `name'"'
		syntax [, name(string) ]
		local 0 `"`name'"'
		syntax [anything(name=name)] [, replace]
	}
	else	local name Graph

	forvalues i = 1/`:list sizeof anything' {	// turn off legends
		_gm_edit .`name'.graphs[`i'].legend.draw_view.set_false
		_gm_edit .`name'.graphs[`i'].legend.fill_if_undrawn.set_false

		if "`xtob1title'"~="" {  // turn loff xaxis1 titles (by M. Over)
			_gm_edit .`name'.graphs[`i'].xaxis1.title.draw_view.set_false
		}
	}
		
							// insert overall legend
	.`name'.insert (legend = .`name'.graphs[`lfrom'].legend)	    ///
			`location' plotregion1 , `ring' `span' 

	_gm_log  .`name'.insert (legend = .graphs[`lfrom'].legend) 	    ///
			`location' plotregion1 , `ring' `span' 

	_gm_edit .`name'.legend.style.box_alignment.setstyle ,		    ///
		style(`.`clockpos'.compass2style')
		
*******************Hack by M. Over begins here*************************
							// use -xtitlefrom- xtitle as overall b1title
	if "`xtob1title'"=="" & "`xtitlefrom'"~="" {
		local xtob1title xtob1title
	}
	if "`xtob1title'"~="" {
							// allow b1title to be from any graph
		if "`xtitlefrom'" != "" {			
			local xfrom : list posof "`xtitlefrom'" in anything
			if `xfrom' == 0 {
				di as error `"`xtitlefrom' not found in graph name list"'
				exit 198
			}
		}
		else	local xfrom 1		// use graph 1 for xtitle by default

		.`name'.b1title = .`name'.graphs[`xfrom'].xaxis1.title
		_gm_log .`name'.b1title = .graphs[`xfrom'].xaxis1.title
		_gm_edit .`name'.b1title.draw_view.set_true

	}
/*							// Attempt to modify the size of the legend labels:
							// This code does successfully changes the tex size
							// in the graph editor dialogue, but does not change
							// the actual size of the label test.  
							// Thus we instead use Derek Wagner's code below.
	if "`lsize'"~="" {

		.`name'.legend.style.labelstyle.size.style.editstyle ,		    ///
			style(`lsize') editcopy

		_gm_log .`name'.legend.style.labelstyle.style.editstyle ,		    ///
			style(`lsize') editcopy
			
		_gm_edit .`name'.legend.style.labelstyle.style.editstyle ,		    ///
			style(`lsize') editcopy
					
	}
*******************Hack by M. Over ends here***************************/

	_gm_edit .`name'.legend.draw_view.set_true

							// hack to maintain serset reference counts
			// must pick up sersets by reference, they were 
			// -.copy-ied when the legend was created above
	forvalues i = 1/`.`name'.legend.keys.arrnels' {
	    if "`.`name'.legend.keys[`i'].view.serset.isa'" != "" {
			_gm_edit .`name'.legend.keys[`i'].view.serset.ref_n + 99

			.`name'.legend.keys[`i'].view.serset.ref = 		   ///
				.`name'.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
			_gm_log  .`name'.legend.keys[`i'].view.serset.ref = 	   ///
				.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
	    }
	    if "`.`name'.legend.plotregion1.key[`i'].view.serset.isa'" != "" {
			_gm_edit						   ///
				.`name'.legend.plotregion1.key[`i'].view.serset.ref_n + 99

			.`name'.legend.plotregion1.key[`i'].view.serset.ref =  ///
				.`name'.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
			_gm_log							   ///
				.`name'.legend.plotregion1.key[`i'].view.serset.ref =  ///
				.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
	    }
*******************Hack by Derek Wagner begins here*************************
		** changes made here to account for -lsize- option
		
		if "`lsize'"~="" {

			.`name'.legend.plotregion1.label[`i'].style.editstyle ///
				size(`lsize') editcopy

			_gm_log .`name'.legend.plotregion1.label[`i'].style.editstyle ///
				size(`lsize') editcopy

			_gm_edit .`name'.legend.plotregion1.label[`i'].style.editstyle ///
				size(`lsize') editcopy	
		}
*******************Hack by Derek Wagner ends here***************************

	}

	gr draw `name'					// redraw graph

	if `"`saving'"' != `""' {
		gr_save `"`name'"' `saving'
	}


end


program GetPos
	gettoken pmac  0 : 0
	gettoken colon 0 : 0

	local 0 `0'
	if `"`0'"' == `""' {
		c_local `pmac' below
		exit
	}

	local 0 ", `0'"
	syntax [ , Above Below Leftof Rightof ]

	c_local `pmac' `above' `below' `leftof' `rightof'
end
* Version 1.0.5 (21feb2015): renamed for packaging with AIDSCost (no other changes)
* Version 1.1.0 (30mar2016): add the -xtob1title- and -xtitlefrom()- options
* Version 1.1.1 (1apr2016): make -xtitlefrom()- imply the -xtob1title- option
* Version 1.1.2 (8apr2016): Attempt to add a size option to the legend
*	The value of the option -lsize- appears in the graph editor under
*	legend/properties/labels/size, but has no effect on the actual size of the labels
* Version 1.1.3 (11apr2016): Incorporates Derek Wagner's suggestion for how 
*	to add asize option to the legend
* Version 1.1.4 (12apr2016): Fixes bug in xtitlefrom() option
