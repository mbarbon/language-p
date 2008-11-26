.HLL 'parrot'

.sub string_load :load :anon
  .local pmc p5string, pstring
  newclass p5string, 'P5String'
  get_class pstring, 'String'
  addparent p5string, pstring
.end

.namespace ['P5String']
