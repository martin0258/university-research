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


if __name__ == '__main__':
    # TODO: remove hard code
    home = expanduser("~")
    data_folder = home + "/Projects/BitBucket/set/data/"
    rating_filename = "Idol_Drama_Ratings.csv"
    rating_filepath = data_folder + rating_filename

    # Read the dataset
    data = pd.read_csv(rating_filepath)

    rng = np.random.RandomState(1)

    actual_ratings = []
    base_forecasts = []
    ada_forecasts = []
    drama_names = []
    for col in data.columns:
        # Decode before printing for window cmd
        ratings = data[col].values
        w_ratings = windowing(ratings, 4)

        # Deal with missing values
        imp = Imputer(missing_values='NaN', strategy='mean', axis=0)
        new_w_ratings = imp.fit_transform(w_ratings)

        X = new_w_ratings[:, :-1]
        y = new_w_ratings[:, -1:].ravel()

        actual_ratings.append(y)
        drama_name = col.decode("utf-8")
        drama_names.append(drama_name)
        print drama_name, ':',

        clf_1 = DecisionTreeRegressor(max_depth=4)
        clf_2 = AdaBoostRegressor(DecisionTreeRegressor(max_depth=4),
                                  n_estimators=300, random_state=rng)
        print "training...",
        clf_1.fit(X, y)
        clf_2.fit(X, y)

        print "predicting...",
        y_1 = clf_1.predict(X)
        y_2 = clf_2.predict(X)
        base_forecasts.append(y_1)
        ada_forecasts.append(y_2)

        print "done!\n",
        # End of for

    # Plot result
    ncols = 4
    nfigures = len(actual_ratings)
    nrows = ceil(float(nfigures) / ncols)
    fig = pl.figure()
    title = 'AdaBoost.R2 with Decision Tree Regression\n' + \
            '(X-axis=Episode; Y-axis=Ratings)'
    pl.suptitle(title)
    for i in range(nfigures):
        mapes = 'MAPE\nitr_1: %.2f\nitr_300: %.2f' % \
                (mape(actual_ratings[i], base_forecasts[i]),
                 mape(actual_ratings[i], ada_forecasts[i]))
        ax = fig.add_subplot(nrows, ncols, i + 1)
        ax.set_title(drama_names[i], fontname='WenQuanYi Zen Hei')
        ax.text(1, 1, mapes, bbox=dict(facecolor='white', alpha=0.5),
                horizontalalignment='right', verticalalignment='top',
                transform=ax.transAxes)
        ax.plot(actual_ratings[i], label="x")
        ax.plot(base_forecasts[i], label="itr=1")
        ax.plot(ada_forecasts[i], label="itr=300")
        ax.legend(loc='lower right', fontsize='small',
                  framealpha=0.5, shadow=True, fancybox=True)
    pl.show()
