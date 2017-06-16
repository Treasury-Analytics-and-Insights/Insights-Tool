************************************************************************************************************************************
************************************************************************************************************************************
/*This program creates monthly 'main activity' indicators for all youth at a specific year of age, for each
  calendar month over a period of time, such as 2008-2014*/
/* the data will be used to generate pivot tables and graphs summarising the activities of different subgroups of children
   at different ages */
/* Main activity is prioritised */
/* The program draws on a series of monthly indicator datasets that were created for the youth service evalution. These
    were created for individuals in the 1990-99 cohorts, using the February IDI refresh */

/*
1. Death ( our Resident population excludes deceased people) 
2. Overseas>=15 days
3. In detention>=15 days
4. Still at school, and enrolled for at least one day in the month (enrolment gaps of 1 month or less will be filled in )
5. Enrolled in formal tertiary study or targeted training with at least 0.5 EFTS
6. Substantially employed (earning MW*30 hours a week*4.33) with industry training (at least 1 day in the month)
7. Substantially employed (earning MW*30 hours a week*4.33) without industry training 
8. Employed part-time or part-month (>$10 threshold)
10.Not employed, not in education or training - short term NEET spell
11. Not employed, not in education or training - long term NEET spell
*/


************************************************************************************************************************************;
************************************************************************************************************************************;
**Part A;
**select the birth cohorts and get demographics for them;
**here I select 1990-1999 birth years;
**Then I restrict to people who either have a birth record or have a perm residence approval by 31 Dec 2014;
************************************************************************************************************************************;
************************************************************************************************************************************;


*******************************************************************************;
***PART D CALENDAR MONTH ACTIVITY VECTORS;
***For 12 months -  covering the calendar months from Jan 2015 to Dec 2015;
**We are picking up data for the 5 months on either side of 2015 so we can calculate long-term NEET spells;
*******************************************************************************;

**WHAT WERE THEY ACTUALLY DOING?

**Overseas for at least 15 days in the calendar month;
/*%let a=185;  * Aug 2014;*/
/*%let b=206;  * May 2016;*/
/*%let z=22;  *length of the vector we are creating, 22 months ;*/

%macro transform_month_pop(population,by_year,a,b,z);
data project.YT_&by_year._os(drop=i os_da_&a-os_da_&b );
merge &population. (in=a keep=snz_uid ) project.YT_&by_year._mth_os(keep=snz_uid os_da_&a-os_da_&b); 
by snz_uid;
if a; 
array os[*] os_da_&a-os_da_&b; 
array nos[*] os1-os&z;
do i=1 to &z;
        nos(i)=os(i);
        if nos(i)>=15 then nos(i)=1;
        else nos(i)=0;	
	end;
run;

proc means data=project.YT_&by_year._os;
run;


***In custody for at least 15 days in the month;

data project.YT_&by_year._custody(drop=i cust_da_&a-cust_da_&b);
merge &population. (in=a keep=snz_uid ) project.YT_&by_year._mth_corrections(keep=snz_uid cust_da_&a-cust_da_&b); 
by snz_uid;
if a; 
array os[*] cust_da_&a-cust_da_&b; 
array nos[*] cust1-cust&z;
do i=1 to &z;
        nos(i)=os(i);
        if nos(i)>=15 then nos(i)=1;
        else nos(i)=0;	
	end;
run;

proc means data=project.YT_&by_year._custody;
run;


**Any industry training in the month - no matter how little;

proc means data=project.YT_&by_year._mth_it_enrol;
run;


data project.YT_&by_year._it(drop=i itl_da_&a-itl_da_&b);
merge &population. (in=a keep=snz_uid ) project.YT_&by_year._mth_it_enrol(keep=snz_uid itl_da_&a-itl_da_&b); 
by snz_uid;
if a; 
array os[*] itl_da_&a-itl_da_&b; 
array nos[*] it1-it&z;
do i=1 to &z;
        nos(i)=os(i);
        if nos(i)>=1 then nos(i)=1;
        else nos(i)=0;	
	end;
run;
proc means data=project.YT_&by_year._it;
run;


***Substantial employment during the month versus limited employment during the month;
**Using the full-time equivalent minimum wage as threshold;

%macro select(year);
* changed here version 3;

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


