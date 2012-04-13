# This is a base class for your uploads. It defines all the essential methods and offers some hooks that
# you can override to set local style definitions. All you need is something like this:
#
#   class Upload << Cropper::Upload
#     def thumbnail_styles 
#       {:precrop => "500x500>"}
#     end
#
# If you have models with very different image-crop outcomes you may want to define a different precrop 
# style for each one.
#
module Cropper
  class Upload < ActiveRecord::Base
    belongs_to :person

    has_attached_file :file,
                      :path => ":rails_root/public/system/:class/:attachment/:id/:style/:filename",
                      :url => "/system/:class/:attachment/:id/:style/:filename",
                      :processors => lambda { |att| att.instance.precrop_processors },
                      :styles => lambda { |att| att.instance.precrop_styles }

    def precrop_styles
      {
        :icon => { :geometry => "40x40#" },
        :precrop => { :geometry => "1600x1600>" },
      }
    end

    def precrop_processors
      [:thumbnail]
    end

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
    
  private
  
    # *read_dimensions* is called after post processing to record in the database the original width, height 
    # and extension of the uploaded file. At this point the file queue will not have been flushed but the upload
    # should be in place. We grab dimensions from the temp file and calculate thumbnail dimensions later, on demand.
    #
    def read_dimensions
      if file = self.file.queued_for_write[:original]
        geometry = Paperclip::Geometry.from_file(file)
        self.original_width = geometry.width
        self.original_height = geometry.height
        self.original_extension = File.extname(file.path)
      end
      true
    end

  end
end