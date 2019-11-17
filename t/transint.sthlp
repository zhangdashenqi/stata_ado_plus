{smcl}
{* 29nov2005/8nov2006/25jul2007}{...}
{hline}
Transformations: an introduction
{hline}

{p 4 4 2}
In data analysis {cmd:transformation} is the replacement of a variable
by a function of that variable: for example, replacing a variable x by
the square root of x or the logarithm of x. In a stronger sense, a
transformation is a replacement that changes the shape of a distribution
or relationship.  

{p 4 4 2}
This help does not pretend to be comprehensive or even generous on literature
citations.  Various references that I have found helpful are sprinkled here and
there. Two that have particularly shaped my understanding are Emerson and Stoto
(1983) and Emerson (1983). Behind those articles lies the persistent emphasis
placed on the value of transformations in the work of John Wilder Tukey 
(1915{c -}2000). 

{p 4 4 2} 
This help item covers the following topics. You can read in sequence or
skim directly to each section. Starred sections are likely to appear
more esoteric or more difficult than the others to those new to the
subject. 

{p 8 8 2}Reasons for using transformations

{p 8 8 2}Review of most common transformations 

{p 8 8 2}Psychological comments {c -} for the puzzled 

{p 8 8 2}How to do transformations in Stata 

{p 8 8 2}* Transformations for proportions and percents 

{p 8 8 2}* Transformations as a family 

{p 8 8 2}* Transformations for variables that are both positive and
negative

{p 4 4 2}Typographical notes:

{p 8 8 2}^ means raise to the power of whatever follows.

{p 8 8 2}_ means that whatever follows should be considered a subscript
(written below the line).

{p 8 8 2}The Stata notation == for "is equal to" and != for "is not
equal to" are used for tests of various true-or-false conditions. 


{title:Reasons for using transformations}

{p 4 4 2}There are many reasons for transformation. The list here is
not comprehensive.

{space 8}1. Convenience
{space 8}2. Reducing skewness
{space 8}3. Equal spreads
{space 8}4. Linear relationships
{space 8}5. Additive relationships

{p 4 4 2}If you are looking at just one variable, 1, 2 and 3 are
relevant, while if you are looking at two or more variables, 4 and 5 are
more important.  However, transformations that achieve 4 and 5 very
often achieve 2 and 3.

{p 4 4 2}1. {cmd:Convenience} A transformed scale may be as natural as
the original scale and more convenient for a specific purpose (e.g.
percentages rather than original data, sines rather than degrees).

{p 4 4 2}One important example is {cmd:standardisation}, whereby values
are adjusted for differing level and spread. In general

{space 29}value - level
{space 8}standardised value = {hline 13}.
{space 32}spread

{p 4 4 2}Standardised values have level 0 and spread 1 and have no
units: hence standardisation is useful for comparing variables expressed
in different units. Most commonly a {cmd:standard score} is calculated
using the mean and standard deviation (sd) of a variable:

{space 12}x - mean of x
{space 8}z = {hline 13}.
{space 15}sd of x

{p 4 4 2}
Standardisation makes no difference to the shape of a distribution. 

{p 4 4 2}
2. {cmd:Reducing skewness} A transformation may be used to reduce
skewness.  A distribution that is symmetric or nearly so is often easier
to handle and interpret than a skewed distribution. More specifically, 
a normal or Gaussian distribution is often regarded as ideal as it is 
assumed by many statistical methods. 

{p 4 4 2}
To reduce right skewness, take roots or logarithms or reciprocals (roots
are weakest). This is the commonest problem in practice.

{p 4 4 2}
To reduce left skewness, take squares or cubes or higher powers.

{p 4 4 2}
3. {cmd:Equal spreads} A transformation may be used to produce
approximately equal spreads, despite marked variations in level, which
again makes data easier to handle and interpret. Each data set or subset
having about the same spread or variability is a condition called
{cmd:homoscedasticity}: its opposite is called {cmd:heteroscedasticity}.
(The spelling {cmd:-sked-} rather than {cmd:-sced-} is also used.)

