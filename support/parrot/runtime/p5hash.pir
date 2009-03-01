.HLL 'p5'

.sub list_load :load :anon
  .local pmc p5hash, phash
  newclass p5hash, 'P5Hash'
  get_class phash, 'Hash'
  addparent p5hash, phash
.end

.namespace ['P5Hash']
