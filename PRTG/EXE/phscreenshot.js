(function(window){
  var page = require('webpage').create()
    , system = require('system')
    , timeout = system.args[3]
    , resultfile = system.args[2]
    , address = system.args[1]
    , waitfor = false;
    phantom.outputEncoding = encodings="ascii";
    page.settings.userAgent = "Chrome/14.14.14";

  if(system.args[4])
    page.clipRect = {
      top:parseInt(system.args[6],10)||0,
      left:parseInt(system.args[7],10)||0,
      width: parseInt(system.args[4],10),
      height: parseInt(system.args[5],10)
    };    
  page.open(address, function(status) {
    if (status !== 'success') {
      console.log('error loading: '+address);
      phantom.exit(2);
    } else {
      try {
         !waitfor && success(timeout);
      } catch (e) {
        console.log(e.toString());
        phantom.exit(1);
      }

    }
  });
  page.onCallback = function(data){
    waitfor = data.waitfor;
    !!data.success && success(0);
  }
  function success(timeout){
    setTimeout(function(){
      if(resultfile)
        page.render(resultfile);
      else
        page.renderBase64('PNG');
      phantom.exit(0);
    },timeout);
  } 
})(window);