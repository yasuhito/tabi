require "config"
require "fdb"


class Tabi < Controller
  def start
    @fdbs = {}
    $switch.each do | each |
      @fdbs[ each[ :dpid ] ] = FDB.new
    end
  end


  def switch_ready datapath_id
    info "Switch %#x connected!" % datapath_id
  end


  def packet_in datapath_id, message
    fdb = @fdbs[ datapath_id ]
    raise "Unknown switch! (datapath=#{ datapath.to_hex })" if fdb.nil?
    fdb.learn message.macsa, message.in_port
    port_no = fdb.port_no_of( message.macda )
    if port_no
      flow_mod datapath_id, message, port_no
      packet_out datapath_id, message, port_no
    else
      @fdbs.keys.each do | each |
        flood each, message
      end
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def flow_mod datapath_id, message, port_no
    send_flow_mod_add(
      datapath_id,
      :match => ExactMatch.from( message ),
      :actions => ActionOutput.new( port_no )
    )
  end


  def packet_out datapath_id, message, port_no
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => ActionOutput.new( port_no )
    )
  end


  def flood datapath_id, message
    packet_out datapath_id, message, OFPP_FLOOD
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
