******************************************************************************************************************************************************
Macro that applies business rules to calclate counts of CYF notifcations

* this is expected to be called in a datastep where a dataset of CYF/YJ events
* are being processed. Can be events relating to the individual themselves
* or it might be relating to other people (eg their siblings/caregivers) ;

* creates counts of CYF notifications, police FV notifications and YJ referrals;
* for an interval  starting at dateofbirth + st years;
*                  ending at dateofbirth + end years;

* prefix - is the first word in the name of the variables created;
*          can be anything but we use child = for reference child  
*          or othchild = sibling;  
* suffix - is the last part of the name of variables created;
*          can be anything but at_age, or by_age or at_birth are 
*          what was expected ;  
******************************************************************************************************************************************************;

%macro CYF_notifications(ref_id,dateofbirth,st,end,prefix,suffix);

  			if first.&ref_id. then do;

			                        &prefix._not_&suffix. =0;
			                        &prefix._Pol_FV_not_&suffix. =0;
			                      	&prefix._YJ_referral_&suffix. =0;

			end;

			if Business_Area in ('CNP','UNK') and 
			intnx('YEAR',&dateofbirth., &st.,'sameday') lt 
             startdate le intnx('YEAR',&dateofbirth., &end.,'sameday') then do;
                       if NOTIFIER_ROLE_GROUP	 not in ('PFV') then do;
			                      &prefix._not_&suffix. + 1;
			                                end;
			end;

			if Business_Area in ('CNP','UNK') and 
           intnx('YEAR',&dateofbirth., &st.,'sameday') lt startdate le
                     intnx('YEAR',&dateofbirth., &end.,'sameday') then do;

			                        if NOTIFIER_ROLE_GROUP	 in ('PFV') then do;
			                                &prefix._Pol_FV_not_&suffix. + 1;
			                        end;
			end;

			if Business_Area in ('YJU') and 
         intnx('YEAR',&dateofbirth., &st.,'sameday') lt startdate 
           le intnx('YEAR',&dateofbirth., &end.,'sameday') then do;
								&prefix._YJ_referral_&suffix.+1;
			end;

%mend;

******************************************************************************************************************************************************
******************************************************************************************************************************************************;

%macro cyf_findings(ref_id,dateofbirth,st,end,prefix,suffix);

                if first.&ref_id. then do;

                        &prefix._fdgs_neglect_&suffix.=0;
                        &prefix._fdgs_phys_abuse_&suffix.=0;
                        &prefix._fdgs_sex_abuse_&suffix.=0;
                        &prefix._fdgs_emot_abuse_&suffix.=0;
                        &prefix._fdgs_behav_rel_&suffix.=0;
						&prefix._fdgs_sh_suic_&suffix.=0;
						&prefix._any_fdgs_abuse_&suffix.=0;
                end;

                if intnx('YEAR',&dateofbirth., &st.,'sameday') 
                   lt finding_date le intnx('YEAR',&dateofbirth., &end.,'sameday') 
          then do;

                        if abuse_type='BRD' then do;
                                &prefix._fdgs_behav_rel_&suffix. + 1;
                        end;
                        if abuse_type='EMO' then do;
                                &prefix._fdgs_emot_abuse_&suffix. + 1;
                        end;
                        if abuse_type='NEG' then do;
                                &prefix._fdgs_neglect_&suffix. + 1;
                        end;
                        if abuse_type='PHY' then do;
                                &prefix._fdgs_phys_abuse_&suffix. + 1;
                        end;
                        if abuse_type='SEX' then do;
                                &prefix._fdgs_sex_abuse_&suffix. + 1;
                        end;
						if abuse_type in ('SHS', 'SHM','SUC') then do;
                                &prefix._fdgs_sh_suic_&suffix. + 1;
                        end;
						if abuse_type in ('EMO','NEG','PHY','SEX') then do;
                                &prefix._any_fdgs_abuse_&suffix. + 1;
                        end;

                end;
%mend;
******************************************************************************************************************************************************
******************************************************************************************************************************************************;

%macro cyf_placements(ref_id,dateofbirth,st,end,prefix,suffix);

			if first.&ref_id. then do;

			                        &prefix._CYF_place_&suffix.=0;
									&prefix._YJ_place_&suffix.=0;


			end;

			if intnx('YEAR',&dateofbirth., &st.,'sameday') lt 
startdate le intnx('YEAR',&dateofbirth.,&end.,'sameday') 
 and business_area in('CNP','UNK') then do;

			                      &prefix._CYF_place_&suffix. + 1;
			                                
			end;
						if intnx('YEAR',&dateofbirth., &st.,'sameday') 
lt startdate le intnx('YEAR',&dateofbirth., &end.,'sameday') 
 and business_area='YJU' then do;

			                      &prefix._YJ_place_&suffix. + 1;
			                                
			end;

%mend;
******************************************************************************************************************************************************
	* this is expected to be called in a datastep where a dataset of CYF/YJ events
	* are being processed. Can be events relating to the individual themselves
	* or it might be relating to other people (eg their siblings/caregivers);

	* creates counts of CYF notifications, police FV notifications and YJ referrals;
	* for an interval  starting at dateofbirth + st years;
	*                  ending at dateofbirth + end years;
	* prefix - is the first word in the name of the variables created;

	*          can be anything but we use child = for reference child  
	*          or othchild = sibling;

	* suffix - is the last part of the name of variables created;

	*          can be anything but at_age, or by_age or at_birth are 
	*          what was expected;
******************************************************************************************************************************************************;

%macro FGC_FWA_count(ref_id, dateofbirth, st, end, prefix, suffix);

	if first.&ref_id. then
		do;
			&prefix._CYF_FGC_&suffix. = 0;
			&prefix._CYF_FWA_&suffix. = 0;
			&prefix._YJ_FGC_&suffix. = 0;
		end;

	if business_area_type_code in ('CNP','UNK') and intervention = 'FGC' and
		intnx('YEAR',&dateofbirth., &st.,'sameday') lt 
		startdate le intnx('YEAR', &dateofbirth., &end.,'sameday') then
			&prefix._CYF_FGC_&suffix. + 1;

	if business_area_type_code in ('CNP','UNK') and intervention = 'FWA' and
		intnx('YEAR',&dateofbirth., &st.,'sameday') lt 
		startdate le intnx('YEAR', &dateofbirth., &end.,'sameday') then
			&prefix._CYF_FWA_&suffix. + 1;

	if business_area_type_code in ('YJU')and intervention = 'FGC' and 
		intnx('YEAR',&dateofbirth., &st.,'sameday') lt startdate 
		le intnx('YEAR',&dateofbirth., &end.,'sameday') then
			&prefix._YJ_FGC_&suffix.+1;

%mend FGC_FWA_count;

******************************************************************************************************************************************************
******************************************************************************************************************************************************;
	* this is expected to be called in a datastep where a dataset of CYF/YJ events
	* are being processed. Can be events relating to the individual themselves
	* or it might be relating to other people (eg their siblings/caregivers);

	* creates counts of CYF and YJ care episodes;
	* for an interval  starting at dateofbirth + st years;
	*                  ending at dateofbirth + end years;
	* prefix - is the first word in the name of the variables created;

	*          can be anything but we use child = for reference child  
	*          or othchild = sibling;

	* suffix - is the last part of the name of variables created;

	*          can be anything but at_age, or by_age or at_birth are 
	*          what was expected;

%macro Care_episodes(ref_id, dateofbirth, st, end, prefix, suffix);
	if first.&ref_id. then do;
			&prefix._CYF_ce_&suffix. = 0;
			&prefix._YJ_ce_&suffix. = 0;

	end;

