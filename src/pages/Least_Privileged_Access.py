"""Contains tiles reporting on Least Privileged Access."""

from toolz import pipe
from toolz.curried import map

from common.tiles import LeastPrivilegedAccessTiles, render
from common.utils import sidebar_footer

# Before the tiles so it renders first
sidebar_footer()

pipe(LeastPrivilegedAccessTiles, map(render), list)
