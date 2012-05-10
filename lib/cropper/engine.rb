require "paperclip"
require "paperclip/geometry_transformation"
require "paperclip_processors/offset_thumbnail"
require "cropper/attachment"

module Cropper

  class Engine < Rails::Engine
    
    engine_name "cropper"

    initialize "cropper.load_app_instance_data" do |app|
      Cropper.setup do |config|
        config.app_root = app.root
      end
    end

    initialize "cropper.load_static_assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end

  end

end