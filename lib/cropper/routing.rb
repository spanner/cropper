module ActionDispatch::Routing

  class Mapper
    def cropper_for(*res)
      options = res.extract_options!
      res.map!(&:to_sym)

      # options[:path] ||= "cropper"
      # options[:as] ||= :cropper
      # options[:path] = "#{options[:path]}/" unless options[:path].last == '/'
      # mount Cropper::Engine => options[:path], :as => options[:as]

      Rails.application.routes.draw do
        resources :uploads, :module => :cropper
        res.each do |resource|
          resources resource do
            resources :uploads, :module => :cropper
          end
        end
      end
    end
  end
end
