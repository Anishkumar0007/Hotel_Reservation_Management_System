CLASS lhc_Room DEFINITION INHERITING FROM cl_abap_behavior_handler.
 PRIVATE SECTION.
   METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
     IMPORTING keys REQUEST requested_authorizations FOR Room RESULT result.
   METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
     IMPORTING REQUEST requested_authorizations FOR Room RESULT result.
   METHODS create FOR MODIFY
     IMPORTING entities FOR CREATE Room.
   METHODS update FOR MODIFY
     IMPORTING entities FOR UPDATE Room.
   METHODS delete FOR MODIFY
     IMPORTING keys FOR DELETE Room.
   METHODS read FOR READ
     IMPORTING keys FOR READ Room RESULT result.
   METHODS lock FOR LOCK
     IMPORTING keys FOR LOCK Room.
   METHODS rba_Booking FOR READ
     IMPORTING keys_rba FOR READ Room\_booking FULL result_requested
     RESULT result LINK association_links.
   METHODS cba_Booking FOR MODIFY
     IMPORTING entities_cba FOR CREATE Room\_booking.
    METHODS setPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Room~setPrice.

ENDCLASS.
CLASS lhc_Room IMPLEMENTATION.


  METHOD get_global_authorizations.
    " Allow Create globally so the 'Create' button appears
    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    " Allow Update and Delete for all instances so 'Edit' and 'Delete' buttons appear
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( %tky    = ls_key-%tky
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed ) TO result.
    ENDLOOP.
  ENDMETHOD.

  " ... (Keep your lock, create, update, delete, read, etc. methods exactly as they are)
 METHOD lock.                        ENDMETHOD.
 METHOD create.
   DATA ls_room TYPE zcit_room_t.
   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
   LOOP AT entities INTO DATA(ls_entity).
     ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
     IF ls_room-roomid IS INITIAL.
       CONTINUE.
     ENDIF.
     SELECT SINGLE FROM zcit_room_t FIELDS roomid
       WHERE roomid = @ls_room-roomid
       INTO @DATA(lv_exists).
     IF sy-subrc NE 0.
       " Just buffer — do NOT touch mapped here
       lo_util->set_room_val(
         EXPORTING im_room    = ls_room
         IMPORTING ex_created = DATA(lv_created) ).
     ELSE.
       APPEND VALUE #(
         %cid = ls_entity-%cid
         roomid = ls_room-roomid )
         TO failed-room.
       APPEND VALUE #(
         %cid = ls_entity-%cid
         roomid = ls_room-roomid
         %msg = new_message(
           id       = 'ZCIT_HOTEL_MSG'
           number   = 002
           v1       = 'Room ID already exists'
           severity = if_abap_behv_message=>severity-error ) )
         TO reported-room.
     ENDIF.
   ENDLOOP.
 ENDMETHOD.
 METHOD update.
   DATA ls_room TYPE zcit_room_t.
   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
   LOOP AT entities INTO DATA(ls_entity).
     ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
     IF ls_room-roomid IS INITIAL.
       CONTINUE.
     ENDIF.
     " Just buffer the updated values — do NOT touch mapped here
     lo_util->set_room_val(
       EXPORTING im_room    = ls_room
       IMPORTING ex_created = DATA(lv_created) ).
   ENDLOOP.
 ENDMETHOD.
 METHOD delete.
   DATA ls_room TYPE zcl_hotel_utl=>ty_room.
   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
   LOOP AT keys INTO DATA(ls_key).
     CLEAR ls_room.
     ls_room-roomid = ls_key-roomid.
     lo_util->set_room_del( EXPORTING im_room = ls_room ).
     lo_util->set_room_del_flag( EXPORTING im_del = abap_true ).
   ENDLOOP.
 ENDMETHOD.
 METHOD read.
   LOOP AT keys INTO DATA(ls_key).
     SELECT SINGLE FROM zcit_room_t FIELDS *
       WHERE roomid = @ls_key-roomid
       INTO @DATA(ls_room).
     IF sy-subrc = 0.
       APPEND CORRESPONDING #( ls_room ) TO result.
     ENDIF.
   ENDLOOP.
 ENDMETHOD.
 METHOD rba_Booking.
   LOOP AT keys_rba INTO DATA(ls_key).
     SELECT FROM zcit_book_t FIELDS *
       WHERE roomid = @ls_key-roomid
       INTO TABLE @DATA(lt_bookings).
     LOOP AT lt_bookings INTO DATA(ls_book).
       APPEND CORRESPONDING #( ls_book ) TO result.
       APPEND VALUE #(
         source-roomid    = ls_key-roomid
         target-roomid    = ls_book-roomid
         target-bookingid = ls_book-bookingid )
         TO association_links.
     ENDLOOP.
   ENDLOOP.
 ENDMETHOD.
 METHOD cba_Booking.
   DATA ls_book TYPE zcit_book_t.
   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
   LOOP AT entities_cba INTO DATA(ls_cba).
     LOOP AT ls_cba-%target INTO DATA(ls_target).
       ls_book = CORRESPONDING #( ls_target MAPPING FROM ENTITY ).
       ls_book-roomid = ls_cba-%key-roomid.
       IF ls_book-roomid IS INITIAL OR ls_book-bookingid IS INITIAL.
         CONTINUE.
       ENDIF.
       SELECT SINGLE FROM zcit_book_t FIELDS bookingid
         WHERE roomid    = @ls_book-roomid
           AND bookingid = @ls_book-bookingid
         INTO @DATA(lv_bk_exists).
       IF sy-subrc NE 0.
         " Just buffer — do NOT touch mapped here
         lo_util->set_book_val(
           EXPORTING im_booking = ls_book
           IMPORTING ex_created = DATA(lv_created) ).
       ELSE.
         APPEND VALUE #(
           %cid      = ls_target-%cid
           roomid    = ls_book-roomid
           bookingid = ls_book-bookingid )
           TO failed-booking.
         APPEND VALUE #(
           %cid   = ls_target-%cid
           roomid = ls_book-roomid
           %msg = new_message(
             id       = 'ZCIT_HOTEL_MSG'
             number   = 002
             v1       = 'Duplicate Booking ID'
             severity = if_abap_behv_message=>severity-error ) )
           TO reported-booking.
       ENDIF.
     ENDLOOP.
   ENDLOOP.
 ENDMETHOD.

 METHOD setPrice.
    " 1. Read the selected Room Type from the UI/Draft
    READ ENTITIES OF zcit_room_010 IN LOCAL MODE
      ENTITY Room
        FIELDS ( RoomType )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rooms).

    DATA: lt_update_rooms TYPE TABLE FOR UPDATE zcit_room_010\\Room.

    " NEW: Declare the price variable referencing your exact database table field
    DATA: lv_price TYPE zcit_room_t-pricepernight.

    " 2. Loop through and assign the price based on RoomType
    LOOP AT lt_rooms INTO DATA(ls_room).
      CLEAR lv_price. " Reset for each loop

      CASE ls_room-RoomType.
        WHEN 'SINGLE'.
          lv_price = 1000.
        WHEN 'DOUBLE'.
          lv_price = 2000.
        WHEN 'SUITE'.
          lv_price = 3000.
        WHEN 'DELUXE'.
          lv_price = 4000.
      ENDCASE.

      " 3. If a valid price was found, prepare it for update
      IF lv_price > 0.
        APPEND VALUE #( %tky          = ls_room-%tky
                        PricePerNight = lv_price ) TO lt_update_rooms.
      ENDIF.
    ENDLOOP.

    " 4. Update the PricePerNight field in the Draft/Active table
    IF lt_update_rooms IS NOT INITIAL.
      MODIFY ENTITIES OF zcit_room_010 IN LOCAL MODE
        ENTITY Room
          UPDATE FIELDS ( PricePerNight )
          WITH lt_update_rooms.
    ENDIF.
  ENDMETHOD.