if grp='CYF' and intnx('YEAR',&dateofbirth., &st.,'sameday') lt startdate le intnx('YEAR', &dateofbirth., &end.,'sameday') 
and event_duration ge 28 then do;
&prefix._CYF_ce_&suffix. + 1;
end;

if grp='YJ' and intnx('YEAR',&dateofbirth., &st.,'sameday') lt startdate le intnx('YEAR', &dateofbirth., &end.,'sameday') 
then do;
&prefix._YJ_ce_&suffix. + 1;
end;
%mend ;



%macro CYF_notifications_mth(ref_id,dateofbirth,st,end,prefix,suffix);

  			if first.&ref_id. then do;

			                        &prefix._not_&suffix. =0;
			                        &prefix._Pol_FV_not_&suffix. =0;
			                      	&prefix._YJ_referral_&suffix. =0;

			end;

			if Business_Area in ('CNP','UNK') and 
			intnx('MONTH',&dateofbirth., &st.,'sameday') lt 
             startdate le intnx('MONTH',&dateofbirth., &end.,'sameday') then do;
                       if NOTIFIER_ROLE_GROUP	 not in ('PFV') then do;
			                      &prefix._not_&suffix. + 1;
			                                end;
			end;

			if Business_Area in ('CNP','UNK') and 
           intnx('MONTH',&dateofbirth., &st.,'sameday') lt startdate le
                     intnx('MONTH',&dateofbirth., &end.,'sameday') then do;

			                        if NOTIFIER_ROLE_GROUP	 in ('PFV') then do;
			                                &prefix._Pol_FV_not_&suffix. + 1;
			                        end;
			end;

			if Business_Area in ('YJU') and 
         intnx('MONTH',&dateofbirth., &st.,'sameday') lt startdate 
           le intnx('MONTH',&dateofbirth., &end.,'sameday') then do;
								&prefix._YJ_referral_&suffix.+1;
			end;

%mend;

******************************************************************************************************************************************************
******************************************************************************************************************************************************;

%macro cyf_findings_mth(ref_id,dateofbirth,st,end,prefix,suffix);

                if first.&ref_id. then do;

                        &prefix._fdgs_neglect_&suffix.=0;
                        &prefix._fdgs_phys_abuse_&suffix.=0;
                        &prefix._fdgs_sex_abuse_&suffix.=0;
                        &prefix._fdgs_emot_abuse_&suffix.=0;
                        &prefix._fdgs_behav_rel_&suffix.=0;
						&prefix._fdgs_sh_suic_&suffix.=0;
						&prefix._any_fdgs_abuse_&suffix.=0;
                end;

                if intnx('MONTH',&dateofbirth., &st.,'sameday') 
                   lt finding_date le intnx('MONTH',&dateofbirth., &end.,'sameday') 
          then do;

                        if abuse_type='BRD' then do;
                                &prefix._fdgs_behav_rel_&suffix. + 1;
                        end;
                        if abuse_type='EMO' then do;
                                &prefix._fdgs_emot_abuse_&suffix. + 1;
                        end;
                        if abuse_type='NEG' then do;
                                &prefix._fdgs_neglect_&suffix. + 1;
                        end;
                        if abuse_type='PHY' then do;
                                &prefix._fdgs_phys_abuse_&suffix. + 1;
                        end;
                        if abuse_type='SEX' then do;
                                &prefix._fdgs_sex_abuse_&suffix. + 1;
                        end;
						if abuse_type in ('SHS', 'SHM','SUC') then do;
                                &prefix._fdgs_sh_suic_&suffix. + 1;
                        end;
						if abuse_type in ('EMO','NEG','PHY','SEX') then do;
                                &prefix._any_fdgs_abuse_&suffix. + 1;
                        end;

                end;
%mend;
******************************************************************************************************************************************************
******************************************************************************************************************************************************;

%macro cyf_placements_mth(ref_id,dateofbirth,st,end,prefix,suffix);

			if first.&ref_id. then do;

			                        &prefix._CYF_place_&suffix.=0;
									&prefix._YJ_place_&suffix.=0;


			end;

			if intnx('MONTH',&dateofbirth., &st.,'sameday') lt 
startdate le intnx('MONTH',&dateofbirth.,&end.,'sameday') 
 and business_area in('CNP','UNK') then do;

			                      &prefix._CYF_place_&suffix. + 1;
			                                
			end;
						if intnx('MONTH',&dateofbirth., &st.,'sameday') 
lt startdate le intnx('MONTH',&dateofbirth., &end.,'sameday') 
 and business_area='YJU' then do;

			                      &prefix._YJ_place_&suffix. + 1;
			                                
			end;

%mend;
******************************************************************************************************************************************************
	* this is expected to be called in a datastep where a dataset of CYF/YJ events
	* are being processed. Can be events relating to the individual themselves
	* or it might be relating to other people (eg their siblings/caregivers);

	* creates counts of CYF notifications, police FV notifications and YJ referrals;
	* for an interval  starting at dateofbirth + st MONTHs;
	*                  ending at dateofbirth + end MONTHs;
	* prefix - is the first word in the name of the variables created;

	*          can be anything but we use child = for reference child  
	*          or othchild = sibling;

	* suffix - is the last part of the name of variables created;

	*          can be anything but at_age, or by_age or at_birth are 
	*          what was expected;
******************************************************************************************************************************************************;

%macro FGC_FWA_count_mth(ref_id, dateofbirth, st, end, prefix, suffix);

	if first.&ref_id. then
		do;
			&prefix._CYF_FGC_&suffix. = 0;
			&prefix._CYF_FWA_&suffix. = 0;
			&prefix._YJ_FGC_&suffix. = 0;
		end;

	if business_area_type_code in ('CNP','UNK') and intervention = 'FGC' and
		intnx('MONTH',&dateofbirth., &st.,'sameday') lt 
		startdate le intnx('MONTH', &dateofbirth., &end.,'sameday') then
			&prefix._CYF_FGC_&suffix. + 1;

	if business_area_type_code in ('CNP','UNK') and intervention = 'FWA' and
		intnx('MONTH',&dateofbirth., &st.,'sameday') lt 
		startdate le intnx('MONTH', &dateofbirth., &end.,'sameday') then
			&prefix._CYF_FWA_&suffix. + 1;

	if business_area_type_code in ('YJU')and intervention = 'FGC' and 
		intnx('MONTH',&dateofbirth., &st.,'sameday') lt startdate 
		le intnx('MONTH',&dateofbirth., &end.,'sameday') then
			&prefix._YJ_FGC_&suffix.+1;

%mend;

******************************************************************************************************************************************************
******************************************************************************************************************************************************;
	* this is expected to be called in a datastep where a dataset of CYF/YJ events
	* are being processed. Can be events relating to the individual themselves
	* or it might be relating to other people (eg their siblings/caregivers);

	* creates counts of CYF and YJ care episodes;
	* for an interval  starting at dateofbirth + st MONTHs;
	*                  ending at dateofbirth + end MONTHs;
	* prefix - is the first word in the name of the variables created;

	*          can be anything but we use child = for reference child  
	*          or othchild = sibling;

	* suffix - is the last part of the name of variables created;

	*          can be anything but at_age, or by_age or at_birth are 
	*          what was expected;

%macro Care_episodes_mth(ref_id, dateofbirth, st, end, prefix, suffix);
	if first.&ref_id. then do;
			&prefix._CYF_ce_&suffix. = 0;
			&prefix._YJ_ce_&suffix. = 0;

	end;

if grp='CYF' and intnx('MONTH',&dateofbirth., &st.,'sameday') lt startdate le intnx('MONTH', &dateofbirth., &end.,'sameday') 
and event_duration ge 28 then do;
&prefix._CYF_ce_&suffix. + 1;
end;

