#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

import numpy as np


def mape(actual, forecast):
    """Return MAPE."""
    actual = np.array(actual)
    forecast = np.array(forecast)
    return np.mean(np.abs(actual - forecast) / actual) * 100


def mapes(actual, *args):
    m = {}
    index = 0
    for col in actual.columns:
        index += 1
        m[index] = []
        for forecast in args:
            m[index].append(mape(actual[col], forecast[col]))
    return m
