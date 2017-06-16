*************************************************************************************************************************************
*************************************************************************************************************************************
Construct datasets for SERVICES TOOL
*************************************************************************************************************************************
*************************************************************************************************************************************;

%macro create_service_date(year);
data emp_assist_1115;
	set msd.msd_employment_assistance;
	year_start=substr(msd_empa_participation_start_dat,1,4);
 	if "&year." >= year_start >="%eval(&year.-4)" then output;
run;

proc sort data=emp_assist_1115;
	by snz_uid year_start;
run;

data emp_assist_1115b(keep=snz_uid year_start emp_:);
	set emp_assist_1115;
	retain emp_info emp_place emp_skill emp_ws emp_other;
	by snz_uid year_start;
	if first.year_start then do; emp_info=0; emp_place=0; emp_skill=0; emp_ws=0; emp_other=0; end;

	if msd_empa_prog_name_text ='CAREERS GUIDANCE AND COUNSELLING' then emp_info=1;
	else if msd_empa_prog_name_text ='REGIONALINITIATIVESEMINAR' then emp_info=1;
	else if msd_empa_prog_name_text ='WORKANDINCOMESEMINAR' then emp_info=1;
	else if msd_empa_prog_name_text ='JOB PREPARATION PROGRAMME' then emp_other=1;
	else if msd_empa_prog_name_text ='JOB SEARCH INITIATIVES' then emp_other=1;
	else if msd_empa_prog_name_text ='JOB SEARCH SEMINAR' then emp_other=1;
	else if msd_empa_prog_name_text ='JOB SEARCH SERVICES' then emp_other=1;
	else if msd_empa_prog_name_text ='EMPLOYMENT PLACEMENT OR ASSISTANCE INITIATIVE' then emp_place=1;
	else if msd_empa_prog_name_text ='WORK AND INCOME VACANCY PLACEMENT' then emp_place=1;
	else if msd_empa_prog_name_text ='BE YOUR OWN BOSS' then emp_other=1;
	else if msd_empa_prog_name_text ='ENTERPRISE ALLOWANCE' then emp_other=1;
	else if msd_empa_prog_name_text ='ENTERPRISE ALLOWANCE CAPITALISATION' then emp_other=1;
	else if msd_empa_prog_name_text ='BUSINESS TRAINING AND ADVICE GRANT' then emp_skill=1;
	else if msd_empa_prog_name_text ='COURSE PARTICIPATION GRANT' then emp_skill=1;
	else if msd_empa_prog_name_text ='FOUNDATION FOCUSED TRAINING' then emp_skill=1;
	else if msd_empa_prog_name_text ='TARGETED TRAINING' then emp_skill=1;
	else if msd_empa_prog_name_text ='TRAINING INCENTIVE ALLOWANCE' then emp_skill=1;
	else if msd_empa_prog_name_text ='CORPORATE RECRUITMENT PARTNERSHIP' then emp_skill=1;
	else if msd_empa_prog_name_text ='LOCAL INDUSTRY PARTNERSHIPS' then emp_skill=1;
	else if msd_empa_prog_name_text ='STRAIGHT 2 WORK' then emp_skill=1;
	else if msd_empa_prog_name_text ='STRAIGHT 2 WORK LITERACY/NUMERACY' then emp_skill=1;
	else if msd_empa_prog_name_text ='MAINSTREAM EMPLOYMENT PROGRAMME' then emp_ws=1;
	else if msd_empa_prog_name_text ='SKILLS INVESTMENT' then emp_ws=1;
	else if msd_empa_prog_name_text ='NZ CONSERVATION CORPS' then emp_other=1;
	else if msd_empa_prog_name_text ='WORK CONFIDENCE' then emp_other=1;
	else if msd_empa_prog_name_text ='ACTIVITY IN THE COMMUNITY' then emp_other=1;
	else if msd_empa_prog_name_text ='COMMUNITYMAX' then emp_other=1;
	else if msd_empa_prog_name_text ='JOB OPS' then emp_other=1;
	else if msd_empa_prog_name_text ='JOB OPS WITH TRAINING' then emp_other=1;
	else if msd_empa_prog_name_text ='TASKFORCE GREEN' then emp_other=1;

	if last.year_start then output;
run;

** Now look at the 00-24 ERP as at December &year.;
data cohort_&year._0024;
	set project.POPULATION_&year._0_24;
	*where 15 <= age <= 24;
