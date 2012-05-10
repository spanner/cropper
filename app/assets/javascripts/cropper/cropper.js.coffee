jQuery ($) ->
        
  $.fn.click_proxy = (target_selector) ->
    this.bind "click", (e) ->
      e.preventDefault()
      $(target_selector).click()

$ ->
  $('.dropbox').uploader()	
  $('a.recrop').recropper()	
