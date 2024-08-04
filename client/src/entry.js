import { createScene } from "./main.js";
import { createVille } from "./ville.js";

export function createGame() {
  const scene = createScene(window);
  const ville = createVille();

  scene.initScene(ville);
  scene.onObjectSelected = (selectedObject) => {
    console.log(selectedObject);
    let { x, y } = selectedObject.userData;
    const tile = ville.lands[x][y];
    console.log(tile);
  };

  const gameUpdater = {
    update() {
      ville.update();
      scene.update(ville);
    },
  };

  setInterval(() => {
    gameUpdater.update();
  }, 1000);

  addEventListener("mousedown", scene.onMouseDown.bind(scene), false);
  addEventListener("mouseup", scene.onMouseUp.bind(scene), false);
  addEventListener("mousemove", scene.onMouseMove.bind(scene), false);
  addEventListener("contextmenu", (e) => e.preventDefault(), false);

  scene.start();

  return gameUpdater;
}
