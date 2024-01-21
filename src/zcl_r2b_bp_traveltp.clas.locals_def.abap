*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section
    TYPES ty_customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.
    TYPES ty_customer_ids TYPE STANDARD TABLE OF /dmo/customer_id.
