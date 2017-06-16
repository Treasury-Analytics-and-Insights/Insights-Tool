
%macro Create_sib_CYF_pop(rel1,rel2);
*part 1;
data TEMP_siblings_events;
	set &projectlib..CHILDSIBLINGMAPVENT_&date;
	format first_contact date9.;
	first_contact=startdate;
	if (source="&rel1." or source1="&rel1.") and (sibsource="&rel2." or sibsource1="&rel2.");
run;

proc sort data=TEMP_siblings_events;
	by snz_uid sibling startdate;

data TEMP_siblings_list;
	set TEMP_siblings_events;
	by snz_uid sibling startdate;
	ref_snz_uid=snz_uid;

	if first.sibling;
run;

data TEMP_siblings;
	merge TEMP_siblings_list(in=insib) &population (in=inpop keep=snz_uid DOB);
	by snz_uid;
	if inpop and insib;
run;

data TEMP_siblings_count;
	set TEMP_siblings;
	by snz_uid;
	if first.snz_uid then
		sibling_count=0;
	retain sibling_count;
	sibling_count+1;
	if last.snz_uid then
		output;
run;
*Part2;
%Create_clean_CYF_tables;

proc sql;
	create table TEMP_cyf_n1 as
		select
			s.sibling,s.ref_snz_uid, s.startdate,s.dob,
			t.*
		from
			TEMP_siblings s inner join
			cyf_intake_clean t
			on
			s.sibling = t.snz_uid
		order by s.ref_snz_uid, t.startdate;
run;

proc sql;
	create table TEMP_cyf_a1 as
		select
			s.sibling,s.ref_snz_uid, s.startdate,s.dob,
			t.*
		from
			TEMP_siblings s inner join
			cyf_abuse_clean t
			on
			s.sibling = t.snz_uid
		order by s.ref_snz_uid, t.finding_Date;
run;

proc sql;
	create table TEMP_cyf_p1 as
		select
			s.sibling,s.ref_snz_uid, s.startdate,s.dob,
			t.*
		from
			TEMP_siblings s inner join
			cyf_place_clean t
			on
			s.sibling = t.snz_uid
		order by s.ref_snz_uid, t.startdate;
run;

proc sql;
	create table TEMP_cyf_ce1 as
		select
			s.sibling,s.ref_snz_uid, s.startdate,s.dob,
			t.*
		from
			TEMP_siblings s inner join
			cyf_care_e_clean t
			on
			s.sibling = t.snz_uid
		order by s.ref_snz_uid, t.startdate;
run;

data TEMP_cyf_n1;
	set TEMP_cyf_n1;

	if enddate>=intnx('YEAR',startdate,-5,'sameday');
	if startdate<intnx('YEAR',startdate,-5,'sameday') 
	and enddate>intnx('YEAR',startdate,-5,'sameday') then
	startdate=intnx('YEAR',startdate,-5,'sameday');

run;

data TEMP_cyf_p1;
	set TEMP_cyf_p1;
	if enddate>=intnx('YEAR',startdate,-5,'sameday');
	if startdate<intnx('YEAR',startdate,-5,'sameday')
		and enddate>intnx('YEAR',startdate,-5,'sameday') then
		startdate=intnx('YEAR',startdate,-5,'sameday');
run;

data TEMP_cyf_a1;
	set TEMP_cyf_a1;
	if finding_date>=intnx('YEAR',startdate,-5,'sameday');
run;

data TEMP_cyf_ce1;
	set TEMP_cyf_ce1;
	if enddate>=intnx('YEAR',startdate,-5,'sameday');
	if startdate<intnx('YEAR',startdate,-5,'sameday')
		and enddate>intnx('YEAR',startdate,-5,'sameday') then
		startdate=intnx('YEAR',startdate,-5,'sameday');
run;

proc sort data=TEMP_CYF_n1;
	by ref_snz_uid ;
proc sort data=TEMP_CYF_a1;
	by ref_snz_uid;
proc sort data=TEMP_CYF_p1;
	by ref_snz_uid ;
run;
proc sort data=TEMP_CYF_ce1;
	by ref_snz_uid ;
run;

data  TEMP_CYF_n2;
	set  TEMP_CYF_n1;
	by ref_snz_uid;
	array othchd_not_at_age_(*) othchd_not_at_age_&firstage-othchd_not_at_age_&cyf_lastage.;
	array othchd_Pol_FV_not_at_age_(*) othchd_Pol_FV_not_at_age_&firstage-othchd_Pol_FV_not_at_age_&cyf_lastage.;
	array othchd_YJ_referral_at_age_(*) othchd_YJ_referral_at_age_&firstage-othchd_YJ_referral_at_age_&cyf_lastage.;
	retain
		othchd:;
	%cyf_notifications(ref_snz_uid,dob,%str(-99),%str(0),othchd,at_birth);

	do ind = &firstage to &cyf_lastage.;
		i=ind-(&firstage-1);

		%cyf_notifications(ref_snz_uid,dob,%str(i-1),%str(i),othchd,at_age_(i));
	end;

	if last.ref_snz_uid then
		output;
	keep ref_snz_uid 		
		othchd_:;
