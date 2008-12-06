# common macros
.macro make_undef(res)
  .local pmc t1
  new t1, 'P5Undef'
  new .res, 'Ref'
  assign .res, t1
.endm

.macro make_integer(res, value)
  .local pmc t2
  new t2, 'P5Integer'
  set t2, .value
  new .res, 'Ref'
  assign .res, t2
.endm

.macro make_string(res, value)
  .local pmc t3
  new t3, 'P5String'
  set t3, .value
  new .res, 'Ref'
  assign .res, t3
.endm

.macro make_float(res, value)
  .local pmc t4
  new t4, 'P5Float'
  set t4, .value
  new .res, 'Ref'
  assign .res, t4
.endm
