$network = "192.168.0.0/24"
$gateway = "192.168.0.254"

$switch = {
  :management => { :bridge => "br0", :dpid => 0x1 },
  :guest => { :bridge => "br1", :dpid => 0x2 }
}

$tap = { :dhcpd => "tap0", :guest => "tap1" }
$mac = { :dhcpd => "00:11:22:ee:ee:01", :guest => "00:11:22:ee:ee:02" }
