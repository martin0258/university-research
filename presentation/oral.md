% TV Ratings Prediction with Time Weighting Based Regression
% Ting-Wei Ku (Martin)
% Feb 2, 2015

# Thesis Goal: Solve the Problem of TV Ratings Prediction

## Thesis Goal: Solve the Problem of TV Ratings Prediction

\note{
We can add speaker note here.
}

# Solution: Time Weighting Based Regression (TWR)

## What is TWR?

## Why TWR?

## How does TWR work?

# Related Work

# Experiments

## Data Set
![Box plots of ratings](../images/Box plots of Idol Dramas Ratings.png)

# Conclusion

## Code example

``` {.r}
if (weight_type == 'equal') {
  # this is known as bagging
  case_weights <- rep(1 / num_cases, num_cases)
} else if (weight_type == 'linear') {
  case_weights <- seq(1, num_cases)
} else if (weight_type == 'exp') {
  case_weights <- exp(1:num_cases)
} else if (weight_type == 'exp3') {
  alpha <- 3
  case_weights <- (exp(1)^alpha)^(1:num_cases)
} else {
  # decide weight type automatically via validation error  
}
```

