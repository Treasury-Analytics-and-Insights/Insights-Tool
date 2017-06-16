

proc format;
	value bendur
		.,low-0='none  '
		0<-.10='1-10% '
		.10<-.25='11-25% '
		.25<-.50='26-50%'
		.50<-.75='50-75%'
		.75<-.85='76-85%'
		.85<-.95='86-95%'
		.95<-high='95%+ '
	;

%macro Create_risk_factors_20_24(population, by_year);

data project.risk_factors_&by_year._20_24;
	merge  &population (in=inframe where=(20<=age<=24 ))
	    
	    	inputlib._ind_ben_adult_20161021(in=inbdd_asadult)
   		    inputlib._ind_cyf_child_20161021(in=incyf_aschild)   
		    inputlib._IND_CORR_20161021(in=incorr)
		
		   ;
	by snz_uid;

* demographics;

		X_gender=1*sex;
        dateofbirth=mdy(snz_birth_month_nbr,15,snz_birth_year_nbr );


* CYF indicators;

     X_child_not=sum(of ch_not_1990-ch_not_&by_year.)>0;
     X_child_yj_referral=sum( of ch_yj_referral_1990-ch_yj_referral_&by_year.)>0;

* welfare indicators;

         * create sums of days on benefit for each benefit type;
		da_YP_sum=sum(of da_yp_1993-da_yp_&by_year.);
		da_YPp_sum=sum(of da_ypp_1993-da_ypp_&by_year.);
		da_spsr_sum=sum(of da_spsr_1993-da_spsr_&by_year.);
		da_slp_c_sum=sum(of da_slp_c_1993-da_slp_c_&by_year.);
		da_slp_hcd_sum=sum(of da_slp_hcd_1993-da_slp_hcd_&by_year.);
		da_jshcd_sum=sum(of da_jshcd_1993-da_jshcd_&by_year.);
		da_jswr_sum=sum(of da_jswr_1993-da_jswr_&by_year.);
		da_jswr_tr_sum=sum(of da_jswr_tr_1993-da_jswr_tr_&by_year.);
		da_oth_sum=sum(of da_oth_1993-da_oth_&by_year.);

max_da=max(da_yp_sum,
		da_YPp_sum, 
		da_spsr_sum, 
		da_slp_c_sum, 
		da_slp_hcd_sum, 
		da_jshcd_sum, 
		da_jswr_sum, 
		da_jswr_tr_sum, 
		da_oth_sum);

		if max_da in (0,.) then
					X_main_bentype='NONE ';
		ELSE if   da_yp_sum=max_da then
			  X_main_bentype='YP    ';
		else if   da_ypp_sum=max_da then
			  X_main_bentype='YPp   ';
		else if   da_spsr_sum=max_da then
			  X_main_bentype='spsr  ';
		else if   da_slp_c_sum=max_da then
			  X_main_bentype='slp_c ';
		else if   da_slp_hcd_sum=max_da then
			  X_main_bentype='slp_hcd';
		else if   da_jshcd_sum=max_da then
			  X_main_bentype='jshcd  ';
		else if   da_jswr_sum=max_da then
			  X_main_bentype='jswr   ';
		else if   da_jswr_tr_sum=max_da then
			  X_main_bentype='jswr_tr';
		else if   da_oth_sum=max_da then
			  X_main_bentype='oth   ';
		else   X_main_bentype='NONE  ';

        if not inbdd_asadult then total_da_onben_&by_year.=0;
		else X_prop_onben_last_yr = max(min(365,total_da_onben_&by_year.) /365,0);

		X_prop_onben_last_yr_cat=put(X_prop_onben_last_yr,bendur.);


* corrections indicators;


  IF sum(of CORR_CUST_1990-CORR_CUST_&by_year.,of CORR_HD_1990-CORR_HD_&by_year.)<=0 THEN X_offending_CUSTODY ='none';
    ELSE X_offending_CUSTODY ='Some';

  if sum(of CORR_COMM_1990-CORR_COMM_&by_year.)<=0 then X_offending_Community='none';
  else X_offending_Community='Some';

  x_any_corrections_sentence=(x_offending_custody='Some' or X_offending_Community='Some');

* risk group code;

* Custodial;
if   x_offending_custody ne 'none' then yo_custodial = 1;
else yo_custodial = 0;

* Non-Custodial;
if  (x_any_corrections_sentence=1) and (x_child_yj_referral=1 or x_child_not=1) and x_offending_custody='none' then yo_noncust = 1;
else yo_noncust = 0;
* JS Poor Health/CYF;
if  x_main_bentype in ('jshcd') and x_prop_onben_last_yr_cat='95%+' 
	and (x_any_corrections_sentence=1 or x_child_yj_referral=1 or x_child_not=1) then ben_health = 1;
else ben_health = 0;
* Sole Parents;
if  x_main_bentype='spsr' and x_prop_onben_last_yr_cat='95%+' 
	and (x_child_not=1 or x_any_corrections_sentence=1 or x_child_yj_referral=1) then ben_sp = 1;
else ben_sp = 0;
* Sole Parents;
if  x_main_bentype='slp_h' and x_prop_onben_last_yr_cat in ('86-95%','95%+') then ben_ltdis = 1;
else ben_ltdis = 0;

			TG2024_yo_custodial=yo_custodial;
			TG2024_yo_noncust=yo_noncust;
			TG2024_ben_health=ben_health;
			TG2024_ben_sp=ben_sp;
			TG2024_ben_ltdis=ben_ltdis;

			if yo_custodial=1 or yo_noncust=1 or ben_health=1 or ben_sp=1 or ben_ltdis=1 then TG2024_InOne20=1; else TG2024_InOne20=0;
			risk_1=TG2024_yo_custodial;
			risk_2=TG2024_yo_noncust;
			risk_3=TG2024_ben_health;
			risk_4=TG2024_ben_sp;
			risk_5=TG2024_ben_ltdis;
			risk_6=TG2024_InOne20;
keep snz_uid TG: risk_:;

if inframe then output;
		


run;

%mend;
