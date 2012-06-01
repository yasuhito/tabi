# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), "lib" )

require "config"
require "fdb"
require "packet-in"
require "user-db"


# Facebook を使った認証 VLAN っぽいことをするための OpenFlow コントローラ
class Tabi < Controller
  SERVICE_VM_PORT = 1
  DPID_GUEST = $switch[ :guest ][ :dpid ]
  DPID_SERVICE = $switch[ :service ][ :dpid ]


  def start
    @user_db = UserDB.new.cleanup
    @fdb = FDB.new
  end


  def packet_in dpid, message
    @fdb.learn message.macsa, message.in_port, dpid
    if guest_packet? message
      handle_guest_packet message
    else
      handle_service_packet message
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def guest_packet? message
    macsa = message.macsa
    @user_db.pending?( macsa ) or @user_db.allowed?( macsa ) or @user_db.denied?( macsa )
  end


  def handle_guest_packet message
    macsa = message.macsa
    if @user_db.pending?( macsa )
      handle_pending message
    elsif @user_db.allowed?( macsa )
      l2_switch message
    elsif @user_db.denied?( macsa )
      # DROP
    end
  end


  def handle_service_packet message
    @user_db.pending( message.macda ) if message.dhcp_pack?
    l2_switch message
  end


  def handle_pending message
    if message.http?
      packet_out_service_vm message
    elsif message.https?
      # [TODO] FB だけに限定し、かつゲートウェイだけに出す
      flood message
    elsif message.arp? or message.dhcp? or message.dns?
      flood message
    else
      # DROP
    end
  end


  def l2_switch message
    dpid, port_no = @fdb[ message.macda ]
    if dpid and port_no
      flow_mod dpid, message, port_no
      packet_out dpid, message, port_no
    else
      flood message
    end
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


  def packet_out_service_vm message
    # [TODO] ActionSetDlDst.new( "00:11:22:33:44:55" ) と書けるように Trema 本体を修正
    send_packet_out(
      DPID_SERVICE,
      :packet_in => message,
      :actions => [
        ActionSetDlDst.new( :dl_dst => Mac.new( $vm[ :service ][ :mac ] ) ),
        ActionOutput.new( SERVICE_VM_PORT )
      ]
    )
  end


  def flood message
    [ DPID_GUEST, DPID_SERVICE ].each do | each |
      packet_out each, message, OFPP_FLOOD
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
