"""Contains tiles reporting on Configuration Management."""

from toolz import pipe
from toolz.curried import map

from common.tiles import ConfigurationManagementTiles, render

pipe(ConfigurationManagementTiles, map(render), list)
