%macro Create_Mat_edu_pop(rel);

* Part 1 ;
data TEMP_mother;
set &projectlib..PARENTTOCHILDMAP_&date.;
if parent_sex='2' and (source="&rel." or source1="&rel.");
run;

* Part 2 ;
proc sql;
create table TEMP_MSDEducation as
	select 
		a.*,
		put(a.msd_edh_education_code, $BDD_edu.) as education_level,
		input(compress(a.msd_edh_educ_lvl_start_date,"-"), yymmdd10.) as Startdate format date9.,
		input(compress(a.msd_edh_educ_lvl_end_date,"-"), yymmdd10.) as Enddate format date9.,
		b.snz_uid as ref_snz_uid,
		b.DOB

	from msd.msd_education_history a inner join TEMP_mother b
	on a.snz_uid=b.parent
order by snz_uid;
quit;

data TEMP_MSDEducation1;
	set TEMP_MSDEducation;
	array Maternal_Edu_at_age_(*) Maternal_Edu_at_age_&firstage-Maternal_Edu_at_age_&lastage;
	DO ind = &firstage to &lastage; 
		i=ind-(&firstage-1);
		if StartDate <=intnx('YEAR',DOB,i,'S')  and (intnx('YEAR',DOB,i,'S')<= EndDate) 
			then Maternal_Edu_at_age_(i) = education_level*1;
		else Maternal_Edu_at_age_(i) = .;
	END;

	if EndDate lt DOB then maternal_edu_prior_birth = education_level*1;
drop i ind;
run;

data TEMP_MSDEducation2;
	set TEMP_MSDEducation;
	array Maternal_Edu_(*) Maternal_Edu_&msd_left_yr.-Maternal_Edu_&last_anal_yr.;
	DO ind = &msd_left_yr. to &last_anal_yr.; 
		i=ind-(&msd_left_yr.-1);
		if StartDate <=intnx('YEAR',MDY(1,1,&msd_left_yr.),i,'S')  and (intnx('YEAR',MDY(1,1,&msd_left_yr.),i,'S')<= EndDate) 
			then Maternal_Edu_(i) = education_level*1;
		else Maternal_Edu_(i) = .;
	END;
	
drop i ind;
run;

***;
proc summary data=TEMP_MSDEducation1 nway;
	class ref_snz_uid;
	var maternal_edu_prior_birth 
		Maternal_Edu_at_age_&firstage-Maternal_Edu_at_age_&lastage;
	output out=&projectlib.._&rel._mat_edu_BDD_at_age_&date(drop=_: rename=ref_snz_uid=snz_uid) max=;
run;

proc summary data=TEMP_MSDEducation2 nway;
	class ref_snz_uid;
	var Maternal_Edu_&msd_left_yr.-Maternal_Edu_&last_anal_yr.;
	output out=&projectlib.._&rel._mat_edu_BDD_&date(drop=_: rename=ref_snz_uid=snz_uid) max=;
run;

*Part3;

data TEMP_student_qual; 
set moe.student_qualification;
	format nzqaloadeddate1 date9.;
	qual=moe_sql_qual_code;
	result=moe_sql_exam_result_code;
	awardingschool=moe_sql_award_provider_code;
	level=moe_sql_nqf_level_code;
	year=moe_sql_attained_year_nbr;
	end_year=moe_sql_endorsed_year_nbr;
	nzqaloadeddate1=input(compress(moe_sql_nzqa_load_date,"-"),yymmdd10.);
load_year=year(nzqaloadeddate1);
run;

proc sql;
create table TEMP_sec_qual as
select distinct
      *
from TEMP_student_qual 
where snz_uid in (select parent from TEMP_mother)
order by qual;
quit;

proc sort data=sandmoe.moe_qualification_lookup 
out=TEMP_qual_lookup(rename=qualificationtableid=qual); by qualificationtableid;
run;

DATA TEMP_sec_qual_event;
	merge TEMP_sec_qual(in=a) TEMP_qual_lookup(in=b);
	by qual;

	if a;
HA=0;
if NQFlevel in (0,.) then delete;

if year < 2003 then delete; 
if year>=&first_anal_yr and year<=&last_anal_yr;

