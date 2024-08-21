import { Controller } from "@hotwired/stimulus"
import Millis from "@millisai/web-sdk"


export default class extends Controller {

  connect() {
    console.log('connected')

    document.addEventListener('channel', (event) => {
      if (event.detail.command == 'pause') {
        console.log('pausing browser listening...')
        this.msClient.stop()
      }
      console.log(`received`, event.detail.command)
    })

    this.msClient = Millis.createClient({
      publicKey: 'P_7D-p-AKPX8pvb-HDgMe-_sPFo_gCdS-EydUEdlfUw',
      endPoint: 'wss://api-west.millis.ai:8080/millis'
    })

    this.msClient.on("onopen", () => {
      console.log('onopen')
    })

    this.msClient.on("onready", () => {
      console.log('onready')
    })

    this.msClient.on("onaudio", (audio) => {
      //console.log('onaudio', audio)
    })

    this.msClient.on("analyzer", (analyzer) => {
      console.log('analyzer', analyzer)
    })

    this.msClient.on("onclose", (event) => {
      console.log('onclose', event)
    })

    this.msClient.on("onerror", (error) => {
      console.log('onerror', error)
    });

    this.msClient.on("onsessionended", (data) => {
      console.log('onsessionended', data)
    });

    this.msClient.on("onresponsetext", (data) => {
      console.log('onresponsetext', data)
    });
  }

  start() {
    //this.msClient.start('-O3dXlg5K4qTTBLpix68')
    //this.msClient.start('-O3dXlg5K4qTTBLpix68', { flow: { response_delay: 4000 } })

    this.msClient.start({
      prompt: `Your name is Samantha. Answer my questions in as few words as possible. Be concise. NEVER write a bullet list or a number list — NO LISTS. Don't give me examples unless I ask for them. Don't repeat yourself or rephrase my statements. Remember, you are a teacher talking to an advanced student who wants short back-and-forths. Even single word responses are sufficient, if that answers my question accurately.

Also, keep in mind that I'm talking to you over voice. Everything you say will be spoken aloud using advanced text-to-speech so never make lists or use emojis.

Be conversational. When I ask a question, answer it succinctly, but if it would be appropriate in a conversation to ask a clarifying question to keep the conversation flowing, then also do that. But don't try to keep the conversation flowing if it seems like I am done with the conversation.

I will sometimes attach photos of my screen so you can see what I am seeing. Any reference to "do you see this" or "on my screen" or "here it is" or similar statements are probably referring to the most recent screenshot that was attached. When I ask, "take a look at my inbox how do you think I did on my inbox today" and include an attached image, a bad answer is, "I cannot view images directly." A good answer is to review the attached image while responding to the question.

When I ask if you can hear me, remember that my text was spoken and transcribed. Please reply to me as if you are speaking rather than typing back.

Do not reply with sample code unless I ask for it.

Remember, NEVER use bullets. NEVER make lists in your response. NEVER write long, complex, compound sentences. ALWAYS use simple words and short sentences. Write as you would speak.`,
      voice: {
        provider: "openai", // Voice provider
        voice_id: "nova", // "21m00Tcm4TlvDq8ikWAM" // Replace 'voice-id' with the ID of the desired voice
      },
      language: "en", // optional - use language code such as en, es
      tools: [
        {
          name: "start_voice_control",
          description: "If the user says 'start voice control' or 'voice control' or 'follow my directions' or 'follow instructions' in a manner that seems like they're giving you a command, then execute start_voice_control.",
          webhook: "http://local.the.bot/serenade?key=4706",
          header: {
            "Content-Type": "application/json",
          },
          params: []
        },
        window.tools
      ].flatten(),
      llm: "gpt-4o", // optional - choose llm model. Ex: gpt-4o, llama-3-70b
      first_message: "Hey Keith",
      session_timeout: {
        max_idle: 86400,
        message: "I'm going to leave now",
      },
      flow: {
        response_delay: 500
      }
    })

    // this.msClient.start({
    //   prompt: "You're a helpful assistant.", // Example prompt
    //   voice: {
    //     provider: "elevenlabs", // Voice provider
    //     voice_id: "21m00Tcm4TlvDq8ikWAM" // Replace 'voice-id' with the ID of the desired voice
    //   },
    //   language: "en", // optional - use language code such as en, es
    //   tools: [], // Replace with actual function calls you need
    //   llm: "gpt-4o", // optional - choose llm model. Ex: gpt-4o, llama-3-70b
    // });
  }

  disconnect() {
  }
}
