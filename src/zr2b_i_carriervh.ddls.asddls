@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Carrier'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZR2B_I_CarrierVH as select from /dmo/carrier
{   
    @UI.lineItem: [{ position:10 }]
    key carrier_id as CarrierId,
    @UI.lineItem: [{ position:20 }]
    name as Name
}
