.HLL 'parrot', ''

.sub load_classes :load :anon
  load_bytecode 'support/parrot/runtime/p5scalar.pbc'
  load_bytecode 'support/parrot/runtime/p5undef.pbc'
  load_bytecode 'support/parrot/runtime/p5integer.pbc'
  load_bytecode 'support/parrot/runtime/p5string.pbc'
  load_bytecode 'support/parrot/runtime/p5array.pbc'
  load_bytecode 'support/parrot/runtime/p5list.pbc'
  load_bytecode 'support/parrot/runtime/p5glob.pbc'
.end
