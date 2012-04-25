require "config"
require "fdb"


class Tabi < Controller
  def start
    @fdbs = {}
    $switch.each do | name, each |
      @fdbs[ each[ :dpid ] ] = FDB.new
    end
  end


  def switch_ready datapath_id
    info "#{ switch_name datapath_id } switch connected"
  end


  def packet_in datapath_id, message
    fdb = @fdbs[ datapath_id ]
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


  def switch_name datapath_id
    $switch.each do | name, attr |
      return name if attr[ :dpid ] == datapath_id
    end
    raise "Switch not found! (dpid = #{ datapath_id.to_hex })"
  end


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
