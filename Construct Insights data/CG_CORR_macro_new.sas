*************************************************************************************************************************************
*************************************************************************************************************************************

DICLAIMER:
This code has been created for research purposed by Analytics and Insights Team, The Treasury. 
The business rules and decisions made in this code are those of author(s) not Statistics New Zealand and The Treasury. 
This code can be modified and customised by users to meet the needs of specific research projects and in all cases, 
Analytics and Insights Team, NZ Treasury must be acknowledged as a source. 
While all care and diligence has been used in developing this code, Statistics New Zealand and The Treasury gives no warranty 
it is error free and will not be liable for any loss or damage suffered by the use directly or indirectly.

*************************************************************************************************************************************
*************************************************************************************************************************************;

%macro Create_CG_corr_history(rel,sex);
proc sql;
	select max(floor(yrdif(dob,"&sensor."d))) into: maxage separated by "" from &population.;
quit;

proc sort data=&projectlib..parenttochildmap_&date out=parenttochildmap_&date;
	by snz_uid parent event_date;
run;

proc sort data=parenttochildmap_&date out=temp_parenttochildmap(where=((source="&rel." or source1="&rel.") and parent_sex="&sex.")) nodupkey;
	by snz_uid parent parent_sex;
run;

data temp_pop_ch_parent_map temp_ch_parentcount;
	merge &population (in=inpop) Temp_parenttochildmap;
	by snz_uid;

	if inpop;

	if first.snz_uid then
		parent_count = 0;
	retain parent_count;

	if parent ne . then
		parent_count + 1;
	noparent = parent_count = 0;

	if last.snz_uid then
		output temp_ch_parentcount;
	output temp_pop_ch_parent_map;
run;

proc sort data=temp_pop_ch_parent_map;
	by parent;
run;

data temp_parents_single temp_parents_ch;
	set temp_pop_ch_parent_map;
	by parent;
	child_snz_uid = snz_uid;
	snz_uid = parent; 

	if first.parent then
		countchild = 1;
	retain countchild;

	if first.parent = 0 and parent ne . then
		countchild + 1;

	if parent ne . then
		output temp_parents_ch;

	if last.parent and  parent ne . then
		output temp_parents_single;
run;

proc sql;
	select max(countchild) into: maxchild separated by "" from temp_parents_single;
quit;


proc sql;
create table temp_cor_0 
as select 
	snz_uid,
	input(compress(cor_mmp_period_start_date,"-"),yymmdd10.) as startdate format date9.,
	input(compress(cor_mmp_period_end_date,"-"),yymmdd10.) as enddate format date9.,
	cor_mmp_mmc_code as mmc_code
	
from cor.ov_major_mgmt_periods 
where snz_uid in (select distinct snz_uid from temp_parents_single) and cor_mmp_mmc_code in 
			('PRISON','REMAND','HD_SENT','HD_REL','ESO','PAROLE',
			'ROC','PDC','PERIODIC', 'COM_DET','CW','COM_PROG','COM_SERV','OTH_COMM',
			'INT_SUPER','SUPER') ;

%overlap(temp_cor_0);

data temp_cor_0_OR ;
	set temp_cor_0_OR ;
	offence = 'COR_COMM';

	if mmc_code = 'PRISON' or mmc_code='REMAND' or mmc_code = 'HD_SENT' 
		or mmc_code = 'HD_REL' then
		offence = 'COR_INTE';

	if startdate > "&sensor."d then
		delete;
if enddate>"&sensor"d then enddate="&sensor"d;
drop mmc_code;
run;

proc sort data = temp_cor_0_OR;
	by snz_uid;
run;

proc sort data = temp_parents_ch;	by snz_uid;
run;

%macro perchild(num);
	data temp_cor_child_&num.;
		merge temp_parents_ch (in = a where = (countchild = &num.)) 
			temp_cor_0_OR(in = b );
		by snz_uid;

		if a and b;

		if intnx('YEAR',enddate,5,'sameday') < (event_date) then
			delete;
	run;

%mend;

%macro run_perchild;
	%do i = 1 %to &maxchild.;
		%perchild(&i.);
	%end;
%mend;

%run_perchild;

data temp_cor_all_ch;
	set temp_cor_child_1-temp_cor_child_&maxchild.;
keep snz_uid child_snz_uid startdate enddate countchild offence;
run;

proc sql;
create table temp_all
as select 
a.*,
b.DOB
from  temp_cor_all_ch a inner join &population b
on a.child_snz_uid=b.snz_uid;

