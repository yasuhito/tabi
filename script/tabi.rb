# -*- coding: utf-8 -*-
#
# [TODO] LOGGING_LEVEL=debug で実行したときに Trema のログとアプリのログ
#        が混ざって見づらいので、Trema のログだけ別ファイルに保存するように変更

$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), "lib" )

require "config"
require "fdb"
require "user-db"


# [TODO] コントローラを eval ではなく普通に load するように Trema 本体を修正
# ↓こういうのが "module Trema; class PacketIn ... end; end" とも書けるように。
class Trema::PacketIn
  # [TODO] このエイリアスを Trema 本体に追加
  alias :dpid :datapath_id


  def http?
    tcp_dst_port == 80
  end


  def dhcp?
    ( udp_src_port == 67 and udp_dst_port == 68 ) or ( udp_src_port == 68 and udp_dst_port == 67 )
  end


  def dhcp_pack?
    if udp_src_port == 67 and udp_dst_port == 68
      data.unpack( "H*" )[ 0 ][ -116, 2 ] == "05"
    end
  end


  def dns?
    udp_dst_port == 53
  end
end


class Tabi < Controller
  def start
    @user_db = UserDB.new
    @user_db.cleanup
    @fdb = FDB.new
  end


  def switch_ready dpid
    info "#{ switch_name dpid } switch connected"
  end


  def packet_in dpid, message
    @fdb.learn message.macsa, message.in_port, dpid

    if message.dhcp_pack?
      @user_db.pending message.macda.to_s
      packet_out dpid_guest, message, @fdb.port_no_of( message.macda )
      return
    end

    if @user_db.pending?( message.macsa )
      if message.http?
        packet_out_management message
      elsif message.arp? or message.dhcp? or message.dns?
        flood message
      else
        # DROP
      end
    elsif @user_db.allowed?( message.macsa )
      port_no = @fdb.port_no_of( message.macda )
      if port_no
        flow_mod dpid, message, port_no
        packet_out dpid, message, port_no
      else
        flood message
      end
    elsif @user_db.denied?( message.macsa )
      # DROP
    else
      fdb_entry = @fdb[ message.macda ]
      if fdb_entry
        packet_out fdb_entry.dpid, message, fdb_entry.port_no
      else
        flood message
      end
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


  def flow_mod dpid, message, port_no
    send_flow_mod_add(
      dpid,
      :match => ExactMatch.from( message ),
      :actions => ActionOutput.new( port_no )
    )
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
