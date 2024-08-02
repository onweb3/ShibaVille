export function createVille() {
  const lands = []; // this data should be fetched from the chromia blockchain
  init();
  function init() {
    // for now we use a temp data to build an MVP to see how the ville looks
    // We do the same thing as create_ville operation here. (10x10 grid)
    for (let x = 0; x < 10; x++) {
      const column = [];
      for (let y = 0; y < 10; y++) {
        const land = {
          x,
          y,
          building: undefined,
          update() {},
        };
        if (Math.random() > 0.7) {
          land.building = "building";
        }
        column.push(land);
      }
      lands.push(column);
    }
  }

  function update() {
    console.log(`updating ville`);
    for (let x = 0; x < lands.length; x++) {
      for (let y = 0; y < lands.length; y++) {
        lands[x][y].update();
      }
    }
  }

  return { lands, update };
}
