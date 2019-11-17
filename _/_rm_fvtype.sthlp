{smcl}
{* *! version 2012-08-31 scott long}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_fvtype} {hline 2}
Returns information on the factor variable type of predictors in a regression
model by decoding the name of the variable when expanded in an estimation
command.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_fvtype}
	{cmd:,}
		rhs_beta({it:string-of-names})


{synoptset 27}{...}
{synopthdr}
{synoptline}
{synopt :{opt rhs_beta(names)}}{it:names}
are the column names from {bf:e(b)}.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:_rm_fvtype} is a programmer's tool that classifies the predictors whose
names are passed to the command.
It is used by _rm_modelinfo to parse the parameter names from e(b).
These are expanded from the specification of predictors in a model.
For example,

        logit lfp i.wc i.k5 age

    leads to:

        . mat list e(b)

        e(b)[1,8]
                   lfp:        lfp:        lfp:        lfp:        lfp:        lfp:
                    0b.          1.         0b.          1.          2.         3o.
                    wc          wc          k5          k5          k5          k5
        y1           0    .8222805           0  -1.5319647  -2.4723011           0

                   lfp:        lfp:

                   age       _cons
        y1  -.06030223   2.9812584

    If bnames contains the column names from e(b), then

        _rm_fvtype `bnames'

{pstd}
The returns list variables using their non-factor names (e.g., age, not c.age)
that are used in different ways in the model.
This information is useful in deciding how to generate and interpret
margins results which depend on the type of variable it is analyzing.
The types of variables are described unser {bf:Saved results}.

{marker options}{...}
{title:Options}

{pstd}
See {helpb _rm_rhsnames} for a way to extract the names needed for {opt rhs_beta(names)}.

{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:_rm_fvtype} saves in {cmd:s()}:

{p2colset 9 32 36 2}{...}
{pstd}Macros:{p_end}
{p2col :{cmd:s(rhs_core)}}unique set of variables on the rhs{p_end}
{p2col :{cmd:s(rhs_notfv)}}variables not used as factor variables{p_end}
{p2col :{cmd:s(rhs_fv)}}variables used as factor variables{p_end}
{p2col :{cmd:s(rhs_fvbin)}}variables used as i1. type factor variables{p_end}
{p2col :{cmd:s(rhs_fvcat)}}variables used as i2., i3., ... type factor variables{p_end}
{p2col :{cmd:s(rhs_fvint)}}variables used in # terms{p_end}
{p2col :{cmd:s(rhs_fvintself)}}variables used in # with themselves (e.g., c.age#c.age){p_end}
{p2col :{cmd:s(rhs_fvintselfonly)}}variables used in # only with self but no other variables
(e.g., not c.age#i.wc){p_end}
{p2col :{cmd:s(rhs_fvintother)}}variables used in # with other varvariables
(e.g., c.age#i.wc) {p_end}

{p2colreset}{...}

{title:Also see}

{pstd}
...: {hi:...}
INCLUDE help _rm_footer
