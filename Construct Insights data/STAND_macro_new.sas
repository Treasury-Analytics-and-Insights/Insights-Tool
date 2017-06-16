*************************************************************************************************************************
Set missing values for numeric variable to zero
*************************************************************************************************************************;

%macro missing_array(var,start,end);
array &var._(*) &var._&start.-&var._&end.;
do ind=&start. to &end.;
i=ind-(&start.-1);
			if &var._(i)=. then &var._(i)=0;
drop i ind; 
end;
%mend;

%macro missing_var(var);
if &var.=. then &var.=0;
%mend;

*************************************************************************************************************************
Set missing values for numeric variable to zero and 
set all non zero values to 1 (create indicator)
*************************************************************************************************************************;

%macro onezero_array(var,start,end);
array &var._(*) &var._&start.-&var._&end.;
do ind=&start. to &end.;
i=ind-(&start.-1);
			if &var._(i)=. then &var._(i)=0;
			if &var._(i) not in (0,.) then &var._(i)=0;
drop i ind; 
end;
%mend;

%macro onezero_var(var);
if &var.=. then &var.=0;
if &var not in (.,0) then &var.=1;
%mend;



*************************************************************************************************************************
Set the dataset to be confidentialised
*************************************************************************************************************************;

%macro suppress_rr3;
proc contents data=&indata. out=vars(keep=name type) noprint;
run;

data vars;
	set vars;
	where type=1 /* need to also exclude any numeric variables here that you don't want to be rounded */;
	call symput('numvars',_n_);
run;

data &indata._rr3;
	set &indata.;
run;

%do i=1 %to &numvars.;

	data _null_;
		set vars;
		if &i.=_n_ then do;
			call symput('vartornd',name);
		end;
	run;

	** First suppress unrounded cells of less than 6 (replace with missing value);
	data &indata._rr3;
		set &indata._rr3;
		if &vartornd. < 6 then &vartornd.=0;
	run;
	%rr3(&indata._rr3,&indata._rr3,&vartornd.);
%end;
%mend suppress_rr3;


*************************************************************************************************************************
Keeping SAS session alive
*************************************************************************************************************************;

%macro zzzrun;
%* every 20 minutes write a 'zzz' to the log;
%* stop it by hitting STOP button;
data _null_;
	sysecho 'I am sleeping - press stop to wake me up';
	do i=1 to 10000;
	y=sleep(1200);
	put 'zzz' i;
	end;
run;
%mend;


*************************************************************************************************************************
Removing overlapping spells
*************************************************************************************************************************;

%macro OVERLAP (dataset,examine= F ); 
%* 	This macro removes overlaps in spell coverage.
	The base code for the macro was written by Sylvia.
	The operating principle is to keep the information in the earlier spell (assuming it is correct)
	and then adjust the dates of the subsequent spell/s by pushing them out.
	The user is advised to check the records that are deleted into the deletes dataset - particularly 
	if there are a large number. 
	If more detailed examination of deletions is required, set examine = T. 
	;

proc sort data= &dataset ;
	by snz_uid startdate enddate;
	run ;

data 	&dataset._OR ( drop =  tempstart tempend startdate enddate delete_flag  rename=(newstart=startdate newend=enddate)) 
		deletes (drop= delete_flag) 
		%if &examine = T %then examine ;
		;	
	length delete_flag 3 ;
	set &dataset;
	by snz_uid startdate enddate;
	retain tempstart tempend ;
	format tempstart tempend newstart newend date9.;

	%* checking ;
	if startdate = .  or enddate = . or enddate < startdate then abort ;

	delete_flag = 0 ;
	if first.snz_uid then do;
    	tempstart=startdate;
    	tempend=enddate;
    	newstart=startdate;
    	newend=enddate;
    	end;
	if not first.snz_uid then do;
		%*if this spell ends before or on the previous spell end then the pervious spell 
		* covers this spell and this spell can be deleted ;
    	if enddate<=tempend then do;
       		newstart=.;
       		newend=.;
			delete_flag = 1 ;
       		end;
		%* else if the spell starts before the previous spell finished;
		%* and finshed after the previous one then start this spell the ;
		* day after the previous one finished ;
    	else if startdate<=tempend and enddate>tempend then do;     
        	newstart=tempend+1;
        	newend=enddate;
        	tempstart=newstart;
        	tempend=newend;
        	end;
		* else if the start of the spell is after the previous one ends then 
		* leave it as is ;
    	else if startdate>tempend then do;        
        	newstart=startdate;
        	newend=enddate;
        	tempstart=newstart;
        	tempend=newend;
        	end;
		else abort ;
   	end;

	* Output ;
	if 	delete_flag = 0 	then	output &dataset._OR ;
	else if delete_flag = 1 then 	output deletes ;
	%if &examine = T %then output examine ; ;
	
run;
%mend;

**************************************************************************************************************************************
Calculating spell days

* This macro calculates the number of days within a spell that fits within a window ;
* It can be used for a fixed window or a window that varies by observation ;
* It also provides a gross_earnings_amt if needed ;
**************************************************************************************************************************************;


