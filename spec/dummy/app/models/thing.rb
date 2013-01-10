class Thing < ActiveRecord::Base
  has_upload :pet, :geometry => "640x427#"
  has_upload :friend, :geometry => "640x427#", :styles => { :large => "1200x1200>", :thumb => "48x48#" }
end
