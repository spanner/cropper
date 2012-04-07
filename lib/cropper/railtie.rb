require 'cropper'
require 'cropper/schema'

module Cropper
  p "Cropper module: have we got a railtie?"

  if defined? Rails::Railtie
    require 'rails'
    p "defining railtie"

    class Railtie < Rails::Railtie
      initializer 'cropper.insert_into_active_record' do
        ActiveSupport.on_load :active_record do
          Cropper::Railtie.insert
        end
      end
    end
  end

  class Railtie
    def self.insert
      p "inserting railtie"
      
      if defined?(ActiveRecord)
        p "extending ActiveRecord"

        ActiveRecord::Base.send :include, Cropper::Attachment
        ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Cropper::Schema)
        ActiveRecord::ConnectionAdapters::Table.send(:include, Cropper::Schema)
        ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Cropper::Schema)
      end
    end
  end
end
