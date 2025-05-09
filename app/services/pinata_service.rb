require "httparty"
require "tempfile"

class PinataService
  def initialize
    @pinata_jwt = ENV["PINATA_JWT_KEY"]
    @ipfs_gateway = ENV["IPFS_GATEWAY"]

    raise "PINATA_JWT_KEY is not configured" unless @pinata_jwt
    raise "IPFS_GATEWAY is not configured" unless @ipfs_gateway
  end

  def upload_file(file_data)
    begin
      # Pour les objets ActionDispatch::Http::UploadedFile, on peut directement utiliser le tempfile
      if file_data.respond_to?(:tempfile)
        temp_path = file_data.tempfile.path

        response = HTTParty.post(
          "https://api.pinata.cloud/pinning/pinFileToIPFS",
          multipart: true,
          headers: {
            "Authorization" => "Bearer #{@pinata_jwt}"
          },
          body: {
            file: File.open(temp_path)
          }
        )
      else
        # Ancienne méthode, pour la compatibilité
        tempfile = create_tempfile(file_data)

        response = HTTParty.post(
          "https://api.pinata.cloud/pinning/pinFileToIPFS",
          multipart: true,
          headers: {
            "Authorization" => "Bearer #{@pinata_jwt}"
          },
          body: {
            file: File.open(tempfile.path)
          }
        )
      end

      if response.success?
        result = JSON.parse(response.body)
        { ipfs_hash: "ipfs://#{result['IpfsHash']}" }
      else
        Rails.logger.error("Pinata upload failed: #{response.body}")
        raise "Failed to upload to IPFS: #{response.code} #{response.message}"
      end
    rescue => e
      Rails.logger.error("Pinata error: #{e.message}")
      raise e
    end
  end

  def ipfs_to_http_url(ipfs_url)
    return ipfs_url unless ipfs_url.start_with?("ipfs://")

    hash = ipfs_url.gsub("ipfs://", "")
    "https://#{@ipfs_gateway}/ipfs/#{hash}"
  end

  def hash_data_to_ipfs(data)
    tempfile = create_data_tempfile(data)

    begin
      response = HTTParty.post(
        "https://api.pinata.cloud/pinning/pinFileToIPFS",
        multipart: true,
        headers: {
          "Authorization" => "Bearer #{@pinata_jwt}"
        },
        body: {
          file: File.open(tempfile.path)
        }
      )

      if response.success?
        result = JSON.parse(response.body)
        { ipfs_hash: "ipfs://#{result['IpfsHash']}" }
      else
        Rails.logger.error("Pinata upload failed: #{response.body}")
        raise "Failed to upload to IPFS: #{response.code} #{response.message}"
      end
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

  private

  def create_tempfile(file_data)
    tempfile = Tempfile.new([ "upload", ".tmp" ])
    tempfile.binmode

    if file_data.is_a?(Hash) && file_data[:tempfile]
      tempfile.write(file_data[:tempfile].read)
    elsif file_data.respond_to?(:read)
      tempfile.write(file_data.read)
    else
      raise "Unsupported file data format"
    end

    tempfile.rewind
    tempfile
  end

  def create_data_tempfile(data)
    tempfile = Tempfile.new([ "data", ".json" ])
    tempfile.binmode
    tempfile.write(data.to_json)
    tempfile.rewind
    tempfile
  end
end
