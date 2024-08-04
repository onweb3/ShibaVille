import * as THREE from "three";
import { CreateCamera } from "./camera.js";

export function createScene(window) {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x6dafdb);
  let prevHeight = window.innerHeight;
  let prevWidth = window.innerWidth;
  let camera = CreateCamera(prevHeight, prevWidth);
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setAnimationLoop(gameLoop);
  document.body.appendChild(renderer.domElement);

  // ville lands
  //   function createVille() {
  //     const lands = []; // this data should be fetched from the chromia blockchain

  //     // for now we use a temp data to build an MVP to see how the ville looks
  //     // We do the same thing as create_ville operation here. (10x10 grid)
  //     for (let x = 0; x < 10; x++) {
  //       const column = [];
  //       for (let y = 0; y < 10; y++) {
  //         const land = { x, y, building: undefined };
  //         if (Math.random() > 0.7) {
  //           land.building = "building";
  //         }
  //         column.push(land);
  //       }
  //       lands.push(column);
  //     }

  //     return lands;
  //   }

  //data

  const tiles = [];
  const buildings = [];

  function lightSetup() {
    const lights = [
      new THREE.AmbientLight(0xffffff, 0.5),
      new THREE.DirectionalLight(0xffffff, 1),
      new THREE.DirectionalLight(0xffffff, 3),
      new THREE.DirectionalLight(0xffffff, 3),
    ];

    lights[1].position.set(0, 1, 0);
    lights[2].position.set(1, 1, 0);
    lights[3].position.set(0, 1, 1);
    scene.add(...lights);
  }
  function initScene(ville) {
    scene.clear();
    const tiles = [];
    lightSetup();
    camera = CreateCamera(prevHeight, prevWidth);
    for (let x = 0; x < ville.lands.length; x++) {
      const column = [];
      for (let y = 0; y < ville.lands.length; y++) {
        const geometry = new THREE.BoxGeometry(1, 1, 1);
        const material = new THREE.MeshLambertMaterial({ color: 0x00aa00 });
        const tile = new THREE.Mesh(geometry, material);
        tile.position.set(x, -0.5, y);
        scene.add(tile);
        column.push(tile);

        // buidling
        if (ville.lands[x][y].building === "building") {
          const Buildinggeometry = new THREE.BoxGeometry(1, 1, 1);
          const Buildingmaterial = new THREE.MeshLambertMaterial({
            color: 0x000500,
          });
          const Building = new THREE.Mesh(Buildinggeometry, Buildingmaterial);
          Building.position.set(x, 0.5, y);
          scene.add(Building);
          column.push(Building);
        }
      }
      tiles.push(column);
    }
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

  function gameLoop() {
    // cube.rotation.x += 0.01;
    // cube.rotation.y += 0.01;
    //ville.update();

    renderer.render(scene, camera.camera);
  }

  return {
    initScene,
    onMouseDown,
    onMouseUp,
    onMouseMove,
  };
}
