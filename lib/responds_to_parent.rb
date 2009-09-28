# Module containing the methods useful for child IFRAME to parent window communication
module RespondsToParent
  # Executes the response body as JavaScript in the context of the parent window.
  # Use this method of you are posting a form to a hidden IFRAME or if you would like
  # to use IFRAME base RPC.
  def responds_to_parent
    yield if block_given?
    default_render unless performed?
    
    if performed?
      # Either pull out a redirect or the request body
      script =  if location = erase_redirect_results
                  "document.location.href = '#{self.class.helpers.escape_javascript location.to_s}'"
                else
                  response.body || ''
                end

      # Clear out the previous render to prevent double render
      erase_results

      # We're returning HTML instead of JS or XML now
      response.headers['Content-Type'] = 'text/html; charset=UTF-8'

      # Eval in parent scope and replace document location of this frame 
      # so back button doesn't replay action on targeted forms
      # loc = document.location to be set after parent is updated for IE
      # with(window.parent) - pull in variables from parent window
      # setTimeout - scope the execution in the windows parent for safari
      # window.eval - legal eval for Opera
      render :text => <<END
<html>
<body>
<script type='text/javascript' charset='utf-8'>
  function parent_eval(script_text) {
    var is_webkit = navigator.userAgent.indexOf(' AppleWebKit/') >= 0;
    var window_parent = window.parent;
    if(is_webkit) {
      var parent_document = window_parent.document;
      var target = parent_document.documentElement;
      var script = parent_document.createElement('script');
      script.type = 'text/javascript';
      script.appendChild(parent_document.createTextNode(script_text));
      target.insertBefore(script, target.firstChild);
      target.removeChild(script);
    } else if(window_parent.execScript) {
      window_parent.execScript(script_text, 'JavaScript');
    } else if(window_parent.eval) {
      window_parent.eval(script_text);
    } else {
      eval.call(window_parent, script_text);
    }
  }
  parent_eval('#{self.class.helpers.escape_javascript script}');
  document.location.replace('about:blank');
</script>
</body>
</html>
END
    end
  end
  alias respond_to_parent responds_to_parent
end