data emp(keep=snz_uid searn&a-searn&b learn&a-learn&b);
merge 
/*  earners2007(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn94-earn105))*/
/*  earners2008(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn106-earn117)) */
/*  earners2009(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn118-earn129))*/
/*  earners2010(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn130-earn141))*/
/*  earners2011(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn142-earn153))*/
  earners2012(keep=snz_uid earn1-earn12 rename=(earn8-earn12=earn161-earn165)) 
  earners2013(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn166-earn177))
  earners2014(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn178-earn189))
  earners2015(keep=snz_uid earn1-earn12 rename=(earn1-earn12=earn190-earn201))
  earners2016(keep=snz_uid earn1-earn6 rename=(earn1-earn6=earn202-earn207));
by snz_uid;
array earn(*) earn&a-earn&b;
array minwage(*) minw&a-minw&b;
%let x=184; **This is the adjustment factor between the LEED numbering sequence and the current one;
do i=1 to dim(earn);
if (i+&x.)<=96 then minwage(i)=10.25;
else if 97<=i+&x.<=108 then minwage(i)=11.25;
else if 109<=i+&x.<=120 then minwage(i)=12.00;
else if 121<=i+&x.<=132 then minwage(i)=12.50;
else if 133<=i+&x.<=144 then minwage(i)=12.75;
else if 145<=i+&x.<=156 then minwage(i)=13.00;
else if 157<=i+&x.<=168 then minwage(i)=13.50;
else if 169<=i+&x.<=180 then minwage(i)=13.75;
else if 181<=i+&x.<=192 then minwage(i)=14.25;
else if 193<=i+&x.<=204 then minwage(i)=14.75;
else if 205<=i+&x.<=207 then minwage(i)=15.25;
end;
array subearn(*) searn&a-searn&b;  *substantial earnings;
array lowearn(*) learn&a-learn&b;   * Limited earnings;
do i=1 to dim(subearn);
  if earn(i)>=minwage(i)*30*4.33 then subearn(i)=1; else subearn(i)=0;
  if earn(i)>=10 and earn(i)<minwage(i)*30*4.33 then lowearn(i)=1; else lowearn(i)=0;
end;
run;

data project.YT_&by_year._emp(drop=i searn&a-searn&b learn&a-learn&b 
    rename=(nsearn1-nsearn&z=searn1-searn&z  nlearn1-nlearn&z=learn1-learn&z));
merge &population.(in=a keep=snz_uid ) emp(keep=snz_uid searn&a-searn&b learn&a-learn&b); 
by snz_uid;
if a; 
array semp[*] searn&a-searn&b;
array lemp[*] learn&a-learn&b;
array nsemp(*) nsearn1-nsearn&z;
array nlemp(*) nlearn1-nlearn&z;
do i=1 to &z;
        nsemp(i)=semp(i);
        nlemp(i)=lemp(i);
	end;
run;

proc means data=emp; run;
proc means data=project.YT_&by_year._emp; run;


***On a benefit during the month - any amount of money and any duration;
data project.YT_&by_year._ben(drop=i ben_da_&a-ben_da_&b);
merge &population.(in=a keep=snz_uid ) project.YT_&by_year._mth_ben(keep=snz_uid ben_da_&a-ben_da_&b); 
by snz_uid;
if a; 
array os[*] ben_da_&a-ben_da_&b; 
array nos[*] ben1-ben&z;
do i=1 to &z;
        nos(i)=os(i);
        if nos(i)>=1 then nos(i)=1;
        else nos(i)=0;	
	end;
run;

proc means data=project.YT_&by_year._ben; run;

**School enrolled;
**eliminate gaps of one month;

data project.YT_&by_year._school( drop=i  sch_enr_id_&a-sch_enr_id_&b);
merge &population. (in=a keep=snz_uid ) project.YT_&by_year._mth_sch_enrol(keep=snz_uid sch_enr_id_&a-sch_enr_id_&b); 
by snz_uid;
if a; 
/*windowstart_leed=refmth;*/
array os[*] sch_enr_id_&a-sch_enr_id_&b; 
array nos[*] sch1-sch&z;
do i=1 to &z;
        nos(i)=os(i);
        if nos(i)>=1 then nos(i)=1;
        else nos(i)=0;	
	end;
