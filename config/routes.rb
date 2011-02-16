ActionController::Routing::Routes.draw do |map|
  map.root :controller => "home"

  map.biz '/mykat7310', :controller => 'users', :action => 'biz'
  map.logout '/logout', :controller => 'users', :action => 'destroy'
  map.forgot '/forgot', :controller => 'users', :action => 'forgot'
  map.change_password '/changepassword', :controller => 'users', :action => 'change_password'

  map.profile '/profile', :controller => 'users', :action => 'profile'

  map.winners '/winners', :controller => 'home', :action => 'winners'
  map.say_your_price '/sayprice', :controller => 'home', :action => 'say_your_price'

  map.success '/success', :controller => 'products', :action => 'success'
  map.cancel '/cancel', :controller => 'products', :action => 'cancel'

  map.product_catalog '/products', :controller => 'products', :action => 'products'
  map.send_to '/:id/sendto', :controller => 'products', :action => 'send_to'
  map.payments '/payment/:id', :controller => 'products', :action => 'payments'

  map.capsule '/:id', :controller => 'products', :action => 'capsule'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
