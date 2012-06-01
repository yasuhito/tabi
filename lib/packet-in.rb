# -*- coding: utf-8 -*-
# Trema::PacketIn にいくつか便利メソッドを追加
class Trema::PacketIn
  def http?
    tcp_dst_port == 80 or tcp_dst_port == 3000
  end


  def https?
    tcp_dst_port == 443
  end


  def dhcp?
    ( udp_src_port == 67 and udp_dst_port == 68 ) or ( udp_src_port == 68 and udp_dst_port == 67 )
  end


  def dhcp_pack?
    # [TODO] ちゃんとパーズする
    if udp_src_port == 67 and udp_dst_port == 68
      data.unpack( "H*" )[ 0 ][ -116, 2 ] == "05"
    end
  end


  def dns?
    udp_dst_port == 53
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
