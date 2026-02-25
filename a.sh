#!/bin/bash
set -e

echo "🗺️  Создание проекта карты (Baremaps + PMTiles + GitHub Pages)"
echo "🚀 Используем Node.js конфигурацию вместо Lua"

# Создаем структуру директорий
mkdir -p .github/workflows
mkdir -p public
mkdir -p scripts
mkdir -p baremaps
mkdir -p data

# ============================================
# 1. GitHub Actions Workflow
# ============================================
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: './public'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

# ============================================
# 2. Public index.html
# ============================================
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Карта Свердловской области</title>
    
    <!-- MapLibre GL JS -->
    <script src="https://unpkg.com/maplibre-gl@4.1.2/dist/maplibre-gl.js"></script>
    <link href="https://unpkg.com/maplibre-gl@4.1.2/dist/maplibre-gl.css" rel="stylesheet" />
    
    <!-- PMTiles Protocol -->
    <script src="https://unpkg.com/pmtiles@4.0.0/dist/index.js"></script>

    <style>
        body { margin: 0; padding: 0; }
        #map { position: absolute; top: 0; bottom: 0; width: 100%; }
        .loading {
            position: absolute; top: 10px; left: 10px;
            background: rgba(255,255,255,0.9); padding: 10px;
            border-radius: 4px; z-index: 999;
            font-family: sans-serif; display: none;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <div id="loading" class="loading">Загрузка карты...</div>

    <script>
        // Инициализация протокола PMTiles
        const protocol = new pmtiles.Protocol();
        maplibregl.addProtocol("pmtiles", protocol.tile);

        // Координаты из config.js (Екатеринбург)
        // bbox: minX: 60.2768, maxX: 60.8812, minY: 56.6769, maxY: 56.9579
        const CENTER = [60.579, 56.817]; 
        const ZOOM = 10;

        // Ссылка на PMTiles файл
        const PMTILES_URL = "./map.pmtiles";
        // Для внешнего хранилища (>100MB):
        // const PMTILES_URL = "https://storage.yandexcloud.net/your-bucket/map.pmtiles";

        const map = new maplibregl.Map({
            container: 'map',
            style: './style.json',
            center: CENTER,
            zoom: ZOOM,
            attributionControl: false
        });

        map.addControl(new maplibregl.AttributionControl({ compact: true }));
        map.addControl(new maplibregl.NavigationControl());
        map.addControl(new maplibregl.ScaleControl());

        const loading = document.getElementById('loading');
        map.on('dataloading', () => loading.style.display = 'block');
        map.on('load', () => loading.style.display = 'none');
    </script>
</body>
</html>
EOF

# ============================================
# 3. Public style.json
# ============================================
cat > public/style.json << 'EOF'
{
  "version": 8,
  "name": "Sverdlovsk Map",
  "sources": {
    "pmtiles": {
      "type": "vector",
      "url": "pmtiles://./map.pmtiles",
      "attribution": "© OpenStreetMap contributors"
    }
  },
  "layers": [
    {
      "id": "background",
      "type": "background",
      "paint": { "background-color": "#f8f4f0" }
    },
    {
      "id": "landuse",
      "type": "fill",
      "source": "pmtiles",
      "source-layer": "landuse",
      "paint": { "fill-color": "#d8e8c8" }
    },
    {
      "id": "water",
      "type": "fill",
      "source": "pmtiles",
      "source-layer": "water",
      "paint": { "fill-color": "#a0c8f0" }
    },
    {
      "id": "roads",
      "type": "line",
      "source": "pmtiles",
      "source-layer": "roads",
      "paint": { "line-color": "#ffffff", "line-width": 1.5 }
    },
    {
      "id": "buildings",
      "type": "fill",
      "source": "pmtiles",
      "source-layer": "buildings",
      "paint": { "fill-color": "#d9d0c9", "fill-opacity": 0.7 }
    }
  ]
}
EOF

# ============================================
# 4. Baremaps config.js (Node.js вместо Lua!)
# ============================================
cat > baremaps/config.js << 'EOF'
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
EOF

# ============================================
# 5. Scripts generate-pmtiles.sh (с Baremaps)
# ============================================
cat > scripts/generate-pmtiles.sh << 'EOF'
#!/bin/bash
set -e

echo "🗺️  Генерация PMTiles для Свердловской области (Baremaps + Node.js)"

# Директории
DATA_DIR="./data"
mkdir -p $DATA_DIR

# 1. Скачивание данных (Sverdlovsk region from Geofabrik)
if [ ! -f "$DATA_DIR/sverdlowskaya-oblast-latest.osm.pbf" ]; then
    echo "⬇️  Скачивание OSM данных..."
    wget -O $DATA_DIR/sverdlowskaya-oblast-latest.osm.pbf \
        https://download.geofabrik.de/russia/sverdlowskaya-oblast-latest.osm.pbf
fi

# 2. Проверка Baremaps
if ! command -v baremaps &> /dev/null; then
    echo "❌ baremaps не найден!"
    echo ""
    echo "📦 Установка Baremaps:"
    echo "   Вариант 1 (Linux/Mac):"
    echo "   wget https://dist.apache.org/repos/dist/release/incubator/baremaps/0.7.1/baremaps-0.7.1-incubating-bin.tar.gz"
    echo "   tar -xzf baremaps-0.7.1-incubating-bin.tar.gz"
    echo "   export PATH=\$PATH:./baremaps-0.7.1-incubating-bin/bin"
    echo ""
    echo "   Вариант 2 (Docker):"
    echo "   docker run -v \$(pwd):/app apache/baremaps --help"
    echo ""
    exit 1
fi

echo "✅ Baremaps найден: $(baremaps --version)"

# 3. Генерация тайлов в MBTiles
echo "🔨 Генерация тайлов через Baremaps..."
baremaps map \
    --config baremaps/config.js \
    --output $DATA_DIR/map.mbtiles \
    --minzoom 0 \
    --maxzoom 14

# 4. Проверка pmtiles CLI
if ! command -v pmtiles &> /dev/null; then
    echo "❌ pmtiles CLI не найден!"
    echo "   Установка: go install github.com/protomaps/go-pmtiles@latest"
    echo "   Или скачайте с: https://github.com/protomaps/PMTiles/releases"
    exit 1
fi

# 5. Конвертация в PMTiles
echo "📦 Конвертация в PMTiles..."
pmtiles convert $DATA_DIR/map.mbtiles public/map.pmtiles

# 6. Очистка
rm -f $DATA_DIR/map.mbtiles

# 7. Информация о размере
FILE_SIZE=$(stat -c%s "public/map.pmtiles" 2>/dev/null || stat -f%z "public/map.pmtiles")
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

echo ""
echo "✅ Готово! Файл public/map.pmtiles создан."
echo "📊 Размер файла: ${FILE_SIZE_MB} MB"
echo ""

if [ $FILE_SIZE_MB -gt 100 ]; then
    echo "⚠️  ВНИМАНИЕ: Файл больше 100MB!"
    echo "   GitHub имеет лимит на размер файла в репозитории."
    echo "   Рекомендуется загрузить файл на внешнее хранилище:"
    echo "   - Cloudflare R2 (бесплатно до 10GB)"
    echo "   - AWS S3"
    echo "   - Yandex Object Storage"
    echo ""
    echo "   После загрузки обновите ссылки в:"
    echo "   - public/index.html"
    echo "   - public/style.json"
else
    echo "✅ Файл можно загрузить в репозиторий GitHub"
fi
EOF

chmod +x scripts/generate-pmtiles.sh

# ============================================
# 6. .gitignore
# ============================================
cat > .gitignore << 'EOF'
node_modules/
data/
*.mbtiles
.env
.env.js
.env.example
.DS_Store
public/map.pmtiles
baremaps/baremaps-*/
EOF

# ============================================
# 7. README.md
# ============================================
cat > README.md << 'EOF'
# Карта Свердловской области (Baremaps + PMTiles + GitHub Pages)

Статическая карта Свердловской области на базе OpenStreetMap данных.
**Конфигурация на Node.js/JavaScript** (без Lua!).

## 📋 Требования

1. **Apache Baremaps** - для генерации векторных тайлов
   - Скачать: https://baremaps.apache.org/
   - Или через Docker: `docker run apache/baremaps`

2. **pmtiles CLI** - для конвертации в PMTiles формат
   - Установка: `go install github.com/protomaps/go-pmtiles@latest`
   - Или скачать бинарник с GitHub Releases

## 🚀 Быстрый старт

### 1. Генерация карты

```bash
./scripts/generate-pmtiles.sh