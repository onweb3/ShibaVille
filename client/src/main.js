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

  //data
  const tiles = [];
  const buildings = [];

  function initScene() {
    scene.clear();
    const tiles = [];
    camera = CreateCamera(prevHeight, prevWidth);
    for (let x = 0; x < 10; x++) {
      const column = [];
      for (let y = 0; y < 10; y++) {
        const geometry = new THREE.BoxGeometry(1, 1, 1);
        const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
        const tile = new THREE.Mesh(geometry, material);
        tile.position.set(x, 0, y);
        scene.add(tile);
        column.push(tile);
      }
      tiles.push(column);
    }
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
  initScene();
  function gameLoop() {
    // cube.rotation.x += 0.01;
    // cube.rotation.y += 0.01;

    renderer.render(scene, camera.camera);
  }
};
