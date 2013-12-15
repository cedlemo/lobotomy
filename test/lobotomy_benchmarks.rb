require 'benchmark'

iterations = 100_000
def array_to_hash_classical(symbols, array)
    an_hash = {}
    symbols.each do |symbol|
      an_hash[symbol] = array[symbols.index(symbol)] || ''
    end
    an_hash
end
def array_to_hash_ruby_way(symbols, array)
  an_hash = Hash[symbols.zip array]
  #an_hash.each { |k,v| v = '' if !v }
end
Benchmark.bm(27) do |bm|
  symbols = [ :foo, :bar, :test ]
  values = [ 'hello', 'world' ]
  bm.report('classical way') do
    iterations.times do
      array_to_hash_classical(symbols, values)
    end
  end

  bm.report('ruby way') do
    iterations.times do
      array_to_hash_ruby_way(symbols, values)
    end
  end
end
