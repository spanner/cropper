#= require lib/modernizr
#= require lib/es5-shim
#= require cropper/filedrop
#= require cropper/upload_crop_scale

jQuery ($) ->
  $.activate_with () ->
    @find_including_self('[data-action="upload"]').uploader()
    @find_including_self('[data-action="recrop"]').recropper()
