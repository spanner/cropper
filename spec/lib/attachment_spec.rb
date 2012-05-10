require 'spec_helper'

describe Cropper::Attachment do
  
  describe "A model class" do
    before :each do
      build_model :foos do
        string :name
        integer :created_by_id
        integer :updated_by_id
        integer :arquebus_upload_id
        integer :arquebus_file_name
        integer :arquebus_content_type
        integer :arquebus_updated_at
        integer :arquebus_file_size
        integer :arquebus_scale_width 
        integer :arquebus_scale_height
        integer :arquebus_offset_left 
        integer :arquebus_offset_top
        integer :arquebus_version
      end

      Foo.included_modules.should include(Cropper::Attachment)
      Foo.send :has_upload, :arquebus, :geometry => '100x100'
    end

    context "when declaring an uploaded attachment" do
      it "should have the named upload associations" do
        Foo.reflect_on_association(:arquebus_upload).should_not be_nil
      end

      it "should define attachments" do
        Foo.new.should respond_to(:arquebus)
      end
      
      it "should set up a before_save filter"
      it "should define a reprocess flag"
      it "should define a cropped flag"
    end

    context "when assigning attachment" do
      before do
        @foo = Foo.new
        @foo.arquebus = Rack::Test::UploadedFile.new('spec/fixtures/images/icon.png', 'image/png')
      end
    
      it "should have an icon style" do
        @foo.arquebus.url(:icon).should == 'hello'
      end
    
      it "should define a crop style" do
        @foo.arquebus.url(:cropped).should == 'hello'
      end
    end
  end

  describe "A model class that lacks the necessary upload_id column" do
    before :each do
      build_model :bars do
        string :name
        integer :created_by_id
        integer :updated_by_id
        integer :arquebus_upload_id
        integer :colophon_upload_id
      end
    end

    it "should raise an error when has_upload is called" do
      lambda { Foo.send :has_upload, :pianola, :geometry => '100x100' }.should raise_error
    end
  end

  describe "A model class with two uploaded attachments" do
    before :each do
      build_model :bars do
        string :name
        integer :created_by_id
        integer :updated_by_id
        integer :arquebus_upload_id
        integer :colophon_upload_id
      end
    end

    it "should raise an error when has_upload is called" do
      lambda { Foo.send :has_upload, :pianola, :geometry => '100x100' }.should raise_error
    end
  end
end