run;

proc sort data=cohort_&year._0024;
	by snz_uid;
run;

** And add on any employment programmes participated in over previous 5 years;
data pop_&year._0024_serv(drop=j emp_info emp_place emp_skill emp_ws emp_other year_start);
	retain 	emp_info_1yr emp_place_1yr emp_skill_1yr emp_ws_1yr emp_other_1yr emp_1yr
			emp_info_5yr emp_place_5yr emp_skill_5yr emp_ws_5yr emp_other_5yr emp_5yr;
	merge cohort_&year._0024(in=a) emp_assist_1115b(in=b);
	by snz_uid;
	array ea{*} emp_info emp_place emp_skill emp_ws emp_other;
	array emp_1yrs{*} emp_info_1yr emp_place_1yr emp_skill_1yr emp_ws_1yr emp_other_1yr;
	array emp_5yrs{*} emp_info_5yr emp_place_5yr emp_skill_5yr emp_ws_5yr emp_other_5yr;

	if first.snz_uid then do j=1 to 5 ;
		emp_1yrs{j}=0; emp_5yrs{j}=0; emp_1yr=0; emp_5yr=0;
	end;
	if a;
	do j=1 to 5 ;
		if ea{j}=1 then do; emp_5yrs{j}=1; emp_5yr=1; end;
		if ea{j}=1 and year_start=&year. then do; emp_1yrs{j}=1; emp_1yr=1; end;
	end;
	if last.snz_uid then output;
run;

** Now we want to add on Youth Service and YTS participation as well;
data yst_all(keep=snz_uid year_start year_end yst_spl_provider_name_text yst_spl_programme_code yst_spl_programme_name_text type);
	set yst.yst_spells;
	year_start=substr(yst_spl_participation_start_date,1,4);
	year_end=substr(yst_spl_participation_end_date,1,4);
	if index(yst_spl_programme_code,'NEET')>0 then type='NEET  ';
	else if index(yst_spl_programme_code,'YP')>0 then type='YP/YPP';
	else if index(yst_spl_programme_code,'YTS')>0 then type='YTS';
run;

proc sort data=yst_all;
	by snz_uid year_start;
run;

proc freq data=yst_all;
	tables yst_spl_programme_code yst_spl_programme_name_text type year_start year_end/list;
run;

data yst_allb;
	retain emp_ys_1yr emp_ysneetyts_1yr emp_ysypypp_1yr emp_ys_5yr emp_ysneetyts_5yr emp_ysypypp_5yr;
	set yst_all;
	by snz_uid year_start;
	if first.snz_uid then do; emp_ys_1yr=0; emp_ysneetyts_1yr=0; emp_ysypypp_1yr=0; emp_ys_5yr=1; emp_ysneetyts_5yr=0; emp_ysypypp_5yr=0; end;
	where year_start <= "&year." and year_end >= "%eval(&year.-4)";
	if year_start le "&year." and year_end ge "&year." then emp_ys_1yr=1;
	if year_start le "&year." and year_end ge "&year." and type in ('YTS','NEET') then emp_ysneetyts_1yr=1;
	if year_start le "&year." and year_end ge "&year." and type in ('YP/YPP') then emp_ysypypp_1yr=1;
	if year_start le "&year." and year_end ge "%eval(&year.-4)" and type in ('YTS','NEET') then emp_ysneetyts_5yr=1;
	if year_start le "&year." and year_end ge "%eval(&year.-4)" and type in ('YP/YPP') then emp_ysypypp_5yr=1;
	emp_ys_5yr=1;
	if last.snz_uid then output;
run;

data pop_&year._0024_serv_emp err;
	merge pop_&year._0024_serv(in=a) yst_allb(in=b drop=year_start);
	by snz_uid;
	if emp_ysneetyts_1yr=. then emp_ysneetyts_1yr=0;
	if emp_ysypypp_1yr=. then emp_ysypypp_1yr=0;
	if emp_ysneetyts_5yr=. then emp_ysneetyts_5yr=0;
	if emp_ysypypp_5yr=. then emp_ysypypp_5yr=0;
	if emp_ys_1yr=. then emp_ys_1yr=0;
	else if emp_ys_1yr=1 then emp_1yr=1;
	if emp_ys_5yr=. then emp_ys_5yr=0;
	else if emp_ys_5yr=1 then emp_5yr=1;
	if a then output pop_&year._0024_serv_emp;
	else output err;
