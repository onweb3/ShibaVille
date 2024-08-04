import { createScene } from "./main.js";
import { createVille } from "./ville.js";

window.onload = () => {
  const scene = createScene(window);
  const ville = createVille();

  scene.initScene(ville);

  //   function resizeCanvas() {
  //     if (window.innerHeight != prevHeight || window.innerWidth != prevWidth) {
  //       renderer.setSize(window.innerWidth, window.innerHeight);

  //       prevHeight = window.innerHeight;
  //       prevWidth = window.innerWidth;
  //     }
  //     scene.initScene(ville);
  //   }

  //   addEventListener("resize", resizeCanvas);
  addEventListener("mousedown", scene.onMouseDown, false);
  addEventListener("mouseup", scene.onMouseUp, false);
  addEventListener("mousemove", scene.onMouseMove, false);
  addEventListener("contextmenu", (e) => e.preventDefault(), false);
};
