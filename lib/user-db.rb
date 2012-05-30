# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), ".." )

require "common"
require "config"
require "fileutils"


dir :pending_dir, tmp_dir, "pending"
dir :allow_dir, tmp_dir, "allow"
dir :deny_dir, tmp_dir, "deny"


class UserDB
  def cleanup
    FileUtils.rm_rf pending_dir
    FileUtils.rm_rf allow_dir
    FileUtils.rm_rf deny_dir
  end


  def pending mac
    return if allowed?( mac )
    return if denied?( mac )
    FileUtils.touch File.join( pending_dir, mac )
  end


  # [TODO] allowed? とかぶってるのでリファクタリング
  def pending? mac
    list = Dir.glob( File.join( pending_dir, "*" ) ).collect do | each |
      File.basename each
    end
    list.include? mac.to_s
  end


  def allow mac
    check_pending_user mac
    FileUtils.mv File.join( pending_dir, mac ), allow_dir
  end


  def allowed? mac
    list = Dir.glob( File.join( allow_dir, "*" ) ).collect do | each |
      File.basename each
    end
    list.include? mac.to_s
  end


  def deny mac
    check_pending_user mac
    FileUtils.mv File.join( pending_dir, mac ), deny_dir
  end


  def denied? mac
    list = Dir.glob( File.join( deny_dir, "*" ) ).collect do | each |
      File.basename each
    end
    list.include? mac.to_s
  end


  ##############################################################################
  private
  ##############################################################################


  def check_pending_user mac
    if not pending?( mac )
      raise "No such pending user: #{ mac }"
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
