#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

from pprint import pprint
import argparse

import numpy as np
import pandas as pd
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import AdaBoostRegressor
from sklearn.preprocessing import Imputer

from lib.windowing import windowing
from lib.mape import mapes
from lib.plot import plot_result


def decision_tree():
    return DecisionTreeRegressor(max_depth=4)


def adaboost_r2():
    rng = np.random.RandomState(1)
    return AdaBoostRegressor(DecisionTreeRegressor(max_depth=4),
                             n_estimators=300, random_state=rng)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('rating_file', help='rating file path', type=str)
    parser.add_argument('window_len', help='window length', type=int)
    args = parser.parse_args()
    rating_filepath = args.rating_file
    window_len = args.window_len

    # Read the dataset
    data = pd.read_csv(rating_filepath)

    forecast_1 = data.mask(np.isnan(data) == False)
    forecast_2 = data.mask(np.isnan(data) == False)

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

            print "fitting...",
            model_1.fit(train_x, train_y)
            model_2.fit(train_x, train_y)

            print "predicting episode %d..." % test_episode,
            f_1 = model_1.predict(test_x)
            f_2 = model_2.predict(test_x)
            forecast_1[col][test_episode - 1] = f_1
            forecast_2[col][test_episode - 1] = f_2

            print "done!"
        # End of for
    # End of for

    color_mapping = plot_result(data, forecast_1, forecast_2)
    print color_mapping
    pprint(mapes(data, forecast_1, forecast_2))
