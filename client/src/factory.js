import * as THREE from "three";

const positionFactor = 100;
const geometry = new THREE.BoxGeometry(positionFactor, 1, positionFactor);
const assets = {
  "land-empty": (x, y) => {
    const material = new THREE.MeshLambertMaterial({ color: 0x00aa00 });
    const Landmesh = new THREE.Mesh(geometry, material);
    Landmesh.userData = { id: "land-empty", x, y };
    Landmesh.position.set(x * positionFactor, -0.5, y * positionFactor);
    return Landmesh;
  },
  "land-used": (x, y) => {
    const material = new THREE.MeshLambertMaterial({ color: 0xff0000 });
    const Landmesh = new THREE.Mesh(geometry, material);
    Landmesh.userData = { id: "land-used", x, y };
    Landmesh.position.set(x * positionFactor, -0.5, y * positionFactor);
    return Landmesh;
  },
  "buildingId-lvl1": (x, y) => {
    const Buildingmaterial = new THREE.MeshLambertMaterial({
      color: 0x000500,
    });
    const BuildingMesh = new THREE.Mesh(geometry, Buildingmaterial);
    BuildingMesh.position.set(x * positionFactor, 0.5, y * positionFactor);
    BuildingMesh.userData = { id: "buildingId-lvl1", x, y };
    return BuildingMesh;
  },
  "buildingId-lvl2": (x, y) => {
    const Buildingmaterial = new THREE.MeshLambertMaterial({
      color: 0x000500,
    });
    const BuildingMesh = new THREE.Mesh(geometry, Buildingmaterial);
    BuildingMesh.scale.set(1, 2, 1);
    BuildingMesh.position.set(x * positionFactor, 1, y * positionFactor);
    BuildingMesh.userData = { id: "buildingId-lvl2", x, y };
    return BuildingMesh;
  },
  "buildingId-lvl3": (x, y) => {
    const Buildingmaterial = new THREE.MeshLambertMaterial({
      color: 0x000500,
    });
    const BuildingMesh = new THREE.Mesh(geometry, Buildingmaterial);
    BuildingMesh.scale.set(1, 3, 1);
    BuildingMesh.position.set(x * positionFactor, 1.5, y * positionFactor);
    BuildingMesh.userData = { id: "buildingId-lvl3", x, y };
    return BuildingMesh;
  },
};

export function createAssetInst(assetId, x, y) {
  if (assetId in assets) {
    return assets[assetId](x, y);
  } else {
    console.warn(`assetId ${assetId} is not found in the factory.`);
    return undefined;
  }
}
