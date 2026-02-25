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
