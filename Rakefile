# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path( File.dirname( __FILE__ ) )
$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), "lib" )

require "rubygems"

require "common"
require "config"
require "rake"
require "rake/clean"
require "rdoc/task"


################################################################################
# clean and clobber
################################################################################

CLOBBER.include object_dir
CLOBBER.include tmp_dir
CLOBBER.include openvswitch_dir


task :clean do
  if FileTest.exists?( openvswitch_dir )
    cd openvswitch_dir do
      sh "make clean"
    end
  end
end


################################################################################
# Open vSwitch
################################################################################

# [TODO] これ書かなくてもいいようにする
directory vswitch_dir
directory vswitch_run_dir
directory vswitch_log_dir


def vswitchd
  File.join object_dir, "sbin", "ovs-vswitchd"
end


def vswitch_pid
  File.join vswitch_run_dir, "ovs-vswitchd.pid"
end


def vswitch_running?
  FileTest.exists? vswitch_pid
end


def vswitch_log
  File.join vswitch_log_dir, "ovs-vswitchd.log"
end


def maybe_kill_vswitch
  return if not vswitch_running?
  pid = `cat #{ vswitch_pid }`.chomp
  sh "sudo kill #{ pid }" rescue nil
end


def start_vswitch
  sh "sudo #{ vswitchd } --log-file=#{ vswitch_log } --pidfile=#{ vswitch_pid } --detach"
end


def openvswitch_makefile
  File.join openvswitch_dir, "Makefile"
end


file openvswitch_makefile do
  cd vendor_dir do
    sh "tar xzvf openvswitch-1.4.0.tar.gz"
  end
  cd openvswitch_dir do
    sh "./configure --prefix=#{ object_dir } --localstatedir=#{ vswitch_dir } --sysconfdir=#{ tmp_dir }"
  end
end


def build_openvswitch
  cd openvswitch_dir do
    sh "make"
    sh "make install"
  end
end


file vswitchd => openvswitch_makefile do
  build_openvswitch
end


def add_switch bridge, dpid
  sh "#{ vsctl } del-br #{ bridge }" rescue nil
  sh "#{ vsctl } add-br #{ bridge }"
  dpid_long = "%016d" % dpid
  sh "#{ vsctl } set bridge #{ bridge } datapath_type=netdev other-config:datapath-id=#{ dpid_long }"
end


desc "show network config"
task :show => "run:db_server" do
  sh "#{ vsctl } show"
end


namespace :run do
  desc "start vswitch"
  task :vswitch => [ vswitchd, vswitch_log_dir, vswitch_run_dir, "run:db_server" ] do
    next if vswitch_running?
    start_vswitch
    $switch.each do | name, attr |
      add_switch attr[ :bridge ], attr[ :dpid ]
    end
  end
end


namespace :kill do
  desc "kill vswitch"
  task :vswitch do
    maybe_kill_vswitch
  end
end


################################################################################
# NAT
################################################################################

desc "enable NAT"
task :nat do
  sh "sudo ip link delete veth" rescue nil
  sh "sudo ip link add name veth type veth peer name veths"
  sh "sudo ifconfig veth #{ $gateway }/24"
  sh "sudo ifconfig veths up"
  sh "sudo ifconfig veth up"
  sh "#{ vsctl } del-port #{ $switch[ :guest ][ :bridge ] } veths" rescue nil
  sh "#{ vsctl } add-port #{ $switch[ :guest ][ :bridge ] } veths"
  sh "sudo iptables -F"
  sh "sudo iptables -A FORWARD -i veth -o eth0 -j ACCEPT"
  sh "sudo iptables -t nat -F"
  sh "sudo iptables -t nat -A POSTROUTING -o eth0 -s #{ $network } -j MASQUERADE"
end


################################################################################
# Open vSwitch DB server
################################################################################

def db_server
  File.join object_dir, "sbin", "ovsdb-server"
end


def db_tool
  File.join object_dir, "bin", "ovsdb-tool"
end


def db_server_socket
  "punix:#{ File.join tmp_dir, "openvswitch", "run", "openvswitch", "db.sock" }"
end


def db_server_pid
  File.join vswitch_run_dir, "ovsdb-server.pid"
end


def db_server_running?
  FileTest.exists? db_server_pid
