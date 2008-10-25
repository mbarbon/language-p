.HLL 'parrot', ''

.sub integer_load :load :anon
  .local pmc p5integer, pinteger, p5scalar
  newclass p5integer, 'P5Integer'
  get_class pinteger, 'Integer'
  addparent p5integer, pinteger
  get_class p5scalar, 'P5Scalar'
  addparent p5integer, p5scalar
.end

.namespace [ 'P5Integer' ]

