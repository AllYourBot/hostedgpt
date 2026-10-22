require "test_helper"

class WavAudioTest < ActiveSupport::TestCase
  test "from_pcm prepends a 44-byte header describing 16-bit mono PCM at 24kHz" do
    pcm = "\x01\x02\x03\x04".b
    wav = WavAudio.from_pcm(pcm)

    assert_equal 44 + pcm.bytesize, wav.bytesize
    riff, riff_size, wave, fmt, fmt_size, format, channels, rate, byte_rate, block_align, bits, data, data_size =
      wav.unpack("a4Va4a4VvvVVvva4V")
    assert_equal ["RIFF", 40, "WAVE", "fmt ", 16, 1, 1, 24_000, 48_000, 2, 16, "data", 4],
      [riff, riff_size, wave, fmt, fmt_size, format, channels, rate, byte_rate, block_align, bits, data, data_size]
    assert_equal pcm, wav.byteslice(44..)
  end
end
