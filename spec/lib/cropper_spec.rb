require 'spec_helper'

describe "Cropper" do
  
  describe "A model class that has_upload" do
    before :each do
      build_model :foos do
        string :name
        integer :created_by_id
        integer :updated_by_id
        integer :arquebus_upload_id
        integer :colophon_upload_id
      end

      Foo.included_modules.should include(Cropper::Attachment)
      Foo.send :has_upload, :arquebus, :geometry => '100x100'
      Foo.send :has_upload, :colophon, :geometry => '200x200'
    end

    it "should have the named upload associations" do
      Foo.reflect_on_association(:arquebus_upload).should_not be_nil
      Foo.reflect_on_association(:colophon_upload).should_not be_nil
    end

    it "should define attachments" do
      Foo.new.should respond_to(:arquebus)
      Foo.new.should respond_to(:colophon)
    end
    
    it "should define an icon style" do
      foo = Foo.new

    end
    
    it "should define a crop style"
    it "should set up a before_save filter"
    it "should define a reprocess flag"
    it "should define a cropped flag"
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
end
