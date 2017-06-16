**********************************************************************************************************************************
**********************************************************************************************************************************
CORE INSIGHTS - This code runs all of the code necessary to construct the Insights data - Risk tool / Youth Transitions tool / Services tool
The population needs to be constructed first - run Construct IDIERP at 31 December before running this
**********************************************************************************************************************************
**********************************************************************************************************************************;

**********************************************************************************************************************************
Global parameters
**********************************************************************************************************************************;

%let version=archive;* for IDI refresh version control; ** Note that archive will use the latest refresh. The Insights tool used refresh 20161020;
%let date=20161021; * for dataset version control;
%let sensor=31Dec2015; * Global censor data cut of date;
%let population=project.Population1988_2016;

**********************************************************************************************************************************
Set libraries and folder locations
**********************************************************************************************************************************;
libname data ODBC dsn=idi_clean_&refresh._srvprd schema=data;
libname moe ODBC dsn=idi_clean_&refresh._srvprd schema=moe_clean;
libname msd ODBC dsn=idi_clean_&refresh._srvprd schema=msd_clean;
libname cyf ODBC dsn=idi_clean_&refresh._srvprd schema=cyf_clean;
libname cor ODBC dsn=idi_clean_&refresh._srvprd schema=cor_clean;
libname ird ODBC dsn=idi_clean_&refresh._srvprd schema=ir_clean;
libname moh ODBC dsn=idi_clean_&refresh._srvprd schema=moh_clean;
libname hnz ODBC dsn=idi_clean_&refresh._srvprd schema=hnz_clean;
libname acc ODBC dsn=idi_clean_&refresh._srvprd schema=acc_clean;
libname dia ODBC dsn=idi_clean_&refresh._srvprd schema=dia_clean;
libname dol ODBC dsn=idi_clean_&refresh._srvprd schema=dol_clean;
libname sanddol ODBC dsn=idi_clean_&refresh._srvprd schema=sanddol;

** Set path to the location where code is stored, and datasets and tables are to be stored - subfolders should be SAS Code, datasets, output, and tables;
%let path=\\wprdsas10\treasurydata\MAA2013-16 Citizen pathways through human services\Infographics;
libname project "&path.\Datasets";
libname inputlib "&path.\Datasets";
%let projectlib=project;
libname projectlib "&path.\Datasets";

**********************************************************************************************************************************
Construct total population
**********************************************************************************************************************************;
* CALL AnI generic macros that not related to specific collections;
%include "&path.\SAS Code\Total_population_definition.sas";


**********************************************************************************************************************************
Set standard A n I macros
**********************************************************************************************************************************;
* CALL AnI generic macros that not related to specific collections;
%include "&path.\SAS Code\Stand_macro_new.sas";


**********************************************************************************************************************************
Create address event table 
**********************************************************************************************************************************;
* Creates dataset Project.Address_Event;
%include "&path.\SAS Code\Address_Event_Create.sas";

**********************************************************************************************************************************
Create source indicator datasets 
**********************************************************************************************************************************;
%include "&path.\SAS Code\Relationships_macro_new.sas";
%include "&path.\SAS Code\MSD_macro_new.sas";
%include "&path.\SAS Code\DIA_births_macro_new.sas";
%include "&path.\SAS Code\Maternal_EDU_macro_new.sas";
%include "&path.\SAS Code\SIB_CYF_macro_new.sas";
%include "&path.\SAS Code\CYF_macro_new.sas";
%include "&path.\SAS Code\get_ethnicity_new.sas";
%include "&path.\SAS Code\CG_CORR_macro_new.sas";

* Run the macros to creat the datasets;
%Create_relationship_tables_pop; ** Create parent to child map - needed later;
%Create_ethnicity_pop; * Create _ind_ethnicity_&date.;
%create_MSD_ind_child_pop; * Create _ind_ben_child_at_age_&date. and _ind_ben_child_&date.;
%Create_CG_corr_history(rel=all,sex=1); * Create _all_CG_1_CORR_&date.;
%Create_CG_corr_history(rel=all,sex=2); * Create _all_CG_2_CORR_&date.;
%Create_CYF_ind_pop; * Create _IND_CYF_child_&date.;
%Create_sib_CYF_pop(rel1=all,rel2=all); * Create _all_all_SIB_CYF_&date.;
%Create_Mat_edu_pop(rel=all); * Create _all_MAT_EDU_COM_&date.;
%Num_children_pop; * Create _IND_PARENT_20161021; 

**********************************************************************************************************************************
**********************************************************************************************************************************
PART 1: Include pre defined population of interest
**********************************************************************************************************************************
**********************************************************************************************************************************;
* Define population 0-24 using Estimated resident population;
%macro Create_population (ref_year);
data Population_&ref_year.; set project.idierp0to24_&ref_year._tempexcl;
proc sort data=Population_&ref_year.; by snz_uid;run;
* get the addresses as at end of reference period;
proc sql;
create table 
temp_address_event
as select 
snz_uid,
startdate,
enddate,
source,
meshblock
from 
project.address_event 
where snz_uid in (select snz_uid from Population_&ref_year.)
order by snz_uid;

