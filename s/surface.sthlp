{smcl}
{* 30 May 2012}{...}
{cmd:help surface}
{hline}

{title:Title}

  {hi: Produce a Wireframe Surface plot}

{title:Syntax}

{p 8 27 2}
{cmdab:surface}
[{it:var1 var2 var3}]
[{cmd:,} {it:options}  {help twoway_options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt saving}(filename[, replace ])} saves the graph to a specified file name.{p_end}
{synopt:{opt round}(#)} specifies the precision of the x and y variables so that a wireframe can be drawn. {p_end}
{synopt:{opt labelround}(#)} specifies the precision of the x, y and z automatic axes labels. {p_end}
{synopt:{opt orient}(string)} specifies which axes should be the x, y and z-axes. {p_end}
{synopt:{opt nowire}} specifies that the data is plotted as a point and a dropline. {p_end}
{synopt:{opt xtitle}(string)} specifies the title for the x-axis. {p_end}
{synopt:{opt ytitle}(string)} specifies the title for the y-axis. {p_end}
{synopt:{opt ztitle}(string)} specifies the title for the z-axis.{p_end}
{synopt:{opt xlabel}(numlist)} specifies the labelling on the x-axis. {p_end}
{synopt:{opt ylabel}(numlist)} specifies the labelling on the y-axis. {p_end}
{synopt:{opt zlabel}(numlist)} specifies the labelling on the z-axis.{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
The function attempts to draw a wireframe plot from three variables.
{it:Var1} specifies the x-coordinate, {it:var2} the y-coordinate and {it:var3} the 
z-coordinate. Alternatively the function can draw a circle at each 
point and add a straight line going 
down to the lowest point.

{pstd}
This function can handle data that is not in the form of a matrix of values.
However if there are too many x- and y- values the function will attempt 
to {it:round} the dataset values into a more reasonable spread of values. This 
will result in very messy figures. However in such a case it is the 
impression that is needed. Many other statistical packages require a full 
matrix of values. This is not a problem using the {it:nowire} option.

{pstd}
At present the state of rotating the diagram is limited to interchanging the 
axes.

{title:Options}

{phang}
{cmdab:saving}{cmd:(}{it:filename} {it:[, replace ]}{cmd:)} this will save the resulting graph in filename.gph. If the file already exists then use the {it:replace} suboption.

{phang}
{cmdab:nowire} this suppresses the drawing of the wire frame in exchange for lines 

{phang}
{cmdab:round}{cmd:(}{it:#}{cmd:)}, data is automatically rounded if there are too many x and y values. This option controls the amount of rounding, for example round(1) rounds the x and y values to the nearest integer.

{phang}
{opt labelround}(#) specifies the precision of the x, y and z automatic axes labels. {p_end}

{phang}
{cmdab:orient}{cmd:(}{it:string} {cmd:)} this function must take the letters xyz or a combination of them. Whichever letter comes first is the x-axis, second is y-axis and third is 
the z-axis. Thus {bf:orient(zxy)} means that {it:var1} is now the y coordinates, {it:var2} 
is the z-coordinates and {it:var3} is the x-coordinates. This is different from 
changing the variables around since the wireframe is still draw across the 
original x and y values. This is a crude attempt to implement rotation to 
obtain a clearer picture.

{phang}
{cmdab:xtitle}{cmd:(}{it:string}{cmd:)} specifies the title for the X-axis, the default is "X-axis"

{phang}
{cmdab:ytitle}{cmd:(}{it:string}{cmd:)} specifies the title for the Y-axis, the default is "Y-axis"

{phang}
{cmdab:ztitle}{cmd:(}{it:string}{cmd:)} specifies the title for the Z-axis, the default is "Z-axis"

{phang}
{cmdab:xlabel}{cmd:(}{it:numlist}{cmd:)} specifies the labelling on the X-axis.

{phang}
{cmdab:ylabel}{cmd:(}{it:numlist}{cmd:)} specifies the labelling on the Y-axis.

{phang}
{cmdab:zlabel}{cmd:(}{it:numlist}{cmd:)} specifies the labelling on the Z-axis.

{title:Examples}

{phang}
{inp:surface x y z, saving(myfile) round(10) orient(zxy) }

{phang}
{inp:surface x y z, xtitle(my x title) ytitle(my y title) ztitle(my z title) saving(myfile,replace)}

{pstd}
An "immediate" example without using a dataset. Please click the commands in order to avoid
problems.

{phang}
{stata clear} <--- NOTE all data is removed you may want to preserve first{p_end}
{phang}
{stata set obs 900}{p_end}
{phang}
{stata gen x = int((_n - mod(_n-1,30) -1 ) /30 ) }{p_end}
{phang}
{stata gen y = mod(_n-1,30) }{p_end}
{phang}
{stata gen z =  normalden(x,10,3)*normalden(y,15,5)}{p_end}
{phang}
{stata surface x y z}{p_end}
{phang}
{stata surface x y z, zlabel(0 0.005 0.012) labelround(1) xtitle(X-variable)}{p_end}
{phang}
{stata surface x y z, zlabel(0 0.005 0.012) labelround(1) xtitle(X-variable) title(My surface plot)}{p_end}

{title:Author}

{pstd}
Adrian Mander, MRC Biostatistics Unit, Cambridge, UK.

{pstd}
Email {browse "mailto:adrian.mander@mrc-bsu.cam.ac.uk":adrian.mander@mrc-bsu.cam.ac.uk}

{title:See Also}

{pstd}
Other Graphic Commands I have written: {p_end}

{synoptset 27 }{...}
{synopt:{help batplot} (if installed)} {stata ssc install batplot}   (to install) {p_end}
{synopt:{help cdfplot} (if installed)} {stata ssc install cdfplot}   (to install) {p_end}
{synopt:{help contour} (if installed)}   {stata ssc install contour}     (to install) {p_end}
{synopt:{help drarea}  (if installed)}   {stata ssc install drarea}      (to install) {p_end}
{synopt:{help graphbinary} (if installed)}   {stata ssc install graphbinary} (to install) {p_end}
{synopt:{help metagraph} (if installed)}   {stata ssc install metagraph}   (to install) {p_end}
{synopt:{help palette_all} (if installed)}   {stata ssc install palette_all} (to install) {p_end}
{synopt:{help plotbeta} (if installed)}   {stata ssc install plotbeta}    (to install) {p_end}
{synopt:{help plotmatrix} (if installed)}   {stata ssc install plotmatrix}  (to install) {p_end}
{synopt:{help radar}  (if installed)}   {stata ssc install radar}     (to install) {p_end}
{synopt:{help trellis}  (if installed)}   {stata ssc install trellis}     (to install) {p_end}
{p2colreset}{...}






 

