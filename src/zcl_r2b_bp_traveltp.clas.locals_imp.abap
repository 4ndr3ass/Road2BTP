"! <p class="shorttext synchronized" lang="en">Local Behavior implementation</p>
CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS select_valid_customers
      IMPORTING i_customers                 TYPE ty_customers
      RETURNING VALUE(r_valid_customer_ids) TYPE zr2b_customer_ids.

    "! <p class="shorttext synchronized" lang="en">Overall Authority Check</p>
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING
      REQUEST requested_authorizations FOR Travel
      RESULT result.

    "! <p class="shorttext synchronized" lang="en">Ensure Early Numbering</p>
    METHODS  earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

    "! <p class="shorttext synchronized" lang="en">Set Status to "Open" by default</p>
    METHODS   setStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setStatusToOpen.

    "! <p class="shorttext synchronized" lang="en">Validate entered Customer ID</p>
    METHODS   validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    "! <p class="shorttext synchronized" lang="en">Validate End and Start Date to be provided</p>
    METHODS validatedDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validatedDates.

ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA travel_id_max TYPE /dmo/travel_id.
    DATA use_number_range TYPE abap_bool VALUE abap_false.

    "Ensure Travel ID is not set yet (idempotent)- must be checked when BO is draft-enabled

    LOOP AT entities REFERENCE INTO DATA(travel_entity) WHERE TravelID IS NOT INITIAL.
      APPEND CORRESPONDING #( travel_entity->* ) TO mapped-travel.
    ENDLOOP.

    DATA(entities_without_travelid) = entities.
    "Remove the entries with an existing Travel ID
    DELETE entities_without_travelid WHERE TravelID IS NOT INITIAL.

    IF use_number_range = abap_false.

      "Get Numbers

      TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = '01'
              object            = '/DMO/TRV_M'
              quantity          = CONV #( lines( entities_without_travelid ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        = DATA(number_range_return_code)
            returned_quantity = DATA(number_range_returned_quantity)
          ).

        CATCH cx_number_ranges INTO DATA(lx_number_ranges).

          LOOP AT entities_without_travelid REFERENCE INTO travel_entity.

            reported-travel =
                VALUE #( BASE reported-travel (
                    %cid = travel_entity->%cid
                    %key = travel_entity->%key
                    %is_draft = travel_entity->%is_draft
                    %msg = lx_number_ranges ) ).

            failed-travel =
               VALUE #( BASE failed-travel (
                   %cid = travel_entity->%cid
                   %key = travel_entity->%key
                   %is_draft = travel_entity->%is_draft ) ).

          ENDLOOP.
          EXIT.
      ENDTRY.

      "determine the first free travel ID from the number range
      travel_id_max = number_range_key - number_range_returned_quantity.

    ELSE.

      "determine the first free travel ID without number range
      "Get max travel ID from active table

      SELECT SINGLE
       FROM zr2b_atrav
        FIELDS MAX( travel_id ) AS travelID
           INTO @travel_id_max.

      SELECT SINGLE
       FROM zr2b_dtrav
        FIELDS MAX( travelid ) AS travelID
           INTO @DATA(max_travelid_draft).

      IF max_travelid_draft > travel_id_max.
        travel_id_max = max_travelid_draft.
      ENDIF.

    ENDIF.

    "Set Travel ID for new instances w/o ID

    LOOP AT entities_without_travelid REFERENCE INTO travel_entity.
      travel_id_max += 1.
      travel_entity->TravelID = travel_id_max.
      mapped-travel =
          VALUE #( BASE mapped-travel
          ( %cid = travel_entity->%cid
            %key = travel_entity->%key
            %is_draft = travel_entity->%is_draft
             ) ).
    ENDLOOP.

  ENDMETHOD.

  METHOD setStatusToOpen.

    READ ENTITIES OF zr2b_r_traveltp
      IN LOCAL MODE
          ENTITY Travel
              FIELDS ( OverallStatus )
              WITH CORRESPONDING #( keys )
      RESULT DATA(travel_entities)
      FAILED DATA(read_faild).

    "If overall travel status is already set, do nothing, i.e. remove such instances

    DELETE travel_entities WHERE OverallStatus IS NOT INITIAL.
    CHECK travel_entities IS NOT INITIAL.

    "else set overall travel status to open ('O')
    MODIFY ENTITIES OF zr2b_r_traveltp IN LOCAL MODE
      ENTITY Travel
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR travel IN travel_entities ( %tky          = travel-%tky
                                              OverallStatus = zcl_r2b_bp_traveltp=>c_travel_status-open ) )
     REPORTED DATA(update_reported).

    "Set the changing parameter
    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD validateCustomer.

    "read relevant travel instance data
    READ ENTITIES OF zr2b_r_traveltp
      IN LOCAL MODE
        ENTITY Travel
         FIELDS ( CustomerID )
          WITH CORRESPONDING #( keys )
            RESULT DATA(travel_entities).

    "optimization of DB select: extract distinct non-initial customer IDs
    DATA customers TYPE ty_customers.

    customers = CORRESPONDING #( travel_entities
                    DISCARDING DUPLICATES MAPPING customer_id = customerID
                        EXCEPT * ).

    DATA(valid_customers) = select_valid_customers( customers ).

    "raise msg for non existing and initial customer id

    LOOP AT travel_entities REFERENCE INTO DATA(travel_entity).

      APPEND VALUE #(
          %tky = travel_entity->%tky
          %state_area = zcl_r2b_bp_traveltp=>c_state_area_validate_customer )
          TO reported-travel.

      IF travel_entity->CustomerID IS INITIAL.

        DATA(flight_message) =  NEW /dmo/cm_flight_messages(
                textid                = /dmo/cm_flight_messages=>enter_customer_id
                severity              = if_abap_behv_message=>severity-error ).


      ELSEIF NOT line_exists( valid_customers[ table_line = travel_entity->CustomerID ] ).

        flight_message =  NEW /dmo/cm_flight_messages(
                 customer_id = travel_entity->customerid
                 textid      = /dmo/cm_flight_messages=>customer_unkown
                 severity    = if_abap_behv_message=>severity-error ).


      ENDIF.

      IF flight_message IS BOUND.

        APPEND VALUE #( %tky = travel_entity->%tky  ) TO failed-travel.

        APPEND VALUE #(
          %tky = travel_entity->%tky
          %state_area = zcl_r2b_bp_traveltp=>c_state_area_validate_customer
          %msg = flight_message
          %element-CustomerID = if_abap_behv=>mk-on
           ) TO reported-travel.

        FREE  flight_message.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validatedDates.

    READ ENTITIES OF zr2b_r_traveltp
      IN LOCAL MODE
        ENTITY Travel
         FIELDS ( BeginDate EndDate )
            WITH CORRESPONDING #( keys )
    RESULT DATA(travel_entities).

    LOOP AT travel_entities REFERENCE INTO DATA(travel_entity).

      APPEND VALUE #(
           %tky = travel_entity->%tky
           %state_area = zcl_r2b_bp_traveltp=>c_state_area_validate_dates )
           TO reported-travel.

