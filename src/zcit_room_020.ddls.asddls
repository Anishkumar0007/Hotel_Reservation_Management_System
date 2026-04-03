@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Room Header Consumption View'
@Search.searchable: true
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZCIT_ROOM_020
 provider contract transactional_query
 as projection on ZCIT_ROOM_010
{
 key RoomId,
//     RoomType,

        @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_ROOMTYPE_VH', element: 'RoomType' } }]
      RoomType,
    
     GuestName,
//     FloorNo,
//     Capacity,

      // NEW: Link the Dropdown for Floor
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_FLOOR_VH', element: 'FloorNo' } }]
      FloorNo,
      
       @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_CAPACITY_VH', element: 'Capacity' } }]
      Capacity,
     
     @Semantics.amount.currencyCode: 'Currency'
     PricePerNight,
    
     Currency,
     @Search.defaultSearchElement: true
     LocalCreatedBy,
     LocalCreatedAt,
     LocalLastChangedBy,
     LocalLastChangedAt,
     /* Associations */
     _booking : redirected to composition child ZCIT_BOOK_020
}
