
******************************************************************************************************************************************
Create Risk factors for population of interest for youth ages 15-24 as at Dec 2015
we will create risk profile by age 15
******************************************************************************************************************************************;
******************************************************************************************************************************************
Create Risk factors for population of interest

******************************************************************************************************************************************;
* left join the required "indicator at year" datasets onto the current population;
* NOTE: Population need to have a ageat05Mar2013 variable;
%macro risk_factors_by_year(population,by_year);
proc sql;
	create table TEMP_PERSON as select
		a.*,  b.* ,     c.* ,     d.* ,     e.* ,      f.* ,     g.* ,     h.*
	from &population a 
		
		left join   inputlib._ind_ben_child_at_age_&date.(keep = snz_uid at_birth_onben) b  on a.snz_uid=b.snz_uid
		left join   inputlib._ind_ben_child_&date.(keep=snz_uid ch_total_da_onben:) c on a.snz_uid=c.snz_uid

		left join   inputlib._all_CG_1_CORR_&date.(keep=snz_uid cg_1:) d on a.snz_uid=d.snz_uid 
		left join   inputlib._all_CG_2_CORR_&date.(keep=snz_uid cg_2:) e on a.snz_uid=e.snz_uid 

		left join   inputlib._IND_CYF_child_&date.(keep=snz_uid ch_any_fdgs: ch_cyf_place: ch_not: ch_CYF_ce: ch_YJ_ce:) f on a.snz_uid=f.snz_uid 
		
		left join   inputlib._all_all_SIB_CYF_&date.(keep=snz_uid othchd_any: othchd_not: othchd_cyf:) g on a.snz_uid=g.snz_uid 

		left join   inputlib._all_MAT_EDU_COM_&date.(keep=snz_uid maternal_edu:) h on a.snz_uid=h.snz_uid;
run;

data TEMP_PERSON; set TEMP_PERSON (where=(age>=15));
%onezero_var(at_birth_onben);

%missing_array(ch_total_da_onben,&first_anal_yr.,&by_year.);
%onezero_array(ch_any_fdgs_abuse,&first_anal_yr.,&by_year.);
%onezero_array(ch_not,&first_anal_yr.,&by_year.);
%onezero_array(ch_CYF_place,&first_anal_yr.,&by_year.);
%onezero_array(ch_CYF_ce,&first_anal_yr.,&by_year.);
%onezero_array(ch_YJ_ce,&first_anal_yr.,&by_year.);
%onezero_array(othchd_any_fdgs_abuse,&first_anal_yr.,&by_year.);
%onezero_array(othchd_not,&first_anal_yr.,&by_year.);
%onezero_array(othchd_CYF_place,&first_anal_yr.,&by_year.);
%onezero_array(cg_1_cust,&first_anal_yr.,&by_year.);
%onezero_array(cg_1_comm,&first_anal_yr.,&by_year.);
%onezero_array(cg_2_cust,&first_anal_yr.,&by_year.);
%onezero_array(cg_2_comm,&first_anal_yr.,&by_year.);
run;

data Risk_factors_&by_year.;
	set TEMP_PERSON;

/*	keep snz_uid */
/*	age ageat year15*/
/*		cyf_risk_&by_year.*/
/*		corr_risk_&by_year.*/
/*		wi_risk_&by_year.*/
/*		risk_mat_no_edu_&by_year. 	*/
/*		WI_onben_ge75_&by_year.	*/
/*		risk_factors_&by_year.*/
/*		risk_factors_2plus_&by_year.*/
		;

	ageat=floor((intck('month',dob,mdy(12,31,&by_year.))- (day(mdy(12,31,&by_year.)) < day(dob))) / 12);

	ch_total_da_onben_by&by_year.=sum(of ch_total_da_onben_&first_anal_yr.-ch_total_da_onben_&by_year.);

	ch_not_by&by_year.=max(of ch_not_&first_anal_yr.-ch_not_&by_year.);
	ch_any_fdgs_by&by_year.=max(of ch_any_fdgs_abuse_&first_anal_yr.-ch_any_fdgs_abuse_&by_year.);
	ch_CYF_place_by&by_year.=max(of ch_CYF_place_&first_anal_yr.-ch_CYF_place_&by_year.);
	ch_CYF_CE_by&by_year.=max(of ch_CYF_CE_&first_anal_yr.-ch_CYF_CE_&by_year.);
	ch_YJ_CE_by&by_year.=max(of ch_YJ_CE_&first_anal_yr.-ch_YJ_CE_&by_year.);

	othchd_any_fdgs_by&by_year.=max(of othchd_any_fdgs_abuse_&first_anal_yr.-othchd_any_fdgs_abuse_&by_year.);
	othchd_not_by&by_year.=max(of othchd_not_&first_anal_yr.-othchd_not_&by_year.);
	othchd_CYF_place_by&by_year.=max(of othchd_CYF_place_&first_anal_yr.-othchd_CYF_place_&by_year.);

	maternal_edu_by&by_year.=max(of maternal_edu_&first_anal_yr.-maternal_edu_&by_year.);

	cg_cust_1_by&by_year.=max(of cg_1_cust_&first_anal_yr.-cg_1_cust_&by_year.);
	cg_comm_1_by&by_year.=max(of cg_1_comm_&first_anal_yr.-cg_1_comm_&by_year.);

	cg_cust_2_by&by_year.=max(of cg_2_cust_&first_anal_yr.-cg_2_cust_&by_year.);
	cg_comm_2_by&by_year.=max(of cg_2_comm_&first_anal_yr.-cg_2_comm_&by_year.);


	cg_cust_by&by_year.=max(of cg_cust_1_by&by_year.,cg_cust_2_by&by_year.);
	cg_comm_by&by_year.=max(of cg_comm_1_by&by_year.,cg_comm_2_by&by_year.);



