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
