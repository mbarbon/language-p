.HLL 'p5'

.sub typeglob_load :load :anon
  .local pmc p5typeglob, p5typeglobbody
  newclass p5typeglob, 'P5Typeglob'
  addattribute p5typeglob, 'body'

  newclass p5typeglobbody, 'P5TypeglobBody'
  addattribute p5typeglobbody, 'scalar'
  addattribute p5typeglobbody, 'array'
  addattribute p5typeglobbody, 'hash'
  addattribute p5typeglobbody, 'io'
  addattribute p5typeglobbody, 'format'
  addattribute p5typeglobbody, 'subroutine'
.end

.namespace ['P5Typeglob']

.sub init :vtable
  .local pmc body
  new body, 'P5TypeglobBody'
  setattribute self, 'body', body
.end

.namespace ['P5TypeglobBody']
