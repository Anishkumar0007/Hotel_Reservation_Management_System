CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
 PRIVATE SECTION.
   METHODS update FOR MODIFY
     IMPORTING entities FOR UPDATE Booking.
   METHODS delete FOR MODIFY
     IMPORTING keys FOR DELETE Booking.
   METHODS read FOR READ
     IMPORTING keys FOR READ Booking RESULT result.
   METHODS rba_Room FOR READ
     IMPORTING keys_rba FOR READ Booking\_room FULL result_requested
     RESULT result LINK association_links.
   " Add the determination method declaration
*    METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
*      IMPORTING keys FOR Booking~calculateTotalAmount.
      METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
     IMPORTING keys FOR Booking~calculateTotalAmount.
ENDCLASS.
CLASS lhc_Booking IMPLEMENTATION.
 METHOD update.
   DATA ls_book TYPE zcit_book_t.
   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
   LOOP AT entities INTO DATA(ls_entity).
     ls_book = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
     IF ls_book-roomid IS INITIAL.
       CONTINUE.
     ENDIF.
     " Just buffer — do NOT touch mapped here
     lo_util->set_book_val(
       EXPORTING im_booking = ls_book
       IMPORTING ex_created = DATA(lv_created) ).
   ENDLOOP.
 ENDMETHOD.
 METHOD delete.
   DATA ls_book TYPE zcl_hotel_utl=>ty_booking.
   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
   LOOP AT keys INTO DATA(ls_key).
     CLEAR ls_book.
     ls_book-roomid    = ls_key-roomid.
     ls_book-bookingid = ls_key-bookingid.
     lo_util->set_book_del( EXPORTING im_booking = ls_book ).
   ENDLOOP.
 ENDMETHOD.
 METHOD read.
 ENDMETHOD.
 METHOD rba_Room.
 ENDMETHOD.
 METHOD calculateTotalAmount.
   " 1. Read the Check-In and Check-Out Dates from the Booking draft/buffer
   READ ENTITIES OF zcit_room_010 IN LOCAL MODE
     ENTITY Booking
       FIELDS ( CheckInDate CheckOutDate RoomId )
       WITH CORRESPONDING #( keys )
     RESULT DATA(lt_bookings).
   " 2. Read the PricePerNight from the Parent (Room) using the Association
   READ ENTITIES OF zcit_room_010 IN LOCAL MODE
     ENTITY Booking BY \_room
       FIELDS ( PricePerNight )
       WITH CORRESPONDING #( keys )
     RESULT DATA(lt_rooms).
   DATA: lt_update_bookings TYPE TABLE FOR UPDATE zcit_room_010\\Booking.
   " 3. Loop through bookings to calculate the total
   LOOP AT lt_bookings INTO DATA(ls_booking)
     WHERE CheckInDate IS NOT INITIAL
       AND CheckOutDate IS NOT INITIAL.
     " Find the corresponding parent room data to get the price
     READ TABLE lt_rooms INTO DATA(ls_room) WITH KEY RoomId = ls_booking-RoomId.
     IF sy-subrc = 0.
       " Calculate the difference in days
       DATA(lv_days) = ls_booking-CheckOutDate - ls_booking-CheckInDate.
       " Ensure at least 1 day is charged if check-in and check-out are the same day
       IF lv_days <= 0.
         lv_days = 1.
       ENDIF.
       " Calculate Total Amount dynamically: Days * Room's PricePerNight
       DATA(lv_total_amount) = lv_days * ls_room-PricePerNight.
       " Prepare the update table with the calculated amount
       APPEND VALUE #( %tky        = ls_booking-%tky
                       TotalAmount = lv_total_amount ) TO lt_update_bookings.
     ENDIF.
   ENDLOOP.
   " 4. Update the Booking Entity with the calculated TotalAmount
   IF lt_update_bookings IS NOT INITIAL.
     MODIFY ENTITIES OF zcit_room_010 IN LOCAL MODE
       ENTITY Booking
         UPDATE FIELDS ( TotalAmount )
         WITH lt_update_bookings.
   ENDIF.
 ENDMETHOD.
