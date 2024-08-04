import * as THREE from "three";
import { CreateCamera } from "./camera.js";
import { createAssetInst } from "./factory.js";

export function createScene(window) {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x6dafdb);

  let camera = CreateCamera(window.innerHeight, window.innerWidth);
  const renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
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
    // camera = CreateCamera(prevHeight, prevWidth);
    for (let x = 0; x < ville.lands.length; x++) {
      const column = [];
      for (let y = 0; y < ville.lands.length; y++) {
        const terrainId = ville.lands[x][y]?.terrainId;
        const tile = createAssetInst(terrainId, x, y);
        scene.add(tile);
        column.push(tile);
      }
      tiles.push(column);
      buildings.push([...Array(ville.lands.length)]);
    }
  }

  function update(ville) {
    //console.log("update scene --------");
    for (let x = 0; x < ville.lands.length; x++) {
      for (let y = 0; y < ville.lands.length; y++) {
        // update buidling
        const currentBuildingId = buildings[x][y]?.userData.id;
        const newBuildingId = ville.lands[x][y].buildingId;

        if (!newBuildingId && currentBuildingId) {
          scene.remove(buildings[x][y]);
          buildings[x][y] = undefined;
        }

        if (newBuildingId != currentBuildingId) {
          scene.remove(buildings[x][y]);
          buildings[x][y] = createAssetInst(newBuildingId, x, y);
          scene.add(buildings[x][y]);
        }
      }
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

  function start() {
    renderer.setAnimationLoop(gameLoop);
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
    update,
    start,
  };
}