if grp='YJ' and intnx('MONTH',&dateofbirth., &st.,'sameday') lt startdate le intnx('MONTH', &dateofbirth., &end.,'sameday') 
then do;
&prefix._YJ_ce_&suffix. + 1;
end;
%mend ;


***********************************************************************************************************************************************************
Creates 4 CYF clean tables
***********************************************************************************************************************************************************;


%macro Create_clean_CYF_tables;
proc sql;
create table CYF_intake as select 
	snz_uid,
	snz_composite_event_uid,
	input(compress(cyf_ine_event_from_date_wid_date,"-"),yymmdd10.) as startdate,
	input(compress(cyf_ine_event_to_date_wid_date,"-"),yymmdd10.) as enddate
from cyf.CYF_intakes_event 
order by snz_composite_event_uid;

proc sql;
create table CYF_intake1 as select 
	a.*,
	b.cyf_ind_business_area_type_code as Business_Area,
	b.cyf_ind_notifier_role_type_code as NOTIFIER_ROLE_GROUP				
from CYF_intake a left join cyf.cyf_intakes_details b

on a.snz_composite_event_uid=b.snz_composite_event_uid
order by snz_uid;

data CYF_intake_clean; 
set CYF_intake1; 
format startdate enddate date9.;
if startdate>"&sensor."D then delete;
if enddate>"&sensor."D then enddate="&sensor."D;

run;



* CYF abuse findings;
proc sql;
create table CYF_abuse as select 
	snz_uid,
	snz_composite_event_uid,
	cyf_abe_source_uk_var2_text as abuse_type,
	input(compress(cyf_abe_event_from_date_wid_date,"-"),yymmdd10.) as finding_date
from cyf.CYF_abuse_event 
order by snz_composite_event_uid;

proc sql;
create table CYF_abuse1 as select 
	a.*,
	b.cyf_abd_business_area_type_code as Business_Area
	from CYF_abuse a left join cyf.cyf_abuse_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by snz_uid;

data CYF_abuse_clean; set CYF_abuse1;
format finding_date date9.;
if finding_date>"&sensor."D then delete;
if abuse_type="NTF" then delete;* abuse not found;
	year=year(finding_date);
drop snz_composite_event_uid;


run;

proc sort data=CYF_abuse_clean nodupkey; 
by snz_uid abuse_type finding_date Business_Area; run;

* CYF placements;

proc sql;
create table CYF_place as select 
	snz_uid,
	cyf_ple_event_type_wid_nbr,
	snz_composite_event_uid,
	cyf_ple_number_of_days_nbr as event_duration,
	input(compress(cyf_ple_event_from_date_wid_date,"-"),yymmdd10.) as startdate,
	input(compress(cyf_ple_event_to_date_wid_date,"-"),yymmdd10.) as enddate
	

from cyf.cyf_placements_event 
order by snz_composite_event_uid;

proc sql;
create table CYF_place1 as select 
	a.*,
	b.cyf_pld_business_area_type_code as Business_Area,
	b.cyf_pld_placement_type_code as placement_type				
from CYF_place a left join cyf.cyf_placements_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by snz_uid;

data CYF_place_clean; 
set CYF_place1;
format startdate enddate date9.;
if startdate>"&sensor."D then delete;
if enddate>"&sensor."D then enddate="&sensor."D;
year=year(startdate);
event_duration=enddate-startdate+1;

run;

* CYF care episodes;

proc sql;
create table 
CYF_Care_e as select 
a.*,
c.cyf_lsd_legal_status_group_text,
c.cyf_lsd_in_favour_of_type_code,
c.cyf_lsd_legal_status_code

from 
cyf.cyf_ev_cli_legal_status_cys_f a 
left join cyf.cyf_dt_cli_legal_status_cys_d c
on a.snz_composite_event_uid=c.snz_composite_event_uid
order by a.snz_uid; 


data CYF_Care_e_clean; set CYF_Care_e; 
	format startdate enddate date9.;
	startdate=input(compress(cyf_lse_event_from_date_wid_date,"-"),yymmdd10.);
	enddate=input(compress(cyf_lse_event_to_date_wid_date,"-"),yymmdd10.);

	if startdate<"&sensor"d;

	if enddate>"&sensor"d then
		enddate="&sensor"d;
	if startdate<=enddate;

if (cyf_lsd_legal_status_group_text="CNP CUSTODY" and cyf_lsd_in_favour_of_type_code='CEO') or 
		(cyf_lsd_legal_status_group_text="CNP CUSTODY" and cyf_lsd_in_favour_of_type_code='CEMSD') or 
		(cyf_lsd_legal_status_group_text="CNP CUSTODY" and cyf_lsd_in_favour_of_type_code='UAC') or 
		(cyf_lsd_legal_status_group_text="CNP GUARDIANSHIP" and cyf_lsd_in_favour_of_type_code='CEMSD' and cyf_lsd_legal_status_code='S1102A') or 
		(cyf_lsd_legal_status_group_text="CNP GUARDIANSHIP" and cyf_lsd_in_favour_of_type_code='CEO' and cyf_lsd_legal_status_code='S1102A') or 
		(cyf_lsd_legal_status_group_text="CNP GUARDIANSHIP" and cyf_lsd_in_favour_of_type_code='UAC' and cyf_lsd_legal_status_code='S1102A') then grp='CYF';
if  (cyf_lsd_legal_status_group_text in ("YJU CUSTODY","YJU SUPERVISION")) then grp='YJ';
if grp='CYF' or grp='YJ';
event_duration=enddate-startdate+1;

run;

* Create clean FGC FWA datasets;

proc sql;
	create table FGC_raw as select 
		a.snz_uid,
		a.snz_composite_event_uid,
		input(compress(a.cyf_fge_event_from_date_wid_date,"-"),yymmdd10.) as startdate format date9.,
		input(compress(a.cyf_fge_event_to_date_wid_date,"-"),yymmdd10.) as enddate format date9.,
		a.cyf_fge_number_of_days_nbr as number_of_days,
		"26JUL2016"d as extractdate format date9.,
		b.cyf_fgd_business_area_type_code as business_area_type_code,
		input(compress(b.cyf_fgd_fgc_convened_date,"-"),yymmdd10.) as convdate format date9.

	from CYF.cyf_ev_cli_fgc_cys_f a left join  cyf.cyf_dt_cli_fgc_cys_d b
		on a.snz_composite_event_uid=b.snz_composite_event_uid;
quit;

proc sql;
	create table FWA_raw as select 
		a.snz_uid,
		a.snz_composite_event_uid,
		input(compress(a.cyf_fwe_event_from_date_wid_date,"-"),yymmdd10.) as startdate format date9.,
		input(compress(a.cyf_fwe_event_to_date_wid_date,"-"),yymmdd10.) as enddate format date9.,
		a.cyf_fwe_number_of_days_nbr as number_of_days,
		"26JUL2016"d as extractdate format date9.,
		b.cyf_fwd_business_area_type_code as business_area_type_code

	from CYF.cyf_ev_cli_fwas_cys_f a left join  cyf.cyf_dt_cli_fwas_cys_d b
		on a.snz_composite_event_uid=b.snz_composite_event_uid;
quit;

data FGC_FWA_clean; set FGC_raw (in=a) FWA_raw (in=b);
	if startdate lt "&sensor."d;
	if enddate>"&sensor"d then enddate="&sensor"d;
	if a then intervention = 'FGC';
	else if b then intervention = 'FWA';
	if business_area_type_code='CNP' and intervention = 'FGC' then CP_FGC = 1;
	else CP_FGC = 0;
	if business_area_type_code='CNP' and intervention = 'FWA' then CP_FWA = 1;
	else CP_FWA = 0;
	if business_area_type_code='YJU' and intervention = 'FGC' then YJ_FGC = 1;
	else YJ_FGC = 0;
