****************************************************************************************************************************
This macro will create 4 relationship tables for given population
****************************************************************************************************************************;


%macro Create_relationship_tables_pop;

* PART 1: DIA rel;
proc sql;
create table PART1 as
		select
			a.snz_uid, 
			MDY(a.dia_bir_birth_month_nbr,15,dia_bir_birth_year_nbr) as DOB format date9.,
			MDY(a.dia_bir_birth_month_nbr,15,dia_bir_birth_year_nbr) as event_date format date9.,
			a.parent1_snz_uid,
			a.parent2_snz_uid,
			'dia' as source
	from  dia.births a 
	where  (a.parent1_snz_uid>0 or a.parent2_snz_uid>0)
order by a.parent1_snz_dia_uid;
quit;


* PART 2: MSD rel;
proc sql;
	create table TEMP as
		select distinct 
				'msd' as source
				,a.snz_uid
				,a.child_snz_uid
				,a.msd_chld_child_birth_month_nbr as child_birth_month
				,a.msd_chld_child_birth_year_nbr as child_birth_year
				,a.msd_chld_spell_nbr
				,MDY(a.msd_chld_child_birth_month_nbr,15,a.msd_chld_child_birth_year_nbr) as DOB format date9.
				,b.partner_snz_uid
				,input(compress(a.msd_chld_child_from_date,"-"),yymmdd10.) as child_from format date9.
				,input(compress(a.msd_chld_child_to_date,"-"),yymmdd10.) as child_to format date9.
				,input(compress(b.msd_ptnr_ptnr_from_date,"-"),yymmdd10.) as ptnr_from format date9.
				,input(compress(b.msd_ptnr_ptnr_to_date,"-"),yymmdd10.) as ptnr_to format date9.
				,b.msd_ptnr_spell_nbr
			from msd.msd_child a LEFT JOIN msd.msd_partner b
				on a.snz_uid = b.snz_uid and a.msd_chld_spell_nbr=b.msd_ptnr_spell_nbr
				and b.msd_ptnr_ptnr_to_date >= a.msd_chld_child_from_date
				and b.msd_ptnr_ptnr_from_date <= a.msd_chld_child_to_date
		
order by a.snz_uid, a.child_snz_uid, child_from, ptnr_from			;
quit;


proc sql;
	create table Part2 as
		select distinct child_snz_uid as snz_uid, 
				DOB,
				snz_uid as parent1_snz_uid,
				partner_snz_uid as parent2_snz_uid,
				source,
				
				child_from as event_date

			from TEMP
				where child_snz_uid ne partner_snz_uid 
				and child_snz_uid ne snz_uid 
				and partner_snz_uid ne snz_uid and ( snz_uid>0 or partner_snz_uid>0)
order by snz_uid;
quit;

* PART 3: DOL rel;
proc sql;
	create table TEMP as
		select snz_uid, snz_application_uid, 
			input(dol_dec_decision_date,yymmdd10.) as Decision_Date format yymmdd10.,
			mdy(dol_dec_birth_month_nbr,15,dol_dec_birth_year_nbr) as DOB format yymmdd10.,
			yrdif(mdy(dol_dec_birth_month_nbr,15,dol_dec_birth_year_nbr),input(dol_dec_decision_date,yymmdd10.),'AGE') as Age,
			case when yrdif(mdy(dol_dec_birth_month_nbr,15,dol_dec_birth_year_nbr),input(dol_dec_decision_date,yymmdd10.),'AGE') >= 18 then 1
			else 0 end as Adult,
			case when yrdif(mdy(dol_dec_birth_month_nbr,15,dol_dec_birth_year_nbr),input(dol_dec_decision_date,yymmdd10.),'AGE') < 18 then 1
			else 0 end as Child
				from dol.decisions
					where dol_dec_nbr_applicants_nbr > 1 and dol_dec_decision_type_code = 'A' and dol_dec_reporting_cat_code = 'R'
						order by snz_application_uid;
quit;