%macro spells_days_calc(startdate,enddate,start_window,end_window,fileout,gross_daily_amt) ;

	* if inside the window ;
	if (&startdate <= &end_window   and &enddate >= &start_window ) then do;
		* calculate the spell days based on the various start and end dates and the appropriate window ;
		if &startdate <= &start_window and  (&enddate < &end_window)     then days = &enddate    - &start_window +1 ; *starts before or on begining of window & ends during but before end of window ;
		if &startdate <= &start_window and  (&end_window  <= &enddate )  then days = &end_window - &start_window +1 ;	*starts before or on begining of window & ends at or after end of window ;
		if (&start_window < &startdate ) 	and  (&enddate < &end_window)  then days = &enddate    - &startdate +1 ; *starts during window & ends during but before end of window ;
		if (&start_window < &startdate ) 	and  (&end_window <=	&enddate) then days = &end_window - &startdate +1 ; *starts during window & ends at or after end of window ; 
		%if &gross_daily_amt ne     %then gross_earnings_amt = days * &gross_daily_amt ; ;
		output &fileout;
	end;
%mend ;

**************************************************************************************************************************************
Aggregate number of days by month  
 * This macro aggregates the number of days by month between the specified first and last year.
  * There is an option to aggregate daily dollar amounts by month. 
  * To aggregate one off payments, use startdate=enddate
  * Any cleaning or conditions to data need to be applied before the aggregation.
  * The input file must include startdate and enddate variable.
  * Note that this macro calls the spells_days_calc macro. ;
**************************************************************************************************************************************;


%macro aggregate_by_month(filein,fileout,first_year,last_year,gross_daily_amt=);
	data  errors &fileout (drop =  temp1 temp2 );
	set &filein;
    %* abort if startdate or enddate are missing or enddate < startdate;
	if enddate = . or startdate = .  or enddate < startdate then abort ;

	do year = &first_year to &last_year ;
 		do month=1 to 12;
			st1=input("01JAN"||put(year,z4.),date9.);
			start_window=intnx('MONTH',st1,month-1,'S');
   			end_window1  =intnx('MONTH',st1,month,'S');
			end_window  =intnx('DAY',end_window1,-1,'S');
			temp1 = put(start_window,ddmmyy8.);
			temp2 = put(end_window,ddmmyy8.);
		%spells_days_calc(startdate,enddate,start_window,end_window,&fileout,&gross_daily_amt) ;
		end;
	end ; 
 run;
%mend;

**************************************************************************************************************************************
Aggregate by year

* This macro aggregates the number of days by year between the specified first and last year.
   There is an option to aggregate daily dollar amounts by year. 
   To aggregate one off payments, use startdate=enddate
   Any cleaning or conditions to data need to be applied before the aggregation.
   The input file must include startdate and enddate variable.
   Note that this macro calls the spells_days_calc macro. ;
**************************************************************************************************************************************;


%macro aggregate_by_year(filein,fileout,first_year,last_year,gross_daily_amt=);

	data  errors &fileout (drop =  temp1 temp2 );
	set &filein;
    %* abort if startdate or enddate are missing or enddate < startdate;
	if enddate = . or startdate = .  or enddate < startdate then abort ;

	do year = &first_year to &last_year ;
		start_window=intnx('YEAR',"01JAN&first_year."d,(year-&first_year.),'S');
   		end_window  =intnx('YEAR',"31DEC&first_year."d,(year-&first_year.),'S');
		temp1 = put(start_window,ddmmyy8.);
		temp2 = put(end_window,ddmmyy8.);
		%spells_days_calc(startdate,enddate,start_window,end_window,&fileout,&gross_daily_amt) ;
	end ; 
 run;
%mend;

**************************************************************************************************************************************
Duplicate check
* delete any dup_set file that might be hanging around 
**************************************************************************************************************************************;

%macro duplcheck (dataset);

%if %sysfunc(exist(dup_set)) %then %do ;
	proc datasets noprint ; delete dup_set ; RUN ;
	%end ;

*delete the duplicates out of the main datset and put them into dup_set ;
proc sort data =  &dataset nodupkey dupout= dup_set out= &dataset ; 
	by snz_uid year; 
	run;

*count the number of duplicates and put this into a macro variable called dupes ;
%let dupes = 0 ;
DATA _NULL_ ;
	set dup_set  end= last;
	if last then call symput('dupes',_n_) ;
	run ;

*if there are duplicates then print them out ;
%if &dupes ne 0 %then %do ;
	proc print data=dup_set ; 
		title1 "&DUPES DUPLICATES WERE DETECTED AND REMOVED"; 	
		run ;
	%end ;

%mend;

**************************************************************************************************************************************
checks for 4 cases where ovelap exists
* four cases where there is some overlap: 
spell2 is within spell1 
spell2 finishes after spell1 
spell1 is within spell2 
spell1 starts after spell2 ;

**************************************************************************************************************************************;

%macro overlap_days(start1,end1,start2,end2,days);

if not ((&end1.<&start2.) or (&start1.>&end2.)) then do;
   if (&start1. <= &start2.) and  (&end1. >= (&end2.)) then &days.=(&end2.-&start2.)+1;
   else if (&start1. <= &start2.) and  (&end1. <= (&end2.)) then &days.=(&end1.-&start2.)+1;
   else if (&start1. >= &start2.) and  (&end1. <= (&end2.)) then &days.=(&end1.-&start1.)+1;
   else if (&start1. >= &start2.) and  (&end1. >= (&end2.)) then &days.=(&end2.-&start1.)+1;
end;
else  &days.=0;
%mend;
