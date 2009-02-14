.HLL 'p5'

.sub string_load :load :anon
  .local pmc p5string, pstring
  get_class pstring, 'String'
  subclass p5string, pstring, 'P5String'
.end

.namespace ['P5String']

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
