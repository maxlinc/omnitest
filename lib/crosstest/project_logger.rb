require 'fileutils'
require 'logger'

module Crosstest
  class ProjectLogger
    include ::Logger::Severity

    # @return [IO] the log device
    attr_reader :logdev

    # Constructs a new logger.
    #
    # @param options [Hash] configuration for a new logger
    # @option options [Symbol] :color color to use when when outputting
    #   messages
    # @option options [Integer] :level the logging severity threshold
    #   (default: `Crosstest::DEFAULT_LOG_LEVEL`)
    # @option options [String,IO] :logdev filepath String or IO object to be
    #   used for logging (default: `nil`)
    # @option options [String] :progname program name to include in log
    #   messages (default: `"Crosstest"`)
    # @option options [IO] :stdout a standard out IO object to use
    #   (default: `$stdout`)
    def initialize(options = {})
      color = options[:color]

      @loggers = []
      @loggers << @logdev = logdev_logger(options[:logdev]) if options[:logdev]
      @loggers << stdout_logger(options[:stdout], color) if options[:stdout]
      @loggers << stdout_logger($stdout, color) if @loggers.empty?

      self.progname = options[:progname] || 'Crosstest'
      self.level = options[:level] || default_log_level
    end

    class << self
      private

      # @api private
      # @!macro delegate_to_first_logger
      #   @method $1()
      def delegate_to_first_logger(meth)
        define_method(meth) { |*args| @loggers.first.public_send(meth, *args) }
      end

      # @api private
      # @!macro delegate_to_all_loggers
      #   @method $1()
      def delegate_to_all_loggers(meth)
        define_method(meth) do |*args|
          result = nil
          @loggers.each { |l| result = l.public_send(meth, *args) }
          result
        end
      end
    end

    # @return [Integer] the logging severity threshold
    # @see http://is.gd/Okuy5p
    delegate_to_first_logger :level

    # Sets the logging severity threshold.
    #
    # @param level [Integer] the logging severity threshold
    # @see http://is.gd/H1VBFH
    delegate_to_all_loggers :level=

    # @return [String] program name to include in log messages
    # @see http://is.gd/5uHGK0
    delegate_to_first_logger :progname

    # Sets the program name to include in log messages.
    #
    # @param progname [String] the program name to include in log messages
    # @see http://is.gd/f2U5Xj
    delegate_to_all_loggers :progname=

    # @return [String] the date format being used
    # @see http://is.gd/btmFWJ
    delegate_to_first_logger :datetime_format

    # Sets the date format being used.
    #
    # @param format [String] the date format
    # @see http://is.gd/M36ml8
    delegate_to_all_loggers :datetime_format=

    # Log a message if the given severity is high enough.
    #
    # @see http://is.gd/5opBW0
    delegate_to_all_loggers :add

    # Dump one or more messages to info.
    #
    # @param message [#to_s] the message to log
    # @see http://is.gd/BCp5KV
    delegate_to_all_loggers :<<

    # Log a message with severity of banner (high level).
    #
    # @param message_or_progname [#to_s] the message to log. In the block
    #   form, this is the progname to use in the log message.
    # @yield evaluates to the message to log. This is not evaluated unless the
    #   logger's level is sufficient to log the message. This allows you to
    #   create potentially expensive logging messages that are only called when
    #   the logger is configured to show them.
    # @return [nil,true] when the given severity is not high enough (for this
    #   particular logger), log no message, and return true
    # @see http://is.gd/pYUCYU
    delegate_to_all_loggers :banner

    # Log a message with severity of debug.
    #
    # @param message_or_progname [#to_s] the message to log. In the block
    #   form, this is the progname to use in the log message.
    # @yield evaluates to the message to log. This is not evaluated unless the
    #   logger's level is sufficient to log the message. This allows you to
    #   create potentially expensive logging messages that are only called when
    #   the logger is configured to show them.
    # @return [nil,true] when the given severity is not high enough (for this
    #   particular logger), log no message, and return true
    # @see http://is.gd/Re97Zp
    delegate_to_all_loggers :debug

    # @return [true,false] whether or not the current severity level
    #   allows for the printing of debug messages
    # @see http://is.gd/Iq08xB
    delegate_to_first_logger :debug?

    # Log a message with severity of info.
    #
    # @param message_or_progname [#to_s] the message to log. In the block
    #   form, this is the progname to use in the log message.
    # @yield evaluates to the message to log. This is not evaluated unless the
    #   logger's level is sufficient to log the message. This allows you to
    #   create potentially expensive logging messages that are only called when
    #   the logger is configured to show them.
    # @return [nil,true] when the given severity is not high enough (for this
    #   particular logger), log no message, and return true
    # @see http://is.gd/pYUCYU
    delegate_to_all_loggers :info

    # @return [true,false] whether or not the current severity level
    #   allows for the printing of info messages
    # @see http://is.gd/lBtJkT
    delegate_to_first_logger :info?

    # Log a message with severity of error.
    #
    # @param message_or_progname [#to_s] the message to log. In the block
    #   form, this is the progname to use in the log message.
    # @yield evaluates to the message to log. This is not evaluated unless the
    #   logger's level is sufficient to log the message. This allows you to
    #   create potentially expensive logging messages that are only called when
    #   the logger is configured to show them.
    # @return [nil,true] when the given severity is not high enough (for this
    #   particular logger), log no message, and return true
    # @see http://is.gd/mLwYMl
    delegate_to_all_loggers :error

    # @return [true,false] whether or not the current severity level
    #   allows for the printing of error messages
    # @see http://is.gd/QY19JL
    delegate_to_first_logger :error?

    # Log a message with severity of warn.
    #
    # @param message_or_progname [#to_s] the message to log. In the block
    #   form, this is the progname to use in the log message.
    # @yield evaluates to the message to log. This is not evaluated unless the
    #   logger's level is sufficient to log the message. This allows you to
    #   create potentially expensive logging messages that are only called when
    #   the logger is configured to show them.
    # @return [nil,true] when the given severity is not high enough (for this
    #   particular logger), log no message, and return true
    # @see http://is.gd/PX9AIS
    delegate_to_all_loggers :warn

    # @return [true,false] whether or not the current severity level
    #   allows for the printing of warn messages
    # @see http://is.gd/Gdr4lD
    delegate_to_first_logger :warn?

    # Log a message with severity of fatal.
    #
    # @param message_or_progname [#to_s] the message to log. In the block
    #   form, this is the progname to use in the log message.
    # @yield evaluates to the message to log. This is not evaluated unless the
    #   logger's level is sufficient to log the message. This allows you to
    #   create potentially expensive logging messages that are only called when
    #   the logger is configured to show them.
    # @return [nil,true] when the given severity is not high enough (for this
    #   particular logger), log no message, and return true
    # @see http://is.gd/5ElFPK
    delegate_to_all_loggers :fatal

    # @return [true,false] whether or not the current severity level
    #   allows for the printing of fatal messages
    # @see http://is.gd/7PgwRl
    delegate_to_first_logger :fatal?

    # Log a message with severity of unknown.
    #
    # @param message_or_progname [#to_s] the message to log. In the block
    #   form, this is the progname to use in the log message.
    # @yield evaluates to the message to log. This is not evaluated unless the
    #   logger's level is sufficient to log the message. This allows you to
    #   create potentially expensive logging messages that are only called when
    #   the logger is configured to show them.
    # @return [nil,true] when the given severity is not high enough (for this
    #   particular logger), log no message, and return true
    # @see http://is.gd/Y4hqpf
    delegate_to_all_loggers :unknown

    # Close the logging devices.
    #
    # @see http://is.gd/b13cVn
    delegate_to_all_loggers :close

    private

    # @return [Integer] the default logger level
    # @api private
    def default_log_level
      Crosstest::Core::Util.to_logger_level(Crosstest.configuration.log_level)
    end

    # Construct a new standard out logger.
    #
    # @param stdout [IO] the IO object that represents stdout (or similar)
    # @param color [Symbol] color to use when outputing messages
    # @return [StdoutLogger] a new logger
    # @api private
    def stdout_logger(stdout, color)
      logger = Crosstest::Core::StdoutLogger.new(stdout)
      if Crosstest.tty?
        logger.formatter = proc do |_severity, _datetime, _progname, msg|
          Core::Color.colorize("#{msg}", color).concat("\n")
        end
      else
        logger.formatter = proc do |_severity, _datetime, _progname, msg|
          msg.concat("\n")
        end
      end
      logger
    end

    # Construct a new logdev logger.
    #
    # @param filepath_or_logdev [String,IO] a filepath String or IO object
    # @return [LogdevLogger] a new logger
    # @api private
    def logdev_logger(filepath_or_logdev)
      Crosstest::Core::LogdevLogger.new(resolve_logdev(filepath_or_logdev))
    end

    # Return an IO object from a filepath String or the IO object itself.
    #
    # @param filepath_or_logdev [String,IO] a filepath String or IO object
    # @return [IO] an IO object
    # @api private
    def resolve_logdev(filepath_or_logdev)
      if filepath_or_logdev.is_a? String
        FileUtils.mkdir_p(File.dirname(filepath_or_logdev))
        file = File.open(File.expand_path(filepath_or_logdev), 'ab')
        file.sync = true
        file
      else
        filepath_or_logdev
      end
    end
  end
end
