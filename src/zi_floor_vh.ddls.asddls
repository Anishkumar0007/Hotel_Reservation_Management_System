@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Floor'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_FLOOR_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZDO_FLOOR' )
{
      @ObjectModel.text.element: ['Description']
  key cast( value_low as abap.int2 ) as FloorNo,
      text                           as Description
}
where language = $session.system_language
