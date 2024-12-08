# Ondemand
https://ondemand-rmacc.rc.colorado.edu
`~ ssh zaca2954@login.rc.colorado.edu`

# taxa dataset
`Genus_Sp_tables.RData`

### how to enter a compute node
``` bash
acompile
# --time=12:00:00
```

tonya brunetti

- couldnt you get clr from the information from the count matricies to get ra, then ra to clr?

- use these genetic risk scores and actial bmi
- genetic predicted bmi to actal bmi   
    - dig into the predctors of this difference
    - quantify the dots which are far apart differ in other metrics
    - which features are different between the groups of the bmi risk scores differ to actual bmi

- bmi diff cont:
    difference between bmi and predicted
    does the microbiome predict this?
    people with huge difference bween genetics and acutal then environmental factors are more contributing than genetics
    rf, lasso
    mircobiome data: taxa, genus level
        abundance of those taxa
        (acromancia?)
    what is the feature? what does it do? why is it involved?
    functional pathways:
        16s rna seq
            guess which microbes and what they are doing

    dataset, estimate of the microbes metaboltes can produce
    metaboloticoms (blood) dataset

    overall cohort is longitutudinal (150 rows -150 people vs ~500 rows - longitudinal analysis)
    time points: baseline, 3, 6, 12, (18?) months
    2 interventions: intermitent fasting, caloric restriction
    5 cohorts: all people start in same cohort end (except cohort 3) at same time
    usually include age, sex, cohort, race, ethcity
    
    - if missing genetics, if consent is n, then (potentially dont include)


# 2024/10/21
## TODO:
    - write script that takes the features and goes back to the column names
can genus count (or ra) predict drift -- need to look if ra and count are different values
can species count (or ra) predict drift -- ^ see above
what other latent factors might be involved and could predict drift (height, sex, age, etc) -- some of these contain missing values, what to do if we wanted to include this analysis? inlcude age, race, sex, ethnicity, cohort (covid and some not)
-- lasso, normalize
what does:
    - wbtot: whole body total fat 
    - rmr-kcald_bl: resting metabolic rate (want to include --maybe predictor)
    - spk_EE_int_kcal_day: energy expenditure?
    - HOMA_ir: homeostatic (model assessment) measure of insulin resistance (maybe predictor?)- do taxa predict this also
    - bes-score: its a score
how are species are genus connected, do we want to combine these matricies, if so how would we do this (primarly use genus dataset, interested to see species data but not important)
could be interesting to get the drift scores for the multiple time series then compare these values with the others, addiitonally to check the features from the multiple time series. 
how did we acquire the pc, and bugpc values? (pc from genetic data, genetic ancestry, potentially include as predictors) --ask emily about bug(pc)
do we want to do any preprocessing? normalizaiton? need to look
if we want to look at latent factors, how do we want to deal with missing values?
how many features do we want to compare, 10, 100, 500? (plot importance scores -- eyeball break)
there are 152 patients that consented and 4 that did not, what do we want to do with the patients that did not consent? remove them? (not consented for blood, remove for now)
in lab meeting today maggie mentioned that a low diversity is often associated with obesity, why?

-- look at rfe output directly
-- rf take out some features based on certain cutoffs (subset taxa)
-- lasso will give b value 
-- rfe is a feature selection technique, will select number of features for us
-- train and testing datasets -- 70/30% try to be consistent with seeds -- kfold

best performing regression models
genus clr:
    - lasso
    - lgbmressor
    - elastic net

# 2024/10/29

-- currently running into an issue extracting the features and their feature importance score. if the r version is built out better I might use this instead however I could also just program the regression models we want specifically and we can fine tune the exact details
-- working on getting working env set up with r and necessary dependencies, could be easier to do it in python
- leave height out
- stick with clr
- standardize for N(0,1)
- rf, lasso, lasso w/ ridge, alpha = 0, 1, 0.5
- lasso B value gives you direction of association
- beeswarm plots using shap
adjust predicted bmi minus bmi

- make some figures with the results for featuers and beta values

# 2024/11/13
- [x] restructre df, ph: species/genus:
- [x] try species level data (not include speceis and genus together)
- maybe try classification rather than 
$$
\text{If } \forall x < 0 \; \text{maps to } 0, \quad \text{then } \forall x > 0 \; \text{maps to } 1.
$$

    - classification model ~ 60%, maybe we can use the extreme cases and convert them to binary 
    ![]()
- check if functional information improves model - email em for functional dataset (kegg, and table ko's -- kegg orthologs)
- most interested in R^2, rn RF is performing the best
- caretEnsemble() -- RF, (not helpful to include all enet -- balance between them, ridge, lasso), maybe xgboost
- maybe 12 month difference (use 12m taxa and clinical factors)
- include beta values (not super informative, maybe include) -- get better method first
- include heatmaps



## thoughts
predictor (actual bmi - genetic bmi)

predictor (12m bmi - bl bmi)
12m -- all predictors would all be the same at 12m not bl
look at change in bl to 12m, how the change is shifting
(12m - grs) = predictors 

(12m - grs) - (bl - grs) = (12m - bl) -> using all predictors at 12m @emily

# 2024/11/20

## remove taxa (features)
- 1. figure out which ones are 20% or more (of people) from count or RA (if 0 then remove)
- 2. Max for every taxa, if max ra is 0.1 (or smaller, not much variability)

PCOA - unifrac, bray curtis

easy way to make the prs better? current method is biased

models dont peform well when there is too much info, cut out 20% - 80% 0's
ideal have ~100-2000 features for function

taxa genus 100-200
taxa species 100-600

from KO results use the description

try pathways_out/*