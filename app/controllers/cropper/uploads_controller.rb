module Cropper
  class UploadsController < ::ApplicationController
    respond_to :js
    before_filter :get_holder, :only => [:new]
    before_filter :find_upload, :only => [:show, :edit, :destroy]
    before_filter :build_upload, :only => [:new, :create]

    def index
      respond_with(@uploads)
    end
    
    def show
      respond_with(@upload)
    end

    def new
      respond_with @upload
    end

    def create
      @upload.update_attributes(params[:upload])
      redirect_to :edit
    end

    def edit
      respond_with(@upload)
    end

    def update
      @upload.update_attributes(params[:upload])
      @holder.save
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
      end
      raise ActiveRecord::RecordNotFound, "Cannot find a valid holder for this upload." unless @holder
    end
    
    def build_upload
      @column = params[:for] || :image
      @upload = @holder.send :"build_#{@column}_upload"
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
