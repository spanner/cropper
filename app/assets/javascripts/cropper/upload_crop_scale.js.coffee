jQuery ($) ->

  $.fn.detach_upload = ->
    @click (e) ->
      e.preventDefault() if e
      # remove the current image...
      console.log "detach_upload", $(@).parents('div.uploadbox').find('input[data-clear-on-detach]')
      # remove the nested image upload id field put in automatically by fields_for
      $(@).parents('div.uploadbox').siblings('input[type="hidden"]').remove()
      $(@).parents('.existing').remove()

  $.fn.uploader = (opts) ->
    @each ->
      options = $.extend {}, opts
      dropbox = $(@)
      csrf_token = dropbox.parents("form").find('input[name="authenticity_token"]').val()
      filefield_selector = options.filefield ? 'input.file_upload'
      filefield = dropbox.find(filefield_selector)
      url = options.url ? dropbox.attr("data-url") ? dropbox.attr("rel")
      paramname = options.paramname ? "upload[file]"
    
      finisher = (i, file, response, time) ->
        dropbox.find(".progress_holder").remove()
        dropbox.find(".waiter").remove()
        new Cropper(response, dropbox, filefield)

      dropbox.filedrop
        maxfiles: 1
        maxfilesize: 10
        url: url
        paramname: paramname
        data:
          authenticity_token: csrf_token

        error: (err, file) ->
          switch err
            when "BrowserNotSupported"
              auth = $('input[name="authenticity_token"]').clone()
              form = $('<form id="uform" method="post" enctype="multipart/form-data" />').append(auth)
              iframe = $('<iframe id="uframe" name="uframe" />').appendTo($('body'))
              newff = filefield.clone()
              filefield.before(newff).attr("name", paramname)
              form.append(filefield).appendTo("body").attr("action", url).attr("target", "uframe")
              newff.change((e) ->
                dropbox.trigger "pick", filefield[0]
              )
              filefield = newff
              iframe.bind "load", () ->
                response = iframe[0].contentWindow.document.body.innerHTML
                if response and response isnt ""
                  finisher.call this, null, null, response, null
                  iframe.remove()
                  form.remove()

              dropbox.find(".instructions").hide()
              dropbox.find(".img").fadeTo('slow', 0.1)
              dropbox.find(".waiter").show()
              form.submit()

            when "TooManyFiles"
              alert "You can only upload 1 file."

            when "FileTooLarge"
              alert "#{file.name} is too large! Files up to 10MB are allowed"
            
            else
              alert "#{file.name} caused an unknown error: #{err}"
            
        dragOver: ->
          dropbox.addClass "hover"

        dragLeave: ->
          dropbox.removeClass "hover"

        beforeEach: (file) ->
          dropbox.removeClass "hover"
          unless file.type.match(/^image\//)
            alert "Sorry: only image files are allowed!"
            false

        afterAll: ->
          filefield.val ""

        uploadStarted: (i, file, len) ->
          dropbox.find("img").fadeTo "fast", 0.5
          dropbox.find("p.instructions").hide()
          dropbox.append "<div class=\"progress_holder\"><div class=\"progress\"></div><div class=\"commentary\">0% uploaded</div></div>"

        progressUpdated: (i, file, progress) ->
          dropbox.find("div.progress").width progress + "%"
          dropbox.find("div.commentary").text progress + "% uploaded"

        uploadFinished: finisher

      dropbox.find('a[data-action="pick"]').picker(filefield)
      dropbox.find('a[data-action="detach"]').detach_upload()
      filefield.change (e) ->
        dropbox.trigger "pick", filefield[0]
    @
    
  $.fn.recropper = ->
    uploadbox = $("div.uploadbox")
    @click (e) ->
      e.preventDefault()
      uploadbox.find("div.waiter").show()
      $.get $(this).attr("href"), ((response) ->
        new Cropper(response, uploadbox)
      ), "html"
    @

  $.fn.picker = (filefield) ->
    @click (e) ->
      e.preventDefault()
      e.stopPropagation()
      filefield ?= $("input.file_upload")
      console.log "picker click",  filefield.get(0)
      filefield.trigger('click')
    @

  $.fn.click_proxy = (target_selector) ->
    this.bind "click", (e) ->
      e.preventDefault()
      $(target_selector).click()



  class Cropper
    constructor: (response, container, filefield) ->
      @element = $(response)
      @container = container
      @field = filefield
      @preview = @element.find("div.preview")
      @instructions = @element.find("p.drag_instructions")
      @fields = @element.find("fieldset.crop")
      @overflow = $("<div class=\"overflow\">").append(@preview.find("img").clone())
      @controls = @container.find(".controls")
      @container.find("div.preview").remove()
      @container.find("div.img").after(@preview)
      @container.find("div.waiter").hide()
      @container.append @instructions
      @container.append @fields
      @container.before @overflow

      @field?.prop('disabled', true)
      
      @detacher = $('<a href="#" class="detach" />').appendTo(@container)
      @detacher.click @cancel

      @top = @preview.position().top
      @left = @preview.position().left
      @lastX = 0
      @lastY = 0

      range = @fields.find("input[type=\"range\"]")
      @scaler = new Scaler range,
        drag: @showOverflow
        move: @resize
        drop: @hideOverflow

      @controls.find(".cancel a").bind "click", @cancel
      @preview.bind "mousedown", @drag

      @recalculateLimits()
      @setOverflow()
      @setControls()
      @container.bind "mouseenter", @showClutter
      @container.bind "mouseleave", @hideClutter
      # @hide()

    drag: (e) =>
      e.preventDefault()
      $(document).bind "mousemove", @move
      $(document).bind "mouseup", @drop
      @lastY = e.pageY
      @lastX = e.pageX
      @hideClutter()
      @showOverflow()

    move: (e) =>
      e.preventDefault()
      @moveTop e.pageY - @lastY
      @moveLeft e.pageX - @lastX
      @lastY = e.pageY
      @lastX = e.pageX
      @setOverflow()

    resize: (w) =>
      h = Math.round(w * @aspect)
      deltaT = Math.round((w - @preview.width()) / 2)
      deltaL = Math.round((h - @preview.height()) / 2)
      @preview.css
        width: w
        height: h
      @fields.find("input.sh").val h
      @recalculateLimits()
      @moveTop(-deltaT)
      @moveLeft(-deltaL)
      @setOverflow()

    recalculateLimits: (argument) =>
      @toplimit = @container.height() - @preview.height()
      @leftlimit = @container.width() - @preview.width()
      @aspect = @preview.height() / @preview.width()

    moveTop: (y) =>
      @top = @top + y
      @top = 0 if @top > 0
      @top = @toplimit if @top < @toplimit
      @preview.css "top", @top
      @fields.find("input.ot").val @top

    moveLeft: (x) =>
      @left = @left + x
      @left = 0  if @left > 0
      @left = @leftlimit  if @left < @leftlimit
      @preview.css "left", @left
      @fields.find("input.ol").val @left

    drop: (e) =>
      $(document).unbind "mousemove", @move
      $(document).unbind "mouseup", @drop
      @move e
      @showClutter()
      @hideOverflow()

    setOverflow: (argument) =>
      @overflow.css
        width: @preview.width()
        height: @preview.height()
      @overflow.offset @preview.offset()

    cancel: (e) =>
      e.preventDefault()
      @preview.remove()
      @overflow.remove()
      @scaler.remove()
      @fields.remove()
      @detacher.remove()
      @instructions.remove()
      @resetControls()
      @container.find("img").fadeIn "slow"
      @container.find("p.instructions").show()
      @field?.prop('disabled', false)

    complete: (e) =>
      e.preventDefault()
      @scaler.hide()
      @hideOverflow()
      @preview.unbind "mousedown", @drag
      @preview.css "cursor", 'auto'
      @container.find(".range_marker").hide()
      @resetControls()
      @controls.find(".recrop").removeClass('unavailable').unbind('click').bind "click", @resume
      @preview.wrap($('<a href="#" class="recrop" />'))
      @preview.parent().bind "click", @resume
      
    resume: (e) =>
      e.preventDefault()
      @scaler.show()
      @detacher.show()
      @showOverflow()
      @preview.bind "mousedown", @drag
      @preview.css "cursor", 'move'
      @container.find(".range_marker").show()
      @setControls()

    setControls: =>
      @controls.show()
      @controls.find(".edit").hide()
      @controls.find(".cancel").show()
      @controls.find('a[data-action="pick"]').addClass("unavailable").unbind "click"
      @controls.find(".save a").removeClass("unavailable").bind "click", @complete
      @detacher.bind "click", @cancel

    resetControls: =>
      @controls.find(".cancel").hide()
      @controls.find(".edit").show()
      @controls.find('a[data-action="pick"]').removeClass("unavailable").picker()
      @controls.find(".save a").addClass("unavailable").unbind("click")

    show: =>
      @showClutter()
      @showOverflow()

    showClutter: =>
      @scaler?.show()
      @controls?.show()
      @detacher?.show()
      @instructions?.show()

    showOverflow: =>
      @overflow.show()#fadeTo('normal', 0.3)

    hide: =>
      @hideClutter()
      @hideOverflow()

    hideClutter: =>
      @scaler?.hide()
      @controls?.hide()
      @detacher?.hide()
      @instructions?.hide()

    hideOverflow: =>
      @overflow.hide()#fadeOut('normal')

  class Scaler
    constructor: (range, callbacks) ->
      @callbacks = $.extend {}, callbacks
      @input = $(range)
      @pos = 0
      @value = @input.val()
      @max = parseInt(@input.attr("max"), 10)
      @min = parseInt(@input.attr("min"), 10)
      @slider = $("<span class=\"slider\"><span class=\"scale\"><span class=\"marker\"></span></span></span>")
      @scale = @slider.find(".scale")
      @marker = @slider.find(".marker")
      @lastX = 0

      @marker.bind("mousedown", @drag)
      @input.before(@slider).hide()
      @scale_width = @scale.width()
      console.log "scale_width", @scale_width
      @reposition()

    drag: (e) =>
      console.log "scaler drag"
      e.preventDefault()
      @lastX = e.pageX
      $(document).bind "mousemove", @move
      $(document).bind "mouseup", @drop
      @callbacks.drag?.call @, @value

    move: (e) =>
      deltaX = e.pageX - @lastX
      console.log "scaler move", deltaX
      @pos = @pos + deltaX
      @pos = 0 if @pos < 0
      @pos = @scale_width-5 if @pos > @scale_width-5
      @placeMarker(@pos)
      @recalculate()
      @lastX = e.pageX
      @callbacks.move?.call @, @value

    drop: (e) =>
      @move e
      $(document).unbind "mousemove", @move
      $(document).unbind "mouseup", @drop
      @callbacks.drop?.call @, @value

    recalculate: =>
      origin = @min
      pixel_proportion = (@pos / @scale_width)
      value_width = @max - @min
      @value = Math.round(origin + (value_width * pixel_proportion))
      @input.val(@value)

    reposition: =>
      origin = @min
      value_proportion = (@value - origin) / (@max - origin)
      @pos = Math.round(@scale_width * value_proportion)
      @placeMarker @pos

    placeMarker: (x) =>
      @marker.css "left", x

    remove: =>
      @slider.remove()
    
    hide: =>
      @slider.hide()

    show: =>
      @slider.show()
      

