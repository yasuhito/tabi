require "fileutils"


def base_dir
  File.join File.dirname( __FILE__ ), ".."
end


def dir name, *names
  path = File.join( *names )
  Kernel.send( :define_method, name ) do
    FileUtils.mkdir_p path if not File.directory?( path )
    path
  end
end


dir :script_dir, base_dir, "script"
dir :vendor_dir, base_dir, "vendor"
dir :tmp_dir, base_dir, "tmp"
dir :object_dir, tmp_dir, "object"
dir :openvswitch_dir, vendor_dir, "openvswitch-1.4.0"
dir :vswitch_dir, tmp_dir, "openvswitch"
dir :vswitch_run_dir, vswitch_dir, "run", "openvswitch"
dir :vswitch_log_dir, vswitch_dir, "log", "openvswitch"


def vsctl
  File.join object_dir, "bin", "ovs-vsctl"
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
