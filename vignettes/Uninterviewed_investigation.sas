/*PTSD investigations*/

%let folder = C:/Users/Anolinx/MTO;
%let reanalysis = &folder/reanalysis;
%include "&reanalysis/mtoptsd_macro.sas";

* Input data file: pre-imputation dataset (one observation for each youth);

%LET NBER = E:/NSCR_Replication_study/NBER;
%LET ncsr = E:/NSCR_Replication_study;
Libname NBER "&NBER";
LIBNAME NCSR "&ncsr";
%LET outputs = &folder/outputs;
libname OUTPUTS "&outputs";

%let preimp = NBER.Mto_jama_preimp_fixed;
%mtoptsd(&preimp,Y,preimp_xwalk ); * Crosswalk MTO-->NCSR PTSD varnames ;

%LET formula = 1*(-1.515)+AGE*(0.0263)+SEXF*(0.1105)+
			RHISP*(-0.0819)+RBLK*(-0.5597)+ROTH*(-0.9751)+PT41*(-0.5603)+
			PT42*(0.0504)+PT43*(-0.3877)+PT44*(0.1148)+PT45*(-0.1614)+
			PT46*(0.5993)+PT48*(0.078)+PT50*(0.4687)+PT50_1*(0.4591)+
			PT51*(0.1683)+PT55*(-0.2237)+PT209*(0.3664)+PT211*(-0.0581)+
			PT212*(0.2516)+PT213*(0.1159)+PT214*(0.64)+PT233*(0.8654)+PT237*(0.1323);
*/
%PUT Formula: &formula;

data vars;
set NCSR.Mental_health_yt_20150612;
format _Numeric_;
ptsd_random=ranuni(1234567);
keep PPID ptsd_random
f_svy_ethnic /*f_svy_ethnic - Ethnicity (1=Hispanic, 2=Not Hispanic) from Revised Demog File*/
f_svy_race /*f_svy_race - Race (1=AfrAm/2=Wht/3=AmInd/4=AsPacIsl/5=Oth) from Revised Demog File*/;
run;

proc sort data = vars;
by PPID; run;
proc sort data = preimp_xwalk;
by PPID; run;

data preimp_xwalk2;
format _numeric_;
merge preimp_xwalk (in=jama)  vars;
by PPID; if jama; run;

data pred_ptsd_youth;
set preimp_xwalk2;
f_mh_pts_y_yt_orig=f_mh_pts_y_yt;
Age = f_svy_age_iw;
SEXF = 1-x_f_ch_male;
 /* Race */
   rhisp = 0;
   rwh = 0;
   rblk = 0;
   roth = 0;
   if f_svy_ethnic = 1 then rhisp = 1;
   else do;
      if f_svy_race = 1 then rblk = 1;
      else if f_svy_race = 2 then rwh = 1;
      else if f_svy_race IN(3,4,5) then roth = 1;
   end;
pred_prob = exp(&formula)/(1+exp(&formula));
run;

/* Impute lifetime PTSD, then calculate 'recency' to assign 12-month diagnosis
 ******************************************************************************/


/* The code in this section was copied from the end of Ptsd_MTO_youth.sas,
 * with modifications as noted (+++) to support additional analyses.
 */

data fnlpred_ptsd_youth; *(keep = ppid f_mh_pts_evr_yt f_mh_pts_aoo_yt f_mh_pts_rec_yt f_wt_totsvy
    ptsd_random pred_prob); * (+++) last 2 vars added ;
set pred_ptsd_youth;
/* Calculate lifetime PTSD by comparing random # to predicted probability */
*ptsd_random = ranuni(1234567);
if mto_ptsd_sample = 1 and 0 < ptsd_random <= pred_prob then f_mh_pts_evr_yt = 1;
else f_mh_pts_evr_yt = 0;

******************************************************************************************
* Calculate Recency of PTSD for DSM                                                      *
******************************************************************************************;

if YCV14b_PT64a <= f_svy_age_iw then pts_ons = YCV14b_PT64a;
else pts_ons = YCV14c;

if pts_ons IN(.D, .R) then pts_ons = .;
if pts_ons > f_svy_age_iw then pts_ons = .;

if YCV22_PT261 = 1 or pts_ons = f_svy_age_iw then pts_rec = f_svy_age_iw;

if pts_rec IN(.D, .R) then pts_rec = .;

if 0 <= pts_ons < 4 then pts_ons = 4;
if 0 <= pts_rec < 4 then pts_rec = 4;

if f_mh_pts_evr_yt = 1 then do;
    f_mh_pts_aoo_yt = pts_ons;            
    f_mh_pts_rec_yt = pts_rec;

/* 12 month PTSD MTO Youth */
/* Cases where HCV14b_PT64a or HCV14c = interview age or HCV22_PT261 is Yes */

if f_mh_pts_evr_yt = 1 and
   (
      (f_svy_age_iw NOT IN(.D,.R,.) and
          (YCV14b_PT64a = f_svy_age_iw or YCV14c = f_svy_age_iw)
      ) or
      YCV22_PT261 = 1 
   ) then f_mh_pts_y_yt = 1;
else f_mh_pts_y_yt = 0;
end;

* The following lines taken from NBER 'Appendix-D' 12month-mto-youth.sas ;
/* 12 month PTSD MTO Youth */
/* Cases where HCV14b_PT64a or HCV14c = interview age or HCV22_PT261 is Yes */

if f_mh_pts_evr_yt = 1 and
   (
      (f_svy_age_iw NOT IN(.D,.R,.) and
          (YCV14b_PT64a = f_svy_age_iw or YCV14c = f_svy_age_iw)
      ) or
      YCV22_PT261 = 1 
   ) then f_mh_pts_y_yt = 1;
else f_mh_pts_y_yt = 0;
run;

ods pdf file = "&outputs/PTSD y_yt from original to final_pred.pdf";
proc freq data = fnlpred_ptsd_youth ;
tables  f_mh_pts_y_yt_orig*f_mh_pts_y_yt /norow nocol nocum nopercent missing;
run;
ods pdf close; 


data missing;
set Fnlpred_ptsd_youth; where missing(f_mh_pts_y_yt_orig);
keep PPID;
run;
proc sort data = missing;
by PPID; 
run;

data Mto_jama_imputed_20160111;
set NBER.Mto_jama_imputed_20160111;
format _numeric_;
run;

proc sort data = Mto_jama_imputed_20160111;
by PPID; 
run;

data imp_missing;
	merge missing (in=jama) Mto_jama_imputed_20160111;
	by ppid;
	* Limit to missing;
	if jama;
run;


ods pdf file = "&outputs/f_mh_pts_y_yt_crosstabs_for_Full_and_(817)Uninterviewed.pdf";

Title "Full (Mto_jama_imputed_20160111)";
proc freq data = Mto_jama_imputed_20160111;
table f_mh_pts_y_yt /nocum ;
run;

Title "817 (Uninterviewed)";
proc freq data = imp_missing;
table f_mh_pts_y_yt /nocum ;
run;
ods pdf close; 
