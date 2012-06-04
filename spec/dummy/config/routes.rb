Rails.application.routes.draw do
  mount CroppedPaperclip::Engine => "/cropped_paperclip"
end