{p 4 4 2}
4.  {cmd:Linear relationships} When looking at relationships between
variables, it is often far easier to think about patterns that are
approximately linear than about patterns that are highly curved. This is
vitally important when using linear regression, which amounts to fitting
such patterns to data. (In Stata, {help regress} is the basic command
for regression.)

{p 4 4 2}
For example, a plot of logarithms of a series of values against time has
the property that periods with {cmd:constant rates of change} (growth or
decline) plot as straight lines.

{p 4 4 2}
5. {cmd:Additive relationships} Relationships are often easier to
analyse when additive rather than (say) multiplicative. So

{space 8}y = a + bx

{p 4 4 2}
in which two terms a and bx are added is easier to deal with than

{space 8}y = ax^b

{p 4 4 2}
in which two terms a and x^b are multiplied. {cmd:Additivity} is a vital
issue in {cmd:analysis of variance} (in Stata, {help anova}, {help oneway}, 
etc.).

{p 4 4 2}
In practice, a transformation often works, serendipitously, to do
several of these at once, particularly to reduce skewness, to produce
nearly equal spreads and to produce a nearly linear or additive
relationship. But this is not guaranteed. 


{title:Review of most common transformations} 

{p 4 4 2}
The most useful transformations in introductory data analysis are the
reciprocal, logarithm, cube root, square root, and square. In what
follows, even when it is not emphasised, it is supposed that
transformations are used only over ranges on which they yield (finite)
real numbers as results. 

{space 4}{it:Reciprocal}

{p 4 4 2}
The {cmd:reciprocal}, x to 1/x, with its sibling the 
{cmd:negative reciprocal}, x to -1/x, is a very strong transformation
with a drastic effect on distribution shape. It can not be applied to
zero values.  Although it can be applied to negative values, it is not
useful unless all values are positive. The reciprocal of a ratio may
often be interpreted as easily as the ratio itself: e.g.

{p 8 8 2}
population density (people per unit area) becomes area per person;

{p 8 8 2}
persons per doctor becomes doctors per person;

{p 8 8 2}
rates of erosion become time to erode a unit depth.

{p 4 4 2}
(In practice, we might want to multiply or divide the results of taking
the reciprocal by some constant, such as 1000 or 10000, to get numbers
that are easy to manage, but that itself has no effect on skewness or
linearity.)

{p 4 4 2}
The reciprocal reverses order among values of the same sign: largest
becomes smallest, etc. The negative reciprocal preserves order among
values of the same sign.

{space 4}{it:Logarithm}

{p 4 4 2}
The {cmd:logarithm}, x to log base 10 of x, or x to log base e of x (ln
x), or x to log base 2 of x, is a strong transformation with a major
effect on distribution shape. It is commonly used for reducing right
skewness and is often appropriate for measured variables. It can not be
applied to zero or negative values. One unit on a logarithmic scale
means a multiplication by the base of logarithms being used. Exponential
growth or decline

{space 8}y = a exp(bx)

{p 4 4 2}
is made linear by

{space 8}ln y = ln a + bx

{p 4 4 2}
so that the response variable y should be logged. (Here exp() means
raising to the power e, approximately 2.71828, that is the base of
natural logarithms.)

{p 4 4 2}
An aside on this {cmd:exponential growth or decline} equation: put x =
0, and 

{space 8}y = a exp(0) = a,

{p 4 4 2}
so that a is the amount or count when x = 0. If a and b > 0, then y
grows at a faster and faster rate (e.g. compound interest or unchecked
population growth), whereas if a > 0 and b < 0, y declines at a slower
and slower rate (e.g. radioactive decay).

{p 4 4 2}
Power functions y = ax^b are made linear by log y = log a + b log x so
that both variables y and x should be logged.

{p 4 4 2}
An aside on such {cmd:power functions}: put x = 0, and for b > 0,

{space 8}y = ax^b = 0,
		 
