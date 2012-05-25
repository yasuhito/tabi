# -*- coding: utf-8 -*-
require "fileutils"


################################################################################
# !!! ここは編集しない !!!
################################################################################

def base_dir
  File.dirname __FILE__
end


def dir name, *names
  path = File.join( base_dir, *names )
  Kernel.send( :define_method, name ) do
    FileUtils.mkdir_p path if not File.directory?( path )
    path
  end
end


def command name, *names
  path = File.expand_path( File.join base_dir, *names )
  Kernel.send( :define_method, name ) do
    path
  end
end


################################################################################
# ここから設定
################################################################################

$network = "192.168.0.0/24"
$gateway = "192.168.0.254"
$netmask = "255.255.255.0"
$proxy_port = 3128

$vm = {
  :management => { :mac => "00:11:22:ee:ee:01", :memory => 256, :tap => "tap0", :ip => "192.168.0.1" },
  :guest => { :mac => "00:11:22:ee:ee:02", :memory => 128, :tap => "tap1", :ip => "192.168.0.2" }
}

$switch = {
  :management => { :dpid => 0x1, :bridge => "br0" },
  :guest => { :dpid => 0x2, :bridge => "br1" },
}

$ovs_vsctl = File.join( File.dirname( __FILE__ ), "objects/bin/ovs-vsctl" )


################################################################################
# Paths
################################################################################

dir :tmp_dir, "tmp"
dir :pending_dir, tmp_dir, "pending"
dir :allow_dir, tmp_dir, "allow"
dir :deny_dir, tmp_dir, "deny"

command :trema, "..", "trema", "trema"
