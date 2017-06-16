************************************************************************************************************************************
************************************************************************************************************************************

Creating monthly indicators for Infographics Tool 2 ( Youth Transitions )

************************************************************************************************************************************
************************************************************************************************************************************

**Part A. Select a broadly-defined birth cohort population for the purpose of compiling data, 
	we already have pre defined popualtion of 0-24 basedon ERP 2015; 

**Part B. Get data on NCEA credits and all qualification attainment, by calendar year;

**Part C. Create calendar month vectors of place of residence data, days spent overseas;

**Part D. Create calendar month vectors capturing other activities and income flows, including
      school and tertiary enrolment, industry training enrolment,
      employment,  earnings, benefit receipt,  custodial and community sentences served, student allowance receipt;

**Note that the numbering sequence used for all monthly vectors is based on the EMS (or LEED) data structure, 
    where the first calendar month is April 1999;

************************************************************************************************************************************
************************************************************************************************************************************;

************************************************************************************************************************************
************************************************************************************************************************************
**Part C;
**MONTHLY VECTORS OF RESIDENCE DATA, OVERSEAS DAYS;
**In the monthly vector numbering system, 1=April 1999;
************************************************************************************************************************************
************************************************************************************************************************************

********************************************************************************************************************************;
********************************************************************************************************************************;
***OVERSEAS DAYS PER MONTH;
********************************************************************************************************************************;
********************************************************************************************************************************;
**Count all days spent overseas in each calendar month from Jan 2004 to Jun 2015;
**Use LEED dates to index each month;

/*%let start='01Aug2012'd;*/
/*%let m=161; * 161-Aug 2012, 190- Jan 2015 , 188-Nov 2014;*/
/*%let n=206;* 201-dec 2015;  **207=June 2016;*/


%macro run_month_OS(population,by_year,start,m,n);
proc sql;
create table os_spells
as select snz_uid, 
   datepart(pos_applied_date) format date9.  as startdate, 
   datepart(pos_ceased_date) format date9. as enddate
from data.person_overseas_spell
where snz_uid IN 
             (SELECT DISTINCT snz_uid FROM &population ) 
order by snz_uid, startdate;
quit;

data os_spells2;
set os_spells;
	if year(enddate)=9999 then enddate='29Feb2016'd;
	if year(startdate)=1900 then startdate='30Jun1997'd;
run;

proc sort data=os_spells2;
by snz_uid startdate enddate;
run;

**Count all days spent overseas in each calendar month from Jan 2004 to Jun 2015;
**Use LEED dates to index each month;

data os_spells3(drop=i start_window end_window days);
set os_spells2;
array osdays [*] os_da_&m-os_da_&n ; * days os;
do i=1 to dim(osdays);
   start_window=intnx('month',&start.,i-1,'S');
   end_window=(intnx('month',&start.,i,'S'))-1;
   format start_window end_window date9.;  
   if not((startdate > end_window) or (enddate < start_window)) then do;	              
		            if (startdate <= start_window) and  (enddate > end_window) then days=(end_window-start_window)+1;
		            else if (startdate <= start_window) and  (enddate <= end_window) then days=(enddate-start_window)+1;
		            else if (startdate > start_window) and  (enddate <= end_window) then days=(enddate-startdate)+1;
		            else if (startdate > start_window) and  (enddate > end_window) then days=(end_window-startdate)+1;     	     
		            osdays[i]=days;				   
		         end;
	end;	          
run;

proc summary data=os_spells3 nway;
class snz_uid;
var os_da_&m-os_da_&n;
output out=project.YT_&by_year._mth_os(drop=_:)  sum=;
run;

proc means data=project.YT_&by_year._mth_os;
var os_da_&m-os_da_&n;
run;
%mend;

%run_month_OS(project.population_2015_0_24,2015,'01Aug2014'd,185,206);
%run_month_OS(project.population_2014_0_24,2014,'01Aug2013'd,173,194);
%run_month_OS(project.population_2013_0_24,2013,'01Aug2012'd,161,182);

%run_month_OS(project.population_2012_0_24,2012,'01Aug2011'd,149,170);

************************************************************************************************************************************
************************************************************************************************************************************
**PART D. SCHOOL ENROLMENT, TERTIARY ENROLMENT, INDUSTRY TRAINING ENROLMENT, 
     EMPLOYMENT AND BENEFIT RECEIPT HISTORY;
*****CORRECTIONS SENTENCES SERVED;
*****STUDENT ALLOWANCE RECEIVED; 
**all these are constructed as vectors of calendar month indicators, 
    with each month referenced using a EMS-based number sequence, where month 1 = April 1999;

********************************************************************************************************************************;
********************************************************************************************************************************;

**School enrolment monthly vectors;
********************************************************************************************************************************;
********************************************************************************************************************************;
%macro run_month_enr (population,by_year, start, m,n);

proc sql;
create table enrol
as select 
snz_uid
,input(compress(moe_esi_start_date,"-"),yymmdd10.) format date9. as startdate
,case when moe_esi_end_date is not null then input(compress(moe_esi_end_date,"-"),yymmdd10.) 
   else input(compress(moe_esi_extrtn_date,"-"),yymmdd10.) end format date9. as enddate
,input(moe_esi_provider_code, 10.) as schoolnbr
,moe_esi_domestic_status_code as domestic_status
,case when moe_esi_end_date='  ' then 1 else 0 end as sch_enddate_imputed
from moe.student_enrol
where snz_uid in (select distinct snz_uid from &population) and moe_esi_start_date is not null
order by snz_uid, startdate, enddate;
quit;

data enrol; set enrol;
if startdate<=enddate;
run;
**Removing any overlaps in enrolment;

%OVERLAP(enrol); 

**CODE FOR SCHOOL ENROLMENT MONTHS;

data enrol_month_temp  ;
set enrol_OR;
format start_window end_window date9.;
array sch_enr_id_(*) sch_enr_id_&m.-sch_enr_id_&n.; * end of jun2015;
array sch_enr_da_(*) sch_enr_da_&m.-sch_enr_da_&n.; * end of jun2015;

do ind=&m. to &n.; i=ind-&m.+1;
	sch_enr_id_(i)=0;
	sch_enr_da_(i)=0;
