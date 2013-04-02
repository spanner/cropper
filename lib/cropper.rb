require "paperclip"
require "paperclip/validators/attachment_height_validator"
require "paperclip/validators/attachment_width_validator"
require "paperclip/geometry_transformation"
require "paperclip_processors/offset_thumbnail"
require "cropper/engine"
require "cropper/routing"
require 'cropper/glue'
require 'open-uri'

module Cropper
  # module configuration is handled in a simple way by accessors on the Cropper module. At the moment
  # there aren't many. Any, in fact, but we do hold a list of uploadable classes for whitelisting in 
  # the controller.
  #
  mattr_accessor :uploadable_classes

  class << self
    def uploadable_classes
      @@uploadable_classes ||= {}
    end

    def declare_uploadable(klass, column)
      k = klass.to_s.underscore
      uploadable_classes[k] ||= []
      uploadable_classes[k].push(column)
    end
  end
  
  # Cropper::ClassMethods is included into ActiveRecord::Base in the same way as the Paperclip module. 
  # It adds a `has_upload` class method that defines an attachment and adds several instance methods 
  # that will return the values that determine its cropping. Those values are usually but not  
  # necessarily given by the user.
  #
  module ClassMethods
    ## Defining upload columns
    #
    # *has_upload* brings in the whole machinery of receiving and cropping an uploaded file. The options given are exactly the same
    # as paperclip's `has_attached_file` call, with the addition of a 'crop' parameter that gives the target dimensions. The crop 
    # value is applied in the upload object, then any other styles you specify here are applied to that cropped image when it is 
    # passed to this model.
    #
    # The practical effect of this is that your :original file always has your :crop dimensions.
    #
    # You can also set an optional :precrop option to set the dimensions of the file that is presented in the cropping interface. 
    # The default is 1600x1600<, which is often going to be too big and may cause unwanted scaling-up of your source image.
    # The precrop geometry is also applied in the upload object, when a file is first uploaded.
    #
    # The call usually looks like this:
    #
    #   class User < ActiveRecord::Base
    #     has_upload :avatar, 
    #                :precrop => '1440x960<
    #                :crop => '720x480#'
    #                :styles => {
    #                  :thumbnail => "60x60#"
    #                }
    #
    # The crop geometry will always be treated as a fixed target shape: that is, as though it ended in '#'. Any other suffix will be 
    # removed. The other styles that you define can be in any form that paperclip understands.
    #
    # A model can make more than one has_upload call. The methods we define here are all prefixed with the association name, so you 
    # usually end up calling methods like `person.icon_upload`.
    #
    def has_upload(attachment_name=:image, options={})
      # unless !table_exists? || column_names.include?("#{attachment_name}_upload_id")
      #   raise RuntimeError, "has_upload(#{attachment_name}) called on class #{self.to_s} but we have no #{attachment_name}_upload_id column" unless 
      # end
      
      # allow uploads to be assigned to this class and column in the UploadsController.
      Cropper.declare_uploadable(self, attachment_name)

      options.reverse_merge!(:crop => "960x640#", :precrop => "1600x1600<", :whiny => true)
      precrop_geometry = options.delete(:precrop)
      cropped_geometry = options.delete(:crop)

      # These two closures are called later by the upload object to discover its scaling dimensions.

      define_method :"precrop_#{attachment_name}_geometry" do
        precrop_geometry
      end

      define_method :"cropped_#{attachment_name}_geometry" do
        cropped_geometry
      end

      ### Upload association
      #
      # [uploads](/app/models/upload.html) are the original image files uploaded and cropped by this person.
      #
      has_many :uploads, :class_name => "Cropper::Upload", :as => :holder # so what happens when we call this twice?
      before_save :"read_#{attachment_name}_upload"
      accepts_nested_attributes_for :"#{attachment_name}_upload"

      define_method :"#{attachment_name}_upload" do
        self.uploads.destined_for(attachment_name).first
      end

      define_method :"#{attachment_name}_upload=" do |upload|
        upload.destination = attachment_name
        upload.updated_at = Time.now if upload.persisted?
        self.uploads << upload
      end

      # You usually want to initialize an upload with something like person.build_image_upload, so that the
      # mutual connection is properly established. It is a weakness of the cropper that we have to tell the
      # upload object for what column it is intended.
      #
      define_method :"build_#{attachment_name}_upload" do
        self.send :"#{attachment_name}_upload=", self.build_upload
      end

      ### Attachment
      #
      # Image attachments work in the usual Paperclip way except that they are always received from an upload object, usually in an already-cropped form.
      # If this class then generates other styles, they are built from that cropped image rather than the file originally uploaded.
      #
      has_attached_file attachment_name, options

      ## Maintenance
      #
      # *read_[name]_upload* is called before_save. If there is a new upload, or its scale or crop values have changed, 
      # it will assign the uploaded file.
      #
      define_method :"read_#{attachment_name}_upload" do
        if self.send :"reprocess_#{attachment_name}?" && upload = self.send(:"#{attachment_name}_upload")
          # We assign the cropped style rather than the whole attachment. At the moment this doesn't work with filesystem storage
          # because the url is just a path. Something with configured hosts will be required.
          self.send :"#{attachment_name}=", open(upload.url(:cropped))
        end
      end

      # *reprocess_[name]?* returns true if there have been any changes to the upload association that would require a new crop.
      #
      define_method :"reprocess_#{attachment_name}?" do
        #todo: we're missing the part where we check for a new upload. need to mimic the _changed? functionality somehow.
        self.send(:"#{attachment_name}_upload").crop_changed?
      end



    end
  end
end
