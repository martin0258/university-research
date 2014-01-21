#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

from math import ceil

import pylab as pl
import matplotlib as mpl


def plot_result(actual, *args):
    """Plot actual data with one or more forecast.

    Args:
        actual: the actual data.
        args: the forecasts.
    Returns:
        a dictionary containing color mapping.

    """
    ncols = 4
    nfigures = len(actual.columns)
    nrows = ceil(float(nfigures) / ncols)

    mapping = {}
    mapping['color'] = mpl.rcParams['axes.color_cycle']

    fig = pl.figure()
    subplot_index = 0
    for col in actual.columns:
        subplot_index += 1
        ax = fig.add_subplot(nrows, ncols, subplot_index)
        ax.set_title(str(subplot_index))
        ax.plot(actual[col])
        for forecast in args:
            ax.plot(forecast[col])
    pl.show()
    return mapping
