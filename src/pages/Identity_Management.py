"""Contains tiles reporting on Identity Management."""

from toolz import pipe
from toolz.curried import map

from common.tiles import IdentityManagementTiles, render

pipe(IdentityManagementTiles, map(render), list)
