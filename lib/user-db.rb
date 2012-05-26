# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), ".." )

require "config"
require "fileutils"


dir :pending_dir, tmp_dir, "pending"
dir :allow_dir, tmp_dir, "allow"
dir :deny_dir, tmp_dir, "deny"


class UserDB
  def initialize
    cleanup_db
  end


  # [TODO] allowed? とかぶってるのでリファクタリング
  def pending? mac
    list = Dir.glob( File.join( pending_dir, "*" ) ).collect do | each |
      File.basename each
    end
    list.include? mac.to_s
  end


  def allowed? mac
    list = Dir.glob( File.join( allow_dir, "*" ) ).collect do | each |
      File.basename each
    end
    list.include? mac.to_s
  end


  ##############################################################################
  private
  ##############################################################################


  def cleanup_db
    FileUtils.rm_rf pending_dir
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
