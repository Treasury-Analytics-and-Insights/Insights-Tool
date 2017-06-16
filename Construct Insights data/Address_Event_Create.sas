/*
Author: Christopher Ball

Purpose: To create an event based address map for the population, and 
summarise the contents into "spells" at the same address.

Has been compared to Census 2013, seems about 80% accurate at this point
in time (with 99% coverage of the linked population).  
Weakest areas are ages 20-29, where accuracy is about 65%.
*/

proc datasets lib=work kill nolist memtype=data;
quit;

%macro Address_Import(Out = , In = , Prefix = , Source = , Date = );
Proc SQL;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	CREATE TABLE &Out. AS 
	SELECT snz_uid, input(StartDate,yymmdd10.) as StartDate format yymmdd10., 
			Region, TA, MeshBlock, snz_idi_address_register_uid, &Source. as Source
	FROM connection to  sqlservr (

		select distinct snz_uid, &Date as StartDate, &Prefix._region_code as Region, 
			&Prefix._ta_code as TA, &Prefix._meshblock_code as MeshBlock,
			snz_idi_address_register_uid 
		from &In.
		where snz_idi_address_register_uid is not NULL
		order by snz_uid

	);
	DISCONNECT FROM sqlservr ;
Quit;
%mend Address_Import;

/* Apparently linking an snz_uid on from the snz_msd_uid is too hard */
%macro Address_Import_HNZ(Out = , In = , Prefix = , Source = , Date = );
Proc SQL;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	CREATE TABLE &Out. AS 
	SELECT snz_uid, datepart(StartDate) as StartDate format yymmdd10., 
			Region, TA, MeshBlock, snz_idi_address_register_uid, &Source. as Source
	FROM connection to  sqlservr (

		select distinct b.snz_uid, a.&Date as StartDate, a.&Prefix._region_code as Region, 
			a.&Prefix._ta_code as TA, a.&Prefix._meshblock_code as MeshBlock,
			a.snz_idi_address_register_uid 
		from &In. A LEFT JOIN (select snz_uid, snz_msd_uid from security.concordance where snz_msd_uid is not NULL) B
		on A.snz_msd_uid = B.snz_msd_uid
		where A.snz_idi_address_register_uid is not NULL
		order by snz_uid, StartDate

	);
	DISCONNECT FROM sqlservr ;
Quit;
%mend Address_Import_HNZ;

%Address_Import(Out = NHIAddress, In = moh_clean.pop_cohort_nhi_address, Prefix = moh_nhi, Source = 'nhi', Date = moh_nhi_effective_date);
%Address_Import(Out = PHOAddress, In = moh_clean.pop_cohort_pho_address, Prefix = moh_adr, Source = 'pho', Date = coalesce(moh_adr_consultation_date,moh_adr_enrolment_date));
%Address_Import(Out = MOEAddress, In = moe_clean.student_per, Prefix = moe_spi, Source = 'moe', Date = moe_spi_mod_address_date);
%Address_Import(Out = IRDAddress, In = ir_clean.ird_addresses, Prefix = ir_apc, Source = 'ird', Date = ir_apc_applied_date);
%Address_Import(Out = ACCAddress, In = acc_clean.claims, Prefix = acc_cla, Source = 'acc', Date = coalesce(acc_cla_lodgement_date, acc_cla_registration_date,acc_cla_accident_date));
%Address_Import(Out = MSDRAddress, In = msd_clean.msd_residential_location, Prefix = msd_rsd, Source = 'msdr', Date = msd_rsd_start_date);

%Address_Import_HNZ(Out = HNZNAddress, In = hnz_clean.new_applications, Prefix = hnz_na, Source = 'hna', Date = hnz_na_date_of_application_date);
%Address_Import_HNZ(Out = HNZTAddress, In = hnz_clean.transfer_applications, Prefix = hnz_ta, Source = 'hnt', Date = hnz_ta_application_date);
%Address_Import_HNZ(Out = HNZRAddress, In = hnz_clean.register_snapshot, Prefix = hnz_rs, Source = 'hnr', Date = hnz_rs_snapshot_date);

* Household Economic Survey;
proc sql;
CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
create table work.HESAddress as
select snz_uid, mdy(hes_hhd_month_nbr,1,hes_hhd_year_nbr) as StartDate format yymmdd10., 
	Region, TA, MeshBlock, snz_idi_address_register_uid,  'hes' as Source
