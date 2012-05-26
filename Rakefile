# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path( File.dirname( __FILE__ ) )

require "rubygems"
require "config"
require "rake"
require "rake/clean"
require "rdoc/task"
require "rubygems/package_task"


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
  if vswitch_running?
    pid = `cat #{ vswitch_pid }`.chomp
    sh "sudo kill #{ pid }" rescue nil
  end
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
task :show do
  if db_server_running?
    sh "#{ vsctl } show"
  end
end


# MEMO: 各 VM で "sudo route add default gw 192.168.0.254
def start_nat
  sh "sudo ip link delete veth" rescue nil
  sh "sudo ip link add name veth type veth peer name veths"
  sh "sudo ifconfig veth #{ $gateway }/24"
  sh "sudo ifconfig veths up"
  sh "sudo ifconfig veth up"
  sh "#{ vsctl } del-port #{ $switch[ :guest ][ :bridge ] } veths" rescue nil
  sh "#{ vsctl } add-port #{ $switch[ :guest ][ :bridge ] } veths"
  sh "sudo iptables -A FORWARD -i veth -o eth0 -j ACCEPT"
  sh "sudo iptables -t nat -A POSTROUTING -o eth0 -s #{ $network } -j MASQUERADE"
end


namespace :run do
  desc "start vswitch"
  task :vswitch => [ vswitchd, vswitch_log_dir, vswitch_run_dir ] do
    Rake::Task[ "run:db_server" ].invoke
    if not vswitch_running?
      start_vswitch
      $switch.each do | name, attr |
        add_switch attr[ :bridge ], attr[ :dpid ]
      end
    end
    start_nat
  end
end


namespace :kill do
  desc "kill vswitch"
  task :vswitch do
    maybe_kill_vswitch
  end
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
  if db_server_running?
    pid = `cat #{ db_server_pid }`.chomp
    sh "kill #{ pid }" rescue nil
  end
end


def db
  File.join vswitch_dir, "conf.db"
end

file db => [ db_server, vswitch_dir ] do
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
  task :db_server => [ db_server, db, vswitch_log_dir, vswitch_run_dir ] do
    if not db_server_running?
      maybe_kill_db_server
      start_db_server
    end
  end
end


namespace :kill do
  desc "kill db server"
  task :db_server do
    maybe_kill_db_server
  end
end


namespace :run do
  desc "start DHCP server"
  task :dhcp do
    # [TODO] subnet がハードコードされているのを直す
    # [TODO] 複数クライアントに対応
    sh "sudo apt-get install isc-dhcp-server"
    tmp_dhcpd_conf = File.join( tmp_dir, "dhcpd.conf" )
    File.open( tmp_dhcpd_conf, "w" ) do | file |
      file.puts <<-EOF
option domain-name-servers 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;

subnet 192.168.0.0 netmask #{ $netmask } {
  option routers #{ $gateway };
  host guest {
    hardware ethernet #{ $vm[ :guest ][ :mac ]};
    fixed-address #{ $vm[ :guest ][ :ip ] };
  }
}
EOF
    end
    sh "sudo cp #{ tmp_dhcpd_conf } /etc/dhcp/"
    sh "sudo stop isc-dhcp-server"
    sh "sudo start isc-dhcp-server"
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


  namespace :vm do
    desc "start #{ name } VM"
    task name => [ runsh( name ), "run:vswitch" ] do
      sh "sudo #{ runsh name }"
    end
  end
end


################################################################################
# Trema
################################################################################

# [TODO] vswitch が動いてない状態でいきなり rake trema しても動くように
desc "run controller"
task :trema do
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
  sh %{find . -name "*.rb" | xargs grep -n -A1 -B1 "\\[TODO\\]" -}
end


################################################################################
# tabi command (gli related tasks)
################################################################################

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Your application title'
end

spec = eval(File.read('tabi.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb']
end

task :default => :test


################################################################################
# VM setup
################################################################################

def setup_network
  tmp_interfaces = File.join( tmp_dir, "interfaces" )
  File.open( tmp_interfaces, "w" ) do | file |
    file.puts <<-EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address #{ $vm[ :management ][ :ip ] }
  netmask #{ $netmask }
  gateway #{ $gateway }
EOF
  end
  sh "sudo cp #{ tmp_interfaces } /etc/network/"
  sh "sudo /etc/init.d/networking restart"
end


def setup_transparent_proxy
  sh "sudo apt-get install squid"

  # [TODO] squid 設定ディレクトリも変数か定数にする
  sh "sudo cp #{ File.join script_dir, "redirector.rb" } /etc/squid/"
  sh "sudo chmod +x /etc/squid/redirector.rb"

  tmp_squid_conf = File.join( tmp_dir, "squid.conf" )
  File.open( tmp_squid_conf, "w" ) do | file |
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
url_rewrite_program /etc/squid/redirector.rb
always_direct allow all

acl CONNECT method CONNECT
access_log /var/log/squid/access.log squid
hosts_file /etc/hosts
coredump_dir /var/spool/squid
EOF
  end
  sh "sudo cp #{ tmp_squid_conf } /etc/squid/"
  sh "sudo service squid restart"

  tmp_iptables_rules = File.join( tmp_dir, "iptables.rules" )
  File.open( tmp_iptables_rules, "w" ) do | file |
    file.puts <<-EOF
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i eth0 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128
COMMIT
EOF
  end
  sh "sudo cp #{ tmp_iptables_rules } /etc/"

  tmp_iptables_start = File.join( tmp_dir, "iptables_start" )
  File.open( tmp_iptables_start, "w" ) do | file |
    file.puts <<-EOF
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.rules
exit 0
EOF
  end
  sh "sudo cp #{ tmp_iptables_start } /etc/network/if-pre-up.d/"
  sh "sudo chmod a+x /etc/network/if-pre-up.d/iptables_start"
end


namespace :init do
  desc "initialize management VM environment"
  task :management do
    setup_network
    setup_transparent_proxy
  end
end
