import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { createAssetInst } from "./factory.js";

let camera, controls, scene, renderer;

export function createScene(window) {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x6dafdb);
  scene.fog = new THREE.FogExp2(0x6dafdb, 0.002);

  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.appendChild(renderer.domElement);

  camera = new THREE.PerspectiveCamera(
    60,
    window.innerWidth / window.innerHeight,
    1,
    1000
  );
  camera.position.set(600, 600, 600);

  // controls

  controls = new OrbitControls(camera, renderer.domElement);
  controls.listenToKeyEvents(window); // optional

  //controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)

  controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
  controls.dampingFactor = 0.05;

  controls.screenSpacePanning = false;

  controls.minDistance = 100;
  controls.maxDistance = 300;

  controls.maxPolarAngle = Math.PI / 4;

  const lineTrace = new THREE.Raycaster();
  const mousePostition = new THREE.Vector2();
  let selectedObject = undefined;
  let onObjectSelected = undefined;
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
      new THREE.AmbientLight(0xffffff),
      new THREE.DirectionalLight(0xffffff, 3),
      new THREE.DirectionalLight(0xffffff, 3),
    ];

    lights[1].position.set(1, 1, 1);
    lights[2].position.set(-1, -1, -1);
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
    window.addEventListener("resize", onWindowResize);
  }

  function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
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
    if (e.button === 0) {
      mousePostition.x = (e.clientX / renderer.domElement.clientWidth) * 2 - 1;
      mousePostition.y =
        -(e.clientY / renderer.domElement.clientHeight) * 2 + 1;

      lineTrace.setFromCamera(mousePostition, camera);

      let hitResult = lineTrace.intersectObjects(scene.children, false);
      if (hitResult.length > 0) {
        if (selectedObject) {
          selectedObject.material.emissive.setHex(0);
        }
        selectedObject = hitResult[0].object;
        selectedObject.material.emissive.setHex(0xff0000);
        if (this.onObjectSelected) {
          this.onObjectSelected(selectedObject);
        }
      }
    }
  }
  function onMouseUp(e) {}
  function onMouseMove(e) {}
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
    controls.update();
    renderer.render(scene, camera);
  }

  return {
    onObjectSelected,
    initScene,
    onMouseDown,
    onMouseUp,
    onMouseMove,
    update,
    start,
  };
}