run;

** Look at the education interventions;
********************************************************************************************************************************************
Create indicators of School intervention 
********************************************************************************************************************************************;
%macro enr_yr(type);* sch;

array &type._enr_da_[*] &type._enr_da_&first_anal_yr.-&type._enr_da_&last_anal_yr.;
	&type._enr_da_(i)=0;

if not((startdate > end_window) or (enddate < start_window)) then do;

					if (startdate <= start_window) and  (enddate > end_window) then
						days=(end_window-start_window)+1;
					else if (startdate <= start_window) and  (enddate <= end_window) then
						days=(enddate-start_window)+1;
					else if (startdate > start_window) and  (enddate <= end_window) then
						days=(enddate-startdate)+1;
					else if (startdate > start_window) and  (enddate > end_window) then
						days=(end_window-startdate)+1;	

					&type._enr_da_(i)=days;
					** Turn it into an indicator;
					if &type._enr_da_(i)>0 then &type._enr_da_(i)=1;
end;

%mend;

%macro Create_edu_interv_pop;
proc format;
	value interv_grp
		5='ESOL'
		6,17='AlTED'
		7='SUSP'
		8='STAND'
		9='TRUENR'
		32='TRUATT'
		12,26,29,24,25,27,28,30='SEDU'
		10='EARLEX'
		11='HOMESCH'
		13,14='BOARD'
		16='RR'
		31='RTLB'
		33='HEALTH'
		34='GWAY'
		35='SECTER'
		37='IRF';
run;

proc sql;
	create table interventions as select 
		a.snz_uid
		,input(compress(moe_inv_start_date,"-"),yymmdd10.) format date9. as startdate
		,input(compress(moe_inv_end_date,"-"),yymmdd10.) format date9. as enddate
		,input(compress(moe_inv_extrtn_date,"-"),yymmdd10.) format date9. as extractiondate
		,put(input(a.moe_inv_intrvtn_code,3.),interv_grp.) as interv_grp
		,b.DOB 
	from moe.student_interventions a inner join pop_&year._0024_serv b 
		on a.snz_uid=b.snz_uid
	order by b.snz_uid;
quit;

data interventions;
	set interventions;
	if enddate='31Dec9999'd then
		enddate=Extractiondate;
	if enddate=. then
		enddate=ExtractionDate;
	if enddate>=startdate;
	* cleaning for errorness records;
	if startdate>"31dec&year."d then
		delete;
	if enddate>"31dec&year."d then
		enddate="31dec&year."d;
run;


* Spliting dataset by each intervention type;
%macro interv(interv);
	data &interv;
		set interventions;
		if interv_grp="&interv.";
		keep snz_uid DOB interv_grp startDate enddate;
	run;
%mend;

%interv(AlTED);
%interv(SUSP);
%interv(STAND);
%interv(TRUENR);
%interv(TRUATT);
%interv(SEDU);
%interv(ESOL);
%interv(EARLEX);
%interv(HOMESCH);
%interv(BOARD);
%interv(RR);
%interv(RTLB);
%interv(HEALTH);
%interv(GWAY);
%interv(SECTER);
%interv(IRF);

* checking for overlap;
%overlap(AlTED);
%overlap(SUSP);
%overlap(STAND);
%overlap(TRUENR);
%overlap(TRUATT);
%overlap(SEDU);
%overlap(ESOL);
%overlap(EARLEX);
%overlap(HOMESCH);
%overlap(BOARD);
%overlap(RR);
%overlap(RTLB);
%overlap(HEALTH);
%overlap(GWAY);
%overlap(SECTER);
%overlap(IRF);

*Creating final long file;
%macro interv_year_age(interv);
data &interv._OR; set &interv._OR;
start1=MDY(1,1,&first_anal_yr.); format start1 date9.;

do ind=&first_anal_yr. to &last_anal_yr.;
			i=ind-(&first_anal_yr.-1);

			start_window=intnx('YEAR',start1,i-1,'S');
			end_window=intnx('YEAR',start1,i,'S')-1;

			%enr_yr(&interv.);

end;

proc summary data=&interv._OR nway;
class snz_uid DOB;
var &interv._enr_da_&first_anal_yr.-&interv._enr_da_&last_anal_yr.;
output out=&interv._temp1(drop=_:) sum=;
run;
%mend;

