require "rubygems"
require "rake"


def vmdir
  File.join File.dirname( __FILE__ ), "tmp", "vm"
end


def runner name
  File.join vmdir, name.to_s, "run.sh"
end


namespace :vm do
  task :guest => runner( :guest )
  task :dhcpd => runner( :dhcpd )


  file runner( :guest ) do
    sh "sudo vmbuilder kvm ubuntu --suite oneiric -d #{ File.join( vmdir, "guest" ) } --verbose"
  end

  file runner( :dhcpd ) do
    sh "sudo vmbuilder kvm ubuntu --suite oneiric -d #{ File.join( vmdir, "dhcpd" ) } --verbose"
  end
end