* overwriting start and end window as interval equal to one month;

start_window=intnx("month",&start.,i-1,"beginning"); * start is beg of the month;
end_window=intnx("month",&start.,i-1,"end");* end is end of the month;

if not((startdate > end_window) or (enddate < start_window)) then do;
	sch_enr_id_(i)=1; * creating inidcator of school enrolment;
	* measuring the days enrolled;
				if (startdate <= start_window) and  (enddate > end_window) then
					days=(end_window-start_window)+1;
				else if (startdate <= start_window) and  (enddate <= end_window) then
					days=(enddate-start_window)+1;
				else if (startdate > start_window) and  (enddate <= end_window) then
					days=(enddate-startdate)+1;
				else if (startdate > start_window) and  (enddate > end_window) then
					days=(end_window-startdate)+1;
				sch_enr_da_[i]=days*sch_enr_id_(i);

end;
end;
run;


proc means data=enrol_month_temp  ;
run;

proc summary data=enrol_month_temp nway;
class snz_uid ;
var sch_enr_id_&m.-sch_enr_id_&n.  sch_enr_da_&m.-sch_enr_da_&n.  sch_enddate_imputed;
output out=TEMP(drop=_:) sum=;
run;

data project.YT_&by_year._mth_sch_enrol(drop=ind i);
set temp;
if sum(of sch_enr_id_&m.-sch_enr_id_&n. )>0;
array sch_enr_id_(*) sch_enr_id_&m.-sch_enr_id_&n. ; 
array sch_enr_da_(*) sch_enr_da_&m.-sch_enr_da_&n. ; 
first_sch_enr_refmth=.;
last_sch_enr_refmth=.;
do ind=&m. to &n.; 
   i=ind-&m.+1;
   if sch_enr_id_[i]>1 then sch_enr_id_[i]=1;
   if sch_enr_id_[i]>=1 and first_sch_enr_refmth=. then first_sch_enr_refmth=ind;
   if sch_enr_id_[i]>=1 then last_sch_enr_refmth=ind;
   end;

run;
%mend;

%run_month_enr(project.population_2015_0_24,2015,'01Aug2014'd,185,206);
%run_month_enr(project.population_2014_0_24,2014,'01Aug2013'd,173,194);
%run_month_enr(project.population_2013_0_24,2013,'01Aug2012'd,161,182);

%run_month_enr(project.population_2012_0_24,2012,'01Aug2011'd,149,170);
********************************************************************************************************************************;
********************************************************************************************************************************;
**Tertiary enrolment monthly vectors;
**Now using formal programmes only for this vector ;
********************************************************************************************************************************;
********************************************************************************************************************************;
%macro run_month_ter_enr(population,by_year, start, m,n);
proc sql;
	create table enrol as
	SELECT distinct 
		snz_uid
		,moe_enr_year_nbr as year
		,input(moe_enr_prog_start_date,yymmdd10.) format date9.  as startdate
		,input(moe_enr_prog_end_date,yymmdd10.) format date9.  as enddate  
		,sum(moe_enr_efts_consumed_nbr) as EFTS_consumed
		,moe_enr_efts_prog_years_nbr as EFTS_prog_yrs
		,moe_enr_qacc_code as qacc
		,moe_enr_qual_code as Qual
		,moe_enr_prog_nzsced_code as NZSCED
		,moe_enr_funding_srce_code as fund_source
		,moe_enr_subsector_code as subsector 
		,moe_enr_qual_level_code as level
		,moe_enr_qual_type_code as qual_type
	FROM moe.enrolment 
		WHERE snz_uid IN 
		(SELECT DISTINCT snz_uid FROM &population) and moe_enr_year_nbr>=2003
		group by snz_uid, moe_enr_prog_start_date , moe_enr_prog_end_date, qual, NZSCED
			order by snz_uid;
quit;

proc sql;
create table enrol_1 as
select a.*,
b.DOB
from enrol a left join &population b
on a.snz_uid=b.snz_uid;
quit;


* Formating dates and creating clean enrolment file;
* Defining formal and informal enrolments;

data enrol_clean_formal;
	set enrol_1;
	if EFTS_consumed>0;
	dur=enddate-startdate;
	if dur>0;
	start_year=year(startdate);
	if start_year>=&first_anal_yr and start_year<=&last_anal_yr;
if qual_type="D" then Formal=1; 
if formal=1 then output;
run;

proc means data=enrol_clean_formal;
run;

**2% have programme durations of more than one year.  How do we know they remained enrolled;
**Might be best cut off enrolment at end of one year;

%overlap(enrol_clean_formal);


data TER_ENROL_MON_temp; 
set enrol_clean_formal_OR ;
format start_window end_window date9.;
array ter_enr_id_(*) ter_enr_id_&m.-ter_enr_id_&n.; 
array ter_enr_da_(*) ter_enr_da_&m.-ter_enr_da_&n.; 
do ind=&m. to &n.; i=ind-&m.+1;
	ter_enr_id_(i)=0;
	ter_enr_da_(i)=0;

start_window=intnx("month",&start.,i-1,"beginning"); * start is beg of the month;
end_window=intnx("month",&start.,i-1,"end");* end is end of the month;

if not((startdate > end_window) or (enddate < start_window)) then do;
	ter_enr_id_(i)=1; * creating inidcator of school enrolment;
	* measuring the days enrolled;
				if (startdate <= start_window) and  (enddate > end_window) then
					days=(end_window-start_window)+1;
				else if (startdate <= start_window) and  (enddate <= end_window) then
					days=(enddate-start_window)+1;
				else if (startdate > start_window) and  (enddate <= end_window) then
					days=(enddate-startdate)+1;
				else if (startdate > start_window) and  (enddate > end_window) then
					days=(end_window-startdate)+1;
				ter_enr_da_[i]=days*ter_enr_id_(i);
end;
end;
run;

proc summary data=TER_ENROL_MON_temp nway;
class snz_uid ;
var ter_enr_id_&m.-ter_enr_id_&n.  ter_enr_da_&m.-ter_enr_da_&n.; 
output out=mth_ter_enrol(drop=_:) sum=;
run;

