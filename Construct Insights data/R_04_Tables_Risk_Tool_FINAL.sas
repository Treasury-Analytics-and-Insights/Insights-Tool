*****************************************************************************************************************************************
*****************************************************************************************************************************************

Creating tables to feed Infographics tool being developed by Team ( Chris Ball)
Specifications for tables have been provided by Robert Templeton

Developer: Sarah Tumen
Date: 12 Jan 2016

QA: Robert Templeton
 Based on QA, labeling of 00-05 was corrected. 
	Ethnicity multiple response was plugged in 
	and risk group definitions for 00-14 were corrected to cumulative measure of risk ( 2+,3+,4+ factors)

USING Three sources data 

***************************************************************************************************************************************
***************************************************************************************************************************************;

* CONSOLIDATING THREE DATASETS;

%macro tab_part1(by_year);
	data TEMP; 
	set 
	project.risk_factors_&by_year._0_14 
	project.risk_factors_&by_year._15_19 
	project.risk_factors_&by_year._20_24;
	year=&by_year.;
	; keep snz_uid age risk_: year;
	run;
	proc sort data=TEMP; by snz_uid;
	data DATA3; 
	merge project.population_&by_year._0_24(in=a) TEMP inputlib._ind_ethnicity_&date. (keep=snz_uid moh_:); by snz_uid; if a;

	* Excluding people with no meshblock info;
	if reg ne '';
	count=1;
run;
**********************************************************************************************************************************
TABULATION PART
Creating tables for RISK TOOL
**********************************************************************************************************************************;

* Table 1;
proc summary data=data3 nway;
	class year reg age_desc x_gender_desc;
	var count risk_1-risk_6;
	output out=temp1 (drop=_:) sum=;
run;

proc summary data=data3 nway;
	class year reg age_desc;
	var count risk_1-risk_6;
	output out=temp2 (drop=_:) sum=;
run;

data table1_final;
	set temp1 temp2;

	if x_gender_desc='' then
		x_gender_desc='All';
	rename count=all;
	rename risk_1=all_risk_1;
	rename risk_2=all_risk_2;
	rename risk_3=all_risk_3;
	rename risk_4=all_risk_4;
	rename risk_5=all_risk_5;
	rename risk_6=all_risk_6;

proc sort data=table1_final;
	by year reg age_desc x_gender_desc;
run;


***************************************************************************************************************************************;
* Table 2;
proc summary data=data3 nway;
	class year reg tla age_desc x_gender_desc;
	var count risk_1-risk_6;
	output out=temp1 (drop=_:) sum=;
run;

proc summary data=data3 nway;
	class year reg tla age_desc;
	var count risk_1-risk_6;
	output out=temp2 (drop=_:) sum=;
run;

data table2_final;
	set temp1 temp2;

	if x_gender_desc='' then
		x_gender_desc='All';
	rename count=all;
	rename risk_1=all_risk_1;
	rename risk_2=all_risk_2;
	rename risk_3=all_risk_3;
	rename risk_4=all_risk_4;
	rename risk_5=all_risk_5;
	rename risk_6=all_risk_6;

proc sort data=table2_final;
	by reg tla age_desc x_gender_desc;
run;

***************************************************************************************************************************************;
***************************************************************************************************************************************;
* Table 3;
proc summary data=data3 nway;
	class year reg tla  au age_desc x_gender_desc;
	var count risk_1-risk_6;
	output out=temp1 (drop=_:) sum=;
run;

proc summary data=data3 nway;
	class year reg tla au age_desc;
	var count risk_1-risk_6;
	output out=temp2 (drop=_:) sum=;
run;

data table3_final;
	set temp1 temp2;

	if x_gender_desc='' then
		x_gender_desc='All';
	rename count=all;
	rename risk_1=all_risk_1;
	rename risk_2=all_risk_2;
	rename risk_3=all_risk_3;
	rename risk_4=all_risk_4;
	rename risk_5=all_risk_5;
	rename risk_6=all_risk_6;

proc sort data=table3_final;
	by reg tla au age_desc x_gender_desc;
run;

data RT_Table1_&by_year._final; set table1_final;
data RT_Table2_&by_year._final; set table2_final;
data RT_Table3_&by_year._final; set table3_final;run;

%mend;
%tab_part1(2013);
%tab_part1(2014);
%tab_part1(2015);

data RT_Table1_final; set RT_Table1_2013_final RT_Table1_2014_final RT_Table1_2015_final ;
data RT_Table2_final; set RT_Table2_2013_final RT_Table2_2014_final RT_Table2_2015_final ;
data RT_Table3_final; set RT_Table3_2013_final RT_Table3_2014_final RT_Table3_2015_final ;run;



