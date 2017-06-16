****************************************************************************
Purpose: This code produces an IDI resident population (the IDI-ERP)
 at 31 December of a given year.
                                                                     
Beginning with the IDI spine, individuals are retained if they have had 
 activity in education, health, IR tax, or ACC datasets in the previous 
 twelve months, or if they have a birth record in the previous five years.                              
                                                                     
Individuals are then removed if they have left the population by death 
 or outmigration prior to the reference date.      

Version:  This is based on Version 2 of the IDI-ERP, as used in the experimental    
 series released on 30 September 2016. A number of modifications have been made
 by the A&I team for A&I population analysis: 
	- The original code was as at 30 June.  This code uses a 31 December date.
	- Most activity measures are based on the calendar year but self-employment uses 
	  the following tax year (as 9 months of it lie within the calendar year of interest).
	  Care needs to be taken that sufficient elapsed time has occurred for a reasonably
	  complete set of self-employment returns however.
	- We also exclude temporary migrants from the ERP, as they are generally not
	  eligible for social services, may only be in NZ for a limited period, and are unlikely
	  to have a history recorded in the administrative data.
	- We add in the prison activity flag as per the Ministry of Justice code.
	- For this version of the ERP we are interested in those people who have spent the majority
	  of the calendar year in NZ, as we subsequently link to outcomes and activities over the period.
	  As such, we move from a year that is centred on December to a calendar year when
	  assessing the amount of time in and out of the country.
 
Original authors: Sheree Gibb and Emily Shrosbree (Statistics New Zealand)                        
Updated by Nathaniel Matheson-Dunning (September 2016)
Modified by Keith McLeod (A&I, The Treasury January 2017) 
****************************************************************************;

%let refresh = archive; ** Specify IDI refresh to use for extractions;
** Note that archive will use the latest refresh. The Insights tool used refresh 20161020;

%macro create_idi_erp(year);
%let prevyear = %eval(&year. - 1);
%let nextyear = %eval(&year. + 1);

libname central ODBC dsn=idi_clean_&refresh._srvprd schema=data;
libname moe ODBC dsn=idi_clean_&refresh._srvprd schema=moe_clean;
libname msd ODBC dsn=idi_clean_&refresh._srvprd schema=msd_clean;
libname ird ODBC dsn=idi_clean_&refresh._srvprd schema=ir_clean;
libname hlth ODBC dsn=idi_clean_&refresh._srvprd schema=moh_clean;
libname acc ODBC dsn=idi_clean_&refresh._srvprd schema=acc_clean;
libname dia ODBC dsn=idi_clean_&refresh._srvprd schema=dia_clean;
libname dol ODBC dsn=idi_clean_&refresh._srvprd schema=dol_clean;
libname sanddol ODBC dsn=idi_clean_&refresh._srvprd schema=sanddol;

%let path=\\wprdsas10\treasurydata\MAA2013-16 Citizen pathways through human services\Infographics;
libname project "&path.\Datasets";

** Set standard AnI macros and libnames;
%let version=archive;
%include "&path.\SAS Code\Stand_macro_new.sas";

* Create a list of all people in the spine;
data spinepop;
   set central.personal_detail (where = (snz_spine_ind = 1 and snz_person_ind = 1));
   keep snz_uid snz_spine_ind snz_sex_code snz_birth_year_nbr snz_birth_month_nbr snz_deceased_year_nbr snz_deceased_month_nbr;
run;
proc sort; by snz_uid;

**********************************************************************************************************
*** Produce a list of all individuals with activity in relevant datasets in last 12 months / 5 years   ***
**********************************************************************************************************;

*********************************************************************************
***   Identify individuals with activity in education datasets in last year   ***
*********************************************************************************;

** Tertiary enrolments;
proc sql;
   create table tertiary as 
   select distinct snz_uid, 1 as flag_ed
   from moe.course
   where (moe_crs_start_date <= "&year.-12-31" and moe_crs_end_date >= "&year.-01-01")
   order by snz_uid;
quit;

** Industry training;
proc sql;
   create table industry_tr as
   select distinct snz_uid, 1 as flag_ed
   from moe.tec_it_learner
   where (moe_itl_start_date <= "&year.-12-31" and moe_itl_end_date >= "&year.-01-01")
   order by snz_uid;
