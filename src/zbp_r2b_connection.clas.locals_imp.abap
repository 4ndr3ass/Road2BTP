CLASS lhc_connection DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR Connection
        RESULT result,
      CheckSemanticKey FOR VALIDATE ON SAVE
        IMPORTING keys FOR Connection~CheckSemanticKey,
      CheckCarrierID FOR VALIDATE ON SAVE
        IMPORTING keys FOR Connection~CheckCarrierID,
      CheckOriginDestination FOR VALIDATE ON SAVE
        IMPORTING keys FOR Connection~CheckOriginDestination,
      getCities FOR DETERMINE ON SAVE
        IMPORTING keys FOR Connection~getCities.

ENDCLASS.

CLASS lhc_connection IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD CheckSemanticKey.

    READ ENTITIES OF zr2b_r_connection IN LOCAL MODE
      ENTITY Connection
          FIELDS ( CarrierID ConnectionID )
              WITH CORRESPONDING #( keys )
          RESULT DATA(connections).

    LOOP AT connections REFERENCE INTO DATA(connection).

      SELECT FROM zr2b_aconn
        FIELDS uuid
           WHERE carrier_id = @connection->CarrierID
             AND connection_id = @connection->ConnectionID
             AND uuid <> @connection->uuid
       UNION
        SELECT FROM zr2b_dconn
          FIELDS uuid
           WHERE  carrierid = @connection->CarrierID
             AND connectionid = @connection->ConnectionID
             AND uuid <> @connection->uuid
        INTO TABLE @DATA(check_result).

      IF check_result IS NOT INITIAL.

        DATA(message) = me->new_message(
                          id       = 'ZS4D400'
                          number   = '001'
                          severity = ms-error
                        ).

        DATA reported_record LIKE LINE OF reported-connection.

        reported_record-%tky = connection->%tky.
        reported_record-%msg = message.
        reported_record-%element-carrierid = if_abap_behv=>mk-on.
        reported_record-%element-connectionid = if_abap_behv=>mk-on.
        APPEND reported_record TO reported-connection.

*        DATA failed_record like LINE OF failed-connection.
*
*        failed_record-%tky = connection->%tky.
*        APPEND failed_record to failed-connection.

        failed-connection = VALUE #( BASE failed-connection ( %tky = connection->%tky ) ).


      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD CheckCarrierID.

    READ ENTITIES OF zr2b_r_connection IN LOCAL MODE
      ENTITY Connection
        FIELDS ( CarrierID )
          WITH CORRESPONDING #( keys )
              RESULT DATA(connections).

    LOOP AT connections REFERENCE INTO DATA(connection).

      SELECT SINGLE
          FROM /DMO/I_Carrier
              FIELDS @abap_true
                  WHERE AirlineID = @connection->CarrierID
                  INTO @DATA(exists).

      IF exists = abap_false.

        reported-connection = VALUE #(
            BASE reported-connection
            ( %tky = connection->%tky
              %msg = me->new_message( id = 'ZS4D400' number = '002' severity = ms-error v1 = connection->CarrierID )
              %element-carrierid = if_abap_behv=>mk-on
             )
         ).

        failed-connection = VALUE #( BASE failed-connection ( %tky = connection->%tky ) ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD CheckOriginDestination.

    READ ENTITIES OF zr2b_r_connection IN LOCAL MODE
    ENTITY Connection
      FIELDS ( AiportFromID AirportToID )
          WITH CORRESPONDING #( keys )
              RESULT DATA(connections).

    LOOP AT connections REFERENCE INTO DATA(connection).

      IF connection->AiportFromID = connection->AirportToID.

        reported-connection = VALUE #(
            BASE reported-connection
            ( %tky = connection->%tky
              %msg = me->new_message( id = 'ZS4D400' number = '003' severity = ms-error )
              %element-carrierid = if_abap_behv=>mk-on
             )
         ).

        failed-connection = VALUE #( BASE failed-connection ( %tky = connection->%tky ) ).

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD getCities.

    READ ENTITIES OF zr2b_r_connection IN LOCAL MODE
      ENTITY Connection
        FIELDS ( AiportFromID AirportToID )
          WITH CORRESPONDING #( keys )
              RESULT DATA(connections).

    LOOP AT connections REFERENCE INTO DATA(connection).

      SELECT SINGLE
         FROM /DMO/I_Airport
            FIELDS city, CountryCode
             WHERE AirportID = @connection->AiportFromID
                 INTO ( @connection->CityFrom, @connection->CountryFrom ).

      SELECT SINGLE
         FROM /DMO/I_Airport
            FIELDS city, CountryCode
             WHERE AirportID = @connection->AirportToID
                 INTO ( @connection->CityTo, @connection->CountryTo ).

      MODIFY connections FROM connection->*.

    ENDLOOP.

    DATA connections_update TYPE TABLE FOR UPDATE zr2b_r_connection.

    connections_update = CORRESPONDING #( connections ).

    MODIFY ENTITIES OF zr2b_r_connection IN LOCAL MODE
        ENTITY Connection
        UPDATE
        FIELDS ( CityFrom CountryFrom CityTo CountryTo )
        WITH connections_update
       REPORTED DATA(reported_records).

    reported-connection = CORRESPONDING #( reported_records-connection ).

  ENDMETHOD.

ENDCLASS.