ENDCLASS.



*CLASS lhc_Room DEFINITION INHERITING FROM cl_abap_behavior_handler.
*  PRIVATE SECTION.
*    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR Room RESULT result.
*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR Room RESULT result.
*    METHODS create FOR MODIFY
*      IMPORTING entities FOR CREATE Room.
*    METHODS update FOR MODIFY
*      IMPORTING entities FOR UPDATE Room.
*    METHODS delete FOR MODIFY
*      IMPORTING keys FOR DELETE Room.
*    METHODS read FOR READ
*      IMPORTING keys FOR READ Room RESULT result.
*    METHODS lock FOR LOCK
*      IMPORTING keys FOR LOCK Room.
*    METHODS rba_Booking FOR READ
*      IMPORTING keys_rba FOR READ Room\_booking FULL result_requested
*      RESULT result LINK association_links.
*    METHODS cba_Booking FOR MODIFY
*      IMPORTING entities_cba FOR CREATE Room\_booking.
*ENDCLASS.
*
*CLASS lhc_Room IMPLEMENTATION.
*  METHOD get_instance_authorizations. ENDMETHOD.
*  METHOD get_global_authorizations.   ENDMETHOD.
*  METHOD lock.                        ENDMETHOD.
*
*  METHOD create.
*    DATA ls_room TYPE zcit_room_t.
*    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*
*    LOOP AT entities INTO DATA(ls_entity).
*      ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
*
*      IF ls_room-roomid IS INITIAL.
*        CONTINUE.
*      ENDIF.
*
*      SELECT SINGLE FROM zcit_room_t FIELDS roomid
*        WHERE roomid = @ls_room-roomid
*        INTO @DATA(lv_exists).
*
*      IF sy-subrc NE 0.
*        " Just buffer — do NOT touch mapped here
*        lo_util->set_room_val(
*          EXPORTING im_room    = ls_room
*          IMPORTING ex_created = DATA(lv_created) ).
*      ELSE.
*        APPEND VALUE #(
*          %cid = ls_entity-%cid
*          roomid = ls_room-roomid )
*          TO failed-room.
*        APPEND VALUE #(
*          %cid = ls_entity-%cid
*          roomid = ls_room-roomid
*          %msg = new_message(
*            id       = 'ZCIT_HOTEL_MSG'
*            number   = 002
*            v1       = 'Room ID already exists'
*            severity = if_abap_behv_message=>severity-error ) )
*          TO reported-room.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD update.
*    DATA ls_room TYPE zcit_room_t.
*    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*
*    LOOP AT entities INTO DATA(ls_entity).
*      ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
*
*      IF ls_room-roomid IS INITIAL.
*        CONTINUE.
*      ENDIF.
*
*      " Just buffer the updated values — do NOT touch mapped here
*      lo_util->set_room_val(
*        EXPORTING im_room    = ls_room
*        IMPORTING ex_created = DATA(lv_created) ).
*
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD delete.
*    DATA ls_room TYPE zcl_hotel_utl=>ty_room.
*    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*
*    LOOP AT keys INTO DATA(ls_key).
*      CLEAR ls_room.
*      ls_room-roomid = ls_key-roomid.
*      lo_util->set_room_del( EXPORTING im_room = ls_room ).
*      lo_util->set_room_del_flag( EXPORTING im_del = abap_true ).
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD read.
*    LOOP AT keys INTO DATA(ls_key).
*      SELECT SINGLE FROM zcit_room_t FIELDS *
*        WHERE roomid = @ls_key-roomid
*        INTO @DATA(ls_room).
*      IF sy-subrc = 0.
*        APPEND CORRESPONDING #( ls_room ) TO result.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD rba_Booking.
*    LOOP AT keys_rba INTO DATA(ls_key).
*      SELECT FROM zcit_book_t FIELDS *
*        WHERE roomid = @ls_key-roomid
*        INTO TABLE @DATA(lt_bookings).
*      LOOP AT lt_bookings INTO DATA(ls_book).
*        APPEND CORRESPONDING #( ls_book ) TO result.
*        APPEND VALUE #(
*          source-roomid    = ls_key-roomid
*          target-roomid    = ls_book-roomid
*          target-bookingid = ls_book-bookingid )
*          TO association_links.
*      ENDLOOP.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD cba_Booking.
*    DATA ls_book TYPE zcit_book_t.
*    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*
*    LOOP AT entities_cba INTO DATA(ls_cba).
*      LOOP AT ls_cba-%target INTO DATA(ls_target).
*        ls_book = CORRESPONDING #( ls_target MAPPING FROM ENTITY ).
*        ls_book-roomid = ls_cba-%key-roomid.
*
*        IF ls_book-roomid IS INITIAL OR ls_book-bookingid IS INITIAL.
*          CONTINUE.
*        ENDIF.
*
*        SELECT SINGLE FROM zcit_book_t FIELDS bookingid
*          WHERE roomid    = @ls_book-roomid
*            AND bookingid = @ls_book-bookingid
*          INTO @DATA(lv_bk_exists).
*
*        IF sy-subrc NE 0.
*          " Just buffer — do NOT touch mapped here
*          lo_util->set_book_val(
*            EXPORTING im_booking = ls_book
*            IMPORTING ex_created = DATA(lv_created) ).
*        ELSE.
*          APPEND VALUE #(
*            %cid      = ls_target-%cid
*            roomid    = ls_book-roomid
*            bookingid = ls_book-bookingid )
*            TO failed-booking.
*          APPEND VALUE #(
*            %cid   = ls_target-%cid
*            roomid = ls_book-roomid
*            %msg = new_message(
*              id       = 'ZCIT_HOTEL_MSG'
*              number   = 002
*              v1       = 'Duplicate Booking ID'
*              severity = if_abap_behv_message=>severity-error ) )
*            TO reported-booking.
*        ENDIF.
*      ENDLOOP.
*    ENDLOOP.
*  ENDMETHOD.
*ENDCLASS.



