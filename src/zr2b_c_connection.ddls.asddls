@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR2B_R_CONNECTION'
define root view entity ZR2B_C_CONNECTION
  provider contract transactional_query
  as projection on ZR2B_R_CONNECTION
{
  key UUID,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR2B_I_CarrierVH', element: 'CarrierID' } }] CarrierID,    
  ConnectionID,
  AiportFromID,
  CityFrom,
  CountryFrom,
  AirportToID,
  CityTo,
  CountryTo,
  LocalLastChangedAt
  
}
