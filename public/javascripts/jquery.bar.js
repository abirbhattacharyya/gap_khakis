(function(jQuery) {
    $j = jQuery.noConflict();
    $j.fn.bar = function(options) {
        var opts = $j.extend({}, $j.fn.bar.defaults, options);
        
        return this.each(function() {
            $jthis = $j(this);
            var o = $j.meta ? $j.extend({}, opts, $jthis.data()) : opts;
			
            $jthis.click(function(e){
                if(!$j('.jbar').length){
                    timeout = setTimeout('$j.fn.bar.removebar()',o.time);
                    var _message_span = $j(document.createElement('span')).addClass('jbar-content').html(o.message);
                    _message_span.css({
                        "color" : o.color
                    });
                    var _wrap_bar;
                    (o.position == 'bottom') ?
                    _wrap_bar	  = $j(document.createElement('div')).addClass('jbar jbar-bottom'):
                    _wrap_bar	  = $j(document.createElement('div')).addClass('jbar jbar-top') ;
					
                    _wrap_bar.css({
                        "background-color" 	: o.background_color
                    });
                    if(o.removebutton){
                        var _remove_cross = $j(document.createElement('a')).addClass('jbar-cross');
                        _remove_cross.click(function(e){
                            $j.fn.bar.removebar();
                        })
                    }
                    else{
                        _wrap_bar.css({
                            "cursor"	: "pointer"
                        });
                        _wrap_bar.click(function(e){
                            $j.fn.bar.removebar();
                        })
                    }
                    _wrap_bar.append(_message_span).append(_remove_cross).hide().insertBefore($j('.content')).fadeIn('fast');
                }
            })
			
			
        });
    };
    var timeout;
    $j.fn.bar.removebar 	= function(txt) {
        if($j('.jbar').length){
            clearTimeout(timeout);
            $j('.jbar').fadeOut('fast',function(){
                $j(this).remove();
            });
        }
    };
    $j.fn.bar.defaults = {
        background_color    : '#FFFFFF',
        color               : '#000',
        position            : 'top',
        removebutton        : true,
        time                : 50000
    };
	
})(jQuery);


function showNotification(message, messageType, time){
    /* we can custom by parameter setting */
    var messagePosition = 'top';
    var backgroundColor = 'Red';
    var textColor = 'White'; //(messageType == 'error') ? 'Crimson' : '#000';//'#1E90FF';
    var removeButton = true;

    if(!$j('.jbar').length){
        timeout = setTimeout('$j.fn.bar.removebar()', time);
        var _message_span = $j(document.createElement('span')).addClass('jbar-content').html(message);
        
        _message_span.css({
            "color" : textColor
        });
        var _wrap_bar;
        (messagePosition == 'bottom') ?
        _wrap_bar	  = $j(document.createElement('div')).addClass('jbar jbar-bottom'):
        _wrap_bar	  = $j(document.createElement('div')).addClass('jbar jbar-top') ;

        _wrap_bar.css({
            "background-color" 	: backgroundColor
        });
        if(removeButton){
            var _remove_cross = $j(document.createElement('a')).addClass('jbar-cross');
            _remove_cross.click(function(e){
                $j.fn.bar.removebar();
            })
        }
        else{
            _wrap_bar.css({
                "cursor"	: "pointer"
            });
            _wrap_bar.click(function(e){
                $j.fn.bar.removebar();
            })
        }
        _wrap_bar.append(_message_span).append(_remove_cross).hide().insertBefore($j('.message-notification')).fadeIn('fast');
    }
}