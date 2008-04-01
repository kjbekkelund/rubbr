module Rubbr

  # Takes care of running latex and related utilities. Gives helpful
  # information if input files are missing and also cleans up the output of
  # these utilities.
  module Runner
    class Base
      include Rubbr::Cli

      # The file to be run trough the latex process.
      attr_accessor :input_file

      # The executable to be run.
      attr_accessor :executable

      # Contains a list of possible warnings after a run.
      attr_accessor :warnings

      # Contains a list of possible errors after a run.
      attr_accessor :errors

      def initialize(input_file, executable)
        @input_file = input_file
        @executable = valid_executable executable
        @errors = []

        if File.exists? @input_file
          run
        else
          error "Running of #@executable aborted. " +
                "Input file: #@input_file not found"
        end
      end

      def run
        disable_stdinn do # No input in case of error correction dialogue
          messages = /^(Overfull|Underfull|No file|Package \w+ Warning:|LaTeX Warning:)/
          run = `#@executable #@input_file`
          puts run if Rubbr.options[:verboser]
          @warnings = run.grep(messages).sort
          lines = run.split("\n")
          while lines.shift
            if lines.first =~ /^!/ # LaTeX Error, processing halted
              3.times { @errors << lines.shift }
            end
          end
        end
      end

      def feedback
        return if Rubbr.options[:verboser] # No preformatted output.
        unless @warnings.empty?
          notice "Warnings from #@executable:"
          @warnings.each do |message|
            warning message
          end
        end
        unless @errors.empty?
          notice "Errors from #@executable:"
          @errors.each do |message|
            error message
          end
          exit
        end
      end
    end

    %w(latex bibtex dvips ps2pdf pdflatex).each do
      |f| require File.dirname(__FILE__) + "/runner/#{f}"
    end
  end
end
