import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('connected home')

    this.bodyElement = document.body
    this.wrapElement = document.getElementById('wrap')

    this.length = 30
    this.radius = 5.6

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

    this.ringcover = new THREE.Mesh(new THREE.PlaneGeometry(50, 15, 1), new THREE.MeshBasicMaterial({color: 0xd1684e, opacity: 0, transparent: true}))
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
    let size = this.element.getBoundingClientRect().height
    this.renderer.setSize(size, size)
    this.renderer.setClearColor('#d1684e')

    this.wrapElement.appendChild(this.renderer.domElement)

    this.bodyElement.addEventListener('mousedown', this.start.bind(this), false)
    this.bodyElement.addEventListener('touchstart', this.start.bind(this), false)
    this.bodyElement.addEventListener('mouseup', this.back.bind(this), false)
    this.bodyElement.addEventListener('touchend', this.back.bind(this), false)

    this.animate()
  }

  disconnect() {
    this.bodyElement.removeEventListener('mousedown', this.start.bind(this), false)
    this.bodyElement.removeEventListener('touchstart', this.start.bind(this), false)
    this.bodyElement.removeEventListener('mouseup', this.back.bind(this), false)
    this.bodyElement.removeEventListener('touchend', this.back.bind(this), false)
  }

  start() {
    console.log('starting')
    this.toend = true
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
    console.log(`animate: `, this.mesh)
    this.mesh.rotation.x += this.rotatevalue + this.acceleration
    this.render()
    requestAnimationFrame(() => {this.animate()})
  }

  render() {
    var progress

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