if nqflevel >= 4 and QualificationType=21 then ha=41;
else if nqflevel >= 4 and QualificationType=10 then ha=40;
else if nqflevel >= 4 then ha=42;
else if qualificationcode='1039' and result='E' then HA=39;
else if qualificationcode='1039' and result='M' then HA=38;
else if qualificationcode='1039' and result='ZZ' then HA=37;
else if qualificationcode='1039' and result='N' then HA=36;
else if nqflevel=3 then HA=35;
else if (qualificationcode='0973' or qualificationcode='973') and result='E' then HA=29;
else if (qualificationcode='0973' or qualificationcode='973') and result='M' then HA=28;
else if (qualificationcode='0973' or qualificationcode='973') and result='ZZ' then HA=27;
else if (qualificationcode='0973' or qualificationcode='973') and result='N' then HA=26;
else if nqflevel=2 then HA=25;
else if (qualificationcode='0928' or qualificationcode='928') and result='E' then HA=19;
else if (qualificationcode='0928' or qualificationcode='928') and result='M' then HA=18;
else if (qualificationcode='0928' or qualificationcode='928') and result='ZZ' then HA=17;
else if (qualificationcode='0928' or qualificationcode='928') and result='N' then HA=16;
else if nqflevel=1 then HA=15;

level=0;
if HA in (19,18,17,16,15) then level=1;
if HA in (29,28,27,26,25) then level=2;
if HA in (39,38,37,36,35) then level=3;
if HA in (42,41,40) then level=4;

	qual_type='SCH';
	format startdate enddate date9.;
	startdate=MDY(12,31,year);
	enddate=startdate;

	* Allows 2 years for loading qualifications;
	if year=load_year or load_year-year<=2 or load_year=.;
	keep snz_uid year startdate enddate qual level qual_type;
run;

proc sort data=TEMP_sec_qual_event nodupkey;
	by snz_uid year startdate enddate qual level qual_type;
run;

*Part 4;
proc sql;
	create table TEMP_TER_compl as
		select  snz_uid,
			moe_com_year_nbr,
			put(moe_com_qacc_code,$lv8idd.) as att_TER_qual_type,
			moe_com_qual_level_code as raw_level,
			moe_com_qual_nzsced_code
		from moe.completion
			where snz_uid in
				(select distinct parent from TEMP_mother)
					and MDY(12,31,moe_com_year_nbr)<="&sensor"d;
quit;

proc freq data=TEMP_ter_compl;
	tables att_TER_qual_type*raw_level/list missing;
run;

data TEMP_Ter_qual_event;
	set TEMP_Ter_compl;
	ter_qual=att_TER_qual_type*1;
	Ter_level=raw_level*1;
* Level 1-3 ;
	IF att_ter_qual_type=1 and (raw_level=. or raw_level=1) then
		level=1; 

	IF att_ter_qual_type=1 and raw_level=2 then
		level=2;
	IF att_ter_qual_type=1 and raw_level>=3 then
		level=3;
* Level 4;
	IF att_ter_qual_type=2 and (raw_level=. or raw_level<=4)  then
		level=4;
	IF att_ter_qual_type=2 and raw_level>4 then
		level=4;
* Tertiary diplomas;
	IF att_ter_qual_type=3 and (raw_level=. or raw_level<=5)  then
		level=5;
	IF att_ter_qual_type=3 and raw_level>=6 then
		level=6;
* Bachelor degrees;
	IF att_ter_qual_type=4 and (raw_level=. or raw_level<=7) then
		level=7;
* Postgraduate degrees ;
	IF att_ter_qual_type=6  then
		level=8;
* Masters and PHDs;
	IF att_ter_qual_type=7 then
		level=9;
	IF att_ter_qual_type=8  then
		level=10;
	qual_type='TER';
	format startdate enddate date9.;
	startdate=MDY(12,31,moe_com_year_nbr);
	enddate=startdate;
	if moe_com_year_nbr>=&first_anal_yr or moe_com_year_nbr<=&last_anal_yr;
year=moe_com_year_nbr;
keep snz_uid year startdate enddate level qual_type;
run;
*Part 5;
data TEMP_it TEMP_deletes;
	set moe.tec_it_learner;
	if moe_itl_programme_type_code in ("NC","TC");
	format startdate enddate date9.;
	startdate=input(compress(moe_itl_start_date,"-"),yymmdd10.);
	if moe_itl_end_date ne '' then
		enddate=input(compress(moe_itl_end_date,"-"),yymmdd10.);
	if moe_itl_end_date='' then
		enddate="&sensor"d;
	if startdate>"&sensor"d then
		output TEMP_deletes;
	if enddate>"&sensor"d then
		enddate="&sensor"d;
	if startdate>enddate then
		output TEMP_deletes;
	else output TEMP_it;
run;

proc sql;
	create table TEMP_it_qual as 
		SELECT distinct
			snz_uid
			,moe_itl_year_nbr as year 
			,startdate 
			,enddate
			,moe_itl_level1_qual_awarded_nbr as L1
			,moe_itl_level2_qual_awarded_nbr as L2
			,moe_itl_level3_qual_awarded_nbr as L3
			,moe_itl_level4_qual_awarded_nbr as L4
			,moe_itl_level5_qual_awarded_nbr as L5
			,moe_itl_level6_qual_awarded_nbr as L6
			,moe_itl_level7_qual_awarded_nbr as L7
			,moe_itl_level8_qual_awarded_nbr as L8
		FROM TEMP_IT
			WHERE snz_uid IN (select distinct parent from TEMP_mother)
				ORDER by snz_uid, year,startdate;
