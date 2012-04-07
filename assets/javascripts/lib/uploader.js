$(function(){
  
  $.fn.uploader = function () {
    var dropbox = $(this);
    var csrf_token = dropbox.parents('form').find('input[name="authenticity_token"]').val();
    var filefield = $('#person_image');
    var url = dropbox.attr('rel');
    var finisher = function(i, file, response, time) {
      dropbox.find('div.progress_holder').remove();
      new Cropper(response, dropbox);
    };
    var paramname = 'upload[file]';

    dropbox.filedrop({
      fallback_id: 'scholar_image',
      maxfiles: 1,
      maxfilesize: 5,
      url: url,
      paramname: paramname,
      data: { authenticity_token: csrf_token },
      
      error: function (err, file) {
        switch(err) {
          case 'BrowserNotSupported':
            console.log("no html5 support: trying an iframe");

            var auth = $('input[name="authenticity_token"]').clone();
            var form = $('<form id="uform" method="post" enctype="multipart/form-data" />').append(auth);
            var iframe = $('<iframe id="uframe" />');
            
            // append iframe to document
            $('body').append(iframe);
            
            // clone file field
            var newff = filefield.clone();
            
            // move file field clone into position of original file field
            filefield.before(newff).attr('name', paramname);
            
            // move original file field into form, append form to body and
            // set form 'action' attribute to our url variable and 'target' attribute to id of iframe
            form.append(filefield).appendTo('body').attr('action' , url).attr('target' , iframe.attr('id'));
            
            // make file field clone the new trigger
            filefield = newff.change(function (e) {
              dropbox.trigger('pick', filefield[0])
            });
            
            // attach a load handler to the iframe
            iframe.bind('load', function () {
              var response = iframe[0].contentWindow.document.body.innerHTML;
              if (response && response != "") {
                finisher.call(this, null, null, response, null);
                iframe.remove();
                form.remove();
              }
            });
            form.submit();
            // show a spinner where the progress bar would have been
            $('.waiter').show();
            
            break;
          case 'TooManyFiles':
            alert('You can only upload 1 file.');
            break;
          case 'FileTooLarge':
            alert(file.name +' is too large! Files up to 5mb are allowed.');
            break;
          default:
            break;
        }
      },
      
      dragOver: function() {
        dropbox.addClass('hover');
      },
      dragLeave: function() {
        dropbox.removeClass('hover');
      },
      beforeEach: function (file) {
        dropbox.removeClass('hover');
        if(!file.type.match(/^image\//)){
          alert('Sorry: only image files are allowed!');
          return false;
        }
      },
      uploadStarted:function(i, file, len){
        dropbox.find('img').fadeTo('fast', 0.5);
        dropbox.find('p.instructions').hide();
        dropbox.append('<div class="progress_holder"><div class="progress"></div><div class="commentary">0% uploaded</div></div>');
      },
      progressUpdated: function(i, file, progress) {
        dropbox.find('div.progress').width(progress + '%');
        dropbox.find('div.commentary').text(progress + '% uploaded');
      },
      uploadFinished: finisher
    });
    
    dropbox.find('a.picker').picker();
    filefield.change(function (e) {
      dropbox.trigger('pick', filefield[0])
    });
  };
  
  $.fn.recropper = function () {
    var dropbox = $('div.dropbox');
    this.click(function (e) {
      e.preventDefault();
      dropbox.find('div.waiter').show();
      $.get($(this).attr('href'), function (response) {
        new Cropper(response, dropbox);
      }, 'html');
    });
    return this;
  }
  
  $.fn.picker = function () {
    this.click(function (e) {
      e.preventDefault();
      e.stopPropagation();
      $('#person_image').click();
    });
    return this;
  }
  
  var Cropper = function (response, container) {
    var self = this;
    var element = $(response);
    var preview = element.find('div.preview');
    var fields = element.find('fieldset.crop');
    var overflow = $('<div class="overflow">').append(preview.find('img').clone());
    var range = fields.find('input[type="range"]');
    var controls = container.find('.controls');
    
    container.find('div.preview').remove();
    container.find('div.img').after(preview);
    container.find('div.waiter').hide();
    container.append(fields);
    $('#bigpicture').before(overflow);
    var start_position = preview.position();
    
    $.extend(self, {
      container: container,
      fields: fields,
      preview: preview,
      overflow: overflow,
      scaler: null,
      
      controls: controls,
      top: start_position.top,
      left: start_position.left,
      toplimit: null,
      leftlimit: null,
      aspect: null,
      lastX: 0,
      lastY: 0,
      drag: function (e) {
        e.preventDefault();
        self.lastY = e.pageY;
        self.lastX = e.pageX;
        $(window).bind('mousemove', self.move);
        $(window).bind('mouseup', self.drop);
        self.showOverflow();
      },
      move: function (e) {
        self.moveTop(e.pageY - self.lastY);
        self.lastY = e.pageY;
        self.moveLeft(e.pageX - self.lastX)
        self.lastX = e.pageX;
        self.setOverflow();
      },
      resize: function (w) {
        var h = Math.round(w * self.aspect),
            width = self.preview.width(),
            height = self.preview.height(),
            deltaT = Math.round((w - width) / 2),
            deltaL = Math.round((h - height) / 2);

        self.preview.css({ width: w, height: h });
        self.fields.find('input.sh').val(h);
        self.recalculateLimits();
        self.moveTop(-deltaT);
        self.moveLeft(-deltaL);
        self.setOverflow();
      },
      recalculateLimits: function (argument) {
        self.toplimit = self.container.height() - self.preview.height();
        self.leftlimit = self.container.width() - self.preview.width();
        self.aspect = self.preview.height() / self.preview.width();
      },
      moveTop: function (y) {
        self.top = self.top + y;
        if (self.top > 0) self.top = 0;
        if (self.top < self.toplimit) self.top = self.toplimit;
        self.preview.css('top', self.top);
      },
      moveLeft: function (x) {
        self.left = self.left + x;
        if (self.left > 0) self.left = 0;
        if (self.left < self.leftlimit) self.left = self.leftlimit;
        self.preview.css('left', self.left);
      },
      drop: function (e) {
        $(window).unbind('mousemove', self.move);
        $(window).unbind('mouseup', self.drop);
        self.move(e);
        self.hideOverflow();
        self.fields.find('input.ot').val(self.top);
        self.fields.find('input.ol').val(self.left);
      },
      showOverflow: function () {
        self.overflow.show();
      },
      hideOverflow: function () {
        self.overflow.hide();
      },
      setOverflow: function (argument) {
        self.overflow.css({ width: self.preview.width(), height: self.preview.height() });
        self.overflow.offset(self.preview.offset());
      },
      cancel: function (e) {
        e.preventDefault();
        self.preview.remove();
        self.overflow.remove();
        self.scaler.remove();
        self.fields.remove();
        self.reset_controls();
        self.container.find('img').fadeIn('slow');
        self.container.find('p.instructions').show();
      },
      complete: function (e) {
        e.preventDefault();
        self.scaler.remove();
        self.overflow.remove();
        self.preview.fadeTo('slow', 1);
        self.container.find('.range_marker').remove();
        self.reset_controls();
      },
      set_controls: function () {
        self.controls.find('.edit').hide();
        self.controls.find('.cancel').show();
        self.controls.find('a.picker').addClass('unavailable').unbind('click');
        self.controls.find('.save a').removeClass('unavailable').bind('click', self.complete);
      },
      reset_controls: function () {
        self.controls.find('.cancel').hide();
        self.controls.find('.edit').show();
        self.controls.find('a.picker').removeClass('unavailable').picker();
        self.controls.find('.save a').addClass('unavailable').unbind('click');
      }
    });
    self.recalculateLimits();
    self.setOverflow();
    self.scaler = new Scaler(range, {
      drag: self.showOverflow,
      move: self.resize,
      drop: self.hideOverflow
    });
    self.controls.find('.cancel a').bind('click', self.cancel);
    self.preview.bind('mousedown', self.drag);
    self.set_controls();
  }
  
  var Scaler = function (range, callbacks) {
    var self = this;
    var input = $(range);
    if (callbacks === undefined) callbacks = {};
    var slider = $('<span class="slider"><span class="scale"><span class="marker"></span></span></span>');
    input.before(slider);
    input.hide();
    $.extend(self, {
      input: input,
      pos: 0,
      value: input.val(),
      max: parseInt(input.attr('max'), 10),
      min: parseInt(input.attr('min'), 10),
      slider: slider,
      scale: slider.find('.scale'),
      marker: slider.find('.marker'),
      lastX: 0,
      drag: function (e) {
        e.preventDefault();
        self.lastX = e.pageX;
        $(window).bind('mousemove', self.move);
        $(window).bind('mouseup', self.drop);
        if (callbacks.drag !== null) callbacks.drag.call(self, self.value);
      },
      move: function (e) {
        var deltaX = e.pageX - self.lastX;
        self.pos = self.pos + e.pageX - self.lastX;
        if (self.pos < 0) self.pos = 0;
        if (self.pos > 400) self.pos = 400;
        self.placeMarker(self.pos);
        self.recalculate();
        self.lastX = e.pageX;
        if (callbacks.move !== null) callbacks.move.call(self, self.value);
      },
      drop: function (e) {
        self.move(e);
        $(window).unbind('mousemove', self.move);
        $(window).unbind('mouseup', self.drop);
        if (callbacks.drop !== null) callbacks.drop.call(self, self.value);
      },
      recalculate: function () {
        var origin = self.min;
        var pixel_proportion = (self.pos / 400);
        var value_width = self.max - self.min;
        self.value = Math.round(origin + (value_width * pixel_proportion));
        self.input.val(self.value);
      },
      reposition: function () {
        var origin = self.min;
        var value_proportion = (self.value - origin) / (self.max - origin);
        var pixel_width = 400;
        self.pos = Math.round(pixel_width * value_proportion);
        self.placeMarker(self.pos);
      },
      placeMarker: function (x) {
        self.marker.css('left', x - 3);
      },
      remove: function () {
        self.slider.remove();
      }
    });
    self.reposition();
    self.marker.bind('mousedown', self.drag);
  }
  
});