%interv_year_age(AlTED);
%interv_year_age(SUSP);
%interv_year_age(STAND);
%interv_year_age(TRUENR);
%interv_year_age(TRUATT);
%interv_year_age(SEDU);
%interv_year_age(ESOL);
%interv_year_age(EARLEX);
%interv_year_age(HOMESCH);
%interv_year_age(BOARD);
%interv_year_age(RR);
%interv_year_age(RTLB);
%interv_year_age(HEALTH);
%interv_year_age(GWAY);
%interv_year_age(SECTER);
%interv_year_age(IRF);

data pop_&year._0024_servb; merge 
pop_&year._0024_serv
AlTED_TEMP1
SUSP_TEMP1
STAND_TEMP1
TRUATT_TEMP1
TRUENR_TEMP1
SEDU_TEMP1
ESOL_TEMP1
EARLEX_TEMP1
HOMESCH_TEMP1
BOARD_TEMP1
RR_TEMP1
RTLB_TEMP1
HEALTH_TEMP1
GWAY_TEMP1
SECTER_TEMP1
IRF_TEMP1;
by snz_uid;run;

proc datasets lib=work;
delete AlTED:
SUSP:
STAND:
TRUATT:
TRUENR:
SEDU:
ESOL:
EARLEX:
HOMESCH:
BOARD:
RR:
RTLB:
HEALTH:
GWAY:
SECTER:
IRF:
INTERVENTIONS
DELETES ;
run;

%mend;
%let first_anal_yr=%eval(&year.-4);
%let last_anal_yr=&year.;
%Create_edu_interv_pop;

proc means data=pop_&year._0024_servb sum;
run;

data pop_&year._0024_servd(keep=snz_uid edu_:);
	set pop_&year._0024_servb;
	if 	AlTED_enr_da_&year.>0 then edu_alt_1yr=1;
	else edu_alt_1yr=0;
	if sum(of AlTED_enr_da_%eval(&year.-4)-AlTED_enr_da_&year.)>0 then edu_alt_5yr=1;
	else edu_alt_5yr=0;
	if 	TRUATT_enr_da_&year.>0 then edu_truatt_1yr=1;
	else edu_truatt_1yr=0;
	if sum(of TRUATT_enr_da_%eval(&year.-4)-TRUATT_enr_da_&year.)>0 then edu_truatt_5yr=1;
	else edu_truatt_5yr=0;
	if 	TRUENR_enr_da_&year.>0 then edu_truenr_1yr=1;
	else edu_truenr_1yr=0;
	if sum(of TRUENR_enr_da_%eval(&year.-4)-TRUENR_enr_da_&year.)>0 then edu_truenr_5yr=1;
	else edu_truenr_5yr=0;
	if 	SEDU_enr_da_&year.>0 then edu_sed_1yr=1;
	else edu_sed_1yr=0;
	if sum(of SEDU_enr_da_%eval(&year.-4)-SEDU_enr_da_&year.)>0 then edu_sed_5yr=1;
	else edu_sed_5yr=0;
	if 	ESOL_enr_da_&year.>0 then edu_esol_1yr=1;
	else edu_esol_1yr=0;
	if sum(of ESOL_enr_da_%eval(&year.-4)-ESOL_enr_da_&year.)>0 then edu_esol_5yr=1;
	else edu_esol_5yr=0;
	if 	HEALTH_enr_da_&year.>0 then edu_hlth_1yr=1;
	else edu_hlth_1yr=0;
	if sum(of HEALTH_enr_da_%eval(&year.-4)-HEALTH_enr_da_&year.)>0 then edu_hlth_5yr=1;
	else edu_hlth_5yr=0;
	if 	gway_enr_da_&year.>0 then edu_gway_1yr=1;
	else edu_gway_1yr=0;
	if sum(of gway_enr_da_%eval(&year.-4)-gway_enr_da_&year.)>0 then edu_gway_5yr=1;
	else edu_gway_5yr=0;
	if 	SECTER_enr_da_&year.>0 then edu_ster_1yr=1;
	else edu_ster_1yr=0;
	if sum(of SECTER_enr_da_%eval(&year.-4)-SECTER_enr_da_&year.)>0 then edu_ster_5yr=1;
	else edu_ster_5yr=0;
	if 	IRF_enr_da_&year.>0 then edu_irf_1yr=1;
	else edu_irf_1yr=0;
	if sum(of IRF_enr_da_%eval(&year.-4)-IRF_enr_da_&year.)>0 then edu_irf_5yr=1;
	else edu_irf_5yr=0;
	if 	HOMESCH_enr_da_&year.>0 then edu_home_1yr=1;
	else edu_home_1yr=0;
	if sum(of HOMESCH_enr_da_%eval(&year.-4)-HOMESCH_enr_da_&year.)>0 then edu_home_5yr=1;
	else edu_home_5yr=0;
	if 	RR_enr_da_&year.>0 then edu_rr_1yr=1;
	else edu_rr_1yr=0;
	if sum(of RR_enr_da_%eval(&year.-4)-RR_enr_da_&year.)>0 then edu_rr_5yr=1;
	else edu_rr_5yr=0;
	if 	RTLB_enr_da_&year.>0 then edu_rtlb_1yr=1;
	else edu_rtlb_1yr=0;
	if sum(of RTLB_enr_da_%eval(&year.-4)-RTLB_enr_da_&year.)>0 then edu_rtlb_5yr=1;
	else edu_rtlb_5yr=0;
