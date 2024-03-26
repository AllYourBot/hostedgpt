# frozen_string_literal: true

# Serves files stored with the disk service in the same way that the cloud services do.
# This means using expiring, signed URLs that are meant for immediate access, not permanent linking.

# TODO: I don't know what this next statement means. There is no BlobsController:
# Always go through the BlobsController, or your own authenticated controller, rather than directly
# to the service url.

class ActiveStorage::PostgresqlController < ActiveStorage::BaseController
  skip_forgery_protection

  def show
    if key = decode_verified_key
      response.headers["Content-Type"] = key[:content_type] || DEFAULT_SEND_FILE_TYPE
      response.headers["Content-Disposition"] = key[:disposition] || DEFAULT_SEND_FILE_DISPOSITION
      size = ActiveStorage::Postgresql::File.open(key[:key], &:size)

      ranges = Rack::Utils.get_byte_ranges(request.get_header('HTTP_RANGE'), size)

      if ranges.nil? || ranges.length > 1
        # No ranges, or multiple ranges (which we don't support):
        # TODO: Support multiple byte-ranges
        self.status = :ok
        range = 0..size-1

      elsif ranges.empty?
        head 416, content_range: "bytes */#{size}"
        return
      else
        range = ranges[0]
        self.status = :partial_content
        response.headers["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{size}"
      end
      self.response_body = postgresql_service.download_chunk(key[:key], range)
    else
      head :not_found
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def update
    if token = decode_verified_token
      if acceptable_content?(token)
        postgresql_service.upload token[:key], request.body, checksum: token[:checksum]
        head :no_content
      else
        head :unprocessable_entity
      end
    else
      head :not_found
    end
  rescue ActiveStorage::IntegrityError
    head :unprocessable_entity
  end

  private

  def postgresql_service
    ActiveStorage::Blob.service
  end

  def decode_verified_key
    ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)&.symbolize_keys
  end

  def decode_verified_token
    ActiveStorage.verifier.verified(params[:encoded_token], purpose: :blob_token)&.symbolize_keys
  end

  def acceptable_content?(token)
    token[:content_type] == request.content_mime_type && token[:content_length] == request.content_length
  end
end
