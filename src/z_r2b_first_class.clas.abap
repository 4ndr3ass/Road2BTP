CLASS z_r2b_first_class DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS z_r2b_first_class IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.


    out->write( 'This is a first text within the Textpool'(100) ).
    out->write( 'Erste Text Für alle'(de1) ).

  ENDMETHOD.

ENDCLASS.
