import {
  Box3, Color, DirectionalLight, Group, HemisphereLight, OrthographicCamera,
  Scene, Vector3, WebGLRenderer, BoxGeometry, BufferGeometry, Float32BufferAttribute,
  Mesh, MeshStandardMaterial, Raycaster, Vector2,
} from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { MTLLoader } from 'three/addons/loaders/MTLLoader.js';
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
import { STLLoader } from 'three/addons/loaders/STLLoader.js';
import { gunzipSync, strFromU8, unzipSync } from 'fflate';

const host = document.querySelector('#campus');
let archives = { campus: [], mascot: [] };
let resetCamera;
let showScene;
let drawRoute;
let focusPlace;

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

const campusPlaces = {
  johyeong_hall_1: ['artsBuilding', '조형1관'],
  johyeong_hall_2: ['artsBuilding', '조형2관'],
  music_hall: ['musicHall', '음악관'],
  sungshin_hall: ['sungshinHall', '성신관'],
  campus_museum: ['campusMuseum', '박물관'],
  sujeong_hall_a: ['sujeongHallA', '수정관 A동'],
  campus_structure_05: ['primeBuilding', '프라임관'],
  sujeong_hall_b: ['sujeongHallB', '수정관 B동'],
  sujeong_hall_c: ['sujeongHallC', '수정관 C동'],
  central_library: ['centralLibrary', '중앙도서관'],
  sungshin_annex: ['sungshinAnnex', '성신별관'],
};

const statusMarkers = [
  ['johyeong_hall_1', ['classrooms', 'events'], '조형1관 · 수업 중 · 행사 중'],
  ['central_library', ['events'], '중앙도서관 · 행사 중'],
  ['sungshin_hall', ['reports'], '성신관 · 벌레 주의'],
];

function box(group, rect, height, color, name = '') {
  const [x, z, width, depth] = rect.map(value => value * 8);
  const mesh = new Mesh(
    new BoxGeometry(width, height, depth),
    new MeshStandardMaterial({ color }),
  );
  mesh.position.set(x + width / 2 - 4, height / 2, z + depth / 2 - 4);
  mesh.name = name;
  group.add(mesh);
  return mesh;
}

function batchCampus(source) {
  // This OBJ has no texture maps and stores its faces as non-indexed triangles.
  const batches = new Map();
  for (const { geometry, material } of source.children) {
    const positions = geometry.getAttribute('position').array;
    const normals = geometry.getAttribute('normal').array;
    const groups = Array.isArray(material)
      ? geometry.groups
      : [{ start: 0, count: positions.length / 3 }];
    for (const { start, count, materialIndex } of groups) {
      const surface = Array.isArray(material) ? material[materialIndex] : material;
      if (!batches.has(surface)) batches.set(surface, { chunks: [], length: 0 });
      const batch = batches.get(surface);
      batch.chunks.push({
        positions: positions.subarray(start * 3, (start + count) * 3),
        normals: normals.subarray(start * 3, (start + count) * 3),
      });
      batch.length += count * 3;
    }
  }

  const group = new Group();
  for (const [material, { chunks, length }] of batches) {
    const positions = new Float32Array(length);
    const normals = new Float32Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      positions.set(chunk.positions, offset);
      normals.set(chunk.normals, offset);
      offset += chunk.positions.length;
    }
    const geometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    geometry.setAttribute('normal', new Float32BufferAttribute(normals, 3));
    group.add(new Mesh(geometry, material));
  }
  return group;
}

