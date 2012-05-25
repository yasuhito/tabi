# -*- coding: utf-8 -*-
require "fileutils"


################################################################################
# !!! ここは編集しない !!!
################################################################################

def base_dir
  File.dirname __FILE__
end


def dir name, *names
  path = File.join( *names )
  Kernel.send( :define_method, name ) do
    FileUtils.mkdir_p path if not File.directory?( path )
    path
  end
end


dir :script_dir, base_dir, "script"
dir :vendor_dir, base_dir, "vendor"
dir :tmp_dir, base_dir, "tmp"
dir :object_dir, tmp_dir, "object"
dir :openvswitch_dir, vendor_dir, "openvswitch-1.4.0"
dir :vswitch_dir, tmp_dir, "openvswitch"
dir :vswitch_run_dir, vswitch_dir, "run", "openvswitch"
dir :vswitch_log_dir, vswitch_dir, "log", "openvswitch"


def vsctl
  File.join object_dir, "bin", "ovs-vsctl"
end


################################################################################
# ここから設定
################################################################################

# ネットワーク情報
$network = "192.168.0.0/24"
$gateway = "192.168.0.254"
$netmask = "255.255.255.0"

# 透過プロキシのポート番号
$proxy_port = 3128

# VM の設定
$vm = {
  :management => { :mac => "00:11:22:ee:ee:01", :memory => 256, :tap => "tap0", :ip => "192.168.0.1" },
  :guest => { :mac => "00:11:22:ee:ee:02", :memory => 128, :tap => "tap1", :ip => "192.168.0.2" }
}

# vSwitch の設定
$switch = {
  :management => { :dpid => 0x1, :bridge => "br0" },
  :guest => { :dpid => 0x2, :bridge => "br1" },
}

# trema コマンドの場所
def trema
  File.join base_dir, "..", "trema", "trema"
end