do i=2 to &z-1;
  if nos(i)=0 and nos(i-1)=1 and nos(i+1)=1 then nos(i)=1;
  end;
run;


**Tertiary enrolled - any amount of time at this stage;
**Formal training includes YT, YO etc so targeted training programmes are included here;

data project.YT_&by_year._tertiary( drop=i ter_enr_id_&a-ter_enr_id_&b);
merge &population.(in=a keep=snz_uid ) project.YT_&by_year._mth_ter_enrol(keep=snz_uid ter_enr_id_&a-ter_enr_id_&b); 
by snz_uid;
if a; 
array os[*] ter_enr_id_&a-ter_enr_id_&b; 
array nos[*] ter1-ter&z;
do i=1 to &z;
        nos(i)=os(i);
        if nos(i)>=1 then nos(i)=1;
        else nos(i)=0;	
	end;
run;

proc means data=project.YT_&by_year._tertiary;
run;

%mend;


%transform_month_pop(project.population_2015_0_24,2015,185,206,22);
%transform_month_pop(project.population_2014_0_24,2014,173,194,22);
%transform_month_pop(project.population_2013_0_24,2013,161,182,22);


%transform_month_pop(project.population_2012_0_24,2012,149,170,22);
**********************************************************************************************************************;
**PART D - ASSIGN A SINGLE MAIN ACTIVITY IN EACH CALENDAR MONTH

***********************************************************************************************************************;

%macro run_mainact(population,by_year,z); 

data mainact( keep=snz_uid dob reg tla  au age_desc x_gender_desc
mainact1-mainact&z ben: searn: learn:);
merge 
&population.(in=a where=(age>=15)) 
project.YT_&by_year._tertiary 
project.YT_&by_year._school 
project.YT_&by_year._ben 
project.YT_&by_year._emp
project.YT_&by_year._custody 
project.YT_&by_year._os /*flows2.deaths*/ 
project.YT_&by_year._it ;
by snz_uid;
if a /*and died1~=1 and os1~=1*/; 
all=1; 
if female=0 then male=1; else male=0;
*array death [*] died1-died&z  ; 
array os[*] os1-os&z;
array custody[*] cust1-cust&z;
array school(*) sch1-sch&z;
array tert(*) ter1-ter&z; 
array it(*) it1-it&z;
array semp[*] searn1-searn&z;
array lemp[*] learn1-learn&z;
array ben[*] ben1-ben&z;

length mainact1-mainact&z $15;
array  main(*) $ mainact1-mainact&z;
do i=1 to &z;
*if death(i)=1 then main(i)='KDead';
/*else*/ if os(i)=1 then main(i)='O';
else if custody(i)=1 then main(i)='C';
else if school(i)=1 then main(i)='S';
else if tert(i)=1 then main(i)='T';
else if semp(i)=1 and it(i)=1 then main(i)='E1';
else if semp(i)=1 and it(i)=0 then main(i)='E2';
else if lemp(i)=1 then main(i)='E3';
else main(i)='N';
end;
run;


proc freq data=mainact;
tables mainact1-mainact&z /list missing;
run;

**Identify months that were part of long-term or short-term NEET spells;
**During the 22 month period from Aug 2014 to May 2016;

%let y=15;  **The number of NEET spells we are creating variables for - the true number of spells per person is probably lower than this; 

data neet_1;
set mainact(keep=snz_uid mainact1-mainact&z );
array hist(&z)   mainact1-mainact&z;
array spell(&z) spells1-spells&z;
array episodes(3,&y) startsp1-startsp&y endsp1-endsp&y lengthsp1-lengthsp&y;
*Create a vector that numbers off successive NEET spells;
counter=0;
do i=1 to &z;
If (i=1 and hist(i)='N') or (i>1 and hist(i)='N' and hist(i-1)~='N') then do;
   counter=counter+1;
   spell(i)=counter;
   end;
Else if i>1 and hist(i)='N' and hist(i-1)='N' then do;
   spell(i)=counter;
   end;
Else if (i=1 and hist(i)~='N') or hist(i)~='N' then do;
   spell(i)=.;
   end;
End;

