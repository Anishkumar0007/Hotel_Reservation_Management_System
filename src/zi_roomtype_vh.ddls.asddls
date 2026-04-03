@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Room Type'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_ROOMTYPE_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZDO_ROOMTYPE' )
{
      @ObjectModel.text.element: ['Description']
  key cast( value_low as abap.char(20) ) as RoomType,
      text                           as Description
}
where language = $session.system_language
