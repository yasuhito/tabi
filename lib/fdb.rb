$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), ".." )

require "config"


class ForwardingEntry
  attr_reader :mac
  attr_reader :port_no
  attr_reader :dpid


  def initialize mac, port_no, dpid
    @mac = mac
    @port_no = port_no
    @dpid = dpid
  end
end


class FDB
  def initialize
    @db = {}
  end


  def port_no_of mac
    dest = @db[ mac.to_s ]
    if dest
      dest.port_no
    else
      nil
    end
  end


  def learn mac, port_no, dpid = nil
    if @db[ mac.to_s ].nil?
      @db[ mac.to_s ] = ForwardingEntry.new( mac.to_s, port_no, dpid )
    end
  end
end


class FdbSet
  def initialize
    @fdbs = {}
    $switch.each do | name, attr |
      @fdbs[ attr[ :dpid ] ] = FDB.new
    end
  end


  def learn dpid, macsa, port
    @fdbs[ dpid ].learn macsa, port
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
