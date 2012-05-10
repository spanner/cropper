require 'cropper/schema'

module Cropper
  module Glue
    def self.included base #:nodoc:
      
      # Extend ActiveRecord::Base with Cropper::ClassMethods, as defined in cropper.rb.
      #
      base.extend ClassMethods

      # Load migration helpers into all the right places.
      #
      if defined?(ActiveRecord)
        ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Cropper::Schema)
        ActiveRecord::ConnectionAdapters::Table.send(:include, Cropper::Schema)
        ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Cropper::Schema)
      end
    end
  end
end
