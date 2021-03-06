require 'babel/transpiler'
require 'sprockets'
require 'sprockets/es6/version'
require 'ostruct'

module Sprockets
  class ES6

    class << self

      attr_accessor :configuration

      def configuration_hash
        configuration.to_h.reduce({}) do |hash, (key, val)|
          hash[key.to_s] = val
          hash
        end
      end

      def instance
        @instance ||= new
      end

      def configure
        self.configuration ||= OpenStruct.new
        yield configuration
      end

      def reset_configuration
        self.configuration = OpenStruct.new
      end

      def call(input)
        instance.call(input)
      end

      def cache_key
        instance.cache_key
      end

    end

    attr_reader :cache_key

    def configuration_hash
      self.class.configuration_hash
    end

    def initialize(options = {})
      @options = configuration_hash.merge(options).freeze

      @cache_key = [
        self.class.name,
        Babel::Transpiler.version,
        Babel::Transpiler.source_version,
        VERSION,
        @options
      ].freeze
    end

    def call(input)
      data = input[:data]
      result = input[:cache].fetch(@cache_key + [input[:filename]] + [data]) do
        transform(data, transformation_options(input))
      end
      result['code']
    end

    def transform(data, opts)
      Babel::Transpiler.transform(data, opts)
    end

    def transformation_options(input)
      opts = {
        'sourceRoot' => input[:load_path],
        'moduleRoot' => nil,
        'filename' => input[:filename],
        'filenameRelative' => input[:environment].split_subpath(input[:load_path], input[:filename])
      }.merge(@options)

      if opts['moduleIds'] && opts['moduleRoot']
        opts['moduleId'] ||= File.join(opts['moduleRoot'], input[:name])
      elsif opts['moduleIds']
        opts['moduleId'] ||= input[:name]
      end

      opts
    end

  end

  append_path Babel::Transpiler.source_path

  register_engine '.es6', ES6, mime_type: 'application/javascript', silence_deprecation: true
end
