class UploadHolder < ActiveRecord::Migration
  def change
    add_column :cropper_uploads, :holder_id, :integer
    add_column :cropper_uploads, :holder_type, :string
    add_column :cropper_uploads, :holder_column, :string

    Cropper::Upload.reset_column_information
    Cropper::Upload.all.each do |u|
      puts "finding match for upload #{u.id}"
      if person = Droom::Person.where(:image_upload_id => u.id).first
        puts "-> #{person.formal_name}"
        %w{offset_left offset_top scale_width scale_height}.each do |col|
          u.update_column(col.to_sym, person.send(:"image_#{col}"))
        end
        u.update_column(:holder_type, "Droom::Person")
        u.update_column(:holder_column, 'image')
      end
    end
  end
end
