{smcl}
{* 22Dec2009}{...}
{cmd:help misschk}: Help for misschk - 2009-12-22
{hline}
{p2colset 4 14 14 2}{...}

{title:Overview}

{p 4 4 2 75}
The command {cmd:misschk} examines patterns of missing data for a set of variables.
pattern of missing data.

{title:Syntax}

{p 8 13 2}
{cmdab:misschk} [{varlist}]
{ifin}
{weight}
[{cmd:,}
{it:options}]
            ,   [GENerate(string)]  /// stub for indicator variables
                [dummy]             /// dummy indicator variables
                [replace]           /// replace variables if they exist
                [NONUMber]          /// . in table for missing, not #
                [NOSort]            /// Don't sort pattern list
                [help]              /// explain what is going on
                [SPace]             /// blank rather than _ if not missing
                [EXTmiss]           //  show extended missing // 1.1.0

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opt ext:miss}}Each type of extended missing values is indicated
with the letter for that missing value (e.g., {bf:c} for {bf:.c}). By
default all missing values are treated simply as missing and 
indicated by a {bf:.}.{p_end}

{synopt:{opt gen:erate(rootname)}}is the root for the variables created with
information about missing data. If this option is not used,
temporary variables are created that are deleted when the program is 
finsihed. The variables created are:

        {it:rootname}{bf:n} is the number of variables from the variable-list for which
            a given observation has missing data. For example, a value of 5 would
            mean that that observation had missing data for five of the variables
            in the list.

        {it:rootname}{bf:which} indicates the pattern of missing values. This is a
            string variable with a {bf:_} indicating valid data for a variable
            and a number indicating missing data for that variable. For
            example, {bf:_____ __8__ _} is the pattern in which there is no
            missing data for the first seven variables in the variablae
            list, missing data for the eighth, and no missing data for the
            ninth through eleventh variable.{p_end}

{synopt:{opt dummy}}requests that dummy variables be created for each 
variable in the variable list. The dummy variable begins with the 
stem specified with the {bf:gen()} options, then adds the name of the
variable. A value of 1 indicates missing data for that case, 0 indicates
data is not missing. For example, with the options {bf:gen(M_) dummy},
variables such as M_female M_income would be generated.{p_end}

{synopt:{opt nonumber}}specifies that a variable that has missing cases will be
indicated by a {bf:.} rather than by a single digit number corresponding
to the sequence number of that variable. For example, without the 
{bf:nonumber} option, a missing data pattern might look like
{bf:_2_4_ 6___} to indicate missing data in the 2nd, 4th and 6th
variables. With the {bf:nonumber} option, the pattern 
would be {bf:_._._ .___} .{p_end}

{synopt:{opt nosort}}specifies that the list of patterns of missing data
should not be sorted with the most common pattern listed first. With
{bf:nosort}, the patterns are listed according to the pattern, not the
frequency of missing data.{p_end}

{synopt:{opt replace}}replaces existing variables {it:rootname}{bf:n}
and {it:rootname}{bf:which} if they already exist.{p_end}

{synopt:{opt space}}indicates that in the summary table a space rather than 
a {bf:_} will be used to indicate when a variable does not have missing data.{p_end}


{synopt:{opt help}}requests a description of each part of the output.{p_end}

{synoptline}
INCLUDE help spost_footer
