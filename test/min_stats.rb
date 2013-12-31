#!/usr/bin/env ruby

a=[ {stats: 2, toto: 'a'}, 
    {stats: 3, toto: 'a'},
    {stats: 4, toto: 'a'},
    {stats: 2, toto: 'a'},
    {stats: 10, toto: 'a'}
]
a.inject(a[0][:stats]) { |min, v|  puts min; puts v }
puts a.inject(a[0][:stats]) { |min, v| min > v[:stats] ?  min = v[:stats] : min} 

