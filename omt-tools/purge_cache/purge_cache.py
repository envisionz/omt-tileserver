#!/usr/bin/env python3

import re

class TileMultiplier:
    """Generate unique list of map tiles from single map tiles

    This is a direct port of 'tile_multiplyer.py' from Makina Maps, which
    is provided under the BSD 3-Clause license.

    Copyright (c) 2021 - Sherman Perry
    Copyright (c) 2019 - 2021 Makina Corpus
    """

    tile_re = re.compile(r'[0-9]{1,2}/[0-9]+/[0-9]+')
    def __init__(self, min_zoom: int = 12, max_zoom: int = 20):
        """Initialise TileMultiplier

        Args:
            min_zoom (int, optional): Min zoom level to generate tile list for. Defaults to 12.
            max_zoom (int, optional): Max zoom level to generate tile list for. Defaults to 20.
        """
        self.min_zoom = min_zoom
        self.max_zoom = max_zoom
        self.tile_set = set()

    def _to_set(self, z: int, x: int, y: int):
        if self.min_zoom <= z <= self.max_zoom:
            tile = f'{z}/{x}/{y}'
            self.tile_set.add(tile)
    
    def _validate_tile_str(self, tile: str) -> bool:
        return TileMultiplier.tile_re.fullmatch(tile) != None
    
    def _validate_range(self, z: int, x: int, y: int) -> bool:
        max = pow(2, z) - 1
        return x <= max and y <= max
    
    def multiply_tile(self, tile: str):
        """Multiply single tile to multiple tiles, and add to 'tile_set'

        Args:
            tile (str): tile in the form of 'z/x/y'
        """

        if not self._validate_tile_str(tile):
            return

        z, x, y = [int(i) for i in tile.split('/')]
        
        # Don't process tiles outside of the min-max zoom level range
        if z < self.min_zoom or z > self.max_zoom:
            return
        
        # Also don't process tiles that have x and y coords out of range for their zoom level
        if not self._validate_range(z, x, y):
            return

        self._to_set(z, x, y)

        xx, yy = x, y
        for zz in range(z - 1, self.min_zoom - 1, -1):
            xx, yy = xx // 2, yy // 2
            self._to_set(zz, xx, yy)

        xx, yy = x, y
        s = 1
        for zz in range(z + 1, self.max_zoom + 1):
            xx, yy = xx * 2, yy * 2
            s *= 2
            for sx in range(0, s):
                for sy in range(0, s):
                    self._to_set(zz, xx+sx, yy+sy)

def main():
    pass

if __name__ == '__main__':
    main()