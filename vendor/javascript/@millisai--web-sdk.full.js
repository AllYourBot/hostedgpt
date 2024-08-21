var S=Object.defineProperty;var w=Object.getOwnPropertySymbols;var E=Object.prototype.hasOwnProperty,_=Object.prototype.propertyIsEnumerable;var A=(s,n,t)=>n in s?S(s,n,{enumerable:!0,configurable:!0,writable:!0,value:t}):s[n]=t,m=(s,n)=>{for(var t in n||(n={}))E.call(n,t)&&A(s,t,n[t]);if(w)for(var t of w(n))_.call(n,t)&&A(s,t,n[t]);return s};var k=(s,n)=>{for(var t in n)S(s,t,{get:n[t],enumerable:!0})};var l=(s,n,t)=>new Promise((e,i)=>{var a=r=>{try{o(t.next(r))}catch(c){i(c)}},u=r=>{try{o(t.throw(r))}catch(c){i(c)}},o=r=>r.done?e(r.value):Promise.resolve(r.value).then(a,u);o((t=t.apply(s,n)).next())});var v={};k(v,{createClient:()=>M,createMicrophoneAudioTrack:()=>y});

// import{EventEmitter as U} from"eventemitter3";
// import R from "eventemitter3";
var C=`
class captureAndPlaybackProcessor extends AudioWorkletProcessor {
    audioData = [];
    index = 0;
    pause = false;

    constructor() {
      super();
      //set listener to receive audio data, data is float32 array.
      this.port.onmessage = (e) => {
        if (e.data === "clear") {
          // Clear all buffer.
          this.audioData = [];
          this.index = 0;
        } else if (e.data === "pause") {
          this.pause = true;
        } else if (e.data === "unpause") {
          this.pause = false;
        } else if (e.data.length > 0) {
          this.audioData.push(this.convertUint8ToFloat32(e.data));
        }
      };
    }

    convertUint8ToFloat32(array) {
      const targetArray = new Float32Array(array.byteLength / 2);

      // A DataView is used to read our 16-bit little-endian samples out of the Uint8Array buffer
      const sourceDataView = new DataView(array.buffer);

      // Loop through, get values, and divide by 32,768
      for (let i = 0; i < targetArray.length; i++) {
        targetArray[i] = sourceDataView.getInt16(i * 2, true) / Math.pow(2, 16 - 1);
      }
      return targetArray;
    }

    convertFloat32ToUint8(array) {
      const buffer = new ArrayBuffer(array.length * 2);
      const view = new DataView(buffer);

      for (let i = 0; i < array.length; i++) {
        const value = array[i] * 32768;
        view.setInt16(i * 2, value, true); // true for little-endian
      }

      return new Uint8Array(buffer);
    }

    process(inputs, outputs, parameters) {
      // Capture
      const input = inputs[0];
      const inputChannel1 = input[0];
      const inputChannel2 = input[1];
      this.port.postMessage(this.convertFloat32ToUint8(inputChannel1));

      // Playback
      const output = outputs[0];
      const outputChannel1 = output[0];
      const outputChannel2 = output[1];
      // start playback.
      for (let i = 0; i < outputChannel1.length; ++i) {
        if (this.audioData.length > 0 && !this.pause) {
          outputChannel1[i] = this.audioData[0][this.index];
          outputChannel2[i] = this.audioData[0][this.index];
          this.index++;
          if (this.index == this.audioData[0].length) {
            this.audioData.shift();
            this.index = 0;
            if (this.audioData.length == 0) {
              this.port.postMessage("playback_finished");
            }
          }
        } else {
          outputChannel1[i] = 0;
          outputChannel2[i] = 0;
        }
      }

      return true;
    }
  }

  registerProcessor(
    "capture-and-playback-processor",
    captureAndPlaybackProcessor,
  );
`;var I=16e3,p=class extends R{constructor(t){super();this.audioContext=null;this.stream=null;this.audioNode=null;this.captureNode=null;this.audioData=[];this.audioDataIndex=0;this.pause=!1;this.needResample=!1;this.resamplerCreated=!1;this.config=t}print(t){this.config.debug&&console.log("[millis audio service]",t)}start(){return l(this,null,function*(){let t=I;this.isFirefox()?(this.audioContext=new AudioContext({latencyHint:"interactive"}),this.needResample=!0):(this.needResample=!1,this.audioContext=new AudioContext({latencyHint:"interactive",sampleRate:t})),this.print("starting audio service, firefox: "+this.isFirefox()+", need resample: "+this.needResample);try{this.print("requesting microphone permission"),this.stream=yield y(t),this.print("microphone permission granted")}catch(e){throw this.print("microphone permission denied"),new Error("User didn't give microphone permission")}if(this.print("starting audio capture and playback processor, worklet: "+this.isAudioWorkletSupported()),this.isAudioWorkletSupported()){this.print("Starting audio worklet"),this.audioContext.resume();let e=new Blob([C],{type:"application/javascript"}),i=URL.createObjectURL(e);yield this.audioContext.audioWorklet.addModule(i),this.print("Audio worklet loaded"),this.audioNode=new AudioWorkletNode(this.audioContext,"capture-and-playback-processor"),this.print("Audio worklet setup"),this.audioNode.port.onmessage=r=>{r.data instanceof Uint8Array?this.emit("data",r.data):r.data==="playback_finished"&&this.onPlaybackFinished()};let a=this.audioContext.createMediaStreamSource(this.stream);a.connect(this.audioNode),this.audioNode.connect(this.audioContext.destination);let u=this.audioContext.createAnalyser();a.connect(u),this.emit("useraudioready",{analyser:u,stream:this.stream});let o=this.audioContext.createAnalyser();this.audioNode.connect(o),o.connect(this.audioContext.destination),this.emit("analyzer",o)}else{this.print("Starting audio capture node");let e=this.audioContext.createMediaStreamSource(this.stream);this.captureNode=this.audioContext.createScriptProcessor(2048,1,1),this.captureNode.onaudioprocess=a=>{if(this.captureNode&&this.audioContext){if(this.needResample&&!this.resamplerCreated){let d=N.SRC_SINC_FASTEST,b=1;this.resamplerCreated=!0,x(b,this.audioContext.sampleRate,t,{converterType:d}).then(f=>{this.inputResampler=f}),x(b,t,this.audioContext.sampleRate,{converterType:d}).then(f=>{this.outputResampler=f})}var u=a.inputBuffer.getChannelData(0),o=null;this.inputResampler!=null?o=this.inputResampler.full(u):o=u;let r=P(o);this.emit("data",r);let g=a.outputBuffer.getChannelData(0);for(let d=0;d<g.length;++d)this.audioData.length>0&&!this.pause?(g[d]=this.audioData[0][this.audioDataIndex++],this.audioDataIndex===this.audioData[0].length&&(this.audioData.shift(),this.audioDataIndex=0,this.audioData.length==0&&this.onPlaybackFinished())):g[d]=0}},e.connect(this.captureNode),this.captureNode.connect(this.audioContext.destination),this.print("Audio capture node setup");let i=this.audioContext.createAnalyser();this.captureNode.connect(i),i.connect(this.audioContext.destination),this.emit("analyzer",i)}})}stop(){return l(this,null,function*(){var t,e,i,a;(t=this.audioContext)==null||t.suspend(),(e=this.audioContext)==null||e.close(),this.isAudioWorkletSupported()?((i=this.audioNode)==null||i.disconnect(),this.audioNode=null):this.captureNode&&(this.captureNode.disconnect(),this.captureNode.onaudioprocess=null,this.captureNode=null,this.audioData=[],this.audioDataIndex=0),(a=this.stream)==null||a.getTracks().forEach(u=>u.stop()),this.audioContext=null,this.stream=null})}play(t){var i;if(this.isAudioWorkletSupported())(i=this.audioNode)==null||i.port.postMessage(t);else{let a=T(t);var e=null;this.outputResampler!=null?e=this.outputResampler.full(a):e=a,this.audioData.push(e)}}setpause(t){var e;this.isAudioWorkletSupported()?(e=this.audioNode)==null||e.port.postMessage(t?"pause":"unpause"):this.pause=t}reset(){var t;this.isAudioWorkletSupported()?(t=this.audioNode)==null||t.port.postMessage("clear"):(this.audioData=[],this.audioDataIndex=0)}onPlaybackFinished(){this.emit("playback_finished")}isAudioWorkletSupported(){return/Chrome/.test(navigator.userAgent)&&/Google Inc/.test(navigator.vendor)}isFirefox(){return/Firefox/.test(navigator.userAgent)}};function T(s){let n=new Float32Array(s.byteLength/2),t=new DataView(s.buffer);for(let e=0;e<n.length;e++)n[e]=t.getInt16(e*2,!0)/Math.pow(2,15);return n}function P(s){let n=new ArrayBuffer(s.length*2),t=new DataView(n);for(let e=0;e<s.length;e++){let i=s[e]*32768;t.setInt16(e*2,i,!0)}return new Uint8Array(n)}var D=(i=>(i.IDLE="idle",i.PREPARE_ANSWER="prepare_answer",i.ANSWER="answer",i.PAUSE="pause",i))(D||{});var F="wss://api-west.millis.ai:8080/millis";var h=class extends U{constructor(t){super();this.startAnswering=0;this.count=0;this.agentState="idle";this.state=0;this.ws=null,this.audioService=null,this.latencyEstimator=null;let e={isTest:!1,debug:!1};this.config=m(m({},e),t),this.print("init")}reset(){this.state=0,this.agentState="idle",this.count=0,this.startAnswering=0}print(t){this.config.debug&&console.log("[millis]",t)}connect(t,e){this.print("starting websocket"),this.ws=new WebSocket(this.config.endPoint||F),this.ws.binaryType="arraybuffer";let i=typeof t=="string"?{agent_id:t}:{agent_config:t};this.ws.onopen=()=>{this.print("websocket connected, sending initiate message"),this.emit("onopen"),this.send(JSON.stringify({method:"initiate",data:{agent:i,public_key:this.config.publicKey,metadata:e}}))},this.ws.onmessage=a=>{var u;if(a.data instanceof ArrayBuffer){this.print("audio data received"),this.startAnswering>0&&(this.emit("onlatency",Date.now()-this.startAnswering),this.print("latency: "+(Date.now()-this.startAnswering)),this.startAnswering=0,this.switchState("answer"));let o=new Uint8Array(a.data);(u=this.audioService)==null||u.play(o),this.emit("onaudio",o)}else{let o=JSON.parse(a.data);if(o.method==="onready"){this.onready();return}this.handle(o)||this.emit(o.method,o.data,o.payload),this.print(`received ${o.method}`)}},this.ws.onclose=a=>{this.stop(),this.emit("onclose",a),this.print("websocket disconnected"),this.switchState("idle")},this.ws.onerror=a=>{this.stop(),this.emit("onerror",a),this.print("websocket error: "+a)}}send(t){var e;((e=this.ws)==null?void 0:e.readyState)===1&&this.ws.send(t)}handle(t){var e,i,a;switch(t.method){case"start_answering":return this.startAnswering=Date.now(),this.switchState("prepare_answer"),!0;case"clear":return(e=this.audioService)==null||e.reset(),this.switchState("idle"),!0;case"pause":return(i=this.audioService)==null||i.setpause(!0),this.switchState("pause"),!0;case"unpause":return(a=this.audioService)==null||a.setpause(!1),this.switchState("answer"),!0;case"pong":return this.print("Ping rtt "+(Date.now()-Number(t.data))),!0}return!1}onready(){this.switchState("idle"),this.switchConnectionState(2)}start(t,e){return l(this,null,function*(){this.print("starting conversation"),this.audioService=new p(this.config),this.audioService.on("data",i=>{this.print("sending audio data"),this.send(i),this.count++,this.count%1e3==0&&(this.print("sending ping"),this.send(JSON.stringify({method:"ping",data:Date.now().toString()}))),this.switchConnectionState(3)}),this.audioService.on("analyzer",i=>{this.emit("analyzer",i)}),this.audioService.on("useraudioready",i=>{this.print("user audio ready"),this.emit("useraudioready",i)}),this.audioService.on("playback_finished",()=>{this.agentState==="answer"&&this.switchState("idle")}),this.print("starting audio service"),yield this.audioService.start(),this.print("audio service started"),this.connect(t,e)})}stop(){return l(this,null,function*(){var t;this.audioService&&(this.print("stopping audio service"),this.audioService.stop(),this.audioService=null,this.print("audio service stopped")),(t=this.ws)==null||t.close(),this.reset()})}switchState(t){this.agentState=t,this.emit("onagentstate",t)}switchConnectionState(t){this.state===0?this.state=t:(this.state===3&&t===2||this.state===2&&t===3)&&(this.state=1,this.emit("onready"))}};function M(s){return new h(s)}function y(s){return l(this,null,function*(){return navigator.mediaDevices.getUserMedia({audio:{sampleRate:s,echoCancellation:!0,noiseSuppression:!0,channelCount:1,autoGainControl:!0,latency:0}})})}var at=v;export{D as AgentState,at as default};
