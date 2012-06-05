#!/usr/bin/env ruby

while not STDIN.closed? do
  break if STDIN.eof?
  STDIN.gets # do nothing

  puts "http://192.168.0.1:3000/redirect"
  STDOUT.flush
  next
end