{p 4 4 2}		 
so the power function for positive b goes through the origin, which
often makes physical or biological or economic sense. Think: does zero
for x imply zero for y? This kind of power function is a shape that fits
many data sets rather well.

{p 4 4 2}
Consider ratios y  = p / q where p and q are both positive in practice.
Examples are

{space 8}males / females;
{space 8}dependants / workers;
{space 8}downstream length / downvalley length. 

{p 4 4 2}
Then y is somewhere between 0 and infinity, or in the last case, between
1 and infinity. If p = q, then y = 1. Such definitions often lead to
skewed data, because there is a clear lower limit and no clear upper
limit. The logarithm, however, namely

{space 8}log y = log p / q = log p - log q,

{p 4 4 2}
is somewhere between -infinity and infinity and p = q means that log y =
0. Hence the logarithm of such a ratio is likely to be more
symmetrically distributed.

{space 4}{it:Cube root} 

{p 4 4 2}
The {cmd:cube root}, x to x^(1/3). This is a fairly strong
transformation with a substantial effect on distribution shape: it is
weaker than the logarithm. It is also used for reducing right skewness,
and has the advantage that it can be applied to zero and negative values. 
Note that the cube root of a volume has the units of a length. It is commonly
applied to rainfall data.

{p 4 4 2}Applicability to negative values requires a special note. Consider
(2)(2)(2) = 8 and (-2)(-2)(-2) = -8. These examples show that the cube root 
of a negative number has negative sign and the same absolute value as 
the cube root of the equivalent positive number. A similar property is 
possessed by any other root whose power is the reciprocal of an odd positive 
integer (powers 1/3, 1/5, 1/7, etc.). 

{p 4 4 2}This property is a little delicate. For example, change the power just
a smidgen from 1/3, and we can no longer define the result as a product of
precisely three terms. However, the property is there to be exploited if
useful. 

{space 4}{it:Square root}

{p 4 4 2}
The {cmd:square root}, x to x^(1/2) = sqrt(x), is a transformation with
a moderate effect on distribution shape: it is weaker than the logarithm
and the cube root. It is also used for reducing right skewness, and also
has the advantage that it can be applied to zero values. Note that the
square root of an area has the units of a length. It is commonly applied
to counted data, especially if the values are mostly rather small.

{space 4}{it:Square} 

{p 4 4 2}
The {cmd:square}, x to x^2, has a moderate effect on distribution shape
and it could be used to reduce left skewness. In practice, the main
reason for using it is to fit a response by a quadratic function y = a +
b x + c x^2. Quadratics have a turning point, either a maximum or a
minimum, although the turning point in a function fitted to data might
be far beyond the limits of the observations. The distance of a body
from an origin is a quadratic if that body is moving under constant
acceleration, which gives a very clear physical justification for using
a quadratic. Otherwise quadratics are typically used solely because they
can mimic a relationship within the data region. Outside that region
they may behave very poorly, because they take on arbitrarily large
values for extreme values of x, and unless the intercept a is
constrained to be 0, they may behave unrealistically close to the
origin.

{p 4 4 2}
Squaring usually makes sense only if the variable concerned is zero or
positive, given that (-x)^2 and x^2 are identical.

{space 4}{it:Which transformation?} 

{p 4 4 2}
The main criterion in choosing a transformation is: what works with the
data? As examples above indicate, it is important to consider as well
two questions.

{p 4 4 2}
What makes physical (biological, economic, whatever) sense, for example
in terms of limiting behaviour as values get very small or very large?
This question often leads to the use of logarithms.

{p 4 4 2} 
Can we keep dimensions and units simple and convenient? If possible, we
prefer measurement scales that are easy to think about. The cube root of
a volume and the square root of an area both have the dimensions of
length, so far from complicating matters, such transformations may
simplify them. Reciprocals usually have simple units, as mentioned
earlier. Often, however, somewhat complicated units are a sacrifice that
has to be made.


{title:Psychological comments {c -} for the puzzled}

