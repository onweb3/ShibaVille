import * as THREE from "three";

window.onload = () => {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x6dafdb);
  const camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );

  let bIsMouseIsDown = false;
  let prevMouseX = 0;
  let prevMouseY = 0;
  let cameraAzimuth = 0;
  let cameraRadius = 4;
  let cameraElevation = 0;
  const DEG2RAD = Math.PI / 360;
  updateCamera();

  function updateCamera() {
    camera.position.x =
      cameraRadius *
      Math.sin(cameraAzimuth * DEG2RAD) *
      Math.cos(cameraElevation * DEG2RAD);
    camera.position.y = cameraRadius * Math.sin(cameraElevation * DEG2RAD);
    camera.position.z =
      cameraRadius *
      Math.cos(cameraAzimuth * DEG2RAD) *
      Math.cos(cameraElevation * DEG2RAD);
    camera.lookAt(0, 0, 0);
    camera.updateMatrix();
  }

  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setAnimationLoop(gameLoop);
  document.body.appendChild(renderer.domElement);

  const geometry = new THREE.BoxGeometry(1, 1, 1);
  const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
  const cube = new THREE.Mesh(geometry, material);

  scene.add(cube);

  function gameLoop() {
    // cube.rotation.x += 0.01;
    // cube.rotation.y += 0.01;

    renderer.render(scene, camera);
  }

  // mouse inputs
  function onMouseDown() {
    bIsMouseIsDown = true;
  }
  function onMouseUp() {
    bIsMouseIsDown = false;
  }
  function onMouseMove(e) {
    console.log([e.screenX, e.screenY]);

    if (bIsMouseIsDown) {
      cameraAzimuth += (e.screenX - prevMouseX) * 0.5;
      cameraElevation += (e.screenY - prevMouseY) * 0.5;
      cameraElevation = Math.min(90, Math.max(0, cameraElevation));
      updateCamera();
    }

    prevMouseX = e.screenX;
    prevMouseY = e.screenY;
  }

  addEventListener("mousedown", onMouseDown, false);
  addEventListener("mouseup", onMouseUp, false);
  addEventListener("mousemove", onMouseMove, false);
};
