"""Contains tiles reporting on Privileged Access."""

from toolz import pipe
from toolz.curried import map

from common.tiles import PrivilegedAccessTiles, render

pipe(PrivilegedAccessTiles, map(render), list)
