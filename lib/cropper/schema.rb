module Cropper
  # Provides helpers that can be used in migrations. 
  # Copied from, and often makes calls on, the equivalent file in Paperclip.
  #
  module Schema
    @@columns = {:upload_id => :integer,
                 :scale_width => :integer,
                 :scale_height => :integer,
                 :offset_left => :integer,
                 :offset_top => :integer,
                 :version => :integer}

    def has_uploaded_image(attachment_name)
      has_attached_file(attachment_name)
      with_columns_for(attachment_name) do |column_name, column_type|
        column(column_name, column_type)
      end
    end
    
    def add_uploaded_image(table_name, attachment_name)
      add_attached_file(table_name, attachment_name)
      with_columns_for(attachment_name) do |column_name, column_type|
        add_column(table_name, column_name)
      end
    end

    def drop_uploaded_image(table_name, attachment_name)
      drop_attached_file(table_name, attachment_name)
      with_columns_for(attachment_name) do |column_name, column_type|
        remove_column(table_name, column_name)
      end
    end

  protected

    def with_columns_for(attachment_name)
      @@columns.each do |suffix, column_type|
        column_name = full_column_name(attachment_name, suffix)
        yield column_name, column_type
      end
    end

    def full_column_name(attachment_name, column_name)
      "#{attachment_name}_#{column_name}".to_sym
    end
  end
end
