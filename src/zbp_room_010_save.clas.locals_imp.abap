*CLASS lsc_ZCIT_ROOM_010 DEFINITION INHERITING FROM cl_abap_behavior_saver.
*  PROTECTED SECTION.
*    METHODS finalize          REDEFINITION.
*    METHODS check_before_save REDEFINITION.
*    METHODS save              REDEFINITION.
*    METHODS cleanup           REDEFINITION.
*    METHODS cleanup_finalize  REDEFINITION.
*ENDCLASS.
*
*CLASS lsc_ZCIT_ROOM_010 IMPLEMENTATION.
*  METHOD finalize.        ENDMETHOD.
*  METHOD check_before_save. ENDMETHOD.
*
*  METHOD save.
*    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
*    lo_util->get_room_val( IMPORTING ex_room     = DATA(ls_room) ).
*    lo_util->get_book_val( IMPORTING ex_booking  = DATA(ls_book) ).
*    lo_util->get_room_del( IMPORTING ex_rooms    = DATA(lt_room_del) ).
*    lo_util->get_book_del( IMPORTING ex_bookings = DATA(lt_book_del) ).
*    lo_util->get_del_flags( IMPORTING ex_room_del = DATA(lv_room_del) ).
*
*    " Save / Update Room
*    IF ls_room IS NOT INITIAL.
*      MODIFY zcit_room_t FROM @ls_room.
*    ENDIF.
*
*    " Save / Update Booking
*    IF ls_book IS NOT INITIAL.
*      MODIFY zcit_book_t FROM @ls_book.
*    ENDIF.
*
*    " Handle Deletions
*    IF lv_room_del = abap_true.
*      LOOP AT lt_room_del INTO DATA(ls_del_room).
*        DELETE FROM zcit_room_t WHERE roomid = @ls_del_room-roomid.
*        DELETE FROM zcit_book_t WHERE roomid = @ls_del_room-roomid.
*      ENDLOOP.
*    ELSE.
*      LOOP AT lt_room_del INTO ls_del_room.
*        DELETE FROM zcit_room_t WHERE roomid = @ls_del_room-roomid.
*      ENDLOOP.
*      LOOP AT lt_book_del INTO DATA(ls_del_book).
*        DELETE FROM zcit_book_t
*          WHERE roomid    = @ls_del_book-roomid
*            AND bookingid = @ls_del_book-bookingid.
*      ENDLOOP.
*    ENDIF.
*  ENDMETHOD.
*
*  METHOD cleanup.
*    zcl_hotel_utl=>get_instance( )->cleanup_buffer( ).
*  ENDMETHOD.
*
*  METHOD cleanup_finalize. ENDMETHOD.
*ENDCLASS.

CLASS lsc_ZCIT_ROOM_010 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save              REDEFINITION.
    METHODS cleanup           REDEFINITION.
    METHODS cleanup_finalize  REDEFINITION.
ENDCLASS.
CLASS lsc_ZCIT_ROOM_010 IMPLEMENTATION.
  METHOD finalize.        ENDMETHOD.
  METHOD check_before_save. ENDMETHOD.
  METHOD save.
    DATA(lo_util) = zcl_hotel_utl=>get_instance( ).
    " Get all buffered records (now tables, not single structs)
    lo_util->get_room_val( IMPORTING ex_rooms     = DATA(lt_rooms) ).
    lo_util->get_book_val( IMPORTING ex_bookings  = DATA(lt_bookings) ).
    lo_util->get_room_del( IMPORTING ex_rooms     = DATA(lt_room_del) ).
    lo_util->get_book_del( IMPORTING ex_bookings  = DATA(lt_book_del) ).
    lo_util->get_del_flags( IMPORTING ex_room_del = DATA(lv_room_del) ).
    " 1. Save / Update all rooms
    LOOP AT lt_rooms INTO DATA(ls_room).
      MODIFY zcit_room_t FROM @ls_room.
    ENDLOOP.
    " 2. Save / Update all bookings
    LOOP AT lt_bookings INTO DATA(ls_book).
      MODIFY zcit_book_t FROM @ls_book.
    ENDLOOP.
    " 3. Handle deletions
    IF lv_room_del = abap_true.
      " Delete entire room + all its bookings
      LOOP AT lt_room_del INTO DATA(ls_del_room).
        DELETE FROM zcit_room_t WHERE roomid = @ls_del_room-roomid.
        DELETE FROM zcit_book_t WHERE roomid = @ls_del_room-roomid.
      ENDLOOP.
    ELSE.
      " Delete individual rooms only
      LOOP AT lt_room_del INTO ls_del_room.
        DELETE FROM zcit_room_t WHERE roomid = @ls_del_room-roomid.
      ENDLOOP.
      " Delete individual bookings only
      LOOP AT lt_book_del INTO DATA(ls_del_book).
        DELETE FROM zcit_book_t
          WHERE roomid    = @ls_del_book-roomid
            AND bookingid = @ls_del_book-bookingid.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
  METHOD cleanup.
    zcl_hotel_utl=>get_instance( )->cleanup_buffer( ).
  ENDMETHOD.
  METHOD cleanup_finalize. ENDMETHOD.
ENDCLASS.
