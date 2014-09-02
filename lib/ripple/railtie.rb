require 'rails/railtie'

module Ripple
  # Railtie for automatic initialization of the Ripple framework
  # during Rails initialization.
  class Railtie < Rails::Railtie
    rake_tasks do
      load "ripple/railties/ripple.rake"
    end
  end
end
