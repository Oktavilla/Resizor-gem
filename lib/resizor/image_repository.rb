require "forwardable"
require "json"

module Resizor
  class ImageRepository
    extend Forwardable

    def_delegators :@config, :api_version, :access_key, :secret_key, :host

    def initialize config
      @config = config
    end

    def all params = {}
      params[:timestamp] = timestamp
      params[:signature] = signature params

      http_response = HTTP.get url("images.json"), params
      code, body = *http_response

      if code == 200
        ImageCollection.new JSON.parse(body)
      end
    end

    def find id
      params = { timestamp: timestamp }
      params[:signature] = signature params.merge(id: id)

      http_response = HTTP.get url("images/#{id}.json"), params
      code, body = *http_response

      if code == 200
        Image.new JSON.parse(body)["image"]
      else
        nil
      end
    end

    def delete id
      params = { timestamp: timestamp }
      params[:signature] = signature params.merge(id: id)

      http_response = HTTP.delete url("images/#{id}.json"), params
      code, body = *http_response

      if code == 204
        SuccessResponse.new
      else
        ErrorResponse.new JSON.parse(body)["errors"]
      end
    end

    def store file, id = nil
      params = { timestamp: timestamp }
      params[:id] = id if id

      http_response = HTTP.post_multipart url("images.json"), params.merge({
        signature: signature(params),
        file: file
      })

      status, body = *http_response
      body = JSON.parse body

      if status == 201
        ImageResponse.new body["image"]
      else
        ErrorResponse.new body["errors"]
      end
    end

    def timestamp
      Time.now.utc.to_i
    end

    def signature params, signature_klass = Signature
      signature_klass.generate secret_key, params
    end

    private

    def url endpoint
      File.join host, client_path, endpoint
    end

    def client_path
      "/#{api_version}/#{access_key}"
    end
  end

  class SuccessResponse
    def success?
      true
    end
  end

  class ImageResponse < SuccessResponse
    attr_reader :image

    def initialize attributes
      @image = Image.new attributes
    end
  end

  class ErrorResponse
    attr_reader :errors

    def initialize errors
      @errors = errors
    end

    def success?
      false
    end
  end
end
