if ARGV.length != 1
  puts "Usage: ll FILE"
  exit
end

filename = File.absolute_path ARGV[0]
dirname = File.dirname filename
tmp = "#{dirname}/tmp.ll"
crystal_c = File.expand_path("../../../ext/crystal.c",  __FILE__)
crystal_ll = File.expand_path("../../../ext/crystal.ll",  __FILE__)
`llvmc #{crystal_c} -emit-llvm -S -o #{crystal_ll}`
`llvm-link #{filename} #{crystal_ll} -o #{tmp}`
puts `opt -loop-reduce -loop-simplify -loop-unroll -loop-unswitch -functionattrs -constprop -correlated-propagation -simplifycfg -instcombine -reassociate -gvn -mem2reg -inline #{tmp} -S`
