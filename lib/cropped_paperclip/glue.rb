require 'cropped_paperclip/schema'

module CroppedPaperclip
  module Glue
    def self.included base #:nodoc:
      
      # Extend ActiveRecord::Base with CroppedPaperclip::ClassMethods, as defined in cropped_paperclip.rb.
      #
      base.extend ClassMethods

      # Load migration helpers into all the right places.
      #
      if defined?(ActiveRecord)
        ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, CroppedPaperclip::Schema)
        ActiveRecord::ConnectionAdapters::Table.send(:include, CroppedPaperclip::Schema)
        ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, CroppedPaperclip::Schema)
      end
    end
  end
end