data project.YT_&by_year._mth_ter_enrol;
set mth_ter_enrol;
array ter_enr_id_(*) ter_enr_id_&m.-ter_enr_id_&n.; 
do ind=&m. to &n.; i=ind-&m.+1;
   if ter_enr_id_[i]>1 then ter_enr_id_[i]=1;
   end;
drop ind i;
run;

proc means data=project.YT_&by_year._mth_ter_enrol;
run;
%mend;

%run_month_ter_enr(project.population_2015_0_24,2015,'01Aug2014'd,185,206);
%run_month_ter_enr(project.population_2014_0_24,2014,'01Aug2013'd,173,194);
%run_month_ter_enr(project.population_2013_0_24,2013,'01Aug2012'd,161,182);

%run_month_ter_enr(project.population_2012_0_24,2012,'01Aug2011'd,149,170);
********************************************************************************************************************************;
********************************************************************************************************************************;
****Employment;
**I choose to select data from 2006 onwards but the first available month is April 1999;
********************************************************************************************************************************;
********************************************************************************************************************************;


%macro run_month_earn (population,by_year,start,m,n);

%macro select(year);

proc sql;
create table WNS_&year. as 
   select snz_uid, 
    inc_cal_yr_year_nbr as year,
      sum(inc_cal_yr_mth_01_amt) as earn1,
	  sum(inc_cal_yr_mth_02_amt) as earn2,
      sum(inc_cal_yr_mth_03_amt) as earn3,
      sum(inc_cal_yr_mth_04_amt) as earn4,
      sum(inc_cal_yr_mth_05_amt) as earn5,
	  sum(inc_cal_yr_mth_06_amt) as earn6,
      sum(inc_cal_yr_mth_07_amt) as earn7,
      sum(inc_cal_yr_mth_08_amt) as earn8,
      sum(inc_cal_yr_mth_09_amt) as earn9,
      sum(inc_cal_yr_mth_10_amt) as earn10,
      sum(inc_cal_yr_mth_11_amt) as earn11,
      sum(inc_cal_yr_mth_12_amt) as earn12   
    from data.income_cal_yr
    where inc_cal_yr_income_source_code = 'W&S' and inc_cal_yr_year_nbr=&year. and snz_uid in (SELECT DISTINCT snz_uid FROM &population.) 
    group by snz_uid, year
    order by snz_uid;
quit;

* Self-employment income;
Proc sql;
		create table sei_&year. as 
		SELECT  distinct 
			snz_uid,			
			inc_tax_yr_year_nbr-1 as year,
			MDY(4,1,inc_tax_yr_year_nbr-1) AS startdate format date9.,
			MDY(3,31,inc_tax_yr_year_nbr) AS enddate format date9.,
			sum(inc_tax_yr_tot_yr_amt) AS gross_earnings_amt
	FROM  data.income_tax_yr 
WHERE snz_uid in (SELECT DISTINCT snz_uid FROM &population.) and (inc_tax_yr_year_nbr-1=&year. or inc_tax_yr_year_nbr=&year.)
	AND inc_tax_yr_income_source_code in ('P00', 'P01', 'P02', 'C00', 'C01', 'C02', 'S00', 'S01', 'S02', 'S03')
	GROUP BY snz_uid 
order by snz_uid ;
quit;

* a bit of transformation;
data  sei_&year.; set  sei_&year.;
if gross_earnings_amt>0;
rate=gross_earnings_amt/(enddate-startdate+1);
array earn(*) earn1-earn12;
do ind=1 to 12;
	earn(ind)=0;
			start_window=intnx('MONTH',MDY(1,1,&year.),ind-1,'S');
			end_window=intnx('MONTH',MDY(1,1,&year.),ind,'S')-1;
	if not((startdate > end_window) or (enddate < start_window)) then do;
			
					if (startdate <= start_window) and  (enddate > end_window) then
						days=(end_window-start_window)+1;
					else if (startdate <= start_window) and  (enddate <= end_window) then
						days=(enddate-start_window)+1;
					else if (startdate > start_window) and  (enddate <= end_window) then
						days=(enddate-startdate)+1;
					else if (startdate > start_window) and  (enddate > end_window) then
						days=(end_window-startdate)+1;	

					earn(ind)=rate*days; 
	end;
end;
run;

proc summary data=sei_&year. nway;
class snz_uid;
var earn: ;
output out=SEI_sum_&year.(keep=snz_uid earn:) sum=;
run;

data total&year.; set WNS_&year. sei_sum_&year.; run;

proc summary data=Total&year. nway;
class snz_uid;
var earn: ;
output out=EARNERS&year.(keep=snz_uid earn:) sum=;
run;
%mend select;
/**/
/*%select(2006);*/
/*%select(2007);*/
/*%select(2008);*/
/*%select(2009);*/
/*%select(2010);*/
/*%select(2011);*/
%select(2012);
%select(2013);
%select(2014);
%select(2015);
%select(2016);

**Convert earnings data to Dec 2015 $ values;
**Disregard months where monthly earnings are less than $10;

data project.YT_&by_year._mth_emp(keep=snz_uid emp&m-emp&n rearn&m-rearn&n);
merge
/*  earners2006(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn82-earn93))*/
/*  earners2007(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn94-earn105))*/
/*  earners2008(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn106-earn117)) */
/*  earners2009(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn118-earn129))*/
/*  earners2010(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn130-earn141))*/
/*  earners2011(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn142-earn153))*/
  earners2012(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn154-earn165)) 
  earners2013(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn166-earn177))
  earners2014(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn178-earn189))
  earners2015(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn190-earn201))
  earners2016(keep=snz_uid earn1-earn6 rename=(earn1-earn6=earn202-earn207));
