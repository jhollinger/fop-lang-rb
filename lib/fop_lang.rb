require_relative 'fop/version'
require_relative 'fop/compiler'
require_relative 'fop/program'

def Fop(src)
  ::Fop.compile!(src)
end

module Fop
  def self.compile!(src)
    prog, errors = compile(src)
    # TODO better exception
    raise "Fop errors: " + errors.map(&:message).join(",") if errors
    prog
  end

  def self.compile(src)
    instructions, errors = ::Fop::Compiler.compile(src)
    return nil, errors if errors
    return Program.new(instructions), nil
  end
end
