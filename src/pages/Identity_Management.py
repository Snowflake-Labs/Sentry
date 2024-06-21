"""Contains tiles reporting on Identity Management."""

from toolz import pipe
from toolz.curried import map

from common.tiles import IdentityManagementTiles, render
from common.utils import sidebar_footer

# Before the tiles so it renders first
sidebar_footer()

pipe(IdentityManagementTiles, map(render), list)