run;


data TEMP_CYF_a2;
	set TEMP_CYF_a1;
	by ref_snz_uid;
	array othchd_fdgs_neglect_at_age_(*) othchd_fdgs_neglect_at_age_&firstage - othchd_fdgs_neglect_at_age_&cyf_lastage.;
	array othchd_fdgs_phys_abuse_at_age_(*) othchd_fdgs_phys_abuse_at_age_&firstage - othchd_fdgs_phys_abuse_at_age_&cyf_lastage.;
	array othchd_fdgs_emot_abuse_at_age_(*) othchd_fdgs_emot_abuse_at_age_&firstage - othchd_fdgs_emot_abuse_at_age_&cyf_lastage.;
	array othchd_fdgs_sex_abuse_at_age_(*) othchd_fdgs_sex_abuse_at_age_&firstage - othchd_fdgs_sex_abuse_at_age_&cyf_lastage.;
	array othchd_fdgs_behav_rel_at_age_(*) othchd_fdgs_behav_rel_at_age_&firstage - othchd_fdgs_behav_rel_at_age_&cyf_lastage.;
	array othchd_fdgs_sh_suic_at_age_(*) othchd_fdgs_sh_suic_at_age_&firstage - othchd_fdgs_sh_suic_at_age_&cyf_lastage.;
	array othChd_any_fdgs_abuse_at_age_(*) othchd_any_fdgs_abuse_at_age_&firstage-othchd_any_fdgs_abuse_at_age_&cyf_lastage.;
	retain		
		othchd:	;
	%cyf_findings(ref_snz_uid,dob,-99,0,othchd,at_birth);

	do ind= &firstage to &cyf_lastage.;
		i=ind-(&firstage-1);

		%cyf_findings(ref_snz_uid,dob,i-1,i,othchd,at_age_(i));
	end;

	if last.ref_snz_uid then
		output;
	keep ref_snz_uid othchd_:;
run;

data  TEMP_CYF_p2;
	set  TEMP_CYF_p1;
	by ref_snz_uid ;
	array othchd_CYF_place_at_age_(*) othchd_CYF_place_at_age_&firstage-othchd_CYF_place_at_age_&cyf_lastage.;
	array othchd_YJ_place_at_age_(*) othchd_YJ_place_at_age_&firstage-othchd_YJ_place_at_age_&cyf_lastage.;
	retain othchd:;
	%cyf_placements(ref_snz_uid,dob,-99,0,othchd,at_birth);

	do ind= &firstage to &cyf_lastage.;
		i=ind-(&firstage-1);

		%cyf_placements(ref_snz_uid,dob,i-1,i,othchd,at_age_(i));
	end;

	if last.ref_snz_uid then
		output;
	keep ref_snz_uid othchd_:;
run;

data  TEMP_cyf_ce2;
	set  TEMP_cyf_ce1;
	by ref_snz_uid ;
	array othchd_CYF_ce_at_age_(*) othchd_CYF_ce_at_age_&firstage.-othchd_CYF_ce_at_age_&cyf_lastage.;
	array othchd_YJ_ce_at_age_(*) othchd_YJ_ce_at_age_&firstage.-othchd_YJ_ce_at_age_&cyf_lastage.; 
	event_duration=enddate-startdate+1;
	retain othchd:;

	%Care_episodes(ref_snz_uid,dob,-99,0,othchd,at_birth);

	do ind= &firstage to &cyf_lastage.;
		i=ind-(&firstage-1);
		%Care_episodes(ref_snz_uid,dob,i-1,i,othchd,at_age_(i));
	end;
	if last.ref_snz_uid then
		output;
	keep ref_snz_uid othchd_:;
run;


data &projectlib.._&rel1._&rel2._sib_cyf_at_age_&date.;
	merge TEMP_CYF_n2	TEMP_CYF_p2 TEMP_CYF_a2 TEMP_CYF_ce2;
	by ref_snz_uid;
	snz_uid=ref_snz_uid;
	drop ref_snz_uid;
run;

