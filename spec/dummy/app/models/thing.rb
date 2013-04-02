class Thing < ActiveRecord::Base
  has_upload :pet, :crop => "640x427#", :precrop => "1280x854<"
  has_upload :friend, :crop => "640x427#", :styles => { :large => "1200x1200>", :thumb => "48x48#" }
end
