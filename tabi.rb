require "config"


class Trema::PacketIn
  def http?
    tcp_dst_port == 80
  end
end


class Tabi < Controller
  def switch_ready dpid
    info "#{ switch_name dpid } switch connected"
  end


  def packet_in dpid, message
    if message.macsa.to_s == $vm[ :guest ][ :mac ]
      if message.arp? or message.icmpv4?
        flood message
      elsif message.http?
        packet_out_squid message
      end
    else
      flood message
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def switch_name dpid
    $switch.each do | name, attr |
      return name if attr[ :dpid ] == dpid
    end
    raise "Switch not found! (dpid = #{ dpid.to_hex })"
  end


  def dpid_guest
    $switch[ :guest ][ :dpid ]
  end


  def dpid_management
    $switch[ :management ][ :dpid ]
  end


  def management_vm_port
    1
  end


  def packet_out dpid, message, port_no
    send_packet_out(
      dpid,
      :packet_in => message,
      :actions => ActionOutput.new( port_no )
    )
  end


  def packet_out_squid message
    send_packet_out(
      dpid_management,
      :packet_in => message,
      :actions => [ ActionSetTpDst.new( :tp_dst => 3128 ), ActionOutput.new( management_vm_port ) ]
    )
  end


  def flood message
    [ dpid_guest, dpid_management ].each do | each |
      packet_out each, message, OFPP_FLOOD
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
