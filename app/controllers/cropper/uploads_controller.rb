module Cropper
  class UploadsController < ::ApplicationController
    respond_to :js
    before_filter :find_upload, :only => [:show, :edit, :destroy]

    def show
      respond_with(@upload)
    end

    def new
      @upload = Upload.new(params[:upload])
      render
    end

    def create
      @upload = Upload.create(params[:upload])
      render :partial => 'crop'
    end

    def edit
      render :partial => 'crop'
    end
  
    def destroy
      @upload.destroy
      respond_with(@upload)
    end

  private
  
    def find_upload
      if params[:id] == 'latest' || params[:id].blank? 
        @upload = current_user.last_upload
      else
        @upload = Upload.find(params[:id])
      end
    end

  end
end