{p 4 4 2}
The main motive for transformation is greater ease of description.
Although transformed scales may seem less natural, this is largely a
psychological objection. Greater experience with transformation tends to
reduce this feeling, simply because transformation so often works so
well. In fact, many familiar measured scales are really transformed
scales: decibels, pH and the Richter scale of earthquake magnitude are
all logarithmic.

{p 4 4 2}
However, transformations cause debate even among experienced data
analysts.  Some use them routinely, others much less. Various views,
extreme or not so extreme, are slightly caricatured here to stimulate
reflection or discussion. For what it is worth, I consider all these
views defensible, or at least understandable. 
 
{p 4 4 2} "This seems like a kind of cheating. You don't like how the
data are, so you decide to change them." 

{p 4 4 2}
"I see that this is a clever trick that works nicely. But how do I know
when this trick will work with some other data, or if another trick is 
needed, or if no transformation is needed?" 

{p 4 4 2}
"Transformations are needed because there is no guarantee that the
world works on the scales it happens to be measured on." 

{p 4 4 2}
"Transformations are most appropriate when they match a scientific
view of how a variable behaves." 

{p 4 4 2}
Often it helps to transform results back again, using the reverse or
{cmd:inverse} transformation:

{space 8}reciprocal   t = 1 / x            reciprocal       x = 1 / t

{space 8}log base 10  t = log_10 x         10 to the power  x = 10^t

{space 8}log base e   t = log_e x = ln x   e to the power   x = exp(t)

{space 8}log base 2   t = log_2 x          2 to the power   x = 2^t 
       
{space 8}cube root    t = x^(1/3)          cube             x = t^3

{space 8}square root  t = x^(1/2)          square           x = t^2


{title:How to do transformations in Stata}

{p 4 4 2}{it:Basic first steps}

{p 4 4 2}
1. Draw a graph of the data to see how far patterns in data match the
simplest ideal patterns. Try {help dotplot} or {help scatter} as 
appropriate. 

{p 4 4 2}
2. See what range the data cover. Transformations will have little effect
if the range is small.

{p 4 4 2}
3. Think carefully about data sets including zero or negative values.
Some transformations are not defined mathematically for some values, 
and often they make little or no scientific sense. For
example, I would never transform temperatures in degrees Celsius or
Fahrenheit for these reasons (unless to Kelvin).

{p 4 4 2}
Standard scores (mean 0 and sd 1) in a new variable are obtained by

{space 8}{cmd:. egen stdpopi = std(popi)}

{p 4 4 2}
whereas the basic transformations can all be put in new variables by
{help generate}:

{space 8}{cmd:. gen recener = 1/energy}
{space 8}{cmd:. gen logeener = ln(energy)}
{space 8}{cmd:. gen l10ener = log10(energy)}
{space 8}{cmd:. gen curtener = energy^(1/3)}
{space 8}{cmd:. gen sqrtener = sqrt(energy)}
{space 8}{cmd:. gen sqener = energy^2}

{space 8}{cmd:. gen logitp = logit(p)}               if p is a proportion
{space 8}{cmd:. gen logitp = logit(p / 100)}         if p is a percent
{space 8}{cmd:. gen frootp = sqrt(p) - sqrt(1-p)}    if p is a proportion
{space 8}{cmd:. gen frootp = sqrt(p) - sqrt(100-p)}  if p is a percent


{p 4 4 2}Cube roots of negative numbers require special care. Stata uses
a general routine to calculate powers and does not look for special cases
of powers. Whenever negative values are present, a more general recipe for 
cube roots is {cmd:sign(x) * (abs(x)^(1/3))}. Similar comments apply to
fifth, seventh, roots etc. 

{p 4 4 2}
Note any messages about missing values carefully: unless you had missing
values in the original variable, they indicate an attempt to apply a
transformation when it is not defined. (Do you have zero or negative
values, for example?)

{p 4 4 2}
It is not always necessary to create a transformed variable before
working with it. In particular, many {help graph} commands allow the options
{cmd:yscale(log)} and {cmd:xscale(log)}. This is very useful because the 
graph is labelled using the original values, but it does not leave behind a
log-transformed variable in memory.

