import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.bodyElement = document.body
    this.wrapElement = document.getElementById("visualizer-wrap")

    this.length = 45
    this.radius = 8.5
    this.animationComplete = false

    this.rotatevalue = 0.035
    this.acceleration = 0
    this.animatestep = 0
    this.startTransition = false

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

    this.ring = new THREE.Mesh(new THREE.RingGeometry(7, 7.55, 64), new THREE.MeshBasicMaterial({color: 0xffffff, opacity: 0, transparent: true}))
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

    window.addEventListener('resize', this.boundSetSize)

    this.animate()
  }

  async activate(event) {
    event.currentTarget.classList.add("hidden")
    this.startTransition = true
    this.transitionDone = false
    this.bootingDone = false
    await Listener.$.screenService.start()
    Play.Speaker.sound('booting', async() => {
      await Invoke.Listener()
      for (let i = 0; i < 20; i++) {
        if (this.transitionDone) {
          runAfter(0.2, () => {
            Prompt.Speaker.toSay("Hello... ? ... ? ... ? ... I'm here.")
          })
          break
        } else {
          await sleep(100)
        }
      }
    })
  }

  boundSetSize = () => { this.setSize() }
  setSize() {
    let size = this.element.getBoundingClientRect().height
    this.renderer.setSize(size, size)
  }

  disconnect() {
    window.removeEventListener('resize', this.boundSetSize)
  }


  fakeShadow() {
    var plain, i
    for (i = 0; i < 10; i++) {
      plain = new THREE.Mesh(new THREE.PlaneGeometry(this.length * 2 + 1, this.radius * 3, 1), new THREE.MeshBasicMaterial({color: 0xd1684e, transparent: true, opacity: 0.13}))
      plain.position.z = -2.5 + i * 0.5
      this.group.add(plain)
    }
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

    if (this.animatestep < 950) {
      this.animatestep = Math.max(0, Math.min(950, this.startTransition ? this.animatestep + 1 : this.animatestep - 4))
      this.acceleration = this.easing(this.animatestep, 0, 1, 950)

      if (this.acceleration > 0.35) {
        progress = (this.acceleration - 0.35) / 0.65
        this.group.rotation.y = -Math.PI / 2 * progress
        this.group.position.z = 50 * progress
        progress = Math.max(0, (this.acceleration - 0.97) / 0.03)
        this.mesh.material.opacity = 1 - progress
        this.ringcover.material.opacity = this.ring.material.opacity = progress
        this.ring.scale.x = this.ring.scale.y = 0.9 + 0.1 * progress
      }
    } else if (this.animatestep == 950) {
      this.animatestep = 951
      this.glob = new Glob({
        count: 100,
        frequencyBand: "mids"
      })
      this.transitionDone = true

    } else if (this.animatestep == 951 && Microphone.$.microphoneService.$.active) {
      Microphone.$.microphoneService.$.audioVisualizer.getByteFrequencyData(Microphone.$.microphoneService.$.audioVisualizerDataArray)
      this.glob.draw(Microphone.$.microphoneService.$.audioVisualizerDataArray, this.scene)
    }

    this.renderer.render(this.scene, this.camera)
  }

  easing(t, b, c, d) {
    if ((t /= d / 2) < 1) return c / 2 * t * t + b

    return c / 2 * ((t -= 2) * t * t + 2) + b
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
    this.maxSize = 255
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

  scaleData(size) {
    if (!(size < this.maxSize)) return

    this.data = this.data.map(value => {
      let percent = Math.round((value / this.maxSize) * 100) / 100
      return size * percent
    })
  }
}

class Glob {
  constructor(options = {}) {
    this._options = options
    this.mesh = null
  }

  draw(audioBufferData, scene) {
    const audioData = new AudioData(audioBufferData)
    this._options = {
      count: 100,
      diameter: 6.7 * 2, // Set diameter to match the white circle
      frequencyBand: "mids",
      rounded: true,
      ...this._options
    }

    if (this._options.frequencyBand) audioData.setFrequencyBand(this._options.frequencyBand)
    audioData.scaleData(60)

    if (this._options?.mirroredX) {
      let n = 1
      for (let i = Math.ceil(audioData.data.length / 2); i < audioData.data.length; i++) {
        audioData.data[i] = audioData.data[Math.ceil(audioData.data.length / 2) - n]
        n++
      }
    }

    // scale down everything
    for (let i = 0; i < audioData.data.length; i++) {
      audioData.data[i] = Math.pow(audioData.data[i], 0.7) * 0.6
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
      let newDiameter = this._options.diameter + dataValue + Math.round(adjValue) + 0.5

      let x = (newDiameter / 2) * Math.cos(THREE.MathUtils.degToRad(degrees * i))
      let y = (newDiameter / 2) * Math.sin(THREE.MathUtils.degToRad(degrees * i))
      points.push(new THREE.Vector3(x, y, 0))
    }

    if (this.mesh) {
      scene.remove(this.mesh)
    }

    // Create the shape for the glob
    const shape = new THREE.Shape()
    points.forEach((point, index) => {
      if (index === 0) {
        shape.moveTo(point.x, point.y)
      } else {
        shape.lineTo(point.x, point.y)
      }
    })
    shape.closePath()

    // Create the inner circle
    const innerCircleRadius = this._options.diameter / 2
    const innerCircle = new THREE.Path()
    innerCircle.absarc(0, 0, innerCircleRadius, 0, Math.PI * 2, true)
    shape.holes.push(innerCircle)

    // Create the geometry and material
    const geometry = new THREE.ShapeGeometry(shape)
    const material = new THREE.MeshBasicMaterial({color: 0xffffff, side: THREE.DoubleSide})

    // Create the mesh and add it to the scene
    this.mesh = new THREE.Mesh(geometry, material)
    this.mesh.position.z = 100
    scene.add(this.mesh)
  }
}