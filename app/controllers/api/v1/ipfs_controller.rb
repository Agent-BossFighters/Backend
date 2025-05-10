module Api
  module V1
    class IpfsController < BaseController
      before_action :authenticate_user!

      # POST /api/v1/ipfs/upload_file
      def upload_file
        unless params[:file].present?
          return render json: { error: "No file provided" }, status: :bad_request
        end

        begin
          result = pinata_service.upload_file(params[:file])
          render json: { ipfs_url: result[:ipfs_hash], http_url: pinata_service.ipfs_to_http_url(result[:ipfs_hash]) }
        rescue => e
          Rails.logger.error("IPFS upload error: #{e.message}")
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      # POST /api/v1/ipfs/hash_data
      def hash_data
        unless params[:data].present?
          return render json: { error: "No data provided" }, status: :bad_request
        end

        begin
          result = pinata_service.hash_data_to_ipfs(params[:data])
          render json: { ipfs_hash: result[:ipfs_hash], http_url: pinata_service.ipfs_to_http_url(result[:ipfs_hash]) }
        rescue => e
          Rails.logger.error("IPFS data hash error: #{e.message}")
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      # GET /api/v1/ipfs/gateway_url
      def gateway_url
        render json: { gateway_url: ENV["IPFS_GATEWAY"] }
      end

      private

      def pinata_service
        @pinata_service ||= PinataService.new
      end
    end
  end
end
