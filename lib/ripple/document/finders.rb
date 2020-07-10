require 'ripple/translation'
require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'
require 'ripple/conflict/resolver'

module Ripple

  # Raised by <tt>find!</tt> when a document cannot be found with the given key.
  #   begin
  #     Example.find!('badkey')
  #   rescue Ripple::DocumentNotFound
  #     puts 'No Document here!'
  #   end
  class DocumentNotFound < StandardError
    include Translation
    def initialize(keys, found)
      if keys.empty?
        super(t("document_not_found.no_key"))
      elsif keys.size == 1
        super(t("document_not_found.one_key", :key => keys.first))
      else
        missing = keys - found.compact.map(&:key)
        super(t("document_not_found.many_keys", :keys => missing.join(', ')))
      end
    end
  end

  module Document
    module Finders
      extend ActiveSupport::Concern

      module ClassMethods
        # Retrieve single or multiple documents from Riak.
        # @overload find(key)
        #   Find a single document.
        #   @param [String] key the key of a document to find
        #   @return [Document] the found document, or nil
        # @overload find(key1, key2, ...)
        #   Find a list of documents.
        #   @param [String] key1 the key of a document to find
        #   @param [String] key2 the key of a document to find
        #   @return [Array<Document>] a list of found documents, including nil for missing documents
        # @overload find(keylist)
        #   Find a list of documents.
        #   @param [Array<String>] keylist an array of keys to find
        #   @return [Array<Document>] a list of found documents, including nil for missing documents
        def find(*args)
          if args.first.is_a?(Array)
            args.flatten.map {|key| find_one(key) }
          else
            args.flatten!
            return nil if args.empty? || args.all?(&:blank?)
            return find_one(args.first) if args.size == 1
            args.map {|key| find_one(key) }
          end
        end

        # Retrieve single or multiple documents from Riak
        # but raise Ripple::DocumentNotFound if a key can
        # not be found in the bucket.
        def find!(*args)
          found = find(*args)
          raise DocumentNotFound.new(args, found) if !found || Array(found).include?(nil)
          found
        end

        private
        def find_one(key)
          instantiate(bucket.get(key, quorums.slice(:r)))
        rescue Riak::FailedRequest => fr
          raise fr unless fr.not_found?
        end

        def instantiate(robject)
          klass = robject.data['_type'].constantize rescue self
          klass.new.tap do |doc|
            doc.key = robject.key
            doc.__send__(:raw_attributes=, robject.data.except("_type")) if robject.data
            doc.instance_variable_set(:@new, false)
            doc.instance_variable_set(:@robject, robject)
            doc.clear_attribute_changes(doc.changed_attributes.keys)
          end
        end
      end
    end
  end
end
