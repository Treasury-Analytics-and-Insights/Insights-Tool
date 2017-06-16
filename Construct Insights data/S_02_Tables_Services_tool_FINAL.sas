*************************************************************************************************************************************
*************************************************************************************************************************************
Tabulation: national tables and mapping for SERVICES TOOL
*************************************************************************************************************************************
*************************************************************************************************************************************;

data edu_tabdata;
run;
data emp_tabdata;
run;
data edu_tabdata2;
run;
data emp_tabdata2;
run;

%macro create_tab_data(year);
data edu_tabdata&year.;
	set project.pop_&year._0024_service(in=a where=(schter_1519)) project.pop_&year._0024_service(in=b);
	where age_desc in ('06-14' '15-19');
	if b then schter_1519=0;
run;

data emp_tabdata&year.;
	set project.pop_&year._0024_service(in=a where=(ben_1524)) project.pop_&year._0024_service(in=b);
	where age_desc in ('15-19' '20-24');
	if b then ben_1524=0;
run;

data emp_tabdata&year.2;
	set emp_tabdata&year.(in=z where=(risk_6=0))
		emp_tabdata&year.(in=a where=(risk_1))
		emp_tabdata&year.(in=b where=(risk_2))
		emp_tabdata&year.(in=c where=(risk_3))
		emp_tabdata&year.(in=d where=(risk_4))
		emp_tabdata&year.(in=e where=(risk_5))
		emp_tabdata&year.(in=f where=(risk_6));
	where age_desc in ('15-19' '20-24');
	if a then riskgrp=1;
	else if b then riskgrp=2;
	else if c then riskgrp=3;
	else if d then riskgrp=4;
	else if e then riskgrp=5;
	else if f then riskgrp=6;
	else if z then riskgrp=0;
run;

data edu_tabdata&year.2;
	set edu_tabdata&year.(in=h where=(risk_1 and age_desc='06-14'))
		edu_tabdata&year.(in=i where=(risk_2 and age_desc='06-14'))
		edu_tabdata&year.(in=j where=(risk_3 and age_desc='06-14'))
		edu_tabdata&year.(in=k where=(risk_4 and age_desc='06-14'))
		edu_tabdata&year.(in=z where=(risk_6=0 and age_desc='15-19'))
		edu_tabdata&year.(in=a where=(risk_1 and age_desc='15-19'))
		edu_tabdata&year.(in=b where=(risk_2 and age_desc='15-19'))
		edu_tabdata&year.(in=c where=(risk_3 and age_desc='15-19'))
		edu_tabdata&year.(in=d where=(risk_4 and age_desc='15-19'))
		edu_tabdata&year.(in=e where=(risk_5 and age_desc='15-19'))
		edu_tabdata&year.(in=f where=(risk_6 and age_desc='15-19'));
	if h then riskgrp=1;
	else if i then riskgrp=2;
	else if j then riskgrp=3;
	else if k then riskgrp=4;
	else if a then riskgrp=1;
	else if b then riskgrp=2;
	else if c then riskgrp=3;
	else if d then riskgrp=4;
	else if e then riskgrp=5;
	else if f then riskgrp=6;
	else if z then riskgrp=0;
run;

data edu_tabdata(keep=year reg age_desc schter_1519 risk_factors_2plus_atyear X_GENDER_DESC tla edu:);
	set edu_tabdata edu_tabdata&year.(in=a rename=(risk_factors_2plus_&year.=risk_factors_2plus_atyear));
	if a then year="&year.";
	if year='' then delete;
run;
data emp_tabdata(keep=year reg age_desc ben_1524 risk_factors_2plus_atyear X_GENDER_DESC tla emp:);
	set emp_tabdata emp_tabdata&year.(in=a rename=(risk_factors_2plus_&year.=risk_factors_2plus_atyear));
	if a then year="&year.";
	if year='' then delete;
run;

data edu_tabdata2(keep=year riskgrp reg age_desc schter_1519 X_GENDER_DESC tla edu:);
	set edu_tabdata2 edu_tabdata&year.2(in=a);
	if a then year="&year.";
	if year='' then delete;
run;
data emp_tabdata2(keep=year riskgrp reg age_desc ben_1524 X_GENDER_DESC tla emp:);
	set emp_tabdata2 emp_tabdata&year.2(in=a);
	if a then year="&year.";
	if year='' then delete;
run;

%mend create_tab_data;

%create_tab_data(year=2013);
%create_tab_data(year=2014);
%create_tab_data(year=2015);

%macro suppress_rr3;
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
		if &vartornd. < 12 then &vartornd.=0;
	run;
	%rr3(&indata._rr3,&indata._rr3,&vartornd.);
%end;
%mend suppress_rr3;


%macro tabulateby2(indat,class,outfile,vars);
proc summary data=&indat. nway;
class &class.;
var &vars.;
output out=temp1(drop=_type_ rename=(_freq_=count)) sum=;
run;

proc summary data=&indat. nway;
class &class. x_gender_desc;
var &vars.;
output out=temp2(drop=_type_ rename=(_freq_=count)) sum=;
run;

data table_final; set temp1 temp2;
if x_gender_desc='' then x_gender_desc='All';
run;

proc sort data=table_final;
	by &class. x_gender_desc;
run;

%let indata=table_final;
data t; set &indata.; drop &class. x_gender_desc; run;
proc contents data=t out=vars(keep=name type) noprint;
run;

