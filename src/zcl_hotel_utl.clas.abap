*CLASS zcl_hotel_utl DEFINITION
*  PUBLIC
*  FINAL
*  CREATE PRIVATE.
*
*  PUBLIC SECTION.
*    TYPES: BEGIN OF ty_room,
*             roomid TYPE zcit_room_id,
*           END OF ty_room,
*           BEGIN OF ty_booking,
*             roomid    TYPE zcit_room_id,
*             bookingid TYPE int4,
*           END OF ty_booking.
*    TYPES: tt_room    TYPE STANDARD TABLE OF ty_room,
*           tt_booking TYPE STANDARD TABLE OF ty_booking.
*
*    CLASS-METHODS get_instance
*      RETURNING VALUE(ro_instance) TYPE REF TO zcl_hotel_utl.
*
*    METHODS:
*      set_room_val
*        IMPORTING im_room     TYPE zcit_room_t
*        EXPORTING ex_created  TYPE abap_boolean,
*      get_room_val
*        EXPORTING ex_room     TYPE zcit_room_t,
*      set_book_val
*        IMPORTING im_booking  TYPE zcit_book_t
*        EXPORTING ex_created  TYPE abap_boolean,
*      get_book_val
*        EXPORTING ex_booking  TYPE zcit_book_t,
*      set_room_del
*        IMPORTING im_room     TYPE ty_room,
*      set_book_del
*        IMPORTING im_booking  TYPE ty_booking,
*      get_room_del
*        EXPORTING ex_rooms    TYPE tt_room,
*      get_book_del
*        EXPORTING ex_bookings TYPE tt_booking,
*      set_room_del_flag
*        IMPORTING im_del      TYPE abap_boolean,
*      get_del_flags
*        EXPORTING ex_room_del TYPE abap_boolean,
*      cleanup_buffer.
*
*  PRIVATE SECTION.
*    CLASS-DATA: gs_room_buff    TYPE zcit_room_t,
*                gs_book_buff    TYPE zcit_book_t,
*                gt_room_del     TYPE tt_room,
*                gt_book_del     TYPE tt_booking,
*                gv_room_del     TYPE abap_boolean.
*    CLASS-DATA mo_instance TYPE REF TO zcl_hotel_utl.
*ENDCLASS.
*
*CLASS zcl_hotel_utl IMPLEMENTATION.
*  METHOD get_instance.
*    IF mo_instance IS INITIAL.
*      CREATE OBJECT mo_instance.
*    ENDIF.
*    ro_instance = mo_instance.
*  ENDMETHOD.
*
*  METHOD set_room_val.
*    IF im_room-roomid IS NOT INITIAL.
*      gs_room_buff = im_room.
*      ex_created   = abap_true.
*    ENDIF.
*  ENDMETHOD.
*
*  METHOD get_room_val.
*    ex_room = gs_room_buff.
*  ENDMETHOD.
*
*  METHOD set_book_val.
*    IF im_booking IS NOT INITIAL.
*      gs_book_buff = im_booking.
*      ex_created   = abap_true.
*    ENDIF.
*  ENDMETHOD.
*
*  METHOD get_book_val.
*    ex_booking = gs_book_buff.
*  ENDMETHOD.
*
*  METHOD set_room_del.
*    APPEND im_room TO gt_room_del.
*  ENDMETHOD.
*
*  METHOD set_book_del.
*    APPEND im_booking TO gt_book_del.
*  ENDMETHOD.
*
*  METHOD get_room_del.
*    ex_rooms = gt_room_del.
*  ENDMETHOD.
*
*  METHOD get_book_del.
*    ex_bookings = gt_book_del.
*  ENDMETHOD.
*
*  METHOD set_room_del_flag.
*    gv_room_del = im_del.
*  ENDMETHOD.
*
*  METHOD get_del_flags.
*    ex_room_del = gv_room_del.
*  ENDMETHOD.
*
*  METHOD cleanup_buffer.
*    CLEAR: gs_room_buff, gs_book_buff,
*           gt_room_del, gt_book_del, gv_room_del.
*  ENDMETHOD.
*ENDCLASS.
CLASS zcl_hotel_utl DEFINITION
 PUBLIC
 FINAL
 CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_room,
             roomid TYPE zcit_room_id,
           END OF ty_room,
           BEGIN OF ty_booking,
             roomid    TYPE zcit_room_id,
             bookingid TYPE int4,
           END OF ty_booking.
    TYPES: tt_room    TYPE STANDARD TABLE OF ty_room,
           tt_booking TYPE STANDARD TABLE OF ty_booking.
    " Buffer tables for multiple records
    TYPES: tt_room_data TYPE STANDARD TABLE OF zcit_room_t,
           tt_book_data TYPE STANDARD TABLE OF zcit_book_t.
    CLASS-METHODS get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_hotel_utl.
    METHODS:
      set_room_val
        IMPORTING im_room    TYPE zcit_room_t
        EXPORTING ex_created TYPE abap_boolean,
      get_room_val
        EXPORTING ex_rooms TYPE tt_room_data,      " <-- now a table
      set_book_val
        IMPORTING im_booking TYPE zcit_book_t
        EXPORTING ex_created TYPE abap_boolean,
      get_book_val
        EXPORTING ex_bookings TYPE tt_book_data,     " <-- now a table
      set_room_del
        IMPORTING im_room TYPE ty_room,
      set_book_del
        IMPORTING im_booking TYPE ty_booking,
      get_room_del
        EXPORTING ex_rooms TYPE tt_room,
      get_book_del
        EXPORTING ex_bookings TYPE tt_booking,
      set_room_del_flag
        IMPORTING im_del TYPE abap_boolean,
      get_del_flags
        EXPORTING ex_room_del TYPE abap_boolean,
      cleanup_buffer.
  PRIVATE SECTION.
    CLASS-DATA: gt_room_buff TYPE tt_room_data,   " <-- table buffer
                gt_book_buff TYPE tt_book_data,   " <-- table buffer
                gt_room_del  TYPE tt_room,
                gt_book_del  TYPE tt_booking,
                gv_room_del  TYPE abap_boolean.
    CLASS-DATA mo_instance TYPE REF TO zcl_hotel_utl.