{p 4 4 2}{it:Other commands} 

{p 4 4 2}
Stata offers various other commands designed to help you choose a
transformation. {help ladder}, {help gladder} and {help qladder} try
several transformations of a variable with the aim of showing how far
they produce a more nearly normal (Gaussian) distribution.  In practice
such commands can be helpful, or they can be confusing at an
introductory level: for examples, they can suggest a transform at odds
with what your scientific knowledge would indicate. {help boxcox} and
{help lnskew0} are more advanced commands that should be used only after
studying textbook explanations of what they do. Box and Cox (1964) is 
the key original reference. 

{p 4 4 2}
For some statistical people any debate about transformation is largely
side-stepped by the advent of {cmd:generalised linear models}. In such
models, estimation is carried out on a transformed scale using a
specified link function, but results are reported on the original scale
of the response. The Stata command is {help glm}. 


{title:Transformations for proportions and percents (more advanced)}

{p 4 4 2}
Data that are proportions (between 0 and 1) or percents (between 0 and
100) often benefit from special transformations. The most common is the
{cmd:logit} (or logistic) transformation, which is

{space 8}logit p = log (p / (1 - p)) for proportions

{space 8}OR logit p = log (p / (100 - p)) for percents

{p 4 4 2}
where p is a proportion or percent.

{p 4 4 2}
This transformation treats very small and very large values
symmetrically, pulling out the tails and pulling in the middle around
0.5 or 50%. The plot of p against logit p is thus a flattened S-shape.
Strictly, logit p cannot be determined for the extreme values of 0 and 1
(100%): if they occur in data, there needs to be some adjustment.

{p 4 4 2}
One justification for this logit transformation might be sketched in
terms of a diffusion process such as the spread of literacy. The push
from zero to a few percent might take a fair time; once literacy starts
spreading its increase becomes more rapid and then in turn slows; and
finally the last few percent may be very slow in converting to literacy,
as we are left with the isolated and the awkward, who are the slowest to
pick up any new thing. The resulting curve is thus a flattened S-shape
against time, which in turn is made more nearly linear by taking logits
of literacy. More formally, the same idea might be justified by
imagining that adoption (infection, whatever) is proportional to the
number of contacts between those who do and those who do not, which will
rise and then fall quadratically. More generally, there are many
relationships in which predicted values cannot logically be less than 0
or more than 1 (100%). Using logits is one way of ensuring this:
otherwise models may produce absurd predictions.

{p 4 4 2}
The logit (looking only at the case of proportions)

{space 8}logit p = log (p / (1 - p))

{p 4 4 2}
can be rewritten

{space 8}logit p = log p  - log (1 - p)

{p 4 4 2}
and in this form it can be seen as a member of a set of {cmd:folded}
{cmd:transformations}

{p 8 12 2}transform of p = something done to p - something done to (1 - p).

{p 4 4 2}
This way of writing it brings out the symmetrical way in which very high
and very low values are treated. (If p is small, 1 - p is large, and
vice versa.) The logit is occasionally called the {cmd:folded log}. The
simplest other such transformation is the {cmd:folded root} (that means
square root)

{space 8}folded root of p = root of p  - root of (1 - p). 

{p 4 4 2}
As with square roots and logarithms generally, the folded root has the
advantage that it can be applied without adjustment to data values of 0
and 1 (100%). The folded root is a weaker transformation than the logit.
In practice it is used far less frequently.

{p 4 4 2}
Two other transformations for proportions and percents met in the older
literature (and still used occasionally) are the {cmd:angular} and the
{cmd:probit}. The angular is

{space 8}arcsin(root of p)

{p 4 4 2}
or the angle whose sine is the square root of p. In practice, it behaves
very like

{space 8}p^0.41 - (1 - p)^0.41,

{p 4 4 2}
which in turn is close to
                       
{space 8}p^0.5 - (1 - p)^0.5,

