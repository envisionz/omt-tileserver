from purge_cache import TileMultiplier

valid_tiles_set_len = {
    '14/16117/10127': 5463
}

tile_format_str = {
    '14/16117/10127': True,
    '125/1234/5678': False,
    'a/1234/5678': False,
    'a/b/c': False,
    '-3/4567/890': False,
}

ranges = {
    (3, 9, 7): False,
    (3, 6, 7): True,
    (3, 5, 9): False,
}

def test_below_zoom():
    tm = TileMultiplier()
    tm.multiply_tile('8/128/128')
    assert len(tm.tile_set) == 0

def test_above_zoom():
    tm = TileMultiplier()
    tm.multiply_tile('24/128/128')
    assert len(tm.tile_set) == 0

def test_valid_set_len():
    for tile, set_len in valid_tiles_set_len.items():
        tm = TileMultiplier()
        tm.multiply_tile(tile)
        assert len(tm.tile_set) == set_len

def test_tile_str_format():
    for fmt, valid in tile_format_str.items():
        tm = TileMultiplier()
        assert(tm._validate_tile_str(fmt) == valid)

def test_range_validation():
    for r, valid in ranges.items():
        tm = TileMultiplier()
        assert(tm._validate_range(r[0], r[1], r[2]) == valid)
