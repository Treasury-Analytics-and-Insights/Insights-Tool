
*******************************************************************************************************************************************
Looking at DIA records and creating indicators of whether refrence person became a parent
created indictor of count of children within the window of age and year

*******************************************************************************************************************************************;
*******************************************************************************************************************************************;

* SENSORING TO RELEVANT RECORDS;
%macro birth_by(datain,dataout,idvar);

	data &dataout;
		set &datain;
		array bir_at_age_(*) bir_at_age_&firstage. - bir_at_age_&lastage.;
		array bir_(*) bir_&first_anal_yr. - bir_&last_anal_yr.;

		do ind=&firstage. to &lastage.;
			i=ind-(&firstage.-1);
			bir_at_age_(i)=0;
			start_window=intnx('YEAR',DOB,i-1,'S');
			end_window=intnx('YEAR',DOB,i,'S');

			if ((DIA_bir_DOB <end_window) and (DIA_bir_DOB>=start_window)) then
				bir_at_age_(i)=1;
		end;
		
		do ind=&first_anal_yr. to &last_anal_yr.;
			i=ind-(&first_anal_yr.-1);
			bir_(i)=0;
			start_window=intnx('YEAR',MDY(1,1,&first_anal_yr.),i-1,'S');
			end_window=intnx('YEAR',MDY(1,1,&first_anal_yr.),i,'S');

			if ((DIA_bir_DOB <end_window) and (DIA_bir_DOB>=start_window)) then
				bir_(i)=1;
		end;


	run;

	proc summary data=&dataout nway;
		class &idvar DOB;
		var bir_at_age_&firstage. - bir_at_age_&lastage. bir_&first_anal_yr. - bir_&last_anal_yr.;
		output out=&dataout._ (drop=_type_ _freq_) sum=;
	run;

%mend;

%macro Num_children_pop;
* Picking up records of parent 1, usually MOTHERS
Where our cohort appears as Parent 1;
proc sql;
	create table TEMP_parent1 as select 
		snz_uid as child_snz_uid,
		dia_bir_sex_snz_code as child_sex_snz_code,
		dia_bir_still_birth_code as child_still_birth,
		dia_bir_multiple_birth_code as miltiple_birth,
		dia_bir_birth_month_nbr as birth_month,
		dia_bir_birth_year_nbr as birth_year,
		dia_bir_parent1_child_rel_text as child_parent1_rel,
		parent1_snz_uid
	from dia.births
		where parent1_snz_uid  in (select snz_uid from &population) 
			and MDY(dia_bir_birth_month_nbr,15,dia_bir_birth_year_nbr)<="&sensor"d
			and (parent1_snz_uid ne parent2_snz_uid or parent2_snz_uid=.)
		order by parent1_snz_uid;

	* Picking up records of parent 2, usually FATHERS
	Where our cohort appears as Parent 1;

	* SENSORING TO RELEVANT RECORDS;
proc sql;
	create table TEMP_parent2 as select 
		snz_uid as child_snz_uid,
		dia_bir_sex_snz_code as child_sex_snz_code,
		dia_bir_still_birth_code as child_still_birth,
		dia_bir_multiple_birth_code as miltiple_birth,
		dia_bir_birth_month_nbr as birth_month,
		dia_bir_birth_year_nbr as birth_year,
		dia_bir_parent2_child_rel_text as child_parent2_rel,
		parent2_snz_uid
	from dia.births
		where parent2_snz_uid  in (select snz_uid from &population)
			and MDY(dia_bir_birth_month_nbr,15,dia_bir_birth_year_nbr)<="&sensor"d
			and (parent2_snz_uid ne parent1_snz_uid or parent1_snz_uid=.)
		order by parent2_snz_uid;

	* BUSINESS RULE: Parents should not be the same person and excluding still birth
	* setting appox DOB in a date format;
data TEMP_parent1;
	set TEMP_parent1;

	if child_still_birth not in ("S","D");
	format DIA_bir_DOB date9.;
	DIA_bir_DOB=MDY(birth_month,15,birth_year);
run;

data TEMP_parent2;
	set TEMP_parent2;

	if child_still_birth not in ("S","D");
	format DIA_bir_DOB date9.;
	DIA_bir_DOB=MDY(birth_month,15,birth_year);
run;

* BUSINESS RULE: Use records where DOB of both child and parent is known where child is born after parent is born;
* brining in DOB of the Parent;
proc sql;
	create table TEMP_parent1_1 as select
		a.*,
		b.DOB
	from TEMP_Parent1 a left join &population b
		on a.parent1_snz_uid=b.snz_uid
	where b.DOB ne . and a.DIA_bir_DOB ne . and b.DOB<a.DIA_bir_DOB;

proc sql;
	create table TEMP_parent2_1 as select
		a.*,
		b.DOB
	from TEMP_Parent2 a left join &population b
		on a.parent2_snz_uid=b.snz_uid
	where b.DOB ne . and a.DIA_bir_DOB ne . and b.DOB<a.DIA_bir_DOB;

	* Starting to calculate the number of children given birth in each year;


%birth_by(TEMP_parent1_1,TEMP_parent1_2,parent1_snz_uid);
%birth_by(TEMP_parent2_1,TEMP_parent2_2,parent2_snz_uid);

* combining mother and father records;
data TEMP_parent1_2_;
	set TEMP_parent1_2_;
	rename bir_at_age_&firstage.-bir_at_age_&lastage.=mother_at_age_&firstage.-mother_at_age_&lastage.;
	rename bir_&first_anal_yr.-bir_&last_anal_yr.=mother_&first_anal_yr.-mother_&last_anal_yr.;
	rename parent1_snz_uid=snz_uid;
run;

data TEMP_parent2_2_;
	set TEMP_parent2_2_;
	rename bir_at_age_&firstage.-bir_at_age_&lastage.=father_at_age_&firstage.-father_at_age_&lastage.;
	rename bir_&first_anal_yr.-bir_&last_anal_yr.=father_&first_anal_yr.-father_&last_anal_yr.;
	rename parent2_snz_uid=snz_uid;
run;

data TEMP_combined; 
merge &population. (keep=snz_uid DOB) TEMP_parent1_2_ TEMP_parent2_2_;
by snz_uid;

proc summary data=TEMP_combined nway;
class snz_uid DOB;
var mother_at_age_:
father_at_age_:;
output out=&projectlib.._IND_PARENT_at_age_&date(keep=snz_uid DOB mother_at_age_9-mother_at_age_&lastage.
father_at_age_9-father_at_age_&lastage) sum=;

proc summary data=TEMP_combined nway;
class snz_uid DOB;
var mother_:
father_:;
output out=&projectlib.._IND_PARENT_&date(keep=snz_uid DOB 
mother_&first_anal_yr.-mother_&last_anal_yr.
father_&first_anal_yr.-father_&last_anal_yr.) sum=;

proc datasets lib=work ;
delete TEMP_:;
quit;

%mend;
