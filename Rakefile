# -*- coding: utf-8 -*-
require "rubygems"
require "rake"


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

