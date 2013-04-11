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
  # Module configuration is handled in a simple way by accessors on the Cropper module. At the moment
  # there aren't many. Any, in fact, but we do hold some structural information about the uploading classes.
  #
  mattr_accessor :uploadable_classes, :upload_options

  class << self
    def uploadable_classes
      @@uploadable_classes ||= {}
    end
    
    def upload_options
      @@upload_options ||= {}
    end

    def declare_uploadable(klass, column, options)
      k = klass.to_s.underscore.to_sym
      uploadable_classes[k] ||= []
      uploadable_classes[k].push(column.to_sym)
      upload_options[k] ||= {}
      upload_options[k][column.to_sym] = {
        :precrop_geometry => options.delete(:precrop),
        :crop_geometry => options.delete(:crop)
      }
    end
    
    def crop_geometry(klass, column)
      k = klass.to_s.underscore.to_sym
      upload_options[k][column.to_sym][:crop_geometry]
    end

    def precrop_geometry(klass, column)
      k = klass.to_s.underscore.to_sym
      Rails.logger.warn "precrop_geometry(#{k.inspect}, #{column.inspect})"
      upload_options[k][column.to_sym][:precrop_geometry]
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
      options.reverse_merge!(:crop => "960x640#", :precrop => "1600x1600<", :whiny => true)
      Cropper.declare_uploadable(self, attachment_name, options)

      ### Upload association
      #
      # [uploads](/app/models/upload.html) are the original image files uploaded and cropped by this person.
      #
      has_many :uploads, :class_name => "Cropper::Upload", :as => :holder # so what happens when we call this twice?
      
      # Ok, I give in. We have to require an image_upload_id column. It's silly trying to fake the whole association machine.
      belongs_to :"#{attachment_name}_upload", :class_name => "Cropper::Upload", :autosave => true

      # accepts_nested_attributes_for :"#{attachment_name}_upload"
      attr_accessible :"#{attachment_name}_upload_attributes"
      after_save :"connect_to_#{attachment_name}_upload"
      
      #...but we still need to intervene to set the holder_column column of the upload when it is assigned
      define_method :"#{attachment_name}_upload_with_holder_column=" do |upload|
        upload.holder_column = attachment_name
        send :"#{attachment_name}_upload_without_holder_column=", upload
      end
      alias_method_chain :"#{attachment_name}_upload=", :holder_column

      #...or built.
      define_method :"build_#{attachment_name}_upload_with_holder_column" do |attributes={}, options={}|
        attributes[:holder_column] = attachment_name
        attributes[:holder_type] ||= self.class.to_s unless attributes[:holder]
        send :"build_#{attachment_name}_upload_without_holder_column", attributes, options
      end
      alias_method_chain :"build_#{attachment_name}_upload", :holder_column

      # when a new holder is created, the interface means that the upload will have preceded it. In that
      # case we force the setting of holder_type to allow crop-dimension lookups. Here we make sure that 
      # holder_id is also present.
      define_method :"connect_to_#{attachment_name}_upload" do
        if upload = send(:"#{attachment_name}_upload")
          upload.update_column(:holder_type, self.class.to_s)
          upload.update_column(:holder_id, self.id)
          upload.update_column(:holder_column, attachment_name)
        end
        Rails.logger.warn "connect_to_#{attachment_name}_upload: upload is #{upload.inspect}. Self is #{self.inspect}"
        true
      end
      
      define_method :"#{attachment_name}_upload_attributes=" do |attributes|
        # assign_nested_attributes_for_image_upload_association(:image_upload, attributes, mass_assignment_options)
        if upload_id = attributes.delete('id')
          self.send :"#{attachment_name}_upload=", Cropper::Upload.find(upload_id)
        end
        if upload = self.send(:"#{attachment_name}_upload")
          Rails.logger.warn "setting upload attributes for #{upload.inspect} -> #{attributes.inspect}"
          upload.assign_attributes(attributes)
        end
      end

      ### Attachment
      #
      # Eventually we get to the point. Image attachments work in the usual Paperclip way except that they are always received from
      # an upload object, presumably in an already-cropped form.
      # If this class then generates other styles, they are built from that cropped image rather than the file originally uploaded.
      #
      has_attached_file attachment_name, options

      # Note: updates to the attached file are pushed to the holder from the upload after processing is complete, so we won't always
      # have them immediately. Best course is to display the upload cropped rather than the holder original.

    end
  end
end
