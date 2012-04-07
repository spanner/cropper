# The Cropper module is included into ActiveRecord::Base alongside the base Paperclip module. 
# It adds a `has_upload` class method that defines an attachment and adds several instance methods 
# that will return the values that determine its cropping. Those values are usually but not  
# necessarily given by the user.
#
module Cropper
  module Attachment
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      ## Defining upload columns
      #
      # *has_upload* brings in the whole machinery of receiving and cropping an uploaded file. eg.
      #
      #   class User < ActiveRecord::Base
      #     has_upload :avatar, :size => '120x120#'
      #
      # The geometry string will always be treated as though it ended in '#'.
      #
      # Set the :cropped option to false if you want the file-upload-sharing mechanism but no cropping step. 
      # In that case any geometry string can be used and it will be passed through intact.
      #
      #   class Group < ActiveRecord::Base
      #     has_upload :icon, :size => '40x40#', :crop => false
      #
      def has_upload(attachment_name=:image, options={})
        unless column_names.include?("#{attachment_name}_upload_id")
          raise RuntimeError "has_upload(#{attachment_name}) called on class #{self.to_s} but we have no #{attachment_name}_upload_id column"
        end
        
        options.reverse_merge!(:geometry => "640x960#", :cropped => true)
        options[:geometry].sub!(/\D*$/, '#') if options[:cropped]
        class_variable_set(:"@@#{attachment_name}_cropped", options[:cropped])
        
        # The essential step is present in this style definition. It specifies the OffsetThumbnail processor, 
        # which is similar to the usual thumbnailer but has a more flexible scaling and cropping procedure,
        # and passes through a couple of callback procs that will provide the scaling and cropping arguments
        # that the processor requires.
        #
        crop_style = options[:cropped] == false ? geometry : {
          :geometry => "#{options[:geometry]}#",
          :processors => [:offset_thumbnail],

          # The processor will first scale the image to the width that is specified by the scale_width property of the instance
          :scale => lambda { |att| 
            width = send :"#{attachment_name}_scale_width"
            "#{width}x"
          },

          # ...then perform the crop described by the width, height, offset_top and offset_left properties of the instance.
          :crop_and_offset => lambda { |att| 
            width, height = size.split('x')
            left = send :"#{attachment_name}_offset_left"
            top = send :"#{attachment_name}_offset_top"
            "%dx%d%+d%+d" % [width, height, -left, -top]
          }
        }

        ### Upload association
        #
        # [uploads](/app/models/upload.html) are the raw image files uploaded by this person. 
        # They are held separately as the basis for repeatable (and shareable) image assignment.
        #
        belongs_to :"#{attachment_name}_upload"
        before_save :"read_#{attachment_name}_upload"

        ### Attachment
        #
        # Image attachments work in the usual Paperclip way except that the :cropped style is applied differently to each instance.
        # The editing interface allows the user to upload a picture (which creates an upload object) and choose how it is scaled 
        # and cropped (which stores values here).
        # 
        # The cropped image is created by a [custom processor](/lib/paperclip_processors/offset_thumbnail.html) very similar to 
        # Paperclip::Thumbnail, but which looks up the scale and crop parameters to calculate the imagemagick transformation.
        #
        has_attached_file attachment_name, 
                          :path => ":rails_root/public/system/:class/:attachment/:id/:style/:filename",
                          :url => "/system/:class/:attachment/:id/:style/:filename",
                          :default_url => '/assets/nopicture_:style.png',
                          :whiny => true,
                          :styles => {
                            :icon => "48x48#", 
                            :cropped => crop_style
                          }

        ## Maintenance
        #
        # *read_[name]_upload* is called before_save. If there is a new upload, or any of our scale and crop values are changed, it will assign 
        # the uploaded file to the person image. Even if it's the same file as before, the effect is to trigger post-processing again
        # and apply the current crop and scale values.
        #
        define_method :"read_#{attachment_name}_upload" do
          if self.send(:"reprocess_#{attachment_name}?") && upload = self.send(:"#{attachment_name}_upload")
            self.send :"#{attachment_name}=", upload.file  
          end
        end
        
        # *reprocess_[name]?* returns true if there have been any changes to the upload association that would necessitate a new crop.
        #
        cols = [:upload_id]
        cols += [:upload_id, :scale_width, :offset_top, :offset_left] if options[:cropped]
        define_method :"reprocess_#{attachment_name}?" do
          cols.any? {|col| send(:"#{attachment_name}_#{col}_changed?") }
        end
        
        # * [name]_cropped? returns true if the named attachment is cropped on assignment. It can be useful in a form partial.
        #
        define_method :"#{attachment_name}_cropped?" do
          !!class_variable_get(:"@@#{attachment_name}_cropped")
        end

      end
    end
  end
end


