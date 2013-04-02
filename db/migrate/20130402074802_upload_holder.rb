class UploadHolder < ActiveRecord::Migration
  def change
    add_column :cropper_uploads, :holder_id, :integer
    add_column :cropper_uploads, :holder_type, :string
  end
end
