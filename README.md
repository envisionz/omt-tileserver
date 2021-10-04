# OMT-Tileserver

Set up a vector and raster tileserver based on OpenMapTiles schema and styles. It has been inspired by [Makina Mapps](https://github.com/makina-maps/makina-maps), although with a somewhat different approach taken.

The goal of OMT-Tileserver is to be completely self-contained. The stack can be brought up without any preparation required on the host.

## Features
- Self contained. No preparations on host required before use.
- Bind mount host volumes not required. All volumes can be named volumes.
- Automatically download and import OpenStreetMap extract from Geofabrik on first run.
- Daily updates from Geofabrik automatically setup.
- Serves raster and vector tiles, and vector styles and fonts.
    - Includes the following OpenMapTiles styles:
        - Dark Matter
        - Maptiler Basic
        - Maptiler Terrain
        - OSM Bright
        - OSM Liberty
        - Positron
    - Raster tiles and vector styles/fonts served by tileserver-gl
    - Vector tiles served by postserve
- Vector and raster tiles are cached using Varnish cache
    - Expired tiles from cache are purged after automatic OSM update
