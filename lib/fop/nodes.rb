module Fop
  module Nodes
    Text = Struct.new(:wildcard, :str) do
      def consume!(input)
        @regex ||= Regexp.new((wildcard ? ".*" : "^") + Regexp.escape(str))
        input.slice!(@regex)
      end

      def to_s
        w = wildcard ? "*" : nil
        "Text #{w}#{str}"
      end
    end

    Regex = Struct.new(:src, :regex) do
      def to_s
        "/#{src}/"
      end
    end

    Expression = Struct.new(:wildcard, :match, :regex_match, :regex, :operator, :operator_arg, :operator_arg_w_caps, :expression) do
      def consume!(input)
        if (match = regex.match(input))
          val = match.to_s
          blank = val == Parser::BLANK
          input.sub!(val, Parser::BLANK) unless blank
          found_val = regex_match || !blank
          arg = operator_arg_w_caps ? sub_caps(operator_arg_w_caps, match.captures) : operator_arg
          expression && found_val ? expression.call(val, operator, arg) : val
        end
      end

      def to_s
        w = wildcard ? "*" : nil
        s = "#{w}#{match}"
        s << " #{operator} #{operator_arg}" if operator
        s
      end

      private

      def sub_caps(tokens, caps)
        tokens.map { |t|
          case t
          when String then t
          when Parser::CaptureGroup then caps[t.index].to_s
          else raise Parser::Error, "Unexpected #{t} in capture group"
          end
        }.join("")
      end
    end
  end
end