run; 

proc datasets lib=work;
delete 
FWA_raw  FGC_raw
CYF_intake CYF_intake1
CYF_abuse CYF_abuse1
CYF_place CYF_place1 deletes
CYF_Care_e
;
run;

%mend;

***********************************************************************************************************************************************************
Creates CYF indicators for population of interest
***********************************************************************************************************************************************************;

%macro Create_CYF_ind_pop;
proc sql;
create table CYF_intake as select 
	a.snz_uid,
	a.snz_composite_event_uid,
	input(compress(a.cyf_ine_event_from_date_wid_date,"-"),yymmdd10.) as startdate,
	input(compress(a.cyf_ine_event_to_date_wid_date,"-"),yymmdd10.) as enddate,
	b.DOB
from cyf.CYF_intakes_event a inner join &population b
on a.snz_uid=b.snz_uid
order by a.snz_composite_event_uid;

proc sql;
create table CYF_intake1 as select 
	a.*,
	b.cyf_ind_business_area_type_code as Business_Area,
	b.cyf_ind_notifier_role_type_code as NOTIFIER_ROLE_GROUP				
from CYF_intake a left join cyf.cyf_intakes_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by a.snz_uid, a.startdate;
* CYF NOTIFICATIONS: clean;

data CYF_intake_clean; 
set CYF_intake1; 
by snz_uid startdate;
format startdate enddate date9.;
if startdate>"&sensor."D then delete;
if enddate>"&sensor."D then enddate="&sensor."D;

if startdate>intnx('YEAR',DOB, 18,'sameday') then delete;
run;

data CYF_intake_clean; set CYF_intake_clean; by snz_uid;
array ch_not_(*) ch_not_&cyf_left_yr.-ch_not_&last_anal_yr.;

array ch_Pol_FV_not_(*) ch_Pol_FV_not_&cyf_left_yr.-ch_Pol_FV_not_&last_anal_yr.;
array ch_YJ_referral_(*) ch_YJ_referral_&cyf_left_yr.-ch_YJ_referral_&last_anal_yr.;

array ch_not_at_age_(*) ch_not_at_age_&firstage.-ch_not_at_age_&cyf_lastage.;
array ch_Pol_FV_not_at_age_(*) ch_Pol_FV_not_at_age_&firstage.-ch_Pol_FV_not_at_age_&cyf_lastage.;
array ch_YJ_referral_at_age_(*) ch_YJ_referral_at_age_&firstage.-ch_YJ_referral_at_age_&cyf_lastage.;

retain
		ch_: ;
	%cyf_notifications(snz_uid,dob,%str(-99),%str(0),ch,at_birth);

	do ind = &cyf_left_yr. to &last_anal_yr.;
		i=ind-(&cyf_left_yr.-1);

		%cyf_notifications(snz_uid,mdy(1,1,&cyf_left_yr.),%str(i-1),%str(i),ch,(i));
	end;

	do ind = &firstage. to &cyf_lastage.;
		i=ind-(&firstage.-1);

		%cyf_notifications(snz_uid,dob,%str(i-1),%str(i),ch,at_age_(i));
	end;



if last.snz_uid then output;
	keep snz_uid DOB ch_:;

run;
**********************
* CYF abuse findings;
* CYF abuse findings: limit to population of interest;
proc sql;
create table CYF_abuse as select 
	a.snz_uid,
	a.snz_composite_event_uid,
	a.cyf_abe_source_uk_var2_text as abuse_type,
	input(compress(a.cyf_abe_event_from_date_wid_date,"-"),yymmdd10.) as finding_date format date9.,
	b.DOB
from cyf.CYF_abuse_event a inner join &population b
on  a.snz_uid=b.snz_uid
order by snz_composite_event_uid;

proc sql;
create table CYF_abuse1 as select 
	a.*,
	b.cyf_abd_business_area_type_code as Business_Area
	from CYF_abuse a left join cyf.cyf_abuse_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by a.snz_uid, a.finding_date;


proc sort data=CYF_abuse1 nodupkey; 
by snz_uid finding_date abuse_type Business_Area; run;

data CYF_abuse_clean; set CYF_abuse1; by snz_uid finding_date;
format finding_date date9.;
if finding_date>"&sensor."D then delete;
if abuse_type="NTF" then delete;* abuse not found;
drop snz_composite_event_uid;
if finding_date>intnx('YEAR',DOB, 18,'sameday') then delete; run;

data CYF_abuse_clean; set CYF_abuse_clean; by snz_uid;
	array ch_fdgs_neglect_at_age_(*) ch_fdgs_neglect_at_age_&firstage. - ch_fdgs_neglect_at_age_&cyf_lastage.;
	array ch_fdgs_phys_abuse_at_age_(*) ch_fdgs_phys_abuse_at_age_&firstage. - ch_fdgs_phys_abuse_at_age_&cyf_lastage.;
	array ch_fdgs_emot_abuse_at_age_(*) ch_fdgs_emot_abuse_at_age_&firstage. - ch_fdgs_emot_abuse_at_age_&cyf_lastage.;
	array ch_fdgs_sex_abuse_at_age_(*) ch_fdgs_sex_abuse_at_age_&firstage. - ch_fdgs_sex_abuse_at_age_&cyf_lastage.;
	array ch_fdgs_behav_rel_at_age_(*) ch_fdgs_behav_rel_at_age_&firstage. - ch_fdgs_behav_rel_at_age_&cyf_lastage.;
	array ch_fdgs_sh_suic_at_age_(*) ch_fdgs_sh_suic_at_age_&firstage. - ch_fdgs_sh_suic_at_age_&cyf_lastage.;
	array ch_any_fdgs_abuse_at_age_(*) ch_any_fdgs_abuse_at_age_&firstage.-ch_any_fdgs_abuse_at_age_&cyf_lastage.;

	array ch_fdgs_neglect_(*) ch_fdgs_neglect_&cyf_left_yr. - ch_fdgs_neglect_&last_anal_yr.;
	array ch_fdgs_phys_abuse_(*) ch_fdgs_phys_abuse_&cyf_left_yr. - ch_fdgs_phys_abuse_&last_anal_yr.;
	array ch_fdgs_emot_abuse_(*) ch_fdgs_emot_abuse_&cyf_left_yr. - ch_fdgs_emot_abuse_&last_anal_yr.;
	array ch_fdgs_sex_abuse_(*) ch_fdgs_sex_abuse_&cyf_left_yr. - ch_fdgs_sex_abuse_&last_anal_yr.;
	array ch_fdgs_behav_rel_(*) ch_fdgs_behav_rel_&cyf_left_yr. - ch_fdgs_behav_rel_&last_anal_yr.;
	array ch_fdgs_sh_suic_(*) ch_fdgs_sh_suic_&cyf_left_yr. - ch_fdgs_sh_suic_&last_anal_yr.;
	array ch_any_fdgs_abuse_(*) ch_any_fdgs_abuse_&cyf_left_yr.-ch_any_fdgs_abuse_&last_anal_yr.;


	retain
		ch_:;

	%cyf_findings(snz_uid,dob,-99,0,ch,at_birth);

	do ind = &cyf_left_yr. to &last_anal_yr.;
		i=ind-(&cyf_left_yr.-1);

		%cyf_findings(snz_uid,mdy(1,1,&cyf_left_yr.),%str(i-1),%str(i),ch,(i));
	end;

	do ind = &firstage. to &cyf_lastage.;
		i=ind-(&firstage.-1);

		%cyf_findings(snz_uid,dob,%str(i-1),%str(i),ch,at_age_(i));
	end;
if last.snz_uid then output;
keep snz_uid DOB ch_: ;

run;
*****************;
* CYF placements ;

