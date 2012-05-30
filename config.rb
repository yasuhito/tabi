# -*- coding: utf-8 -*-

# ネットワーク情報
$network = "192.168.0.0/24"
$gateway = "192.168.0.254"
$netmask = "255.255.255.0"

# 透過プロキシのポート番号
$proxy_port = 3128

# VM の設定
$vm = {
  :management => { :mac => "8a:0b:b3:32:74:9c", :memory => 512, :tap => "tap0", :ip => "192.168.0.1" },
  :guest => { :mac => "00:11:22:ee:ee:02", :memory => 1024, :tap => "tap1", :ip => "192.168.0.2" }
}

# vSwitch の設定
$switch = {
  :management => { :dpid => 0x1, :bridge => "br0" },
  :guest => { :dpid => 0x2, :bridge => "br1" },
}

# trema コマンドの場所
def trema
  File.expand_path File.join( File.dirname( __FILE__ ), "..", "trema", "trema" )
end
