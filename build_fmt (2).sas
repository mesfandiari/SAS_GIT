/*
 * Project:  Any/All
 * Filename: build_fmt.sas
 * Author:   Ray Devore    
 * Company:  Knowesis, Inc 
 * Contract: ASGARD        
 * Written:  April 2018
 * Directory: cd /afmoa/sgw/ray/formats
 *                                     
 * This macro builds a format statment from a dataset
 * 
 * Parameters: 
 *	SET = Dataset name that the format will come from
 *	START the variable with the lookup value
 *	LABEL the value to be returned
 *	FMTNAME = the name of the format being created
 *	TYPE = C for character, N for numeric
 *	OTH (optional) = Value for Other
 */
/* Notes:
 * HLO - High, Low, Other 
 * HLO = " " means to use the start/end values given 
 * HLO = "H" means to replace end value with High 
 * HLO = "L" means to replace the start value with Low 
 * HLO = "O" is the same as stating Other 
 *       Start and End values are ignored 
 *       
 * If ranges exclude endpoints, use: *
 * SEXCL="Y" (start excluded) or EEXCL="Y" (end excluded) 
 */
%BUILD_FMT(ICD&PROC.&FY., ICD&PROC., CCS, $ICD&FY.P2CCS, C, OTH);

%macro BUILD_FMT(SET, START, LABEL, FMTNAME, TYPE, OTH);

	%let namefmt = ;

	DATA OUTPUT_FORMAT;
		set &SET.		
		(keep =
			&START.
			%if "&LABEL" ne "FLAG" %then
			%do;
				&LABEL.
			%end;
			rename =
			(
				&START. = Start
				%if "&LABEL" ne "FLAG" %then
				%do;
					&LABEL. = Label
				%end;
			)
		)
		end = lastfmt;
		%if "&LABEL" = "FLAG" %then
		%do;
			length
				label
					$ 1
			;
			retain
				label
					"1"
			;
		%end;	   	

		RETAIN 
			/* name of the format to be created */
	   		FMTNAME
				"&FMTNAME." 
			/* type of format */
	   		TYPE
				"&TYPE." 
			%if "&OTH." ne "" %then
			%do;
				HLO
					" "
			%end;
		;

		/* For export, get rid of $ if it exists */
		if _N_ = 1 then
		do;
			if substr("&FMTNAME.",1,1) = "$" then
				call symput("NameFmt", "_" || substr("&fmtname",2));
			else
				call symput("NameFmt", "&fmtname");
		end;

		%if "&OTH." ne "" %then
		%do;
			output;
	   		/* create an Other category */
			if lastfmt then
			do;
				HLO = "O"; /* other */
				Label = "&OTH.";
				output;
			end;
		%end;
	run;

	%put "BUILD_FMT 102 " &=NameFmt;

	proc format 
		lib = library 
		cntlin = OUTPUT_FORMAT;
	run;

	proc export 
		data = OUTPUT_FORMAT
		outfile = "&NAMEFMT._format.txt"
		dbms = tab
		replace
		;
	run;

	proc datasets lib = work;
		delete 
			OUTPUT_FORMAT
		;
	run;

%mend BUILD_FMT;
/* end of file build_fmt.sas */