***Derive the start and  end months and durations of each spell;
do k=1 to &y;
  do i=1 to &z ;
   If (k=1 and i=1 and spell(i)=1)  or (spell(i)=k and spell(i-1)=.) then episodes(1,k)=i;
   If (k=1 and i=1 and spell(i)=1 and spell(i+1)=.)
       or (1<i<&z and spell(i)=k and spell(i+1)=.) then episodes(2,k)=i;
   If episodes(1,k)>0 and episodes(2,k)=. and spell(&z)=k then episodes(2,k)=&z;
   If episodes(1,k)>0 and episodes(2,k)>0 then episodes(3,k)=episodes(2,k)-episodes(1,k)+1;
   end;
end;
**For each NEET spell, identify the  number of months that fall within 2015;
array start(&y) startsp1-startsp&y ;
array end(&y) endsp1-endsp&y;
array durn2(&y) mths1-mths&y;  **months falling within 2015;
array spelldur(&y) lengthsp1-lengthsp&y;  **total duration of the spell within the whole 22 month window;

do i=1 to &y;
if end(i)>=6 and start(i)<=17 then do;
   durn2(i)=min(end(i), 17) - max(start(i), 6) +1; 
   end;
end;
**Then count up the LT and the ST NEET months that fall within 2015, using two different long-term/short-term thresholds;
cnt_lt6_neet=0;
cnt_st6_neet=0;
cnt_lt3_neet=0;
cnt_st3_neet=0;
do i=1 to &y;
   if durn2(i)>=1 and spelldur(i)>=6 then cnt_lt6_neet= cnt_lt6_neet + durn2(i);
   else if durn2(i)>=1 and 1<=spelldur(i)<6 then cnt_st6_neet = cnt_st6_neet + durn2(i);
end;
do i=1 to &y;
   if durn2(i)>=1 and spelldur(i)>=3 then cnt_lt3_neet= cnt_lt3_neet + durn2(i);
   else if durn2(i)>=1 and 1<=spelldur(i)<3 then cnt_st3_neet = cnt_st3_neet + durn2(i);
end;
run;


proc freq data=neet_1;
tables startsp1-startsp10  endsp1-endsp10  mths1-mths10   ; 
run;

proc freq data=neet_1;
tables cnt_lt6_neet
cnt_st6_neet
cnt_lt3_neet
cnt_st3_neet;
run;

proc print data=neet_1(obs=10);
where cnt_lt6_neet>0;
var snz_uid mainact1-mainact&z spells1-spells&z cnt_lt6_neet
cnt_st6_neet
cnt_lt3_neet
cnt_st3_neet;
run;


**Merge on the NEET variables and count time in other main activity states over the year; 


data project.YT_&by_year._mainact_cross_section(keep=snz_uid dob 
reg tla  au age_desc x_gender_desc
      mainact1-mainact&z cnt: pp: denom: alt: );
merge mainact(in=a) 
     neet_1(keep=snz_uid cnt_lt6_neet
         cnt_st6_neet
         cnt_lt3_neet
         cnt_st3_neet);
by snz_uid;
if a;
array  main(*) $ mainact1-mainact&z;
array ben[*] ben1-ben&z;
array semp[*] searn1-searn&z;
array lemp[*] learn1-learn&z;
**Count the months of each other main activity during the reference year;	
	cnt_ma_sch=0;
	cnt_ma_TE=0;
	cnt_ma_sempIT=0;
	cnt_ma_semp=0;
	cnt_ma_lemp=0;
	cnt_ma_neet=0;
	cnt_ma_cust=0;
	cnt_ma_os=0;
	cnt_ben=0;
    cnt_ws_empl=0;

do i=6 to 17;
	if main(i)='S' then cnt_ma_sch+1;
	if main(i)='T' then cnt_ma_TE+1;
	if main(i)='E1' then cnt_ma_sempIT+1;
	if main(i)='E2' then cnt_ma_semp+1;
	if main(i)='E3' then cnt_ma_lemp+1;
	if main(i)='N' then cnt_ma_neet+1;
	if main(i)='C' then cnt_ma_cust+1;
	if main(i)='O' then cnt_ma_os+1;

if ben(i)=1 and main(i) ne 'O' then cnt_ben+1;
if (semp(i)=1 or lemp(i)=1) and main(i) ne 'O'  then cnt_ws_empl+1;
end;
**Create 2 variables for checking;
alt_cnt_neet_A=sum(of cnt_lt6_neet, cnt_st6_neet); 
alt_cnt_neet_B=sum(of cnt_lt3_neet, cnt_st3_neet); 

