# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','tabi_version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'tabi'
  s.version = Tabi::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
# Add your other files here if you make them
  s.files = %w(
bin/tabi
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','tabi.rdoc']
  s.rdoc_options << '--title' << 'tabi' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'tabi'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
end
