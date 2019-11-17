{smcl}
{hline}
{cmd:help: {helpb spcs2xt}}{space 55} {cmd:dialog:} {bf:{dialog spcs2xt}}
{hline}

{bf:{err:{dlgtab:Title}}}

{bf: spcs2xt: Convert Squared Cross Section to Panel Spatial Weight Matrix}

{bf:{err:{dlgtab:Syntax}}}
{phang}

{cmd: spcs2xt} {varlist} {cmd:,} {opt p:anel(numlist)} {opt t:ime(numlist)} {opt m:atrix(new_panel_weight_file)}

{bf:{err:{dlgtab:Description}}}

{p 2 2 2} {cmd: spcs2xt} creates or generates squared panel spatial weight matrix and file among neighbor locations, from squared Cross Section weight matrix, that already exists in stata dta file, for using in panel spatial regression analysis.{p_end}

{bf:{err:{dlgtab:Options}}}

{p 2 2 2}{cmd: time}: Number of time series in each cross section (must be balanced).{p_end}

{p 2 2 2}{cmd: matrix}: Specify name of new panel spatial weight matrix file as stata dta file, that will be created.{p_end}

{bf:{err:{dlgtab:Examples}}}

	{stata clear all}

	{stata use spcs2xt.dta, clear}

	{stata db spcs2xt}

	{stata spcs2xt v1 v2 v3 v4, time(4) matrix(W)}

{cmd:OR USE}

	{stata spcs2xt v*, time(4) matrix(W)}

	{stata mat list W}

	{stata mat list Wxt}

{p 2 2 2} The final shape of cross section and panel spatial weight matrix will be as follows:.{p_end}

  --------------------------
  |   {bf:1}      {bf:2}      {bf:3}      {bf:4}
  |-------------------------
  |   0      {bf:{red:1}}      {bf:{red:1}}      {bf:{red:1}}
  |   {bf:{red:1}}      0      {bf:{red:1}}      0
  |   {bf:{red:1}}      {bf:{red:1}}      0      {bf:{red:1}}
  |   {bf:{red:1}}      0      {bf:{red:1}}      0
  |-------------------------

            (1)               (2)               (3)               (4)         
    |-----------------|-----------------|-----------------|-----------------|
(1) |  0   0   0   0  |  {bf:{red:1}}   0   0   0  |  {bf:{red:1}}   0   0   0  |  {bf:{red:1}}   0   0   0  |
    |  0   0   0   0  |  0   {bf:{red:1}}   0   0  |  0   {bf:{red:1}}   0   0  |  0   {bf:{red:1}}   0   0  |
    |  0   0   0   0  |  0   0   {bf:{red:1}}   0  |  0   0   {bf:{red:1}}   0  |  0   0   {bf:{red:1}}   0  |
    |  0   0   0   0  |  0   0   0   {bf:{red:1}}  |  0   0   0   {bf:{red:1}}  |  0   0   0   {bf:{red:1}}  |
    |-----------------|-----------------|-----------------|-----------------|
(2) |  {bf:{red:1}}   0   0   0  |  0   0   0   0  |  {bf:{red:1}}   0   0   0  |  0   0   0   0  |
    |  0   {bf:{red:1}}   0   0  |  0   0   0   0  |  0   {bf:{red:1}}   0   0  |  0   0   0   0  |
    |  0   0   {bf:{red:1}}   0  |  0   0   0   0  |  0   0   {bf:{red:1}}   0  |  0   0   0   0  |
    |  0   0   0   {bf:{red:1}}  |  0   0   0   0  |  0   0   0   {bf:{red:1}}  |  0   0   0   0  |
    |-----------------|-----------------|-----------------|-----------------|
(3) |  {bf:{red:1}}   0   0   0  |  {bf:{red:1}}   0   0   0  |  0   0   0   0  |  {bf:{red:1}}   0   0   0  |
    |  0   {bf:{red:1}}   0   0  |  0   {bf:{red:1}}   0   0  |  0   0   0   0  |  0   {bf:{red:1}}   0   0  |
    |  0   0   {bf:{red:1}}   0  |  0   0   {bf:{red:1}}   0  |  0   0   0   0  |  0   0   {bf:{red:1}}   0  |
    |  0   0   0   {bf:{red:1}}  |  0   0   0   {bf:{red:1}}  |  0   0   0   0  |  0   0   0   {bf:{red:1}}  |
    |-----------------|-----------------|-----------------|-----------------|