function paintMascot(geometry) {
  const snow = new Color(0xf4f1ed);
  const red = new Color(0xbf2736);
  const violet = new Color(0x5b3d9e);
  const ink = new Color(0x17141c);
  const positions = geometry.getAttribute('position');
  const colors = new Float32Array(positions.count * 3);

  // The STL has a single surface. These regions use its original coordinates
  // after rotating the model upright, with the face pointing toward +z.
  for (let i = 0; i < positions.count; i++) {
    const x = positions.getX(i);
    const y = positions.getY(i);
    const z = positions.getZ(i);
    const side = Math.abs(x);
    const cap = y > 117 && y < 137 && side < 20 && Math.abs(z) < 19;
    const scarf = y > 44 && y < 58 && side < 28;
    const scarfEnds = y > 24 && y <= 44 && x > -16 && x < 4 && z > 27;
    const eyes = Math.hypot((side - 10) / 3.2, (y - 84) / 3.4) < 1;
    const mouth = side < 5.7 && Math.abs(y - 73 - side * .19) < 1.4;
    const cheek =
      (side > 17 && side < 31 && Math.abs(y - 98 - (side - 23) * .70) < 4) ||
      (side > 19 && side < 30 && Math.abs(y - 83 - (side - 23) * .45) < 3) ||
      (side > 20 && side < 30 && Math.abs(y - 73) < 2.6);
    const ridge = z < -28 && side < 8 && y > 37 && y < 106;
    const toes = y > 13 && y < 19 && side > 10 && z > 34;
    const color = z > 30 && (eyes || mouth) ? ink
      : cap || scarf || scarfEnds ? red
      : (z > 12 && cheek) || ridge || toes ? violet
      : snow;
    color.toArray(colors, i * 3);
  }
  geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));
}
function start(rooms, corridor, initialIndoor, initialFilter, initialActive, measure) {
  const started = performance.now();
  const campusSource = model(archives.campus, 'sungshin-campus-lowpoly');
  const campus = batchCampus(campusSource);
  const campusTargets = campusSource.children.filter(mesh =>
    Object.hasOwn(campusPlaces, mesh.name.replace(/^label_(plate_)?/, '')));
  for (const target of campusTargets) target.geometry.computeBoundingBox();
  const packed = Uint8Array.from(atob(archives.mascot.join('')), character => character.charCodeAt(0));
  const geometry = new STLLoader().parse(gunzipSync(packed).buffer);
  geometry.rotateX(-Math.PI / 2);
  geometry.computeVertexNormals();
  paintMascot(geometry);
  const mascotModel = new Mesh(geometry, new MeshStandardMaterial({
    vertexColors: true, roughness: .85,
  }));
  archives = null;
  const indoor = new Group();
  box(indoor, [0, 0, 1, 1], .06, 0xe5edf3);
  box(indoor, corridor, .075, 0xffffff);
  for (const room of rooms) {
    box(indoor, room.rect, .22, room.id === 'elevator' ? 0x9ccdbb : 0xc5caf9, room.id);
  }

  const scene = new Scene();
  scene.background = new Color(0xeaf0ea);
  scene.add(campus, indoor, new HemisphereLight(0xffffff, 0x71644a, 2.1));
  const sun = new DirectionalLight(0xfff4dc, 2);
  sun.position.set(8, 15, 6);
  scene.add(sun);

  const renderer = new WebGLRenderer();
  renderer.domElement.addEventListener('webglcontextlost', () => send('error'));
  renderer.setPixelRatio(1);
  host.appendChild(renderer.domElement);
  const camera = new OrthographicCamera(-1, 1, 1, -1, 0.1, 150);
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.maxPolarAngle = Math.PI * .46;
  controls.minZoom = .65;
  controls.maxZoom = 5;
  controls.enableDamping = true;

  const mascotBounds = new Box3().setFromObject(mascotModel);
  const mascotCenter = mascotBounds.getCenter(new Vector3());
  const mascotScale = .85 / mascotBounds.getSize(new Vector3()).y;
  mascotModel.scale.setScalar(mascotScale);
  mascotModel.position.set(-mascotCenter.x * mascotScale, -mascotBounds.min.y * mascotScale, -mascotCenter.z * mascotScale);
  const mascot = new Group();
  mascot.add(mascotModel);
  const walkway = new Box3().setFromObject(campusSource.getObjectByName('west_campus_walk'));
  mascot.position.copy(walkway.getCenter(new Vector3()));
  mascot.position.y = walkway.max.y + .015;
  campus.add(mascot);
  const indoorMascot = mascot.clone();
  indoorMascot.position.set(-.85, .08, -.4);
  indoorMascot.scale.setScalar(.58);
  indoor.add(indoorMascot);

  const labels = [];
  function addMarker(mesh, id, label, categories = []) {
    const marker = document.createElement('button');
    marker.className = 'marker ' + (categories.length === 2 ? 'combined' : categories[0] ?? '');
    marker.textContent = label;
    marker.addEventListener('click', () => {
      focusMesh(mesh);
      send('place:' + id);
    });
    host.append(marker);
    const bounds = new Box3().setFromObject(mesh);
    const anchor = bounds.getCenter(new Vector3());
    anchor.y = bounds.max.y + .12;
    labels.push({ marker, anchor, categories, indoorMarker: mesh.parent === indoor });
  }
  for (const room of rooms) {
    addMarker(indoor.getObjectByName(room.id), room.id, room.label);
  }

  for (const [object, categories, label] of statusMarkers) {
    addMarker(campusSource.getObjectByName(object), campusPlaces[object][0], label, categories);
  }
  const [primeId, primeLabel] = campusPlaces.campus_structure_05;
  addMarker(campusSource.getObjectByName('campus_structure_05'), primeId, primeLabel);

  let inside = false;
  let filter = 'all';
  let active = true;
  let span;
  let dirty = true;
  let flight;
  resetCamera = () => {
    flight = null;
    const bounds = new Box3().setFromObject(inside ? indoor : campus);
    const center = bounds.getCenter(new Vector3());
    const size = bounds.getSize(new Vector3());
    span = Math.max(size.x, size.z);
    camera.zoom = inside ? 1 : 1.45;
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
    dirty = true;
  }
  new ResizeObserver(resize).observe(host);

  const roomTargets = rooms.map(room => indoor.getObjectByName(room.id));
  function flyTo(target, zoom) {
    flight = {
      from: controls.target.clone(),
      offset: camera.position.clone().sub(controls.target),
      target,
      startZoom: camera.zoom,
      endZoom: Math.max(camera.zoom, zoom),
      started: performance.now(),
    };
    dirty = true;
  }

  function focusMesh(mesh) {
    const target = new Box3().setFromObject(mesh).getCenter(new Vector3());
    flyTo(target, inside ? 2.3 : 2.7);
  }

  focusPlace = id => {
    if (id === 'mascot') {
      const target = (inside ? indoorMascot : mascot).position.clone();
      target.y += inside ? .24 : .4;
      flyTo(target, inside ? 3.2 : 4.5);
      return;
    }
    const mesh = inside
      ? indoor.getObjectByName(id)
      : campusSource.getObjectByName(Object.keys(campusPlaces).find(name => campusPlaces[name][0] === id));
    if (mesh) focusMesh(mesh);
  };
  controls.addEventListener('start', () => { flight = null; });

  const raycaster = new Raycaster();
  const point = new Vector2();
  const canvas = renderer.domElement;
  let pointerDown;
  canvas.addEventListener('pointerdown', event => {
    pointerDown = event.isPrimary ? [event.clientX, event.clientY] : null;
  });
  canvas.addEventListener('pointercancel', () => { pointerDown = null; });
  canvas.addEventListener('pointerup', event => {
    if (!pointerDown || Math.hypot(event.clientX - pointerDown[0], event.clientY - pointerDown[1]) > 8) return;
    const rect = canvas.getBoundingClientRect();
    point.set((event.clientX - rect.left) / rect.width * 2 - 1, 1 - (event.clientY - rect.top) / rect.height * 2);
    raycaster.setFromCamera(point, camera);
    const pickStarted = performance.now();
    const targets = inside ? roomTargets : campusTargets;
    const hit = raycaster.intersectObjects(targets, false)[0]?.object;
    if (measure) send('perf:pick_ms=' + (performance.now() - pickStarted).toFixed(1));
    const name = hit?.name.replace(/^label_(plate_)?/, '');
    const id = inside ? rooms.find(room => room.id === name)?.id : campusPlaces[name]?.[0];
    if (id) {
      const mesh = inside ? hit : campusSource.getObjectByName(name);
      if (mesh) focusMesh(mesh);
      send('place:' + id);
    }
  });

  const route = new Group();
  const routeMaterial = new MeshStandardMaterial({ color: 0x347dff });
  indoor.add(route);
  const mascotTarget = indoorMascot.position.clone();
  drawRoute = (points, step) => {
    for (const segment of [...route.children]) {
      segment.geometry.dispose();
      route.remove(segment);
    }
    for (let i = 1; i < points.length; i++) {
      const [x, z] = points[i - 1];
      const [endX, endZ] = points[i];
      const dx = (endX - x) * 8;
      const dz = (endZ - z) * 8;
      const segment = new Mesh(new BoxGeometry(Math.hypot(dx, dz), .018, .075), routeMaterial);
      segment.position.set((x + endX) * 4 - 4, .088, (z + endZ) * 4 - 4);
      segment.rotation.y = -Math.atan2(dz, dx);
      route.add(segment);
    }
    const point = points[step] ?? points[0];
    mascotTarget.set(point ? point[0] * 8 - 4 : -.85, .08, point ? point[1] * 8 - 4 : -.4);
    if (step == null || step === 0) indoorMascot.position.copy(mascotTarget);
    dirty = true;
  };

  showScene = (showIndoor, selectedFilter, isActive) => {
    const changed = inside !== showIndoor;
    inside = showIndoor;
    active = isActive;
    filter = selectedFilter;
    campus.visible = !inside;
    indoor.visible = inside;
    if (changed) resetCamera();
    dirty = true;
  };
  showScene(initialIndoor, initialFilter, initialActive);
  resetCamera();
  const projected = new Vector3();
  let firstFrame = true;
  let gestureGaps = null;
  let previousGestureFrame = null;
  if (measure) {
    controls.addEventListener('start', () => {
      gestureGaps = [];
      previousGestureFrame = null;
    });
    controls.addEventListener('end', () => {
      if (gestureGaps?.length >= 3) {
        gestureGaps.sort((a, b) => a - b);
        const p95 = gestureGaps[Math.ceil(gestureGaps.length * .95) - 1];
        send('perf:gesture_p95_frame_ms=' + p95.toFixed(1) + ' samples=' + gestureGaps.length);
      }
      gestureGaps = null;
    });
  }
  renderer.setAnimationLoop(time => {
    if (!active && !firstFrame) return;
    if (gestureGaps && gestureGaps.length < 300) {
      if (previousGestureFrame !== null) gestureGaps.push(time - previousGestureFrame);
      previousGestureFrame = time;
    }
    if (flight) {
      const progress = Math.min(1, Math.max(0, (time - flight.started) / 450));
      const eased = 1 - (1 - progress) ** 3;
      controls.target.lerpVectors(flight.from, flight.target, eased);
      camera.position.copy(controls.target).add(flight.offset);
      camera.zoom = flight.startZoom + (flight.endZoom - flight.startZoom) * eased;
      camera.updateProjectionMatrix();
      if (progress === 1) flight = null;
      dirty = true;
    }
    const moved = controls.update();
    const mascotMoving = inside && indoorMascot.position.distanceToSquared(mascotTarget) > .0001;
    if (mascotMoving) {
      const dx = mascotTarget.x - indoorMascot.position.x;
      const dz = mascotTarget.z - indoorMascot.position.z;
      indoorMascot.rotation.y = Math.atan2(dx, dz);
      indoorMascot.position.lerp(mascotTarget, .09);
    }
    if (!(moved || dirty || mascotMoving)) return;
    renderer.render(scene, camera);
    if (firstFrame) {
      firstFrame = false;
      const { calls, triangles } = renderer.info.render;
      requestAnimationFrame(() => {
        if (measure) send('perf:scene_to_first_frame_ms=' + (performance.now() - started).toFixed(1)
          + ' draw_calls=' + calls + ' triangles=' + triangles);
        send('ready');
      });
    }
    dirty = false;
    for (const { marker, anchor, categories, indoorMarker } of labels) {
      projected.copy(anchor).project(camera);
      marker.hidden = Math.abs(projected.x) >= .98 || Math.abs(projected.y) >= .98 ||
        inside !== indoorMarker ||
        (categories.length > 0 && filter !== 'all' && !categories.includes(filter));
      if (!marker.hidden) {
        marker.style.left = (projected.x + 1) * 50 + '%';
        marker.style.top = (1 - projected.y) * 50 + '%';
      }
    }
  });
}

window.yogiCampus = {
  append(name, chunk) { archives[name].push(chunk); },
  start(rooms, corridor, indoor, filter, active, measure) {
    try {
      start(rooms, corridor, indoor, filter, active, measure);
    } catch (error) {
      console.error(error);
      send('error');
    }
  },
  focus(id) { focusPlace?.(id); },
  route(points, step) { drawRoute?.(points, step); },
  show(indoor, filter, active) { showScene?.(indoor, filter, active); },
};
send('loader-ready');