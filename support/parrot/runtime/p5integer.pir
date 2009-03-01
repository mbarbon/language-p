.HLL 'p5'

.sub integer_load :load :anon
  .local pmc p5integer, pinteger
  get_class pinteger, 'Integer'
  subclass p5integer, pinteger, 'P5Integer'
.end

.namespace ['P5Integer']

.sub shallow_clone :method
  .param int level
  $P0 = clone self
  $P1 = new 'Ref'
  assign $P1, $P0

  .return ($P1)
.end

.sub localize :method
  .make_undef($P0)

  .return ($P0)
.end

.sub add :multi(P5Integer, P5Integer)
  .param pmc v1
  .param pmc v2
  .param pmc dest

  set $I0, v1
  set $I1, v2
  $I2 = $I0 + $I1
  new $P1, 'P5Integer'
  assign $P1, $I2
  new dest, 'Ref'
  assign dest, $P1

  .return (dest)
.end

.sub multiply :multi(P5Integer, P5Integer)
  .param pmc v1
  .param pmc v2
  .param pmc dest

  set $I0, v1
  set $I1, v2
  $I2 = $I0 * $I1
  new $P1, 'P5Integer'
  assign $P1, $I2
  new dest, 'Ref'
  assign dest, $P1

  .return (dest)
.end
