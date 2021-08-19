require_relative 'parser'

module Fop
  module Compiler
    def self.compile(src)
      parser = Parser.new(src)
      nodes, errors = parser.parse
      return nodes, errors
    end
  end
end
