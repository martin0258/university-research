#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

import numpy as np


def mape(actual, forecast):
    """Return MAPE."""
    return np.mean(np.abs(actual - forecast) / actual) * 100