by snz_uid;
array earn(*) earn&m-earn&n;
array rearn(*) rearn&m-rearn&n;
array emp(*) emp&m-emp&n;
do i=&m to &n;
    if i<=48 then rearn(i-&m+1) = earn(i-&m+1)*1198/913;
    else if i<=51 then rearn(i-&m+1) = earn(i-&m+1)*1198/913;
    else if i<=54 then rearn(i-&m+1) = earn(i-&m+1)*1198/918;
    else if i<=57 then rearn(i-&m+1) = earn(i-&m+1)*1198/924;
    else if i<=60 then rearn(i-&m+1) = earn(i-&m+1)*1198/928;
    else if i<=63 then rearn(i-&m+1) = earn(i-&m+1)*1198/935;
    else if i<=66 then rearn(i-&m+1) = earn(i-&m+1)*1198/941;
    else if i<=69 then rearn(i-&m+1) = earn(i-&m+1)*1198/949;
    else if i<=72 then rearn(i-&m+1) = earn(i-&m+1)*1198/953;
    else if i<=75 then rearn(i-&m+1) = earn(i-&m+1)*1198/962;
    else if i<=78 then rearn(i-&m+1) = earn(i-&m+1)*1198/973;
    else if i<=81 then rearn(i-&m+1) = earn(i-&m+1)*1198/979;
    else if i<=84 then rearn(i-&m+1) = earn(i-&m+1)*1198/985;
    else if i<=87 then rearn(i-&m+1) = earn(i-&m+1)*1198/1000;
    else if i<=90 then rearn(i-&m+1) = earn(i-&m+1)*1198/1007;
    else if i<=93 then rearn(i-&m+1) = earn(i-&m+1)*1198/1005;
    else if i<=96 then rearn(i-&m+1) = earn(i-&m+1)*1198/1010;
    else if i<=99  then rearn(i-&m+1) = earn(i-&m+1)*1198/1020;
    else if i<=102 then rearn(i-&m+1) = earn(i-&m+1)*1198/1025;
    else if i<=105 then rearn(i-&m+1) = earn(i-&m+1)*1198/1037;
    else if i<=108 then rearn(i-&m+1) = earn(i-&m+1)*1198/1044;
    else if i<=111 then rearn(i-&m+1) = earn(i-&m+1)*1198/1061;
    else if i<=114 then rearn(i-&m+1) = earn(i-&m+1)*1198/1077;
    else if i<=117 then rearn(i-&m+1) = earn(i-&m+1)*1198/1072;
    else if i<=120 then rearn(i-&m+1) = earn(i-&m+1)*1198/1075;    
    else if i<=123 then rearn(i-&m+1) = earn(i-&m+1)*1198/1081;
    else if i<=126 then rearn(i-&m+1) = earn(i-&m+1)*1198/1095;
    else if i<=129 then rearn(i-&m+1) = earn(i-&m+1)*1198/1093;  
    else if i<=132 then rearn(i-&m+1) = earn(i-&m+1)*1198/1097;   
    else if i<=135 then rearn(i-&m+1) = earn(i-&m+1)*1198/1099;
    else if i<=138 then rearn(i-&m+1) = earn(i-&m+1)*1198/1111;
    else if i<=141 then rearn(i-&m+1) = earn(i-&m+1)*1198/1137;
    else if i<=144 then rearn(i-&m+1) = earn(i-&m+1)*1198/1146;   
    else if i<=147 then rearn(i-&m+1) = earn(i-&m+1)*1198/1157;   
    else if i<=150 then rearn(i-&m+1) = earn(i-&m+1)*1198/1162;
    else if i<=153 then rearn(i-&m+1) = earn(i-&m+1)*1198/1158;  * 1176 Dec 2011 ;  
    else if i<=156 then rearn(i-&m+1) = earn(i-&m+1)*1198/1164;
    else if i<=159 then rearn(i-&m+1) = earn(i-&m+1)*1198/1168;   
    else if i<=162 then rearn(i-&m+1) = earn(i-&m+1)*1198/1171;
    else if i<=165 then rearn(i-&m+1) = earn(i-&m+1)*1198/1169;  * Dec 2012;  
    else if i<=168 then rearn(i-&m+1) = earn(i-&m+1)*1198/1174;
    else if i<=171 then rearn(i-&m+1) = earn(i-&m+1)*1198/1176;  * June 2013; 
    else if i<=174 then rearn(i-&m+1) = earn(i-&m+1)*1198/1187;   
    else if i<=177 then rearn(i-&m+1) = earn(i-&m+1)*1198/1188;  *Dec 2013;
	else if i<=180 then rearn(i-&m+1) = earn(i-&m+1)*1198/1192; *Mar 2014;
    else if i<=183 then rearn(i-&m+1) = earn(i-&m+1)*1198/1195; *Jun 2014;
	else if i<=186 then rearn(i-&m+1) = earn(i-&m+1)*1198/1199; *Sep 2014;
	else if i<=189 then rearn(i-&m+1) = earn(i-&m+1)*1198/1198; *Dec 2014;
    else if i<=192 then rearn(i-&m+1) = earn(i-&m+1)*1198/1195; *Mar 2015;
    else if i<=195 then rearn(i-&m+1) = earn(i-&m+1)*1198/1200; *Jun 2015;
else if i<=198 then rearn(i-&m+1) = earn(i-&m+1)*1198/1204; *sep2015;
else if i<=201 then rearn(i-&m+1) = earn(i-&m+1)*1198/1198; *dec 2015;
else if i<=204 then rearn(i-&m+1) = earn(i-&m+1)*1198/1200; *mar 2016;
else if i<=207 then rearn(i-&m+1) = earn(i-&m+1)*1198/1205; *jun 2016;
end;
do i=1 to dim(rearn);
if rearn(i)<10 then do; 
     emp(i)=0; 
	 rearn(i)=.; end;
else do; 
   emp(i)=1; 
   rearn(i)=round(rearn(i), 1); 
   if rearn(i)>500000 then rearn(i)=500000;
   end;
end;
run;


proc means data=project.YT_&by_year._mth_emp;
run;

%mend;

%run_month_earn(project.population_2015_0_24,2015,'01Aug2014'd,185,206);
%run_month_earn(project.population_2014_0_24,2014,'01Aug2013'd,173,194);
%run_month_earn(project.population_2013_0_24,2013,'01Aug2012'd,161,182);

%run_month_earn(project.population_2012_0_24,2012,'01Aug2011'd,149,170);

********************************************************************************************************************************;
********************************************************************************************************************************;

**Industry training monthly activity;
**Pick up temp dataset from the code that created IT quals, above;

