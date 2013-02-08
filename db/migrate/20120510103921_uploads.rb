class Uploads < ActiveRecord::Migration
  def change
    create_table :cropper_uploads do |t|
      t.attachment :file
      t.string :original_extension
      t.integer :original_width
      t.integer :original_height
      t.timestamps
    end
  end
end
