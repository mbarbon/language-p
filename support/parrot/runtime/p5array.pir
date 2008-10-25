.HLL 'parrot', ''

.sub list_load :load :anon
  .local pmc p5array, plist
  newclass p5array, 'P5Array'
  get_class plist, 'ResizablePMCArray'
  addparent p5array, plist
.end

.namespace [ 'P5Array' ]

.sub assign_pmc :vtable
  .param pmc other
  .local pmc iterator, cloned, oiter
  cloned = other.'shallow_clone'( 1 )
  oiter = new 'Iterator', self
  self.'assign_iterator'( oiter )
.end

.sub shallow_clone :method
  .param int level
  .local pmc scopy, sclass, entry
  .local int size

  class sclass, self
  scopy = new sclass

  if level > 0 goto deep_clone
    size = elements self
    copy_loop:
      size = size - 1
      if size < 0 goto copy_end
      entry = self[size]
      scopy[size] = entry
      goto copy_loop
    copy_end:
    goto end_clone
  deep_clone:
    level = level - 1
    size = elements self
    clone_loop:
      size = size - 1
      if size < 0 goto clone_end
      entry = self[size]
      entry = entry.'shallow_clone'( level )
      scopy[size] = entry
      goto clone_loop
    clone_end:
  end_clone:

  .return (scopy)
.end

.sub assign_iterator :method
  .param pmc iter

  self = 0
  unless iter goto end
loop:
    .local pmc value
    value = shift iter
    push self, value
  if iter goto loop
end:
.end
