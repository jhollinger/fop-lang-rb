require_relative 'fop/version'
require_relative 'fop/compiler'
require_relative 'fop/runtime'

def Fop(src)
  ::Fop.compile!(src)
end

module Fop
  def self.compile!(src)
    fop, errors = compile(src)
# TODO better exception
    raise "Fop errors" + errors.map(&:message).join(",") if errors.any?
    fop
  end

  def self.compile(src)
    nodes, errors = ::Fop::Compiler.compile(src)
    raise "Fop errors" + errors.map(&:message).join(",") if errors.any?
    return ::Fop::Runtime.new(nodes), errors
  end
end
