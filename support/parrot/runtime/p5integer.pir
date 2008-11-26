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