* by year;
data  TEMP_CYF_N3;
	set  TEMP_CYF_N1;
	by ref_snz_uid ;
	array othchd_not_(*) othchd_not_&cyf_left_yr.-othchd_not_&last_anal_yr.;
	array othchd_Pol_FV_not_(*) othchd_Pol_FV_not_&cyf_left_yr.-othchd_Pol_FV_not_&last_anal_yr.;
	array othchd_YJ_referral_(*) othchd_YJ_referral_&cyf_left_yr.-othchd_YJ_referral_&last_anal_yr.;
	retain othchd_:	;

	do ind = &cyf_left_yr.  to &last_anal_yr;
		i=ind-(&cyf_left_yr. -1);

		%cyf_notifications(ref_snz_uid,mdy(1,1,&cyf_left_yr.),%str(i-1),%str(i),othchd,(i));
	end;

	if last.ref_snz_uid then
		output;
	keep ref_snz_uid DOB othchd_:;
run;

data TEMP_CYF_a3;
	set TEMP_CYF_a1;
	by ref_snz_uid;
	array othchd_fdgs_neglect_(*) othchd_fdgs_neglect_&cyf_left_yr. - othchd_fdgs_neglect_&last_anal_yr.;
	array othchd_fdgs_phys_abuse_(*) othchd_fdgs_phys_abuse_&cyf_left_yr.  - othchd_fdgs_phys_abuse_&last_anal_yr.;
	array othchd_fdgs_emot_abuse_(*) othchd_fdgs_emot_abuse_&cyf_left_yr.  - othchd_fdgs_emot_abuse_&last_anal_yr.;
	array othchd_fdgs_sex_abuse_(*) othchd_fdgs_sex_abuse_&cyf_left_yr.  - othchd_fdgs_sex_abuse_&last_anal_yr.;
	array othchd_fdgs_behav_rel_(*) othchd_fdgs_behav_rel_&cyf_left_yr.  - othchd_fdgs_behav_rel_&last_anal_yr.;
	array othchd_fdgs_sh_suic_(*) othchd_fdgs_sh_suic_&cyf_left_yr.  - othchd_fdgs_sh_suic_&last_anal_yr.;
	array othChd_any_fdgs_abuse_(*) othchd_any_fdgs_abuse_&cyf_left_yr. -othchd_any_fdgs_abuse_&last_anal_yr.;
	retain othchd_:	;

	do ind = &cyf_left_yr.  to &last_anal_yr;
		i=ind-(&cyf_left_yr. -1);

		%cyf_findings(ref_snz_uid,mdy(1,1,&cyf_left_yr. ),i-1,i,othchd,(i));
	end;

	if last.ref_snz_uid then
		output;
	keep ref_snz_uid DOB othchd:;
run;


data  TEMP_CYF_p3;
	set  TEMP_CYF_p1;
	by ref_snz_uid ;
	array othchd_CYF_place_(*) othchd_CYF_place_&cyf_left_yr. -othchd_CYF_place_&last_anal_yr.;
	array othchd_YJ_place_(*) othchd_YJ_place_&cyf_left_yr. -othchd_YJ_place_&last_anal_yr.;
	retain othchd:;

	do ind = &cyf_left_yr.  to &last_anal_yr;
		i=ind-(&cyf_left_yr. -1);

		%cyf_placements(ref_snz_uid,mdy(1,1,&cyf_left_yr. ),i-1,i,othchd,(i));
	end;

	if last.ref_snz_uid then
		output;
	keep ref_snz_uid DOB othchd_CYF_place_:;
run;



data  TEMP_CYF_ce3;
	set  TEMP_CYF_ce1;
	by ref_snz_uid ;
	event_duration=enddate-startdate+1;
	array othchd_CYF_ce_(*) othchd_CYF_ce_&cyf_left_yr. -othchd_CYF_ce_&last_anal_yr.;
	array othchd_YJ_ce_(*) othchd_YJ_ce_&cyf_left_yr. -othchd_YJ_ce_&last_anal_yr.;
	retain othchd:;

	do ind = &cyf_left_yr.  to &last_anal_yr;
		i=ind-(&cyf_left_yr. -1);

		%care_episodes(ref_snz_uid,mdy(1,1,&cyf_left_yr. ),i-1,i,othchd,(i));
	end;

	if last.ref_snz_uid then
		output;
	keep ref_snz_uid DOB othchd_CYF_ce_:;
run;

data &projectlib.._&rel1._&rel2._sib_cyf_&date.; retain snz_uid dob: ;
	merge TEMP_CYF_n3 TEMP_CYF_p3 TEMP_CYF_a3 TEMP_CYF_ce3;
	by ref_snz_uid;
	snz_uid=ref_snz_uid;
	drop ref_snz_uid;
keep snz_uid DOB othchd_:;
run;

proc datasets lib=work;
delete temp: CYF:;
run;
%mend;