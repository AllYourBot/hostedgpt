class ActiveStorage::Postgresql::File < ApplicationRecord
  attribute :oid, :integer, default: ->{ connection.raw_connection.lo_creat }

  delegate :lo_seek, :lo_tell, :lo_import, :lo_read, :lo_write, :lo_open,
    :lo_unlink, :lo_close, :lo_creat, to: "self.class.connection.raw_connection"

  before_create :write_or_import, if: :io
  before_create :verify_checksum, if: :checksum

  before_destroy :unlink

  scope :prefixed_with, -> prefix { where("key like ?", "#{prefix}%") }

  attr_accessor :checksum, :io
  attr_writer :digest

  def digest
    @digest ||= Digest::MD5.new
  end

  def write_or_import
    if io.respond_to?(:to_path)
      import(io.to_path)
    else
      open(::PG::INV_WRITE) do |file|
        while data = io.read(5.megabytes)
          write(data)
        end
      end
    end
  end

  def verify_checksum
    raise ActiveStorage::IntegrityError unless digest.base64digest == checksum
  end

  def self.open(key, &block)
    find_by!(key: key).open(&block)
  end

  def open(*args)
    transaction do
      begin
        @lo = lo_open(oid, *args)
        yield(self)
      ensure
        lo_close(@lo) if @lo
      end
    end
  end

  def write(content)
    lo_write(@lo, content)
    digest.update(content)
  end

  def read(bytes=size)
    lo_read(@lo, bytes)
  end

  def seek(position, whence=PG::SEEK_SET)
    lo_seek(@lo, position, whence)
  end

  def import(path)
    self.oid = lo_import(path)
    self.digest = Digest::MD5.file(path)
  end

  def tell
    lo_tell(@lo)
  end

  def size
    current_position = tell
    seek(0, PG::SEEK_END)
    tell.tap do
      seek(current_position)
    end
  end

  def unlink
    lo_unlink(oid)
  end
end
