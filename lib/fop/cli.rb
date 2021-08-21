require 'optparse'

module Fop
  module CLI
    Options = Struct.new(:src, :check, :quiet)

    def self.options!
      options = Options.new
      OptionParser.new do |opts|
        opts.banner = "Usage: fop [options] [ 'prog' | -f progfile ] [ file ... ]"

        opts.on("-fFILE", "--file=FILE", "Read program from file instead of first argument") do |f|
          options.src = File.open(f)
          options.src.advise(:sequential)
        end

        opts.on("-c", "--check", "Perform a syntax check on the program and exit") do
          options.check = true
        end

        opts.on("-q", "--quiet") do
          options.quiet = true
        end
      end.parse!

      options.src ||= StringIO.new(ARGV.shift)
      options
    end
  end
end