quit;

** School enrolments;
proc sql;
   create table school as 
   select distinct snz_uid, 1 as flag_ed
   from moe.student_enrol 
   where ((moe_esi_start_date <= "&year.-12-31") and (moe_esi_end_date >= "&year.-01-01" or moe_esi_end_date is NULL))
   order by snz_uid;
quit;

***************************************************************************
***   Identify individuals with activity in tax datasets in last year   ***
***************************************************************************;

** EMS (tax at source) dataset;
proc sql;
   create table ems as
   select distinct snz_uid, 1 as flag_ir, 1 as flag_ems
   from ird.ird_ems
   where ir_ems_return_period_date >= "&year.-01-01" and ir_ems_return_period_date <= "&year.-12-31"
   order by snz_uid;
quit;

** Self-employment income - KM - use the next tax year as that covers nine months of the period to 31 December (NB: enough elapsed time needs to be available to use this);
proc sql;
   create table selfemp as 
   select distinct snz_uid as snz_uid, 1 as flag_ir, 1 as flag_se
   from central.income_tax_yr_summary
   where (inc_tax_yr_sum_year_nbr = &nextyear.)
      and (inc_tax_yr_sum_S00_tot_amt <> 0 or inc_tax_yr_sum_S01_tot_amt <> 0 or inc_tax_yr_sum_S02_tot_amt <> 0 or inc_tax_yr_sum_S03_tot_amt <> 0
        or inc_tax_yr_sum_C00_tot_amt <> 0 or inc_tax_yr_sum_C01_tot_amt <> 0 or inc_tax_yr_sum_C02_tot_amt <> 0
        or inc_tax_yr_sum_P01_tot_amt <> 0 or inc_tax_yr_sum_P02_tot_amt <> 0) 
   order by snz_uid;
quit;

**********************************************************************************
***   Identify individuals with activity in health datasets in the last year   ***
**********************************************************************************;

** GMS claims;
proc sql;
   create table gms_activity as
   select distinct snz_uid
   from hlth.gms_claims
   where moh_gms_visit_date >= "&year.-01-01" and moh_gms_visit_date <= "&year.-12-31"
   order by snz_uid;
quit;

** Laboratory tests;
proc sql;
   create table lab_claims as
   select distinct snz_uid
   from hlth.lab_claims
   where moh_lab_visit_date >= "&year.-01-01" and moh_lab_visit_date <= "&year.-12-31"
   order by snz_uid;
quit;

** Non-admissions events;
proc sql;
   create table nnpac as
   select distinct snz_uid
   from hlth.nnpac
   where moh_nnp_service_date >= "&year.-01-01" and moh_nnp_service_date <= "&year.-12-31" and moh_nnp_attendence_code = 'ATT'
   order by snz_uid;
quit;

** Prescriptions dispensed;
proc sql;
   create table pharma as
   select distinct snz_uid
   from hlth.pharmaceutical
   where moh_pha_dispensed_date >= "&year.-01-01" and moh_pha_dispensed_date <= "&year.-12-31"
   order by snz_uid;
quit;

** Consultation with PHO-registered GP;
proc sql;
   create table pho as
   select distinct snz_uid
   from hlth.pho_enrolment
   where moh_pho_last_consul_date >= "&year.-01-01" and moh_pho_last_consul_date <= "&year.-12-31"
   order by snz_uid;
quit;

** Discharged from publically funded hospitals;
proc sql;
   create table hospital as
   select distinct snz_uid
   from hlth.pub_fund_hosp_discharges_event
   where moh_evt_even_date >= "&year.-01-01" and moh_evt_evst_date <= "&year.-12-31"
   order by snz_uid;
quit;

** Combine all health activity datasets to get list of all people with health activity in last year;
data health_activity;
   merge gms_activity lab_claims nnpac pharma pho hospital;
   by snz_uid;
   flag_health = 1;
run;

**********************************************************************
***   Identify individuals with activity in ACC in the last year   ***
**********************************************************************;