denom=sum(cnt_ma_sch,cnt_ma_TE,cnt_ma_sempIT,cnt_ma_semp,cnt_ma_lemp,cnt_ma_neet,cnt_ma_cust,cnt_ma_os);
denom_adj=sum(cnt_ma_sch,cnt_ma_TE,cnt_ma_sempIT,cnt_ma_semp,cnt_ma_lemp,cnt_ma_neet,cnt_ma_cust);

pp_sch=cnt_ma_sch;
pp_ter=cnt_ma_TE;
pp_sempIT=cnt_ma_sempIT;
pp_semp=cnt_ma_semp;
pp_lemp=cnt_ma_lemp;
pp_cust=cnt_ma_cust;

pp_lt6_neet=cnt_lt6_neet;
pp_st6_neet=cnt_st6_neet;
pp_lt3_neet=cnt_lt3_neet;
pp_st3_neet=cnt_st3_neet;

pp1_ben=cnt_ben;
pp1_ws_empl=cnt_ws_empl;
run;

proc freq data= project.YT_&by_year._mainact_cross_section;
tables cnt_ma_neet*alt_cnt_neet_A cnt_ma_neet*alt_cnt_neet_b
   /norow nocol nopercent missing;
run;

proc freq data=project.YT_&by_year._mainact_cross_section;
tables pp1_ben pp_: /list missing;
run;

%mend;

%run_mainact(project.population_2015_0_24,2015,22);
%run_mainact(project.population_2014_0_24,2014,22);
%run_mainact(project.population_2013_0_24,2013,22);

%run_mainact(project.population_2012_0_24,2012,22);

*************************************************************************************************************************************
*************************************************************************************************************************************
Tabulation: national tables for OUTCOMES TOOL
*************************************************************************************************************************************
*************************************************************************************************************************************;


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
		if &vartornd. < 6 then &vartornd.=0;
	run;
	%rr3(&indata._rr3,&indata._rr3,&vartornd.);
%end;
%mend suppress_rr3;

%macro NAT_tables(by_year);

	proc sort data=project.YT_&by_year._mainact_cross_section; by snz_uid;
	proc sort data=project.population_&by_year._0_24 (keep=snz_uid DOB reg tla au age x_gender_desc age_desc ); by snz_uid;
	proc sort data=project.RISK_FACTORS_&by_year._15_24_BY_AGE15; by snz_uid;

	data project.YT_&by_year._TAB_YT_Outcomes_tool; 
	merge project.YT_&by_year._mainact_cross_section (in=a) 
	project.RISK_FACTORS_&by_year._15_24_BY_AGE15
	project.population_&by_year._0_24;
	if a; 
	by snz_uid;
	year=&by_year.;
	count=1;
	if risk_factors_by15>=3 then risk_factors_3plus_by15=1; else risk_factors_3plus_by15=0;
	if risk_factors_by15=4 then risk_factors_4_by15=1; else risk_factors_4_by15=0;
	run;
%mend;


%NAT_tables(2015);
%NAT_tables(2014);
%NAT_tables(2013);

%NAT_tables(2012);

********************************************************************************************************************************************
********************************************************************************************************************************************

TABULATION PART

********************************************************************************************************************************************
********************************************************************************************************************************************;

%macro tabulateby(class1,class2,class3,class4,outfile);

* combine three years and tabulate at once;
data YT_2013; merge project.YT_2013_TAB_YT_Outcomes_tool(in=a drop=pp_lt3_neet pp_st3_neet) inputlib._ind_ethnicity_&date.; by snz_uid; if a;
data YT_2014; merge project.YT_2014_TAB_YT_Outcomes_tool(in=a drop=pp_lt3_neet pp_st3_neet) inputlib._ind_ethnicity_&date.; by snz_uid; if a;
data YT_2015; merge project.YT_2015_TAB_YT_Outcomes_tool(in=a drop=pp_lt3_neet pp_st3_neet) inputlib._ind_ethnicity_&date.; by snz_uid; if a; 
if reg not in ('Area Outside Region'); run;

data TAB_combined; set YT_2013 YT_2014 YT_2015 ;run;