proc sql;
create table CYF_place as select 
	a.snz_uid,
	a.cyf_ple_event_type_wid_nbr,
	a.snz_composite_event_uid,
	a.cyf_ple_number_of_days_nbr as event_duration,
	input(compress(a.cyf_ple_event_from_date_wid_date,"-"),yymmdd10.) as startdate,
	input(compress(a.cyf_ple_event_to_date_wid_date,"-"),yymmdd10.) as enddate,
	b.DOB

from cyf.cyf_placements_event a inner join &population b
on a.snz_uid=b.snz_uid
order by snz_composite_event_uid;

proc sql;
create table CYF_place1 as select 
	a.*,
	b.cyf_pld_business_area_type_code as Business_Area,
	b.cyf_pld_placement_type_code as placement_type				
from CYF_place a left join cyf.cyf_placements_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by a.snz_uid, a.startdate;

data CYF_place_clean; 
set CYF_place1; by snz_uid startdate;
format startdate enddate date9.;
if startdate>"&sensor."D then delete;
if enddate>"&sensor."D then enddate="&sensor."D;
if startdate>intnx('YEAR',DOB, 18,'sameday') then delete;
run;

data CYF_place_clean; set CYF_place_clean; by snz_uid;

array ch_CYF_place_at_age_(*) ch_CYF_place_at_age_&firstage.-ch_CYF_place_at_age_&cyf_lastage.;
array ch_YJ_place_at_age_(*) ch_YJ_place_at_age_&firstage.-ch_YJ_place_at_age_&cyf_lastage.;

array ch_CYF_place_(*) ch_CYF_place_&cyf_left_yr.-ch_CYF_place_&last_anal_yr.;
array ch_YJ_place_(*) ch_YJ_place_&cyf_left_yr.-ch_YJ_place_&last_anal_yr.;
event_duration=enddate-startdate+1;
retain ch_:;

	%cyf_placements(snz_uid,dob,-99,0,ch,at_birth);

	do ind = &cyf_left_yr. to &last_anal_yr.;
		i=ind-(&cyf_left_yr.-1);

		%cyf_placements(snz_uid,mdy(1,1,&cyf_left_yr.),%str(i-1),%str(i),ch,(i));
	end;

	do ind = &firstage. to &cyf_lastage.;
		i=ind-(&firstage.-1);

		%cyf_placements(snz_uid,dob,%str(i-1),%str(i),ch,at_age_(i));
	end;
if last.snz_uid then output;
keep snz_uid DOB ch_: ;

run;
************************
* Care episodes  ;

proc sql;
create table 
Care_e as select 
a.*,
b.DOB,
c.cyf_lsd_legal_status_group_text,
c.cyf_lsd_in_favour_of_type_code,
c.cyf_lsd_legal_status_code

from 
cyf.cyf_ev_cli_legal_status_cys_f a inner join &population b
on a.snz_uid=b.snz_uid
left join cyf.cyf_dt_cli_legal_status_cys_d c
on a.snz_composite_event_uid=c.snz_composite_event_uid
order by a.snz_uid; 

data care_e; set care_e; 
	format startdate enddate date9.;
	startdate=input(compress(cyf_lse_event_from_date_wid_date,"-"),yymmdd10.);
	enddate=input(compress(cyf_lse_event_to_date_wid_date,"-"),yymmdd10.);

	if startdate<"&sensor"d;

	if enddate>"&sensor"d then
		enddate="&sensor"d;


	if startdate<=enddate;
	if startdate>intnx('YEAR',DOB, 18,'sameday') then delete;	
	if enddate>intnx('YEAR',DOB, 18,'sameday') then enddate=intnx('YEAR',DOB, 18,'sameday');
if cyf_lsd_legal_status_group_text in ('CNP CUSTODY','CNP GUARDIANSHIP') then grp='CYF'; 
if cyf_lsd_legal_status_group_text in ('YJU CUSTODY','YJU SUPERVISION') then grp='YJ';

run;


proc sort data=care_e nodupkey; by snz_uid grp startdate enddate; run;

data care_e_1; set care_e; if grp='CYF';
data care_e_2; set care_e; if grp='YJ';
run;

%overlap(care_e_1);
%overlap(care_e_2);

data care_e_clean; 
set care_e_1_OR care_e_2_OR ; 
proc sort data=care_e_clean; by snz_uid;
data care_e_clean; set care_e_clean;
by snz_uid;
format startdate enddate date9.;

run;

data care_e_clean; set care_e_clean; by snz_uid;

array ch_CYF_ce_at_age_(*) ch_CYF_ce_at_age_&firstage.-ch_CYF_ce_at_age_&cyf_lastage.;
array ch_YJ_ce_at_age_(*) ch_YJ_ce_at_age_&firstage.-ch_YJ_ce_at_age_&cyf_lastage.;

array ch_CYF_ce_(*) ch_CYF_ce_&cyf_left_yr.-ch_CYF_ce_&last_anal_yr.;
array ch_YJ_ce_(*) ch_YJ_ce_&cyf_left_yr.-ch_YJ_ce_&last_anal_yr.;

array ch_CYF_ce_da_at_age_(*) ch_CYF_ce_da_at_age_&firstage.-ch_CYF_ce_da_at_age_&cyf_lastage.;
array ch_YJ_ce_da_at_age_(*) ch_YJ_ce_da_at_age_&firstage.-ch_YJ_ce_da_at_age_&cyf_lastage.;

array ch_CYF_ce_da_(*) ch_CYF_ce_da_&cyf_left_yr.-ch_CYF_ce_da_&last_anal_yr.;
array ch_YJ_ce_da_(*) ch_YJ_ce_da_&cyf_left_yr.-ch_YJ_ce_da_&last_anal_yr.;

event_duration=enddate-startdate+1;

retain ch_:;

	%Care_episodes(snz_uid,dob,-99,0,ch,at_birth);

	do ind = &cyf_left_yr. to &last_anal_yr.;
		i=ind-(&cyf_left_yr.-1);

			Ch_CYF_ce_da_(i)=0;
			Ch_YJ_ce_da_(i)=0;

			start_window=intnx('YEAR',mdy(1,1,&cyf_left_yr.),i-1,'S');
			end_window=intnx('YEAR',mdy(1,1,&cyf_left_yr.),i,'S');


	%Care_episodes(snz_uid,mdy(1,1,&cyf_left_yr.),%str(i-1),%str(i),ch,(i));

		if not((startdate > end_window) or (enddate < start_window)) then
			do;
				if (startdate <= start_window) and  (enddate > end_window) then
					days=(end_window-start_window)+1;
				else if (startdate <= start_window) and  (enddate <= end_window) then
					days=(enddate-start_window)+1;
				else if (startdate > start_window) and  (enddate <= end_window) then
					days=(enddate-startdate)+1;
				else if (startdate > start_window) and  (enddate > end_window) then
					days=(end_window-startdate)+1;

				if grp='CYF' then
					Ch_CYF_ce_da_(i)=days;

				if grp='YJ' then
					Ch_YJ_ce_da_(i)=days;
			end;

 	end;

	do ind = &firstage. to &cyf_lastage.;
	i=ind-(&firstage.-1);

			Ch_CYF_ce_da_at_age_(i)=0;
			Ch_YJ_ce_da_at_age_(i)=0;

			start_window=intnx('YEAR',DOB,i-1,'S');
			end_window=intnx('YEAR',DOB,i,'S');


		%Care_episodes(snz_uid,dob,%str(i-1),%str(i),ch,at_age_(i));

		if not((startdate > end_window) or (enddate < start_window)) then
			do;
				if (startdate <= start_window) and  (enddate > end_window) then
					days=(end_window-start_window)+1;
				else if (startdate <= start_window) and  (enddate <= end_window) then
					days=(enddate-start_window)+1;
				else if (startdate > start_window) and  (enddate <= end_window) then
					days=(enddate-startdate)+1;
				else if (startdate > start_window) and  (enddate > end_window) then
					days=(end_window-startdate)+1;

				if grp='CYF' then
					Ch_CYF_ce_da_at_age_(i)=days;

				if grp='YJ' then
					Ch_YJ_ce_da_at_age_(i)=days;
			end;

	end;


