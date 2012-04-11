require 'cropper'
require 'cropper/schema'

module Cropper
  if defined? Rails::Railtie
    require 'rails'
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
      if defined?(ActiveRecord)
        ActiveRecord::Base.send :include, Cropper::Attachment
        ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Cropper::Schema)
        ActiveRecord::ConnectionAdapters::Table.send(:include, Cropper::Schema)
        ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Cropper::Schema)
        ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), "../../app/models/")
      end
    end
  end
end
