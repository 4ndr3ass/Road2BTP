"! <p class="shorttext synchronized" lang="en">##GENERATED Behavior implementation</p>
CLASS zcl_r2b_bp_traveltp DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zr2b_r_traveltp .

  PUBLIC SECTION.

    CONSTANTS :
      "! <p class="shorttext synchronized" lang="en">Valid Attributes for attribute OverallStatus</p>
      BEGIN OF c_travel_status,
        open     TYPE /dmo/overall_status VALUE 'O', "Open
        accepted TYPE /dmo/overall_status VALUE 'A', "Accepted
        rejected TYPE /dmo/overall_status VALUE 'X', "Rejected
      END OF c_travel_status.

    CONSTANTS  c_state_area_validate_customer TYPE string VALUE 'VALIDATE_CUSTOMER' ##NO_TEXT.
    CONSTANTS c_state_area_validate_dates TYPE string VALUE 'VALIDATE_DATES' ##NO_TEXT.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_r2b_bp_traveltp IMPLEMENTATION.
ENDCLASS.
