{smcl}
{hline}
help for {cmd:adodev}, {cmd:adoind}, and {cmd:adofac}{right:(Roger Newson)}
{hline}


{title:Reorder ado-path for developers and other independent-minded users}

{p 8 21 2}
{cmd:adodev}

{p 8 21 2}
{cmd:adoind}

{p 8 21 2}
{cmd:adofac}


{title:Description}

{pstd}
{cmd:adodev} re-orders the {help adopath:ado-file path} to start with the Stata system folders
{cmd:UPDATES}, {cmd:BASE}, {cmd:.}, {cmd:PERSONAL}, {cmd:PLUS}, {cmd:SITE}, and {cmd:OLDPLACE},
in that order.
{cmd:adoind} re-orders the {help adopath:ado-file path} to start with the Stata system folders
{cmd:UPDATES}, {cmd:BASE}, {cmd:PERSONAL}, {cmd:PLUS}, {cmd:SITE}, {cmd:.}, and {cmd:OLDPLACE},
in that order.
{cmd:adofac} re-orders the {help adopath:ado-file path} to start with the Stata system folders
{cmd:UPDATES}, {cmd:BASE}, {cmd:SITE}, {cmd:.}, {cmd:PERSONAL}, {cmd:PLUS}, and {cmd:OLDPLACE},
in that order.
All these commands preserve any existing ordering between other folders
on the {help adopath:ado-file path}.
The {cmd:adodev} command was written for development work,
and allows the user to develop ado-files in the current folder.
The {cmd:adoind} command was written for independent-minded users,
who think that they can update packages faster than their Stata site administrators
(if any Stata site administrators exist).
The {cmd:adofac} command restores the factory setting of the ordering between system folders,
as defined in the manuals for {help version:Stata Version 10}.


{title:Examples}

{phang2}{cmd:.adopath}{p_end}
{phang2}{cmd:.adodev}{p_end}
{phang2}{cmd:.adopath}{p_end}
{phang2}{cmd:.adoind}{p_end}
{phang2}{cmd:.adopath}{p_end}
{phang2}{cmd:.adofac}{p_end}
{phang2}{cmd:.adopath}{p_end}


{title:Author}

{pstd}
Roger Newson, National Heart and Lung Institute, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:Also see}

{p 4 13 2}
Manual: {hi:[P] sysdir}
{p_end}
{p 4 13 2}
Online: help for {helpb adopath}, {helpb sysdir}
{p_end}
