"""Contains tiles reporting on Privileged Access."""

from toolz import pipe
from toolz.curried import map

from common.tiles import May30TTPsGuidanceTiles, render

pipe(May30TTPsGuidanceTiles, map(render), list)
