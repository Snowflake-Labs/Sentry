"""Contains tiles reporting on Identity Management."""

from toolz import pipe
from toolz.curried import map

from common.tiles import SharingTiles, render

pipe(SharingTiles, map(render), list)
