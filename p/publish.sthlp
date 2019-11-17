{smcl}
{* *! version 0.3.0 - 19jan2013}{...}
{cmd:help publish}
{hline}
{* index publish tt}{...}

{marker top}{...}

{title:Title}

{pstd} {cmd:publish} - Publication quality tables in a single document{p_end}


{title:Overview}

{col 5}{hline 70}
{col 7}What to do?{col 50}Reference
{col 5}{hline 70}

{col 7}{opt Begin and end your work}
{col 9}Open the document for use{col 50}{bf:{help publish##open:publish open}}
{col 9}Close the file{col 50}{bf:{help publish##open:publish close}}

{col 7}{opt Create a table containing....}
{col 9}definitions of variables {col 50}{bf:{help publish##des:publish describe}}
{col 9}summary statistics for variables{col 50}{bf:{help publish##sum:publish summarize}}
{col 9}one-way tables of frequencies{col 50}{bf:{help publish##tab1:publish tab1}}
{col 9}two-way tables of frequencies{col 50}{bf:{help publish##tab2:publish tab2}}
{col 9}tables displaying summary statistics{col 50}{bf:{help publish##table:publish table}}
{col 9}estimation results{col 50}{bf:{help publish##est:publish est}}
{col 9}part of the data in memory{col 50}{bf:{help publish##data:publish data}}
{col 9}contents of a matrix {col 50}{bf:{help publish##matrix:publish matrix}}
{col 9}nothing (an empty table) {col 50}{bf:{help publish##empty:publish empty}}

{col 7}{opt Control the layout of tables}{col 50}{bf:{help publish##layout:{it:common_layout_options}}}

{col 7}{opt Update the publish package}{col 50}{bf:{help publish##update:{it:update_info}}}

{col 5}{hline 70}

{title:Description}

{pstd}
{cmd:publish} allows you to create a document which contains publication quality tables. Main features are as follows

{p 8 12 2}
1.	Not only estimation results, but tables containing data, summary statistics, frequencies may be created.

{p 8 12 2}
2.	The document created can contain as many table as you wish. You first has to open a document using {cmd:publish open}; then
you can use any of the commands listed above. When ready, you complete your work by typing {cmd:publish close}.

{p 8 12 2}
3.	{cmd:publish} may create standard html, Microsoft Office compatible html as well as plain latex documents.  

{p 8 12 2}
4.	Although each subcommands have their own options, there is a set of common options for controlling the appearance of the tables. 
For details, consult the {help publish##layout:{it:common_layout_options}}.

{pstd} {p_end}

{pstd} {p_end}
{marker top}{bf:{help publish##top:Top of the help file}}
{hline}
{pstd} {p_end}

{marker open}{...}
{title:Title}

{pstd} Opening and closing the file for use{p_end}

{title:Syntax}

{p 8 18 2}
{cmd:publish open} {it:filename} [{cmd:,} {it:options} ] 

{p 8 18 2}
{cmd:publish close}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt as(format)}} Sets the format of the document to be created{p_end}
{synopt :{opt from(name)}} Uses {it:name} as a template file{p_end}
{synopt :{opt title(text)}} Sets the title of the document{p_end}
{synopt :{opt replace}} Overwrites {it:filename} {p_end}
{synopt :{opt append}} Appends new tables at the end of {it:filename} {p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:publish open} selects the document which will contain the tables you wish to create by subsequent {cmd:publish} commands. 
{cmd:publish open} does two things: first, it writes the the source code of an empty document to {it:filename}; second, it creates some global macros for subsequent use.
{cmd:publish close} closes the file; it adds some lines of codes indicating end of the file and clears the global macros created by {cmd:publish open}.

{title:Options}

{phang}
{opt as(format)} sets the format of the document to be created. Available formats are:

{col 9}{it:format}{col 20}Description
{col 9}{hline 65}
{col 9}{cmd:html}{col 20}Standard HTML format.
{col 9}{cmd:doc} {col 20}MS Office 2000 compatible HTML format
{col 9}{cmd:tex} {col 20}Plain LaTex format
{col 9}{hline 65}

{p 8 8 2}
If you do not specify this option, file format is determined by the extension you specified in {it:filename}. If you do not specify any extension, html is assumed. 

{phang}
{opt from(name)} selects the template file, where {it:name} is 

{p 8 12 2}
o
either a full filename specification or 

{p 8 12 2}
o
a keyword such that the file publish_{it:format}_{it:name}.style can be found along the adopath.

{p 8 8 2}
Template files determine the font sizes and spacing of all the texts appearing in the tables, as well as of the captions.
If you do not specify this option, the default template file, shipped with the {cmd:publish} package, is used. The default template files are

{col 9}Template file name{col 40}Description
{col 9}{hline 65}
{col 9}{cmd:publish_html_default.style}{col 40}Template for HTML files.
{col 9}{cmd:publish_doc_default.style}{col 40}Template for doc files.
{col 9}{cmd:publish_tex_default.style}{col 40}Template for Latex files.
{col 9}{hline 65}


{phang}
{opt title(text)} sets the title of the document. The usefulness of adding a title depends on file format. 
For instance, the title of a html document is displayed in by web browsers.  

{phang}
{opt replace} forces {cmd:publish} to overwrite {it:filename} if it exists.{p_end}

{phang}
{opt append} forces {cmd:publish} to appends the new ables at the end of {it:filename}.
{p_end}


{marker top}{bf:{help publish##top:Top of the help file}}


{hline}
{marker des}{...}

{title:Title}

{pstd}Definition of variables{p_end}

{title:Syntax}

{p 8 18 2}
{cmd:publish}  {opt des:cribe} [{it:varlist}]

{title:Description}

{pstd}{cmd:publish} {opt des:cribe} creates a table displaying the definitions of each variables in {it:varlist}. 
The table has two columns. 
The first column displays the variable labels of variables, if they exist. (In the absence of variable label, the variable name is displayed.)
The second column displays the definition in terms of value labels and notes.

{pstd}Users of {cmd:publish} are encouraged to attach coincise variable labels to variable names. 
More detailed explanations of continuous variables (e.g., unit of measurement, operational definition) should be placed in notes. 
The detailed definition of categorical variables should be provided by appropriate value labels, and, if necessary, by notes.


{bf:{help publish##top:Top of the help file}}


{hline}
{marker sum}{...}

{title:Title}

{pstd}Summary statistics for variables{p_end}

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt sum:marize} [{it:varlist}]  {ifin} {weight} [, {it:options} {help publish##layout:{it:common_layout_options}} ] 


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opt stat:istics(statlist)}} report specified statistics{p_end}
{synopt :{opt by(varname)}} group statistics by {it:varname}{p_end}
{synopt :{opt tot:al}} Display statistics in the whole sample{p_end}
{synoptline}
{pstd}
{it:varlist} may contain factor variables; see {help fvvarlist:fvvarlist}.
{p_end}


{title:Description}

{pstd}{cmd:publish} {opt sum:marize} creates a table displaying summary statistics, similar to the official {help summarize:summarize} command.

{title:Options}

{phang}
{opt stat:istics(statlist)} specifies the statistics to be displayed. If the by option is not specified, the default is equivalent to specifying {cmd:statistics(N mean sd)}; otherwise the default is is equivalent to specifying {cmd:statistics(N mean sd)}. Multiple statistics may be specified and are separated by white space.
Available statistics are
{p_end}


{synoptset 15 tabbed}{...}
{synopt:{space 4}{it:statname}}definition{p_end}
{space 4}{synoptline}
{synopt:{space 4}{cmd:N}}Number of observations{p_end}
{synopt:{space 4}{cmd:mean}}mean{p_end}
{synopt:{space 4}{cmd:skewness}}skewness {p_end}
{synopt:{space 4}{cmd:min}}minimum{p_end}
{synopt:{space 4}{cmd:max}}maximum{p_end}
{synopt:{space 4}{cmd:sum_w}}sum of the weights{p_end}
{synopt:{space 4}{cmd:p1}}1st percentile {p_end}
{synopt:{space 4}{cmd:p5}}5th percentile {p_end}
{synopt:{space 4}{cmd:p10}}10th percentile {p_end}
{synopt:{space 4}{cmd:p25}}25th percentile {p_end}
{synopt:{space 4}{cmd:p50}}50th percentile {p_end}
{synopt:{space 4}{cmd:p75}}75th percentile {p_end}
{synopt:{space 4}{cmd:p90}}90th percentile {p_end}
{synopt:{space 4}{cmd:p95}}95th percentile {p_end}
{synopt:{space 4}{cmd:p99}}99th percentile {p_end}
{synopt:{space 4}{cmd:Var}}variance{p_end}
{synopt:{space 4}{cmd:kurtosis}}kurtosis {p_end}
{synopt:{space 4}{cmd:sum}}sum of variable{p_end}
{synopt:{space 4}{cmd:sd}}standard deviation{p_end}
{space 4}{synoptline}
{p2colreset}{...}

{phang}
{opth by(varname)} causes {cmd:publish} to display the requested statistics separately for each unique value of {it:varname}.
   it:varname} must be numeric. For instance, {cmd:publish sum price} would present
   descriptive statistics for price in the whole sample; {cmd:publish sum price, by(foreign)} would present
   the descriptives for price separately for domestic and foreign cars. Do not confuse the {opt by()} option with the {helpb by} prefix; the latter may
   not be specified.

{phang}
{opt tot:al} causes {cmd:publish} to display the requested statistics for the whole sample. 
You do not need to specify this option if you do not specify the {opt by(varname)} option.{p_end}


{bf:{help publish##top:Top of the help file}}


{hline}
{marker tab1}

{title:Title}

{pstd}Frequency distributions

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt tab2} [{it:varlist}]  {ifin} {weight} [, {it:options} {help publish##layout:{it:common_layout_options}} ] 


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt by(varname)}} group frequency distributions by {it:varname}{p_end}
{synoptline}


{title:Description}

{pstd}{cmd:publish} {opt tab1} creates a table displaying univariate frequency distributions for each variable in {it:varlist}. 


{title:Options}

{phang}
{opth by(varname)} causes {cmd:publish} to display the requested frequency distributions separately for each unique value of {it:varname}.
   it:varname} must be numeric. For instance, {cmd:publish tab1 rep78} would present the distribution of rep78 in the whole sample; 
   {cmd:publish tab1 rep78, by(foreign)} would present the distributions separately for domestic and foreign cars. 
   Do not confuse the {opt by()} option with the {helpb by} prefix; the latter may not be specified.


{bf:{help publish##top:Top of the help file}}


{hline}
{marker tab2}

{title:Title}

{pstd}Two-way and three-way tables of frequencies

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt tab2} [{it:varlist}]  {ifin} {weight} [, {it:options} {help publish##layout:{it:common_layout_options}} ] 


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt c:ontents(cname varname)}} contents of table cells{p_end}
{synopt :{opt by(varname)}} group frequency distributions by {it:varname}{p_end}
{synoptline}


{title:Description}

{pstd}{cmd:publish} {opt tab2} creates a table presenting two and three dimensional contingency tables. 
  The row variables of the contingency tables are the elements of {it:varlist}. The column variables are defined by the {opt c:ontents(cname varname)} option.
  Three dimensional tables can be obtained by specifying the {opt by(varname)} option.

{pstd}For instance, typing

{phang2}
{cmd: . publish tab2 {it:var1} {it:var2} , contents(freq {it:cvar}) }  

{p 8 8 2}
produces the same output as typing the commands

{phang2}
{cmd: . tab {it:var1} {it:cvar} }
  
{phang2}
{cmd: . tab {it:var2} {it:cvar} }


{title:Options}

{phang}
{opt c:ontents(cname varname)} is mandatory; it specifies the column variable of the contingency table as well as the contents of table cells. Available contents are

{synoptset 15 tabbed}{...}
{synopt:{space 4}{it:cname}}definition{p_end}
{space 4}{synoptline}
{synopt:{space 4}{cmd:freq}}frequencies{p_end}
{synopt:{space 4}{cmd:col}}column percentages{p_end}
{synopt:{space 4}{cmd:col}}row percentages{p_end}
{space 4}{synoptline}
{p2colreset}{...}

{phang}
{opth by(varname)} causes {cmd:publish} to display the requested tables separately for each unique value of {it:varname}.
   it:varname} must be numeric. For instance, {cmd:publish tab2 rep78 , contents(freq pricecat)} would crosstabulate rep78 with pricecat 
   (any categorized transformation of price) in the whole sample; 
   {cmd:publish tab2 rep78 , contents(freq pricecat) by(foreign)} would present the crosstabulation separately for domestic and foreign cars. 
   Do not confuse the {opt by()} option with the {helpb by} prefix; the latter may not be specified.


{bf:{help publish##top:Top of the help file}}


{hline}
{marker table}

{title:Title}

{pstd}Tables displaying summary statistics

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt table} [{it:varlist}]  {ifin} {weight} [, {it:options} {help publish##layout:{it:common_layout_options}} ] 

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth c:ontents(table##clist:clist)}}contents of table cells; select
      up to five statistics; default is {cmd:contents(freq)}{p_end}
{synopt :{opt by(varname)}} group frequency distributions by {it:varname}{p_end}
{synopt :{opt tot:al}} Display statistics in the whole sample{p_end}
{synoptline}

{title:Description}

{pstd}{cmd:publish} {opt table} creates a table of summary statistics, similar to the official {help table} command. Typing

{phang2}
{cmd: . publish table {it:var1} {it:var2} , contents({it:clist}) [ by({it:byvar}) ] }  

{p 8 8 2}
produces the same output as typing the commands

{phang2}
{cmd: . table {it:var1} [ {it:byvar} ] , contents({it:clist}) }
  
{phang2}
{cmd: . table {it:var2} [ {it:byvar} ] , contents({it:clist}) }  


{title:Options}

{phang}
{opth "contents(table##clist:clist)"} specifies the contents of the table's cells. For a detailed explanation, see {help table}.

{phang}
{opth by(varname)} causes {cmd:publish} to display the requested statistics separately for each unique value of {it:varname}.
   it:varname} must be numeric. Note that {it:varname} is equivalent to {it:colvar} in the {help table} command. For instance

{phang2}
{cmd: . publish table rep78 , contents(mean mpg mean price) by(foreign) }  

{p 8 8 2}
produces the same output as

{phang2}
{cmd: . table rep78 foreign , contents(mean mpg mean price) }

{phang}
{opt tot:al} causes {cmd:publish} to display the requested statistics for the whole sample. 
You do not need to specify this option if you do not specify the {opt by(varname)} option.{p_end}


{bf:{help publish##top:Top of the help file}}


{hline}
{marker est}

{title:Title}

{pstd}Tables displaying estimation results

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt est} {it:estlist} [, {it:options} {help publish##layout:{it:common_layout_options}} ] 

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth var:list(varlist)}}report coefficients in order specified (mandatory).{p_end}
{synopt :{opt asis}}prevents unabbreviation of {it:varlist}{p_end}
{synopt :{opt nocons:tant}}suppress the constant term{p_end}
{synopt :{opt t}}report t or z values (default) {p_end}
{synopt :{opt se}}report standard errors{p_end}
{synopt :{opt ci}}report conficence intervals{p_end}
{synopt :{opt p}}report p-values{p_end}
{synopt :{opt level(#)}}set confidence level; default is {cmd:level(}95{cmd:{)}{p_end}
{synopt :{opt long}}display standard errors (or t-statistics...) below the coefficients{p_end}
{synopt :{opt wide}}display standard errors (or t-statistics...) next to the coefficients{p_end}
{synopt:{opt star}[{cmd:(}{it:#1 #2 #3}{cmd:)}]}use stars to denote significance levels{p_end}
{synopt:{opt stat:istics(statlist)}}report model statistics in table{p_end}
{synoptline}
{pstd}

{p 4 4 2}
where 

{p 8 12 2}
o
A {it:estlist} is a list of names under which estimation results were stored using {help estimates_store:estimates store}.

{p 8 12 2}
o
{it:varlist} may contain factor variables (see {help fvvarlist:fvvarlist})

{p 8 12 2}
o
A {it:stalist} is a list of the sequence {it:name} ["{it:label}"], 
where {it:name} is a names of scalar stored in {cmd:e()} and the optional {it:label} is used to label {cmd:e({it:name})} {it:label} instead of {it:name}.

{p 8 12 2}
o
A {it:stalist} is a list of the sequence {it:name} ["{it:label}"], 
where {it:name} is a names of scalar stored in {cmd:e()} and the optional {it:label} is used to label {cmd:e({it:name})} {it:label} instead of {it:name}.

{p 8 12 2}
o
{it:#1} {it:#2} {it:#3} are three numbers such as {cmd:.05} {cmd:.01} {cmd:.001}.


{title:Description}

{pstd}
{cmd:publish} {cmd:est} arranges coefficients and statistics for one or more 
sets of estimation results into a single table.


{title:Options}

{phang}
{cmd:varlist(}{it:varlist}{cmd:)} is mandatory; 
it specifies the variables for which results be displayed in the table. 
{it:varlist} also specifies the order in which coefficients appear.
{it:varlist} may include factor variables.

{phang}
{opt asis} forces {cmd:publish} to use {it:varlist} as it was typed by the user.
    This option prevents the unabbreviation of factor variables, if any. 
    You do not need to specify this option if your {it:varlist} is free from factor variable notation.

{phang}
{opt nocons:tant} suppresses the constant term. The default behavior is to display the coefficients of the constant.

{phang}
{cmd:se}, {cmd:t}, {cmd:ci} and {cmd:p} specify that standard errors, {it:t} or 
    {it:z} statistics, confidence intervals (more precisely, half of the difference between the upper and lower bound of the confidence interval) and significance levels are to be displayed.
    The default is to display {it:t} or {it:z} statistics. Note that these statistics are displayed in parentheses.

{phang}
{opt level(#)} set confidence level as a percentage, for confidence intervals. The default is {cmd:level(}95{cmd:)} or as set by {help level:set level}.
     This option takes effect only if you also specify {opt ci}.

{phang}
{opt long} and {opt wide} control where to display standard errors or or {it:t}-statistics etc. 
     {opt long} specifies that standard errors be displayed below the coefficients.
     {opt wide} specifies that standard errors be displayed next to the coefficients.
	 By default, {cmd:publish} decides on the layout: if the table has more than four columns, the long format is chosen;
	 otherwise the wide layout is selected.

{phang}
{cmd:star(}{it:#1 #2 #3}{cmd:)} control the marking of significant coefficients with stars.
    One star (*) means that {it:p} < {it:#2}, two stars indicate (**) that {it:p} < {it:#2}, and three stars (***) mean that {it:p} < {it:#3}.
	If you do not specify this option, {cmd:star(.05} {cmd:.01} {cmd:.001}{cmd:)} is assumed.

{phang}
{opt stat:istics(statlist)} specifies one or more scalar statistics to be displayed and labeled in the table.  
	
{pmore}
{it:stalist} is a list of the sequence {it:name} ["{it:label}"], 
where {it:name} is a names of scalar stored in {cmd:e()} and the optional {it:label} is used to label {cmd:e({it:name})} {it:label} instead of {it:name}.
For instance, specifying

{phang2} 
{cmd:statistics(N r2)}

{pmore}after a linear regression model requests number of observations and r-squared be displayed. In the table, these statistics will be labeled as N and r2. To improve the label for r2, you may wish to type

{phang2} 
{cmd:statistics(N r2 "R-squared")}

{pmore}Labels may contain special characters being part of the source code of the document. For instance, you might prefer to see "R" followed by 2 in the superscript, instead of "R-squared". If you are creating an HTML document, you may type

{phang2} 
{cmd:statistics(N r2 "R<sup>2</sup>")}

{pmore}
where <sup> and </sup> are the HTML codes for superscript. If you are working with Latex, you may type

{phang2} {cmd:statistics(N r2 "R^2")}

{pmore}
where ^ is the Latex code for superscipt.




{bf:{help publish##top:Top of the help file}}


{hline}
{marker data}

{title:Title}

{pstd}Tables displaying part of data in memory

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt data} {it:varlist}  {ifin}  [ , {it:options} {help publish##layout:{it:common_layout_options}} ] 

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt row:names(varname | textlist)}}contents of the variable column (required){p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:publish} {opt data} creates a table displaying part of the data in memory. 
The rows and the columns of the data matrix are defined by {ifin} and {it:varlist}, respectively.

{title:Options}

{phang}
{opt row:names(varname | textlist)} is mandatory; it specifies the names of rows to be displayed. 
This option accepts either a {it:varname} or a list of texts, each item being enclosed in double quotes.

{title:Example}

{pstd}For purposes of illustration, pretend we were interested in displaying the mean of price by car type:

{col 10}{hline 30}
{col 10}foreign{col 30}price
{col 10}{hline 30}
{col 10}Domestic{col 30}6072.42
{col 10}Foreign{col 30}6384.68
{col 10}{hline 30}

{pstd}
Using {cmd:publish data}, this table can be created by typing the following commands

{phang2}
{cmd: . sysuse auto , clear }

{phang2}
{cmd: . collapse (mean) price , by(foreign) }

{phang2}
{cmd: . publish data price , rownames(foreign) }

{pstd}
Note that the last command could also have been

{phang2}
{cmd: . publish data price , rownames("Domestic" "Foreign") }


{bf:{help publish##top:Top of the help file}}


{hline}
{marker matrix}

{title:Title}

{pstd}Tables displaying contents of a matrix

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt mat:rix} {it:matname}  [ ,  {help publish##layout:{it:common_layout_options}} ] 


{title:Description}

{pstd}
{cmd:publish} {opt mat:rix} displays the contents of a matrix in a table. 
{it:matname} may be both an ordinary matrix and an r-class or e-class matrix. 

{title:Example}

{pstd}The example shows the creation of a table containing a correlation matrix, 


{phang2}
{cmd: . sysuse auto , clear }

{phang2}
{cmd: . correlate price mpg trunk }

{phang2}
{cmd: . publish matrix r(C)  }


{bf:{help publish##top:Top of the help file}}


{hline}
{marker empty}

{title:Title}

{pstd}Creating empty tables

{title:Syntax}

{p 8 18 2}
{cmd:publish} {opt empty} {it:matname}  [ , {it:options} {help publish##layout:{it:common_layout_options}} ] 

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt row:names(varname | textlist)}}labeling rows (required){p_end}
{synopt :{opt ctitle(textlist)}}labeling columns (required). This option is part of {it:common_layout_options}{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:publish} {opt empty} creates a table containing nothing except labels for rows and columns. 
This command might be useful
for combining some tables in your favourite word processor. 
Indeed, {cmd: publish empty} is intended for MS Office or Open Office users who to create a nonstandard table by selecting and moving parts of tables with the mouse.

{title:Options}

{phang}
{opt row:names(varname | textlist)} is mandatory; it specifies the names of rows to be displayed. 
This option accepts either a {it:varname} or a list of texts, each item being enclosed in double quotes.

{phang}
{opt ctitle(textlist)} is mandatory; it specifies the names of columns to be displayed. 
Although this option is part of {it:common_layout_options}, it is mentioned here because it must be specified.


{title:Example}

{pstd}
Some publications display means of and correlations among the variables. 
This nonstandard table can be created as follows. 
First we create the table containing the means and the table containing the correlation matrix separately:

{phang2}
{cmd: . sysuse auto , clear }

{phang2}
{cmd: . publish sum price mpg trunk }

{phang2}
{cmd: . correlate price mpg trunk }

{phang2}
{cmd: . publish matrix r(C)  }

{pstd}
Then we create an empty table where results from the above two tables can be combined:

{phang2}
{cmd: . publish empty , rownames("price" "mpg" "trunk") ctitle{"Mean" "price" "mpg" "trunk"}  }


{bf:{help publish##top:Top of the help file}}


{hline}
{marker layout}

{title:Title}

{p2colset 5 28 30 2}{...}
{phang}Common layout options for publish
{p2colreset}{...}


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Table}
{synopt:{opt tabwidth(#1)}}Control width of the table{p_end}
{synopt:{opt title(text)}}Control title of the table{p_end}

{syntab:Columns}
{synopt:{opt varwidth(#2)}}Control width of the variable column{p_end}
{synopt:{opt vtitle(text)}}Control the title of the variable column{p_end}
{synopt:{opt cwidth(numlist)}}Control width of the columns{p_end}
{synopt:{opt ctitle(textlist)}}Set column titles{p_end}
{synopt:{cmd:ndec(numlist)}}Set display format of numbers{p_end}

{syntab:Supercolumns}
{synopt:{opt sctitle(textlist)}}Set supercolumn titles{p_end}
{synopt:{opt scol(numlist)}}Control number of columns belonging to a supercolumn{p_end}

{synoptline}
{p2colreset}{...}

{p 4 4 2}
where 

{p 8 12 2}
o
A {it:numlist} is a list of numbers separated by blanks.

{p 8 12 2}
o
A {it:textlist} consists of quoted texts separated by blanks.


{title:Terminology}

{p 4 4 2}
{bf:1. Tables without supercolumns}. Consider the following table showing the mean and standard deviation of price and mpg.
{p_end}

{col 10}{hline 40} 
{col 10}Variables{col 30}Mean{col 40}Std. Dev.         
{col 10}{hline 40} 
{col 10}price{col 29}6165.3{col 42}2949
{col 10}mpg{col 31}21.3{col 45}6
{col 10}{hline 40} 

{p 4 4 2}
For {cmd:publish}, that table consists of two (not three) columns:  "Mean" and "Std. Dev.". The number of decimal places in the colums are 1 and 0, respectively. The table has no supercolumns. Its layout illustrates the following layout options:

{p 8 8 4}
{cmd:ctitle(}"Mean" "Std. Dev."{cmd:)} {cmd:ndec(}1 0{cmd:)}

{p 4 4 2}
{bf:2. Tables with supercolumns}. Consider the following table showing the mean and standard deviation of price and mpg by car type.
{p_end}

{col 10}{hline 55}
{col 10}Variables      Domestic Cars          Foreign Cars         
{col 10}             Mean    Std. Dev.      Mean    Std. Dev.         
{col 10}{hline 55} 
{col 10}price       6072.4     3097        6384.7    2621.9
{col 10}mpg           19.8       5         24.8         7
{col 10}{hline 55} 


{p 4 4 2}
For {cmd:publish}, that table consists of four (not five) columns:  "Mean", "Std. Dev.", "Mean" and "Std. Dev.". The respective number of decimal places in the colums are 1, 0, 1 and 0. The tables has two supercolumns, each of which consisting of two columns. Its layout illustrates the following layout options:

{p 8 8 4}
{cmd:scol(}2 2{cmd:)} {cmd:sctitle(}"Domestic Cars" "Foreign Cars"{cmd:)} {cmd:ctitle(}"Mean" "Std. Dev." "Mean" "Std. Dev.{cmd:)} {cmd:ndec(}1 0 1 0{cmd:)}

{pstd}
The column displaying the labels for rows is called the variable column.

{title:Options}

{dlgtab:Table}

{phang}
{opt tabwidth(#)} sets the width of the table as a percentage of page width. The default is 90 meaning 90 per cent of page width.

{phang}
{opt title(text)} specifies the caption to be displayed above the table.

{dlgtab:Columns}

{phang}
{opt varwidth(#)} sets the width of the variable column as a percentage of table width. 

{phang}
{opt title(text)} specifies the label for the column which contains the variable names

{phang}
{opt cwidth(numlist)} sets the width of each column. The default is to give equal spacing to all columns.

{phang}
{opt ctitle(textlist)} specifies the label for each column. By default, {publish} determines the labels given
available information.

{phang}
{opt ndec(numlist)} set the number of decimal places in each column separately.

{dlgtab:Supercolumns}

{phang}
{opt sctitle(textlist)} set supercolumn titles or modifies the existing titles, if any.

{phang}
{opt scol(numlist)} set or changes the number of columns belonging to a supercolumn. 
For example, {opt scol(1 3)} tells publish that the table should have two supercolumns, the first spanning one, the second spanning three columns.


{bf:{help publish##top:Top of the help file}}


{hline}
{marker update}

{title:Updating the publish package}

{pstd}
{cmd:publish} is written by Tamás Bartus (Corvinus University, Budapest, Hungary). 

{pstd}
Right now, {cmd:publish} is under beta testing. In case of problems, plese contact me via email: tamas.bartus@uni-corvinus.hu.

{pstd}
To download {cmd:publish}, type the following two commands from within Stata:

{phang2}
{cmd: . net from "http://web.uni-corvinus.hu/bartus/stata" }
  
{phang2}
{cmd: . net install publish , replace }  

{pstd}
You might also visit the above website and download the package in a single zip file. Unpacking and installing the package is then your own responsibility.


{bf:{help publish##top:Top of the help file}}

