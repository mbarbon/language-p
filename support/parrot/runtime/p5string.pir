.HLL 'parrot', ''

.sub string_load :load :anon
  .local pmc p5string, pstring, p5scalar
  newclass p5string, 'P5String'
  get_class pstring, 'String'
  addparent p5string, pstring
  get_class p5scalar, 'P5Scalar'
  addparent p5string, p5scalar
.end

.namespace [ 'P5String' ]
