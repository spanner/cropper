module Cropper
  class UploadsController < ::ApplicationController
    respond_to :js
    before_filter :find_upload, :only => [:show, :edit, :destroy]


    def index
      respond_with(@uploads)
    end
    
    def show
      respond_with(@upload)
    end

    def new
      @upload = Upload.new(params[:upload])
      render
    end

    def create
      @upload = Upload.create(params[:upload])
      redirect_to :edit
    end

    def edit
      respond_with(@upload)
    end
  
    def destroy
      @upload.destroy
      head :ok
    end

  private
  
    def find_upload
      if params[:uuid]
        @upload = Cropper::Upload.find_by_uuid(params[:uuid])
      else
        @upload = Cropper::Upload.find(params[:id])
      end
    end

  end
end