ENDCLASS.
CLASS zcl_hotel_utl IMPLEMENTATION.
  METHOD get_instance.
    IF mo_instance IS INITIAL.
      CREATE OBJECT mo_instance.
    ENDIF.
    ro_instance = mo_instance.
  ENDMETHOD.
  METHOD set_room_val.
    IF im_room-roomid IS NOT INITIAL.
      " Update existing entry or append new one
      DELETE gt_room_buff WHERE roomid = im_room-roomid.
      APPEND im_room TO gt_room_buff.
      ex_created = abap_true.
    ENDIF.
  ENDMETHOD.
  METHOD get_room_val.
    ex_rooms = gt_room_buff.
  ENDMETHOD.
  METHOD set_book_val.
    IF im_booking IS NOT INITIAL.
      " Update existing entry or append new one
      DELETE gt_book_buff
        WHERE roomid    = im_booking-roomid
          AND bookingid = im_booking-bookingid.
      APPEND im_booking TO gt_book_buff.
      ex_created = abap_true.
    ENDIF.
  ENDMETHOD.
  METHOD get_book_val.
    ex_bookings = gt_book_buff.
  ENDMETHOD.
  METHOD set_room_del.
    APPEND im_room TO gt_room_del.
  ENDMETHOD.
  METHOD set_book_del.
    APPEND im_booking TO gt_book_del.
  ENDMETHOD.
  METHOD get_room_del.
    ex_rooms = gt_room_del.
  ENDMETHOD.
  METHOD get_book_del.
    ex_bookings = gt_book_del.
  ENDMETHOD.
  METHOD set_room_del_flag.
    gv_room_del = im_del.
  ENDMETHOD.
  METHOD get_del_flags.
    ex_room_del = gv_room_del.
  ENDMETHOD.
  METHOD cleanup_buffer.
    CLEAR: gt_room_buff, gt_book_buff,
           gt_room_del,  gt_book_del,
           gv_room_del.
  ENDMETHOD.
ENDCLASS.

