# -*- coding: utf-8 -*-
require "config"


# [TODO] コントローラを eval ではなく普通に load するように Trema 本体を修正
# ↓こういうのが "module Trema; class PacketIn ... end; end" とも書けるように。
class Trema::PacketIn
  def http?
    tcp_dst_port == 80
  end


  def from_guest?
    macsa.to_s == $vm[ :guest ][ :mac ]
  end


  def to_guest?
    macda.to_s == $vm[ :guest ][ :mac ]
  end
end


class Tabi < Controller
  attr_reader :guest_vm_port


  def switch_ready dpid
    info "#{ switch_name dpid } switch connected"
  end


  def packet_in dpid, message
    if message.from_guest?
      @guest_vm_port ||= message.in_port
      if message.http?
        packet_out_management message
      else
        flood message
      end
    elsif message.to_guest?
      packet_out_guest message
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


  def packet_out_management message
    # [TODO] ActionSetDlDst.new( "00:11:22:33:44:55" ) と書けるように Trema 本体を修正
    send_packet_out(
      dpid_management,
      :packet_in => message,
      :actions => [
        ActionSetDlDst.new( :dl_dst => Trema::Mac.new( $vm[ :management ][ :mac ] ) ),
        ActionOutput.new( management_vm_port )
      ]
    )
  end


  def packet_out_guest message
    send_packet_out(
      dpid_guest,
      :packet_in => message,
      :actions => ActionOutput.new( guest_vm_port )
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
