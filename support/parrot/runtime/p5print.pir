.HLL 'p5'

.namespace ['builtins']

.sub print
  .param pmc args

  $I0 = args
  $I1 = 0
  if $I0 == 0 goto end
ploop:
  set $P0, args[$I1]
  print $P0
  sub $I0, $I0, 1
  add $I1, $I1, 1
  if $I0 > 0 goto ploop
end:
  # cheat for now
  .make_integer( $P16, 1 )
  .return ($P16)
.end
