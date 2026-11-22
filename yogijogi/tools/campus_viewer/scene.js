import {
  Box3, Color, DirectionalLight, Group, HemisphereLight, OrthographicCamera,
  Scene, Vector3, WebGLRenderer,
} from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { MTLLoader } from 'three/addons/loaders/MTLLoader.js';
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
import { strFromU8, unzipSync } from 'fflate';

const host = document.querySelector('#campus');
let archives = { campus: [], mascot: [] };
let resetCamera;
let walking = false;
let following = false;

function send(message) {
  window.CampusViewer?.postMessage(message);
}

function model(parts, stem) {
  const packed = Uint8Array.from(atob(parts.join('')), character => character.charCodeAt(0));
  const objName = stem + '.obj';
  const mtlName = stem + '.mtl';
  const files = unzipSync(packed, { filter: ({ name }) => name === objName || name === mtlName });
  if (!files[objName] || !files[mtlName]) throw new Error('Missing model files');
  const materials = new MTLLoader().parse(strFromU8(files[mtlName]), '');
  materials.preload();
  return new OBJLoader().setMaterials(materials).parse(strFromU8(files[objName]));
}

function start() {
  const campus = model(archives.campus, 'sungshin-campus-lowpoly');
  const mascotModel = model(archives.mascot, 'suryongi_mascot_3d');
  archives = null;

  const scene = new Scene();
  scene.background = new Color(0xeaf0ea);
  scene.add(campus, new HemisphereLight(0xffffff, 0x71644a, 2.1));
  const sun = new DirectionalLight(0xfff4dc, 2);
  sun.position.set(8, 15, 6);
  scene.add(sun);

  const renderer = new WebGLRenderer({ antialias: true });
  renderer.domElement.addEventListener('webglcontextlost', () => send('error'));
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
  host.appendChild(renderer.domElement);
  const camera = new OrthographicCamera(-1, 1, 1, -1, 0.1, 150);
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.maxPolarAngle = Math.PI * 0.46;
  controls.minZoom = 0.65;
  controls.maxZoom = 5;
  controls.enableDamping = true;

  const bounds = new Box3().setFromObject(campus);
  const center = bounds.getCenter(new Vector3());
  const size = bounds.getSize(new Vector3());
  const span = Math.max(size.x, size.z);
  let needsRender = true;
  resetCamera = () => {
    following = false;
    camera.zoom = 1;
    camera.position.copy(center).add(new Vector3(span * .65, span * .72, span * .62));
    controls.target.copy(center);
    resize();
    controls.update();
  };

  function resize() {
    const width = Math.max(host.clientWidth, 1);
    const height = Math.max(host.clientHeight, 1);
    const aspect = width / height;
    const halfHeight = span * .55 / Math.min(aspect, 1);
    camera.left = -halfHeight * aspect;
    camera.right = halfHeight * aspect;
    camera.top = halfHeight;
    camera.bottom = -halfHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
    needsRender = true;
  }
  new ResizeObserver(resize).observe(host);
  resetCamera();

  const mascotBounds = new Box3().setFromObject(mascotModel);
  const mascotCenter = mascotBounds.getCenter(new Vector3());
  const mascotScale = .85 / mascotBounds.getSize(new Vector3()).y;
  mascotModel.scale.setScalar(mascotScale);
  mascotModel.position.set(-mascotCenter.x * mascotScale, -mascotBounds.min.y * mascotScale, -mascotCenter.z * mascotScale);
  const mascot = new Group();
  mascot.add(mascotModel);
  scene.add(mascot);

  const walkway = campus.getObjectByName('west_campus_walk');
  if (!walkway) throw new Error('Missing campus demo walkway');
  const walkingBounds = new Box3().setFromObject(walkway);
  const midpoint = walkingBounds.getCenter(new Vector3());
  midpoint.y = walkingBounds.max.y + .015;
  const pathSize = walkingBounds.getSize(new Vector3());
  const axis = pathSize.x > pathSize.z ? 'x' : 'z';
  const offset = pathSize[axis] * .26;
  const target = new Vector3();
  const viewOffset = new Vector3(-1.7, 2.1, 2.5);
  let distance = 0;
  let previousTime;

  renderer.setAnimationLoop(time => {
    const dt = Math.min((time - (previousTime ?? time)) / 1000, .05);
    previousTime = time;
    if (walking) distance += dt * .48;
    const position = Math.sin(distance);
    mascot.position.copy(midpoint);
    mascot.position[axis] += position * offset;
    const direction = Math.cos(distance) >= 0 ? 1 : -1;
    mascot.rotation.y = (axis === 'x' ? Math.PI / 2 : 0) + (direction < 0 ? Math.PI : 0);
    mascotModel.position.y = -mascotBounds.min.y * mascotScale +
      (walking ? Math.abs(Math.sin(distance * 14)) * .035 : 0);
    if (following) {
      if (camera.zoom !== 2.8) {
        camera.zoom = 2.8;
        camera.updateProjectionMatrix();
      }
      target.copy(mascot.position).add(new Vector3(0, .45, 0));
      controls.target.lerp(target, .1);
      camera.position.lerp(target.add(viewOffset), .1);
    }
    const cameraMoved = controls.update();
    if (cameraMoved || needsRender || walking || following) {
      renderer.render(scene, camera);
      needsRender = false;
    }
  });
  send('ready');
}

window.yogiCampus = {
  append(name, chunk) { archives[name].push(chunk); },
  start() {
    try {
      start();
    } catch (error) {
      console.error(error);
      send('error');
    }
  },
  reset() { resetCamera?.(); },
  walk(enabled) { walking = enabled; },
  follow(enabled) {
    following = enabled;
    if (!enabled) resetCamera?.();
  },
};
send('loader-ready');