********************************************************************************************************************************;
********************************************************************************************************************************;

* removing overlaps to count the days in IT programme;

**Industry training qualifications;
%macro run_month_it(population,by_year,start,m,n);
data it deletes;
	set moe.tec_it_learner;
if moe_itl_tot_credits_awarded_nbr>0 and moe_itl_sum_units_consumed_nbr>0;
if moe_itl_programme_type_code in ("NC","TC"); 
   **National certificate or Trade certificate - but nearly all are NC;
   *Limited credit programmes, Supplementary credit programmes, and records with missing
   prog type are not selected;
format startdate enddate date9.;
	startdate=input(compress(moe_itl_start_date,"-"),yymmdd10.);
    startyr=year(startdate);
	if moe_itl_end_date ne '' then
		enddate=input(compress(moe_itl_end_date,"-"),yymmdd10.);
	if moe_itl_end_date=' ' then do;
        it_enddate_imputed=1;
        enddate=input((strip(31)||strip(12)||strip(startyr)),ddmmyy8.);
		end;
	if startdate>enddate then
		output deletes;
	else output it;
run;

proc freq data=it;
tables startyr /list missing;
run;


proc sql;
	create table itl_event as 
		SELECT distinct
snz_uid,
moe_itl_fund_code,
startdate,
enddate,
it_enddate_imputed
,moe_itl_level1_qual_awarded_nbr as L1
			,moe_itl_level2_qual_awarded_nbr as L2
			,moe_itl_level3_qual_awarded_nbr as L3
			,moe_itl_level4_qual_awarded_nbr as L4
			,moe_itl_level5_qual_awarded_nbr as L5
			,moe_itl_level6_qual_awarded_nbr as L6
			,moe_itl_level7_qual_awarded_nbr as L7
			,moe_itl_level8_qual_awarded_nbr as L8
   FROM IT 
   WHERE snz_uid IN (select distinct snz_uid from &population)
   order by snz_uid, startdate;
quit;


%overlap(itl_event);

* Creating monthly arrays;

data itl_mth_temp; 
set itl_event_OR;
format start_window end_window date9.;

array itl_id_(*) itl_id_&m.-itl_id_&n.; 
array itl_da_(*)  itl_da_&m.-itl_da_&n.; 

do ind=&m. to &n.; i=ind-&m.+1;
	itl_id_(i)=0;
	itl_da_(i)=0;
	
	start_window=intnx("month",&start.,i-1,"beginning"); * start is beg of the month;
	end_window=intnx("month",&start.,i-1,"end");* end is end of the month;

if not((startdate > end_window) or (enddate < start_window)) then do;
    itl_id_(i)=1;
	* measuring the days overseas;
				if (startdate <= start_window) and  (enddate > end_window) then
					days=(end_window-start_window)+1;
				else if (startdate <= start_window) and  (enddate <= end_window) then
					days=(enddate-start_window)+1;
				else if (startdate > start_window) and  (enddate <= end_window) then
					days=(enddate-startdate)+1;
				else if (startdate > start_window) and  (enddate > end_window) then
					days=(end_window-startdate)+1;
				itl_da_[i]=days*itl_id_(i);				
	end;
end;
run;

* Industry training data are available from Jan 2003 ;
proc summary data=ITL_MTH_TEMP nway;
class snz_uid ;
var itl_id_&m.-itl_id_&n. itl_da_&m.-itl_da_&n.; 
output out=MTH_ITL_ENR (drop=_:) sum=;
run;

proc means data=MTH_ITL_ENR;
run;

data MTH_IT_ENR_2(drop=i);
set MTH_ITL_ENR ;
array itl_id_(*) itl_id_&m.-itl_id_&n.; 
do i=1 to dim(itl_id_);
   if itl_id_(i)>=1 then itl_id_(i)=1;
   end;
run;

**If person was not employed in a given month, set their IT activity measures to zero;

data combine;
merge MTH_IT_ENR_2(in=a) project.YT_&by_year._mth_emp(keep=snz_uid emp&m.-emp&n.);
by snz_uid;
if a;
array ita(*) itl_id_&m.-itl_id_&n.;
array itb(*) itl_da_&m.-itl_da_&n.; 
array emp(*) emp&m.-emp&n.;
do i=1 to dim(ita);
  if emp(i)~=1 then do;
     ita(i)=0;
	 itb(i)=0;
	 end;
	 end;
run;

proc means data=combine;
run;

data project.YT_&by_year._mth_it_enrol;
set combine(keep=snz_uid itl_id_&m.-itl_id_&n. itl_da_&m.-itl_da_&n.); 
run;
%mend;


%run_month_it(project.population_2015_0_24,2015,'01Aug2014'd,185,206);
%run_month_it(project.population_2014_0_24,2014,'01Aug2013'd,173,194);
%run_month_it(project.population_2013_0_24,2013,'01Aug2012'd,161,182);

%run_month_it(project.population_2012_0_24,2012,'01Aug2011'd,149,170);

********************************************************************************************************************************;
********************************************************************************************************************************;
**Monthly vectors of adult or youth benefit receipt -using Sarah's code;
**This code draws on the benefit spell datasets;
**An alternative and simpler method is to use the first tier benefit expenditure dataset - but the results won't be the same;
********************************************************************************************************************************;
********************************************************************************************************************************;

proc format ;
VALUE $bengp_pre2013wr                  /* Jane suggest to add the old format */
    '020','320' = "Invalid's Benefit"
    '030','330' = "Widow's Benefit"
    '040','044','340','344'
                = "Orphan's and Unsupported Child's benefits"
    '050','350','180','181'
    = "New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
    '115','604','605','610'
                = "Unemployment Benefit and Unemployment Benefit Hardship"
    '125','608' = "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"
    '313','613','365','665','366','666','367','667'
                = "Domestic Purposes related benefits"
    '600','601' = "Sickness Benefit and Sickness Benefit Hardship"
    '602','603' = "Job Search Allowance and Independant Youth Benefit"
    '607'       = "Unemployment Benefit Student Hardship"
    '609','611' = "Emergency Benefit"
    '839','275' = "Non Beneficiary"
    'YP ','YPP' = "Youth Payment and Young Parent Payment"
        ' '     = "No Benefit"
 ;

