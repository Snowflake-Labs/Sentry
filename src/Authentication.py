"""Main entrypoint. Contains tiles reporting on Authentication."""

from toolz import pipe
from toolz.curried import map

from common.tiles import AuthTiles, render
from common.utils import maybe_connect

# NOTE: since this is the main entry point, call to maybe_session ensures that the Snowpark Session is properly
# generated
session = maybe_connect()

pipe(AuthTiles, map(render), list)
