# Gemini's TTS returns headerless 16-bit mono PCM, which browsers can't decode without this header.
class WavAudio
  def self.from_pcm(pcm, sample_rate: 24_000)
    header = ["RIFF", 36 + pcm.bytesize, "WAVE", "fmt ", 16, 1, 1, sample_rate, sample_rate * 2, 2, 16, "data", pcm.bytesize]
    header.pack("a4Va4a4VvvVVvva4V") + pcm.b
  end
end
