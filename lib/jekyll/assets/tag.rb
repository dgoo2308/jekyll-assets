# Frozen-string-literal: true
# Copyright: 2012 - 2017 - MIT License
# Encoding: utf-8

require "fastimage"
require_relative "html"
require "liquid/tag/parser"
require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/hash/deep_merge"
require_relative "default"
require_relative "proxy"
require "nokogiri"

module Jekyll
  module Assets
    class Tag < Liquid::Tag
      class << self
        public :new
      end

      # --
      attr_reader :name
      attr_reader :tokens
      attr_reader :args
      attr_reader :tag

      # --
      def initialize(tag, args, tokens)
        @tag = tag.to_sym
        @args = Liquid::Tag::Parser.new(args)
        @name = @args[:argv1]
        @tokens = tokens

        super
      end

      # --
      # @return [String]
      # Render the tag, run the proxies, set the defaults.
      # @note Defaults are ran twice just incase the content type
      #   changes, at that point there might be something that
      #   has to change in the new content.
      # --
      def render(context)
        env = context.registers[:site].sprockets
        arg = env.parse_liquid(@args)

        o_asset = env.find_asset!(@name)
        Default.set(arg, env: env, asset: o_asset)
        asset = Proxy.proxy(o_asset, args: arg, env: env)
        Default.set(arg, env: env, asset: asset)
        env.manifest.compile(asset.logical_path)

        return env.prefix_url(asset.digest_path) if arg[:path]
        return asset.data_uri if args[:"data-uri"] || arg[:data_uri]
        return asset.to_s if arg[:source]
        type = asset.content_type

        HTML.build({
          args: arg,
          asset: asset,
          type: type,
          env: env,
        })
      end
    end
  end
end

# --

Liquid::Template.register_tag "asset", Jekyll::Assets::Tag