proc summary data=TAB_combined nway;
class x_gender_desc &class1 &class2 &class3 &class4;
var count denom denom_adj pp_: pp1:;
output out=temp_all(drop=_type_) sum=;
run;

proc summary data=TAB_combined nway;
	where moh_pop_ethnic_grp1_snz_ind=1;
class x_gender_desc &class1 &class2 &class3 &class4;
var count denom denom_adj pp_: pp1:;
output out=temp_E(drop=_type_) sum=;
run;

proc summary data=TAB_combined nway;
	where moh_pop_ethnic_grp2_snz_ind=1;
class x_gender_desc &class1 &class2 &class3 &class4;
var count denom denom_adj pp_: pp1:;
output out=temp_M(drop=_type_) sum=;
run;

proc summary data=TAB_combined nway;
	where moh_pop_ethnic_grp3_snz_ind=1;
class x_gender_desc &class1 &class2 &class3 &class4;
var count denom denom_adj pp_: pp1:;
output out=temp_PI(drop=_type_) sum=;
run;

proc summary data=TAB_combined nway;
	where moh_pop_ethnic_grp4_snz_ind=1;
class x_gender_desc &class1 &class2 &class3 &class4;
var count denom denom_adj pp_: pp1:;
output out=temp_A(drop=_type_) sum=;
run;

	proc summary data=TAB_combined  nway;
	where (moh_pop_ethnic_grp5_snz_ind or moh_pop_ethnic_grp6_snz_ind=1); 
	class x_gender_desc &class1 &class2 &class3 &class4;
	var count denom denom_adj pp_: pp1:;
	output out=temp_O(drop=_type_) sum=;
	run;

	data YT_nat; retain eth; length eth $20.;set 
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

 

%let indata=YT_nat;

proc contents data=&indata. out=vars(keep=name type) noprint;
run;

data vars;
	set vars;
	if  type=1 /* need to also exclude any numeric variables here that you don't want to be rounded */;
	if name not in ("&class1.","&class2.","&class3.","&class4.");
call symput('numvars',_n_);
run;
%suppress_rr3; * supressing counts less than 6;


data Output1.&outfile._rr3; 
set YT_Nat_rr3;
pp2_sch=pp_sch/denom_adj;
pp2_ter=pp_ter/denom_adj;
pp2_sempIT=pp_sempIT/denom_adj;
pp2_semp=pp_semp/denom_adj;
pp2_lemp=pp_lemp/denom_adj;
pp2_cust=pp_cust/denom_adj;

pp2_lt6_neet=pp_lt6_neet/denom_adj;
pp2_st6_neet=pp_st6_neet/denom_adj;

pp3_ben=pp1_ben/denom_adj;
pp3_ws_empl=pp1_ws_empl/denom_adj;

keep eth count denom_adj denom x_gender_desc &class1 &class2 &class3 &class4 pp:;
run;

data output1.&outfile.; set YT_Nat;
pp2_sch=pp_sch/denom_adj;
pp2_ter=pp_ter/denom_adj;
pp2_sempIT=pp_sempIT/denom_adj;
pp2_semp=pp_semp/denom_adj;
pp2_lemp=pp_lemp/denom_adj;
pp2_cust=pp_cust/denom_adj;

pp2_lt6_neet=pp_lt6_neet/denom_adj;
pp2_st6_neet=pp_st6_neet/denom_adj;

pp3_ben=pp1_ben/denom_adj;
pp3_ws_empl=pp1_ws_empl/denom_adj;

keep eth count denom_adj denom x_gender_desc &class1 &class2 &class3 &class4 pp:;
run;

%mend;


* Allowing only three dimentional split for descriptive part of Outcomes tool;

%tabulateby(year,age,,,YT_age); * age groups No risk category;

%tabulateby(year,risk_factors_2plus_by15,age,,YT_risk2_age); * age groups by YES at risk category;
%tabulateby(year,risk_factors_2plus_by15,REG,age,YT_reg_risk2_age); * at risk, region, age split;

%tabulateby(year,risk_factors_3plus_by15,age,,YT_risk3_age); * age groups by YES at risk category;
%tabulateby(year,risk_factors_3plus_by15,REG,age,YT_reg_risk3_age); * at risk, region, age split;



