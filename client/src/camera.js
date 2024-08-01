import * as THREE from "three";

export function CreateCamera(Height, Width) {
  const camera = new THREE.PerspectiveCamera(75, Width / Height, 0.1, 1000);

  // mouse inputs
  let bIsleftMouseDown = false; // button 0
  let bIsRightMouseDown = false; // button 2
  let prevMouseX = 0;
  let prevMouseY = 0;

  //Camera settings
  const YAxis = new THREE.Vector3(0, 1, 1);
  let cameraOrigin = new THREE.Vector3();
  let cameraAzimuth = 135;
  let cameraRadius = 15;
  let cameraElevation = 45;
  const DEG2RAD = Math.PI / 180;
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
    //camera.add(cameraOrigin);
    camera.lookAt(cameraOrigin);
    camera.updateMatrix();
  }

  // mouse inputs
  function onMouseDown(e) {
    if (e.button === 0) {
      bIsleftMouseDown = true;
    }
    if (e.button === 2) {
      bIsRightMouseDown = true;
    }
  }
  function onMouseUp(e) {
    if (e.button === 0) {
      bIsleftMouseDown = false;
    }
    if (e.button === 2) {
      bIsRightMouseDown = false;
    }
  }
  function onMouseMove(e) {
    //mouse position change per frame;
    const deltaX = e.screenX - prevMouseX;
    const deltaY = e.screenY - prevMouseY;
    if (bIsleftMouseDown) {
      cameraAzimuth += deltaX * 0.2;
      cameraElevation += deltaY * 0.2;
      cameraElevation = Math.min(90, Math.max(30, cameraElevation));
      updateCamera();
    }

    if (bIsRightMouseDown) {
      const forward = new THREE.Vector3(0, 0, 1).applyAxisAngle(
        YAxis,
        cameraAzimuth * DEG2RAD
      );
      const left = new THREE.Vector3(1, 0, 0).applyAxisAngle(
        YAxis,
        cameraAzimuth * DEG2RAD
      );

      cameraOrigin.add(forward.multiplyScalar(-0.01 * deltaY));
      cameraOrigin.add(left.multiplyScalar(-0.01 * deltaX));
      updateCamera();
    }

    prevMouseX = e.screenX;
    prevMouseY = e.screenY;
  }

  return { camera, onMouseDown, onMouseUp, onMouseMove, updateCamera };
}
