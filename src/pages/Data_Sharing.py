"""Contains tiles reporting on Identity Management."""

from toolz import pipe
from toolz.curried import map

from common.tiles import SharingTiles, render
from common.utils import sidebar_footer

# Before the tiles so it renders first
sidebar_footer()

pipe(SharingTiles, map(render), list)