from connection to sqlservr
	( select snz_uid, hes_add_region_code as Region, hes_add_ta_code as TA, 
		hes_add_meshblock_code as MeshBlock, snz_idi_address_register_uid,
		b.hes_hhd_month_nbr, b.hes_hhd_year_nbr
		from hes_clean.hes_address A LEFT JOIN hes_clean.hes_household B
		on a.snz_hes_hhld_uid = b.snz_hes_hhld_uid
		where A.snz_idi_address_register_uid is not NULL
		order by snz_uid);
disconnect from sqlservr;
quit;

* Household Labour Force Survey - impute date at start of quarter;
proc sql;
CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
create table work.HLFSAddress as
select snz_uid, intnx('month', input(hlfs_adr_quarter_date,yymmdd10.), -2) as StartDate format yymmdd10., 
	Region, TA, MeshBlock, snz_idi_address_register_uid,  'hlf' as Source
from connection to sqlservr
	( select snz_uid, hlfs_adr_quarter_date, hlfs_adr_region_code as Region, hlfs_adr_ta_code as TA, 
		hlfs_adr_meshblock_code as MeshBlock, snz_idi_address_register_uid
		from hlfs_clean.household_address
		where snz_idi_address_register_uid is not NULL
		order by snz_uid, hlfs_adr_quarter_date);
disconnect from sqlservr;
quit;

* Census;
proc sql;
CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
create table work.CensusAddress as
select snz_uid, mdy(3,5,2013) as StartDate format yymmdd10., 
	Region, TA, MeshBlock, snz_idi_address_register_uid,  'cen' as Source
from connection to sqlservr
	( select snz_uid, region_code as Region, ta_code as TA, 
		meshblock_code as MeshBlock, snz_idi_address_register_uid
		from cen_clean.census_address 
		where address_type_code = 'UR' AND meshblock_code is not NULL 
		order by snz_uid);
disconnect from sqlservr;
quit;

* Census 5 years ago;
proc sql;
CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
create table work.CensusAddress5 as
select snz_uid, mdy(3,5,2008) as StartDate format yymmdd10., Region, TA, MeshBlock, snz_idi_address_register_uid, 'cen' as Source
from connection to sqlservr
	( select snz_uid, region_code as Region, ta_code as TA, 
		meshblock_code as MeshBlock, snz_idi_address_register_uid
		from cen_clean.census_address 
		where address_type_code = 'UR5' AND meshblock_code is not NULL 
		order by snz_uid);
disconnect from sqlservr;
quit;

* Stick them all together;
* Postal address from MSD has been removed;
data Address;
set NHIAddress PHOAddress MOEAddress IRDAddress ACCAddress MSDRAddress HNZNAddress HNZTAddress HNZRAddress HLFSAddress HESAddress CensusAddress CensusAddress5;
run;

proc datasets library=Work;
delete NHIAddress PHOAddress MOEAddress IRDAddress ACCAddress MSDRAddress HNZNAddress HNZTAddress HNZRAddress HLFSAddress HESAddress CensusAddress CensusAddress5;
run;

proc sql;
	create table Sub_Source as
	select a.*, b.AddRep
	from Address a LEFT JOIN (
		select snz_uid, snz_idi_address_register_uid, sum(0*snz_uid+1) as AddRep
		from Address
		group by snz_uid, snz_idi_address_register_uid) b
	on a.snz_uid = b.snz_uid and a.snz_idi_address_register_uid = b.snz_idi_address_register_uid
	order by snz_uid, snz_idi_address_register_uid;
quit;

proc sort data=Sub_Source;
by snz_uid StartDate descending AddRep;
run;

data Sub_Source;
	set Sub_Source;
	if snz_uid = lag(snz_uid) and StartDate = lag(StartDate) then DELETE;
run;

data Sub_Source;
	set Sub_Source;
	if snz_idi_address_register_uid = lag(snz_idi_address_register_uid) and 
		snz_uid = lag(snz_uid) then DELETE;
run;

proc sort data=Sub_Source;
	by snz_uid descending StartDate;
run;

data Sub_Source;
	format Enddate yymmdd10.;
	set Sub_Source;
	EndDate = ifn(lag(snz_uid) = snz_uid, lag(StartDate)-1, .);
run;

proc sort data= Sub_Source;
	by snz_uid StartDate;
run;

* Save to directory;
data Project.Address_Event;
	set Sub_Source;
run;
