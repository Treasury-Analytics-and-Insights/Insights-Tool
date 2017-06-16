**********************************************************************************************************************************
Global parameters
**********************************************************************************************************************************;

%let version=archive;* for IDI refresh version control;
%let date=20161021; * for dataset version control;
%let sensor=31Dec2015; * Global censor data cut of date;
%let projectlib=project; * the indicators datasets will be saved permanently in this folder


**********************************************************************************************************************************
Set libraries
**********************************************************************************************************************************;
* creating IDI libraries based on version;
%include "\\wprdsas10\TreasuryData\MAA2013-16 Citizen pathways through human services\Common Code\Std_macros_and_libs\Std_libs.txt";

* define path that is long "location/folder" string that will be repeating everywhere;
%let path=\\wprdsas10\TreasuryData\MAA2013-16 Citizen pathways through human services\Social Investment_2016\1_Indicator_at_age_datasets\;
* set projet library;
libname Project "&path.Dataset_rerun_21102016";


**********************************************************************************************************************************
Set standard A n I macros
**********************************************************************************************************************************;
* CALL AnI generic macros that not related to specific collections;
%include "\\wprdsas10\TreasuryData\MAA2013-16 Citizen pathways through human services\Common Code\Std_macros_and_libs\Stand_macro_new.sas";

* Call macro that includes An I formats;
%include "&path.codes for rerun_21102016\FORMATS_new.sas";

* Call AnI macros that related to specific collections;

%include "&path.codes for rerun_21102016\COR_macro_new.sas";
%include "&path.codes for rerun_21102016\CYF_macro_new.sas";
%include "&path.codes for rerun_21102016\MSD_macro_new.sas";
%include "&path.codes for rerun_21102016\MOE_macro_new.sas";
%include "&path.codes for rerun_21102016\INCOME_COST_macro_new.sas";
%include "&path.codes for rerun_21102016\CUST_macro_new.sas";
%include "&path.codes for rerun_21102016\get_ethnicity_new.sas";
%include "&path.codes for rerun_21102016\Relationships_macro_new.sas";
%include "&path.codes for rerun_21102016\HEALTH_macro_new.sas";
%include "&path.codes for rerun_21102016\CG_CORR_macro_new.sas";
%include "&path.codes for rerun_21102016\CG_CYF_macro_new.sas";
%include "&path.codes for rerun_21102016\SIB_CYF_macro_new.sas";
%include "&path.codes for rerun_21102016\Maternal_EDU_macro_new.sas";
%include "&path.codes for rerun_21102016\DIA_births_macro_new.sas";

**********************************************************************************************************************************
Include pre defined population of interest
**********************************************************************************************************************************;
%let population=project.Population1988_2016;
proc sort data=&population; by snz_uid;run;

options compress=yes reuse=yes ; * compress datasets to save space in IDI;

**********************************************************************************************************************************
Parameters related to population of interest
Parameters for annual summary of indicators
**********************************************************************************************************************************;

%let first_anal_yr=1988;* first calendar year of analysis, first year of birth for popualtion of interest;
%let last_anal_yr=2015;* Last calendar year of analysis;

%let msd_left_yr=1993; * the year first BDD time series;
%let cyf_left_yr=1990; * the first year of CYF datasets;

%let firstage=0; * start creating variables from birth, at age 0 means a year from DOB to first biorthday;
%let lastage=26; * dependent on population of interest, the last year of follow up of oldest children;
%let cyf_lastage=18; * censor age for CYF variables;

%let cohort_start=&first_anal_yr;

**********************************************************************************************************************************
Create annual indicatros for Population of interest
**********************************************************************************************************************************;

%Create_relationship_tables_pop; * run for population1988_2016;
%Create_ethnicity_pop;* run for population1988_2016;

%Create_MSD_ind_child_pop;* run for population1988_2016;
%Create_MSD_ind_adult_pop;* run for population1988_2016;