%macro export(dataset);
proc export data=output1.&dataset._rr3
outfile="&path.\tables\&dataset..csv" dbms=csv replace;run;
%mend;
%export(YT_age);
%export(YT_risk2_age);
%export(YT_reg_risk2_age);

%export(YT_risk3_age);
%export(YT_reg_risk3_age);


*************************************************************************************************************************************
*************************************************************************************************************************************
Tabulation: MAPPING PART of "OUTCOMES TOOL"
*************************************************************************************************************************************
*************************************************************************************************************************************;

* Table 1;
data TAB_combined; set 
project.YT_2013_TAB_YT_Outcomes_tool(drop=pp_lt3_neet pp_st3_neet)
project.YT_2014_TAB_YT_Outcomes_tool(drop=pp_lt3_neet pp_st3_neet)
project.YT_2015_TAB_YT_Outcomes_tool(drop=pp_lt3_neet pp_st3_neet);
run;

proc summary data=TAB_combined nway;
	class year risk_factors_2plus_by15 reg age_desc x_gender_desc;
	var count denom denom_adj  PP_: pp1_:; * calcualting sum of weights;
	output out=temp1 (drop=_:) sum=;
run;

proc summary data=TAB_combined nway;
	class year risk_factors_2plus_by15 reg age_desc;
	var count denom denom_adj PP_: pp1_:;
	output out=temp2 (drop=_:) sum=;
run;

data table1_final; set temp1 temp2;
rename count=all;
if x_gender_desc='' then 
x_gender_desc='All';
run;

proc sort data=table1_final;
	by year risk_factors_2plus_by15 reg age_desc x_gender_desc;
run;

***************************************************************************************************************************************;
* Table 2;
proc summary data=TAB_combined nway;
	class year risk_factors_2plus_by15 reg tla age_desc  x_gender_desc;
	var count denom denom_adj PP_: pp1_:;
	output out=temp1 (drop=_:) sum=;
run;

proc summary data=TAB_combined nway;
	class year risk_factors_2plus_by15 reg tla age_desc;
	var count denom denom_adj  PP_: pp1_:;
	output out=temp2 (drop=_:) sum=;
run;

data table2_final;
	set temp1 temp2;
	if x_gender_desc='' then
		x_gender_desc='All';
	rename count=all;


proc sort data=table2_final;
	by year risk_factors_2plus_by15 reg tla age_desc x_gender_desc;
run;

***************************************************************************************************************************************;
***************************************************************************************************************************************;
* Table 3;

proc summary data=TAB_combined nway;
	class year risk_factors_2plus_by15 reg tla  au age_desc x_gender_desc;
	var count denom denom_adj PP_: pp1_:;
	output out=temp1 (drop=_:) sum=;
run;

proc summary data=TAB_combined  nway;
	class year risk_factors_2plus_by15 reg tla  au age_desc ;
	var count denom denom_adj PP_: pp1_:;
	output out=temp2 (drop=_:) sum=;
run;

data table3_final;
	set temp1 temp2;
	if x_gender_desc='' then
		x_gender_desc='All';
	rename count=all;
run;
proc sort data=table3_final;
	by year risk_factors_2plus_by15 reg tla au age_desc x_gender_desc;
run;

data Output2.YT_Table1_final; set table1_final;
data Output2.YT_Table2_final; set table2_final;
data Output2.YT_Table3_final; set table3_final;run;

*************************************************************************************************************************************************
Randomly rounding using SAS macro

*************************************************************************************************************************************************
*************************************************************************************************************************************************;

%let indata=Table1_final;

proc contents data=&indata. out=vars(keep=name type) noprint;
run;

data vars;
	set vars;
	if  type=1 /* need to also exclude any numeric variables here that you don't want to be rounded */;
	if name not in ("risk_factors_2plus_by15");
call symput('numvars',_n_);
run;


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
		if &vartornd. < 6 then &vartornd.=0;
	run;
	%rr3(&indata._rr3,&indata._rr3,&vartornd.);
%end;
%mend suppress_rr3;

%suppress_rr3;

%let indata=Table2_final;
%suppress_rr3;

%let indata=Table3_final;
%suppress_rr3;

*Saving tabulated outputs as final datasets ( back up);

