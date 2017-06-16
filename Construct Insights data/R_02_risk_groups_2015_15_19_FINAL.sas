
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
		value daysdur
			.,low-0='none  '
			0<-180='6 mths or less'
			180<-365='6mo to 1 yr '
			365<-730='1yr to 2yrs'
			730<-high='2 yrs plus'
			;
	value specialf
	500,503,507,510,514,518,519,522,523,525,540,650,662,663,664,665,666,667,668,1007,1057,
	1209,1210,1379,1397,1415,1435,1472,1483,1484,1517,1551,1556,1574,1630,1631, 1632,1712,1726, 1732,
	1762,1772,1891,1901,2334,2340,2558,2565,2588,2830,2872,2938,3202,3275,3339,3349,3433,3554,3814,
	3816,4011,4156,4157,4925, 4926,4927,4929,4930,4931,4932,4933,4934,5570='Special School'
	other='Other School'
	;

%macro impute(varname,vars,num_vars,start,forwards,char,missval);

		array &varname._arr  (%eval(&num_vars.)) &char. &vars.;
		X_&varname.= &varname._arr(%eval(&start.));

		* go backwards to find earlier TLA for missing cases;
		do i=  %eval(&start.-1) to 1 by -1;
			if x_&varname.=&missval. then
				X_&varname.= &varname._arr(i);
		end;

		%if &forwards.=1 %then %do;
		* go forwards if still missing;
		do i= %eval(&start.+1) to &num_vars.;
			if x_&varname.=&missval. then
				X_&varname.= &varname._arr(i);
		end;
		%end;
%mend;

%macro Create_risk_factors_15_19(population,by_year);

data project.risk_factors_&by_year._15_19;
	merge  &population (in=inframe where=(15<=age<=19 ))
	    	inputlib._ind_ben_child_20161021(in=inbdd_aschild)
	    	inputlib._ind_ben_adult_20161021(in=inbdd_asadult)
   		    inputlib._ind_cyf_child_20161021(in=incyf_aschild)   
   		    inputlib._ind_interv_20161021(in=insch_interv)   
			inputlib._IND_SCH_ATTENDED_20161021(in=insch_attend)
			inputlib._IND_SCH_qual_20161021(in=insch_qual)
            inputlib._all_cg_1_corr_20161021(in=incorr_cg1)   
            inputlib._all_cg_2_corr_20161021(in=incorr_cg2)
		    inputlib._IND_CORR_20161021(in=incorr)
			inputlib._ind_parent_at_age_20161021(in=in_young_parent)
			inputlib._ind_mh_prim_20161021(in=inmhealth) 
            inputlib.childtoparentmap_20161021(in=india_parent where=(source='dia' and parent1_spine=1 and parent2_spine=1)) 
		   ;
	by snz_uid;

* demographics;

		X_gender=1*sex;
        dateofbirth=mdy(snz_birth_month_nbr,15,snz_birth_year_nbr );


* CYF indicators;

     X_child_not=sum(of ch_not_1990-ch_not_&by_year.)>0;
     X_child_cyf_place=sum( of ch_CYF_place_1990-ch_CYF_place_&by_year.)>0;
     X_child_yj_place=sum( of ch_yj_place_1990-ch_yj_place_&by_year.)>0;
     X_child_yj_referral=sum( of ch_yj_referral_1990-ch_yj_referral_&by_year.)>0;

* school indicators;

     X_stand_da=sum( of stand_enr_da_1990-stand_enr_da_&by_year.);
     X_sedu_da=sum( of sedu_enr_da_1990-sedu_enr_da_&by_year.);

    %impute(school_number,school_in_2006-school_in_&by_year.,%EVAL(&BY_YEAR-2005),%EVAL(&BY_YEAR-2005),0,,.);

 	x_special_school= put(X_school_number,specialf.)='Special School';

    X_highest_qualification=max(of ncea_l1_2006-ncea_l1_%EVAL(&BY_YEAR.-1),of ncea_l2_2006-ncea_l2_%EVAL(&BY_YEAR.-1),of ncea_l3_2006-ncea_l3_%EVAL(&BY_YEAR.-1))=1;


* welfare indicators;
     X_ch_total_da_onben=sum(of ch_total_da_onben_1993-ch_total_da_onben_&by_year.);


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
		else   X_main_bentype='none  ';