if last.snz_uid then output;
keep snz_uid DOB ch_: ;
run;

***FWA and FGC **********;

proc sql;
	create table FGC_raw as select 
		a.snz_uid,
		a.snz_composite_event_uid,
		input(compress(a.cyf_fge_event_from_date_wid_date,"-"),yymmdd10.) as startdate format date9.,
		input(compress(a.cyf_fge_event_to_date_wid_date,"-"),yymmdd10.) as enddate format date9.,
		a.cyf_fge_number_of_days_nbr as number_of_days,
		"26JUL2016"d as extractdate format date9.,
		b.cyf_fgd_business_area_type_code as business_area_type_code,
		input(compress(b.cyf_fgd_fgc_convened_date,"-"),yymmdd10.) as convdate format date9.

	from CYF.cyf_ev_cli_fgc_cys_f a left join  cyf.cyf_dt_cli_fgc_cys_d b
		on a.snz_composite_event_uid=b.snz_composite_event_uid;
quit;

proc sql;
	create table FWA_raw as select 
		a.snz_uid,
		a.snz_composite_event_uid,
		input(compress(a.cyf_fwe_event_from_date_wid_date,"-"),yymmdd10.) as startdate format date9.,
		input(compress(a.cyf_fwe_event_to_date_wid_date,"-"),yymmdd10.) as enddate format date9.,
		a.cyf_fwe_number_of_days_nbr as number_of_days,
		"26JUL2016"d as extractdate format date9.,
		b.cyf_fwd_business_area_type_code as business_area_type_code

	from CYF.cyf_ev_cli_fwas_cys_f a left join  cyf.cyf_dt_cli_fwas_cys_d b
		on a.snz_composite_event_uid=b.snz_composite_event_uid;
quit;

data FGC_FWA; set FGC_raw (in=a) FWA_raw (in=b);
	if startdate lt "&sensor."d;
	if enddate>"&sensor"d then enddate="&sensor"d;
	if a then intervention = 'FGC';
	else if b then intervention = 'FWA';
	if business_area_type_code='CNP' and intervention = 'FGC' then CYF_FGC = 1;
	else CYF_FGC = 0;
	if business_area_type_code='CNP' and intervention = 'FWA' then CYF_FWA = 1;
	else CYF_FWA = 0;
	if business_area_type_code='YJU' and intervention = 'FGC' then YJ_FGC = 1;
	else YJ_FGC = 0;
run;

proc sql;
	create table FGC_FWA_temp
		as select 
			a.*,
			b.DOB
		from 
			FGC_FWA a inner join &population b
			on a.snz_uid=b.snz_uid
order by snz_uid, startdate;
quit;

data FGC_FWA_temp; set FGC_FWA_temp;
if enddate>intnx('YEAR',DOB,18,'sameday') then enddate=intnx('YEAR',DOB,18,'sameday');
run;


data FGC_FWA_clean; set  FGC_FWA_temp;
	by snz_uid startdate;
	array ch_CYF_FGC_at_age_(*) ch_CYF_FGC_at_age_&firstage.-ch_CYF_FGC_at_age_&cyf_lastage.;
	array ch_CYF_FWA_at_age_(*) ch_CYF_FWA_at_age_&firstage.-ch_CYF_FWA_at_age_&cyf_lastage.;
	array ch_YJ_FGC_at_age_(*) ch_YJ_FGC_at_age_&firstage.-ch_YJ_FGC_at_age_&cyf_lastage.;

	array ch_CYF_FGC_(*) ch_CYF_FGC_&cyf_left_yr.-ch_CYF_FGC_&last_anal_yr.;
	array ch_CYF_FWA_(*) ch_CYF_FWA_&cyf_left_yr.-ch_CYF_FWA_&last_anal_yr.;
	array ch_YJ_FGC_(*) ch_YJ_FGC_&cyf_left_yr.-ch_YJ_FGC_&last_anal_yr.;

	retain ch_:	;

	do ind  =  &firstage. to &cyf_lastage.;
		i = ind-(&firstage.-1);
		%FGC_FWA_count(snz_uid, dob, %str(i-1), %str(i), ch, at_age_(i));
	end;
	
	
	do ind  =  &cyf_left_yr. to &last_anal_yr.;
		i = ind-(&cyf_left_yr.-1);
		%FGC_FWA_count(snz_uid,mdy(1,1,&cyf_left_yr.), %str(i-1), %str(i), ch, (i));
	end;
	
	* counting on the period of conception and birth;
	%FGC_FWA_count(snz_uid,dob,%str(-0.75), %str(0), ch, prior_birth);

drop ch_YJ_FGC_prior_birth;

	* Set to missing if the age interval is not fully observed 
	(i.e. the end is after the censoring date);
	if last.snz_uid then output;

	keep snz_uid DOB ch_:;
run; 



***********;


data &projectlib.._ind_CYF_child_&date.; 
merge CYF_intake_clean(in=a) CYF_abuse_clean (in=b) CYF_place_clean(in=c) care_e_clean(in=d) FGC_FWA_clean(in=e); 
by snz_uid;
drop 
ch_not_at_age_:
	ch_Pol_FV_not_at_age_:
	ch_YJ_referral_at_age_:

	ch_fdgs_neglect_at_age:
	ch_fdgs_phys_abuse_at_age:
	ch_fdgs_emot_abuse_at_age:
	ch_fdgs_sex_abuse_at_age:
	ch_fdgs_behav_rel_at_age:
	ch_fdgs_sh_suic_at_age:
	ch_any_fdgs_abuse_at_age:

	ch_CYF_place_at_age:
	ch_YJ_place_at_age:

	ch_CYF_ce_at_age:
	ch_YJ_ce_at_age:

	ch_CYF_ce_da_at_age:
	ch_YJ_ce_da_at_age:

ch_not_at_birth
ch_Pol_FV_not_at_birth
ch_YJ_referral_at_birth
ch_fdgs_neglect_at_birth
ch_fdgs_phys_abuse_at_birth
ch_fdgs_sex_abuse_at_birth
ch_fdgs_emot_abuse_at_birth
ch_fdgs_behav_rel_at_birth
ch_fdgs_sh_suic_at_birth
ch_any_fdgs_abuse_at_birth
ch_CYF_place_at_birth
ch_YJ_place_at_birth
ch_CYF_ce_at_birth
ch_YJ_ce_at_birth


ch_CYF_FGC_at_age:
ch_CYF_FWA_at_age:
ch_YJ_FGC_at_age:

ch_CYF_FGC_prior_birth:
ch_CYF_FWA_prior_birth:
;

run;

data &projectlib.._ind_CYF_child_at_age_&date.; 
merge CYF_intake_clean(in=a) CYF_abuse_clean (in=b) CYF_place_clean(in=c) care_e_clean(in=d) FGC_FWA_clean(in=e); 
by snz_uid;
keep snz_uid  
	ch_not_at_birth
	ch_CYF_FGC_prior_birth:
	ch_CYF_FWA_prior_birth:

	ch_Pol_FV_not_at_birth
	ch_YJ_referral_at_birth
	ch_fdgs_neglect_at_birth
	ch_fdgs_phys_abuse_at_birth
	ch_fdgs_sex_abuse_at_birth
	ch_fdgs_emot_abuse_at_birth
	ch_fdgs_behav_rel_at_birth
	ch_fdgs_sh_suic_at_birth
	ch_any_fdgs_abuse_at_birth
	ch_CYF_place_at_birth
	ch_YJ_place_at_birth
	ch_CYF_ce_at_birth
	ch_YJ_ce_at_birth

