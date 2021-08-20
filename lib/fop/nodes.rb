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

    Expression = Struct.new(:wildcard, :match, :regex_match, :regex, :operator, :arg) do
      def to_s
        w = wildcard ? "*" : nil
        s = "[#{w}exp] #{match}"
        if operator
          arg_str = arg
            .map { |a| a.is_a?(Integer) ? "$#{a+1}" : a.to_s }
            .join("")
          s << " #{operator} #{arg_str}"
        end
        s
      end
    end
  end
end
