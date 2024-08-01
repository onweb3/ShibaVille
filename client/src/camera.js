import * as THREE from "three";

export function CreateCamera(Height, Width) {
  const camera = new THREE.PerspectiveCamera(75, Width / Height, 0.1, 1000);

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
    //camera.aspect = Width / Height;
    camera.lookAt(0, 0, 0);
    camera.updateMatrix();
  }

  // mouse inputs
  function onMouseDown() {
    console.log("camera mouise");
    bIsMouseIsDown = true;
  }
  function onMouseUp() {
    bIsMouseIsDown = false;
  }
  function onMouseMove(e) {
    //console.log([e.screenX, e.screenY]);

    if (bIsMouseIsDown) {
      cameraAzimuth += (e.screenX - prevMouseX) * 0.5;
      cameraElevation += (e.screenY - prevMouseY) * 0.5;
      cameraElevation = Math.min(90, Math.max(0, cameraElevation));
      updateCamera();
    }

    prevMouseX = e.screenX;
    prevMouseY = e.screenY;
  }

  return { camera, onMouseDown, onMouseUp, onMouseMove, updateCamera };
}
