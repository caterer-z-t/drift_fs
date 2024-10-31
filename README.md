# DRIFT_FS

## setup working env

``` bash
deactivate
module load python/3.10.2
module load anaconda 
module load R/4.4.0
conda activate stanislawski_lab
```

## dataset information
`BetaDiversity_DMs.RData` - This has 3 beta-diversity distance matrices: Weighted UniFrac, unweighted UniFrac, and aitchison

`PhyloseqObj.RData` - This has the data saved as Phyloseq objects at the ASV level - as count data (drift.phy.count), rarefied count data (drift.phy.count.r21116 ), CLR transformed (drift.phy.clr), and relative abundance (drift.phy.ra)

`Genus_Sp_tables.RData` - this has genus and species level tables (count, relative abundance, and CLR)

`meta_long.RData` - this is a long file with numerous records for each person - one per study visit timepoint.  It can be merged with the taxa tables (by SampleID) since those are also long files. Alpha diversity metrics are in here, as well as clinical meaures, psychosocial, etc.

`meta_wide.RData` - this is a wide file with one record per person with change in outcome measures between timepoints 
