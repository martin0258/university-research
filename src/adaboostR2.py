"""
======================================
Decision Tree Regression with AdaBoost
======================================

A decision tree is boosted using the AdaBoost.R2 [1] algorithm on a 1D
sinusoidal dataset with a small amount of Gaussian noise.
299 boosts (300 decision trees) is compared with a single decision tree
regressor. As the number of boosts is increased the regressor can fit more
detail.

.. [1] H. Drucker, "Improving Regressors using Boosting Techniques", 1997.

"""
print(__doc__)

import numpy as np
import pandas as pd


# Perform time series windowing transformation with numpy.vstack
def windowing(arr, window_len):
  num_cases = len(arr) - window_len + 1
  cases = [arr[i:(i + window_len)] for i in range(num_cases)]
  return np.array(cases)


def train_predict_plot(X, y):
  rng = np.random.RandomState(1)
  # Fit regression model
  from sklearn.tree import DecisionTreeRegressor
  from sklearn.ensemble import AdaBoostRegressor

  clf_1 = DecisionTreeRegressor(max_depth=4)

  clf_2 = AdaBoostRegressor(DecisionTreeRegressor(max_depth=4),
                            n_estimators=300, random_state=rng)

  clf_1.fit(X, y)
  clf_2.fit(X, y)

  # Predict
  y_1 = clf_1.predict(X)
  y_2 = clf_2.predict(X)

  # Plot the results
  import pylab as pl

  pl.figure()
  pl.scatter(X, y, c="k", label="training samples")
  pl.plot(X, y_1, c="g", label="n_estimators=1", linewidth=2)
  pl.plot(X, y_2, c="r", label="n_estimators=300", linewidth=2)
  pl.xlabel("data")
  pl.ylabel("target")
  pl.title("Boosted Decision Tree Regression")
  pl.legend()
  pl.show()


# Read the dataset
from os.path import expanduser
home = expanduser("~")

# TODO: remove hard code
data_folder = home + "/Projects/BitBucket/set/data/"
rating_filename = "Idol_Drama_Ratings.csv"
rating_filepath = data_folder + rating_filename

data = pd.read_csv(rating_filepath)
for col in data.columns:
  # Decode before printing for window cmd
  ratings = data[col].values
  w_ratings = windowing(ratings, 4)
  X = w_ratings[:, :-1]
  y = w_ratings[:, -1:]
  print "training %s..." % col.decode("utf-8"),
  train_predict_plot(X, y)
  print "done"
