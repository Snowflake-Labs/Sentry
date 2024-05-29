"""Contains tiles reporting on Privileged Access."""

from toolz import pipe
from toolz.curried import map

from common.tiles import TempTiles, render

pipe(TempTiles, map(render), list)
