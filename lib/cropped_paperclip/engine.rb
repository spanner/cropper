module CroppedPaperclip
  class Engine < Rails::Engine
    initializer "cropped_paperclip.integration" do
      ActiveRecord::Base.send(:include, CroppedPaperclip::Glue)
    end
  end
end