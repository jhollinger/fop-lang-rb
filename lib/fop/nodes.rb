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

    Match = Struct.new(:wildcard, :tokens) do
      NUM = "N"
      WORD = "W"
      WILD = "*"

      def consume!(input)
        if (val = input.slice!(@regex))
          @expression ? @expression.call(val) : val
        end
      end

      def to_s
        w = wildcard ? "*" : nil
        @op ? "#{w}#{@match} #{@op} #{@arg}" : "#{w}#{@match}"
      end

      def parse!
        match = tokens.shift || raise(ParserError, "Empty match")
        raise ParserError, "Unexpected #{match}" unless match.is_a? Tokenizer::Char

        @match = match.char
        @regex =
          case @match
          when NUM then Regexp.new((wildcard ? ".*" : "^") + "[0-9]+")
          when WORD then Regexp.new((wildcard ? ".*" : "^") + "[a-zA-Z]+")
          when WILD then /.*/
          else raise ParserError, "Unknown match type '#{@match}'"
          end

        if (op = tokens.shift)
          raise ParserError, "Unexpected #{op}" unless op.is_a? Tokenizer::Char
          arg = tokens.shift
          raise ParserError, "Unexpected #{arg}" unless arg.nil? or arg.is_a? Tokenizer::Char

          @op = op.char
          @arg = arg&.char
          @expression =
            case @op
            when "=" then ->(_) { @arg || "".freeze }
            when "+", "-", "*", "/"
              raise ParserError, "Operator #{@op} is only available for numeric matches" unless @match == NUM
              raise ParserError, "Operator #{@op} expects an argument" if @arg.nil?
              ->(x) { x.to_i.send(@op, @arg.to_i) }
            else raise ParserError, "Unknown operator #{@op}"
            end
        end
      end
    end
  end
end
