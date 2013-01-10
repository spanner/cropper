Rails.application.routes.draw do
  # mount Cropper::Engine => "/cropper"
  
  cropper_for :things
  
end