%Create_CYF_ind_pop;* run for population1988_2016;
%Create_CORR_ind_pop;* run for population1988_2016;

%Create_sch_enr_da_pop;* run for population1988_2016;
%Create_sch_attended_pop;* run for population1988_2016;
%Create_sch_qual_pop;* run for population1988_2016;

%Create_edu_interv_pop;* run for population1988_2016;
%Create_ter_enrol_pop;* run for population1988_2016;
%Create_IT_MA_enrol_pop;* run for population1988_2016;

%Create_ter_compl_pop;* run for population1988_2016;

%Create_Earn_pop;* Takes long time to run, not run for population;
%Create_OS_spell_pop;* run for population1988_2016;
%Create_BEN_cost_pop;* run for population1988_2016;

%Create_MH_ind_pop;* Takes long time to run, not run for population;

%Create_MH_PRIM_ind_pop;* Creates PRIm based mental health indicators ;

%Create_moth_father_pop; * Created number of children mothered/fathered in a given year or window of age;

* Correction history of caregivers;
%Create_CG_corr_history(msd,1);* run for population1988_2016;
%Create_CG_corr_history(msd,2);* run for population1988_2016;

%Create_CG_corr_history(dia,1);* run for population1988_2016;
%Create_CG_corr_history(dia,2);* run for population1988_2016;

%Create_CG_corr_history(cen,1);* NOT run ;
%Create_CG_corr_history(cen,2);* NOT run ;

%Create_CG_corr_history(dol,1);* NOT run ;
%Create_CG_corr_history(dol,2);* NOT run ;

%Create_CG_corr_history(all,1);* run for population1988_2016;
%Create_CG_corr_history(all,2);* run for population1988_2016;

* CYF history of caregivers;
%Create_CG_CYF_history(msd,1);* run for population1988_2016;
%Create_CG_CYF_history(msd,2);* run for population1988_2016;

%Create_CG_CYF_history(dia,1);* run for population1988_2016;
%Create_CG_CYF_history(dia,2);* run for population1988_2016;

%Create_CG_CYF_history(all,1);* run for population1988_2016;
%Create_CG_CYF_history(all,2);* run for population1988_2016;

%Create_CG_CYF_history(cen,1);* NOT run ;
%Create_CG_CYF_history(cen,2);* NOT run ;

%Create_CG_CYF_history(cen,1);* NOT run ;
%Create_CG_CYF_history(cen,2);* NOT run ;


* CYF hisory of siblings;
%Create_sib_CYF_pop(msd,msd);* run for population1988_2016;
%Create_sib_CYF_pop(dia,dia);* run for population1988_2016;
%Create_sib_CYF_pop(all,all);* run for population1988_2016;

* Maternal education of mothers;
%Create_Mat_edu_pop(dia);* run for population1988_2016;
%Create_Mat_edu_pop(msd);* run for population1988_2016;
%Create_Mat_edu_pop(all);* run for population1988_2016;

%Create_Mat_edu_pop(cen);* NOT run ;
%Create_Mat_edu_pop(dol);* NOT run ;

**********************************************************************************************************************************
Parameters related to population of interest
Parameters for monthly summary of indicators
**********************************************************************************************************************************;
* Make sure that months you want to cover are within range of years set by first_anal_yr and last_anal_yr;
%let start='01JAN2015'd;
%let m=190; * 190- Jan 2015 , 188-Nov 2014;
%let n=201;* 201-dec 2015;

**********************************************************************************************************************************
Create Monthly datasets
**********************************************************************************************************************************;

%Create_mth_OS_spell_pop;
%Create_mth_Sch_enrol_pop;
%Create_mth_Ter_enrol_pop;
%Create_mth_IT_MA_enrol_pop;

%Create_mth_CORR_ind_pop;
%Create_mth_MSD_ind_adult_pop;
%Create_mth_MSD_ind_child_pop;

%Create_mth_CYF_ind_child_pop;

