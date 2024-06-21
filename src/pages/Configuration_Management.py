"""Contains tiles reporting on Configuration Management."""

from toolz import pipe
from toolz.curried import map

from common.tiles import ConfigurationManagementTiles, render
from common.utils import sidebar_footer

# Before the tiles so it renders first
sidebar_footer()

pipe(ConfigurationManagementTiles, map(render), list)
