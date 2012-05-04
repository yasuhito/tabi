$network = "192.168.0.0/24"
$gateway = "192.168.0.254"
$switch = {
  :management => { :bridge => "br0", :dpid => 0x1 },
  :guest => { :bridge => "br1", :dpid => 0x2 }
}
$memory = { :management => 256, :guest => 128 }
$tap = { :management => "tap0", :guest => "tap1" }
$mac = { :management => "00:11:22:ee:ee:01", :guest => "00:11:22:ee:ee:02" }

$ovs_vsctl = File.join( File.dirname( __FILE__ ), "objects/bin/ovs-vsctl" )