** ACC claims (date of file within the last year, not date of accident);
proc sql;
   create table acc as
   select distinct snz_uid, 1 as flag_acc
   from acc.claims
   where acc_cla_lodgement_date >= "&year.-01-01" and acc_cla_lodgement_date <= "&year.-12-31"
   order by snz_uid;
quit;

******************************************
***   Get births in the last 5 years   ***
******************************************;
proc sql;
   create table births as
   select snz_uid, 1 as flag_birth
   from dia.births
   where (dia_bir_birth_year_nbr > %eval(&year.- 5) and dia_bir_birth_year_nbr <= &year.) 
      and dia_bir_still_birth_code IS NULL
   order by snz_uid;
quit;

***************************************************
***   Get visa approvals for children under 5   ***
***************************************************;
proc sql;
   create table visas_under5 as 
   select distinct snz_uid, 1 as flag_visa_under5
   from dol.decisions
   where (dol_dec_birth_year_nbr > %eval(&year.- 5) and dol_dec_birth_year_nbr <= &year.)
      and dol_dec_decision_date <= "&year.-12-31"
      and dol_dec_decision_type_code = 'A' 
      and dol_dec_application_type_code not in ('20', '21')
   order by snz_uid;
quit;

/*****************************************************************************************
	Activity - prison
******************************************************************************************/

*Check if a person has spent any time in prison or remand in the year;
PROC SQL;
	CREATE TABLE prison_spell AS
	SELECT DISTINCT 
		snz_uid
		,INPUT(cor_mmp_period_start_date,yymmdd10.) AS startdate FORMAT=yymmdd10.
		,INPUT(cor_mmp_period_end_date, yymmdd10.) AS enddate FORMAT=yymmdd10.
	FROM cor.ov_major_mgmt_periods
	WHERE cor_mmp_mmc_code IN ('PRISON', 'REMAND' , 'HD_REL', 'HD_SENT')
	ORDER BY snz_uid, startdate;
QUIT;

DATA prison;
	SET prison_spell;
	BY snz_uid;
	IF first.snz_uid THEN flag_prison = 0;

	*flag years where time was spent in prison;
	if YEAR(startdate)<=&year. and YEAR(enddate)>=&year. then flag_prison = 1;

	IF last.snz_uid and flag_prison = 1 THEN OUTPUT;
RUN;


******************************************************************************
***   Combine all activity files with spine to create a total population   ***
******************************************************************************;

** Combine all activity sources **;
data total_activity_pop;
   merge selfemp ems industry_tr tertiary school health_activity acc births visas_under5 prison;
   by snz_uid;
   if flag_ed = . then flag_ed = 0;
   if flag_ir = . then flag_ir = 0;
   if flag_health = . then flag_health = 0;
   if flag_acc = . then flag_acc = 0;
   if flag_se = . then flag_se = 0;
   if flag_ems = . then flag_ems = 0;
   if flag_prison=. then flag_prison=0;
   if flag_birth = 1 or flag_visa_under5 = 1 then flag_under5 = 1;
   else flag_under5 = 0;
   activity_flag = 1;
run;

** Combine all individuals who have activity and are in the spine **;
data totalpop;
   merge total_activity_pop (in=a) spinepop (in=b);
   by snz_uid;

   ** Only include invididuals who had activity and are in spine;
   if a and b;

   ** Calculate age from birth year and month **;
   age = &year. - snz_birth_year_nbr;

   ** Remove people with no date of birth or sex information;
   if age < 0 then delete;
   if snz_sex_code = '' then delete;
   ** Remove individuals with deaths prior to reference date ;
   if snz_deceased_year_nbr <= &year.
         and snz_deceased_year_nbr ne . then delete;

   rename snz_sex_code = sex;
   keep snz_uid snz_sex_code age flag_ir flag_ed flag_health flag_acc flag_under5 flag_prison snz_birth_year_nbr snz_birth_month_nbr;
run;

******************************************************************************
***   Remove individuals from the population if they are living overseas   ***
******************************************************************************;

** Calculate amount of time spent overseas in last 12 months (KM - actually the 12 months centred on the 31 December date of interest);
proc sql;
   create table overseas_spells_1yr as
   select distinct snz_uid , pos_applied_date, pos_ceased_date, pos_day_span_nbr
   from central.person_overseas_spell
   where pos_applied_date <= "31DEC&year.:23:59:59.999"dt and pos_ceased_date >= "01JAN&year.:00:00:00.000"dt
   order by snz_uid, pos_applied_date;
