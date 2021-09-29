#!/usr/bin/env python3

import argparse
import re
import time

from pathlib import Path
import requests
from requests import Response
from requests.exceptions import RequestException

class TileMultiplier:
    """Generate unique list of map tiles from single map tiles

    This is a direct port of 'tile_multiplyer.py' from Makina Maps, which
    is provided under the BSD 3-Clause license.

    Copyright (c) 2021 - Sherman Perry
    Copyright (c) 2019 - 2021 Makina Corpus
    """

    class MultiplierError(Exception):
        pass

    tile_re = re.compile(r'[0-9]{1,2}/[0-9]+/[0-9]+')
    def __init__(self, min_zoom: int = 12, max_zoom: int = 20):
        """Initialise TileMultiplier

        Args:
            min_zoom (int, optional): Min zoom level to generate tile list for. Defaults to 12.
            max_zoom (int, optional): Max zoom level to generate tile list for. Defaults to 20.
        """
        self.min_zoom = min_zoom
        self.max_zoom = max_zoom
        self.tile_set: set[str] = set()

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
            raise TileMultiplier.MultiplierError('Invalid tile string format')

        z, x, y = [int(i) for i in tile.split('/')]
        
        # Don't process tiles outside of the min-max zoom level range
        if z < self.min_zoom or z > self.max_zoom:
            raise TileMultiplier.MultiplierError('Tile outside zoom level range')
        
        # Also don't process tiles that have x and y coords out of range for their zoom level
        if not self._validate_range(z, x, y):
            raise TileMultiplier.MultiplierError('Tile coordinates outside range for specified zoom level')

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

class CachePurger:
    def __init__(self, varnish_url: str="http://localhost/", rate: int=5000) -> None:
        self.varnish_url=varnish_url
        self.purge_req: int = 0
        self.cache_n_gone: int = 0
        self.req_delta: float = 1 / rate
    
    def purge_tile(self, tile: str):
        # a crude form of throttling, good enough for this purpose
        time.sleep(self.req_delta)
        headers = {'xkey': tile}
        r = requests.request('PURGE', self.varnish_url, headers=headers)
        if r.status_code == 200:
            self.purge_req += 1
            if 'n-gone' in r.headers:
                self.cache_n_gone += int(r.headers['n-gone'])
    
    def report(self) -> str:
        return f'Purge req sent: {self.purge_req} - Objs removed: {self.cache_n_gone}'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-z', '--min-zoom', type=int, default=12, help='Minimum zoom level')
    parser.add_argument('-Z', '--max-zoom', type=int, default=18, help='Maximum zoom level')
    parser.add_argument('-v', '--varnish-host', default='http://localhost/', help='Varnish server to send purge requests to')
    parser.add_argument('file',nargs='+', help='File containing list of tiles to expire from imposm3')
    args = parser.parse_args()
    files = sorted(args.file)
    purger = CachePurger(args.v)
    for file in files:
        p = Path(file)
        tm = TileMultiplier(args.z, args.Z)
        try:
            with p.open() as f:
                for line in f:
                    try:
                        tm.multiply_tile(line.rstrip())
                    except TileMultiplier.MultiplierError as m_err:
                        print(m_err)
            for t in tm.tile_set:
                try:
                    purger.purge_tile(t)
                except RequestException as req_err:
                    print(req_err)
        except OSError as os_err:
            print(os_err)
    print(purger.report())

if __name__ == '__main__':
    main()