run;

** Now we want to add in Tertiary interventions - specifically Youth guarantee fees free / Industry training / Targeted training;

** Industry training;
**Industry training qualifications;
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
    endyr=year(enddate);
	if startdate>enddate then
		output deletes;
	else output it;
run;

data it_years(keep=snz_uid it_:);
	set it(keep=snz_uid startyr endyr);
	by snz_uid;
	retain it_2009-it_2015;
	array it_yr{*} it_2009-it_2015;
	where startyr <= 2015 and endyr >= 2009;
	do y=1 to 7;
		if first.snz_uid then it_yr{y}=0;
		if startyr <= y+2008 and endyr >= y+2008 then it_yr{y}=1;
	end;
	if last.snz_uid then output;
run;

** And now targeted training;
data tt(rename=(moe_ttr_year_nbr=year moe_ttr_training_prog_code=programme));
	set moe.targeted_training(keep=snz_uid moe_ttr_year_nbr moe_ttr_training_prog_code);
	where 2009 le moe_ttr_year_nbr le 2015;
run;

proc sort data=tt nodup;
	by snz_uid;
run;

data tt_years(drop=programme year y);
	set tt;
	by snz_uid;
	retain gway2_2009-gway2_2015 top_2009-top_2015 ygff2_2009-ygff2_2015 ytrain_2009-ytrain_2015;
	array gway2_yr{*} gway2_2009-gway2_2015;
	array top_yr{*} top_2009-top_2015;
	array ygff2_yr{*} ygff2_2009-ygff2_2015;
	array ytrain_yr{*} ytrain_2009-ytrain_2015;
	do y=1 to 7;
		if first.snz_uid then do; gway2_yr{y}=0; top_yr{y}=0; ygff2_yr{y}=0; ytrain_yr{y}=0; end;
		if programme='GATEW' and year=y+2008 then gway2_yr{y}=1;
		if programme='TOP' and year=y+2008 then top_yr{y}=1;
		if programme='YGTH' and year=y+2008 then ygff2_yr{y}=1;
		if programme='YOUTH' and year=y+2008 then ytrain_yr{y}=1;
	end;
	if last.snz_uid then output;
run;

** And check secondary-tertiary programme data - this is much smaller than through the education interventions data - why?;
data sectert(rename=(moe_stp_enrolment_yr_nbr=year));
	set moe.secondary_tertiary_prog(keep=snz_uid moe_stp_enrolment_yr_nbr);
	where 2009 le moe_stp_enrolment_yr_nbr le 2015;
run;

proc sort data=sectert nodup;
	by snz_uid;
run;

data st_years(keep=snz_uid st_:);
	set sectert;
	by snz_uid;
	retain st_2009-st_2015;
	array st_yr{*} st_2009-st_2015;
	do y=1 to 7;
		if first.snz_uid then st_yr{y}=0;
		if year = y+2008 then st_yr{y}=1;
	end;
	if last.snz_uid then output;
run;

proc freq data=st_years;
	tables st_:;
run;