data temp_address_event; set temp_address_event;
if startdate>MDY(12,13,&ref_year.) then delete;
if enddate=.  then enddate=MDY(12,13,&ref_year.);
if startdate<=MDY(12,13,&ref_year.) and enddate>=MDY(12,13,&ref_year.) then chosen_add=1; 
if chosen_add=1; 
mesh=1*meshblock;
run;

proc sql;
create table 
temp_address_event_pop
as select 
a.*,
b.REGC2016_N as reg,
b.TA2016_NAM as tla,
b.AU2016_NAM as au,
b.WARD2016_N as ward
from 
temp_address_event a
left join project.MESHBLOCK_CONCORDANCE_2016 b
on a.mesh=b.MB2016
order by snz_uid;

data project.population_&ref_year._0_24; 
merge Population_&ref_year.(in=a) 
temp_address_event_pop ; by snz_uid;
DOB=MDY(snz_birth_month_nbr,15,snz_birth_year_nbr);
format DOB date9.;
	x_gender=sex;
	if x_gender='2' then x_gender_desc='Female';
	if x_gender='1' then x_gender_desc='Male';

	* creating age groups;
	if age<6 then age_desc='00-05';
	else if age>=6 and age<=14 then age_desc='06-14';
	else if age>=15 and age<=19 then age_desc='15-19'; 
	else age_desc='20-24';
	x_mesh=mesh; * Numeric variable;

	** Largest 5 main centres we use Ward instead of TA for more geographic detail;
	if tla in('Auckland','Hamilton City','Wellington City','Christchurch City','Tauranga City') then tla=ward;
	bday_15=intnx('YEAR',dob,15,'S');
	year15=year(bday_15);

run;

%mend;

%create_population(2013);
%create_population(2014);
%create_population(2015);

proc freq data=project.population_2013_0_24; tables age; run;
**********************************************************************************************************************************
Parameters related to population of interest
Parameters for annual summary of indicators
**********************************************************************************************************************************;

* Global sensor data cut of date;
* the oldest person born in 1998;
%let msd_left_yr=1989;
%let cyf_left_yr=1989;

*;ears of analysis;
%let first_anal_yr=1989;
%let last_anal_yr=2015;

* start creating variables from birth to age 18;
%let firstage=0;
%let lastage=18;
%let cyf_lastage=18;

options compress=yes reuse=yes ;


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 2: Create risk factors and risk groups for 0-24 age groups
**********************************************************************************************************************************
**********************************************************************************************************************************;
%include "&path.\SAS code\R_01_RISK Factors_0_14_FINAL.sas";
%Create_risk_factors_0_14(project.population_2015_0_24,2015);
%Create_risk_factors_0_14(project.population_2014_0_24,2014);
%Create_risk_factors_0_14(project.population_2013_0_24,2013);

%include "&path.\SAS code\R_02_risk_groups_2015_15_19_FINAL.sas";
* Create risk factors for given population, by given;ear, last argument is the;ear prior to by_year;
%Create_risk_factors_15_19(project.population_2015_0_24,2015);
%Create_risk_factors_15_19(project.population_2014_0_24,2014);
%Create_risk_factors_15_19(project.population_2013_0_24,2013);

%include "&path.\SAS code\R_03_risk_groups_2015_20_24_FINAL.sas";
%Create_risk_factors_20_24(project.population_2015_0_24,2015);
%Create_risk_factors_20_24(project.population_2014_0_24,2014);
%Create_risk_factors_20_24(project.population_2013_0_24,2013);

*** Now create data for the number of risk factors at age 15 for the 15 to 24;ear old population;
*** This is not used in the Risk tool, but feeds through into the youth transitions and services tools;
%include "&path.\SAS code\R_05_RISK Factors_byage15_ages15_24_FINAL.sas";
%run_all(by_year=2015);
%run_all(by_year=2014);
%run_all(by_year=2013);

**********************************************************************************************************************************
**********************************************************************************************************************************
PART 3: Tabulation for Risk tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
libname Output "&path.\Output\";

%include "&path.\SAS code\R_04_Tables_Risk_Tool_FINAL.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 4: Create Monthly datasets for Outcomes tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
libname Output1 "&path.\Output";
libname Output2 "&path.\Output";
%include "&path.\SAS code\YT_01_Create monthly indicator datasets_trimmed_FINAL.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 5: CREATE final datasets for Outcomes tool and produce output tables
**********************************************************************************************************************************
**********************************************************************************************************************************;
%include "&path.\SAS code\YT_02_Main_activity_graphs_for_cross_sectional_samples_FINAL.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 6: Create datasets for Service tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
%include "&path.\SAS code\S_01_Create service use data_FINAL.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 7: Output tables for service tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
libname Output1 "&path.\Output";
libname Output2 "&path.\Output";
%include "&path.\SAS Code\S_02_Tables_Services_tool_FINAL.sas";