import * as THREE from "three";
import { CreateCamera } from "./camera.js";

window.onload = () => {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x6dafdb);
  let prevHeight = window.innerHeight;
  let prevWidth = window.innerWidth;
  let camera = CreateCamera(prevHeight, prevWidth);

  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setAnimationLoop(gameLoop);
  document.body.appendChild(renderer.domElement);

  const geometry = new THREE.BoxGeometry(1, 1, 1);
  const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
  const cube = new THREE.Mesh(geometry, material);

  scene.add(cube);

  function initScene() {
    camera = CreateCamera(prevHeight, prevWidth);
  }

  function resizeCanvas() {
    if (window.innerHeight != prevHeight || window.innerWidth != prevWidth) {
      renderer.setSize(window.innerWidth, window.innerHeight);

      prevHeight = window.innerHeight;
      prevWidth = window.innerWidth;
    }
    initScene();
  }

  // mouse inputs
  function onMouseDown() {
    console.log("main mouse");
    camera.onMouseDown();
  }
  function onMouseUp() {
    camera.onMouseUp();
  }
  function onMouseMove(e) {
    camera.onMouseMove(e);
  }

  addEventListener("resize", resizeCanvas);
  addEventListener("mousedown", onMouseDown, false);
  addEventListener("mouseup", onMouseUp, false);
  addEventListener("mousemove", onMouseMove, false);

  function gameLoop() {
    // cube.rotation.x += 0.01;
    // cube.rotation.y += 0.01;

    renderer.render(scene, camera.camera);
  }
};