quit;

** Calculate number of days spent overseas **;
data overseas_time_1yr;
   set overseas_spells_1yr;
   if pos_ceased_date > "31DEC&year.:23:59:59.999"dt and pos_applied_date < "01JAN&year.:00:00:00.000"dt 
      then time_to_add = 365;

   else if pos_ceased_date > "31DEC&year.:23:59:59.999"dt  and pos_applied_date >= "01JAN&year.:00:00:00.000"dt
      then time_to_add = ("31DEC&year.:23:59:59.999"dt - pos_applied_date) / 86400;

   else if pos_ceased_date <= "31DEC&year.:23:59:59.999"dt and pos_applied_date >= "01JAN&year.:00:00:00.000"dt 
      then time_to_add = (pos_ceased_date - pos_applied_date) / 86400;

   else if pos_ceased_date <= "31DEC&year.:23:59:59.999"dt and pos_applied_date < "01JAN&year.:00:00:00.000"dt 
      then time_to_add = (pos_ceased_date - "01JAN&year.:00:00:00.000"dt) / 86400;
run;

proc sql;
   create table time_overseas_1yr as 
   select snz_uid, ROUND(SUM(time_to_add),1) as days_overseas_last1
   from overseas_time_1yr
   group by snz_uid;
quit;

** Combine total population with time spent overseas;
data idierp;
   merge totalpop (in=a) time_overseas_1yr;
   by snz_uid;
   if a;

   ** remove people who are overseas for more than 6 months out of the last 12;
   if days_overseas_last1 > 182 then delete;
run;

** Code below - added KM 16012017;
** Apply migration status as at most recent spell in NZ to 31 December &year. - use the MBIE-derived migration spells data to define status at the date of interest;

** Use the version of migration spells on researchdata for now, as there are problems with the sandpit;
libname migdata "\\wprdfs08\ResearchData\IDI Migration Analysis\SAS data";
data project.idierp_mig(rename=(spell_stream=visa_type start_date=visa_start end_date=visa_end));
	merge idierp(in=a) /*sanddol*/migdata.migration_spells(where=(start_date<="31Dec&year."d) keep=snz_uid spell_stream arrival_visa start_date end_date date_arrive date_depart);
	by snz_uid;
	if a;
	if last.snz_uid then output;
run;

** Now exclude anyone with temporary status as at 31 December &year. - that is students, workers, and visitors, as well as a very small number with transit visas or unrecorded visa type;
data project.idierp0to24_&year._tempexcl idierp0to24_temponly;
	set project.idierp_mig;
	where age <= 24;
	if visa_type in ('WORK','STUDENT',"VISITOR'S",'TRANSIT','(NOT RECORDED)') then output idierp0to24_temponly;
	else output project.idierp0to24_&year._tempexcl;
run;

************************************************************
***   Derive latest address for individuals in IDI-ERP   ***
************************************************************;
proc sql;
   create table project.idierp0to24_&year._address as
   select snz_uid, ant_address_source_code, ant_notification_date, ant_meshblock_code as latest_mb, ant_ta_code as latest_ta, ant_region_code as latest_reg
   from central.address_notification_full
   where ant_notification_date <= "&year.-12-31"
      and ant_address_source_code ne 'CEN'
      and ant_meshblock_code IS NOT NULL
	  and snz_uid in (select distinct snz_uid from project.idierp0to24_&year._tempexcl)
   order by snz_uid, ant_notification_date desc, ant_address_tier_nbr, ant_address_rank_nbr;
quit;

** Select latest address;
data project.idierp0to24_&year._address;
   set project.idierp0to24_&year._address;
   by snz_uid;
   if first.snz_uid;
run;

** Add latest meshblock and other address information to IDI-ERP **;
data project.idierp0to24_&year._address;
   merge project.idierp0to24_&year._tempexcl(in=a) project.idierp0to24_&year._address;
   by snz_uid;
   if a;
run;
%mend create_idi_erp(year);

%create_idi_erp(2013);
%create_idi_erp(2014);
%create_idi_erp(2015);