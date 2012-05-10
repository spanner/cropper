class Uploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.has_attached_file :file
      t.string :original_extension
      t.integer :original_width
      t.integer :original_height
      t.timestamps
    end
  end
end
