module Fop
  module Nodes
    Text = Struct.new(:wildcard, :str, :regex) do
      def to_s
        w = wildcard ? "*" : nil
        "[#{w}txt] #{str}"
      end
    end

    Regex = Struct.new(:wildcard, :src, :regex) do
      def to_s
        w = wildcard ? "*" : nil
        "[#{w}reg] #{src}"
      end
    end

    Expression = Struct.new(:wildcard, :match, :regex_match, :regex, :operator_token, :args) do
      def to_s
        w = wildcard ? "*" : nil
        s = "[#{w}exp] #{match}"
        if operator_token
          arg_str = args
            .map { |a| a.is_a?(Integer) ? "$#{a+1}" : a.to_s }
            .join("")
          s << " #{operator_token.val} #{arg_str}"
        end
        s
      end
    end

    Arg = Struct.new(:segments, :has_captures) do
      def to_s
        segments.map { |s|
          case s
          when Integer then "$#{s + 1}"
          else s.to_s
          end
        }.join("")
      end
    end
  end
end
