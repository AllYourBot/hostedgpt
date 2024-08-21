import consumer from "channels/consumer"

consumer.subscriptions.create({ channel: "VoiceChannel", room: "voice" }, {
  connected() {
    console.log('VoiceChannel connected')
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    document.dispatchEvent(new CustomEvent('channel', { detail: data }));
  }
});
