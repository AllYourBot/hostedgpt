# frozen_string_literal: true

require "test_helper"

class ActiveStorage::PostgresqlControllerTest < ActionDispatch::IntegrationTest

  teardown do
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.select_values("SELECT oid from pg_largeobject_metadata").each do |oid|
        ActiveRecord::Base.connection.raw_connection.lo_unlink(oid)
      end
    end
  end

  test "showing blob inline" do
    blob = create_blob(filename: "hello.jpg", content_type: "image/jpeg")

    get blob.send(url_method)
    assert_response :ok
    assert_equal "inline; filename=\"hello.jpg\"; filename*=UTF-8''hello.jpg", response.headers["Content-Disposition"]
    assert_equal "image/jpeg", response.headers["Content-Type"]
    assert_equal "Hello world!", response.body
  end

  test "showing blob as attachment" do
    blob = create_blob
    get blob.send(url_method, disposition: :attachment)

    assert_response :ok
    assert_equal "attachment; filename=\"hello.txt\"; filename*=UTF-8''hello.txt", response.headers["Content-Disposition"]
    assert_equal "text/plain", response.headers["Content-Type"]
    assert_equal "Hello world!", response.body
  end

  test "showing blob range" do
    blob = create_blob
    get blob.send(url_method), headers: { "Range" => "bytes=5-9" }
    assert_response :partial_content
    assert_equal "attachment; filename=\"hello.txt\"; filename*=UTF-8''hello.txt", response.headers["Content-Disposition"]
    assert_equal "text/plain", response.headers["Content-Type"]
    assert_equal " worl", response.body
  end

  test "showing blob with empty range" do
    blob = create_blob
    get blob.send(url_method), headers: { "Range" => "bytes=100-" }
    assert_response 416
  end

  test "showing blob that does not exist" do
    blob = create_blob
    blob.delete

    get blob.send(url_method)
  end

  test "showing blob with invalid key" do
    get rails_postgresql_service_url(encoded_key: "Invalid key", filename: "hello.txt")
    assert_response :not_found
  end

  test "not allowing to set disposition from params" do
    blob = create_blob(filename: "hello.jpg", content_type: "image/jpeg")

    get blob.send(url_method), params: { disposition: :attachment }
    assert_response :ok
    assert_equal "inline; filename=\"hello.jpg\"; filename*=UTF-8''hello.jpg", response.headers["Content-Disposition"]
  end

  test "not allowing to set content-type from params" do
    blob = create_blob(filename: "hello.jpg", content_type: "image/jpeg")

    get blob.send(url_method), params: { content_type: 'text/html' }
    assert_response :ok
    assert_equal "image/jpeg", response.headers["Content-Type"]
  end

  test "directly uploading blob with integrity" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size, checksum: Digest::MD5.base64digest(data)

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }
    assert_response :no_content
    assert_equal data, blob.download
  end

  test "directly uploading blob without integrity" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size, checksum: Digest::MD5.base64digest("bad data")

    put blob.service_url_for_direct_upload, params: data
    assert_response :unprocessable_entity
    assert_not blob.service.exist?(blob.key)
  end

  test "directly uploading blob with mismatched content type" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size, checksum: Digest::MD5.base64digest(data)

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "application/octet-stream" }
    assert_response :unprocessable_entity
    assert_not blob.service.exist?(blob.key)
  end

  test "directly uploading blob with different but equivalent content type" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload(
      byte_size: data.size, checksum: Digest::MD5.base64digest(data), content_type: "application/x-gzip")

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "application/x-gzip" }
    assert_response :no_content
    assert_equal data, blob.download
  end

  test "directly uploading blob with mismatched content length" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size - 1, checksum: Digest::MD5.base64digest(data)

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }
    assert_response :unprocessable_entity
    assert_not blob.service.exist?(blob.key)
  end

  test "showing public blob & blob variant" do
    with_service(:local_public) do
      blob = create_blob(content_type: "image/jpeg")

      get blob.send(url_method)
      assert_response :ok
      assert_equal "image/jpeg", response.headers["Content-Type"]
      assert_equal "Hello world!", response.body
    end
  end

  test "showing public blob variant" do
    with_service(:local_public) do
      blob = create_file_blob.variant(resize_to_limit: [100, 100]).processed
      get blob.send(url_method)
      assert_response :ok
      assert_equal "image/jpeg", response.headers["Content-Type"]
    end
  end

  test "directly uploading blob with invalid token" do
    put update_rails_postgresql_service_url(encoded_token: "invalid"),
      params: "Something else entirely!", headers: { "Content-Type" => "text/plain" }
    assert_response :not_found
  end

  private

  def url_method
    ActiveStorage::Blob.method_defined?(:url) ? :url : :service_url
  end

  def with_service(service_name)
    previous_service = ActiveStorage::Blob.service

    skip unless ActiveStorage::Blob.respond_to?(:services)

    ActiveStorage::Blob.service = service_name ? ActiveStorage::Blob.services.fetch(service_name) : nil

    yield
  ensure
    ActiveStorage::Blob.service = previous_service
  end

  def create_blob(data: "Hello world!", filename: "hello.txt", content_type: "text/plain", identify: true)
    ActiveStorage::Blob.create_and_upload! io: StringIO.new(data), filename: filename, content_type: content_type
  end

  def create_blob_before_direct_upload(filename: "hello.txt", byte_size:, checksum:, content_type: "text/plain")
    ActiveStorage::Blob.create_before_direct_upload! filename: filename, byte_size: byte_size, checksum: checksum, content_type: content_type
  end

  def create_file_blob(key: nil, filename: "racecar.jpg", content_type: "image/jpeg", metadata: nil, service_name: nil, record: nil)
    ActiveStorage::Blob.create_and_upload! io: file_fixture(filename).open, filename: filename, content_type: content_type, metadata: metadata, service_name: service_name, record: record
  end
end
