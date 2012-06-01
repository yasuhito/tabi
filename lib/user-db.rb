$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), ".." )

require "common"
require "fileutils"


class UserDB
  dir :pending_dir, tmp_dir, "pending"
  dir :allow_dir, tmp_dir, "allow"
  dir :deny_dir, tmp_dir, "deny"


  def cleanup
    FileUtils.rm_rf pending_dir
    FileUtils.rm_rf allow_dir
    FileUtils.rm_rf deny_dir
    self
  end


  def pending mac
    return if allowed?( mac.to_s )
    return if denied?( mac.to_s )
    FileUtils.touch File.join( pending_dir, mac.to_s )
  end


  def pending? mac
    list( :pending ).include? mac.to_s
  end


  def allow mac
    mv_to :allow, mac
  end


  def allowed? mac
    list( :allow ).include? mac.to_s
  end


  def deny mac
    mv_to :deny, mac
  end


  def denied? mac
    list( :deny ).include? mac.to_s
  end


  def list name
    Dir.glob( File.join status_dir( name ), "*" ).collect do | each |
      File.basename each
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def status_dir name
    dir = { :pending => pending_dir, :allow => allow_dir, :deny => deny_dir }[ name ]
    raise "Invalid user status: #{ name }" if dir.nil?
    dir
  end


  def mv_to status, mac
    pending?( mac ) or raise "No such pending user: #{ mac }"
    FileUtils.mv File.join( pending_dir, mac ), status_dir( status )
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
