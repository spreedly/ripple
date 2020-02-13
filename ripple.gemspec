$:.push File.expand_path('../lib', __FILE__)
require 'ripple/version'

Gem::Specification.new do |gem|
  # Meta
  gem.name = "ripple"
  gem.version = Ripple::VERSION
  gem.summary = %Q{ripple is an object-mapper library for Riak, the distributed database by Basho.}
  gem.description = %Q{ripple is an object-mapper library for Riak, the distributed database by Basho.  It uses ActiveModel to provide an experience that integrates well with Rails 3 applications.}
  gem.email = ["sean@basho.com"]
  gem.homepage = "http://seancribbs.github.com/ripple"
  gem.authors = ["Sean Cribbs"]

  # Deps
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "rspec", "~>2.8.0"
  gem.add_development_dependency "rake"

  gem.add_dependency "riak-client", "~> 2.6"
  gem.add_dependency "activesupport", "~> 6.0.2"
  gem.add_dependency "activemodel", "~> 6.0.2"
  gem.add_dependency "tzinfo"

  # Files
  ignores = File.read(".gitignore").split(/\r?\n/).reject{ |f| f =~ /^(#.+|\s*)$/ }.map {|f| Dir[f] }.flatten
  gem.files         = (Dir['**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.test_files    = (Dir['spec/**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.require_paths = ['lib']
end
