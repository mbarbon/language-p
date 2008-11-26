.HLL 'parrot'

.sub undef_load :load :anon
  .local pmc p5undef, pundef
  newclass p5undef, 'P5Undef'
  get_class pundef, 'Undef'
  addparent p5undef, pundef
.end

.namespace ['P5Undef']
