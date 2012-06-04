Rails.application.routes.draw do
  resources :uploads, :controller => 'cropped_paperclip/uploads'
end
