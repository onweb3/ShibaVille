export function createVille() {
  const lands = []; // this data should be fetched from the chromia blockchain
  init();
  function init() {
    // for now we use a temp data to build an MVP to see how the ville looks
    // We do the same thing as create_ville operation here. (10x10 grid)
    for (let x = 0; x < 24; x++) {
      const column = [];
      for (let y = 0; y < 24; y++) {
        const land = createLand(x, y);
        column.push(land);
      }
      lands.push(column);
    }
  }

  function update() {
    console.log("update ville");
    for (let x = 0; x < lands.length; x++) {
      for (let y = 0; y < lands.length; y++) {
        lands[x][y].update();
      }
    }
  }

  function createLand(x, y) {
    return {
      x,
      y,
      terrainId: "land-empty",
      buildingId: undefined,
      update() {
        const rand = Math.random();
        if (rand < 0.01) {
          if (this.buildingId === undefined) {
            this.buildingId = "buildingId-lvl1";
          } else if (this.buildingId === "buildingId-lvl1") {
            this.buildingId = "buildingId-lvl2";
          } else if (this.buildingId === "buildingId-lvl2") {
            this.buildingId = "buildingId-lvl3";
          }
          //console.log(this.buildingId);
        }
      },
    };
  }

  return { lands, update };
}
