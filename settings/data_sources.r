#------------------

### data sources (DS: list)

# fetch all tables in the project dataset view
dataschema.tb     = DB2getTablesInSchema('SAIL0317V')

DS = list()

DS$WIMD2011 = 'SAILREFRV.WIMD2011_OVERALL_INDEX'

DS$WDS_PERS           = dataschema.tb$WDSD_AR_PERS_20181101
DS$WDS_ADDR_WALES_CLN = dataschema.tb$WDSD_CLEAN_ADD_WALES_20180410
DS$WDS_ADDR_LSOA_CLN  = dataschema.tb$WDSD_CLEAN_ADD_LSOA_20180410

DS$OPD_OPT  = dataschema.tb$OPDW_OUTPATIENTS_20181101
DS$OPD_DX   = dataschema.tb$OPDW_OUTPATIENTS_DIAG_20181101
DS$OPD_OPR  = dataschema.tb$OPDW_OUTPATIENTS_OPER_20181101

DS$EDDS     = dataschema.tb$EDDS_EDDS_20181022

DS$PEDW_SS  = dataschema.tb$PEDW_SUPERSPELL_20181031
DS$PEDW_SP  = dataschema.tb$PEDW_SPELL_20181031
#DS$PEDW_SPCLN = paste0(PROJECT.WorkingSchema, '.CC1_COHORT_PEDW_SPELL_CLEANED_V')
DS$COHORT_PEDW_SP_CLN = paste0(project.working.schema, '.COHORT_COHORT_PEDW_SPELL_CLEANED')
DS$PEDW_EP  = dataschema.tb$PEDW_EPISODE_20181031
DS$PEDW_DIAG= dataschema.tb$PEDW_DIAG_20181031
DS$PEDW_OPER= dataschema.tb$PEDW_OPER_20181031

DS$WLGP     = dataschema.tb$WLGP_GP_EVENT_ALF_CLEANSED_20180820
DS$GPREG    = dataschema.tb$WLGP_CLEAN_GP_REG_MEDIAN_20180820
DS$WLGP_subset = cohort.table %>% paste0('_WLGP_SUBSET')



DS$DEATHS   = dataschema.tb$ADDE_DEATHS_20180608

#------------------

#paste0("
#call fnc.clean_gp_regs( -- Version 2.01 - 2018-08-14
#    target_table    => '", GP_REG, "',
#    log_table       => '", project.working.schema, ".", "GPREG_20180820_log',
#    gp_data_extract	=> 'SAILWLGPV.GP_EVENT_CLEANSED_20180820',
#    max_gap_to_fill=>30,
#    threshold=>.1,
#    ignore_practices_with_missing_data=>0,
#    group_on_sail_data=>1,
#    group_on_practice=>0,
#    keep_non_sail_recs=>0,
#    birth_correction=>1,
#    use_median_event_rates=>1);
#") %>% cat
