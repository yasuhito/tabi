# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), "lib" )
require "common"


# ネットワーク情報
$network = "192.168.0.0/24"
$gateway = "192.168.0.254"
$netmask = "255.255.255.0"

# 透過プロキシのポート番号
$proxy_port = 3128

# VM の設定
$vm = {
  :management => { :mac => "00:11:22:ee:ee:01", :memory => 1024, :tap => "tap0", :ip => "192.168.0.1" },
  :guest => { :mac => "00:11:22:ee:ee:02", :memory => 128, :tap => "tap1", :ip => "192.168.0.2" }
}

# vSwitch の設定
$switch = {
  :management => { :dpid => 0x1, :bridge => "br0" },
  :guest => { :dpid => 0x2, :bridge => "br1" },
}

# trema コマンドの場所
def trema
  # [TODO] base_dir を使うのをやめて、上の require "common" を無くす。
  File.join base_dir, "..", "trema", "trema"
end
