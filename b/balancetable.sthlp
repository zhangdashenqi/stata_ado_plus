{smcl}
{* *! version 4.0 03nov2017}


{title:Title}

{phang}{bf:balancetable} {hline 2} Build a balance table (showing means and difference in means) and print it in a LaTeX file or an Excel file


{title:Syntax}

{phang}Basic syntax{p_end}

{p 8 16 2}{cmd:balancetable} {varname} {depvarlist} {cmd:using} {it:{help filename}} {ifin} [{cmd:,} {it:options}]

{pmore}where {varname} must be a variable taking values 0 and 1 only.{p_end}


{phang}Long syntax{p_end}

{p 8 16 2}{cmd:balancetable} {cmd:(}{it:column1}{cmd:)} [{cmd:(}{it:column2}{cmd:)} {it:...}] {depvarlist} {cmd:using} {it:{help filename}} {ifin} [{cmd:,} {it:options}]

{pmore}where {cmd:(}{it:column#}{cmd:)} can take either of these two forms:{p_end}
{pmore2}a. {cmd:(mean} [{it:{help if}}]{cmd:)}, or{p_end}
{pmore2}b. {cmd:(diff} {varname} [{it:{help if}}]{cmd:)}, where {varname} must be a variable taking values 0 and 1 only.{p_end}

{pmore}The long syntax can be used to show the means over several subsamples and/or when there is more than one treatment arm (see {help balancetable##remarks:Remarks} below).{p_end}


{pmore}For both syntaxes, {it:{help filename}} must be a LaTeX file (.tex) or an Excel file (.xls or .xlsx), and it can be preceded by the file path.{p_end}


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:{help balancetable##content:Content}}
{synopt :{opth vce(vcetype)}} specify the type of standard errors reported{p_end}
{synopt :{opth fe(varname)}} add fixed effects when computing the difference in means{p_end}
{synopt :{opth cov:ariates(varlist)}} add control variables when computing the difference in means{p_end}
{synopt :{opt stddiff} (*)} compute standardized differences{p_end}
{synopt :{opt observationscolumn} (*)} add an additional column with the sample size for each variable in {depvarlist}{p_end}

{syntab:{help balancetable##formatting:Formatting}}
{synopt :{opt ctitles(strlist)}} insert column titles (in quotes){p_end}
{synopt :{opt leftctitle(string)}} change the title in the leftmost column{p_end}
{synopt :{opt pval:ues}} print p-values instead of standard errors for the difference in means{p_end}
{synopt :{opt varla:bels}} use variable labels in the balance table{p_end}
{synopt :{opt varna:mes}} use variable names in the balance table{p_end}
{synopt :{opt wrap}[{cmd:(}{it:wrap_subopt}{cmd:)}]} wrap variable label if it is too long{p_end}
{synopt :{space 2}{it:#}} number of characters before wrapping{p_end}
{synopt :{space 2}{opt indent}} indent the second line{p_end}
{synopt :{opt nonum:bers}} do not print column numbers{p_end}
{synopt :{opt noobs:ervations}} do not print the number of observations for each subsample{p_end}
{synopt :{opth format(fmt)}} format numbers inside the table{p_end}

{syntab:{help balancetable##latex:LaTeX-specific}}
{synopt :{opt varwidth(string)}} set maximum length of variable label{p_end}
{synopt :{opt tabulary}} use the {cmd:tabulary} environment in LaTeX{p_end}
{synopt :{opt bookt:abs}} use the {cmd:booktabs} package in LaTeX{p_end}
{synopt :{opt prehead(string)}} add text before the table header{p_end}
{synopt :{opt posthead(string)}} add text after the table header{p_end}
{synopt :{opt prefoot(string)}} add text before the table footer{p_end}
{synopt :{opt postfoot(string)}} add text after the table footer{p_end}

{syntab:{help balancetable##output:Output}}
{synopt: {opt replace}} overwrite existing file{p_end}
{synoptline}
{pmore}(*) These options are not available with the long syntax{p_end}


{title:Description}

{pstd}
This command builds a balance table, to compare two subsamples according to a set of characteristics.
The first variable after the {cmd:balancetable} command (i.e. {varname}) must be the dummy indicating the two subsamples.{p_end}
{pstd}For each variable in {depvarlist}, {cmd: balancetable} does the following:{p_end}
{p 6 9 2}1. compute the mean and the standard deviation of the variable when {varname} is equal to 0, corresponding to column (1);{p_end}
{p 6 9 2}2. compute the mean and the standard deviation of the variable when {varname} is equal to 1, corresponding to column (2);{p_end}
{p 6 9 2}3. regress the variable in {depvarlist} on {varname} to compute the difference and the associated standard error (or p-value, if the appropriate option is specified), corresponding to column (3).{p_end}
{pstd}The same procedure is applied to all the variables in {depvarlist}, to produce the complete balance table.{p_end}

{pstd}
In addition, {cmd:balancetable} allows for the use of different types of standard errors, the use of fixed effects, the additions of control variables, as well as several formatting options, as explained below.{p_end}

{pstd}
The long syntax allows more control over the content of each column.
In particular, the user can add as many columns as desired, and these can be of two types:{p_end}
{p 6 9 2}a. type {cmd:(mean)}, containing the mean and the standard deviation of each variable in {depvarlist}, as in columns (1) and (2) with the basic syntax;{p_end}
{p 6 9 2}b. type {cmd:(diff)}, containing the difference between the subsamples indicated by {varname}, as well as the associated standard error (or p-value), as in column (3) with the basic syntax.{p_end}


{title:Options}

{marker content}{...}
{dlgtab:Content}

{phang}{opth vce(vcetype)} specifies the type of standard errors reported.
For instance, one could use {cmd: vce(robust)} or {cmd: vce(cluster} {it:clustvar}{cmd:)}.

{phang}{opth fe(varname)} includes fixed effects for {varname} when computing the coefficient in column (3).
Of course, if the {opt fe} option is specified, the number in column (3) will no longer be the difference between column (1) and column (2). 

{phang}{opth covariates(varlist)} includes covariates in {varlist} when computing the coefficient in column (3).
Of course, if the {opt covariates} option is specified, the number in column (3) will no longer be the difference between column (1) and column (2).

{phang}{opt stddiff} computes the standardized differences and adds them in a column next to column (3).
The standardized difference is computed as {cmd:[mean(t)-mean(c)]/[sqrt(var(t)+var(c))]},
where mean(t) and mean(c) are the mean of the variable of interest in the treatment group and control group respectively, while var(t) and var(c) are the variances in those two groups.

{phang}{opt observationscolumn} adds a fourth column, numbered (4), containing the sample size for each regression computed in column (3).
This number may vary across variables in {depvarlist}, depending on the number of missing values for each variable.

{marker formatting}{...}
{dlgtab:Formatting}

{phang}{opt ctitles(strlist)} is used to insert the titles of columns (1), (2), etc.
Each column title must be enclosed in quotes.
The titles will appear in the same order as they are written; to skip the title for one column, it is sufficient to open and close the quotes without any text in between ({cmd:""}) and then continue with the subsequent column title.

{phang}{opt leftctitle(string)} changes the title of the leftmost column, the one containing the variable names or labels (the default column name is "Variable").
This option is effective only if the option {opt ctitles} has been specified.

{phang}{opt pvalues} instructs {cmd: balancetable} to print p-values instead of standard errors in column (3) for the basic syntax or in {cmd:diff} type columns for the complex syntax.

{phang}{opt varlabels} includes variable labels in the balance table, instead of variable names.

{phang}{opt varnames} includes variable names in the balance table (this is the default).

{phang}{opt wrap} wraps labels in two lines when they are too long.
The maximum length of a variable label (maximum number of characters) is defined by the {opt varwidth} option (if the option is specified, otherwise it defaults to 32).
The option {it:#} sets the number of characters after which the label is wrapped (the default is 32 characters).
The option {opt indent} ensures that the second line is indented, to ease readability.
Even with the option {opt wrap}, labels can never take more than two lines.{p_end}

{phang}{opt nonumbers} does not print in the table column numbers, i.e. (1), (2), etc., which are included by default.{p_end}

{phang}{opt noobservations} does not print in the table the number of observations for each subsample, which are added by default at the bottom of the table.{p_end}

{phang}{opth format(fmt)} allows formatting numbers inside the table according to conventional Stata formatting (e.g. %#.#g, %#.#fc, etc.).

{marker latex}{...}
{dlgtab:LaTeX-specific}

{phang}These options apply only if the output is a LaTeX file, that is the {it:{help filename}} specified by the user has the .tex extension.{p_end}

{phang}{opt varwidth(string)} sets the length of the leftmost column of the table (the one with variable names or labels).
This option takes any valid measure in LaTeX (e.g. {it:10em}, {it:5pt}, {it:10cm}, etc.).
It is up to the user to make sure that this does not conflict with the length set in the {opt wrap} sub-options (e.g. {cmd: balancetable ..., wrap(20) vardwidth(10em)} would produce an ugly-looking table).{p_end}

{phang}{opt tabulary} prints the table using the {cmd:tabulary} environment in LaTeX, which allows for better spacing and text wrapping.
It is particularly useful when column titles are rather long. By default, {cmd:balancetable} uses the {cmd:tabular} environment in LaTeX.
Notice that this option requires using the {cmd:tabulary} package in the .tex file.

{phang}{opt booktabs} uses the horizontal lines provided with the {cmd:booktabs} package, which allows for enhanced quality of tables.
By default, {cmd:balancetable} uses the standard {cmd:\hline} command in LaTeX.
Notice that this option requires using the {cmd:booktabs} package in the .tex file.

{phang}{opt prehead(string)} inserts a string of text before the table header.
Remember that this is still within the {cmd:tabular} environment in LaTeX, meaning that the text must be chosen accordingly, i.e. using the correct number of "&" symbols and/or multicolumns, as well as "\\" at the end of each row.
Also remember that the total number of columns may increase to 5 or 6 when the options {opt stddiff} and/or {opt observationscolumn} are specified with the basic syntax,
while with the complex syntax the total number of columns depends on the number of parenthesis.

{phang}{opt postfoot(string)} inserts a string of text after the table header.
Remember that this is still within the {cmd:tabular} environment in LaTeX, meaning that the text must be chosen accordingly, i.e. using the correct number of "&" symbols and/or multicolumns, as well as "\\" at the end of each row.
Also remember that the total number of columns may increase to 5 or 6 when the options {opt stddiff} and/or {opt observationscolumn} are specified with the basic syntax,
while with the complex syntax the total number of columns depends on the number of parenthesis.

{phang}{opt prefoot(string)} inserts a string of text before the table footer.
Remember that this is still within the {cmd:tabular} environment in LaTeX, meaning that the text must be chosen accordingly, i.e. using the correct number of "&" symbols and/or multicolumns, as well as "\\" at the end of each row.
Also remember that the total number of columns may increase to 5 or 6 when the options {opt stddiff} and/or {opt observationscolumn} are specified with the basic syntax,
while with the complex syntax the total number of columns depends on the number of parenthesis.

{phang}{opt postfoot(string)} inserts a string of text after the table footer.
Remember that this is still within the {cmd:tabular} environment in LaTeX, meaning that the text must be chosen accordingly, i.e. using the correct number of "&" symbols and/or multicolumns, as well as "\\" at the end of each row.
Also remember that the total number of columns may increase to 5 or 6 when the options {opt stddiff} and/or {opt observationscolumn} are specified with the basic syntax,
while with the complex syntax the total number of columns depends on the number of parenthesis.

{marker output}{...}
{dlgtab:Output}

{phang}{opt replace} allows overwriting {it:{help filename}} if it already exists.


{marker remarks}{...}
{title:Remarks on the long syntax}

{pstd}
The long syntax allows a more refined control, by allowing the user to specify the content of each column inside the parenthesis.
The long syntax support two types of columns (that is, {cmd:mean} and {cmd:diff}), mimicking those used in the basic syntax.{p_end}

{pstd}
The {cmd:mean} column takes the form{p_end}

{phang2}{cmd:(mean} [{it:{help if}}]{cmd:)}{p_end}

{pstd}allowing the use of an optional {help if:if expression} to identify the subsample over which to calculate the mean and the standard deviations.{p_end}

{pstd}
The {cmd:diff} column takes the form

{phang2}{cmd:(diff} {varname} [{it:{help if}}]{cmd:)}{p_end}

{pstd}meaning that it requires specifying a {varname} (which must be binary) to identify the two subsamples to calculate the difference and the standard errors (and it also supports optional {help if:if expressions}  for a better control).{p_end}

{pstd}Therefore, the short syntax{p_end}

{phang2}{cmd:balancetable mytreatvar mydepvar_1 mydepvar_2 mydepvar_3} using "myfile.tex"{p_end}

{pstd}is equivalent to{p_end}

{phang2}{cmd:balancetable (mean if mytreatvar==0) (mean if mytreatvar==1) (diff mytreatvar) mydepvar_1 mydepvar_2 mydepvar_3} using "myfile.tex"{p_end}

{pstd}
The long syntax is especially useful in case of multiple treatments.
For instance, suppose we have an experiment with two treatment arms (A and B) and a control group, and we want to check the balance of each treatment arm versus the control group and the balance between treatment arms.{p_end}
{pstd}We could write

{phang2}{cmd:balancetable (mean if treatment==0) (mean if treatment==1) (mean if treatment==2) (diff treatment_A if treatment!=2) (diff treatment_B if treatment!=1) (diff treatment_A if treatment!=0) using "myfile.xls"}{p_end}

{pstd}where {cmd:treatment} is a variable that takes value 0 for the control group, value 1 for treatment A and value 2 for treatment B, while {cmd:treatment_A} and {cmd:treatment_B} are two dummy variables for treatment arms.

{pstd}
As mentioned above, {cmd:(diff)} type columns require the use of a binary (dummy) variable, and the command {cmd:balancetable} does not create them.
In the previous example, {cmd:treatment_A} and {cmd:treatment_B} must be created by the user, for instance in the following way:{p_end}

{pmore2}{cmd:gen treatment_A = treatment==1}{p_end}
{pmore2}{cmd:gen treatment_B = treatment==2}{p_end}

{pstd}
One final remark: {help if:if expressions} placed inside the parenthesis are complementary to the {ifin} conditions specified in the main argument of {cmd:balancetable}, that is {it:both} are applied to the relevant columns.{p_end}


{title:Examples}

{phang}{cmd:. balancetable subsample_dummy age sex income using "myfile.tex", ctitles("Control group" "Treatment group")}{p_end}

{phang}{cmd:. balancetable choice_dummy cov1 cov2 cov3 cov4 using "path/myfile.tex", vce(robust) pvalues ctitles("First group" "Second group" "Difference") tabulary}{p_end}

{phang}{cmd:. balancetable dummy cov1 cov2 cov3 cov4 using "myfile.tex", prefoot(" & This goes in column (1) & & This goes in column (3) \\")}{p_end}

{phang}{cmd:. balancetable dummy cov1 cov2 cov3 cov4 using "myfile.tex", stddiff postfoot("\multicolumn{5}{l}{postfoot can be used in this way to add table notes} \\")}{p_end}

{phang}{cmd:. balancetable treatment covariate1 covariate2 covariate3 using "filename.tex", wrap(15 indent) varwidth(15em)}{p_end}

{phang}{cmd:. balancetable treatment_dummy age sex income using "mydirectory/somefile.xlsx", replace}{p_end}

{phang}{cmd:. balancetable (mean if treat==0) (mean if treat==1) (mean if treat==2) (diff treat_A if treat!=2) (diff treat_B if treat!=1) (diff treat_A if treat!=0) using "myfile.xlsx", ///}{p_end}
{pmore}{cmd:ctitles( "Mean Control" "Mean treat A" "Mean treat B" "Treat. A vs Control") ///}{p_end}
{pmore}{cmd:varlabels replace}{p_end}

{phang}{cmd:. balancetable (mean if treat==0) (mean if treat==1) (diff treat) age sex income hh_members using "balance.tex" if followup1==1, nonumbers booktabs}{p_end}



