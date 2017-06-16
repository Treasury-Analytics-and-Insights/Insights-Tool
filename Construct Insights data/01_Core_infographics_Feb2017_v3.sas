
**********************************************************************************************************************************
Global parameters
**********************************************************************************************************************************;

%let version=archive;* for IDI refresh version control;
%let date=20161021; * for dataset version control;
%let sensor=31Dec2015; * Global censor data cut of date;


**********************************************************************************************************************************
Set libraries
**********************************************************************************************************************************;
%include "\\wprdsas10\TreasuryData\MAA2013-16 Citizen pathways through human services\Common Code\Std_macros_and_libs\Std_libs.txt";
%let path=\\wprdsas10\TreasuryData\MAA2013-16 Citizen pathways through human services\Social Investment_2016\1_Indicator_at_age_datasets\;
%let path2=&path2.;

libname Inputlib "&path.Dataset_rerun_21102016";
libname project "&path2.\Datasets";


**********************************************************************************************************************************
Set standard A n I macros
**********************************************************************************************************************************;
* CALL AnI generic macros that not related to specific collections;
%include "&path2.\Stand_macro_new.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 1: Include pre defined population of interest
**********************************************************************************************************************************
**********************************************************************************************************************************;

** Create address_event data;


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
inputlib.address_event 
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
%let first_anal_yr=1989;
%let msd_left_yr=1989;
%let cyf_left_yr=1989;

* first calendar year of analysis;
%let last_anal_yr=2015;

* Last calendar year of analysis;
%let firstage=0;

* start creating variables from birth to age 1;
%let lastage=18;
%let cyf_lastage=18;

options compress=yes reuse=yes ;


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 2: Create risk factors for 0-24 age groups
**********************************************************************************************************************************
**********************************************************************************************************************************;
%include "&path2.\SAS code\02_RISK Factors_0_14_Feb2017_v2.sas";
%Create_risk_factors_0_14(project.population_2015_0_24,2015);
%Create_risk_factors_0_14(project.population_2014_0_24,2014);
%Create_risk_factors_0_14(project.population_2013_0_24,2013);

%include "&path2.\SAS code\02_risk_groups_2015_15_19_ST_v2.sas";
* Create risk factors for given population, by given year, last argument is the year prior to by_year;
%Create_risk_factors_15_19(project.population_2015_0_24,2015);
%Create_risk_factors_15_19(project.population_2014_0_24,2014);
%Create_risk_factors_15_19(project.population_2013_0_24,2013);

%include "&path2.\SAS codes\codes_v2\02_risk_groups_2015_20_24_ST_v2.sas";
%Create_risk_factors_20_24(project.population_2015_0_24,2015);
%Create_risk_factors_20_24(project.population_2014_0_24,2014);
%Create_risk_factors_20_24(project.population_2013_0_24,2013);


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 3: Tabulation for Risk tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
libname Output "&path2.\Output\Risk tool\Mapping";

%include "&path2.\SAS code\03_Tables for Infographics_Outcomes_tool_v2.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 4: Create Monthly datasets for Outcomes tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
libname Output1 "&path2.\Output\Outcomes tool\Tables and graphs";
libname Output2 "&path2.\Output\Outcomes tool\Mapping";

%include "&path2.\SAS code\03_Tables for Infographics_Outcomes_tool_v3.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 5: CREATE final datasets for Outcomes tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
%include "&path2.\SAS code\03_Tables for Infographics_Outcomes_tool_v3.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 6: Create Monthly datasets for Outcomes tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
%include "&path2.\SAS code\03_Tables for Infographics_Outcomes_tool_v3.sas";


**********************************************************************************************************************************
**********************************************************************************************************************************
PART 7: CREATE final datasets for Outcomes tool
**********************************************************************************************************************************
**********************************************************************************************************************************;
%include "&path2.\SAS codes\codes_v3\03_Tables for Infographics_Outcomes_tool_v3.sas";