{p 4 4 2}
which is another way of writing the folded root (Tukey 1960). The probit
is a transformation with a mathematical connection to the normal
(Gaussian) distribution, which is not only very similar in behaviour to
the logit, but also more awkward to work with. As a result, it is now
less seen, except in more advanced applications, where it retains
several advantages.


{title:Transformations as a family (more advanced)} 

{p 4 4 2}
The main transformations mentioned previously, with the
exception of the logarithm, namely the reciprocal, cube root, square
root and square, are all powers. The powers concerned are 

{space 8}reciprocal  -1
{space 8}cube root    1/3
{space 8}square root  1/2 
{space 8}square       2 

{p 4 4 2}
Note that the sequence of explanation was not capricious, but in
numerical order of power. Therefore, these transformations are all
members of a family. In addition, contrary to what may appear at first
sight, the logarithm really belongs in the family too. Knowing this is
important to appreciating that the transformations used in practice are
not just a bag of tricks, but a series of tools of different sizes or
strengths, like a set of screwdrivers or drill bits. We could thus fill
out this sequence, the ladder of transformations as it is sometimes
known, with more powers, as for example in 

{space 8}reciprocal square -2
{space 8}reciprocal        -1
{space 8}(yields one)       0 
{space 8}cube root          1/3
{space 8}square root        1/2 
{space 8}identity           1 
{space 8}square             2 
{space 8}cube               3 
{space 8}fourth power       4 

{p 4 4 2}
Among the additions here, the identity transformation, say x^1 = x, is
the transformation that is, in a sense, no transformation. The graph of
x against x is naturally a straight line and so the power of 1 divides
transformations whose graph is convex upwards (powers less than 1) from
transformations whose graph is concave upwards (powers greater than 1).
Powers less than 1 squeeze high values together and stretch low values
apart, and powers more than 1 do the opposite. 

{p 4 4 2}
The transformation x^0, on the other hand, is degenerate, as it always
yields 1 as a result. However, we will now see that in a strong sense
log x (meaning, strictly, the natural logarithm or ln x) really belongs
in the family at the position of power 0. 

{p 4 4 2}
If you know calculus, you will know that the sequence of powers 

{space 8}..., x^-3, x^-2, x^-1, x^0, x^1, x^2, ... 

{p 4 4 2}
has as integrals, apart from additive constants, 

{space 8}..., -x^-2 / 2, -x^-1, ln x, x, x^2 / 2, x^3 / 3, ... 

{p 4 4 2}
and the mapping can be reversed by differentiation. So integrating 
x^(p - 1) yields x^p / p, unless p is 0, in which case it yields ln x. 
Thus we can define a family 

{space 8}t_p(x) = x^p      if p != 0, 
{space 8}       = ln x     if p == 0. 

{p 4 4 2}
The notion of choosing from a family when we choose a power or logarithm
is a key idea. It follows that we can usually choose a different member
of the family if the transformation turns out to be too weak, or too
strong, for our purpose and our data. 

{p 4 4 2} 
Many discussions of transformations focus on slightly different
families, for a variety of mathematical and statistical reasons.  The
canonical reference here is Box and Cox (1964), although note also
earlier work by Tukey (1957). Most commonly, the definition is changed
to 

{space 8}t_p(x) = (x^p - 1) / p  if p != 0,
{space 8}       = ln x           if p == 0. 
		
{p 4 4 2}
This t(x, p) has various properties which point up family resemblances. 

{p 4 4 2}
1. ln x is the limit as p -> 0 of (x^p - 1) / p. 

{p 4 4 2} 
2. At x = 1, t_p(x) = 0, for all p.  

{p 4 4 2}
3. The first derivative (rate of change) of t_p(x) is x^(p - 1) 
if p != 0 and 1 / x if p == 0. At x = 1, this is always 1.  

{p 4 4 2}
4. The second derivative of t_p(x) is (p - 1) x^(p - 2) if p != 0
and -1 / x^2 if p == 0. At x = 1, this is always (p - 1). 

{p 4 4 2} 
Another small change of definition has some similar consequences,
but also some other advantages. Consider

