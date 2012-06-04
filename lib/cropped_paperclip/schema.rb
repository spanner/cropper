module CroppedPaperclip
  # Provides helpers that can be used in migrations. 
  # Copied from, and often makes calls on, the equivalent file in Paperclip.
  #
  module Schema
    @@upload_columns = {:upload_id => :integer,
                 :scale_width => :integer,
                 :scale_height => :integer,
                 :offset_left => :integer,
                 :offset_top => :integer,
                 :version => :integer}

    def has_upload(attachment_name)
      has_attached_file(attachment_name)
      with_columns_for_upload(attachment_name) do |column_name, column_type|
        column(column_name, column_type)
      end
    end
    
    def add_upload(table_name, attachment_name)
      add_attached_file(table_name, attachment_name)
      with_columns_for_upload(attachment_name) do |column_name, column_type|
        add_column(table_name, column_name, column_type)
      end
    end

    def drop_upload(table_name, attachment_name)
      drop_attached_file(table_name, attachment_name)
      with_columns_for_upload(attachment_name) do |column_name, column_type|
        remove_column(table_name, column_name)
      end
    end
    
    # Paperclip doesn't have this one, for some reason.
    def add_attached_file(table_name, attachment_name)
      # with_columns_for is defined in Paperclip::Schema
      with_columns_for(attachment_name) do |column_name, column_type|
        add_column(table_name, column_name, column_type)
      end
    end
    
  protected

    def with_columns_for_upload(attachment_name)
      @@upload_columns.each do |suffix, column_type|
        # full_column_name is defined in Paperclip::Schema
        column_name = full_column_name(attachment_name, suffix)
        yield column_name, column_type
      end
    end

  end
end

