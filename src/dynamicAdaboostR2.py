#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

from os.path import expanduser
from math import ceil

import numpy as np
import pandas as pd
import pylab as pl
import matplotlib
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import AdaBoostRegressor
from sklearn.preprocessing import Imputer

from lib.windowing import windowing
from lib.mape import mape


def decision_tree():
    return DecisionTreeRegressor(max_depth=4)


def adaboost_r2():
    rng = np.random.RandomState(1)
    return AdaBoostRegressor(DecisionTreeRegressor(max_depth=4),
                             n_estimators=300, random_state=rng)


if __name__ == '__main__':
    # TODO: remove hard code
    home = expanduser("~")
    data_folder = home + "/Projects/BitBucket/set/data/"
    rating_filename = "Idol_Drama_Ratings.csv"
    rating_filepath = data_folder + rating_filename
    window_len = 4

    # Read the dataset
    data = pd.read_csv(rating_filepath)

    # Loop through each drama
    for col in data.columns:
        ratings = data[col].values
        w_ratings = windowing(ratings, window_len)

        # FIXME: the actual num of episodes should come from drama definition
        num_episodes = np.max(np.where(np.isnan(ratings) == False))
        num_cases = num_episodes - window_len + 1
        # Loop through each episode to be predicted
        for test_index in range(1, num_cases):
            test_episode = test_index + window_len

            # Deal with missing values
            # TODO: Survey specific approach for time series data
            imp = Imputer(missing_values='NaN', strategy='mean', axis=0)
            new_w_ratings = imp.fit_transform(w_ratings[:test_index + 1])

            train_x = new_w_ratings[:test_index, :-1]
            train_y = new_w_ratings[:test_index, -1:].ravel()
            # Must use a 2-dim array for AdaBoostRegressor.predict()
            test_x = np.array([new_w_ratings[test_index, :-1]])

            drama_name = col.decode("utf-8")
            print drama_name, ':',

            model_1 = decision_tree()
            model_2 = adaboost_r2()

            print "training...",
            model_1.fit(train_x, train_y)
            model_2.fit(train_x, train_y)

            print "testing episode %d..." % test_episode,
            y_1 = model_1.predict(test_x)
            y_2 = model_2.predict(test_x)

            print "done!\n",
        # End of for
