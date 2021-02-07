### data sources (DS: list)

# fetch all tables in the project dataset view

dataschema.tb     = DB2getTablesInSchema('SAIL0317V')

DS = list()

DS$WIMD2011           = 'SAILREFRV.WIMD2011_OVERALL_INDEX'
DS$WDS_PERS           = dataschema.tb$WDSD_AR_PERS_20181101
DS$WDS_ADDR_WALES_CLN = dataschema.tb$WDSD_CLEAN_ADD_WALES_20180410
DS$WDS_ADDR_LSOA_CLN  = dataschema.tb$WDSD_CLEAN_ADD_LSOA_20180410
DS$EDDS     = dataschema.tb$EDDS_EDDS_20181022
DS$PEDW_SS  = dataschema.tb$PEDW_SUPERSPELL_20181031
DS$PEDW_SP  = dataschema.tb$PEDW_SPELL_20181031
DS$PEDW_EP  = dataschema.tb$PEDW_EPISODE_20181031
DS$PEDW_DIAG= dataschema.tb$PEDW_DIAG_20181031
DS$PEDW_OPER= dataschema.tb$PEDW_OPER_20181031
DS$WLGP     = dataschema.tb$WLGP_GP_EVENT_ALF_CLEANSED_20180820
DS$GPREG    = dataschema.tb$WLGP_CLEAN_GP_REG_MEDIAN_20180820
DS$WLGP_subset = cohort.table %>% paste0('_WLGP_SUBSET')
DS$DEATHS   = dataschema.tb$ADDE_DEATHS_20180608
