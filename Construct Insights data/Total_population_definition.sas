******************************************************************************************************************************************************
DEFINING BIRTH COHORTS

Analyst: Sarah Tumen
QA Analyst:
Created date: 11 Sep 2014
Code modified : 23 June 2015 to capture youth population as at end of 2013 (aged 15 and above).

******************************************************************************************************************************************************
       Obtaining those records of unique citizen in IDI
	Notes: This includes unique citizen that have records with IRD, MOE, MSD, Justice)
	This includes records of seasonal workers, overseas residents, international students ( at later stage they will be exlcuded from population).
*******************************************************************************************************************************************************;

* Run 00_code.sas code to get macros and libraries;
*Obtaining all records from admin datasets using SNZ concordance table;
proc SQL;
	Connect to sqlservr (server=WPRDSQL36\iLeed database=IDI_clean);
	create table CONC as select * from connection to  sqlservr
		(select 
			snz_uid, 
			snz_ird_uid, 
			snz_dol_uid, 
			snz_moe_uid, 
			snz_msd_uid,
			snz_dia_uid,
			snz_moh_uid, 
			snz_jus_uid from security.concordance)
where snz_uid>0
order by snz_uid;
quit;

proc SQL;
	Connect to sqlservr (server=WPRDSQL36\iLeed database=IDI_clean);
	create table PERS as select * from connection to  sqlservr
		(select 
			snz_uid, 
			snz_sex_code,
			snz_birth_year_nbr,
			snz_birth_month_nbr,
			snz_ethnicity_grp1_nbr,
			snz_ethnicity_grp2_nbr,
			snz_ethnicity_grp3_nbr,
			snz_ethnicity_grp4_nbr,
			snz_ethnicity_grp5_nbr,
			snz_ethnicity_grp6_nbr,
			snz_deceased_year_nbr,
			snz_deceased_month_nbr,
			snz_person_ind,
			snz_spine_ind
		from data.personal_detail)
where snz_birth_year_nbr >=1988 and snz_birth_year_nbr<=2016
order by snz_uid;
quit;

* This definition of the cohorts includes international students, overseas residents, deceased as at today and other subgroups of population, these subgroups need to be identified
* We will create indicators that will help to define population of interest;

* We decided to run this refresh for cohort 1990;
data Birth;
	merge conc (in=a) pers (in=b);
	by snz_uid;

	if a and b;

	if snz_person_ind=1;

	* Limiting to actual people;
	if snz_spine_ind=1;

	* This is to limit to people only who linked to the spine;

	format DOB DOD date9.;
	DOB=MDY(snz_birth_month_nbr,15,snz_birth_year_nbr);
	DOD=MDY(snz_deceased_month_nbr,15,snz_deceased_year_nbr);

run;

data project.Population1988_2016;
	set Birth;
run;

proc datasets lib=work kill nolist memtype=data;
quit;