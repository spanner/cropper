module Cropper
  class UploadsController < ::ApplicationController
    respond_to :js
    before_filter :get_holder, :only => [:new, :create]
    before_filter :find_upload, :only => [:show, :edit, :destroy]
    before_filter :build_upload, :only => [:new, :create]

    def index
      respond_with(@uploads)
    end
    
    def show
      respond_with(@upload)
    end

    def new
      respond_with @upload do |format|
        format.js { render :partial => 'pick' }
      end
    end

    def create
      @upload.update_attributes(params[:upload])
      # if the holder is new, this isn't populated
      @upload.holder ||= @holder
      respond_with(@upload) do |format|
        format.js { render :partial => 'crop' }
      end
    end

    def edit
      respond_with(@upload) do |format|
        format.js { render :partial => 'crop' }
      end
    end

    def update
      @upload.update_attributes(params[:upload])
      redirect_to @holder
    end

    def destroy
      @upload.destroy
      head :ok
    end

  private
  
    def get_holder
      klass = params[:holder_type]
      if id = params[:holder_id]
        @holder = klass.classify.constantize.find(id)
      else
        # The difficult case is when an upload is created during the creation of a new holder
        # this at least gives us access the necessary geometry methods.
        @holder = klass.classify.constantize.new
      end
    end
    
    def build_upload
      @column = params[:holder_column] || :image
      @upload = @holder.send(:"build_#{@column}_upload")
      @holder.send(:"#{@column}_upload=", @upload)
    end
  
    def find_upload
      if params[:uuid]
        @upload = Cropper::Upload.find_by_uuid(params[:uuid])
      else
        @upload = Cropper::Upload.find(params[:id])
      end
    end

  end
end
