module Cropper
  class Engine < ::Rails::Engine
    isolate_namespace Cropper
    initializer "cropper.integration" do
      ActiveRecord::Base.send(:include, Cropper::Glue)
      Paperclip::Attachment.send(:include, Paperclip::Dirty)
    end
  end
end