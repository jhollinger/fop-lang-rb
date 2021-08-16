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

    Op = Struct.new(:wildcard, :match, :regex_match, :regex, :operator, :operator_arg, :expression) do
      def consume!(input)
        if (val = input.slice!(regex))
          found_val = regex_match || val != Parser::BLANK
          expression && found_val ? expression.call(val) : val
        end
      end

      def to_s
        w = wildcard ? "*" : nil
        s = "#{w}#{match}"
        s << " #{operator} #{operator_arg}" if operator
        s
      end
    end
  end
end
