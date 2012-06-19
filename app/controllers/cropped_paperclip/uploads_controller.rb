module CroppedPaperclip
  class UploadsController < ::ApplicationController
    respond_to :js
    before_filter :find_upload, :only => [:show, :edit, :destroy]
    before_filter :build_upload, :only => [:new, :create]

    def show
      respond_with(@upload)
    end

    def new
      render
    end

    def create
      @upload.update_attributes(params[:upload])
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
      @upload = params[:id] == 'latest' || params[:id].blank? ? current_user.last_upload : Upload.find(params[:id])
    end
  
    def build_upload
      @upload = Upload.create
    end
    
  end
end
