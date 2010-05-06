require 'net/http'
require 'uri'
require 'cgi'
require 'digest/md5'
require 'rexml/document'

module Animoto
  class HttpError < StandardError
    attr_accessor :code, :body

    def initialize(code, body)
      @code = code.to_i
      @body = body
    end
  end

  class QuickstartUploadClient
    #URL = "https://animoto.com"
    URL = "http://localhost:3000"

    def initialize(affiliate_code, secret_key)
      @affiliate_code = affiliate_code 
      @secret_key = secret_key
    end

    def get_resource_links(asset_type, number_of_links, client_id = nil)
      links = []
      params = {:type => asset_type, :n => number_of_links}
      params.merge!(:client_id => client_id) unless client_id.nil?
      doc = REXML::Document.new(do_http_get("#{URL}/api/upload", params))
      doc.root.elements.each('url') do |element|
        links << element.text
      end
      links
    end

    protected

    def do_http_get(resource, params)
      params.merge!(:sig => generate_signature(params), :partner_id => @affiliate_code)
      resource += "?" + query_string(params)
      url = URI.parse(resource)
      response = Net::HTTP.start(url.host, url.port) do |http|
        http.get(resource)
      end

      raise Animoto::HttpError.new(response.code, response.body) unless response.code.to_i == 200
      response.body
    end

    def query_string(params) 
      s = []
      params.each_pair do |k, v|
        s << "#{k.to_s}=#{CGI::escape(params[k].to_s)}"
      end
      s.join('&')
    end

    def generate_signature(params)
      md5_params = Hash[params]
      md5_params[:secret_key] = @secret_key
      md5_params[:partner_id] = @affiliate_code
      # sort the query string parameters alphabetically by key, then join by key=value separated by &
      source = md5_params.keys.sort { |a, b| a.to_s <=> b.to_s }.map { |i| "#{i}=#{md5_params[i]}" }.join("&")
      Digest::MD5.hexdigest(source)
    end
  end
end
