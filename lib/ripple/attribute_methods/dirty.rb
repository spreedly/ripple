require 'active_support/concern'
require 'active_model/dirty'

module Ripple
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      module ClassMethods
        # @private
        def instantiate(robject)
          super(robject).tap do |o|
            o.clear_attribute_changes(o.changed_attributes.keys)
          end
        end
      end

      # @private
      def really_save(*args)
        if result = super
          @previously_changed = changes
          clear_attribute_changes(changed_attributes.keys)
        end
        result
      end

      # @private
      def reload
        super.tap do
          clear_attribute_changes(changed_attributes.keys)
        end
      end

      # @private
      def initialize(*args)
        super
        clear_attribute_changes(changed_attributes.keys)
      end

      def previous_changes
        @previously_changed ||= ActiveSupport::HashWithIndifferentAccess.new
      end

      # Determines if the document has any chnages.
      # @return [Boolean] true if this document, or any of its embedded
      # documents at any level, have changed.
      def changed?
        super || self.class.embedded_associations.any? do |association|
          send(association.name).has_changed_documents?
        end
      end

      private
      def attribute=(attr_name, value)
        if self.class.properties.include?(attr_name.to_sym) && @__attributes[attr_name] != value
          attribute_will_change!(attr_name)
        end
        super
      end
    end
  end
end
