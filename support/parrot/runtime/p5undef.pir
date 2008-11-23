.HLL 'parrot'

.sub undef_load :load :anon
  .local pmc p5undef, pundef, p5scalar
  newclass p5undef, 'P5Undef'
  get_class pundef, 'Undef'
  addparent p5undef, pundef
  get_class p5scalar, 'P5Scalar'
  addparent p5undef, p5scalar
.end

.namespace [ 'P5Undef' ]
