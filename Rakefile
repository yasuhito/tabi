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

CLOBBER.include "objects"

task :clean do
  cd openvswitch_dir do
    sh "make clean"
  end
end


################################################################################
# Open vSwitch
################################################################################

def openvswitch_dir
  File.join vendor_dir, "openvswitch-1.4.0"
end


def openvswitch_localstate_dir
  File.join tmp_dir, "openvswitch"
end


def db_server
  File.join objects_dir, "sbin", "ovsdb-server"
end


def db_server_socket
  "punix:#{ File.join tmp_dir, "openvswitch", "run", "openvswitch", "db.sock" }"
end


task :openvswitch do
  cd openvswitch_dir do
    sh "./configure --prefix=#{ objects_dir } --localstatedir=#{ openvswitch_localstate_dir } --sysconfdir=#{ tmp_dir }"
    sh "make"
    sh "make install"
  end
end


def vswitch_run_dir
  File.join tmp_dir, "openvswitch", "run", "openvswitch"
end


def db_server_pid
  File.join vswitch_run_dir, "ovsdb-server.pid"
end


def maybe_restart_db_server
  if FileTest.exists?( db_server_pid )
    pid = `cat #{ db_server_pid }`.chomp
    sh "kill #{ pid }"
  end
end


def vswitchd
  File.join objects_dir, "sbin", "ovs-vswitchd"
end


def vswitch_pid
  File.join vswitch_run_dir, "ovs-vswitchd.pid"
end


def maybe_restart_vswitch
  if FileTest.exists?( vswitch_pid )
    pid = `cat #{ vswitch_pid }`.chomp
    sh "sudo kill #{ pid }"
  end
end


def vsctl
  File.join objects_dir, "bin", "ovs-vsctl"
end


namespace :run do
  desc "(Re-)start db server"
  task :db_server do
    maybe_restart_db_server
    sh "#{ db_server } --remote=#{ db_server_socket } --remote=db:Open_vSwitch,manager_options --pidfile --detach"
  end

  desc "start vswitch"
  task :vswitch => :db_server do
    maybe_restart_vswitch
    sh "sudo #{ vswitchd } --log-file --pidfile --detach"
    sh "#{ vsctl } del-br br0"
    sh "#{ vsctl } add-br br0"
    sh "#{ vsctl } set bridge br0 datapath_type=netdev"
  end
end


################################################################################
# KVM
################################################################################

def vmdir
  File.join File.dirname( __FILE__ ), "tmp", "vm"
end


def runner name
  File.join vmdir, name.to_s, "run.sh"
end


desc "動作確認用 VM をセットアップ"
task :vm => [ "vm:guest", "vm:dhcpd" ]

namespace :vm do
  [ :guest, :dhcpd ].each do | each |
    task each => runner( each )
    file runner( each ) do
      sh "sudo vmbuilder kvm ubuntu --suite oneiric -d #{ File.join( vmdir, each.to_s ) } --overwrite"
    end
  end
end


desc "run guest VM"
task "run:guest" do
  cd File.join( tmp_dir, "vm", "guest" ) do
    sh "sudo ./run.sh"
  end
end


desc "run dhcpd VM"
task "run:dhcpd" do
  cd File.join( tmp_dir, "vm", "dhcpd" ) do
    sh "sudo ./run.sh"
  end
end
