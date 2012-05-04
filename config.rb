$network = "192.168.0.0/24"
$gateway = "192.168.0.254"
$vm = [ :management, :guest ]
$bridge = { :management => "br0", :guest => "br1" }
$tap = { :management => "tap0", :guest => "tap1" }
$dpid = { :management => 0x1, :guest => 0x2 }
$memory = { :management => 256, :guest => 128 }
$mac = { :management => "00:11:22:ee:ee:01", :guest => "00:11:22:ee:ee:02" }

$ovs_vsctl = File.join( File.dirname( __FILE__ ), "objects/bin/ovs-vsctl" )