quit;

data TEMP_IT_qual_event; set TEMP_it_qual;
level=0;
	if L1=1 then level=1;
	if L2=1 then level=2;
	if L3=1 then level=3;
	if L4=1 then level=4;
	if L5=1 then level=4;
	if L6=1 then level=4;
	if L7=1 then level=4;
	if L8=1 then level=4;
if level>0;
startdate=enddate;
qual_type='ITL';
keep snz_uid startdate enddate level qual_type year;
run;
* Part 6;
proc sort data=TEMP_SEC_QUAL_EVENT; by snz_uid;
proc sort data=TEMP_TER_QUAL_EVENT; by snz_uid;
proc sort data=TEMP_IT_QUAL_EVENT; by snz_uid;
data TEMP_Qual_event;
	set TEMP_SEC_QUAL_EVENT TEMP_TER_QUAL_EVENT TEMP_IT_QUAL_EVENT;
	by snz_uid;
drop qual;
run;
*part 7;

proc sql;
create table TEMP_Mother_qual_event
as select
	a.snz_uid as mother,
	a.startdate,
	a.enddate,
	a.qual_type,
	a.level,
	b.snz_uid,
	b.DOB
from  TEMP_Qual_event a inner join TEMP_mother b
on a.snz_uid=b.parent;

data TEMP_qual_event_at_age;
	set TEMP_Mother_qual_event;
	array Maternal_edu_at_age_(*) Maternal_edu_at_age_&firstage- Maternal_edu_at_age_&lastage;

	do ind = &firstage to &lastage;
		i=ind-(&firstage-1);

		start_window=intnx('YEAR',DOB,i-1,'S');
		end_window=intnx('YEAR',DOB,i,'S');

		* events by selected birthdays;
		if ((startdate <end_window) and (startdate>=start_window)) then
			do;
				Maternal_edu_at_age_(i)=level;
			end;
		if startdate<DOB then Maternal_edu_prior_birth=level;
	end;
run;


data TEMP_qual_event_year;
	set TEMP_Mother_qual_event;
	array Maternal_edu_(*) Maternal_edu_&first_anal_yr.- Maternal_edu_&last_anal_yr.;

	do ind = &first_anal_yr. to &last_anal_yr.;
		i=ind-(&first_anal_yr.-1);

		start_window=intnx('YEAR',MDY(1,1,&first_anal_yr.),i-1,'S');
		end_window=intnx('YEAR',MDY(1,1,&first_anal_yr.),i,'S');

		* events by selected birthdays;
		if ((startdate <end_window) and (startdate>=start_window)) then
			do;
				Maternal_edu_(i)=level;
			end;
	
	end;
run;

proc summary data=TEMP_qual_event_at_age nway;
class snz_uid DOB;
var Maternal_edu_prior_birth Maternal_edu_at_age_&firstage- Maternal_edu_at_age_&lastage;
output out= _Mat_Edu_Ter_at_age_&date  (drop=_:) max=;
run; 

proc summary data=TEMP_qual_event_year nway;
class snz_uid DOB;
var Maternal_edu_&first_anal_yr.- Maternal_edu_&last_anal_yr.;
output out= _Mat_Edu_Ter_&date  (drop=_:) max=;
run; 

* Part 9;

data TEMP_MaternalEducation_year;
	set &projectlib.._&rel._Mat_Edu_BDD_&date (in=a)
	    _Mat_Edu_Ter_&date (in=b);
run;

data TEMP_MaternalEducation_at_age;
	set &projectlib.._&rel._Mat_Edu_BDD_at_age_&date (in=a)
	    _Mat_Edu_Ter_at_age_&date (in=b);
run;

proc summary data=TEMP_MaternalEducation_year nway;
	class snz_uid;
	var Maternal_Edu_&first_anal_yr.-Maternal_Edu_&last_anal_yr.;
	output out=&projectlib.._&rel._Mat_Edu_Com_&date(drop=_type_ _freq_) max=;
run;

proc summary data=TEMP_MaternalEducation_at_age nway;
	class snz_uid;
	var maternal_edu_prior_birth 
		Maternal_Edu_at_age_&firstage-Maternal_Edu_at_age_&lastage;
	output out=&projectlib.._&rel._Mat_Edu_Com_at_age_&date(drop=_type_ _freq_) max=;
run;
proc datasets lib=work;
delete temp_: _Mat_Edu_Ter_&date _Mat_Edu_Ter_at_age_&date ;
run;
%mend;