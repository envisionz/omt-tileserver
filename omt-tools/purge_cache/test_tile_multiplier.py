from purge_cache import TileMultiplier

valid_tiles = {
    '18/257820/162019': set()
}

def test_below_zoom():
    tm = TileMultiplier()
    tm.multiply_tile('8/128/128')
    assert len(tm.tile_set) == 0

def test_above_zoom():
    tm = TileMultiplier()
    tm.multiply_tile('24/128/128')
    assert len(tm.tile_set) == 0
