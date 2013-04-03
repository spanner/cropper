class UploadsHoldCropData < ActiveRecord::Migration
  def change
    add_column :cropper_uploads, :scale_width, :integer
    add_column :cropper_uploads, :scale_height, :integer
    add_column :cropper_uploads, :offset_left, :integer
    add_column :cropper_uploads, :offset_top, :integer
  end
end
