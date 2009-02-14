.HLL 'p5'

.sub list_load :load :anon
  .local pmc p5array, p5list
  get_class p5array, 'P5Array'
  subclass p5list, p5array, 'P5List'
.end

.namespace ['P5List']

.sub assign_pmc :vtable
  .param pmc other
  .local pmc iterator, cloned, oiter, entry

  cloned = other.'shallow_clone'( 1 )
  oiter = new 'Iterator', cloned
  iterator = new 'Iterator', self
  unless iterator goto iter_end

  iter_loop:
    entry = shift iterator
    if oiter goto has_elem
      .local pmc undef
      new undef, 'P5Undef'
      assign entry, undef
  has_elem:
      .local pmc value
      value = shift oiter
      deref value, value
      assign entry, value
  end_assign_element:
    if iterator goto iter_loop
  iter_end:
.end

.sub push_pmc :vtable
  .param pmc other
  .local int isa_array, size

  set size, self
  isa isa_array, other, 'P5Array'
  if isa_array goto push_array
push_scalar:
  # poor man's push
  set self[size], other
  goto end_push
push_array:
  .local pmc oiter, entry
  new oiter, 'Iterator', other
  oiter_loop:
    unless oiter goto end_push
    shift entry, oiter
    # poor man's push
    set self[size], entry
    inc size
    goto oiter_loop
end_push:
.end