(4) |  {bf:{red:1}}   0   0   0  |  0   0   0   0  |  {bf:{red:1}}   0   0   0  |  0   0   0   0  |
    |  0   {bf:{red:1}}   0   0  |  0   0   0   0  |  0   {bf:{red:1}}   0   0  |  0   0   0   0  |
    |  0   0   {bf:{red:1}}   0  |  0   0   0   0  |  0   0   {bf:{red:1}}   0  |  0   0   0   0  |
    |  0   0   0   {bf:{red:1}}  |  0   0   0   0  |  0   0   0   {bf:{red:1}}  |  0   0   0   0  |
    |-----------------|-----------------|-----------------|------------------


{p 2 2 2} After creating panel spatial weight matrix, you can use {helpb spautoreg} {opt (if installed)} to generate eigenvalues vector and standardized weight matrix.{p_end}

{bf:{err:{dlgtab:Author}}}

  {hi:Emad Abd Elmessih Shehata}
  {hi:Assistant Professor}
  {hi:Agricultural Research Center - Agricultural Economics Research Institute - Egypt}
  {hi:Email:   {browse "mailto:emadstat@hotmail.com":emadstat@hotmail.com}}
  {hi:WebPage:{col 27}{browse "http://emadstat.110mb.com/stata.htm"}}
  {hi:WebPage at IDEAS:{col 27}{browse "http://ideas.repec.org/f/psh494.html"}}
  {hi:WebPage at EconPapers:{col 27}{browse "http://econpapers.repec.org/RAS/psh494.htm"}}

{bf:{err:{dlgtab:spcs2xt Citation}}}

{p 1}{cmd:Shehata, Emad Abd Elmessih (2012)}{p_end}
{p 1 10 1}{cmd:SPCS2XT: "Convert Squared Cross Section to Panel Spatial Weight Matrix"}{p_end}

	{browse "http://ideas.repec.org/c/boc/bocode/s457348.html"}

	{browse "http://econpapers.repec.org/software/bocbocode/s457348.htm"}

{title:Online Help:}

{p 2 2 2}{cmd:* Spatial Cross Sections Models:}{p_end}
{p 4 4 4}{helpb gs2sls}, {helpb gs2slsar}, {helpb gs3sls}, {helpb gsp3sls},
{helpb spautoreg}, {helpb spgmm}, {helpb spmstar}, {helpb spmstard},
{helpb spmstardh}, {helpb spmstarh}, {helpb spregcs}, {helpb spregsac},
{helpb spregsar}, {helpb spregsdm}, {helpb spregsem}.{p_end}

{p 2 2 2}{cmd:* Spatial Panel Data Models:}{p_end}
{p 4 4 4}{helpb gs2slsarxt}, {helpb gs2slsxt}, {helpb spglsxt}, {helpb spgmmxt},
{helpb spmstardhxt}, {helpb spmstardxt}, {helpb spmstarhxt}, {helpb spmstarxt},
{helpb spregdhp}, {helpb spregdpd}, {helpb spregfext}, {helpb spreghetxt},
{helpb spregrext}, {helpb spregsacxt}, {helpb spregsarxt}, {helpb spregsdmxt},
{helpb spregsemxt}, {helpb spregxt}, {helpb spxttobit}.{p_end}

{p 2 2 2}{cmd:* Panel Data Models:}{p_end}
{p 4 4 4}{helpb xtregam}, {helpb xtregbem}, {helpb xtregbn}, {helpb xtregdhp},
{helpb xtregfem}, {helpb xtreghet}, {helpb xtregmle}, {helpb xtregrem},
{helpb xtregsam}, {helpb xtregwem}, {helpb xtregwhm}.{p_end}

{p 2 2 2}{cmd:* Spatial Weight Matrix:}{p_end}
{p 4 4 4}{helpb spcs2xt}, {helpb gs2slsarxt}, {helpb spweight}, {helpb spweightcs}, {helpb spweightxt}, {helpb xtidt}. {opt (if installed)}.{p_end}

{psee}
{p_end}