max_da_&by_year.=max(da_yp_&by_year.,da_YPp_&by_year., da_spsr_&by_year., da_slp_c_&by_year., 	da_slp_hcd_&by_year., da_jshcd_&by_year., da_jswr_&by_year., da_jswr_tr_&by_year., 	da_oth_&by_year.);

		if max_da_&by_year. in (0,.) then
					X_main_bentype_last_yr='NONE ';
		ELSE if da_yp_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='YP    ';
		else if da_ypp_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='YPp   ';
		else if da_spsr_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='spsr  ';
		else if da_slp_c_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='slp_c ';
		else if da_slp_hcd_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='slp_hcd';
		else if da_jshcd_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='jshcd  ';
		else if da_jswr_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='jswr   ';
		else if da_jswr_tr_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='jswr_tr';
		else if da_oth_&by_year.=max_da_&by_year. then
			X_main_bentype_last_yr='oth   ';
		else X_main_bentype_last_yr='none  ';


	if age >= 17 then ch_ben_days=17*365;
	else ch_ben_days= mdy(12,15,&by_year.)-dateofbirth;

		X_prop_onben_aschild = (X_ch_total_da_onben) /ch_ben_days;
		X_prop_onben_aschild_cat=put(X_prop_onben_aschild,bendur.);
     
		X_total_da_onben=SUM(OF total_da_onben_1993-total_da_onben_&by_year.);

        X_duration_on_ben=put(X_total_da_onben,daysdur.);

* corrections indicators;
X_ever_onben_aschild=inbdd_aschild;
dia_parent=india_parent;


	 if inbdd_aschild=0 and india_parent=0 then X_cg_community=2;
     else X_cg_community=sum(of cg_1_comm_1988-cg_1_comm_&by_year.,of cg_2_comm_1988-cg_2_comm_&by_year.)>0;

	 if inbdd_aschild=0 and india_parent=0 then X_cg_community=2;
     else X_cg_custody=sum(of cg_1_cust_1988-cg_1_cust_&by_year.,of cg_2_cust_1988-cg_2_cust_&by_year.)>0;


  IF (age<=16) or sum(of CORR_CUST_1990-CORR_CUST_&by_year.,of CORR_HD_1990-CORR_HD_&by_year.)<=0 THEN X_offending_CUSTODY ='none';
    ELSE X_offending_CUSTODY ='Some';

  if (age<=16) or sum(of CORR_COMM_1990-CORR_COMM_&by_year.)<=0 then X_offending_Community='none';
  else X_offending_Community='Some';


* health indicators;

x_oth_act=sum(of oth_mh_2003-oth_mh_%EVAL(&BY_YEAR.-1))>0;

x_parent_less_19=sum(of mother_at_age_10-mother_at_age_18,of father_at_age_10-father_at_age_18)>0;

* risk group code;

if (sum(X_prop_onben_aschild_cat in ('76-85%','86-95%','95%+'),X_cg_community=1,(X_child_not=1))=3) or x_child_cyf_place=1 then childhood_risk = 1;
else childhood_risk = 0;


if  x_gender=1 and (( not(X_offending_custody='none' and X_offending_community='none') and age in (18,19)) or 
                              ((X_child_yj_referral=1 or x_child_yj_place=1) and age in (15,16,17,18,19)) 
                                                        or ((X_cg_custody=1) and age in (15,16,17))) then male_offenders = 1;
else male_offenders = 0;

sedu=x_SEDU_DA>0;
main_bentype_last_yr =x_main_bentype_last_yr in ('slp_h' /*,'Other'*/) and age in (17,18,19);

* Early Benefit Health;
if  (x_main_bentype_last_yr in ('slp_h' /*,'Other'*/) and age in (17,18,19))
       or x_SEDU_DA>0 or X_special_school then slp = 1;
   else slp = 0;

stand=x_stand_da>0;

* Mental Health;
if  ( x_oth_act>0 and sum(x_child_not>0,x_stand_da>0)>=1  and age in (15,16,17)) then proxy_health2 = 1;
else proxy_health2 = 0;

* female long term benefit;

if  X_gender=2 and (X_highest_qualification<1) and ( (x_parent_less_19 or x_main_bentype_last_yr='spsr')
or (age in (15,16,17) and x_prop_onben_aschild_cat='95%+' and x_child_not=1)
or (X_duration_on_ben in ('1yr to 2yrs','2 yrs plus','6 mths or less','6mo to 1 yr') and age=16)
or (X_duration_on_ben in ('1yr to 2yrs','2 yrs plus','6mo to 1 yr') and age=17)
or (X_duration_on_ben in ('1yr to 2yrs','2 yrs plus') and age=18)
or (X_duration_on_ben in ('2 yrs plus') and age = 19 )) then longben = 1;
else longben = 0;
			TG1519_slp=slp;
			TG1519_proxy_health2=proxy_health2;
			TG1519_longben=longben;
			TG1519_male_offenders=male_offenders;
			TG1519_childhood_risk=childhood_risk;
			if slp=1 or proxy_health2=1 or longben=1 or male_offenders=1 or childhood_risk=1 then InOne15=1; else InOne15=0;

			risk_1=TG1519_slp;
			risk_2=TG1519_proxy_health2;
			risk_3=TG1519_longben;
			risk_4=TG1519_male_offenders;
			risk_5=TG1519_childhood_risk;
			risk_6=InOne15;

if not inframe then	delete;

		
			keep snz_uid TG: InOne15 risk_:;
run;
%mend;
