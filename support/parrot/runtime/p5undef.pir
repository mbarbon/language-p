.HLL 'parrot'

.sub undef_load :load :anon
  .local pmc p5undef, pundef
  newclass p5undef, 'P5Undef'
  get_class pundef, 'Undef'
  addparent p5undef, pundef
.end

.namespace ['P5Undef']

.sub defined :vtable
  .return (0)
.end

.sub get_bool :vtable
  .return (0)
.end

.sub logical_not :vtable
  .param pmc dest

  .make_integer(dest, 1)
  .return (dest)
.end