value $bennewgp 

'020'=	"Invalid's Benefit"
'320'=	"Invalid's Benefit"

'330'=	"Widow's Benefit"
'030'=	"Widow's Benefit"

'040'=	"Orphan's and Unsupported Child's benefits"
'044'=	"Orphan's and Unsupported Child's benefits"
'340'=	"Orphan's and Unsupported Child's benefits"
'344'=	"Orphan's and Unsupported Child's benefits"

'050'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
'180'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
'181'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
'350'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"

'115'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'604'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'605'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'610'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'607'=	"Unemployment Benefit Student Hardship"
'608'=	"Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"
'125'=	"Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"


'313'=  "Domestic Purposes related benefits"
'365'=	"Sole Parent Support "					/* renamed */
'366'=	"Domestic Purposes related benefits"
'367'=	"Domestic Purposes related benefits"
'613'=	"Domestic Purposes related benefits"
'665'=	"Domestic Purposes related benefits"
'666'=	"Domestic Purposes related benefits"
'667'=	"Domestic Purposes related benefits"

'600'=	"Sickness Benefit and Sickness Benefit Hardship"
'601'=	"Sickness Benefit and Sickness Benefit Hardship"

'602'=	"Job Search Allowance and Independant Youth Benefit"
'603'=	"Job Search Allowance and Independant Youth Benefit"

'611'=	"Emergency Benefit"

'315'=	"Family Capitalisation"
'461'=	"Unknown"
'000'=	"No Benefit"
'839'=	"Non Beneficiary"

/* new codes */
'370'=  "Supported Living Payment related"
'675'=  "Job Seeker related"
'500'=  "Work Bonus"
;
run  ;

proc format;
value $ADDSERV
'YP'	='Youth Payment'
'YPP'	='Young Parent Payment'
'CARE'	='Carers'
'FTJS1'	='Job seeker Work Ready '
'FTJS2'	='Job seeker Work Ready Hardship'
'FTJS3'	='Job seeker Work Ready Training'
'FTJS4'	='Job seeker Work Ready Training Hardship'
'MED1'	='Job seeker Health Condition and Disability'
'MED2'	='Job seeker Health Condition and Disability Hardship'
'PSMED'	='Health Condition and Disability'
''		='.';
run;

%let sensor=30Jun2016;

%macro run_month_ben(population,by_year, start,m,n);
data msd_spel; 
   set msd.msd_spell;
* Formating dates and sensoring;
	format startdate enddate spellfrom spellto date9.;
	spellfrom=input(compress(msd_spel_spell_start_date,"-"),yymmdd10.);
	spellto=input(compress(msd_spel_spell_end_date,"-"),yymmdd10.);
	if spellfrom<"&sensor"d;
	if spellto>"&sensor"d then spellto="&sensor"d;
	if spellto=. then spellto="&sensor"d;
	startdate=spellfrom;
	enddate=spellto;

	if msd_spel_prewr3_servf_code='' then prereform=put(msd_spel_servf_code, $bengp_pre2013wr.); 
	else prereform=put(msd_spel_prewr3_servf_code,$bengp_pre2013wr.);	

* applying wider groupings;
length ben ben_new $20.;
if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='dpb';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='ib';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='ub';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='iyb';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='sb';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='ucb';
else ben='oth';

length benefit_desc_new $50;
servf=msd_spel_servf_code;
additional_service_data=msd_spel_add_servf_code;
	if  servf in ('602', /* Job Search Allowance - a discontinued youth benefit */
				 '603') /* IYB then aft 2012 Youth/Young Parent Payment */	 
		and additional_service_data ne 'YPP' then benefit_desc_new='1: YP Youth Payment Related' ;/* in 2012 changes some young DPB-SP+EMA moved to YPP */

	else if servf in ('313')   /* EMA(many were young mums who moved to YPP aft 2012) */
		or additional_service_data='YPP' then benefit_desc_new='1: YPP Youth Payment Related' ;
  
	else if  (servf in (
				   '115', /* UB Hardship */
                   '610', /* UB */
                   '611', /* Emergency Benefit (UB for those that did not qualify)*/
				   '030', /* B4 2012 was MOST WB, now just WB paid overseas) */ 
				   '330', /* Widows Benefit (weekly, old payment system) */ 
				   '366', /* DPB Woman Alone (weekly, old payment system) */
				   '666'))/* DPB Woman Alone */
		or (servf in ('675') and additional_service_data in (
					'FTJS1', /* JS Work Ready */
					'FTJS2')) /* JS Work Ready Hardship */
			
		then benefit_desc_new='2: Job Seeker Work Ready Related'; 

	else if  (servf in ('607', /* UB Student Hardship (mostly over summer holidays)*/ 
				   '608')) /* UB Training */
        or (servf in ('675') and additional_service_data in (
					'FTJS3', /* JS Work Ready Training */
					'FTJS4'))/* JS Work Ready Training Hardship */
		then benefit_desc_new='2: Job Seeker Work Ready Training Related'; 


	else if (servf in('600', /* Sickness Benefit */
				  '601')) /* Sickness Benefit Hardship */ 
		or (servf in ('675') and additional_service_data in (
				'MED1',   /* JS HC&D */
				'MED2'))  /* JS HC&D Hardship */
		then benefit_desc_new='3: Job Seeker HC&D Related' ;

	else if servf in ('313',   /* Emergency Maintenance Allowance (weekly) */
				   
				   '365',   /* B4 2012 DPB-SP (weekly), now Sole Parent Support */
				   '665' )  /* DPB-SP (aft 2012 is just for those paid o'seas)*/
		then benefit_desc_new='4: Sole Parent Support Related' ;/*NB young parents in YPP since 2012*/

	else if (servf in ('370') and additional_service_data in (
						'PSMED', /* SLP */
						'')) /* SLP paid overseas(?)*/ 
		or (servf ='320')    /* Invalids Benefit */
		or (servf='020')     /* B4 2012 020 was ALL IB, now just old IB paid o'seas(?)*/
		then benefit_desc_new='5: Supported Living Payment HC&D Related' ;

	else if (servf in ('370') and additional_service_data in ('CARE')) 
		or (servf in ('367',  /* DPB - Care of Sick or Infirm */
					  '667')) /* DPB - Care of Sick or Infirm */
		then benefit_desc_new='6: Supported Living Payment Carer Related' ;

	else if servf in ('999') /* merged in later by Corrections... */
		then benefit_desc_new='7: Student Allowance';

	else if (servf = '050' ) /* Transitional Retirement Benefit - long since stopped! */
		then benefit_desc_new='Other' ;

	else if benefit_desc_new='Unknown'   /* hopefully none of these!! */;