ENDCLASS.






*CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
* PRIVATE SECTION.
*   METHODS update FOR MODIFY
*     IMPORTING entities FOR UPDATE Booking.
*   METHODS delete FOR MODIFY
*     IMPORTING keys FOR DELETE Booking.
*   METHODS read FOR READ
*     IMPORTING keys FOR READ Booking RESULT result.
*   METHODS rba_Room FOR READ
*     IMPORTING keys_rba FOR READ Booking\_room FULL result_requested
*     RESULT result LINK association_links.
*   " Add the determination method declaration
**    METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
**      IMPORTING keys FOR Booking~calculateTotalAmount.
*      METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
*     IMPORTING keys FOR Booking~calculateTotalAmount.
*ENDCLASS.
*CLASS lhc_Booking IMPLEMENTATION.
* METHOD update.
*   DATA ls_book TYPE zcit_book_t.
*   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*   LOOP AT entities INTO DATA(ls_entity).
*     ls_book = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
*     IF ls_book-roomid IS INITIAL.
*       CONTINUE.
*     ENDIF.
*     " Just buffer — do NOT touch mapped here
*     lo_util->set_book_val(
*       EXPORTING im_booking = ls_book
*       IMPORTING ex_created = DATA(lv_created) ).
*   ENDLOOP.
* ENDMETHOD.
* METHOD delete.
*   DATA ls_book TYPE zcl_hotel_utl=>ty_booking.
*   DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*   LOOP AT keys INTO DATA(ls_key).
*     CLEAR ls_book.
*     ls_book-roomid    = ls_key-roomid.
*     ls_book-bookingid = ls_key-bookingid.
*     lo_util->set_book_del( EXPORTING im_booking = ls_book ).
*   ENDLOOP.
* ENDMETHOD.
* METHOD read.
* ENDMETHOD.
* METHOD rba_Room.
* ENDMETHOD.
* METHOD calculateTotalAmount.
*   " 1. Read the Check-In and Check-Out Dates from the Booking draft/buffer
*   READ ENTITIES OF zcit_room_010 IN LOCAL MODE
*     ENTITY Booking
*       FIELDS ( CheckInDate CheckOutDate RoomId )
*       WITH CORRESPONDING #( keys )
*     RESULT DATA(lt_bookings).
*   " 2. Read the PricePerNight from the Parent (Room) using the Association
*   READ ENTITIES OF zcit_room_010 IN LOCAL MODE
*     ENTITY Booking BY \_room
*       FIELDS ( PricePerNight )
*       WITH CORRESPONDING #( keys )
*     RESULT DATA(lt_rooms).
*   DATA: lt_update_bookings TYPE TABLE FOR UPDATE zcit_room_010\\Booking.
*   " 3. Loop through bookings to calculate the total
*   LOOP AT lt_bookings INTO DATA(ls_booking)
*     WHERE CheckInDate IS NOT INITIAL
*       AND CheckOutDate IS NOT INITIAL.
*     " Find the corresponding parent room data to get the price
*     READ TABLE lt_rooms INTO DATA(ls_room) WITH KEY RoomId = ls_booking-RoomId.
*     IF sy-subrc = 0.
*       " Calculate the difference in days
*       DATA(lv_days) = ls_booking-CheckOutDate - ls_booking-CheckInDate.
*       " Ensure at least 1 day is charged if check-in and check-out are the same day
*       IF lv_days <= 0.
*         lv_days = 1.
*       ENDIF.
*       " Calculate Total Amount dynamically: Days * Room's PricePerNight
*       DATA(lv_total_amount) = lv_days * ls_room-PricePerNight.
*       " Prepare the update table with the calculated amount
*       APPEND VALUE #( %tky        = ls_booking-%tky
*                       TotalAmount = lv_total_amount ) TO lt_update_bookings.
*     ENDIF.
*   ENDLOOP.
*   " 4. Update the Booking Entity with the calculated TotalAmount
*   IF lt_update_bookings IS NOT INITIAL.
*     MODIFY ENTITIES OF zcit_room_010 IN LOCAL MODE
*       ENTITY Booking
*         UPDATE FIELDS ( TotalAmount )
*         WITH lt_update_bookings.
*   ENDIF.
* ENDMETHOD.
*ENDCLASS.
*
*
*
***CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
***  PRIVATE SECTION.
***    METHODS update FOR MODIFY
***      IMPORTING entities FOR UPDATE Booking.
***    METHODS delete FOR MODIFY
***      IMPORTING keys FOR DELETE Booking.
***    METHODS read FOR READ
***      IMPORTING keys FOR READ Booking RESULT result.
***    METHODS rba_Room FOR READ
***      IMPORTING keys_rba FOR READ Booking\_room FULL result_requested
***      RESULT result LINK association_links.
***ENDCLASS.
***
***CLASS lhc_Booking IMPLEMENTATION.
***  METHOD update.
***    DATA: ls_book TYPE zcit_book_t.
***    LOOP AT entities INTO DATA(ls_entity).
***      ls_book = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
***      IF ls_book-roomid IS NOT INITIAL.
***        SELECT FROM zcit_book_t FIELDS *
***          WHERE roomid    = @ls_book-roomid
***            AND bookingid = @ls_book-bookingid
***          INTO TABLE @DATA(lt_book).
***        IF sy-subrc EQ 0.
***          DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
***          lo_util->set_book_val(
***            EXPORTING im_booking = ls_book
***            IMPORTING ex_created = DATA(lv_created) ).
***          IF lv_created EQ abap_true.
***            APPEND VALUE #( roomid = ls_book-roomid bookingid = ls_book-bookingid )
***              TO mapped-booking.
***            APPEND VALUE #( %key = ls_entity-%key
***              %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 001
***                v1 = 'Booking Updated Successfully'
***                severity = if_abap_behv_message=>severity-success ) )
***              TO reported-booking.
***          ENDIF.
***        ELSE.
***          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_book-roomid
***                          bookingid = ls_book-bookingid )
***            TO failed-booking.
***          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_book-roomid
***            %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
***              v1 = 'Booking not found'
***              severity = if_abap_behv_message=>severity-error ) )
***            TO reported-booking.
***        ENDIF.
***      ENDIF.
***    ENDLOOP.
***  ENDMETHOD.
***
***  METHOD delete.
***    TYPES: BEGIN OF ty_booking, roomid TYPE ZCIT_ROOM_ID, bookingid TYPE int4, END OF ty_booking.
***    DATA ls_book TYPE ty_booking.
***    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
***    LOOP AT keys INTO DATA(ls_key).
***      CLEAR ls_book.
***      ls_book-roomid    = ls_key-roomid.
***      ls_book-bookingid = ls_key-bookingid.
***      lo_util->set_book_del( EXPORTING im_booking = ls_book ).
***      APPEND VALUE #( %cid = ls_key-%cid_ref roomid = ls_key-roomid
***                      bookingid = ls_key-bookingid
***        %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 001
***          v1 = 'Booking Deleted Successfully'
***          severity = if_abap_behv_message=>severity-success ) )
***        TO reported-booking.
***    ENDLOOP.
***  ENDMETHOD.
***
***  METHOD read.
***    ENDMETHOD.
***
***  METHOD rba_Room.
***    ENDMETHOD.
***ENDCLASS.
**
**
**
***CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
***  PRIVATE SECTION.
***    METHODS update FOR MODIFY
***      IMPORTING entities FOR UPDATE Booking.
***    METHODS delete FOR MODIFY
***      IMPORTING keys FOR DELETE Booking.
***    METHODS read FOR READ
***      IMPORTING keys FOR READ Booking RESULT result.
***    METHODS rba_Room FOR READ
***      IMPORTING keys_rba FOR READ Booking\_room FULL result_requested
***      RESULT result LINK association_links.
***ENDCLASS.
**
**CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
**  PRIVATE SECTION.
**    METHODS update FOR MODIFY
**      IMPORTING entities FOR UPDATE Booking.
**    METHODS delete FOR MODIFY
**      IMPORTING keys FOR DELETE Booking.
**    METHODS read FOR READ
**      IMPORTING keys FOR READ Booking RESULT result.
**    METHODS rba_Room FOR READ
**      IMPORTING keys_rba FOR READ Booking\_room FULL result_requested
**      RESULT result LINK association_links.
**
**    " Add the determination method declaration
***    METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
***      IMPORTING keys FOR Booking~calculateTotalAmount.
**
**
**       METHODS calculateTotalAmount FOR DETERMINE ON MODIFY
**      IMPORTING keys FOR Booking~calculateTotalAmount.
**
**       METHODS validateDates FOR VALIDATE ON SAVE
**      IMPORTING keys FOR Booking~validateDates.
**
**
**
**
**ENDCLASS.
**
**
**
**
**CLASS lhc_Booking IMPLEMENTATION.
**
***  METHOD update.
***    DATA ls_book TYPE zcit_book_t.
***    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
***
***    LOOP AT entities INTO DATA(ls_entity).
***      ls_book = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
***
***      IF ls_book-roomid IS INITIAL.
***        CONTINUE.
***      ENDIF.
***
***      " Just buffer — do NOT touch mapped here
***      lo_util->set_book_val(
***        EXPORTING im_booking = ls_book
***        IMPORTING ex_created = DATA(lv_created) ).
***
***    ENDLOOP.
***  ENDMETHOD.
**
**  METHOD update.
**    DATA: ls_book TYPE zcit_book_t.
**    LOOP AT entities INTO DATA(ls_entity).
**      ls_book = CORRESPONDING #( ls_entity MAPPING FROM ENTITY ).
**      IF ls_book-roomid IS NOT INITIAL.
**        SELECT FROM zcit_book_t FIELDS *
**          WHERE roomid    = @ls_book-roomid
**            AND bookingid = @ls_book-bookingid
**          INTO TABLE @DATA(lt_book).
**        IF sy-subrc EQ 0.
**          DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
**          lo_util->set_book_val(
**            EXPORTING im_booking = ls_book
**            IMPORTING ex_created = DATA(lv_created) ).
**          IF lv_created EQ abap_true.
**            APPEND VALUE #( roomid = ls_book-roomid bookingid = ls_book-bookingid )
**              TO mapped-booking.
**            APPEND VALUE #( %key = ls_entity-%key
**              %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 001
**                v1 = 'Booking Updated Successfully'
**                severity = if_abap_behv_message=>severity-success ) )
**              TO reported-booking.
**          ENDIF.
**        ELSE.
**          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_book-roomid
**                          bookingid = ls_book-bookingid )
**            TO failed-booking.
**          APPEND VALUE #( %cid = ls_entity-%cid_ref roomid = ls_book-roomid
**            %msg = new_message( id = 'ZCIT_HOTEL_MSG' number = 002
**              v1 = 'Booking not found'
**              severity = if_abap_behv_message=>severity-error ) )
**            TO reported-booking.
**        ENDIF.
**      ENDIF.
**    ENDLOOP.
**  ENDMETHOD.
**
**  METHOD delete.
**    DATA ls_book TYPE zcl_hotel_utl=>ty_booking.
**    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
**
**    LOOP AT keys INTO DATA(ls_key).
**      CLEAR ls_book.
**      ls_book-roomid    = ls_key-roomid.
**      ls_book-bookingid = ls_key-bookingid.
**      lo_util->set_book_del( EXPORTING im_booking = ls_book ).
**    ENDLOOP.
**  ENDMETHOD.
**
**  METHOD read.
**  ENDMETHOD.
**
**  METHOD rba_Room.
**  ENDMETHOD.
**
**
**  METHOD calculateTotalAmount.
**    " 1. Read the Check-In and Check-Out Dates from the Booking draft/buffer
**    READ ENTITIES OF zcit_room_010 IN LOCAL MODE
**      ENTITY Booking
**        FIELDS ( CheckInDate CheckOutDate RoomId )
**        WITH CORRESPONDING #( keys )
**      RESULT DATA(lt_bookings).
**
**    " 2. Read the PricePerNight from the Parent (Room) using the Association
**    READ ENTITIES OF zcit_room_010 IN LOCAL MODE
**      ENTITY Booking BY \_room
**        FIELDS ( PricePerNight )
**        WITH CORRESPONDING #( keys )
**      RESULT DATA(lt_rooms).
**
**    DATA: lt_update_bookings TYPE TABLE FOR UPDATE zcit_room_010\\Booking.
**
**    " 3. Loop through bookings to calculate the total
**    LOOP AT lt_bookings INTO DATA(ls_booking)
**      WHERE CheckInDate IS NOT INITIAL
**        AND CheckOutDate IS NOT INITIAL.
**
**      " Find the corresponding parent room data to get the price
**      READ TABLE lt_rooms INTO DATA(ls_room) WITH KEY RoomId = ls_booking-RoomId.
**
**      IF sy-subrc = 0.
**        " Calculate the difference in days
**        DATA(lv_days) = ls_booking-CheckOutDate - ls_booking-CheckInDate.
**
**        " Ensure at least 1 day is charged if check-in and check-out are the same day
**        IF lv_days <= 0.
**          lv_days = 1.
**        ENDIF.
**
**        " Calculate Total Amount dynamically: Days * Room's PricePerNight
**        DATA(lv_total_amount) = lv_days * ls_room-PricePerNight.
**
**        " Prepare the update table with the calculated amount
**        APPEND VALUE #( %tky        = ls_booking-%tky
**                        TotalAmount = lv_total_amount ) TO lt_update_bookings.
**      ENDIF.
**
**    ENDLOOP.
**
**    " 4. Update the Booking Entity with the calculated TotalAmount
**    IF lt_update_bookings IS NOT INITIAL.
**      MODIFY ENTITIES OF zcit_room_010 IN LOCAL MODE
**        ENTITY Booking
**          UPDATE FIELDS ( TotalAmount )
**          WITH lt_update_bookings.
**    ENDIF.
**
**  ENDMETHOD.
**
**
**  " ... (keep your existing methods)
**
***  METHOD validateDates.
***    " 1. Read the Check-In and Check-Out Dates from the buffer
***    READ ENTITIES OF zcit_room_010 IN LOCAL MODE
***      ENTITY Booking
***        FIELDS ( CheckInDate CheckOutDate )
***        WITH CORRESPONDING #( keys )
***      RESULT DATA(lt_bookings).
***
***    " 2. Loop through the bookings to validate the dates
***    LOOP AT lt_bookings INTO DATA(ls_booking)
***      WHERE CheckInDate IS NOT INITIAL
***        AND CheckOutDate IS NOT INITIAL.
***
***      " Check if Check-Out is before or exactly the same as Check-In
***      IF ls_booking-CheckOutDate <= ls_booking-CheckInDate.
***
***        " 3. Mark the record as failed (prevents saving)
***        APPEND VALUE #( %tky = ls_booking-%tky ) TO failed-booking.
***
***        " 4. Report the error message to the Fiori UI
***        APPEND VALUE #(
***            %tky = ls_booking-%tky
***            " Create the error message
***            %msg = new_message(
***                     id       = 'ZCIT_HOTEL_MSG'  " <-- Use your message class
***                     number   = 003               " <-- Pick an unused message number
***                     severity = if_abap_behv_message=>severity-error
***                     v1       = 'Check-Out date must be after Check-In date' )
***
***            " Highlight the specific fields in RED on the Fiori UI
***            %element-CheckOutDate = if_abap_behv=>mk-on
***            %element-CheckInDate  = if_abap_behv=>mk-on
***          ) TO reported-booking.
***
***      ENDIF.
***
***    ENDLOOP.
***  ENDMETHOD.
**
**METHOD validateDates.
**    " 1. Read the Check-In and Check-Out Dates from the buffer
**    READ ENTITIES OF zcit_room_010 IN LOCAL MODE
**      ENTITY Booking
**        FIELDS ( CheckInDate CheckOutDate )
**        WITH CORRESPONDING #( keys )
**      RESULT DATA(lt_bookings).
**
**    " 2. Loop through the bookings to validate the dates
**    LOOP AT lt_bookings INTO DATA(ls_booking)
**      WHERE CheckInDate IS NOT INITIAL
**        AND CheckOutDate IS NOT INITIAL.
**
**      " Check if Check-Out is before or exactly the same as Check-In
**      IF ls_booking-CheckOutDate <= ls_booking-CheckInDate.
**
**        " 3. Mark the record as failed (prevents saving)
**        APPEND VALUE #( %tky = ls_booking-%tky ) TO failed-booking.
**
**        " 4. Report the error message directly to the Fiori UI
**        APPEND VALUE #(
**            %tky = ls_booking-%tky
**
**            " Use a direct text message (no message class needed)
**            %msg = new_message_with_text(
**                     severity = if_abap_behv_message=>severity-error
**                     text     = 'Check-Out date must be after Check-In date.' )
**
**            " Highlight the specific fields in RED on the Fiori UI
**            %element-CheckOutDate = if_abap_behv=>mk-on
**            %element-CheckInDate  = if_abap_behv=>mk-on
**          ) TO reported-booking.
**
**      ENDIF.
**
**    ENDLOOP.
**  ENDMETHOD.
**
**
**
**ENDCLASS.
**
**
**
***
***  METHOD calculateTotalAmount.
***    " 1. Read the relevant data (Check-In and Check-Out dates) from the buffer
***    READ ENTITIES OF zcit_room_010 IN LOCAL MODE
***      ENTITY Booking
***        FIELDS ( CheckInDate CheckOutDate )
***        WITH CORRESPONDING #( keys )
***      RESULT DATA(lt_bookings).
***
***    DATA: lt_update TYPE TABLE FOR UPDATE zcit_room_010\\Booking.
***
***    " 2. Loop through the bookings and calculate the amount
***    LOOP AT lt_bookings INTO DATA(ls_booking)
***      WHERE CheckInDate IS NOT INITIAL
***        AND CheckOutDate IS NOT INITIAL.
***
***      " Calculate the difference in days
***      DATA(lv_days) = ls_booking-CheckOutDate - ls_booking-CheckInDate.
***
***      " Optional: If CheckOut is the same as CheckIn, treat it as at least 1 night
***      IF lv_days <= 0.
***        lv_days = 1.
***      ENDIF.
***
***      " Calculate Total Amount (Days * 3000)
***      DATA(lv_total_amount) = lv_days * 3000.
***
***      " Prepare the update table
***      APPEND VALUE #( %tky        = ls_booking-%tky
***                      TotalAmount = lv_total_amount ) TO lt_update.
***    ENDLOOP.
***
***    " 3. Automatically update the TotalAmount field in the buffer
***    IF lt_update IS NOT INITIAL.
***      MODIFY ENTITIES OF zcit_room_010 IN LOCAL MODE
***        ENTITY Booking
***          UPDATE FIELDS ( TotalAmount )
***          WITH lt_update.
***    ENDIF.
***
***  ENDMETHOD.
