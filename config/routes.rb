ActionController::Routing::Routes.draw do |map|
  map.root :controller => "home"

  map.biz '/mykat7310', :controller => 'users', :action => 'biz'
  map.logout '/logout', :controller => 'users', :action => 'destroy'
  map.forgot '/forgot', :controller => 'users', :action => 'forgot'

  map.profile '/profile', :controller => 'users', :action => 'profile'

  map.product_catalog '/products', :controller => 'products', :action => 'product_catalog'
  map.payments '/payment/:id', :controller => 'products', :action => 'payments'

  map.analytics '/analytics', :controller => 'home', :action => 'analytics'
  map.notifications '/notifications', :controller => 'home', :action => 'notifications'
  map.say_your_price '/sayprice', :controller => 'home', :action => 'say_your_price'
  map.winners '/winners', :controller => 'home', :action => 'winners'

  map.faqs '/faqs', :controller => 'home', :action => 'faqs'

  map.download_pdf '/download_pdf/:id', :controller => 'products', :action => 'download_pdf'

  map.capsule '/:id', :controller => 'products', :action => 'capsule'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