** And now Youth Guarantee Fees Free;
proc sql;
	create table ygff as
		SELECT distinct 
			snz_uid
			,year(input(moe_enr_prog_start_date,yymmdd10.)) as startyr
			,year(input(moe_enr_prog_end_date,yymmdd10.)) as endyr 
			,moe_enr_efts_consumed_nbr as EFTS_consumed
			,moe_enr_funding_srce_code as fund_source
			,moe_enr_qual_level_code as level_nbr
			,moe_enr_qual_type_code as qual_type
		FROM moe.enrolment 
		WHERE 	fund_source='22' and moe_enr_efts_consumed_nbr>0 and moe_enr_qual_type_code="D" and
				year(input(moe_enr_prog_start_date,yymmdd10.))<=2015 and
				year(input(moe_enr_prog_end_date,yymmdd10.))>=2009 
		order by snz_uid;
quit;

data ygff_years(keep=snz_uid ygff_:);
	set ygff(keep=snz_uid startyr endyr);
	by snz_uid;
	retain ygff_2009-ygff_2015;
	array ygff_yr{*} ygff_2009-ygff_2015;
	where startyr <= 2015 and endyr >= 2009;
	do y=1 to 7;
		if first.snz_uid then ygff_yr{y}=0;
		if startyr <= y+2008 and endyr >= y+2008 then ygff_yr{y}=1;
	end;
	if last.snz_uid then output;
run;

** And Student Allowances;
proc sql;
	Connect to sqlservr (server=WPRDSQL36\iLeed database=IDI_clean_&version.);
	create table sal as 

	SELECT distinct 
		snz_uid AS snz_uid,
		inc_cal_yr_year_nbr AS year,
		inc_cal_yr_income_source_code AS income_source_code,
		sum(inc_cal_yr_tot_yr_amt) AS gross_earnings_amt

	FROM data.income_cal_yr
	WHERE 2009 <= inc_cal_yr_year_nbr <= 2015 
		and  snz_ird_uid <> 0  
	and inc_cal_yr_income_source_code in ('STU')
	GROUP BY snz_uid, inc_cal_yr_year_nbr , inc_cal_yr_income_source_code
		ORDER BY snz_uid, inc_cal_yr_year_nbr , inc_cal_yr_income_source_code 
	;
quit;

data sal_years(keep=snz_uid sal_:);
	set sal;
	by snz_uid;
	retain sal_2009-sal_2015;
	array sal_yr{*} sal_2009-sal_2015;
	do y=1 to 7;
		if first.snz_uid then sal_yr{y}=0;
		if year = y+2008 then sal_yr{y}=1;
	end;
	if last.snz_uid then output;
run;

data pop_&year._0024_serve(keep=snz_uid edu_:);
	merge pop_&year._0024_servd(in=a) it_years tt_years ygff_years st_years sal_years;
	by snz_uid;
	if a;
	if 	it_&year.=1 then edu_it_1yr=1;
	else edu_it_1yr=0;
	if sum(of it_%eval(&year.-4)-it_&year.)>0 then edu_it_5yr=1;
	else edu_it_5yr=0;
	if 	ygff_&year.=1 then edu_ygff_1yr=1;
	else edu_ygff_1yr=0;
	if sum(of ygff_%eval(&year.-4)-ygff_&year.)>0 then edu_ygff_5yr=1;
	else edu_ygff_5yr=0;
	if 	st_&year.=1 then edu_st_1yr=1;
	else edu_st_1yr=0;
	if sum(of st_%eval(&year.-4)-st_&year.)>0 then edu_st_5yr=1;
	else edu_st_5yr=0;
	if 	gway2_&year.=1 then edu_gway2_1yr=1;
	else edu_gway2_1yr=0;
	if sum(of gway2_%eval(&year.-4)-gway2_&year.)>0 then edu_gway2_5yr=1;
	else edu_gway2_5yr=0;
	if 	sal_&year.=1 then edu_sal_1yr=1;
	else edu_sal_1yr=0;
	if sum(of sal_%eval(&year.-4)-sal_&year.)>0 then edu_sal_5yr=1;
	else edu_sal_5yr=0;
	if 	top_&year.=1 then edu_top_1yr=1;
	else edu_top_1yr=0;
	if sum(of top_%eval(&year.-4)-top_&year.)>0 then edu_top_5yr=1;
	else edu_top_5yr=0;
	if 	ygff2_&year.=1 then edu_ygff2_1yr=1;
	else edu_ygff2_1yr=0;
	if sum(of ygff2_%eval(&year.-4)-ygff2_&year.)>0 then edu_ygff2_5yr=1;
	else edu_ygff2_5yr=0;
	if 	ytrain_&year.=1 then edu_ytrain_1yr=1;
	else edu_ytrain_1yr=0;
	if sum(of ytrain_%eval(&year.-4)-ytrain_&year.)>0 then edu_ytrain_5yr=1;
	else edu_ytrain_5yr=0;