**********************************************************************
*... BeginnDate Validation
**********************************************************************

      IF travel_entity->BeginDate IS INITIAL.

        DATA(flight_message) = NEW /dmo/cm_flight_messages(
           textid   = /dmo/cm_flight_messages=>enter_begin_date
           severity = if_abap_behv_message=>severity-error ).

      ELSEIF travel_entity->BeginDate < cl_abap_context_info=>get_system_date( ).

        flight_message = NEW /dmo/cm_flight_messages(
           begin_date = travel_entity->BeginDate
           textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
           severity   = if_abap_behv_message=>severity-error ).

      ENDIF.

      IF flight_message IS BOUND.

        APPEND VALUE #( %tky = travel_entity->%tky  ) TO failed-travel.

        APPEND VALUE #(
          %tky = travel_entity->%tky
          %state_area = zcl_r2b_bp_traveltp=>c_state_area_validate_dates
          %msg = flight_message
           %element-BeginDate = if_abap_behv=>mk-on
           ) TO reported-travel.

        FREE flight_message.

      ENDIF.

**********************************************************************
*... EndDate Validation
**********************************************************************

      IF travel_entity->EndDate IS INITIAL.

        flight_message = NEW /dmo/cm_flight_messages(
           textid   = /dmo/cm_flight_messages=>enter_begin_date
           severity = if_abap_behv_message=>severity-error ).

      ELSEIF travel_entity->EndDate < travel_entity->BeginDate.

        flight_message = NEW /dmo/cm_flight_messages(
           begin_date = travel_entity->EndDate
           textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
           severity   = if_abap_behv_message=>severity-error ).

      ENDIF.

      IF flight_message IS BOUND.

        APPEND VALUE #( %tky = travel_entity->%tky  ) TO failed-travel.

        APPEND VALUE #(
          %tky = travel_entity->%tky
          %state_area = zcl_r2b_bp_traveltp=>c_state_area_validate_dates
          %msg = flight_message
          %element-BeginDate = if_abap_behv=>mk-on
          %element-EndDate = if_abap_behv=>mk-on
           ) TO reported-travel.

        FREE flight_message.

      ENDIF.

**********************************************************************

    ENDLOOP.



  ENDMETHOD.


  METHOD select_valid_customers.

    SELECT FROM /dmo/customer
        FIELDS customer_id
         FOR ALL ENTRIES IN @i_customers WHERE customer_id = @i_customers-customer_id
            INTO TABLE @r_valid_customer_ids.

  ENDMETHOD.

ENDCLASS.
