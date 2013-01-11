# 
#
#  This is a somewhat hacked up version of filedrop, by Weixi Yen:
# 
#  Email: [Firstname][Lastname]@gmail.com
#  
#  Copyright (c) 2010 Resopollution
#  
#  Licensed under the MIT license:
#    http://www.opensource.org/licenses/mit-license.php
# 
#  Project home:
#    http://www.github.com/weixiyen/jquery-filedrop
# 
#  Version:  0.1.0
# 
#  Features:
#       Allows sending of extra parameters with file.
#       Works with Firefox 3.6+
#       Future-compliant with HTML5 spec (will work with Webkit browsers and IE9)
#  Usage:
#      See README at project homepage

Modernizr.addTest 'filereader', ->
  !!(window.File && window.FileList && window.FileReader)

jQuery ($) ->
  jQuery.event.props.push "dataTransfer"

  opts = {}
  errors = [ "BrowserNotSupported", "TooManyFiles", "FileTooLarge" ]
  doc_leave_timer = undefined
  stop_loop = false
  files_count = 0
  files = undefined
  
  drop = (e) ->
    e.preventDefault()
    opts.drop e
    files = e.dataTransfer.files
    unless Modernizr.filereader && files?
      opts.error(errors[0])
      return false
    files_count = files.length
    upload()
    false

  pick = (e, filefield) ->
    e.preventDefault()
    files = filefield.files
    unless Modernizr.filereader && files?
      opts.error(errors[0])
      return false
    files_count = files.length
    console.log "pick", files
    upload()
    false

  getBuilder = (filename, filedata, boundary) ->
    dashdash = "--"
    crlf = "\r\n"
    builder = ""
    $.each opts.data, (i, val) ->
      val = val()  if typeof val is "function"
      builder += dashdash
      builder += boundary
      builder += crlf
      builder += "Content-Disposition: form-data; name=\"" + i + "\""
      builder += crlf
      builder += crlf
      builder += val
      builder += crlf

    builder += dashdash
    builder += boundary
    builder += crlf
    builder += "Content-Disposition: form-data; name=\"" + opts.paramname + "\""
    builder += "; filename=\"" + filename + "\""
    builder += crlf
    builder += "Content-Type: image/jpeg"
    builder += crlf
    builder += crlf
    builder += filedata
    builder += crlf
    builder += dashdash
    builder += boundary
    builder += dashdash
    builder += crlf
    builder

  progress = (e) ->
    if e.lengthComputable
      percentage = Math.round((e.loaded * 100) / e.total)
      unless @currentProgress is percentage
        @currentProgress = percentage
        opts.progressUpdated @index, @file, @currentProgress
        elapsed = new Date().getTime()
        diffTime = elapsed - @currentStart
        if diffTime >= opts.refresh
          diffData = e.loaded - @startData
          speed = diffData / diffTime
          opts.speedUpdated @index, @file, speed
          @startData = e.loaded
          @currentStart = elapsed

  upload = ->
    send = (e) ->
      e.target.index = getIndexBySize(e.total)  if e.target.index is `undefined`
      xhr = new XMLHttpRequest()
      ul = xhr.upload
      file = files[e.target.index]
      index = e.target.index
      start_time = new Date().getTime()
      boundary = "------multipartformboundary" + (new Date).getTime()
      builder = undefined
      newName = rename(file.name)
      if typeof newName is "string"
        builder = getBuilder(newName, e.target.result, boundary)
      else
        builder = getBuilder(file.name, e.target.result, boundary)
      ul.index = index
      ul.file = file
      ul.downloadStartTime = start_time
      ul.currentStart = start_time
      ul.currentProgress = 0
      ul.startData = 0
      ul.addEventListener "progress", progress, false
      xhr.open "POST", opts.url, true
      xhr.setRequestHeader "content-type", "multipart/form-data; boundary=" + boundary
      xhr.sendAsBinary builder
      opts.uploadStarted index, file, files_count
      xhr.onload = ->
        if xhr.responseText
          now = new Date().getTime()
          timeDiff = now - start_time
          result = opts.uploadFinished(index, file, xhr.responseText, timeDiff)
          filesDone++
          afterAll()  if filesDone is files_count - filesRejected
          stop_loop = true  if result is false

    stop_loop = false
    unless files
      opts.error errors[0]
      return false
    filesDone = 0
    filesRejected = 0
    if files_count > opts.maxfiles
      opts.error errors[1]
      return false
    i = 0

    while i < files_count
      return false  if stop_loop
      try
        unless beforeEach(files[i]) is false
          return  if i is files_count
          reader = new FileReader()
          max_file_size = 1048576 * opts.maxfilesize
          reader.index = i
          if files[i].size > max_file_size
            opts.error errors[2], files[i], i
            filesRejected++
            continue
          reader.onloadend = send
          reader.readAsBinaryString files[i]
        else
          filesRejected++
      catch err
        opts.error errors[0]
        return false
      i++
  getIndexBySize = (size) ->
    i = 0

    while i < files_count
      return i  if files[i].size is size
      i++
    `undefined`
  rename = (name) ->
    opts.rename name
  beforeEach = (file) ->
    opts.beforeEach file
  afterAll = ->
    opts.afterAll()
  dragEnter = (e) ->
    clearTimeout doc_leave_timer
    e.preventDefault()
    opts.dragEnter e
  dragOver = (e) ->
    clearTimeout doc_leave_timer
    e.preventDefault()
    opts.docOver e
    opts.dragOver e
  dragLeave = (e) ->
    clearTimeout doc_leave_timer
    opts.dragLeave e
    e.stopPropagation()
  docDrop = (e) ->
    e.preventDefault()
    opts.docLeave e
    false
  docEnter = (e) ->
    clearTimeout doc_leave_timer
    e.preventDefault()
    opts.docEnter e
    false
  docOver = (e) ->
    clearTimeout doc_leave_timer
    e.preventDefault()
    opts.docOver e
    false
  docLeave = (e) ->
    doc_leave_timer = setTimeout(->
      opts.docLeave e
    , 200)
  empty = ->

  default_opts =
    url: ""
    refresh: 1000
    paramname: "userfile"
    maxfiles: 25
    maxfilesize: 1
    data: {}
    drop: empty
    dragEnter: empty
    dragOver: empty
    dragLeave: empty
    docEnter: empty
    docOver: empty
    docLeave: empty
    beforeEach: empty
    afterAll: empty
    rename: empty
    error: (err, file, i) ->
      alert err

    uploadStarted: empty
    uploadFinished: empty
    progressUpdated: empty
    speedUpdated: empty

  $.fn.filedrop = (options) ->
    opts = $.extend({}, default_opts, options)
    @bind("drop", drop).bind("pick", pick).bind("dragenter", dragEnter).bind("dragover", dragOver).bind "dragleave", dragLeave
    $(document).bind("drop", docDrop).bind("dragenter", docEnter).bind("dragover", docOver).bind "dragleave", docLeave

  try
    return if XMLHttpRequest::sendAsBinary
    XMLHttpRequest::sendAsBinary = (datastr) ->
      byteValue = (x) ->
        x.charCodeAt(0) & 0xff
      ords = Array::map.call(datastr, byteValue)
      ui8a = new Uint8Array(ords)
      @send ui8a.buffer