Data TEMP_all; set TEMP_ALL;
array cg_&sex._cust_at_age_(*) cg_&sex._cust_at_age_&firstage.-cg_&sex._cust_at_age_&maxage.;
array cg_&sex._comm_at_age_(*) cg_&sex._comm_at_age_&firstage.-cg_&sex._comm_at_age_&maxage.;
array cg_&sex._comm_(*) cg_&sex._comm_&first_anal_yr.-cg_&sex._comm_&last_anal_yr.;
array cg_&sex._cust_(*) cg_&sex._cust_&first_anal_yr.-cg_&sex._cust_&last_anal_yr.;

do ind=&firstage. to &maxage.;
		i=ind-(&firstage.-1);

		start_window=intnx('YEAR',DOB,i-1,'S');
		end_window=intnx('YEAR',DOB,i,'S');
			cg_&sex._cust_at_age_(i)=0;
			cg_&sex._comm_at_age_(i)=0;

		cg_&sex._cust_at_birth = 0;
		cg_&sex._comm_at_birth = 0;	
		minus5 = intnx('YEAR',dob,-5,'sameday');


		if not((startdate > end_window) or (enddate < start_window)) then do;
					
					if (startdate <= start_window) and  (enddate > end_window) then
						days=(end_window-start_window)+1;
					else if (startdate <= start_window) and  (enddate <= end_window) then
						days=(enddate-start_window)+1;
					else if (startdate > start_window) and  (enddate <= end_window) then
						days=(enddate-startdate)+1;
					else if (startdate > start_window) and  (enddate > end_window) then
						days=(end_window-startdate)+1;	

					if offence ='COR_COMM' and days>0 then cg_&sex._comm_at_age_[i]=1;
					if offence ='COR_INTE' and days>0 then cg_&sex._cust_at_age_[i]=1;
		end;

		if not((startdate > DOB) or (enddate < minus5 )) then do;
					
					if (startdate <= minus5) and  (enddate > DOB) then
						days=(end_window-minus5)+1;
					else if (startdate <= minus5) and  (enddate <= DOB) then
						days=(enddate-minus5)+1;
					else if (startdate > minus5) and  (enddate <= DOB) then
						days=(enddate-startdate)+1;
					else if (startdate > minus5) and  (enddate > DOB) then
						days=(end_window-startdate)+1;	

					if offence ='COR_COMM' and days>0 then cg_&sex._comm_at_birth=1;
					if offence ='COR_INTE' and days>0 then cg_&sex._cust_at_birth=1;
		end;
end;

do ind=&first_anal_yr. to &last_anal_yr.;
			i=ind-(&first_anal_yr.-1);

			start_window=intnx('YEAR',MDY(1,1,&first_anal_yr.),i-1,'S');
			end_window=intnx('YEAR',MDY(1,1,&first_anal_yr.),i,'S')-1;

			cg_&sex._cust_(i)=0;
			cg_&sex._comm_(i)=0;
	
		if not((startdate > end_window) or (enddate < start_window)) then do;
					
					if (startdate <= start_window) and  (enddate > end_window) then
						days=(end_window-start_window)+1;
					else if (startdate <= start_window) and  (enddate <= end_window) then
						days=(enddate-start_window)+1;
					else if (startdate > start_window) and  (enddate <= end_window) then
						days=(enddate-startdate)+1;
					else if (startdate > start_window) and  (enddate > end_window) then
						days=(end_window-startdate)+1;	

					if offence ='COR_COMM' and days>0 then cg_&sex._comm_[i]=1;
					if offence ='COR_INTE' and days>0 then cg_&sex._cust_[i]=1;

					
		end;
end;

run;
proc summary data = TEMP_ALL nway;
	class child_snz_uid DOB;
	var cg_&sex._cust_at_birth cg_&sex._comm_at_birth cg_&sex._cust_at_age_0-cg_&sex._cust_at_age_&maxage. 
		cg_&sex._comm_at_age_0-cg_&sex._comm_at_age_&maxage.;
	output out =&projectlib.._&rel._cg_&sex._corr_at_age_&date.(rename= (child_snz_uid=snz_uid) drop = _:) max=;
run;

proc summary data = TEMP_ALL nway;
	class child_snz_uid DOB;
	var cg_&sex._cust_&first_anal_yr.-cg_&sex._cust_&last_anal_yr. 
		cg_&sex._comm_&first_anal_yr.-cg_&sex._comm_&last_anal_yr.;
	output out =&projectlib.._&rel._cg_&sex._corr_&date.(rename= (child_snz_uid=snz_uid) drop = _:) max=;
run;
proc datasets lib=work;
delete TEMP:;
run;
%mend;
