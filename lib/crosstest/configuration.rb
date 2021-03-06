
require 'rspec/support'
require 'rspec/expectations'

module Crosstest
  RESOURCES_DIR = File.expand_path '../../../resources', __FILE__

  class Configuration < Crosstest::Core::Dash
    extend Forwardable
    field :dry_run, Object, default: false
    field :log_root, Pathname, default: '.crosstest/logs'
    field :log_level, Symbol, default: :info
    field :travis, Object, default: false
    field :concurrency, Integer

    # TODO: This should probably be configurable, or tied to Thor color options.
    if RSpec.respond_to?(:configuration)
      RSpec.configuration.color = true
    else
      RSpec::Expectations.configuration.color = true
    end

    def skeptic
      Skeptic.configuration
    end

    def default_logger
      @default_logger ||= ProjectLogger.new(stdout: $stdout, level: Core::Util.to_logger_level(log_level))
    end

    def project_set
      @project_set ||= load_project_set('crosstest.yaml')
    end

    def project_set=(project_set_data)
      if project_set_data.is_a? Skeptic::TestManifest
        @project_set = project_set_data
      else
        @project_set = ProjectSet.from_yaml project_set_data
      end
      @project_set
    rescue Errno::ENOENT => e
      raise UserError, "Could not load test manifest: #{e.message}"
    end

    def clear
      skeptic.clear
      super
    end

    alias_method :load_project_set, :project_set=
  end
end