ch_not_at_age_:
	ch_Pol_FV_not_at_age_:
	ch_YJ_referral_at_age_:

	ch_fdgs_neglect_at_age:
	ch_fdgs_phys_abuse_at_age:
	ch_fdgs_emot_abuse_at_age:
	ch_fdgs_sex_abuse_at_age:
	ch_fdgs_behav_rel_at_age:
	ch_fdgs_sh_suic_at_age:
	ch_any_fdgs_abuse_at_age:

	ch_CYF_place_at_age:
	ch_YJ_place_at_age:

	ch_CYF_ce_at_age:
	ch_YJ_ce_at_age:
	ch_CYF_ce_da_at_age:
	ch_YJ_ce_da_at_age:

	ch_CYF_FGC_at_age:
	ch_CYF_FWA_at_age:
	ch_YJ_FGC_at_age:

;
run;

proc datasets lib=work;

delete 

CYF_intake CYF_intake1
CYF_abuse CYF_abuse1
CYF_place CYF_place1 
CYF_intake_clean 
CYF_abuse_clean 
CYF_place_clean
care_e:
FGC_:
FWA_:
deletes;

run;

%mend;


***********************************************************************************************************************************************************
Creates CYF indicators for population of interest
***********************************************************************************************************************************************************;

%macro Create_mth_CYF_ind_pop;
proc sql;
create table CYF_intake as select 
	a.snz_uid,
	a.snz_composite_event_uid,
	input(compress(a.cyf_ine_event_from_date_wid_date,"-"),yymmdd10.) as startdate,
	input(compress(a.cyf_ine_event_to_date_wid_date,"-"),yymmdd10.) as enddate,
	b.DOB
from cyf.CYF_intakes_event a inner join &population b
on a.snz_uid=b.snz_uid
order by a.snz_composite_event_uid;

proc sql;
create table CYF_intake1 as select 
	a.*,
	b.cyf_ind_business_area_type_code as Business_Area,
	b.cyf_ind_notifier_role_type_code as NOTIFIER_ROLE_GROUP				
from CYF_intake a left join cyf.cyf_intakes_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by a.snz_uid, a.startdate;
* CYF NOTIFICATIONS: clean;

data CYF_intake_clean; 
set CYF_intake1; 
by snz_uid startdate;
format startdate enddate date9.;
if startdate>"&sensor."D then delete;
if enddate>"&sensor."D then enddate="&sensor."D;

if startdate>intnx('YEAR',DOB, 18,'sameday') then delete;
run;

data CYF_intake_clean; set CYF_intake_clean; by snz_uid;
array ch_not_(*) ch_not_&m.-ch_not_&n.;
array ch_Pol_FV_not_(*) ch_Pol_FV_not_&m.-ch_Pol_FV_not_&n.;
array ch_YJ_referral_(*) ch_YJ_referral_&m.-ch_YJ_referral_&n.;

retain
		ch_: ;

	do ind = &m. to &n.;
		i=ind-(&m.-1);

		%cyf_notifications_mth(snz_uid,&start.,%str(i-1),%str(i),ch,(i));
	end;


if last.snz_uid then output;
	keep snz_uid DOB ch_:;

run;
**********************
* CYF abuse findings;
* CYF abuse findings: limit to population of interest;
proc sql;
create table CYF_abuse as select 
	a.snz_uid,
	a.snz_composite_event_uid,
	a.cyf_abe_source_uk_var2_text as abuse_type,
	input(compress(a.cyf_abe_event_from_date_wid_date,"-"),yymmdd10.) as finding_date format date9.,
	b.DOB
from cyf.CYF_abuse_event a inner join &population b
on  a.snz_uid=b.snz_uid
order by snz_composite_event_uid;

proc sql;
create table CYF_abuse1 as select 
	a.*,
	b.cyf_abd_business_area_type_code as Business_Area
	from CYF_abuse a left join cyf.cyf_abuse_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by a.snz_uid, a.finding_date;


proc sort data=CYF_abuse1 nodupkey; 
by snz_uid finding_date abuse_type Business_Area; run;

data CYF_abuse_clean; set CYF_abuse1; by snz_uid finding_date;
format finding_date date9.;
if finding_date>"&sensor."D then delete;
if abuse_type="NTF" then delete;* abuse not found;
drop snz_composite_event_uid;
if finding_date>intnx('YEAR',DOB, 18,'sameday') then delete; run;

data CYF_abuse_clean; set CYF_abuse_clean; by snz_uid;
	array ch_fdgs_neglect_(*) ch_fdgs_neglect_&m. - ch_fdgs_neglect_&n.;
	array ch_fdgs_phys_abuse_(*) ch_fdgs_phys_abuse_&m. - ch_fdgs_phys_abuse_&n.;
	array ch_fdgs_emot_abuse_(*) ch_fdgs_emot_abuse_&m. - ch_fdgs_emot_abuse_&n.;
	array ch_fdgs_sex_abuse_(*) ch_fdgs_sex_abuse_&m. - ch_fdgs_sex_abuse_&n.;
	array ch_fdgs_behav_rel_(*) ch_fdgs_behav_rel_&m. - ch_fdgs_behav_rel_&n.;
	array ch_fdgs_sh_suic_(*) ch_fdgs_sh_suic_&m. - ch_fdgs_sh_suic_&n.;
	array ch_any_fdgs_abuse_(*) ch_any_fdgs_abuse_&m.-ch_any_fdgs_abuse_&n.;
retain
		ch_:;

	do ind = &m. to &n.;
		i=ind-(&m.-1);

		%cyf_findings_mth(snz_uid,&start.,%str(i-1),%str(i),ch,(i));
	end;
if last.snz_uid then output;
keep snz_uid DOB ch_: ;

run;
*****************;
* CYF placements ;

proc sql;
create table CYF_place as select 
	a.snz_uid,
	a.cyf_ple_event_type_wid_nbr,
	a.snz_composite_event_uid,
	a.cyf_ple_number_of_days_nbr as event_duration,
	input(compress(a.cyf_ple_event_from_date_wid_date,"-"),yymmdd10.) as startdate,
	input(compress(a.cyf_ple_event_to_date_wid_date,"-"),yymmdd10.) as enddate,
	b.DOB

from cyf.cyf_placements_event a inner join &population b
on a.snz_uid=b.snz_uid
order by snz_composite_event_uid;

proc sql;
create table CYF_place1 as select 
	a.*,
	b.cyf_pld_business_area_type_code as Business_Area,
	b.cyf_pld_placement_type_code as placement_type				
from CYF_place a left join cyf.cyf_placements_details b
on a.snz_composite_event_uid=b.snz_composite_event_uid
order by a.snz_uid, a.startdate;

data CYF_place_clean; 
set CYF_place1; by snz_uid startdate;
format startdate enddate date9.;
if startdate>"&sensor."D then delete;
if enddate>"&sensor."D then enddate="&sensor."D;
if startdate>intnx('YEAR',DOB, 18,'sameday') then delete;
run;

data CYF_place_clean; set CYF_place_clean; by snz_uid;
array ch_CYF_place_(*) ch_CYF_place_&m.-ch_CYF_place_&n.;
array ch_YJ_place_(*) ch_YJ_place_&m.-ch_YJ_place_&n.;
event_duration=enddate-startdate+1;
retain ch_:;


	do ind = &m. to &n.;
		i=ind-(&m.-1);

		%cyf_placements_mth(snz_uid,&start.,%str(i-1),%str(i),ch,(i));
	end;

if last.snz_uid then output;
keep snz_uid DOB ch_: ;