end


def maybe_kill_db_server
  return if not db_server_running?
  pid = `cat #{ db_server_pid }`.chomp
  sh "kill #{ pid }" rescue nil
end


def db
  File.join vswitch_dir, "conf.db"
end

task :db => [ db_server, vswitch_dir ] do
  next if FileTest.exists?( db )
  sh "#{ db_tool } create #{ db } #{ File.join object_dir, "share/openvswitch/vswitch.ovsschema" }"
end


def start_db_server
  sh "#{ db_server } --remote=#{ db_server_socket } --remote=db:Open_vSwitch,manager_options --pidfile --detach"
end


file db_server => openvswitch_makefile do
  build_openvswitch
end


namespace :run do
  desc "start db server"
  task :db_server => [ db_server, :db, vswitch_log_dir, vswitch_run_dir ] do
    next if db_server_running?
    start_db_server
  end
end


namespace :kill do
  desc "kill db server"
  task :db_server do
    maybe_kill_db_server
  end
end


################################################################################
# DHCP server
################################################################################

def dhcpd_running?
  /start\/running/=~ `status isc-dhcp-server`
end


def etc_file path
  file = File.open( File.join( tmp_dir, File.basename( path ) ), "w" )
  yield file
  file.close
  sh "sudo cp #{ file.path } #{ File.dirname path }"
end


def maybe_install_dhcpd
  if not FileTest.exist?( "/var/lib/dpkg/info/isc-dhcp-server.md5sums" )
    sh "sudo apt-get install isc-dhcp-server"
  end
end


def setup_dhcpd
  sh "sudo cp #{ File.join script_dir, "isc-dhcp-server.conf" } /etc/init/"

  etc_file( "/etc/default/isc-dhcp-server" ) do | file |
    file.puts %{INTERFACES="eth0"}
  end

  subnet = $network[/\A([^\/]+)/]
  etc_file( "/etc/dhcp/dhcpd.conf" ) do | file |
    file.puts <<-EOF
option domain-name-servers 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;

subnet #{ subnet } netmask #{ $netmask } {
  option routers #{ $gateway };
  host guest {
    hardware ethernet #{ $vm[ :guest ][ :mac ]};
    fixed-address #{ $vm[ :guest ][ :ip ] };
  }
}
EOF
  end
end


def start_dhcpd
  sh "sudo start isc-dhcp-server"
end


def maybe_kill_dhcpd
  sh "sudo stop isc-dhcp-server" if dhcpd_running?
end


# [TODO] service VM 以外で run:dhcp をやろうとすると怒るようにする
namespace :run do
  task :dhcp => "service:networking" do
    next if dhcpd_running?
    maybe_install_dhcpd
    setup_dhcpd
    maybe_kill_dhcpd
    start_dhcpd
  end
end


namespace :kill do
  task :dhcp do
    maybe_kill_dhcpd
  end
end


################################################################################
# KVM
################################################################################

def vm_dir name
  File.join tmp_dir, "vm", name.to_s
end


def runsh name
  File.join vm_dir( name ), "run.sh"
end


def vm_image name
  File.join vm_dir( name ), "image.qcow2"
end


def qcow2 name
  Dir.glob( File.join( vm_dir( name ), "/tmp*.qcow2" ) ).first
end


def maybe_buildvm name
  if qcow2( name ).nil?
    sh "sudo vmbuilder kvm ubuntu --suite oneiric -d #{ vm_dir name } --overwrite"
  end
  mv qcow2( name ), vm_image( name )
end


def ovs_ifup
  File.join script_dir, "ovs-ifup"
end


def ovs_ifdown
  File.join script_dir, "ovs-ifdown"
end


def generate_runsh name, memory, mac, tap
  File.open( runsh( name ), "w" ) do | f |
    f.puts <<-EOF
#!/bin/sh

exec kvm -m #{ memory } -smp 1 -drive file=#{ vm_image name } -net nic,macaddr=#{ mac } -net tap,ifname=#{ tap },script=#{ ovs_ifup },downscript=#{ ovs_ifdown } "$@"
EOF
  end
  sh "chmod +x #{ runsh name }"
end