proc sql;
	create table TEMP_sum as
		select distinct
			snz_application_uid, decision_date,
			sum(Adult) as Adults, 
			sum(Child) as Children, 
			max(Age*Child) as Oldest,
			max(age*adult) as Oldest_p
			from TEMP
			group by snz_application_uid, decision_date
			order by snz_application_uid;
quit;

data TEMP_sum;
set TEMP_sum; 
if Adults > 2 or Children=0 then delete;
if Oldest_p-oldest<14 then delete;
run;

proc sql;
	create table TEMP_1 as
		select distinct 
			a.*,
			b.adults,
			b.children,
			b.oldest,
			b.oldest_p
			from TEMP a right join TEMP_sum b
on a.snz_application_uid = b.snz_application_uid and a.decision_date = b.decision_date
order by a.snz_application_uid, a.Decision_Date;
quit;

proc transpose data=TEMP_1(rename=snz_uid=parent) out=TEMP_Parents(rename=(col1=Parent1_snz_uid col2=Parent2_snz_uid));
where Adult=1;
by snz_application_uid Decision_Date;
var parent;
run;

data PART3; 
merge TEMP_1(where=(child=1) in=a) TEMP_Parents(in=b); 
by snz_application_uid Decision_Date; 
if a and b;
event_date=decision_date;
format event_date date9.;
source='dol';
keep snz_uid DOB source event_date parent1_snz_uid Parent2_snz_uid;
run;

* Part5: Census relat;
proc sql;
create table TEMP_Cen_fam as select 
snz_uid,
snz_cen_uid,
snz_cen_fam_uid,
cen_ind_sex_code,
MDY(cen_ind_birth_month_nbr,15,cen_ind_birth_year_nbr) as DOB format date9.,
MDY(cen_ind_birth_month_nbr,15,cen_ind_birth_year_nbr) as event_date format date9.,
cen_ind_fam_grp_code,
cen_ind_fam_role_code
from cen.census_individual
where snz_uid>0 and snz_cen_fam_uid>0 and cen_ind_fam_grp_code not in ('00','50') and cen_ind_fam_role_code not in ('00','50');

data TEMP_cen_fam; set TEMP_cen_fam; 
child=0; CG_parent=0; Grand_parent=0; other_cg=0;
if cen_ind_fam_role_code in ('02','12') then child=1;
if cen_ind_fam_role_code='01' then CG_parent=1;
if cen_ind_fam_role_code='03' then Grand_parent=1;
if cen_ind_fam_role_code='11' then other_cg=1;
run;
proc sort data=TEMP_cen_fam; by snz_cen_fam_uid;run;

proc summary data=TEMP_cen_fam nway;
class snz_cen_fam_uid;
var child CG_parent Grand_parent other_cg;
output out=TEMP_fam_sum(drop=_:) sum=;
run;

proc transpose data=TEMP_cen_fam(rename=snz_uid=parent) out=TEMP_Parents_cen(rename=(col1=Parent1_snz_uid col2=Parent2_snz_uid));
where child=0;
by snz_cen_fam_uid;
var parent;
run;

proc sql;
create table PART5
as select 
a.snz_uid,
a.DOB,
a.event_date,
'cen' as source,
b.parent1_snz_uid,
b.Parent2_snz_uid
from TEMP_cen_fam a inner join 
TEMP_Parents_cen b 
on a.snz_cen_fam_uid=b.snz_cen_fam_uid
where a.child=1 ;

proc datasets lib=work;
delete 
TEMP:;
run;

* INTEGRATION;

DATA TEMP; set part1 part2 part3 part5; 
source1='all';
keep snz_uid
		DOB
		parent1_snz_uid
		parent2_snz_uid
		source source1
		Event_Date; 	
if DOB ne .;run;

proc sql;
create table TEMP_parentchildmap_5
as select 
a.*,
b.snz_sex_code as parent1_snz_sex_code,
b.snz_person_ind as parent1_spine,
c.snz_sex_code as parent2_snz_sex_code,
c.snz_person_ind as parent2_spine
from TEMP a left join data.personal_detail b
on a.parent1_snz_uid=b.snz_uid
left join data.personal_detail c
on a.parent2_snz_uid=c.snz_uid
;

