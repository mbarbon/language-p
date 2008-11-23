.HLL 'parrot'

.sub scalar_load :load :anon
  .local pmc p5scalar
  newclass p5scalar, 'P5Scalar'
.end

.namespace [ 'P5Scalar' ]

.sub shallow_clone :method
  .param int level
  .local pmc scopy
  scopy = clone self

  .return (scopy)
.end

.sub assign_iterator :method
  .param pmc iter
  if iter goto has_elem
    .local pmc undef
    undef = new 'P5Undef'
    assign self, undef
  goto end
has_elem:
  .local pmc value
  value = shift iter
  assign self, value
end:
.end