$vm.each do | name, attr |
  file vm_image( name ) do
    maybe_buildvm name
  end


  file runsh( name ) => vm_image( name ) do
    generate_runsh name, attr[ :memory ], attr[ :mac ], attr[ :tap ]
  end


  desc "start #{ name } VM"
  task name => [ runsh( name ), "run:vswitch" ] do
    sh "sudo #{ runsh name }"
  end
end


################################################################################
# Trema
################################################################################

desc "run controller"
task :trema => "run:vswitch" do
  $switch.each do | name, attr |
    sh "#{ vsctl } set-controller #{ attr[ :bridge ] } tcp:127.0.0.1"
  end
  begin
    sh "#{ trema } run #{ File.join script_dir, "tabi.rb" }"
  ensure
    $switch.each do | name, attr |
      sh "#{ vsctl } del-controller #{ attr[ :bridge ] }"
    end
  end
end


################################################################################
# Misc.
################################################################################

desc "show todo"
task :todo do
  cd File.dirname( __FILE__ ) do
    files = FileList[ "*/**/*.rb" ] + FileList[ "Rakefile", "bin/tabi" ]
    files.each do | each |
      sh %{grep -H -n -A1 -B1 "\\[TODO\\]" #{ each }}, :verbose => false rescue nil
    end
  end
end


################################################################################
# tabi command (gli related tasks)
################################################################################

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Your application title'
end

# require "rubygems/package_task"
#
# spec = eval(File.read('tabi.gemspec'))
# Gem::PackageTask.new(spec) do |pkg|
# end

# require 'rake/testtask'
# Rake::TestTask.new do |t|
#   t.libs << "test"
#   t.test_files = FileList['test/tc_*.rb']
# end

# task :default => :test


################################################################################
# VM setup
################################################################################

def squid_running?
  FileTest.exists? "/var/run/squid3.pid"
end


def maybe_install_squid
  if not FileTest.exist?( "/var/lib/dpkg/info/squid3.md5sums" )
    sh "sudo apt-get install squid3"
  end
end


def setup_squid
  etc_squid = "/etc/squid3/"
  sh "sudo cp #{ File.join script_dir, "redirector.rb" } #{ etc_squid }"
  sh "sudo chmod +x #{ etc_squid }/redirector.rb"

  etc_file( File.join etc_squid, "squid.conf" ) do | file |
    file.puts <<-EOF
acl all src all
acl localhost src 127.0.0.1/32
acl localnet src #{ $network }

acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443

http_access allow localnet
http_access allow localhost
http_access deny all
icp_access deny all

http_port #{ $proxy_port } transparent
url_rewrite_program #{ etc_squid }/redirector.rb
always_direct allow all

acl CONNECT method CONNECT
access_log /var/log/squid3/access.log squid
hosts_file /etc/hosts
coredump_dir /var/spool/squid3
EOF
  end
end


def maybe_kill_squid
  sh "sudo service squid3 stop" if squid_running?
end


def start_squid
  sh "sudo service squid3 start"
end


def redirect_http
  sh "sudo iptables -t nat -F"
  sh "sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports #{ $proxy_port }"
end


namespace :run do
  task :squid do
    redirect_http
    next if squid_running?
    maybe_install_squid
    setup_squid
    maybe_kill_squid
    start_squid
  end
end


namespace :kill do
  task :squid do
    maybe_kill_squid
  end
end


def setup_network
  tmp_interfaces = File.join( tmp_dir, "interfaces" )
  File.open( tmp_interfaces, "w" ) do | file |
    file.puts <<-EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address #{ $vm[ :service ][ :ip ] }
  netmask #{ $netmask }
  gateway #{ $gateway }
EOF
  end
  sh "sudo cp #{ tmp_interfaces } /etc/network/"
  sh "sudo /etc/init.d/networking restart"
end


namespace :service do
  task :networking do
    etc_file( "/etc/network/interfaces" ) do | file |
      file.puts <<-EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address #{ $vm[ :service ][ :ip ] }
  netmask #{ $netmask }
  gateway #{ $gateway }
EOF
    end
    sh "sudo /etc/init.d/networking restart"
  end
end


namespace :start do
  desc "start services"
  task :service => [ "run:dhcp", "run:squid" ]
end


namespace :stop do
  desc "stop services"
  task :service => [ "kill:dhcp", "kill:squid" ]
end
