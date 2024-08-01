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
  const geometry1 = new THREE.BoxGeometry(1, 1, 1);
  const material1 = new THREE.MeshBasicMaterial({ color: 0x0000ff });
  const cube1 = new THREE.Mesh(geometry1, material1);

  scene.add(cube1);
  cube.position.x = 2;
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
  function onMouseDown(e) {
    console.log("main mouse");
    camera.onMouseDown(e);
  }
  function onMouseUp(e) {
    camera.onMouseUp(e);
  }
  function onMouseMove(e) {
    camera.onMouseMove(e);
  }
  function NoContextMenu(e) {
    e.preventDefault();
  }

  addEventListener("resize", resizeCanvas);
  addEventListener("mousedown", onMouseDown, false);
  addEventListener("mouseup", onMouseUp, false);
  addEventListener("mousemove", onMouseMove, false);
  addEventListener("contextmenu", NoContextMenu, false);

  function gameLoop() {
    // cube.rotation.x += 0.01;
    // cube.rotation.y += 0.01;

    renderer.render(scene, camera.camera);
  }
};
