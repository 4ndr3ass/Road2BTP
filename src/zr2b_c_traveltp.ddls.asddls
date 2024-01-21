@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR2B_R_TRAVELTP'
@Search.searchable: true
@ObjectModel.semanticKey: [ 'TravelID' ]
define root view entity ZR2B_C_TRAVELTP
  provider contract transactional_query
  as projection on ZR2B_R_TRAVELTP
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
  key TravelID,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Consumption.valueHelpDefinition: [{
          entity: {
              name: '/DMO/I_Agency',
              element: 'AgencyID' },
          useForValidation: true }]
      AgencyID,
      _Agency.Name              as AgencyName,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{
          entity: {
              name: '/DMO/I_Customer',
              element: 'CustomerID' },
          useForValidation: true
      }]
      CustomerID,
      _Customer.LastName        as CustomerName,

      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,

      @Consumption.valueHelpDefinition: [{
        entity: {
            name: 'I_CurrencyStdVH',
            element: 'Currency' },
        useForValidation: true
      }]
      CurrencyCode,
      Description,

      @ObjectModel.text.element: ['OverallStatusText'] //case-sensitive
      @Consumption.valueHelpDefinition: [{
        entity: {
            name: '/DMO/I_Overall_Status_VH',
            element: 'OverallStatus' },
        useForValidation: true }]
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,

      Attachment,
      MimeType,
      FileName,
      LocalLastChangedAt

}
