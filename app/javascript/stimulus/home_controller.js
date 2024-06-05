import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('connected home')

    this.bodyElement = document.body
    this.wrapElement = document.getElementById('wrap')

    this.length = 45
    this.radius = 8.5
    this.animationComplete = false

    this.rotatevalue = 0.035
    this.acceleration = 0
    this.animatestep = 0
    this.toend = false

    this.pi2 = Math.PI * 2

    this.group = new THREE.Group()

    this.camera = new THREE.PerspectiveCamera(65, 1, 1, 10000)
    this.camera.position.z = 150

    this.scene = new THREE.Scene()
    this.scene.add(this.group)

    var path = new CustomSinCurve(1, this.length, this.radius, this.pi2)
    var geometry = new THREE.TubeGeometry(path, 200, 1.1, 2, true)
    var material = new THREE.MeshBasicMaterial({color: 0xffffff})

    this.mesh = new THREE.Mesh(geometry, material)
    this.group.add(this.mesh)

    this.ringcover = new THREE.Mesh(new THREE.PlaneGeometry(60, 20, 1), new THREE.MeshBasicMaterial({color: 0xd1684e, opacity: 0, transparent: true}))
    this.ringcover.position.x = this.length + 1
    this.ringcover.rotation.y = Math.PI / 2
    this.group.add(this.ringcover)

    this.ring = new THREE.Mesh(new THREE.RingGeometry(5, 5.55, 32), new THREE.MeshBasicMaterial({color: 0xffffff, opacity: 0, transparent: true}))
    this.ring.position.x = this.length + 1.1
    this.ring.rotation.y = Math.PI / 2
    this.group.add(this.ring)

    this.fakeShadow()

    this.renderer = new THREE.WebGLRenderer({
      antialias: true
    })
    this.renderer.setPixelRatio(window.devicePixelRatio)
    this.setSize()
    this.renderer.setClearColor('#d1684e')

    this.wrapElement.appendChild(this.renderer.domElement)
    console.log(`canvas dom`, this.renderer.domElement)

    this.bodyElement.addEventListener('mousedown', this.start.bind(this), false)
    this.bodyElement.addEventListener('touchstart', this.start.bind(this), false)
    this.bodyElement.addEventListener('mouseup', this.back.bind(this), false)
    this.bodyElement.addEventListener('touchend', this.back.bind(this), false)
    window.addEventListener('resize', this.setSize.bind(this))

    this.animate()
  }

  setSize() {
    console.log('resized')
    let size = this.element.getBoundingClientRect().height
    this.renderer.setSize(size, size)
  }

  disconnect() {
    this.bodyElement.removeEventListener('mousedown', this.start.bind(this), false)
    this.bodyElement.removeEventListener('touchstart', this.start.bind(this), false)
    this.bodyElement.removeEventListener('mouseup', this.back.bind(this), false)
    this.bodyElement.removeEventListener('touchend', this.back.bind(this), false)
    window.removeEventListener('resize', this.back.bind(this))
  }

  async start() {
    console.log('starting')
    this.toend = true
    return
  }

  fakeShadow() {
    var plain, i
    for (i = 0; i < 10; i++) {
      plain = new THREE.Mesh(new THREE.PlaneGeometry(this.length * 2 + 1, this.radius * 3, 1), new THREE.MeshBasicMaterial({color: 0xd1684e, transparent: true, opacity: 0.13}))
      plain.position.z = -2.5 + i * 0.5
      this.group.add(plain)
    }
  }

  back() {
    //this.toend = false
  }

  tilt(percent) {
    this.group.rotation.y = percent * 0.5
  }

  animate() {
    this.mesh.rotation.x += this.rotatevalue + this.acceleration
    this.render()
    this.animationFrameId = requestAnimationFrame(() => { this.animate() })
  }

  render() {
    if (this.animationComplete) return

    var progress

    if (this.animatestep < 240) {
      this.animatestep = Math.max(0, Math.min(240, this.toend ? this.animatestep + 1 : this.animatestep - 4))
      this.acceleration = this.easing(this.animatestep, 0, 1, 240)

      if (this.acceleration > 0.35) {
        progress = (this.acceleration - 0.35) / 0.65
        this.group.rotation.y = -Math.PI / 2 * progress
        this.group.position.z = 50 * progress
        progress = Math.max(0, (this.acceleration - 0.97) / 0.03)
        this.mesh.material.opacity = 1 - progress
        this.ringcover.material.opacity = this.ring.material.opacity = progress
        this.ring.scale.x = this.ring.scale.y = 0.9 + 0.1 * progress
      }
    } else if (this.animatestep == 240) {
      console.log(`start glob ${this.animatestep}`)
      this.animatestep = 241
      void this.startSoundGraphic()
    } else if (this.animatestep == 242) {
      console.log('glob', this.analyser)
      this.analyser.getByteFrequencyData(this.dataArray)
      // this.renderer.clearRect(0, 0, this.renderer.domElement.width, this.renderer.domElement.height)
      this.glob.draw(this.dataArray, this.scene)
    }

    this.renderer.render(this.scene, this.camera)
  }

  easing(t, b, c, d) {
    if ((t /= d / 2) < 1) return c / 2 * t * t + b

    return c / 2 * ((t -= 2) * t * t + 2) + b
  }

  async startSoundGraphic() {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)()
    const stream = await navigator.mediaDevices.getUserMedia({audio: true})
    this.analyser = audioCtx.createAnalyser()
    const source = audioCtx.createMediaStreamSource(stream)
    source.connect(this.analyser)
    console.log(`analyzer`, this.analyser)

    this.glob = new Glob({
      fillColor: "black",
      lineColor: "black",
      lineWidth: 2,
      count: 100,
      frequencyBand: "mids"
    })

    this.analyser.fftSize = 1024
    const bufferLength = this.analyser.frequencyBinCount
    this.dataArray = new Uint8Array(bufferLength)
    this.animatestep = 242
  }

}

