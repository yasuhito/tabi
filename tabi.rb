require "config"
require "fdb"


class Trema::PacketIn
  def http?
    tcp_dst_port == 80 or tcp_dst_port == 3000
  end
end


class Tabi < Controller
  def start
    @fdbs = {}
    $switch.each do | name, attr |
      @fdbs[ attr[ :dpid ] ] = FDB.new
    end
  end


  def switch_ready datapath_id
    info "#{ switch_name datapath_id } switch connected"
  end


  def packet_in datapath_id, message
    learn message
    case message.macsa.to_s
    when mac_guest
      if message.arp? or message.icmpv4?
        flood message
      elsif message.http?
        handle_http message
      end
    when mac_management
      forward message
    else
      if datapath_id != dpid_guest
        raise "Packet-in from unknown dpid!"
      end
      forward message
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def learn message
    @fdbs[ message.datapath_id ].learn message.macsa, message.in_port
  end


  def mac_guest
    $vm[ :guest ][ :mac ]
  end


  def mac_management
    $vm[ :management ][ :mac ]
  end


  def dpid_guest
    $switch[ :guest ][ :dpid ]
  end


  def dpid_management
    $switch[ :management ][ :dpid ]
  end


  def handle_http message
    if management_vm_port
      packet_out dpid_management, message, management_vm_port
    end
  end


  def forward message
    fdb = @fdbs[ message.datapath_id ]
    port_no = fdb.port_no_of( message.macda )
    if port_no
      flow_mod message.datapath_id, message, port_no
      packet_out message.datapath_id, message, port_no
    else
      flood message
    end
  end


  def management_vm_port
    @fdbs[ dpid_management ].port_no_of( mac_management )
  end


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


  def flood message
    @fdbs.keys.each do | each |
      packet_out each, message, OFPP_FLOOD
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
