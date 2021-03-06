require 'benchmark'

module Crosstest
  module Command
    class Task < Crosstest::Command::Base
      include RunAction

      # Invoke the command.
      def call
        banner "Starting Crosstest (v#{Crosstest::VERSION})"
        elapsed = Benchmark.measure do
          setup
          task = args.shift
          project_regex = args.shift
          projects = Crosstest.filter_projects(project_regex)
          if options[:exec]
            run_action(projects, :execute, options[:concurrency])
          else
            run_action(projects, task, options[:concurrency])
          end
        end
        #  Need task summary...
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
