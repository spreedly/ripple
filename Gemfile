source 'https://rubygems.org'

gemspec

group :guard do
  gem 'guard-rspec'
  gem 'ruby_dep', '1.3.1'
  gem 'listen', '3.0.8'
  gem 'rb-fsevent'
  gem 'growl'
end

group :development, :test do
  gem "riak_test_server", git: "git@github.com:spreedly/riak_test_server.git", branch: :master
end

if File.directory?(File.expand_path("../../riak-ruby-client", __FILE__))
  gem 'riak-client', :path => "../riak-ruby-client"
end

platforms :jruby do
  gem 'jruby-openssl'
end

group :development do
  gem "riak_test_server", git: "git@github.com:spreedly/riak_test_server.git", branch: :master
end