*CLASS lhc_Room DEFINITION INHERITING FROM cl_abap_behavior_handler.
*  PRIVATE SECTION.
*    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR Room RESULT result.
*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR Room RESULT result.
*    METHODS create FOR MODIFY
*      IMPORTING entities FOR CREATE Room.
*    METHODS update FOR MODIFY
*      IMPORTING entities FOR UPDATE Room.
*    METHODS delete FOR MODIFY
*      IMPORTING keys FOR DELETE Room.
*    METHODS read FOR READ
*      IMPORTING keys FOR READ Room RESULT result.
*    METHODS lock FOR LOCK
*      IMPORTING keys FOR LOCK Room.
*    METHODS rba_Booking FOR READ
*      IMPORTING keys_rba FOR READ Room\_booking FULL result_requested
*      RESULT result LINK association_links.
*    METHODS cba_Booking FOR MODIFY
*      IMPORTING entities_cba FOR CREATE Room\_booking.
*ENDCLASS.
*
*
*CLASS lhc_Room IMPLEMENTATION.
*  METHOD get_instance_authorizations. ENDMETHOD.
*  METHOD get_global_authorizations.   ENDMETHOD.
*  METHOD lock.                        ENDMETHOD.
*
*  METHOD create.
*    DATA: ls_room TYPE zcit_room_t.
*    LOOP AT entities INTO DATA(ls_entity).
*      ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
*      IF ls_room-roomid IS NOT INITIAL.
*        SELECT FROM zcit_room_t FIELDS *
*          WHERE roomid = @ls_room-roomid
*          INTO TABLE @DATA(lt_room).
*        IF sy-subrc NE 0.
*          DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*          lo_util->set_room_val(
*            EXPORTING im_room    = ls_room
*            IMPORTING ex_created = DATA(lv_created) ).
*          IF lv_created EQ abap_true.
*            " %cid and %key must BOTH be filled correctly
*            APPEND VALUE #(
*              %cid   = ls_entity-%cid
*              %key   = ls_entity-%key         " <-- this line was missing
*              roomid = ls_room-roomid )
*              TO mapped-room.
*          ENDIF.
*        ELSE.
*          APPEND VALUE #( %cid = ls_entity-%cid roomid = ls_room-roomid )
*            TO failed-room.
*          APPEND VALUE #( %cid = ls_entity-%cid roomid = ls_room-roomid
*            %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
*              v1 = 'Room ID already exists'
*              severity = if_abap_behv_message=>severity-error ) )
*            TO reported-room.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD update.
*    DATA: ls_room TYPE zcit_room_t.
*    LOOP AT entities INTO DATA(ls_entity).
*      ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
*      IF ls_room-roomid IS NOT INITIAL.
*        SELECT FROM zcit_room_t FIELDS *
*          WHERE roomid = @ls_room-roomid
*          INTO TABLE @DATA(lt_room).
*        IF sy-subrc EQ 0.
*          DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*          lo_util->set_room_val(
*            EXPORTING im_room    = ls_room
*            IMPORTING ex_created = DATA(lv_created) ).
*          IF lv_created EQ abap_true.
*            APPEND VALUE #( roomid = ls_room-roomid ) TO mapped-room.
*          ENDIF.
*        ELSE.
*          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_room-roomid )
*            TO failed-room.
*          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_room-roomid
*            %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
*              v1 = 'Room not found'
*              severity = if_abap_behv_message=>severity-error ) )
*            TO reported-room.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD delete.
*    DATA ls_room TYPE zcl_hotel_utl=>ty_room.
*    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*    LOOP AT keys INTO DATA(ls_key).
*      CLEAR ls_room.
*      ls_room-roomid = ls_key-roomid.
*      lo_util->set_room_del( EXPORTING im_room = ls_room ).
*      lo_util->set_room_del_flag( EXPORTING im_del = abap_true ).
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD read.
*    LOOP AT keys INTO DATA(ls_key).
*      SELECT SINGLE FROM zcit_room_t FIELDS *
*        WHERE roomid = @ls_key-roomid
*        INTO @DATA(ls_room).
*      IF sy-subrc = 0.
*        APPEND CORRESPONDING #( ls_room ) TO result.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD rba_Booking.
*    LOOP AT keys_rba INTO DATA(ls_key).
*      SELECT FROM zcit_book_t FIELDS *
*        WHERE roomid = @ls_key-roomid
*        INTO TABLE @DATA(lt_bookings).
*      LOOP AT lt_bookings INTO DATA(ls_book).
*        APPEND CORRESPONDING #( ls_book ) TO result.
*        APPEND VALUE #( source-roomid    = ls_key-roomid
*                        target-roomid    = ls_book-roomid
*                        target-bookingid = ls_book-bookingid )
*          TO association_links.
*      ENDLOOP.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD cba_Booking.
*    DATA ls_book TYPE zcit_book_t.
*    LOOP AT entities_cba INTO DATA(ls_cba).
*      LOOP AT ls_cba-%target INTO DATA(ls_target).         " <-- loop all targets
*        ls_book = CORRESPONDING #( ls_target MAPPING FROM ENTITY ).
*        ls_book-roomid = ls_cba-%key-roomid.               " <-- inherit parent key
*        IF ls_book-roomid IS NOT INITIAL AND ls_book-bookingid IS NOT INITIAL.
*          SELECT FROM zcit_book_t FIELDS *
*            WHERE roomid    = @ls_book-roomid
*              AND bookingid = @ls_book-bookingid
*            INTO TABLE @DATA(lt_book).
*          IF sy-subrc NE 0.
*            DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*            lo_util->set_book_val(
*              EXPORTING im_booking = ls_book
*              IMPORTING ex_created = DATA(lv_created) ).
*            IF lv_created EQ abap_true.
*              APPEND VALUE #(
*                %cid      = ls_target-%cid
*                %key      = ls_target-%key             " <-- %key filled
*                roomid    = ls_book-roomid
*                bookingid = ls_book-bookingid )
*                TO mapped-booking.
*            ENDIF.
*          ELSE.
*            APPEND VALUE #( %cid = ls_target-%cid
*                            roomid    = ls_book-roomid
*                            bookingid = ls_book-bookingid )
*              TO failed-booking.
*            APPEND VALUE #( %cid = ls_target-%cid roomid = ls_book-roomid
*              %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
*                v1 = 'Duplicate Booking ID'
*                severity = if_abap_behv_message=>severity-error ) )
*              TO reported-booking.
*          ENDIF.
*        ENDIF.
*      ENDLOOP.
*    ENDLOOP.
*  ENDMETHOD.
*ENDCLASS.
*
*
*




