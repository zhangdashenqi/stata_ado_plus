^Title^

	^mapch^ -- map chains of events

^Syntax^

	^mapch^ begin end [time]

^Description^

	^mapch^ maps chains of events. A 'chain' consists of at least one event; 
an 'event' in this context is a change of information contained in the 
variable begin into information contained in the variable end. Optionally, 
the time at which the event took place can be stored in the variable time and 
used to map the chains chronologically. It is assumed that both begin and end 
contain unique information, i.e., each value in both variables can only appear 
once. It is also assumed that events in a chain can not occur at the same 
time and that chains are not circular, i.e., the begin value of a chain must
not be the same as the end value of that chain. ^mapch^ creates a database 
'mapping' that contains maps of each chain and two or three additional 
variables: recent, whose value is equal to the end value of the chain for 
each step in that chain; date (only in case real time is not available), a 
fictitious time when the event took place allowing to sort the information;
and NoOfEvents, the number of events per chain. ^mapch^ also tabulates the 
frequency of n-step chains with 1<n<=N (N=total number of events in your 
database). Consider the following two examples.

^Example 1:^

	begin		end
	A		B
	B		C
	G		H
	C		D
	X		Y
	H		I
	Z		Z1
	Z1		Z2
	X2		X3
	Z2		Z3

^mapch^ will map the chains and create the database mapping as follows:

	begin		end		recent	date		NoOfEvents
	A		B		D		1		3
	B		C		D		2		3
	C		D		D		3		3
	G		H		I		1		2
	H		I		I		2		2
	X		Y		Y		.		1
	X2		X3		X3		.		1
	Z		Z1		Z3		1		3
	Z1		Z2		Z3		2		3
	Z2		Z3		Z3		3		3


^Example 2:^

	begin		end		time
	A		B		17004
	B		C		17203
	G		H		15000
	C		D		18999
	X		Y		17034
	H		I		16000
	Z		Z1		14333
	Z1		Z2		14334
	X2		X3		15001
	Z2		Z3		14335

^mapch^ will map the chains and create the database mapping as follows:

	begin		end		time		recent	NoOfEvents
	A		B		17004		D		3
	B		C		17203		D		3
	C		D		18999		D		3
	G		H		15000		I		2
	H		I		16000		I		2
	X		Y		17034		Y		1
	X2		X3		15001		X3		1
	Z		Z1		14333		Z3		3
	Z1		Z2		14334		Z3		3
	Z2		Z3		14335		Z3		3




^Remarks^

	^mapch^ was written based on a do-file that was used to overcome the 
challenge of merging databases in which unique key identifiers changed over 
time, more precisely driver license numbers. While this key variable 
was really unique, a substantial portion of the driver license numbers did 
change over time because this variable's format was alpha-numeric and based 
on the driver's name. In order to capture all accident records when merging 
databases in which the updated number was used with databases in which the 
original number was used, the name changes had to be mapped in order to
create a cross-reference database. To this end, a solution consisting of a 
combination of appending, indexing and merging was developed, which proved 
to be considerably faster than simply looping; e.g., a database containing 
86,000 events with chains of length up to five events (i.e., drivers who 
changed their name ergo driver's license number up to five times in a 
period of ten years) is mapped in a couple of seconds using ^mapch^, while 
it takes numerous hours in case a simpler combination of looping procedures 
would be used.

Author: Ward Vanlaar (wardv@trafficinjuryresearch.com)
