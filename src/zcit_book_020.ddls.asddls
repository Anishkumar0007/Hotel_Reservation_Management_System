@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Item Consumption View'
@Search.searchable: true
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZCIT_BOOK_020
 as projection on ZCIT_BOOK_010
{
 key RoomId,
   @EndUserText.label: 'Booking ID'   
  key BookingId,
     @Search.defaultSearchElement: true
     CheckInDate,
     CheckOutDate,
     @Semantics.amount.currencyCode: 'Currency'
     TotalAmount,
     Currency,
     BookingStatus,
     LocalCreatedBy,
     LocalCreatedAt,
     LocalLastChangedBy,
     LocalLastChangedAt,
     /* Associations */
     _room : redirected to parent ZCIT_ROOM_020
}