{space 8}t_p(x) = [(x + 1)^p - 1] / p     if p != 0, 
{space 8}       = ln(x + 1)               if p == 0. 

{p 4 4 2}
This t(x, p) has various properties which also point up family
resemblances. 

{p 4 4 2}
1. If p = 1, t_p(x) = x. 

{p 4 4 2} 
2. At x = 0, t_p(x) = 0, for all p. So all curves
start at the origin. 

{p 4 4 2}
3. The first derivative (rate of change) of t_p(x) is (x + 1)^(p - 1) if
p != 0 and 1 / (x + 1) if p == 0. At x = 0, this is always 1. So the
curves have the same slope at the origin. 

{p 4 4 2}
4. The second derivative of t_p(x) is (p - 1) (x + 1)^(p - 2) if p != 0
and -1 / (x + 1)^2 if p == 0. At x = 0, this is always (p - 1). 

{p 4 4 2} 
The most useful consequence, however, is that this definition can 
be extended more easily to variables that can be both positive and
negative, as will now be seen. 


{title:Transformations for variables that are both positive and negative (more advanced)}

{p 4 4 2}
Most of the literature on transformations focuses on one or both of two
related situations: the variable concerned is strictly positive; or it is
zero or positive. If the first situation does not hold, some
transformations do not yield real number results (notably, logarithms
and reciprocals); if the second situation does not hold, then some other
transformations do not yield real number results or more generally do
not appear useful (notably, square roots or squares).

{p 4 4 2}
However, in some situations response variables in particular can be both
positive and negative. This is common whenever the response is a
balance, change, difference or derivative. Although such variables are
often skew, the most awkward property that may invite transformation is
heavy (long or fat) tails, high kurtosis in one terminology.  Zero
usually has a strong substantive meaning, so that we wish to preserve the
distinction between negative, zero and positive values. (Note that
Celsius or Fahrenheit temperatures do not really qualify here, as their
zero points are statistically arbitrary, for all the importance of
whether water melts or freezes.) 

{p 4 4 2}
In these circumstances, experience with right-skewed and strictly
positive variables might suggest looking for a transformation that
behaves like ln x when x is positive and like -ln(-x) when x is negative.
This still leaves the problem of what to do with zeros. In addition, it
is clear from any sketch that (in Stata terms) 

{space 8}{cmd:cond(x <= 0, -ln(-x), ln(x))}

{p 4 4 2}
would be useless. One way forward is to use 

{space 8}-ln(-x + 1)    if x <= 0, 
{space 8}ln(x + 1)     if x > 0.  

{p 4 4 2}This can also be written 

{space 8}sign(x) ln(|x| + 1)

{p 4 4 2}where sign(x) is 1 if x > 0, 0 if x == 0 and -1 if x < 0. 
This function passes through the origin, behaves like x for small x,
positive and negative, and like sign(x) ln(abs(x)) for large |x|.  The
gradient is steepest at 1 at x = 0, so the transformation pulls in
extreme values relative to those near the origin.  It has recently been
dubbed the neglog transformation (Whittaker et al. 2005).  An earlier
reference is John and Draper (1980).  In Stata language, this could be 

{space 8}{cmd:cond(x <= 0, -ln(-x + 1), ln(x + 1))}

{p 4 4 2}or 

{space 8}{cmd:sign(x) * ln(abs(x) + 1)} 

{p 4 4 2}The inverse transformation is 

{space 8}{cmd:cond(t <= 0, 1 - exp(-t), exp(t) - 1)}

{p 4 4 2}
A suitable generalisation of powers other than 0 is 

{space 8}-[(-x + 1)^p - 1] / p    if x <= 0, 
{space 8}  [(x + 1)^p - 1] / p    if x > 0. 

{p 4 4 2}Transformations that affect skewness as well as heavy tails in
variables that are both positive and negative were discussed by Yeo and
Johnson (2000).

{p 4 4 2}Another possibility in this terrain is to apply the inverse
hyperbolic function arsinh (also known as arg sinh, sinh^-1 and arcsinh). 
This is the inverse of the sinh function, which in turn is defined as 