*CLASS lhc_Room DEFINITION INHERITING FROM cl_abap_behavior_handler.
*  PRIVATE SECTION.
*    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR Room RESULT result.
*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR Room RESULT result.
*    METHODS create FOR MODIFY
*      IMPORTING entities FOR CREATE Room.
*    METHODS update FOR MODIFY
*      IMPORTING entities FOR UPDATE Room.
*    METHODS delete FOR MODIFY
*      IMPORTING keys FOR DELETE Room.
*    METHODS read FOR READ
*      IMPORTING keys FOR READ Room RESULT result.
*    METHODS lock FOR LOCK
*      IMPORTING keys FOR LOCK Room.
*    METHODS rba_Booking FOR READ
*      IMPORTING keys_rba FOR READ Room\_booking FULL result_requested
*      RESULT result LINK association_links.
*    METHODS cba_Booking FOR MODIFY
*      IMPORTING entities_cba FOR CREATE Room\_booking.
*ENDCLASS.
*
*CLASS lhc_Room IMPLEMENTATION.
*  METHOD get_instance_authorizations. ENDMETHOD.
*  METHOD get_global_authorizations.   ENDMETHOD.
*  METHOD lock.                        ENDMETHOD.
*
*  METHOD create.
*    DATA: ls_room TYPE zcit_room_t.
*    LOOP AT entities INTO DATA(ls_entity).
*      ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
*      IF ls_room-roomid IS NOT INITIAL.
*        SELECT FROM zcit_room_t FIELDS *
*          WHERE roomid = @ls_room-roomid
*          INTO TABLE @DATA(lt_room).
*        IF sy-subrc NE 0.
*          DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*          lo_util->set_room_val(
*            EXPORTING im_room    = ls_room
*            IMPORTING ex_created = DATA(lv_created) ).
*          IF lv_created EQ abap_true.
*            APPEND VALUE #( %cid = ls_entity-%cid roomid = ls_room-roomid )
*              TO mapped-room.
*            APPEND VALUE #( %cid = ls_entity-%cid roomid = ls_room-roomid
*              %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 001
*                v1 = 'Room Created Successfully'
*                severity = if_abap_behv_message=>severity-success ) )
*              TO reported-room.
*          ENDIF.
*        ELSE.
*          APPEND VALUE #( %cid = ls_entity-%cid roomid = ls_room-roomid )
*            TO failed-room.
*          APPEND VALUE #( %cid = ls_entity-%cid roomid = ls_room-roomid
*            %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
*              v1 = 'Room ID already exists'
*              severity = if_abap_behv_message=>severity-error ) )
*            TO reported-room.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD update.
*    DATA: ls_room TYPE zcit_room_t.
*    LOOP AT entities INTO DATA(ls_entity).
*      ls_room = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
*      IF ls_room-roomid IS NOT INITIAL.
*        SELECT FROM zcit_room_t FIELDS *
*          WHERE roomid = @ls_room-roomid
*          INTO TABLE @DATA(lt_room).
*        IF sy-subrc EQ 0.
*          DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*          lo_util->set_room_val(
*            EXPORTING im_room    = ls_room
*            IMPORTING ex_created = DATA(lv_created) ).
*          IF lv_created EQ abap_true.
*            APPEND VALUE #( roomid = ls_room-roomid ) TO mapped-room.
*            APPEND VALUE #( %key = ls_entity-%key
*              %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 001
*                v1 = 'Room Updated Successfully'
*                severity = if_abap_behv_message=>severity-success ) )
*              TO reported-room.
*          ENDIF.
*        ELSE.
*          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_room-roomid )
*            TO failed-room.
*          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_room-roomid
*            %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
*              v1 = 'Room not found'
*              severity = if_abap_behv_message=>severity-error ) )
*            TO reported-room.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD delete.
*    TYPES: BEGIN OF ty_room,
*           roomid TYPE ZCIT_ROOM_ID,
*           END OF ty_room.
*    DATA ls_room TYPE ty_room.
*    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*    LOOP AT keys INTO DATA(ls_key).
*      CLEAR ls_room.
*      ls_room-roomid = ls_key-roomid.
*      lo_util->set_room_del( EXPORTING im_room = ls_room ).
*      lo_util->set_room_del_flag( EXPORTING im_del = abap_true ).
*      APPEND VALUE #( %cid = ls_key-%cid_ref roomid = ls_key-roomid
*        %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 001
*          v1 = 'Room Deleted Successfully'
*          severity = if_abap_behv_message=>severity-success ) )
*        TO reported-room.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD read.
*    LOOP AT keys INTO DATA(ls_key).
*      SELECT SINGLE FROM zcit_room_t FIELDS *
*        WHERE roomid = @ls_key-roomid
*        INTO @DATA(ls_room).
*      IF sy-subrc = 0.
*        APPEND CORRESPONDING #( ls_room ) TO result.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD rba_Booking.
*    LOOP AT keys_rba INTO DATA(ls_key).
*      SELECT FROM zcit_book_t FIELDS *
*        WHERE roomid = @ls_key-roomid
*        INTO TABLE @DATA(lt_bookings).
*      LOOP AT lt_bookings INTO DATA(ls_book).
*        APPEND CORRESPONDING #( ls_book ) TO result.
*        APPEND VALUE #( source-roomid  = ls_key-roomid
*                        target-roomid  = ls_book-roomid
*                        target-bookingid = ls_book-bookingid )
*          TO association_links.
*      ENDLOOP.
*    ENDLOOP.
*  ENDMETHOD.
*
*  METHOD cba_Booking.
*    DATA ls_book TYPE zcit_book_t.
*    LOOP AT entities_cba INTO DATA(ls_cba).
*      ls_book = CORRESPONDING #( ls_cba-%target[ 1 ] ).
*      IF ls_book-roomid IS NOT INITIAL AND ls_book-bookingid IS NOT INITIAL.
*        SELECT FROM zcit_book_t FIELDS *
*          WHERE roomid    = @ls_book-roomid
*            AND bookingid = @ls_book-bookingid
*          INTO TABLE @DATA(lt_book).
*        IF sy-subrc NE 0.
*          DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*          lo_util->set_book_val(
*            EXPORTING im_booking = ls_book
*            IMPORTING ex_created = DATA(lv_created) ).
*          IF lv_created EQ abap_true.
*            APPEND VALUE #( %cid = ls_cba-%target[ 1 ]-%cid
*                            roomid    = ls_book-roomid
*                            bookingid = ls_book-bookingid )
*              TO mapped-booking.
*            APPEND VALUE #( %cid = ls_cba-%target[ 1 ]-%cid
*                            roomid = ls_book-roomid
*              %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 001
*                v1 = 'Booking Created Successfully'
*                severity = if_abap_behv_message=>severity-success ) )
*              TO reported-booking.
*          ENDIF.
*        ELSE.
*          APPEND VALUE #( %cid = ls_cba-%target[ 1 ]-%cid
*                          roomid = ls_book-roomid
*                          bookingid = ls_book-bookingid )
*            TO failed-booking.
*          APPEND VALUE #( %cid = ls_cba-%target[ 1 ]-%cid
*                          roomid = ls_book-roomid
*            %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
*              v1 = 'Duplicate Booking ID'
*              severity = if_abap_behv_message=>severity-error ) )
*            TO reported-booking.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.
*ENDCLASS.
