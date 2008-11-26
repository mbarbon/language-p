.HLL 'p5'

.sub typeglob_load :load :anon
  .local pmc p5typeglob, p5typeglobbody
  newclass p5typeglob, 'P5Typeglob'
  addattribute p5typeglob, 'body'
  newclass p5typeglobbody, 'P5TypeglobBody'
  addattribute p5typeglob, 'scalar'
  addattribute p5typeglob, 'array'
  addattribute p5typeglob, 'hash'
  addattribute p5typeglob, 'io'
  addattribute p5typeglob, 'format'
  addattribute p5typeglob, 'subroutine'
.end

.namespace ['P5Typeglob']

.namespace ['P5TypeglobBody']
