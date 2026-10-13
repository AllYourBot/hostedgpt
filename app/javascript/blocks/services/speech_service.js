import Service from "../service.js"

export default class extends Service {
  logLevel_info
  attrReader_apiTimeoutHandler

  async audioFromOpenAI(text) {
    const ttsAbortController = new AbortController()
    let ttsResponse

    $.apiTimeoutHandler = runAfter(3, () => ttsAbortController.abort())

    try {
      ttsResponse = await fetch("/speech", {
        signal: ttsAbortController.signal,
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ text: text })
      })
    } catch (error) {
      throw new Error("Service is currently unavailable")
    } finally {
      $.apiTimeoutHandler.end()
    }

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

  cancel() {
    $.apiTimeoutHandler?.run()
  }

  static splitIntoThoughts(text) {
    if (!text) return []
    text = text.replace(". . .", "...")
    const thoughts = text.split(/(?<=[^ ][\.:!\?;…] |[\n，。．！？；：])/)
    return thoughts.reject(t => t.strip().empty()).map(t => t.replace(/''/g, "'"))
  }
}
