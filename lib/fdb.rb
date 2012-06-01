#
# Fowarding DB
#
class FDB
  def initialize
    @db = {}
  end


  def learn mac, port_no, dpid
    @db[ mac ] = [ dpid, port_no ]
  end


  def [] mac
    @db[ mac ]
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
