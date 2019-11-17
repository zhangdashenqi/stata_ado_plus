{smcl}
{hline}
{cmd:help: {helpb xls2stata}}{space 55} {cmd:dialog:} {bf:{dialog xls2stata}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf: xls2stata: Import Excel Files into Stata}

{bf:{err:{dlgtab:Syntax}}}

{p 4 8 6}
{cmd:odbc load}, {opt dsn("Excel Files; DBQ=(path_of_excel_file_name)")} {opt table(sheet_name$)}

{bf:{err:{dlgtab:Description}}}

{p 4 8 6}
{cmd: xls2stata} Is a simple dialog box imports EXCEL files into STATA , the user must specify the workbook excel file name, and select the sheet name which will be converted and imported into stata.{p_end}

{bf:{err:{dlgtab:Examples}}}

	{stata clear all}

	{stata db xls2stata}

	{cmd: odbc load, dsn("Excel Files; DBQ=C:\xls2stata.xls") table(Sheet1$)}

	{cmd: odbc load, dsn("Excel Files; DBQ=C:\xls2stata.xls") table(Sheet1$) clear}

	{cmd: odbc load, dsn("Excel Files; DBQ=C:\xls2stata.xls") table(panel$) clear}

	{cmd: odbc load, dsn("Excel Files; DBQ=C:\xls2stata.xls") table(theil1$) clear}
 
	{cmd: odbc load, dsn("Excel Files; DBQ=C:\xls2stata.xls") table(theil2$) clear}
 
  {cmd: - Note that variables names are imported as typed either small or capital letters}

  {cmd: - Dont forget to put a sign dollar {cmd:$} at the end of sheet name}

{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:xls2stata Citation}}}

{phang}Shehata, Emad Abd Elmessih (2012){p_end}
{phang}{cmd:XLS2STATA: "Stata Module Dialog Box to Import Excel Files into Stata"}{p_end}

{psee}
{p_end}

