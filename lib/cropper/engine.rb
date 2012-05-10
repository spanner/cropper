module Cropper
  class Engine < Rails::Engine
    initializer "cropper.integration" do
      ActiveRecord::Base.send(:include, Cropper::Glue)
    end
  end
end