* Draw 10^5 different sets of imputation coefficients from the posterior      ;
* density implied by the original coefficients of the JAMA article, taken     ;
* together with their variance-covariance matrix received from Nancy Sampson. ;
* Demonstrate that the mean and covariance matrix for these samples match     ;
* closely the desired values.   ;


proc iml;
  title1 "Sampling from joint posterior of PTSD model coefficients";
  title2 "(with illustrative sample printouts and checks on sample mean and covariance)";
  load their_beta their_cov CovarNames;
  call randseed(2016);
  betas_posterior_samples = RandNormal(100000, their_beta, their_cov);
  * Simply overwrite the first sample with the original beta vector ;
  betas_posterior_samples[1,] = their_beta;
  sample_labels = {"Original" "Sample 1" "Sample 2" "Sample 3" "Sample 4"};
  print(betas_posterior_samples[1:5,])[Label="Original and first 4 sampled coefficient vectors"
   colname=CovarNames rowname=sample_labels];
  create OUTPUTS.betas_samples from betas_posterior_samples[colname=CovarNames];
  append from betas_posterior_samples;
  close OUTPUTS.betas_samples;
  SampleMean = mean(betas_posterior_samples);
  SampleCov = cov(betas_posterior_samples);
  compare_means = SampleMean // their_beta;
  print compare_means[colname=CovarNames rowname={"Sample Mean" "Their Betas"}];
  print SampleCov[colname=CovarNames rowname=CovarNames];
  cov_diff = SampleCov - their_cov;
  print cov_diff[colname=CovarNames rowname=CovarNames];
  store betas_posterior_samples;


* Define the %mtoptsd macro needed by impdata20x.sas, which is    ;
* %included by the bootstrap loop below.                          ;
* --------------------------------------------------------------- ;
%include "&reanalysis/mtoptsd_macro.sas";

* Iterate over the betas_posterior_samples, constructing a model    ;
* formula for each one and passing it to the impdata20x.sas script. ;
* Collect the resulting voucher effect estimates with their CIs.    ;

proc iml;
  *title1 "Constructing PTSD imputation model formulas";
  *title2 "(to be passed one-by-one as 'formula' to Ptsd_MTO_youth.sas)";
  load betas_posterior_samples CovarNames;
  CovarNames[loc(CovarNames='Intercept')] = "1";
/*  if exist("OUTPUTS.orci") then*/
/*    edit OUTPUTS.orci;*/
/*  else */
/*	create OUTPUTS.orci var {imod seed OddsRatioEst LowerCL UpperCL};*/
  do imod = 5 to 5;
    coefs = betas_posterior_samples[imod,];
    * convert coefs to explicitly (+/-) signed strings ;
    signs = repeat(" ",1,ncol(coefs));
    signs[loc(coefs>=0)] = "+";
    coefs = catx("", signs, coefs);
    * generate formula terms, then concatenate them ;
    terms = catx("*",coefs,CovarNames`);
    formula = rowcatc(terms);
    *title1 "Passing this formula to Ptsd_MTO_youth.sas script";
    *print formula;
    *title1;
    do seed = 524238 to 524238;
      submit formula seed; * the 'formula' parameter allows substitution below;
        %LET formula=&formula; * sets a &formula macro for impdata20x.sas;
        %LET mi_seed=&seed;
        %include "&reanalysis/impdata20x.sas";
      endsubmit;
      * Extract the desired effect estimate and its CI ;
/*	  create OUTPUTS.orci var {imod seed OddsRatioEst LowerCL UpperCL};*/
/*      use ORs;*/
/*      read all var {Effect _Imputation_ OddsRatioEst LowerCL UpperCL};*/
/*      close ORs;*/
/*	  imod=1;*/
/*	  seed=1;*/
/*      effrow = loc(compbl(Effect)='ra_grp_exp'*/
/*                       & _Imputation_=.);*/
/*      OddsRatioEst = OddsRatioEst[effrow];*/
/*      LowerCL = LowerCL[effrow];*/
/*      UpperCL = UpperCL[effrow];*/
/*      append var {imod seed OddsRatioEst LowerCL UpperCL};*/
   end; * mi_seed loop ;
  end; * imod loop ;
/*  close OUTPUTS.orci;*/
Quit;


proc iml;
     use ORs;
      read all var {Effect _Imputation_ OddsRatioEst LowerCL UpperCL};
      close ORs; 
  if exist("OUTPUTS.orci") then
    edit OUTPUTS.orci;
  else 
	create OUTPUTS.orci var {imod seed OddsRatioEst LowerCL UpperCL};
	  imod=5;
	  seed=524238;
      effrow = loc(compbl(Effect)='ra_grp_exp'
                       & _Imputation_=.);
      OddsRatioEst = OddsRatioEst[effrow];
      LowerCL = LowerCL[effrow];
      UpperCL = UpperCL[effrow];
      append var {imod seed OddsRatioEst LowerCL UpperCL};
    end; * mi_seed loop ;
  end; * imod loop ;
  close OUTPUTS.orci;
