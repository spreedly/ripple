require 'active_support/concern'

module Ripple
  module AttributeMethods
    module Read
      extend ActiveSupport::Concern

      if ActiveSupport::VERSION::STRING < '3.2'
        included do
          attribute_method_suffix ''
        end
      end

      def [](attr_name)
        attribute(attr_name)
      end

      private
      def attribute(attr_name)
        if @__attributes.include?(attr_name)
          @__attributes[attr_name]
        else
          nil
        end
      end
    end
  end
end
