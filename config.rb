require "fileutils"


$network = "192.168.0.0/24"
$gateway = "192.168.0.254"
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

def base_dir
  File.dirname __FILE__
end


def tmp_dir
  path = File.join( base_dir, "tmp" )
  FileUtils.mkdir_p path if not File.directory?( path )
  path
end


def pending_dir
  File.join tmp_dir, "pending"
end


def allow_dir
  File.join tmp_dir, "allow"
end


def deny_dir
  File.join tmp_dir, "deny"
end
