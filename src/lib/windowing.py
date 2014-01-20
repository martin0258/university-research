#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

import numpy as np


def windowing(arr, window_len):
    """Perform time series windowing transformation."""
    num_cases = len(arr) - window_len + 1
    cases = [arr[i:(i + window_len)] for i in range(num_cases)]
    return np.array(cases)