{space 8}sinh(x) = (exp(x) - exp(-x)) / 2. 

{p 4 4 2}The sinh and arsinh functions can be computed in Mata as
{cmd:sinh(x)} and {cmd:asinh(x)} and in Stata as 
{cmd:(exp(x) - exp(-x))/2} and {cmd:ln(x + sqrt(x^2 + 1))}. 

{p 4 4 2}The arsinh function also too passes through the origin and is
steepest at the origin.  For large |x| it behaves like sign(x) ln(|2x|).
So in practice neglog(x) and arsinh(x) have loosely similar effects. See
also Johnson (1949).  


{title:Acknowledgements} 

{p 4 4 2}Austin Nichols pointed out that cube roots are well defined for 
negative values. 
 

{title:Author} 

{p 4 4 2}Nicholas J. Cox, Durham University{break}
	 n.j.cox@durham.ac.uk

{p 4 4 2}(last major revision 29 November 2005;
corrections and minor revisions 8 November 2006, 25 July 2007)


{title:Postscript}

{p 4 4 2}I came across the following in a text on calculus. 

{p 8 8 2}Transformation of a function into a form in which it can
readily be integrated can be effected by suitable algebraical
substitutions in which the independent variable is changed. The forms
these take will depend on the kind of function to be integrated and, in
general, experience and experiment must guide the student. The general
aim will be to simplify the function so that it may become easier to 
integrate. (Abbott 1940, p.184) 

{p 4 4 2}Modulo some small changes in terminology, this applies here
too.  Either way, the advice that "experience and experiment must guide
the student" is not much comfort to the beginner looking for guidance! 


{title:References} 

{p 4 8 2}
Abbott, P. 1940. 
{it:Teach Yourself Calculus.} 
London: English Universities Press. 

{p 4 8 2}
Box, G.E.P. and D.R. Cox. 1964. 
An analysis of transformations. 
{it:Journal of the Royal Statistical Society B}
26: 211{c -}252. 

{p 4 8 2}
Emerson, J.D. 1983. 
Mathematical aspects of transformation. 
In Hoaglin, D.C., F. Mosteller and J.W. Tukey (eds) 
{it:Understanding Robust and Exploratory Data Analysis.}
New York: John Wiley, 247{c -}282.

{p 4 8 2}
Emerson, J.D. and M.A. Stoto. 1983. 
Transforming data. 
In Hoaglin, D.C., F. Mosteller and J.W. Tukey (eds) 
{it:Understanding Robust and Exploratory Data Analysis.}
New York: John Wiley, 97{c -}128. 

{p 4 8 2}
John, J.A. and N.R. Draper. 1980. 
An alternative family of transformations.  
{it:Applied Statistics} 
29: 190{c -}197. 

{p 4 8 2}
Johnson, N.L. 1949. 
Systems of frequency curves generated by methods of translation. 
{it:Biometrika} 
36: 149{c -}176.

{p 4 8 2}
Tukey, J.W. 1957.
On the comparative anatomy of transformations. 
{it:Annals of Mathematical Statistics}
28: 602{c -}632.

{p 4 8 2}
Tukey, J. W. 1960. 
The practical relationship between the common transformations of 
percentages or fractions and of amounts. Reprinted in 
Mallows, C.L. (ed.) 1990. 
{it:The Collected Works of John W. Tukey. Volume VI: More Mathematical.}
Pacific Grove, CA: Wadsworth & Brooks-Cole, 211{c -}219.

{p 4 8 2} 
Whittaker, J., J. Whitehead and M. Somers. 2005.
The neglog transformation and quantile regression
for the analysis of a large credit scoring database. 
{it:Applied Statistics} 
54: 863{c -}878. 

{p 4 8 2}
Yeo, I. and R.A. Johnson. 2000. 
A new family of power transformations to improve normality or symmetry.
{it:Biometrika}
87: 954{c -}959. 


{title:Also see}

{p 4 13 2}
On-line: {help generate}, {help egen}, {help graph}

