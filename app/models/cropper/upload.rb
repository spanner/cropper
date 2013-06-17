# This is a standard upload class that should be useable for most purposes. 
# We assume that even when the final destination is an S3 bucket, the initial upload
# will be held locally.
#
require 'open-uri'

module Cropper
  class Upload < ActiveRecord::Base
    belongs_to :holder, :polymorphic => true
    attr_accessible :file, :scale_width, :scale_height, :offset_top, :offset_left, :holder_type, :holder_id, :holder, :holder_column, :multiplier
    attr_accessor :reprocessed, :multiplier
    # Unlike previous versions, the main resizing and cropping step is now carried out within the upload object.
    # Usually this happens in a second step: first we upload, then we update with crop parameters, but it is
    # also possible to present the cropping in javascript and upload the file with all the necessary values.
    
    has_attached_file :file,
                      :processors => [:thumbnail],
                      :styles => lambda { |attachment| attachment.instance.paperclip_styles }

    validates :file, :attachment_presence => true
    validates :holder_column, :presence => true
    
    before_update :reprocess_if_crop_changed
    before_save :apply_multiplier
    
    scope :destined_for, lambda { |col|
      where(:holder_column => col).order('updated_at DESC, created_at DESC')
    }

    def paperclip_styles
      styles = {}
      styles[:precrop] = {
        :geometry => precrop_geometry,
        :processors => [:thumbnail]
      }
      if croppable?
        styles[:cropped] = {
          :geometry => crop_geometry,
          :processors => [:offset_thumbnail],
          :scale => "#{scale_width}x",
          :crop_and_offset => "%dx%d%+d%+d" % [crop_width, crop_height, -offset_left, -offset_top]
        }
      end
      styles
    end

    def styled_file(style=:cropped)
      settings = Rails.application.config.paperclip_defaults
      if bucket = Fog::Storage.new(settings[:fog_credentials]).directories.get(settings[:fog_directory])
        bucket.files.get(file.path(style))
      end
    end

    # crop_changed? returns true if any property has changed that should cause a recrop. That shuold include the file attachment itself.
    #
    def crop_changed?
      !self.reprocessed && !![:scale_width, :scale_height, :offset_top, :offset_left, :holder_type, :holder_id, :holder_column].detect { |col| self.send :"#{col}_changed?" }
    end
    
    def reprocess_if_crop_changed
      self.file.assign(file) if crop_changed?
    end

    ## Image dimensions
    #
    # We need to know dimensions of the precrop image in order to set up the cropping interface,
    # so we examine the uploaded file before it is flushed.
    #
    after_post_process :read_dimensions
    after_save :update_holder

    # ## Crop boundaries
    #
    # Precrop geometry is unpredictable and has to be calculated.
    #
    def precrop_geometry
      @precrop_geometry ||= Cropper.precrop_geometry(holder_type, holder_column)
    end

    def precrop_width
      @precrop_width ||= width(:precrop)
    end
    
    def precrop_height
      @precrop_height ||= height(:precrop)
    end
    
    # Cropped geometry is always to a fixed size, so we can just return parts of the definition 
    # knowing that they match the eventual dimensions. Useful, because we need this information to
    # build the cropping interface.
    #
    def crop_geometry
      @crop_geometry ||= Cropper.crop_geometry(holder_type, holder_column)
    end
        
    def crop_width
      @cropped_width ||= crop_geometry.split('x').first.to_i
    end
    
    def crop_height
      @cropped_height ||= crop_geometry.split('x').last.to_i
    end

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
    
    ## 
    
    def url(style=:cropped)
      file.url(:style)
    end

  private

    # sometimes the interface will work in miniature and send through a multiplier by which to scale everything up.
    def apply_multiplier
      if multiplier = self.multiplier.to_i
        Rails.logger.warn "multiplying upload params by #{multiplier}."
        if multiplier != 1
          %w{offset_left offset_top scale_width scale_height}.each do |col|
            if param = self.send(col.to_sym)
              self.send(:"#{col}=", param * self.multiplier.to_i)
            end
          end
        end
        self.multiplier = 1
      end
    end

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
        Rails.logger.warn "=== Geometry: #{geometry.inspect}"
        self.original_width = geometry.width
        self.original_height = geometry.height
        self.original_extension = File.extname(file.path)
        Rails.logger.warn "??? validity: #{self.valid?.inspect}. errors: #{self.errors.inspect}"
      end
      true
    end
    
    def croppable?
      !!scale_width && !!offset_left && !!offset_top
    end
    
    def update_holder
      if holder
        holder.send :"#{holder_column}_upload=", self
        if croppable? && holder.persisted?
          if source = file.url(:cropped, false)
            source = (Rails.root + "public/#{source}") unless source =~ /^http/
            Rails.logger.warn "--- update_holder: #{source}"
            Rails.logger.warn "--- File exist? #{File.exist?(source).inspect}"
            holder.send :"#{holder_column}=", open(source)
          end
        end
        holder.save
      end
    end

  end
end