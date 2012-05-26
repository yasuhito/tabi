# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), ".." )

require "config"
require "fileutils"


dir :pending_dir, tmp_dir, "pending"
dir :allow_dir, tmp_dir, "allow"
dir :deny_dir, tmp_dir, "deny"


class ForwardingEntry
  attr_reader :mac
  attr_reader :port_no
  attr_reader :dpid


  def initialize mac, port_no, dpid
    @mac = mac
    @port_no = port_no
    @dpid = dpid
  end
end


class FDB
  attr_reader :db


  def initialize
    @db = {}
  end


  def port_no_of mac
    dest = @db[ mac.to_s ]
    if dest
      dest.port_no
    else
      nil
    end
  end


  def learn mac, port_no, dpid = nil
    if @db[ mac.to_s ].nil?
      @db[ mac.to_s ] = ForwardingEntry.new( mac.to_s, port_no, dpid )
    end
  end


  def lookup mac
    @db[ mac.to_s ]
  end
end


class UserDB
  def initialize
    cleanup_db
    @fdb = FDB.new
  end


  def pending? mac
    list = Dir.glob( File.join( pending_dir, "*" ) ).collect do | each |
      File.basename each
    end
    list.include? mac
  end


  def allowed? mac
    list = Dir.glob( File.join( allow_dir, "*" ) ).collect do | each |
      File.basename each
    end
    list.include? mac
  end


  def dest_port_of message
    @fdb.port_no_of message.macda
  end


  def mac_list
    @fdb.db.keys
  end


  def learn message
    add_to_pending message.macsa if new_user?( message )
    @fdb.learn message.macsa, message.in_port
  end


  ##############################################################################
  private
  ##############################################################################


  def cleanup_db
    FileUtils.rm_rf pending_dir
  end


  def new_user? message
    @fdb.lookup( message.macsa ).nil?
  end


  def add_to_pending macsa
    FileUtils.touch File.join( pending_dir, macsa.to_s )
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
