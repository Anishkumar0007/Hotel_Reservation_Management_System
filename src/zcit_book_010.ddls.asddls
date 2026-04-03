@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Child Interface View for Booking'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
 serviceQuality: #X,
 sizeCategory: #S,
 dataClass: #MIXED
}
define view entity ZCIT_BOOK_010
 as select from zcit_book_t
 association to parent ZCIT_ROOM_010 as _room
   on $projection.RoomId = _room.RoomId
{
 key roomid                    as RoomId,
  @EndUserText.label: 'Booking ID'   
 key bookingid                 as BookingId,
     checkindate               as CheckInDate,
     checkoutdate              as CheckOutDate,
     @Semantics.amount.currencyCode: 'Currency'
     totalamount               as TotalAmount,
     currency                  as Currency,
     bookingstatus             as BookingStatus,
     @Semantics.user.createdBy: true
     local_created_by          as LocalCreatedBy,
     @Semantics.systemDateTime.createdAt: true
     local_created_at          as LocalCreatedAt,
     @Semantics.user.lastChangedBy: true
     local_last_changed_by     as LocalLastChangedBy,
     @Semantics.systemDateTime.localInstanceLastChangedAt: true
     local_last_changed_at     as LocalLastChangedAt,
     /* Associations */
     _room
}
