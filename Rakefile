# -*- coding: utf-8 -*-
require "rubygems"
require "rake"
require "rake/clean"


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


def db_server
  File.join objects_dir, "sbin", "ovsdb-server"
end


def db_server_socket
  "punix:#{ File.join tmp_dir, "openvswitch", "run", "openvswitch", "db.sock" }"
end


def vswitch_run_dir
  File.join tmp_dir, "openvswitch", "run", "openvswitch"
end


def vswitch_log_dir
  File.join tmp_dir, "openvswitch", "log", "openvswitch"
end


def db_server_pid
  File.join vswitch_run_dir, "ovsdb-server.pid"
end


def maybe_kill_db_server
  if FileTest.exists?( db_server_pid )
    pid = `cat #{ db_server_pid }`.chomp
    sh "kill #{ pid }"
  end
end


def start_db_server
  sh "#{ db_server } --remote=#{ db_server_socket } --remote=db:Open_vSwitch,manager_options --pidfile --detach"  
end


def vswitchd
  File.join objects_dir, "sbin", "ovs-vswitchd"
end


def vswitch_pid
  File.join vswitch_run_dir, "ovs-vswitchd.pid"
end


def vswitch_log
  File.join vswitch_log_dir, "ovs-vswitchd.log"
end


def maybe_kill_vswitch
  if FileTest.exists?( vswitch_pid )
    pid = `cat #{ vswitch_pid }`.chomp
    sh "sudo kill #{ pid }"
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


file db_server => openvswitch_makefile do
  build_openvswitch  
end

file vswitchd => openvswitch_makefile do
  build_openvswitch  
end


def add_switch bridge
  sh "#{ vsctl } del-br #{ bridge }" rescue nil
  sh "#{ vsctl } add-br #{ bridge }"
  sh "#{ vsctl } set bridge #{ bridge } datapath_type=netdev"
end


namespace :run do
  desc "start db server"
  task :db_server => db_server do
    maybe_kill_db_server
    start_db_server
  end

  desc "start vswitch"
  task :vswitch => vswitchd do
    Rake::Task[ "run:db_server" ].invoke
    maybe_kill_vswitch
    start_vswitch
    add_switch "br0"
    add_switch "br1"
  end
end


################################################################################
# KVM
################################################################################

def vm_dir name
  File.join File.dirname( __FILE__ ), "tmp", "vm", name.to_s
end


def run_sh name
  File.join vm_dir( name ), "run.sh"
end


def mac_address name
  { :dhcpd => "00:11:22:EE:EE:01", :guest => "00:11:22:EE:EE:02" }[ name ]
end


def qcow2 name
  Dir.glob( File.join( vm_dir( name ), "/*.qcow2" ) ).first  
end


def maybe_buildvm name
  if qcow2( name ).nil?
    sh "sudo vmbuilder kvm ubuntu --suite oneiric -d #{ vm_dir name } --overwrite"
  end
end


def tap name
  { :dhcpd => "tap0", :guest => "tap1" }[ name ]
end


def create_run_sh name
  File.open( run_sh( name ), "w" ) do | f |
    f.puts <<-EOF
#!/bin/sh

exec kvm -m 128 -smp 1 -drive file=#{ qcow2 name } -net nic,macaddr=#{ mac_address name } -net tap,ifname=#{ tap name },script=../../../ovs-ifup.#{ name },downscript=../../../ovs-ifdown.#{ name } "$@"
EOF
  end
  sh "chmod +x #{ run_sh( name ) }"
end


[ :guest, :dhcpd ].each do | each |
  file run_sh( each ) do | t |
    maybe_buildvm each
    create_run_sh each
  end


  namespace :run do
    desc "run #{ each } VM"
    task each => run_sh( each ) do
      cd vm_dir( each ) do
        sh "sudo ./run.sh"
      end
    end
  end
end


################################################################################
# NAT
################################################################################

desc "enable NAT"
task :nat do
  sh "sudo ip link add name veth type veths peer name veth"
  sh "sudo ifconfig veth 192.168.0.254/24"
  sh "sudo ifconfig veths up"
  sh "sudo ifconfig veth up"
  sh "#{ vsctl } add-port br0 veths"
end

# MEMO: このあと各 VM で "sudo route add default gw 192.168.0.254
