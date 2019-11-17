#delim ;
program define adodev;
version 10.0;
*
 Alter ado path to start with the Stata system folders
 UPDATES, BASE, ., PERSONAL, PLUS, SITE and OLDPLACE
 (for development work).
*!Author: Roger Newson
*!Date: 29 March 2009
*;

qui{;
  cap adopath - .;
  cap dopath - BASE;
  cap adopath - UPDATES;
  cap adopath - PERSONAL;
  cap adopath - PLUS;
  cap adopath - SITE;
  cap adopath - OLDPLACE;
  adopath ++ OLDPLACE;
  adopath ++ SITE;
  adopath ++ PLUS;
  adopath ++ PERSONAL;
  adopath ++ .;
  adopath ++ BASE;
  adopath ++ UPDATES;
};

* Display final adopath *;
adopath;

end;

