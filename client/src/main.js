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

  camera.position.set(0, 0, 100);
  camera.lookAt(0, 0, 0);

  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setAnimationLoop(gameLoop);
  document.body.appendChild(renderer.domElement);

  const geometry = new THREE.BoxGeometry(1, 1, 1);
  const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
  const cube = new THREE.Mesh(geometry, material);

  scene.add(cube);

  camera.position.z = 5;

  function gameLoop() {
    cube.rotation.x += 0.01;
    cube.rotation.y += 0.01;

    renderer.render(scene, camera);
  }

  // mouse inputs
  function onMouseDown() {
    console.log("Mouse Down event");
  }
  function onMouseUp() {
    console.log("Mouse Up event");
  }
  function onMouseMove() {
    console.log("Mouse Move event");
  }

  addEventListener("mousedown", onMouseDown, false);
  addEventListener("mouseup", onMouseUp, false);
  addEventListener("mousemove", onMouseMove, false);
};
