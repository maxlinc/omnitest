require 'pacto'

contracts_path = options[:directory] || File.expand_path('contracts', Dir.pwd)
Pacto.configure do |config|
  config.contracts_path = contracts_path
  config.strict_matchers = options[:strict]
  config.generator_options = {:schema_version => :draft3, :defaults => true}
end

if options[:generate]
  Pacto.generate!
  logger.info 'Pacto generation mode enabled'
else
  Pacto.validate! if options[:validate]
  Dir["#{contracts_path}/*"].each do |host|
    host = File.basename host
    Pacto.load_all host, "https://#{host}", host
    Pacto.use host
  end
end

if options[:live]
  WebMock.reset!
  WebMock.allow_net_connect!
end
