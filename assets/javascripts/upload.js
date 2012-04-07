/*
  init page controls
*/

$(document).ready(function() {
  $('#grid').grid('.grid, .gridlike');
	$('input.labelled, textarea.labelled').self_label();
	$('input.password').password_field();
	$('.dropbox').uploader();
	$('.recrop').recropper();
	$('a.save, a.search, a.submit').submitter();
	$('#selectinstitution').alternate_with('#addinstitution');
  $('input.suggestible').suggestible();
  $('form#person_search').captive({replacing: '#results', clearing: '#q'}).fast();
  $('form#admin_search').captive({replacing: '#results', clearing: null}).fast();
  $('.facet a').facet_remover();
  $('ul.tagger').tagger();
  $('a.detag').detagger();
  $('#edit_links li.new').clone_when_filled('input.name, input.destination');
  $('#edit_links li.old').hide_when_emptied('input.name, input.destination');
  $('#edit_scholarships div.old').hide_when_emptied('input.from_year, input.to_year, select.institution, input.title');
  $('#edit_honours li.old').hide_when_emptied('input.year, select.honour_type, input.name');
  $('a.append').append_remote_content();
  $('a.remote, form.remote').replace_with_remote_content();
  $('a.unavailable').unavailable();
  $('input.toggle').toggle();
  $('select.row_switch').disables_row();
  $('#admin .cloud a').merge();
  $('.editable').editable();
  $('#map').init_map();
});

