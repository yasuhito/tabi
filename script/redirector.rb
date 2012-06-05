#!/usr/bin/env ruby

while not STDIN.closed? do
  break if STDIN.eof?
  request = STDIN.gets # do nothing

  url = request[/\S+/]
  if url == "http://192.168.0.1:3000/"
    puts url
  else
    puts "http://192.168.0.1:3000/redirect"
  end
  STDOUT.flush
  next
end
