# This is a standard upload class that should be useable for most purposes. 
# We assume that even when the final destination is an S3 bucket, the initial upload
# will be held locally.
#
module Cropper
  class Upload < ActiveRecord::Base
    belongs_to :holder, :polymorphic => true
    attr_accessible :file, :scale_width, :scale_height, :offset_top, :offset_left, :holder_type, :holder_id
    
    
    # Unlike previous versions, the main resizing and cropping step is now carried out within the upload object.
    # Usually this happens in a second step: first we upload, then we update with crop parameters, but it is
    # also possible to present the cropping in javascript and upload the file with all the necessary values.
    
    has_attached_file :file,
                      :processors => [:thumbnail],
                      :styles => lambda { |attachment| attachment.instance.paperclip_styles }

    def paperclip_styles
      # precrop and crop dimensions are set in the has_upload declaration and can be retrieved from the holder.
      if !!holder
        # 
      end
    end
    
    def cropped_style
      # this is a calculated crop size that would normally be applied only on update,
      # when the crop values are available.
    end
    
    def crop_changed?
      file_changed? || 
    end

    validates :file, :attachment_presence => true

    ## Image dimensions
    #
    # We need to know dimensions of the precrop image in order to set up the cropping interface, so we
    # examine the uploaded file before it is flushed.
    #
    after_post_process :read_dimensions

    # *original_geometry* returns the discovered dimensions of the uploaded file as a paperclip geometry object.
    #
    def original_geometry
      @original_geometry ||= Paperclip::Geometry.new(original_width, original_height)
    end

    # *geometry*, given a style name, returns the dimensions of the file if that style were applied. For 
    # speed we calculate this rather than reading the file, which might be in S3 or some other distant place. 
    # 
    # The logic is in [lib/paperclip/geometry_tranformation.rb](/lib/paperclip/geometry_tranformation.html), 
    # which is a ruby library that mimics the action of imagemagick's convert command.
    #
    def geometry(style_name='original')
      # These calculations are all memoised.
      @geometry ||= {}
      begin
        @geometry[style_name] ||= if style_name.to_s == 'original'
          # If no style name is given, or it is 'original', we return the original discovered dimensions.
          original_geometry
        else
          # Otherwise, we apply a mock transformation to see what dimensions would result.
          style = self.file.styles[style_name.to_sym]
          original_geometry.transformed_by(style.geometry)
        end
      rescue Paperclip::TransformationError => e
        # In case of explosion, we always return the original dimensions so that action can continue.
        original_geometry
      end
    end

    # *width* returns the width of this image in a given style.
    #
    def width(style_name='original')
      geometry(style_name).width.to_i
    end

    # *height* returns the height of this image in a given style.
    #
    def height(style_name='original')
      geometry(style_name).height.to_i
    end

    # *square?* returns true if width and height are the same.
    #
    def square?(style_name='original')
      geometry(style_name).square?
    end

    # *vertical?* returns true if the image, in the given style, is taller than it is wide.
    #
    def vertical?(style_name='original')
      geometry(style_name).vertical?
    end

    # *horizontal?* returns true if the image, in the given style, is wider than it is tall.
    #
    def horizontal?(style_name='original')
      geometry(style_name).horizontal?
    end

    # *dimensions_known?* returns true we have managed to discover the dimensions of the original file.
    #
    def dimensions_known?
      original_width? && original_height?
    end

    # The offset_thumbnail processor needs two arguments: first the size to which the image should scale, then the 
    # precise crop that should be taken from the scaled image.
    #
    # *image_scale* returns a geometry string based on the user's chosen scale width.
    def scale
      "#{self.scale_width}x"
    end

    # *image_crop_and_offset* returns another geometry string based on the exact cutout that should be used.
    # The result of this operation is always a jpeg 853px by 505px, but its relation to the original uploaded file
    # is different every time.
    def crop_and_offset
      "%dx%d%+d%+d" % [853, 505, -offset_left, -offset_top]
    end

  private

    # *read_dimensions* is called after post processing to record in the database the original width, height 
    # and extension of the uploaded file. At this point the file queue will not have been flushed but the upload
    # should be in place. We grab dimensions from the temp file and calculate thumbnail dimensions later, on demand.
    #
    def read_dimensions
      if uploaded_file = self.file.queued_for_write[:original]
        file = uploaded_file.send :destination
        Rails.logger.warn "+++ getting geometry from queued file #{file.inspect}."
        Rails.logger.warn "--- File exist? #{File.exist?(file).inspect}"
        geometry = Paperclip::Geometry.from_file(file)
        self.original_width = geometry.width
        self.original_height = geometry.height
        self.original_extension = File.extname(file.path)
      end
      true
    end

  end
end