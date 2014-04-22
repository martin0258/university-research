#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

from os.path import expanduser
import pandas as pd
import numpy as np
from sklearn.preprocessing import Imputer
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import AdaBoostRegressor

from lib.windowing import windowing
from lib.mape import mape

def gradual_ts_regression(ts, window_len, estimator):
    """Forecast time series via windowing transformation and regression."""

    # Initialize result
    result = {'Episode': [],
              'Ratings': [],
              'Prediction': [],
              'TestError': [],
              'TrainError': []}

    # Form regression data from time series data
    w_ts = windowing(ts, 4)
    x = w_ts[:, :-1]
    y = w_ts[:, -1:].ravel()

    # Train a model for each time period to predict
    test_start_period = window_len + 1
    test_end_period = len(ts)
    # Loop through each episode to predict
    for test_period in range(test_start_period, test_end_period + 1):
        train_index = range(0, test_period - window_len)
        test_index = train_index[-1] + 1
        ## Train
        estimator.fit(x[train_index, :], y[train_index])
        ## Test
        predict_index = list(train_index) # Copy
        predict_index.append(test_index)
        predict = estimator.predict(x[predict_index, :])
        predict_train = predict[train_index]
        predict_test = predict[test_index]
        ## Evaluate
        train_error = mape(y[train_index], predict_train)
        test_error = mape(y[test_index], predict_test)
        ## Store results
        result['Episode'].append(test_period)
        result['Ratings'].append(y[test_index])
        result['Prediction'].append(predict_test)
        result['TestError'].append(test_error)
        result['TrainError'].append(train_error)
    return result


home = expanduser("~")
data_folder = home + "/Projects/GitHub/ntu-research/data/"
data_filename = "Chinese_Drama_Ratings_AnotherFormat.csv"
if __name__ == '__main__':
    data = pd.read_csv(data_folder + data_filename)
    grouped = data.groupby('Drama')
    # For each drama
    for drama_name, group in grouped:
        print 'processing ' + drama_name + '...',

        ratings = group['Ratings'].values

        # Deal with missing values
        imp = Imputer(missing_values='NaN', strategy='mean', verbose=1, axis=1)
        ratings_no_missing = imp.fit_transform(ratings)[0]

        decision_tree = DecisionTreeRegressor(max_depth=4)
        result = gradual_ts_regression(ratings_no_missing, 4, decision_tree)
        result_mape = mape(result['Ratings'], result['Prediction'])
        print 'Decision Tree MAPE: ', result_mape,

        rng = np.random.RandomState(1)
        ada_decision_tree = AdaBoostRegressor(DecisionTreeRegressor(max_depth=4),
                                              n_estimators=10, random_state=rng)
        result = gradual_ts_regression(ratings_no_missing, 4, ada_decision_tree)
        result_mape = mape(result['Ratings'], result['Prediction'])
        print 'AdaBoostR2 MAPE: ', result_mape
