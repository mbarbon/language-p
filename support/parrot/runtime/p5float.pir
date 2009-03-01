.HLL 'p5'

.sub float_load :load :anon
  .local pmc p5float, pfloat
  get_class pfloat, 'Float'
  subclass p5float, pfloat, 'P5Float'
.end

.namespace ['P5Float']

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

.sub add :multi(P5Float, P5Float)
  .param pmc v1
  .param pmc v2
  .param pmc dest

  set $N0, v1
  set $N1, v2
  $N2 = $N0 + $N1
  new $P1, 'P5Float'
  assign $P1, $N2
  new dest, 'Ref'
  assign dest, $P1

  .return (dest)
.end

.sub multiply :multi(P5Float, P5Float)
  .param pmc v1
  .param pmc v2
  .param pmc dest

  set $N0, v1
  set $N1, v2
  $N2 = $N0 * $N1
  new $P1, 'P5Float'
  assign $P1, $N2
  new dest, 'Ref'
  assign dest, $P1

  .return (dest)
.end
