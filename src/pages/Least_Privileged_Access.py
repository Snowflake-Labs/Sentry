"""Contains tiles reporting on Least Privileged Access."""

from toolz import pipe
from toolz.curried import map

from common.tiles import LeastPrivilegedAccessTiles, render

pipe(LeastPrivilegedAccessTiles, map(render), list)
