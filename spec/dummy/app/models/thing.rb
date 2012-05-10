# This is a base class for your uploads. It defines all the essential methods and offers some hooks that
# you can override to set local style definitions. All you need is something like this:
#
#   class Upload << Cropper::Upload
#     def thumbnail_styles 
#       {:precrop => "500x500>"}
#     end
#
# If you have models with very different image-crop outcomes you may want to define a different precrop 
# style for each one.
#
class Thing < ActiveRecord::Base
  has_upload :pet, :geometry => "640x427#"
  has_upload :friend, :geometry => "640x427#", :styles => { :large => "1200x1200>", :thumb => "48x48#" }
end