* applying wider groupings;
if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='DPB';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='IB';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='UB';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='IYB';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='SB';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='UCB';
else ben='OTHBEN';

if benefit_desc_new='2: Job Seeker Work Ready Training Related' then ben_new='JSWR_TR';
else if benefit_desc_new='1: YP Youth Payment Related' then ben_new='YP';
else if benefit_desc_new='1: YPP Youth Payment Related' then ben_new='YPP';
else if benefit_desc_new='2: Job Seeker Work Ready Related' then ben_new='JSWR';

else if benefit_desc_new='3: Job Seeker HC&D Related' then ben_new='JSHCD';
else if benefit_desc_new='4: Sole Parent Support Related' then ben_new='SPSR';
else if benefit_desc_new='5: Supported Living Payment HC&D Related' then ben_new='SLP_HCD';
else if benefit_desc_new='6: Supported Living Payment Carer Related' then ben_new='SLP_C';
else if benefit_desc_new='7: Student Allowance' then ben_new='SA';

else if benefit_desc_new='Other' then ben_new='OTH';
if prereform='370' and ben_new='SLP_C' then ben='DPB';
if prereform='370' and ben_new='SLP_HCD' then ben='IB';

if prereform='675' and ben_new='JSHCD' then ben='SB';
if prereform='675' and (ben_new ='JSWR' or ben_new='JSWR_TR') then ben='UB';
run;


* BDD spell dataset;
data msd_spel;
	set msd_spel;
	spell=msd_spel_spell_nbr;
	keep snz_uid spell servf spellfrom spellto ben ben_new;
run;

proc sort data=msd_spel out=mainbenefits(rename=(spellfrom=startdate spellto=enddate));
	by snz_uid spell spellfrom spellto;
run;

* BDD partner spell table;
data icd_bdd_ptnr;
	set msd.msd_partner;
	format ptnrfrom ptnrto date9.;
	spell=msd_ptnr_spell_nbr;
	ptnrfrom=input(compress(msd_ptnr_ptnr_from_date,"-"), yymmdd10.);
	ptnrto=input(compress(msd_ptnr_ptnr_to_date,"-"), yymmdd10.);

	* Sensoring;
	if ptnrfrom>"&sensor"d then
		delete;

	if ptnrto=. then
		ptnrto="&sensor"d;

	if ptnrto>"&sensor"d then
		ptnrto="&sensor"d;
	keep snz_uid partner_snz_uid spell ptnrfrom ptnrto;
run;

* EXTRACTING MAIN BENEFIT AS PRIMARY;
proc sql;
	create table prim_mainben_prim_data as
		select
			s.snz_uid, s.spellfrom as startdate, s.spellto as enddate, s.ben, s.ben_new, s.spell,
			t.DOB
		from
			msd_spel  s inner join &population t
			on t.snz_uid= s.snz_uid;
run;

proc sql;
	create table prim_mainben_part_data as
		select
			s.partner_snz_uid, s.ptnrfrom as startdate, s.ptnrto as enddate,s.spell,
			s.snz_uid as main_snz_uid,
			t.DOB
		from  icd_bdd_ptnr  s inner join &population t
			on t.snz_uid = s.partner_snz_uid
		order by s.snz_uid, s.spell;


proc sort data=mainbenefits out=main nodupkey;
	by snz_uid spell startdate enddate;
run;

proc sort data=prim_mainben_part_data out=partner(rename=(main_snz_uid=snz_uid)) nodupkey;
	by main_snz_uid spell startdate enddate;
run;

data fullymatched  unmatched(drop=ben ben_new servf);
	merge partner (in = a)
		main (in = b);
	by snz_uid spell startdate enddate;

	if a and b then
		output fullymatched;
	else if a and not b then
		output unmatched;
run;

proc sql;
	create table partlymatched as
		select a.partner_snz_uid, a.snz_uid, a.spell, a.dob, a.startdate, a.enddate,
			b.ben, b.ben_new, b.servf
		from unmatched a left join main b
			on a.snz_uid=b.snz_uid and a.spell=b.spell and a.startdate>=b.startdate and (a.enddate<=b.enddate or b.enddate=.) ;
quit;
run;

data prim_mainben_part_data_2;
	set fullymatched partlymatched;
run;

proc freq data=prim_mainben_part_data_2;
	tables ben_new ben;
run;

data prim_bennzs_data_1 del;
	set prim_mainben_prim_data (in=a)
		prim_mainben_part_data_2 (in=b);
	if b then
		snz_uid=partner_snz_uid;

	if startdate<DOB then
		output del;
	else output prim_bennzs_data_1;
run;

proc sort data = prim_bennzs_data_1;
	by snz_uid startdate enddate;
run;

%overlap(prim_bennzs_data_1);

proc freq data=prim_bennzs_data_1;
tables enddate /list missing;


data ben_TEMP; 
set PRIM_BENNZS_DATA_1_OR(keep=snz_uid startdate enddate);
format start_window end_window date9.;

array ben_id_(*) ben_id_&m.-ben_id_&n.; 
array ben_da_(*) ben_da_&m.-ben_da_&n.; 

do ind=&m. to &n.; i=ind-&m.+1;
	ben_id_(i)=0;

start_window=intnx("month",&start.,i-1,"beginning"); * start is beg of the month;
end_window=intnx("month",&start.,i-1,"end");* end is end of the month;
if not((startdate > end_window) or (enddate < start_window)) then do;
	ben_id_(i)=1; * creating inidcator of school enrolment;
	* measuring the days enrolled;
				if (startdate <= start_window) and  (enddate > end_window) then
					days=(end_window-start_window)+1;
				else if (startdate <= start_window) and  (enddate <= end_window) then
					days=(enddate-start_window)+1;
				else if (startdate > start_window) and  (enddate <= end_window) then
					days=(enddate-startdate)+1;
				else if (startdate > start_window) and  (enddate > end_window) then
					days=(end_window-startdate)+1;
				ben_da_[i]=days*ben_id_(i);