run;

** Look at school types;
data schools;
	merge pop_&year._0024_serv(in=a keep=snz_uid) inputlib._IND_SCH_ATTENDED_20161021;
	by snz_uid;
	if a;
run;

proc format;
	value insttype
		10000	=	'Casual-Education and Care'
		10001	=	'Free Kindergarten'
		10002	=	'Playcentre'
		10003	=	'Education & Care Service'
		10004	=	'Homebased Network'
		10005	=	'Te Kohanga Reo'
		10007	=	'Licence Exempt Kohanga Reo'
		10008	=	'Hospitalbased'
		10009	=	'Playgroup'
		10010	=	'Private Training Establishment'
		10011	=	'Government Training Establishment'
		10012	=	'Polytechnic'
		10013	=	'College of Education'
		10014	=	'University'
		10015	=	'Wananga'
		10016	=	'Other Tertiary Education Provider'
		10017	=	'Industry Training Organisation'
		10018	=	'Other Certifying Authorities'
		10019	=	'OTEP Resource Centre'
		10020	=	'OTEP RS24(Completes RS24)'
		10021	=	'Government Agency'
		10022	=	'Peak Body'
		10023	=	'Full Primary (Year 1-8)'
		10024	=	'Contributing (Year 1-6)'
		10025	=	'Intermediate (Year 7 & 8)'
		10026	=	'Special School'
		10027	=	'Centre for Extra Support'
		10028	=	'Correspondence Unit'
		10029	=	'Secondary (Year 7-15)'
		10030	=	'Composite (Year 1-15)'
		10031	=	'Correspondence School'
		10032	=	'Restricted Composite (Year 7-10)'
		10033	=	'Secondary (Year 9-15)'
		10034	=	'Teen Parent Unit'
		10035	=	'Alternative Education Provider'
		10036	=	'Activity Centre'
		10037	=	'Kura Teina - Primary'
		10038	=	'Side-school'
		10039	=	'Special Unit'
		10040	=	'Kura Teina - Composite'
		10041	=	'Land Site'
		10042	=	'Manual Training Centre (stand alone)'
		10043	=	'Community Education/Resource/Youth Learning Centre'
		10044	=	'Rural Education Activities Programme (REAP)'
		10045	=	'Special Education Service Centre'
		10047	=	'Examination Centre'
		10048	=	'School cluster (for NZQA)'
		10049	=	'School Camp'
		10050	=	'Subsidiary Provider'
		10051	=	'Miscellaneous'
		10052	=	'Kindergarten Association'
		10053	=	'Playcentre Association'
		10054	=	'Commercial ECE Service Provider'
		10055	=	'Other ECE Service Provider'
		10056	=	'Board of Trustees'
		10057	=	'Private School Provider'
		10058	=	'Campus'
		10059	=	'Local Office'
		10060	=	'Special Unit Funded';
	value authority
		42000='State'
		42001='StateIntegrated'
		42002,42003='Private'
		42004,42010,42011,42012='Other'
		42005='Public Tertiary Institution'
		42006='Privately Owned Tertiary Institution'
		42007='Tertiary prov est under own Act of Parliament'
		42008='Tertiary inst owned by a Trust'
		42009='Tertiary inst owned by an Incorporated Society';
run;

data all_schools(drop=SchoolAuthorityID schooltypeid);
	set sandmoe.moe_school_profile(keep=schoolnumber SchoolAuthorityID schooltypeid);
	schooltype=put(schooltypeid,insttype.);
	schoolauthority=put(SchoolAuthorityID,authority.);
run;

