class ForwardingEntry
  attr_reader :port_no
  attr_reader :dpid


  def initialize port_no, dpid
    @port_no = port_no
    @dpid = dpid
  end
end


class FDB
  attr_reader :db


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


  def dpid_of mac
    dest = @db[ mac.to_s ]
    if dest
      dest.dpid
    else
      nil
    end
  end


  def learn mac, port_no, dpid
    if @db[ mac.to_s ].nil?
      @db[ mac.to_s ] = ForwardingEntry.new( port_no, dpid )
    end
  end


  def [] mac
    @db[ mac.to_s ]
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