end;
end;
run;

proc summary data=ben_temp nway;
class snz_uid ;
var ben_id_&m.-ben_id_&n. ben_da_&m.-ben_da_&n.;
output out=ben_mon_enrol(drop=_:) sum=;
run;

data project.YT_&by_year._mth_ben(drop=i);
set ben_mon_enrol;
array ben_id_(*) ben_id_&m.-ben_id_&n.; 
do i=1 to dim(ben_id_);
   if ben_id_(i)>=1 then ben_id_(i)=1;
   end;
run;

proc means data=project.YT_&by_year._mth_ben;
run;

%mend;

%run_month_ben(project.population_2015_0_24,2015,'01Aug2014'd,185,206);
%run_month_ben(project.population_2014_0_24,2014,'01Aug2013'd,173,194);
%run_month_ben(project.population_2013_0_24,2013,'01Aug2012'd,161,182);

%run_month_ben(project.population_2012_0_24,2012,'01Aug2011'd,149,170);

********************************************************************************************************************************;
********************************************************************************************************************************;
***ANY CUSTODIAL OR COMMUNITY SENTENCES SERVED;
**by month - from Jan 2006 to June 2015;
********************************************************************************************************************************;
********************************************************************************************************************************;
%macro run_month_corr(population,by_year,start,m,n);

proc sql;
Connect to sqlservr (server=WPRDSQL36\iLeed database=IDI_clean);
	create table COR as
		SELECT distinct 
		 snz_uid,
			input(cor_mmp_period_start_date,yymmdd10.) format date9. as startdate,
			input(cor_mmp_period_end_date, yymmdd10.)format date9. as enddate,
			cor_mmp_mmc_code,  
           /* Creating broader correction sentence groupings */
	    	(case when cor_mmp_mmc_code in ('PRISON','REMAND' ) then 'Custody'
			     
			when cor_mmp_mmc_code in ('HD_SENT','HD_SENT', 'HD_REL' 'COM_DET','CW','COM_PROG',
                 'COM_SERV' ,'OTH_COMM','INT_SUPER','SUPER','PERIODIC') then 'Comm'
                 else 'COR_OTHER' end) as sentence 
		FROM COR.ov_major_mgmt_periods 
		where snz_uid in (SELECT DISTINCT snz_uid FROM &population) 
		AND cor_mmp_mmc_code IN ('PRISON','REMAND','HD_SENT','HD_REL','PERIODIC',
			'COM_DET','CW','COM_PROG','COM_SERV','OTH_COMM','INT_SUPER','SUPER')        
		ORDER BY snz_uid,startdate;
quit;

proc means data=cor;
run;

proc sql;
create table COR_1 as select
a.* ,
b.DOB
from COR a left join &population b
on a.snz_uid=b.snz_uid;
quit;

data cor_2;
set cor_1;
**delete any spells that started before 14th birthday - probably wrong;
if startdate>=intnx('YEAR',DOB,14,'S');
run;


%OVERLAP (COR_2); 

data cor_spells(drop=i start_window end_window days);
set COR_2_OR;
array custdays [*] cust_da_&m.-cust_da_&n. ; 
array commdays [*] comm_da_&m.-comm_da_&n. ; 
do i=1 to dim(custdays);
   start_window=intnx('month',&start.,i-1,'S');
   end_window=(intnx('month',&start.,i,'S'))-1;
   format start_window end_window date9.;  
   if not((startdate > end_window) or (enddate < start_window)) and sentence='Custody' then do;	              
		            if (startdate <= start_window) and  (enddate > end_window) then days=(end_window-start_window)+1;
		            else if (startdate <= start_window) and  (enddate <= end_window) then days=(enddate-start_window)+1;
		            else if (startdate > start_window) and  (enddate <= end_window) then days=(enddate-startdate)+1;
		            else if (startdate > start_window) and  (enddate > end_window) then days=(end_window-startdate)+1;     	     
		            custdays[i]=days;	                 
		         end;
   if not((startdate > end_window) or (enddate < start_window)) and sentence='Comm' then do;	              
		            if (startdate <= start_window) and  (enddate > end_window) then days=(end_window-start_window)+1;
		            else if (startdate <= start_window) and  (enddate <= end_window) then days=(enddate-start_window)+1;
		            else if (startdate > start_window) and  (enddate <= end_window) then days=(enddate-startdate)+1;
		            else if (startdate > start_window) and  (enddate > end_window) then days=(end_window-startdate)+1;     	     
		            commdays[i]=days;	                 
		         end;
	end;	          
run;

proc summary data=cor_spells nway;
class snz_uid;
var cust_da_&m-cust_da_&n comm_da_&m.-comm_da_&n. ; 
output out=corr(drop=_:)  sum=;
run;

data project.YT_&by_year._mth_corrections(drop=i);
set corr;
array custdays [*] cust_da_&m-cust_da_&n ; 
array commdays [*] comm_da_&m-comm_da_&n ; 
array cust [*] cust_id_&m-cust_id_&n ; 
array comm [*] comm_id_&m-comm_id_&n ; 
do i=1 to dim(custdays);
   if custdays(i)>0 then cust(i)=1; else cust(i)=0;
   if commdays(i)>0 then comm(i)=1; else comm(i)=0;
   end;
run;

proc means data=project.YT_&by_year._mth_corrections;
run;

%mend;
%run_month_corr(project.population_2015_0_24,2015,'01Aug2014'd,185,206);
%run_month_corr(project.population_2014_0_24,2014,'01Aug2013'd,173,194);
%run_month_corr(project.population_2013_0_24,2013,'01Aug2012'd,161,182);

%run_month_corr(project.population_2012_0_24,2012,'01Aug2011'd,149,170);

************************************************************************************************************************************
************************************************************************************************************************************
THE END 
************************************************************************************************************************************
************************************************************************************************************************************;
