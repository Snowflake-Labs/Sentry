"""Contains tiles reporting on Privileged Access."""

from toolz import pipe
from toolz.curried import map

from common.tiles import May30TTPsGuidanceTiles, render
from common.utils import sidebar_footer

# Before the tiles so it renders first
sidebar_footer()

pipe(May30TTPsGuidanceTiles, map(render), list)
