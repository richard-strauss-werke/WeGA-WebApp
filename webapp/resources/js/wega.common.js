/* WeGA common javascript library */

/* settings */
/*wegaSettings.ajaxLoaderImage = "<img src='"+options.baseHref+"/"+options.html_pixDir+"/ajax-loader.gif' alt='spinning-wheel'/>";
wegaSettings.ajaxLoaderImageBar = "<img src='"+options.baseHref+"/"+options.html_pixDir+"/ajax-loader2.gif' alt='spinning-wheel'/>";
wegaSettings.ajaxLoaderText = "Requesting content …";
wegaSettings.ajaxLoaderCombined = wegaSettings.ajaxLoaderImage+wegaSettings.ajaxLoaderText;
*/
/* functions */
function loadTooltip(id)
{
    $('.tooltip').tooltipster({
        interactive : true,
        content: 'Loading...',
        functionBefore: function(origin, continueTooltip) {
        
          // we'll make this function asynchronous and allow the tooltip to go ahead and show the loading notification while fetching our data
          continueTooltip();
/*          console.log(origin.attr('class'));*/
          var params = origin.attr('class');
            
          // next, we want to check if our data has already been cached
          if (origin.data('ajax') !== 'cached') {
             $.ajax({
                type: 'POST',
                url: '/exist/apps/WeGA-WebApp/modules/get-ajax.xql?id='+params,
                success: function(data) {
                   // update our tooltip content with our returned data and cache it
                   origin.tooltipster('update', data).data('ajax', 'cached');
                }
             });
          }
        }
   })
};