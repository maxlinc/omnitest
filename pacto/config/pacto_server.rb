require 'pacto'

config[:port] = port
contracts_path = options[:directory] || File.expand_path('contracts', Dir.pwd)
Pacto.configure do |config|
  config.contracts_path = contracts_path
  config.strict_matchers = options[:strict]
  config.generator_options = {
    :schema_version => :draft3,
    :token_map => MultiJson.load(File.read '.tokens.json')
  }
end

if options[:generate]
  Pacto.generate!
  logger.info 'Pacto generation mode enabled'
end

if options[:validate]
  Pacto.validate! if options[:validate]
  Dir["#{contracts_path}/*"].each do |host_dir|
    host = File.basename host_dir
    Pacto.load_contracts(host_dir, "https://#{host}")
  end
end

if options[:live]
#  WebMock.reset!
  WebMock.allow_net_connect!
end