data vars;
	set vars;
	if  type=1 /* need to also exclude any numeric variables here that you don't want to be rounded */;
	call symput('numvars',_n_);
run;
%suppress_rr3; * supressing counts less than 6;

data &outfile._rr3; set &indata._rr3;
if Reg='Area Outside Region' then delete;
run;

data &outfile.; set &indata.;
run;
%mend;

%tabulateby2(edu_tabdata,year age_desc schter_1519,Output1.S_table1_edu,edu:);
%tabulateby2(edu_tabdata,year risk_factors_2plus_atyear age_desc schter_1519,Output1.S_table2_edu,edu:);
%tabulateby2(edu_tabdata,year risk_factors_2plus_atyear reg age_desc schter_1519,Output2.S_table3_edu,edu:);
%tabulateby2(edu_tabdata,year risk_factors_2plus_atyear reg TlA age_desc schter_1519,Output2.S_table4_edu,edu:);
%tabulateby2(emp_tabdata,year age_desc ben_1524,Output1.S_table1_emp,emp:); 
%tabulateby2(emp_tabdata,year risk_factors_2plus_atyear age_desc ben_1524,Output1.S_table2_emp,emp:); 
%tabulateby2(emp_tabdata,year risk_factors_2plus_atyear reg age_desc ben_1524,Output2.S_table3_emp,emp:); 
%tabulateby2(emp_tabdata,year risk_factors_2plus_atyear reg tlA age_desc ben_1524,Output2.S_table4_emp,emp:); 
%tabulateby2(emp_tabdata2,year riskgrp age_desc ben_1524,Output1.S_table5_emp,emp:); 
%tabulateby2(emp_tabdata2,year riskgrp reg age_desc ben_1524,Output2.S_table6_emp,emp:); 
%tabulateby2(emp_tabdata2,year riskgrp reg tlA age_desc ben_1524,Output2.S_table7_emp,emp:); 
%tabulateby2(edu_tabdata2,year riskgrp age_desc schter_1519,Output1.S_table5_edu,edu:); 
%tabulateby2(edu_tabdata2,year riskgrp reg age_desc schter_1519,Output2.S_table6_edu,edu:); 
%tabulateby2(edu_tabdata2,year riskgrp reg tlA age_desc schter_1519,Output2.S_table7_edu,edu:); 

** We want to create a new risk group 7 in the b files where 2+ risk factors at age15;
data output1.S_Table5_edu_rr3(drop=risk_factors_2plus_atyear);
	set output1.S_Table5_edu_rr3 output1.S_Table2_edu_rr3(where=(risk_factors_2plus_atyear=1));
	if risk_factors_2plus_atyear then riskgrp=7;
run;

data output2.S_Table6_edu_rr3(drop=risk_factors_2plus_atyear);
	set output2.S_Table6_edu_rr3 output2.S_Table3_edu_rr3(where=(risk_factors_2plus_atyear=1));
	if risk_factors_2plus_atyear then riskgrp=7;
run;

data output2.S_Table7_edu_rr3(drop=risk_factors_2plus_atyear);
	set output2.S_Table7_edu_rr3 output2.S_Table4_edu_rr3(where=(risk_factors_2plus_atyear=1));
	if risk_factors_2plus_atyear then riskgrp=7;
run;

data output1.S_Table5_emp_rr3(drop=risk_factors_2plus_atyear);
	set output1.S_Table5_emp_rr3 output1.S_Table2_emp_rr3(where=(risk_factors_2plus_atyear=1));
	if risk_factors_2plus_atyear then riskgrp=7;
run;

data output2.S_Table6_emp_rr3(drop=risk_factors_2plus_atyear);
	set output2.S_Table6_emp_rr3 output2.S_Table3_emp_rr3(where=(risk_factors_2plus_atyear=1));
	if risk_factors_2plus_atyear then riskgrp=7;
run;

data output2.S_Table7_emp_rr3(drop=risk_factors_2plus_atyear);
	set output2.S_Table7_emp_rr3 output2.S_Table4_emp_rr3(where=(risk_factors_2plus_atyear=1));
	if risk_factors_2plus_atyear then riskgrp=7;
run;

proc export data=output1.S_Table1_edu_rr3 
outfile="&path.\tables\S_age_edu.csv" dbms=csv replace;
run;
proc export data=output1.S_Table5_edu_rr3 
outfile="\&path.\tables\S_agerisk_edub.csv" dbms=csv replace;
run;
proc export data=output2.S_Table6_edu_rr3 
outfile="&path.\tables\S_REGION_edub.csv" dbms=csv replace;
run;
proc export data=output2.S_Table7_edu_rr3 
outfile="&path.\tables\S_TA_edub.csv" dbms=csv replace;
run;
proc export data=output1.S_Table1_emp_rr3 
outfile="&path.\tables\S_age_emp.csv" dbms=csv replace;
run;
proc export data=output1.S_Table5_emp_rr3 
outfile="&path.\tables\S_agerisk_empb.csv" dbms=csv replace;
run;
proc export data=output2.S_Table6_emp_rr3 
outfile="&path.\tables\S_REGION_empb.csv" dbms=csv replace;
run;
proc export data=output2.S_Table7_emp_rr3 
outfile="&path.\tables\S_TA_empb.csv" dbms=csv replace;
run;