* note: the above variables are summed over all the years 1988 onwards even though many individuals are born well  after 1988;
* they are missing prior to anyones birth date o this does not cause any problema nd just makes the coding simpler;

	****************************************;
	* create WI risk factor;
	****************************************;
	* indicator of being supported by benefit at birth;
	supp_ben_at_birth = max(at_birth_onben);

	days_of_life = mdy(12,31,&by_year.) - dob; 
	prop_of_life_onben_&by_year.= ch_total_da_onben_by&by_year./days_of_life;
	WI_onben_ge75_&by_year.= (prop_of_life_onben_&by_year. ge 0.75);

	if ageat=0 then
		do;
			if supp_ben_at_birth or WI_onben_ge75_&by_year. then
				WI_risk_&by_year. = 1;
			else WI_risk_&by_year. = 0;
		end;
	else
		do;
			if WI_onben_ge75_&by_year. then
				WI_risk_&by_year. = 1;
			else WI_risk_&by_year. = 0;
		end;

	****************************************;
	* create CYF risk factor;
	****************************************;

	* indicator for the children themselves. But if the child is under 3 then
	  include indicator of their siblings;

	* adding sibling info for 0 and 1 year olds;
	* converting the abuse variables into indicators;
	if ageat = 0 then
		do;
			CYF_risk_&by_year. = max(ch_any_fdgs_by&by_year.
				,ch_CYF_place_by&by_year.
				,ch_CYF_CE_by&by_year.
				,ch_not_by&by_year.
				,othchd_any_fdgs_by&by_year.
				,othchd_not_by&by_year.
				,othchd_CYF_place_by&by_year.);
		end;
	else if ageat <=2 then
		do;
			CYF_risk_&by_year. = (max(ch_any_fdgs_by&by_year.
				,ch_CYF_place_by&by_year.
				,ch_CYF_CE_by&by_year.
				,othchd_any_fdgs_by&by_year.
				,othchd_CYF_place_by&by_year.));
		end;
	else
		do;
			CYF_risk_&by_year. = max(ch_any_fdgs_by&by_year.
				,ch_CYF_place_by&by_year.
				,ch_CYF_CE_by&by_year.);
		end;

	****************************************;
	* create mother education risk factor;
	****************************************;
	risk_mat_no_edu_&by_year. = (maternal_edu_by&by_year. in (0));

	****************************************;
	* create CG CORR_ections risk factor;
	****************************************;
	CORR_risk_&by_year. = max(cg_cust_by&by_year., cg_comm_by&by_year.);

	****************************************;
	* Count risk factors;
	****************************************;
	risk_factors_&by_year.= sum(WI_risk_&by_year.
		,CYF_risk_&by_year.
		,CORR_risk_&by_year.
		,risk_mat_no_edu_&by_year.
		,0);
	risk_factors_2plus_&by_year.=(risk_factors_&by_year. ge 2);
if ch_not_&by_year.>1 then ch_not_ever=1; else ch_not_ever=0;
if ageat=15;

run;
%mend;


* for population ref year 2015 2006-2015 is the window for risk factors by age 15;
* for population ref year 2014 2005-2014 is the window for risk factors by age 15;
* for population ref year 2013 2004-2013 is the window for risk factors by age 15;
%macro run_all(by_year);
%do i=1 %to 10;
%risk_factors_by_year(project.population_&by_year._0_24,%eval(&by_year.-&i+1));* 24 yrs olds at age 15;
%end;

DATA project.RISK_FACTORS_&by_year._15_24_by_age15; 
merge RISK_FACTORS_:;
by snz_uid;
%do i=1 %to 10;
	if year15=%eval(&by_year.-&i+1) then do;
			cyf_risk_by15=cyf_risk_%eval(&by_year.-&i+1);
			corr_risk_by15=corr_risk_%eval(&by_year.-&i+1);
			wi_risk_by15=wi_risk_%eval(&by_year.-&i+1);
			risk_mat_no_edu_by15=risk_mat_no_edu_%eval(&by_year.-&i+1); 	
			WI_onben_ge75_by15=WI_onben_ge75_%eval(&by_year.-&i+1);	
			risk_factors_by15=risk_factors_%eval(&by_year.-&i+1);
			risk_factors_2plus_by15=risk_factors_2plus_%eval(&by_year.-&i+1);
	end;
%end;
keep snz_uid year15 cyf_risk_by15
		corr_risk_by15
		wi_risk_by15
		risk_mat_no_edu_by15 	
		WI_onben_ge75_by15
risk_factors_by15	
		risk_factors_2plus_by15;
run;
proc datasets lib=work;
delete RISK_FACTORS_:;
run;

%mend;



%macro Tab_risk_byage15(dataset);
proc tabulate data=&dataset;
class year15;
var cyf_risk_by15
		corr_risk_by15
		wi_risk_by15
		risk_mat_no_edu_by15 	
		WI_onben_ge75_by15	
		risk_factors_2plus_by15;
tables  year15, cyf_risk_by15
		corr_risk_by15
		wi_risk_by15
		risk_mat_no_edu_by15 	
		WI_onben_ge75_by15	
		risk_factors_2plus_by15;
run;
%mend;