data output2.YT_Table1_final_rr3; set Table1_final_rr3;
data output2.YT_Table2_final_rr3; set Table2_final_rr3;
data output2.YT_Table3_final_rr3_; set Table3_final_rr3;
run;

proc export data=output2.YT_Table1_final_rr3 
outfile="&path.\tables\YT_REGION_final_2015.csv" dbms=csv;run;

proc export data=output2.YT_Table2_final_rr3 
outfile="&path.\tables\YT_TA_final_2015.csv" dbms=csv;run;

proc export data=output2.YT_Table3_final_rr3_ 
outfile="&path.\tables\YT_AU_final_2015.csv" dbms=csv;run;


***********************************************************************************************************************************************
***********************************************************************************************************************************************
Adding birth information for Sylvia

***********************************************************************************************************************************************
***********************************************************************************************************************************************;

data Parent_by(keep=snz_uid parent_by:);
set inputlib._IND_PARENT_20161021;
%onezero_array(father,&first_anal_yr.,&last_anal_yr.);
%onezero_array(mother,&first_anal_yr.,&last_anal_yr.);

if max(of father_&first_anal_yr.-father_2013)>0 or max(of mother_&first_anal_yr.-mother_2013)>0 then parent_by2013=1; else parent_by2013=0;
if max(of father_&first_anal_yr.-father_2014)>0 or max(of mother_&first_anal_yr.-mother_2014)>0 then parent_by2014=1; else parent_by2014=0;
if max(of father_&first_anal_yr.-father_2015)>0 or max(of mother_&first_anal_yr.-mother_2015)>0 then parent_by2015=1; else parent_by2015=0;
proc freq data=Parent_by;
tables parent: ;
run;

proc sort data=parent_by; by snz_uid;
proc sort data=project.YT_2013_TAB_YT_OUTCOMES_TOOL; by snz_uid;
proc sort data=project.YT_2013_TAB_YT_OUTCOMES_TOOL; by snz_uid;
proc sort data=project.YT_2013_TAB_YT_OUTCOMES_TOOL; by snz_uid;

data project.YT_2013_TAB_YT_OUTCOMES_TOOL1; merge project.YT_2013_TAB_YT_OUTCOMES_TOOL(in=a) parent_by(keep=snz_uid parent_by2013); by snz_uid; if a; rename parent_by2013=parent;
data project.YT_2014_TAB_YT_OUTCOMES_TOOL1; merge project.YT_2014_TAB_YT_OUTCOMES_TOOL(in=a) parent_by(keep=snz_uid parent_by2014); by snz_uid; if a;rename parent_by2014=parent;
data project.YT_2015_TAB_YT_OUTCOMES_TOOL1; merge project.YT_2015_TAB_YT_OUTCOMES_TOOL(in=a) parent_by(keep=snz_uid parent_by2015); by snz_uid; if a;rename parent_by2015=parent;
run;

%contents(project.YT_2013_TAB_YT_OUTCOMES_TOOL1);

* Table 1;
data TAB_combined; set 
project.YT_2013_TAB_YT_Outcomes_tool1(drop=pp_lt3_neet pp_st3_neet)
project.YT_2014_TAB_YT_Outcomes_tool1(drop=pp_lt3_neet pp_st3_neet)
project.YT_2015_TAB_YT_Outcomes_tool1(drop=pp_lt3_neet pp_st3_neet);
run;

proc summary data=TAB_combined nway;
where pp_lt6_neet>0;
	class year age parent ;
	var count denom denom_adj  PP_: pp1_:; * calcualting sum of weights;
	output out=temp1 (drop=_:) sum=;
run;

proc summary data=TAB_combined nway;
where pp_st6_neet>0;
	class year age parent ;
	var count denom denom_adj  PP_: pp1_:; * calcualting sum of weights;
	output out=temp2 (drop=_:) sum=;
run;

data table1_final; set temp1 temp2;
rename count=all;
if x_gender_desc='' then 
x_gender_desc='All';
run;

proc sort data=table1_final;
	by year risk_factors_2plus_by15 reg age_desc x_gender_desc parent;
run;


***********************************************************************************************************************************************
***********************************************************************************************************************************************
Tabulate Outcome for sylvia
***********************************************************************************************************************************************
***********************************************************************************************************************************************;
