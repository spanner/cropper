module CroppedPaperclip
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
    end

    module TableDefinition
      def uploadable_attachment(*attachment_names)
        attachment_names.each do |attachment_name|
          UPLOAD_COLUMNS.each_pair do |column_name, column_type|
            column("#{attachment_name}_#{column_name}", column_type)
          end
        end
      end
    end

  end
end

