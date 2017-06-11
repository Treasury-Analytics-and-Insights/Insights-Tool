$( document ).ready(function() {
  $('#aoa_links a h3').click(function() {
	  $('.navbar-nav li').removeClass();
    var clicked = $(this).text();
    $('.navbar-nav li a').each(function(index) {
	    if($(this).attr('data-value')==clicked){
		    $(this).trigger("click");
	    }
    });
  });
  
  $('.footer-right a').click(function() {
  	$('.navbar-nav li').removeClass();
  	var clicked = $(this).attr("direct_to");
  	$('.navbar-nav li a').each(function(index) {
  		if($(this).attr('data-value')==clicked){
  			$(this).trigger("click");
  		}
  	});
  });
  
  $('.banner a').click(function() {
  	$('.navbar-nav li').removeClass();
  	var clicked = $(this).attr("direct_to");
  	$('.navbar-nav li a').each(function(index) {
  		if($(this).attr('data-value')==clicked){
  			$(this).trigger("click");
  		}
  	});
  });
});