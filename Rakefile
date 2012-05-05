# -*- coding: utf-8 -*-
require "rubygems"
require "rake"
require "rake/clean"
require "config"


################################################################################
# Paths
################################################################################

def base_dir
  File.dirname( __FILE__ )
end


def objects_dir
  File.join base_dir, "objects"
end


def tmp_dir
  File.join base_dir, "tmp"
end


def vendor_dir
  File.join base_dir, "vendor"
end


################################################################################
# clean and clobber
################################################################################

def openvswitch_dir
  File.join vendor_dir, "openvswitch-1.4.0"
end


CLOBBER.include "objects"
CLOBBER.include "tmp"
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

def openvswitch_localstate_dir
  File.join tmp_dir, "openvswitch"
end


def vswitch_dir
  File.join tmp_dir, "openvswitch"
end

directory vswitch_dir


def vswitch_run_dir
  File.join vswitch_dir, "run", "openvswitch"
end

directory vswitch_run_dir


def vswitch_log_dir
  File.join vswitch_dir, "log", "openvswitch"
end

directory vswitch_log_dir


def vswitchd
  File.join objects_dir, "sbin", "ovs-vswitchd"
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


def vsctl
  File.join objects_dir, "bin", "ovs-vsctl"
end


def openvswitch_makefile
  File.join openvswitch_dir, "Makefile"
end


file openvswitch_makefile do
  cd vendor_dir do
    sh "tar xzvf openvswitch-1.4.0.tar.gz"
  end
  cd openvswitch_dir do
    sh "./configure --prefix=#{ objects_dir } --localstatedir=#{ openvswitch_localstate_dir } --sysconfdir=#{ tmp_dir }"
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
  sh "sudo ip link delete veth"
  sh "sudo ip link add name veth type veth peer name veths"
  sh "sudo ifconfig veth #{ $gateway }/24"
  sh "sudo ifconfig veths up"
  sh "sudo ifconfig veth up"
  sh "#{ vsctl } del-port #{ $switch[ :guest ][ :bridge ] } veths"
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
  File.join objects_dir, "sbin", "ovsdb-server"
end


def db_tool
  File.join objects_dir, "bin", "ovsdb-tool"
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
  sh "#{ db_tool } create #{ db } #{ File.join objects_dir, "share/openvswitch/vswitch.ovsschema" }"
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
  File.join base_dir, "ovs-ifup"
end


def ovs_ifdown
  File.join base_dir, "ovs-ifdown"
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

desc "run controller"
task :trema do
  $switch.each do | name, attr |
    sh "#{ vsctl } set-controller #{ attr[ :bridge ] } tcp:127.0.0.1"
  end
  begin
    sh "../trema/trema run tabi.rb"
  ensure
    $switch.each do | name, attr |
      sh "#{ vsctl } del-controller #{ attr[ :bridge ] }"
    end
  end
end