class CustomSinCurve extends THREE.Curve {
  constructor(scale, length, radius, pi2) {
    super()
    this.scale = scale
    this.length = length
    this.radius = radius
    this.pi2 = pi2
  }

  getPoint(t) {
    var x = this.length * Math.sin(this.pi2 * t)
    var y = this.radius * Math.cos(this.pi2 * 3 * t)
    var z, temp

    temp = t % 0.25 / 0.25
    temp = t % 0.25 - (2 * (1 - temp) * temp * -0.0185 + temp * temp * 0.25)
    if (Math.floor(t / 0.25) == 0 || Math.floor(t / 0.25) == 2) {
      temp *= -1
    }
    z = this.radius * Math.sin(this.pi2 * 2 * (t - temp))

    return new THREE.Vector3(x, y, z).multiplyScalar(this.scale)
  }
}


// Custom sound graphic

class AudioData {
  constructor(audioBufferData) {
    this.data = audioBufferData
  }

  setFrequencyBand(band) {
    let baseLength = Math.floor(this.data.length * .0625)
    let lowsLength = Math.floor(this.data.length * .0625)
    let midsLength = Math.floor(this.data.length * .375)

    let bands = {
      base: this.data.slice(0, baseLength),
      lows: this.data.slice(baseLength + 1, baseLength + lowsLength),
      mids: this.data.slice(baseLength + lowsLength + 1, baseLength + lowsLength + midsLength),
      highs: this.data.slice(baseLength + lowsLength + midsLength + 1)
    }

    this.data = bands[band]
  }

  scaleData(maxSize) {
    if (!(maxSize < 255)) return

    this.data = this.data.map(value => {
      let percent = Math.round((value / 255) * 100) / 100
      return maxSize * percent
    })
  }
}

class Glob {
  constructor(options = {}) {
    this._options = options
    this.mesh = null
  }

  draw(audioBufferData, scene) {
    console.log('drawing')
    const audioData = new AudioData(audioBufferData)
    this._options = {
      count: 100,
      diameter: 5.55 * 2,
      frequencyBand: "mids",
      rounded: true,
      ...this._options
    }

    if (this._options.frequencyBand) audioData.setFrequencyBand(this._options.frequencyBand)
    audioData.scaleData(50)

    if (this._options?.mirroredX) {
      let n = 1
      for (let i = Math.ceil(audioData.data.length / 2); i < audioData.data.length; i++) {
        audioData.data[i] = audioData.data[Math.ceil(audioData.data.length / 2) - n]
        n++
      }
    }

    let points = []
    let highestFreqValue = audioData.data[Math.floor(audioData.data.length / this._options.count) * 99]

    for (let i = 0; i < this._options.count; i++) {
      let dataIndex = Math.floor(audioData.data.length / this._options.count) * i
      let dataValue = audioData.data[dataIndex]

      let perctDecrease = 100 - i * 10
      let differenceToSmooth = dataValue - highestFreqValue
      let adjValue = (i >= 0 && i <= 10) ? (-1 * differenceToSmooth * (perctDecrease / 100)) : 0

      let degrees = 360 / this._options.count
      let newDiameter = this._options.diameter + dataValue + Math.round(adjValue)

      let x = (newDiameter / 2) * Math.cos(THREE.MathUtils.degToRad(degrees * i))
      let y = (newDiameter / 2) * Math.sin(THREE.MathUtils.degToRad(degrees * i))
      points.push(new THREE.Vector3(x, y, 0))
    }

    if (this.mesh) {
      scene.remove(this.mesh)
    }

    const geometry = new THREE.BufferGeometry().setFromPoints(points)
    const material = new THREE.LineBasicMaterial({color: 0xffffff, side: THREE.DoubleSide})
    this.mesh = new THREE.LineLoop(geometry, material)
    this.mesh.position.z = 100
    scene.add(this.mesh)
  }
}