data TEMP_parentchildmap_5 
;	set TEMP_parentchildmap_5;
rename parent1_snz_uid=parent1;
rename parent2_snz_uid=parent2;


run;

proc sort data=TEMP_parentchildmap_5 nodup out=TEMP_events_nodup;
	by snz_uid DOB event_date source parent1 parent2;
run;

data &projectlib..child_parent_events_&date; set TEMP_events_nodup; 
format event_end date9.;
event_end = ifn(lag(snz_uid) = snz_uid, lag(event_date)-1, .);
run;

data TEMP_parentchildmap_5;
	set TEMP_parentchildmap_5;
	if event_date = lag(event_date) and snz_uid = lag(snz_uid) then DELETE; /* DIA DOL MSD WFF priority order */
	if (snz_uid=lag(snz_uid) and parent1 = lag(parent1) and parent2 = lag(parent2)) then
		delete;
run;

proc sort data=TEMP_parentchildmap_5 nodup;
	by snz_uid descending event_date;
run;

data TEMP_parentchildmap_6;
	format event_end ddmmyy10.;
	set TEMP_parentchildmap_5;
	event_end = ifn(lag(snz_uid) = snz_uid, lag(event_date)-1, .);
run;

proc sort data= TEMP_parentchildmap_6;
	by snz_uid event_date;
run;

data TEMP_PC1;
	set TEMP_parentchildmap_6;
	parent = parent1;
	if parent = . then
		delete;

run;

data TEMP_PC2;
	set TEMP_parentchildmap_6;
	parent = parent2;
	if parent = . then
		delete;

run;

data TEMP_PC3; set TEMP_PC1 TEMP_PC2;run;

proc sort data=TEMP_PC3 noduprecs;
	by parent snz_uid event_date;
run;

proc sql;
create table &projectlib..ChildToParentMap_&date 
as select 
* from TEMP_parentchildmap_6
where snz_uid in (select snz_uid from &population);
run;

proc sql;
create table ParentToChildMap_&date
as select
*
from TEMP_PC3
where snz_uid in (select snz_uid from &population);

data &projectlib..ParentToChildMap_&date; set ParentToChildMap_&date;
if parent=parent1 then parent_sex=parent1_snz_sex_code; 
else if parent=parent2 then parent_sex=parent2_snz_sex_code;
run;


proc sql;
	create table TEMP_SiblingBase as
		select a.snz_uid as snz_uid,
			b.snz_uid as sibling, 
			a.parent as parent,
			a.event_date as start1, 
			a.event_end as end1, 
			b.event_date as start2, 
			b.event_end as end2, 
			a.source as Source, 
			a.source1 as Source1,
			b.source as SibSource 
		from TEMP_PC3 a 
		left join TEMP_PC3 b
			on a.parent = b.parent
		where a.snz_uid ne b.snz_uid;

	create table TEMP_SiblingExtended as
		select distinct snz_uid, sibling, 1 as CNT
		from TEMP_SiblingBase
		order by snz_uid;

	create table  TEMP_SiblingEvent as
		select distinct snz_uid, sibling, parent, 
				max(start1,start2) as startdate format = ddmmyy10., 
				min(end1,end2) as enddate format = ddmmyy10., 
				Source, source1, SibSource
		from TEMP_SiblingBase
		where (end2 = . or start1 <= end2) 
		and (end1 = . or start2 <= end1)
		order by snz_uid;

	create table TEMP_SiblingEvCnt as
		select distinct snz_uid, sibling, 1 as CNT
		from TEMP_SiblingEvent
		order by snz_uid;
quit;

proc sql;
create table &projectlib..ChildSiblingMapExtended_&date
as select *,
	"all" as sibsource1 from 
TEMP_SiblingExtended
where snz_uid in (select snz_uid from &population);


proc sql;
create table &projectlib..ChildSiblingMapvent_&date
as select * ,
	"all" as sibsource1
from 
TEMP_SiblingEvent
where snz_uid in (select snz_uid from &population);


proc datasets lib=work;
delete temp: Part: ;
run;

%mend;


