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
          update() {
            const rand = Math.random();
            if (rand < 0.01) {
              if (this.building === undefined) {
                this.building = "buidling-lvl1";
              } else if (this.building === "buidling-lvl1") {
                this.building = "buidling-lvl2";
              } else if (this.building === "buidling-lvl2") {
                this.building = "buidling-lvl3";
              }
              console.log(this.building);
            }
          },
        };
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

  return { lands, update };
}
