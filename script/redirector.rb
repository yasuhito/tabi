#!/usr/bin/env ruby

while not STDIN.closed? do
  break if STDIN.eof?
  STDIN.gets # do nothing

  puts "http://yasuhito.info"
  STDOUT.flush
  next
end
