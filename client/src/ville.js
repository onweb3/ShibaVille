export function createVille() {
  const lands = []; // this data should be fetched from the chromia blockchain
  init();
  function init() {
    // for now we use a temp data to build an MVP to see how the ville looks
    // We do the same thing as create_ville operation here. (10x10 grid)
    for (let x = 0; x < 10; x++) {
      const column = [];
      for (let y = 0; y < 10; y++) {
        const land = { x, y };
        column.push(land);
      }
      lands.push(column);
    }
  }

  return lands;
}