proc sql;
	create table school_type as
	select a.*, b.schooltype as schooltype2006, 
				c.schooltype as schooltype2007, 
				d.schooltype as schooltype2008, 
				e.schooltype as schooltype2009, 
				f.schooltype as schooltype2010, 
				g.schooltype as schooltype2011, 
				h.schooltype as schooltype2012, 
				i.schooltype as schooltype2013, 
				j.schooltype as schooltype2014, 
				k.schooltype as schooltype2015
	from schools(drop=non:) a
	left join all_schools b on a.school_in_2006=b.schoolnumber
	left join all_schools c on a.school_in_2007=c.schoolnumber
	left join all_schools d on a.school_in_2008=d.schoolnumber
	left join all_schools e on a.school_in_2009=e.schoolnumber
	left join all_schools f on a.school_in_2010=f.schoolnumber
	left join all_schools g on a.school_in_2011=g.schoolnumber
	left join all_schools h on a.school_in_2012=h.schoolnumber
	left join all_schools i on a.school_in_2013=i.schoolnumber
	left join all_schools j on a.school_in_2014=j.schoolnumber
	left join all_schools k on a.school_in_2015=k.schoolnumber
	order by snz_uid;
quit;

data pop_&year._0024_serv_edu(keep=snz_uid edu_:);
	merge pop_&year._0024_serve school_type;
	by snz_uid;
	if schooltype&year.='Correspondence School' then edu_corr_1yr=1;
	else edu_corr_1yr=0;
	if substr(schooltype&year.,1,7)='Special' then edu_sed2_1yr=1;
	else edu_sed2_1yr=0;
	if schooltype&year.='Correspondence School' or schooltype%eval(&year.-1)='Correspondence School' or schooltype%eval(&year.-2)='Correspondence School' or schooltype%eval(&year.-3)='Correspondence School' or schooltype%eval(&year.-4)='Correspondence School' then edu_corr_5yr=1;
	else edu_corr_5yr=0;
	if substr(schooltype&year.,1,7)='Special' or substr(schooltype%eval(&year.-1),1,7)='Special' or substr(schooltype%eval(&year.-2),1,7)='Special' or substr(schooltype%eval(&year.-3),1,7)='Special' or substr(schooltype%eval(&year.-4),1,7)='Special' then edu_sed2_5yr=1;
	else edu_sed2_5yr=0;
	** Use the secondary-tertiary and gateway data from the direct sources, not from the schools interventions data;
	edu_ster_1yr=edu_st_1yr;
	edu_ster_5yr=edu_st_5yr;
	edu_gway_1yr=edu_gway2_1yr;
	edu_gway_5yr=edu_gway2_5yr;
	drop edu_gway2: edu_st_:;
	** Use the targeted training youth guarantee fees free code to supplement the enrolment-based YGFF data (this only affects 2012);
	if edu_ygff2_1yr=1 then edu_ygff_1yr=1;
	if edu_ygff2_5yr=1 then edu_ygff_5yr=1;
	drop edu_ygff2:;
run;

data project.pop_&year._0024_service;
	merge project.risk_factors_&year._0_14(in=a) project.risk_factors_&year._15_19(in=a) project.risk_factors_&year._20_24(in=a) pop_&year._0024_serv_emp pop_&year._0024_serv_edu project.yt_&year._tab_yt_outcomes_tool(keep=snz_uid risk_factors_by15 pp_sch pp_ter pp1_ben rename=(risk_factors_by15=risk_factors_&year.));
	by snz_uid;
	if a;
	if age_desc in ('15-19') and (pp_sch>0 or pp_ter>0) then schter_1519=1;
	else schter_1519=0;
	if age_desc in ('15-19','20-24') and pp1_ben>0 then ben_1524=1;
	else ben_1524=0;
	if risk_factors_&year.>=2 then risk_factors_2plus_&year.=1;
	else risk_factors_2plus_&year.=0;
run;

proc tabulate data=project.pop_&year._0024_service missing;
	class risk_factors_2plus_&year. age_desc schter_1519;
	var edu:;
	where age_desc in ('06-14','15-19');
	*tables (edu:)*age_desc*schter_1519,risk_factors_2plus_&year.*(N SUM)/NOCELLMERGE;
	tables (edu:),SUM/NOCELLMERGE;
run;
proc tabulate data=project.pop_&year._0024_service missing;
	class risk_factors_2plus_&year. age_desc ben_1524;
	var emp:;
	where age_desc in ('15-19','20-24');
	*tables (emp:)*age_desc*ben_1524,risk_factors_2plus_&year.*(N SUM)/NOCELLMERGE;
	tables (emp:),SUM/NOCELLMERGE;
run;
%mend create_service_date;

%create_service_date(2013);
%create_service_date(2014);
%create_service_date(2015);

