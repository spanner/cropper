module Cropper
  # Provides helpers that can be used in migrations. 
  # Copied from, and often makes calls on, the equivalent file in Paperclip.
  #
  module Schema
    UPLOAD_COLUMNS = {
      :file_name    => :string,
      :content_type => :string,
      :file_size    => :integer,
      :updated_at   => :datetime,
      :upload_id    => :integer,
      :scale_width  => :integer,
      :scale_height => :integer,
      :offset_left  => :integer,
      :offset_top   => :integer
    }

    def self.included(base)
      ActiveRecord::ConnectionAdapters::Table.send :include, TableDefinition
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, TableDefinition
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Statements
    end

    module Statements
      def add_upload(table_name, *attachment_names)
        raise ArgumentError, "Please specify attachment name in your add_upload call in your migration." if attachment_names.empty?
        
        attachment_names.each do |attachment_name|
          UPLOAD_COLUMNS.each_pair do |column_name, column_type|
            add_column(table_name, "#{attachment_name}_#{column_name}", column_type)
          end
        end
      end
      
      
      def remove_upload(table_name, *attachment_names)
        raise ArgumentError, "Please specify attachment name in your remove_upload call in your migration." if attachment_names.empty?

        attachment_names.each do |attachment_name|
          COLUMNS.each_pair do |column_name, column_type|
            remove_column(table_name, "#{attachment_name}_#{column_name}")
          end
        end
      end
    end
    
    module TableDefinition
      def cropped_attachment(*attachment_names)
        attachment_names.each do |attachment_name|
          UPLOAD_COLUMNS.each_pair do |column_name, column_type|
            column("#{attachment_name}_#{column_name}", column_type)
          end
        end
      end
    end

  end
end