*************************************************************************************************************************************************
Randomly rounding using SAS macro
OUTPUTS FOR NATIONAL TABLES (NEW)
*************************************************************************************************************************************************
*************************************************************************************************************************************************;

%macro tab_nat(by_year);
	data TEMP; 
	set 
	project.risk_factors_&by_year._0_14 
	project.risk_factors_&by_year._15_19 
	project.risk_factors_&by_year._20_24;
	year=&by_year.;
	; keep snz_uid age risk_: year;
	run;
	proc sort data=TEMP; by snz_uid;
	data DATA3; 
	merge project.population_&by_year._0_24(in=a) TEMP inputlib._ind_ethnicity_&date. (keep=snz_uid moh_:); by snz_uid; if a;

	* Excluding people with no meshblock info;
	if reg ne '';
	count=1;
	run;

	proc summary data=DATA3 nway;
	class year x_gender_desc age_desc;
	var count risk_1-risk_6;
	output out=temp_ALL sum=;

	proc summary data=DATA3 nway;
	where moh_pop_ethnic_grp1_snz_ind=1; 
	class year x_gender_desc age_desc;
	var count risk_1-risk_6;
	output out=temp_E sum=;

	proc summary data=DATA3 nway;
	where moh_pop_ethnic_grp2_snz_ind=1; 
	class year x_gender_desc age_desc;
	var count risk_1-risk_6;
	output out=temp_M sum=;

	proc summary data=DATA3 nway;
	where moh_pop_ethnic_grp3_snz_ind=1; 
	class year x_gender_desc age_desc;
	var count risk_1-risk_6;
	output out=temp_PI sum=;

	proc summary data=DATA3 nway;
	where moh_pop_ethnic_grp4_snz_ind=1; 
	class year x_gender_desc age_desc;
	var count  risk_1-risk_6;
	output out=temp_A sum=;

	proc summary data=DATA3 nway;
	where (moh_pop_ethnic_grp5_snz_ind or moh_pop_ethnic_grp6_snz_ind=1); 
	class year x_gender_desc age_desc;
	var count risk_1-risk_6;
	output out=temp_O sum=;

	data RT_nat_&by_year; retain eth; length eth $20.;set 
	TEMP_ALL(in=a) 
	TEMP_E(in=e)
	TEMP_M(in=m)
	TEMP_PI(in=p) 
	TEMP_A(in=s)
	TEMP_O(in=o);
	if a then ETH='ALL';
	if e then ETH='European';
	if m then ETH='Maori';
	if p then ETH='Pacific Islander';
	if s then ETH='Asian';
	if o then ETH='Other';
	drop _:;
	run;

%let indata=RT_nat_&by_year;
%suppress_rr3;


%mend;
%tab_nat(2013);
%tab_nat(2014);
%tab_nat(2015);

data RT_NAT_table;
set RT_nat_2013-RT_nat_2015;
run;

proc export data=RT_NAT_table 
outfile="&path.\tables\RT_national_table.csv" dbms=csv replace ;run;


*************************************************************************************************************************************************
Randomly rounding using SAS macro
OUTPUTS FOR MAPPING TOOL
*************************************************************************************************************************************************
*************************************************************************************************************************************************;


%macro suppress_rr3;

proc contents data=&indata. out=vars(keep=name type) noprint;
run;

data vars;
	set vars;
	where type=1 and name ne 'year'/* need to also exclude any numeric variables here that you don't want to be rounded */;
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

%let indata=RT_Table1_final;
%suppress_rr3;

%let indata=RT_Table2_final;
%suppress_rr3;

%let indata=RT_Table3_final;
%suppress_rr3;

*Saving tabulated outputs as final datasets ( back up);

data output.RT_Table1_final; set RT_Table1_final;
data output.RT_Table2_final; set RT_Table2_final;
data output.RT_Table3_final; set RT_Table3_final;
run;
data output.RT_Table1_final_rr3; set RT_Table1_final_rr3;
data output.RT_Table2_final_rr3; set RT_Table2_final_rr3;
data output.RT_Table3_final_rr3; set RT_Table3_final_rr3;
run;

proc export data=output.RT_Table1_final_rr3 
outfile="&path.\tables\RT_REGION_final.csv" dbms=csv;run;

proc export data=output.RT_Table2_final_rr3 
outfile="&path.\tables\RT_TA_final.csv" dbms=csv;run;

proc export data=output.RT_Table3_final_rr3 
outfile="&path.\tables\RT_AU_final.csv" dbms=csv;run;
