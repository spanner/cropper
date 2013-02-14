require "paperclip"
require "paperclip/validators/attachment_height_validator"
require "paperclip/validators/attachment_width_validator"
require "paperclip/geometry_transformation"
require "paperclip_processors/offset_thumbnail"
require "cropper/engine"
require "cropper/routing"
require 'cropper/glue'

module Cropper
  # Cropper::ClassMethods is included into ActiveRecord::Base in the same way as the Paperclip module. 
  # It adds a `has_upload` class method that defines an attachment and adds several instance methods 
  # that will return the values that determine its cropping. Those values are usually but not  
  # necessarily given by the user.
  #

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
      # unless !table_exists? || column_names.include?("#{attachment_name}_upload_id")
      #   raise RuntimeError, "has_upload(#{attachment_name}) called on class #{self.to_s} but we have no #{attachment_name}_upload_id column" unless 
      # end

      options.reverse_merge!(:geometry => "640x960#", :cropped => true, :whiny => true)
      options[:geometry].sub!(/\D*$/, '') if options[:cropped]
      # raise here if geometry is not useable

      class_variable_set(:"@@#{attachment_name}_cropped", options[:cropped])

      # The essential step is present in this style definition. It specifies the OffsetThumbnail processor, 
      # which is similar to the usual thumbnailer but has a more flexible scaling and cropping procedure,
      # and passes through a couple of callback procs that will return the scaling and cropping arguments
      # it requires.
      #
      crop_style = options[:cropped] == false ? geometry : {
        :geometry => "#{options[:geometry]}#",
        :processors => [:offset_thumbnail],

        # The processor will first scale the image to the width that is specified by the scale_width property of the instance
        :scale => lambda { |att| 
          width = att.instance.send :"#{attachment_name}_scale_width"
          "#{width || 0}x"
        },

        # ...then perform the crop described by the width, height, offset_top and offset_left properties of the instance.
        :crop_and_offset => lambda { |att| 
          width, height = options[:geometry].split('x')
          left = att.instance.send :"#{attachment_name}_offset_left" || 0
          top = att.instance.send :"#{attachment_name}_offset_top"
          "%dx%d%+d%+d" % [width, height, -(left  || 0), -(top || 0)]
        }
      }

      options[:styles] ||= { :icon => "48x48#" }
      options[:styles].merge!({:cropped => crop_style})

      ### Upload association
      #
      # [uploads](/app/models/upload.html) are the raw image files uploaded by this person. 
      # They are held separately as the basis for repeatable (and shareable) image assignment.
      #
      belongs_to :"#{attachment_name}_upload", :class_name => "Cropper::Upload"
      before_save :"read_#{attachment_name}_upload"
      accepts_nested_attributes_for :"#{attachment_name}_upload"

      ### Attachment
      #
      # Image attachments work in the usual Paperclip way except that the :cropped style is applied differently to each instance.
      # The editing interface allows the user to upload a picture (which creates an upload object) and choose how it is scaled 
      # and cropped (which stores values here).
      # 
      # The cropped image is created by a [custom processor](/lib/paperclip_processors/offset_thumbnail.html) very similar to 
      # Paperclip::Thumbnail, but which looks up the scale and crop parameters to calculate the imagemagick transformation.
      #
      Rails.logger.warn ">>> #{self}.has_attached_file #{attachment_name}, #{options.inspect}"
      has_attached_file attachment_name, options

      ## Maintenance
      #
      # *read_[name]_upload* is called before_save. If there is a new upload, or any of our scale and crop values are changed, it will assign 
      # the uploaded file. Even if it's the same file as before, the effect is to trigger post-processing again and apply the current crop and scale values.
      #
      define_method :"read_#{attachment_name}_upload" do
        if self.send(:"reprocess_#{attachment_name}?") && upload = self.send(:"#{attachment_name}_upload")
          self.send :"#{attachment_name}=", upload.file  
        end
      end

      # *reprocess_[name]?* returns true if there have been any changes to the upload association that would require a new crop.
      #
      cols = [:upload_id]
      cols += [:upload_id, :scale_width, :scale_height, :offset_top, :offset_left] if options[:cropped]

      attr_accessible *cols.map {|col| :"#{attachment_name}_#{col}"}
      attr_accessible :"#{attachment_name}_upload", :"#{attachment_name}_upload_attributes"

      define_method :"reprocess_#{attachment_name}?" do
        cols.any? {|col| send(:"#{attachment_name}_#{col}_changed?") }
      end

      # * [name]_cropped? returns true if the named attachment is cropped on assignment. It can be useful in a form partial.
      #
      define_method :"#{attachment_name}_cropped?" do
        !!class_variable_get(:"@@#{attachment_name}_cropped")
      end

      define_method :"#{attachment_name}_for_cropping" do
        if upload = send(:"#{attachment_name}_upload")
          upload.url(:"#{attachment_name}")
        end
      end

    end

    ## Delay post-processing

    def delay_post_processing(attachment_name=:image)
      send(:"before_#{attachment_name}_post_process", :"defer_#{attachment_name}_post_processing")
      after_save(:"resume_#{attachment_name}_post_processing")

      # There are too many thumbnail styles in this class. We can't make the user wait while they are processed,
      # so the whole job of thumbnailing is spun off into a delayed_job. Since the main publication page displays
      # the :original style, we can show the user her public page while the rest of the thumbnails are still being
      # processed.
      #
      # The usual post_processing routine is abandoned when we return false from this call.
      #
      define_method :"defer_#{attachment_name}_post_processing" do
        if send(:"reprocess_#{attachment_name}?") && !send(:"awaiting_#{attachment_name}_processing?")
          send(:"awaiting_#{attachment_name}_processing", true)
          false
        end
      end

      # The delayed job is created just by interposing the `delay` method in a call to `process_image_styles!`. The effect
      # is to serialize this object and that call to the database and resume it later when the job runner picks it up. 
      # We can't do  that until the publication object has an id, so the call is made from an after_save handler.
      #
      define_method :"resume_#{attachment_name}_post_processing" do
        if send(:"reprocess_#{attachment_name}?") && send(:"awaiting_#{attachment_name}_processing?")
          self.delay.send(:"process_#{attachment_name}_styles!")
        end
      end

      # This is the eventual processing step, to which the delayed job object is just a sort of pointer.
      # It retrieves the original image from S3 and applies the processing styles.
      #
      define_method :"process_#{attachment_name}_styles!" do
        send(attachment_name).reprocess! 
        update_column(:"awaiting_#{attachment_name}_processing", false)
      end
      
    end
  end
end
