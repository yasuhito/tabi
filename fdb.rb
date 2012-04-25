class ForwardingEntry
  include Trema::Logger


  attr_reader :mac
  attr_reader :port_no
  attr_reader :dpid


  def initialize mac, port_no, dpid
    @mac = mac
    @port_no = port_no
    @dpid = dpid
    debug "New entry: MAC address = #{ @mac.to_s }, port number = #{ @port_no }"
  end
end


class FDB
  def initialize
    @db = {}
  end


  def port_no_of mac
    dest = @db[ mac ]
    if dest
      dest.port_no
    else
      nil
    end
  end


  def lookup mac
    if dest = @db[ mac ]
      [ dest.dpid, dest.port_no ]
    else
      nil
    end
  end


  def learn mac, port_no, dpid = nil
    if @db[ mac ].nil?
      new_entry = ForwardingEntry.new( mac, port_no, dpid )
      @db[ new_entry.mac ] = new_entry
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
