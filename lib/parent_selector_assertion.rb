module ActionController
  module Assertions
    module SelectorAssertions
      JS_UNESCAPES = {
        'r' => "\r",
        'n' => "\n",
      }
      # :call-seq:
      #   assert_select_parent()
      #   assert_select_parent() { |script| ... }
      #
      # Selects JavaScript that is generated for the `parent' window.
      #
      # Without a block, #assert_select_parent asserts that the response
      # is generated by responds_to_parent.
      #
      # With a block, #assert_select_parent selects script that is supposed
      # to be evaluated in the parent window and passes it to the block.
      # Typically #assert_select_rjs is used in the block.
      def assert_select_parent(*args, &block)
        if @response.body =~ /window\.parent\.eval\('(.*)'\);\s*document\.location\.replace\('about\:blank'\);/
          escaped_js = $1
          unescaped_js = escaped_js.gsub(/\\(.)/) { JS_UNESCAPES[$1] || $1 }
          @response.body = unescaped_js # assert_select_rjs refers @response.body.

          if block_given?
            begin
              in_scope, @selected = @selected, unescaped_js
              yield unescaped_js
            ensure
              @selected = in_scope
            end
          end
          unescaped_js
        else
          # doesn't seem a responds_to_parent content.
          flunk args.shift || "No content for the parent window."
        end
      end
    end
  end
end
