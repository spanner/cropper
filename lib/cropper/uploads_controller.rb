module Cropper
  class UploadsController < ApplicationController
    respond_to :js

    def show
      @upload = params[:id] == 'latest' || params[:id].blank? ? current_user.last_upload : Upload.find(params[:id])
      respond_with(@upload)
    end

    def create
      @upload = Upload.create(params[:upload])
      render :partial => 'crop'
    end

    def edit
      @upload = Upload.find(params[:id])
      if @person && @upload = @person.upload
        render :partial => 'crop', :locals => {
          :scale_w => @person.image_scale_width,
          :scale_h => @person.image_scale_height,
          :scale_t => @person.image_offset_top,
          :scale_l => @person.image_offset_left
        }
      else
        render :partial => 'crop'
      end
    end
  
    def destroy
      @upload = Upload.find(params[:id])
      @upload.destroy
      respond_with(@upload)
    end

  end
end