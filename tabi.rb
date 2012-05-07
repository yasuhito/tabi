require "config"
require "fdb"


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
    fdb = @fdbs[ datapath_id ]
    fdb.learn message.macsa, message.in_port

    case message.macsa.to_s
    when $vm[ :guest ][ :mac ]
      handle_guest_packet message
    when $vm[ :management ][ :mac ]
      forward message
    else
      if datapath_id != $switch[ :guest ][ :dpid ]
        raise "packet-in from unknown dpid!"
      end
      forward message
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def handle_guest_packet message
    if message.arp? or message.icmpv4?
      flood message
    else
      if message.tcp_dst_port == 80 or message.tcp_dst_port == 3000
        info "HTTP from guest VM"
        if management_vm_port
          packet_out $switch[ :management ][ :dpid ], message, management_vm_port
        end
      end
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
    @fdbs[ $switch[ :management ][ :dpid ] ].port_no_of( $vm[ :management ][ :mac ] )
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