run;
************************
* Care episodes  ;

proc sql;
create table 
Care_e as select 
a.*,
b.DOB,
c.cyf_lsd_legal_status_group_text,
c.cyf_lsd_in_favour_of_type_code,
c.cyf_lsd_legal_status_code

from 
cyf.cyf_ev_cli_legal_status_cys_f a inner join &population b
on a.snz_uid=b.snz_uid
left join cyf.cyf_dt_cli_legal_status_cys_d c
on a.snz_composite_event_uid=c.snz_composite_event_uid
order by a.snz_uid; 

data care_e; set care_e; 
	format startdate enddate date9.;
	startdate=input(compress(cyf_lse_event_from_date_wid_date,"-"),yymmdd10.);
	enddate=input(compress(cyf_lse_event_to_date_wid_date,"-"),yymmdd10.);

	if startdate<"&sensor"d;

	if enddate>"&sensor"d then
		enddate="&sensor"d;


	if startdate<=enddate;
	if startdate>intnx('YEAR',DOB, 18,'sameday') then delete;	
	if enddate>intnx('YEAR',DOB, 18,'sameday') then enddate=intnx('YEAR',DOB, 18,'sameday');
if cyf_lsd_legal_status_group_text in ('CNP CUSTODY','CNP GUARDIANSHIP') then grp='CYF'; 
if cyf_lsd_legal_status_group_text in ('YJU CUSTODY','YJU SUPERVISION') then grp='YJ';

run;


proc sort data=care_e nodupkey; by snz_uid grp startdate enddate; run;

data care_e_1; set care_e; if grp='CYF';
data care_e_2; set care_e; if grp='YJ';
run;

%overlap(care_e_1);
%overlap(care_e_2);

data care_e_clean; 
set care_e_1_OR care_e_2_OR ; 
proc sort data=care_e_clean; by snz_uid;
data care_e_clean; set care_e_clean;
by snz_uid;
format startdate enddate date9.;

run;

data care_e_clean; set care_e_clean; by snz_uid;

array ch_CYF_ce_(*) ch_CYF_ce_&m.-ch_CYF_ce_&n.;
array ch_YJ_ce_(*) ch_YJ_ce_&m.-ch_YJ_ce_&n.;

array ch_CYF_ce_da_(*) ch_CYF_ce_da_&m.-ch_CYF_ce_da_&n.;
array ch_YJ_ce_da_(*) ch_YJ_ce_da_&m.-ch_YJ_ce_da_&n.;

event_duration=enddate-startdate+1;

retain ch_:;

	do ind = &m. to &n.;
		i=ind-(&m.-1);

			Ch_CYF_ce_da_(i)=0;
			Ch_YJ_ce_da_(i)=0;

   start_window=intnx('month',&start.,i-1,'S');
   end_window=(intnx('month',&start.,i,'S'))-1;


	%Care_episodes_mth(snz_uid,&start.,%str(i-1),%str(i),ch,(i));

		if not((startdate > end_window) or (enddate < start_window)) then
			do;
				if (startdate <= start_window) and  (enddate > end_window) then
					days=(end_window-start_window)+1;
				else if (startdate <= start_window) and  (enddate <= end_window) then
					days=(enddate-start_window)+1;
				else if (startdate > start_window) and  (enddate <= end_window) then
					days=(enddate-startdate)+1;
				else if (startdate > start_window) and  (enddate > end_window) then
					days=(end_window-startdate)+1;

				if grp='CYF' then
					Ch_CYF_ce_da_(i)=days;

				if grp='YJ' then
					Ch_YJ_ce_da_(i)=days;
			end;

 	end;
if last.snz_uid then output;
keep snz_uid DOB ch_: ;
run;

***FWA and FGC **********;

proc sql;
	create table FGC_raw as select 
		a.snz_uid,
		a.snz_composite_event_uid,
		input(compress(a.cyf_fge_event_from_date_wid_date,"-"),yymmdd10.) as startdate format date9.,
		input(compress(a.cyf_fge_event_to_date_wid_date,"-"),yymmdd10.) as enddate format date9.,
		a.cyf_fge_number_of_days_nbr as number_of_days,
		"26JUL2016"d as extractdate format date9.,
		b.cyf_fgd_business_area_type_code as business_area_type_code,
		input(compress(b.cyf_fgd_fgc_convened_date,"-"),yymmdd10.) as convdate format date9.

	from CYF.cyf_ev_cli_fgc_cys_f a left join  cyf.cyf_dt_cli_fgc_cys_d b
		on a.snz_composite_event_uid=b.snz_composite_event_uid;
quit;

proc sql;
	create table FWA_raw as select 
		a.snz_uid,
		a.snz_composite_event_uid,
		input(compress(a.cyf_fwe_event_from_date_wid_date,"-"),yymmdd10.) as startdate format date9.,
		input(compress(a.cyf_fwe_event_to_date_wid_date,"-"),yymmdd10.) as enddate format date9.,
		a.cyf_fwe_number_of_days_nbr as number_of_days,
		"26JUL2016"d as extractdate format date9.,
		b.cyf_fwd_business_area_type_code as business_area_type_code

	from CYF.cyf_ev_cli_fwas_cys_f a left join  cyf.cyf_dt_cli_fwas_cys_d b
		on a.snz_composite_event_uid=b.snz_composite_event_uid;
quit;

data FGC_FWA; set FGC_raw (in=a) FWA_raw (in=b);
	if startdate lt "&sensor."d;
	if enddate>"&sensor"d then enddate="&sensor"d;
	if a then intervention = 'FGC';
	else if b then intervention = 'FWA';
	if business_area_type_code='CNP' and intervention = 'FGC' then CYF_FGC = 1;
	else CYF_FGC = 0;
	if business_area_type_code='CNP' and intervention = 'FWA' then CYF_FWA = 1;
	else CYF_FWA = 0;
	if business_area_type_code='YJU' and intervention = 'FGC' then YJ_FGC = 1;
	else YJ_FGC = 0;
run;

proc sql;
	create table FGC_FWA_temp
		as select 
			a.*,
			b.DOB
		from 
			FGC_FWA a inner join &population b
			on a.snz_uid=b.snz_uid
order by snz_uid, startdate;
quit;

data FGC_FWA_temp; set FGC_FWA_temp;
if enddate>intnx('YEAR',DOB,18,'sameday') then enddate=intnx('YEAR',DOB,18,'sameday');
run;


data FGC_FWA_clean; set  FGC_FWA_temp;
	by snz_uid startdate;
	array ch_CYF_FGC_(*) ch_CYF_FGC_&m.-ch_CYF_FGC_&n.;
	array ch_CYF_FWA_(*) ch_CYF_FWA_&m.-ch_CYF_FWA_&n.;
	array ch_YJ_FGC_(*) ch_YJ_FGC_&m.-ch_YJ_FGC_&n.;

	retain ch_:	;


	do ind  =  &m. to &n.;
		i = ind-(&m.-1);
		%FGC_FWA_count_mth(snz_uid,&start., %str(i-1), %str(i), ch, (i));
	end;
	
	if last.snz_uid then output;

	keep snz_uid DOB ch_:;
run; 



***********;


data &projectlib.._mth_CYF_child_&date.; 
merge CYF_intake_clean(in=a) CYF_abuse_clean (in=b) CYF_place_clean(in=c) care_e_clean(in=d) FGC_FWA_clean(in=e); 
by snz_uid;
run;

proc datasets lib=work;

delete 

CYF_intake CYF_intake1
CYF_abuse CYF_abuse1
CYF_place CYF_place1 
CYF_intake_clean 
CYF_abuse_clean 
CYF_place_clean
care_e:
FGC_:
FWA_:
deletes;

run;

%mend;

