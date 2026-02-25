// Baremaps конфигурация на JavaScript
// Координаты из вашего оригинального config.js
const bbox = {
  minX: 60.2768,
  maxX: 60.8812,
  minY: 56.6769,
  maxY: 56.9579,
};

export default {
  // Источник данных
  sources: {
    osm: {
      type: "pbf",
      url: "./data/sverdlowskaya-oblast-latest.osm.pbf",
    },
  },

  // Векторные слои
  layers: {
    water: {
      source: "osm",
      type: "polygon",
      filter: ["==", "natural", "water"],
      minzoom: 5,
      maxzoom: 14,
    },
    landuse: {
      source: "osm",
      type: "polygon",
      filter: ["has", "landuse"],
      minzoom: 5,
      maxzoom: 14,
      attributes: ["landuse"],
    },
    roads: {
      source: "osm",
      type: "line",
      filter: ["has", "highway"],
      minzoom: 5,
      maxzoom: 14,
      attributes: ["highway", "name"],
    },
    buildings: {
      source: "osm",
      type: "polygon",
      filter: ["has", "building"],
      minzoom: 13,
      maxzoom: 14,
    },
    places: {
      source: "osm",
      type: "point",
      filter: ["has", "place"],
      minzoom: 5,
      maxzoom: 14,
      attributes: ["place", "name"],
    },
  },

  // Настройки экспорта
  export: {
    minzoom: 0,
    maxzoom: 14,
    center: [
      (bbox.minX + bbox.maxX) / 2,
      (bbox.minY + bbox.maxY) / 2,
    ],
    bounds: [bbox.minX, bbox.minY, bbox.maxX, bbox.maxY],
  },
};
