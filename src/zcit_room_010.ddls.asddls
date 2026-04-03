@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root Interface View for Room'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCIT_ROOM_010
 as select from zcit_room_t as Room
 composition [0..*] of ZCIT_BOOK_010 as _booking
{
 key roomid                    as RoomId,
      guestname                 as GuestName,
      roomtype                  as RoomType,
     floorno                   as FloorNo,
     capacity                  as Capacity,
     @Semantics.amount.currencyCode: 'Currency'
     pricepernight             as PricePerNight,
     currency                  as Currency,
     @Semantics.user.createdBy: true
     local_created_by          as LocalCreatedBy,
     @Semantics.systemDateTime.createdAt: true
     local_created_at          as LocalCreatedAt,
     @Semantics.user.lastChangedBy: true
     local_last_changed_by     as LocalLastChangedBy,
     @Semantics.systemDateTime.localInstanceLastChangedAt: true
     local_last_changed_at     as LocalLastChangedAt,
     /* Associations */
     _booking
}
