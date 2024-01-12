@AbapCatalog.viewEnhancementCategory: [#NONE]
@AbapCatalog.sqlViewName: 'ZR2B_I_OVERALL'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Overall Status Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
 serviceQuality: #A,
 sizeCategory: #S,
 dataClass: #MASTER
 }
@ObjectModel.resultSet.sizeCategory: #XS 
define view ZR2B_I_Overall_Status_VH 
as select from zr2b_oall_stat


  association [0..*] to zr2b_I_Overall_Status_VH_Text as _Text on $projection.OverallStatus = _Text.OverallStatus

{
      @UI.textArrangement: #TEXT_ONLY
      @UI.lineItem: [{importance: #HIGH}]
      @ObjectModel.text.association: '_Text'
  key overall_status as OverallStatus,

      _Text
}
