import Service from "../service.js"

export default class extends Service {
  logLevel_info

  static async audioFromOpenAI(text) {
    const ttsAbortController = new AbortController()
    const openAITTSUrl = "https://api.openai.com/v1/audio/speech"
    let ttsResponse

    const apiTimeoutHandler = runAfter(3, () => ttsAbortController.abort())

    try {
      ttsResponse = await fetch(openAITTSUrl, {
        signal: ttsAbortController.signal,
        method: "POST",
        headers: {
          "Authorization": `Bearer ${window.openAIKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: "tts-1",
          input: text,
          voice: "nova",
          response_format: "wav",
          speed: 1.0
        })
      })
    } catch (error) {
      throw new Error("Service is currently unavailable")
    }

    apiTimeoutHandler.end()

    if (!ttsResponse.ok) {
      let errorMessage = "Failed to generate audio";
      try {
        const { message } = await ttsResponse.json()
        errorMessage = message;
      } catch (error) {}
      throw new Error(errorMessage);
    }

    const blob = await ttsResponse.blob()
    var audioUrl = window.URL.createObjectURL(blob)

    return audioUrl
  }

  static splitIntoThoughts(text) {
    if (!text) return []
    text = text.replace(". . .", "...")
    const thoughts = text.split(/(?<=[^ ][\.,:!\?;…] |[\n，。．！？；：])/)
    return thoughts.reject(t => t.strip().empty())
  }
}