// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
Ajax.Responders.register({
 onCreate: function(){
   if($('ajax_busy') && Ajax.activeRequestCount > 0){
       Effect.Appear('ajax_busy', {duration: 0.5, queue: 'end'});
   }
 },
 onComplete: function(){
   if($('ajax_busy') && Ajax.activeRequestCount == 0){
     Effect.Fade('ajax_busy', {duration: 0.5, queue: 'end'});
   }
 }
});
