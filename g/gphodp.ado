* Stata programm to convert Stata graphics (.gph) 
* to Open Document Presentation (.odp)
* Peter Parzer (peter.parzer@med.uni-heidelberg.de)
* Version 1.1, 23.01.2007 (for Stata 9)

program gphodp
  version 9
  syntax anything(name=files id="input-filenames"), GENerate(string) [ STub(string) SCHeme(passthru) Fontface(string) Orientation(string) Pagesize(string) Margin(real 1.0) REPLACE]

  if "`stub'"=="" {
    local stub "Gph"
  }

  * check arguments
  if ~strmatch("`generate'","*.odp") {
    local generate "`generate'.odp"
  }
  if "`replace'"=="" {
    confirm new file `generate'
  }
  else {
    capture confirm new file `generate'
    if _rc==0 {
      display as text "(note: file `generate' not found)"
    }
  }

  * expand wildcards and check filenames
  local gphlist
  foreach f of local files {
    if substr("`f'",length("`f'")-3,.)~=".gph" {
      local f "`f'.gph"
    }
    local p: dir . files "`f'"
    local n: word count `p'
    if `n'==0 {
      display as error "file `f' not found"
      exit
    }
    local gphlist "`gphlist' `p'"
  }

  * some constants
  local hex "0123456789abcdef"
  local pt_per_cm = .39*72
  local cm_per_pt = 2.54/72
  local viewport = 2.54*1000/72

  * initialize some variables
  local color "#000000"
  local shading "#000000"
  local textcolor "#000000"
  local linewidth 1
  local current_x 0
  local current_y 0

  * check font option
  if "`fontface'"=="" {
    local fontface "Arial"
  }

  * check pagesize option
  if "`pagesize'"=="A4" {
    local pg_widht=841.7
    local pg_height=595.4
  }
  else if "`pagesize'"=="letter" {
    local pg_width=792.0
    local pg_height=612.0
  }
  else if "`pagesize'"=="legal" {
    local pg_width=1008.1
    local pg_height=612.0
  }
  else {
    * default page size is screen
    local pg_width=793.7
    local pg_height=595.3
  }

  * check orientation option
  if "`orientation'"=="portrait" {
    local tmp=`pg_width'
    local pg_width=`pg_height'
    local pg_height=`tmp'
  } 
  else {
    local orientation "landscape"
  }

  * check margin option
  if "`margin'" == "" {
    local margin = 72
  }
  else {
    local margin = `margin'*72
  }

  local xoff = `margin'
  local yoff = `pg_height'-`margin'

  * size of the graph
  local gr_width = `pg_width'-2*`margin'
  local gr_height = `pg_height'-2*`margin'

  * translate gph to ps
  tempname ps
  tempname xml
  tempname plg
  tempfile psfile
  tempfile xmlfile
  tempfile plgfile
  file open `xml' using "`xmlfile'", write text

  * translate each gph file to a drawing page

  foreach gphfile of local gphlist {
    graph use `gphfile', `scheme'
    quietly graph export `psfile', as(ps) replace fontface(`fontface')
    file open `ps' using "`psfile'", read text
    file read `ps' line

    * start a new page
    * local width = `p_width'
    * local height = `p_height'
    local page = substr("`gphfile'",1,length("`gphfile'")-4)
    file write `xml' `"<draw:page draw:name="`page'" draw:style-name="dp1" draw:master-page-name="Standard">"' _n

    * read drawing commands and translate to xml
    while 1 {
      file read `ps' line
      if r(eof) == 1 {
        continue, break
      }

      * parse tokens
      local i = 0
      while trim(`"`line'"') != "" {
        gettoken tok`i' line : line, match(par)
        local i=`i'+1
      }
      local n=`i'-1


      * parse commands:
      * on drawing commands check if pen changed, before all command execution
      if match("`tok`n''","S?*") {
        * if color, width or shading changed, find corresponding pen
        if "`color'"~="`penc`pen''" | "`linewidth'"~="`penw`pen''" | "`shading'"~="`pens`pen''" {
          local i 1
          while "`penc`i''"~="" {
            if "`penc`i''"=="`color'" & "`penw`i''"=="`linewidth'" & "`pens`i''"=="`shading'" {
              local pen `i'
              continue, break
            }
            local i = `i'+1
          }
          * if no pen found, create a new one
          if "`penc`i''"=="" {
            local pen `i'
            local penc`i' `color'
            local penw`i' `linewidth'
            local pens`i' `shading'
            local penf`i' "none"
          }
        }
      }

      * the most frequent commands: line width and colors
      * pen line width
      if "`tok0'" == "/Slw" {
        local linewidth `tok1'
        continue
      }

      * pen color
      else if match("`tok0'","/S?rgb") {
        local tok1: subinstr local tok1 "{" ""
        local tok3: subinstr local tok3 "}" ""
        local d = round(255*`tok1',1)
        local c = "#"+substr("`hex'",int(`d'/16)+1,1)+substr("`hex'",mod(`d',16)+1,1)
        local d = round(255*`tok2',1)
        local c = "`c'"+substr("`hex'",int(`d'/16)+1,1)+substr("`hex'",mod(`d',16)+1,1)
        local d = round(255*`tok3',1)
        local c = "`c'"+substr("`hex'",int(`d'/16)+1,1)+substr("`hex'",mod(`d',16)+1,1)

        if "`tok0'"=="/Ssrgb" {
          local shading `c'
        }
        else if "`tok0'"=="/Slrgb" {
          local color `c'
        }
        else {
          local textcolor `c'
        }
        continue
      }

      * draw a point: x y
      else if "`tok`n''" == "Spt" {
        local x0 = round(`xoff'+`tok0'*`xratio',.01)
        local y0 = round(`yoff'-`tok1'*`yratio',.01)
        local y1 = round(`y0'+`linewidth',.01)
        file write `xml' `"<draw:line draw:style-name="gr`pen'" svg:x1="`x0'pt" svg:y1="`y0'pt" svg:x2="`x0'pt" svg:y2="`y1'pt"/>"' _n
        continue
      }

      * draw a line: x0 y0 x1 y1
      else if "`tok`n''" == "Sln" {
        local x0 = round(`xoff'+`tok0'*`xratio',.01)
        local y0 = round(`yoff'-`tok1'*`yratio',.01)
        local x1 = round(`xoff'+`tok2'*`xratio',.01)
        local y1 = round(`yoff'-`tok3'*`yratio',.01)
        file write `xml' `"<draw:line draw:style-name="gr`pen'" svg:x1="`x0'pt" svg:y1="`y0'pt" svg:x2="`x1'pt" svg:y2="`y1'pt"/>"' _n
        continue
      }

      * moveto: x y
      else if "`tok`n''" == "Sm" {
        local current_x `tok0'
        local current_y `tok1'
        continue
      }

      * lineto: x y
      else if "`tok`n''" == "Sl" {
        if `current_x'~=`tok0' | `current_y'~=`tok1' {
          local x0 = round(`xoff'+`current_x'*`xratio',.01)
          local y0 = round(`yoff'-`current_y'*`yratio',.01)
          local x1 = round(`xoff'+`tok0'*`xratio',.01)
          local y1 = round(`yoff'-`tok1'*`yratio',.01)
          file write `xml' `"<draw:line draw:style-name="gr`pen'" svg:x1="`x0'pt" svg:y1="`y0'pt" svg:x2="`x1'pt" svg:y2="`y1'pt"/>"' _n
        }
        continue
      }

      * rectangle: x0 y0 x1 y1 fill
      else if "`tok`n''" == "Srect" {
        local w = round((`tok2'-`tok0')*`xratio',.01)
        local h = round((`tok3'-`tok1')*`yratio',.01)
        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio'-`h',.01)
        if `tok4' {
          local penf`pen' "solid"
        }
	* dont draw rectangles with background color
	if "`penc`pen''"~="`bg_color'" {
          file write `xml' `"<draw:rect draw:style-name="gr`pen'" svg:x="`x'pt" svg:y="`y'pt" svg:width="`w'pt" svg:height="`h'pt"/>"' _newline
	}
        continue
      }

      * circle: x y r fill
      else if "`tok`n''" == "Scc" {
        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio',.01)
        local r = round(`tok2'*`xratio',.01)
        local x0 = `x'-`r'
        local y0 = `y'-`r'
        local w = 2*`r'
        if `tok3' {
          local penf`pen' "solid"
        }
        file write `xml' `"<draw:circle draw:style-name="gr`pen'" svg:x="`x0'pt" svg:y="`y0'pt" svg:width="`w'pt" svg:height="`w'pt"/>"' _n
        continue
      }

      * triangle: x y r fill
      else if inlist("`tok`n''","Stri","Soldtri") {
        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio',.01)
        local r = round(`tok2'*`xratio',.01)
        local y0 = `y'-`r'
        local h = `r'*1.5
        local w = `r'*sqrt(3)
        local x0 = `x'-`w'/2
        local vx = round(`w'*`viewport',1)
        local vy = round(`h'*`viewport',1)
        local vc = round(`vx'/2,.01)
        if `tok3' {
          local penf`pen' "solid"
        }
        file write `xml' `"<draw:polygon draw:style-name="gr`pen'" svg:x="`x0'pt" svg:y="`y0'pt" svg:width="`w'pt" svg:height="`h'pt" svg:viewBox="0 0 `vx' `vy'" draw:points="0,`vy' `vx',`vy' `vc',0"/>"' _n
        continue
      }

      * diamond: x y r fill
      else if "`tok`n''" == "Sdia" {
        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio',.01)
        local r = round(`tok2'*`xratio',.01)
        local x0 = `x'-`r'
        local y0 = `y'-`r'
        local w = `r'*2
        local vw = round(`w'*`viewport',1)
        local vc = round(`w'*`viewport'/2,1)
        if `tok3' {
          local penf`pen' "solid"
        }
        file write `xml' `"<draw:polygon draw:style-name="gr`pen'" svg:x="`x0'pt" svg:y="`y0'pt" svg:width="`w'pt" svg:height="`w'pt" svg:viewBox="0 0 `vw' `vw'" draw:points="0,`vc' `vc',`vw' `vw',`vc' `vc',0"/>"' _n
        continue
      }

      * plus: x y r
      else if "`tok`n''" == "Splu" {
        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio',.01)
        local r = round(`tok2'*`xratio',.01)
        local x0 = `x'-`r'
        local y0 = `y'-`r'
        local x1 = `x'+`r'
        local y1 = `y'+`r'
        file write `xml' `"<draw:line draw:style-name="gr`pen'" svg:x1="`x0'pt" svg:y1="`y'pt" svg:x2="`x1'pt" svg:y2="`y'pt"/>"' _n
        file write `xml' `"<draw:line draw:style-name="gr`pen'" svg:x1="`x'pt" svg:y1="`y0'pt" svg:x2="`x'pt" svg:y2="`y1'pt"/>"' _n
        continue
      }

      * cross: x y r
      else if "`tok`n''" == "Scro" {
        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio',.01)
        local r = round(`tok2'*`xratio',.01)
        local x0 = `x'-`r'
        local y0 = `y'-`r'
        local x1 = `x'+`r'
        local y1 = `y'+`r'
        file write `xml' `"<draw:line draw:style-name="gr`pen'" svg:x1="`x0'pt" svg:y1="`y0'pt" svg:x2="`x1'pt" svg:y2="`y1'pt"/>"' _n
        file write `xml' `"<draw:line draw:style-name="gr`pen'" svg:x1="`x0'pt" svg:y1="`y1'pt" svg:x2="`x1'pt" svg:y2="`y0'pt"/>"' _n
        continue
      }

      * begin path: start new polygon
      else if "`tok`n''" == "Sbp" {
        quietly file open `plg' using "`plgfile'", write text replace
        local px = -1
        local py = -1
        local px0
        local py0
        local px1
        local py1
        continue
      }

      * path line x y: add point to polygon
      else if "`tok`n''" == "SPl" {
        if `px'~=`tok0' | `py'~=`tok1' {
          local px = `tok0'
          local py = `tok1'
          local x = round(`xoff'+`tok0'*`xratio',.01)
          local y = round(`yoff'-`tok1'*`yratio',.01)
          if "`px0'" == "" {
            local px0 = round(`xoff'+`current_x'*`xratio',.01)
            local px1 = `px0'
            local py0 = round(`yoff'-`current_y'*`yratio',.01)
            local py1 = `py0'
	    file write `plg' "`px0' `py0'" _n
          }
          local px0 = min(`px0', `x')
          local px1 = max(`px1', `x')
          local py0 = min(`py0', `y')
          local py1 = max(`py1', `y')
          file write `plg'  "`x' `y'" _n
        }
        continue
      }

      * end path: close polygon
      else if "`tok`n''" == "Sep" {
        file close `plg'
        local w = `px1'-`px0'
        local h = `py1'-`py0'
        local vw = round(`w'*`viewport',1)
        local vh = round(`h'*`viewport',1)
        if `tok0' {
          local penf`pen' "solid"
        }
        file write `xml' `"<draw:polygon draw:style-name="gr`pen'" svg:x="`px0'pt" svg:y="`py0'pt" svg:width="`w'pt" svg:height="`h'pt" svg:viewBox="0 0 `vw' `vh'" draw:points=""'
        file open `plg' using "`plgfile'", read text
        while 1 {
          file read `plg' line
          gettoken x line : line
          gettoken y line : line
          if r(eof)==1 | "`y'"=="" {
            continue, break
          }
          local vx = round((`x'-`px0')*`viewport',1)
          local vy = round((`y'-`py0')*`viewport',1)
          file write `xml' "`vx',`vy' "
        }
        file close `plg'
        file write `xml' `""/>"' _n
        continue
      }

      * draw text: x y angle size text
      else if match("`tok`n''","Stxt?") {
        * set text-alignment
        if "`tok5'"=="Stxtl" {
          local align = "start"
        }
        else if "`tok5'"=="Stxtc" {
          local align = "center"
        }
        else if "`tok5'"=="Stxtr" {
          local align = "end"
        }
        * round font size
        local tok3 = round(`tok3'*`xratio',1)
        * find font matching size, color and alignment
        if "`tok3'"~="`size`font''" | "`textcolor`font''"~="`textcolor'" | "`align`font''"~="`align'" {
          local i=1
	  local font=0
          while "`size`i''"~="" {
            if "`size`i''"=="`tok3'" & "`textcolor`i''"=="`textcolor'" & "`align`font''"=="`align'" {
	      local font=`i'
              continue, break
            }
            local i=`i'+1
          }
          * if no matching font found create new
	  if `font'==0 {
	    local size`i' `tok3'
	    local textcolor`i' `textcolor'
            local align`i' `align'
	  }
          local font `i'
        }

        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio'+`size`font''/4,.01)
        
        file write `xml' `"<draw:text-box draw:style-name="`tok5'" draw:text-style-name="P`font'""'

        * rotation angle
        if `tok2' {
          local y=`y'-3
          local x=`x'+`size`font''/2
          local tok2 = _pi/180*`tok2'
          file write `xml' `" draw:transform="rotate (`tok2') translate (`x'pt `y'pt)">"' _n
        }
        else {
          local y=`y'+3
          file write `xml' `" svg:x="`x'pt" svg:y="`y'pt">"' _n
        }

        * leading blanks
        local text = ltrim(`"`tok4'"')
        local blanks = length(`"`tok4'"')-length(`"`text'"')

        * remove escape chars before parentheses
        local text = subinstr(`"`text'"',"\(","(",.)
        local text = subinstr(`"`text'"',"\)",")",.)

        * change '<' character in text (has special xml meaning)
        local text = subinstr(`"`text'"',"<","&lt;",.)

        * in the ps-file some special characters are coded as octal numbers
        * we have to translate them back
        while regexm("`text'","\\[0-9][0-9][0-9]") {
          local s = regexs(0)
          local c = char(real(substr("`s'",2,1))*8^2+real(substr("`s'",3,1))*8+real(substr("`s'",4,1)))
          local text: subinstr local text "`s'" "`c'", all
        }

        if `blanks'>0 {
          file write `xml' `"<text:p text:style-name="P`font'"><text:s text:c="`blanks'"/>`text'</text:p>"' _n
        }
        else {
          file write `xml' `"<text:p text:style-name="P`font'">`text'</text:p>"' _n
        }
        file write `xml' `"</draw:text-box>"' _n
        continue
      }

      * pie: x y r a0 a1 fill
      else if "`tok`n''" == "Spie" {
        local x = round(`xoff'+`tok0'*`xratio',.01)
        local y = round(`yoff'-`tok1'*`yratio',.01)
        local r = round(`tok2'*`xratio',.01)
        local x0 = `x'-`r'
        local y0 = `y'-`r'
        local w = 2*`r'
        if `tok5' {
          local penf`pen' "solid"
        }
        file write `xml' `"<draw:circle draw:style-name="gr`pen'" svg:x="`x0'pt" svg:y="`y0'pt" svg:width="`w'pt" svg:height="`w'pt" draw:kind="section" draw:start-angle="`tok3'" draw:end-angle="`tok4'"/>"' _n
        continue
      }

      * seldom commands at the end
      * x and y aspect ratio in the postscript file
      if "`tok0'" == "/xratio" {
        local xratio=`tok1'
        continue
      }

      else if "`tok0'" == "/yratio" {
        local yratio=`tok1'
        continue
      }

      * background rectangle, we use it to position the graph
      * but we don't draw it.
      else if "`tok`n''"=="Sbgfill" {
        local st_width = round(`tok2',.01)
        local st_height = round(`tok3',.01)

        * change x and y ratio from postscript file
        local xratio = `xratio'*`gr_width'/`st_width'
        local yratio = `yratio'*`gr_height'/`st_height'
        continue
      }

      * background color
      else if `n'==3 & "`tok`n''"=="setrgbcolor" {
        local d = round(255*`tok0',1)
        local c = "#"+substr("`hex'",int(`d'/16)+1,1)+substr("`hex'",mod(`d',16)+1,1)
        local d = round(255*`tok1',1)
        local c = "`c'"+substr("`hex'",int(`d'/16)+1,1)+substr("`hex'",mod(`d',16)+1,1)
        local d = round(255*`tok2',1)
        local c = "`c'"+substr("`hex'",int(`d'/16)+1,1)+substr("`hex'",mod(`d',16)+1,1)
        local color `c'
        local shading `c'
        local bg_color `c'
        continue
      }
    * end of drawing commands
    }

    file close `ps'

    * close drawing page
    file write `xml' "</draw:page>" _n
  }
  file close `xml'

  * create content.xml
  tempfile xmldir
  qui shell mkdir `xmldir'
  tempname content
  file open `content' using "`xmldir'/content.xml", write text

  * write content header
  file write `content' `"<?xml version="1.0" encoding="ISO-8859-1"?>"' _n
  file write `content' `"<office:document-content"'
  file write `content' `" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0""'
  file write `content' `" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0""'
  file write `content' `" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0""'
  file write `content' `" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0""'
  file write `content' `" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0""'
  file write `content' `" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0""'
  file write `content' `" xmlns:xlink="http://www.w3.org/1999/xlink""'
  file write `content' `" xmlns:dc="http://purl.org/dc/elements/1.1/""'
  file write `content' `" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0""'
  file write `content' `" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0""'
  file write `content' `" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0""'
  file write `content' `" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0""'
  file write `content' `" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0""'
  file write `content' `" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0""'
  file write `content' `" xmlns:math="http://www.w3.org/1998/Math/MathML""'
  file write `content' `" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0""'
  file write `content' `" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0""'
  file write `content' `" xmlns:ooo="http://openoffice.org/2004/office""'
  file write `content' `" xmlns:ooow="http://openoffice.org/2004/writer""'
  file write `content' `" xmlns:oooc="http://openoffice.org/2004/calc""'
  file write `content' `" xmlns:dom="http://www.w3.org/2001/xml-events""'
  file write `content' `" xmlns:xforms="http://www.w3.org/2002/xforms""'
  file write `content' `" xmlns:xsd="http://www.w3.org/2001/XMLSchema""'
  file write `content' `" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance""'
  file write `content' `" xmlns:smil="urn:oasis:names:tc:opendocument:xmlns:smil-compatible:1.0""'
  file write `content' `" xmlns:anim="urn:oasis:names:tc:opendocument:xmlns:animation:1.0""'
  file write `content' `" office:version="1.0">"' _n
  file write `content' `"<office:scripts/>"' _n

  * write automatic styles
  file write `content' "<office:automatic-styles>" _n

  * text box automatic styles
  file write `content' `"<style:style style:name="Stxtl" style:family="graphics" style:parent-style-name="`stub'label">"' _n
  file write `content' `"<style:properties draw:textarea-horizontal-align="left" draw:textarea-vertical-align="bottom" draw:auto-grow-width="true" draw:auto-grow-height="true"/>"' _n
  file write `content' `"</style:style>"' _n
  file write `content' `"<style:style style:name="Stxtc" style:family="graphics" style:parent-style-name="`stub'label">"' _n
  file write `content' `"<style:properties draw:textarea-horizontal-align="center" draw:textarea-vertical-align="bottom" draw:auto-grow-width="true" draw:auto-grow-height="true"/>"' _n
  file write `content' `"</style:style>"' _n
  file write `content' `"<style:style style:name="Stxtr" style:family="graphics" style:parent-style-name="`stub'label">"' _n
  file write `content' `"<style:properties draw:textarea-horizontal-align="right" draw:textarea-vertical-align="bottom" draw:auto-grow-width="true" draw:auto-grow-height="true" fo:text-align="end"/>"' _n
  file write `content' `"</style:style>"' _n

  * graphic automatic styles
  local i 1
  while "`penc`i''"~="" {
    file write `content' `"<style:style style:name="gr`i'" style:family="graphics" style:parent-style-name="`stub'pen`i'"/>"' _n
    local i = `i'+1
  }

  * paragraph automatic styles
  local i 1
  while "`size`i''"~="" {
    file write `content' `"<style:style style:name="P`i'" style:family="paragraph" style:parent-style-name="`stub'label`i'">"' _n
    file write `content' `"<style:properties fo:font-size="`size`i''" fo:color="`textcolor`i''" fo:text-align="`align`i''"/>"' _n
    file write `content' `"</style:style>"' _n
    local i = `i'+1
  }
  file write `content' "</office:automatic-styles>" _n

  * drawing pages
  file write `content' `"<office:body>"' _n
  file open `xml' using "`xmlfile'", read text
  file read `xml' line
  while r(eof) == 0 {
    file write `content' `"`line'"' _n
    file read `xml' line
  }
  file close `xml'
  file write `content' "</office:body>" _n
  file write `content' "</office:document-content>" _n
  file close `content'

  * create style.xml
  tempname style
  file open `style' using "`xmldir'/styles.xml", write text

  * write style header
  file write `style' `"<?xml version="1.0" encoding="UTF-8"?>"' _n
  file write `style' `"<office:document-styles"'
  file write `style' `" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0""'
  file write `style' `" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0""'
  file write `style' `" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0""'
  file write `style' `" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0""'
  file write `style' `" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0""'
  file write `style' `" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0""'
  file write `style' `" xmlns:xlink="http://www.w3.org/1999/xlink""'
  file write `style' `" xmlns:dc="http://purl.org/dc/elements/1.1/""'
  file write `style' `" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0""'
  file write `style' `" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0""'
  file write `style' `" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0""'
  file write `style' `" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0""'
  file write `style' `" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0""'
  file write `style' `" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0""'
  file write `style' `" xmlns:math="http://www.w3.org/1998/Math/MathML""'
  file write `style' `" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0""'
  file write `style' `" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0""'
  file write `style' `" xmlns:ooo="http://openoffice.org/2004/office""'
  file write `style' `" xmlns:ooow="http://openoffice.org/2004/writer""'
  file write `style' `" xmlns:oooc="http://openoffice.org/2004/calc""'
  file write `style' `" xmlns:dom="http://www.w3.org/2001/xml-events""'
  file write `style' `" xmlns:smil="urn:oasis:names:tc:opendocument:xmlns:smil-compatible:1.0""'
  file write `style' `" xmlns:anim="urn:oasis:names:tc:opendocument:xmlns:animation:1.0""'
  file write `style' `" office:version="1.0">"' _n

  * styles
  file write `style' `"<office:styles>"' _n
  file write `style' `"<style:style style:name="`stub'label" style:family="graphics" style:parent-style-name="standard">"' _n
  file write `style' `"<style:properties draw:stroke="none" fo:font-family="`fontface'" draw:fill="none"/>"' _n
  file write `style' `"</style:style>"' _n
  local i 1
  while "`penc`i''"~="" {
    file write `style' `"<style:style style:name="`stub'pen`i'" style:family="graphics" style:parent-style-name="standard">"' _n
    file write `style' `"<style:properties fo:color="`penc`i''" draw:fill-color="`pens`i''" draw:fill="`penf`i''" svg:stroke-color="`penc`i''" svg:stroke-width="`penw`i''pt"/>"' _n
    file write `style' `"</style:style>"' _n
    local i = `i'+1
  }
  file write `style' `"</office:styles>"' _n

  * automatic styles
  file write `style' `"<office:automatic-styles>"' _n
  file write `style' `"<style:page-master style:name="PM0">"' _n
  file write `style' `"<style:properties fo:page-width="`pg_width'pt" fo:page-height="`pg_height'pt" style:print-orientation="`orientation'"/>"' _n
  file write `style' `"</style:page-master>"' _n
  file write `style' `"<style:style style:name="dp1" style:family="drawing-page">"' _n
  file write `style' `"<style:properties draw:background-size="border" "'
  file write `style' `"draw:fill="solid" draw:fill-color="`bg_color'"/>"' _n
  file write `style' `"</style:style>"' _n
  file write `style' `"</office:automatic-styles>"' _n

  * master styles
  file write `style' `"<office:master-styles>"' _n
  file write `style' `"<style:master-page style:name="Standard" style:page-master-name="PM0" draw:style-name="dp1"/>"' _n
  file write `style' `"</office:master-styles>"' _n

  file write `style' `"</office:document-styles>"' _n
  file close `style'

  * create manifest.xml
  quietly shell mkdir "`xmldir'/META-INF"
  tempname manifest
  file open `manifest' using "`xmldir'/META-INF/manifest.xml", write text
  file write `manifest' `"<?xml version="1.0" encoding="UTF-8"?>"' _n
  file write `manifest' `"<!DOCTYPE manifest:manifest PUBLIC "-//OpenOffice.org//DTD Manifest 1.0//EN" "Manifest.dtd">"' _n
  file write `manifest' `"<manifest:manifest xmlns:manifest="http://openoffice.org/2001/manifest">"' _n
  file write `manifest' `" <manifest:file-entry manifest:media-type="application/vnd.sun.xml.impress" manifest:full-path="/"/>"' _n
  file write `manifest' `" <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/>"' _n
  file write `manifest' `" <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml"/>"' _n
  file write `manifest' `"</manifest:manifest>"' _n
  file close `manifest'

  * create OpenOffice file
  quietly local gendir=c(pwd)
  quietly cd "`xmldir'"
  quietly shell zip -rm "`gendir'/`generate'" "."
  quietly cd "`gendir'"
  quietly shell rmdir `xmldir'

end
