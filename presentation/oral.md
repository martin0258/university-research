---
author:
- Student — Ting-Wei Ku (Martin) \newline\newline
- Advisor — Prof. Shou-De Lin \newline\newline
- Committee — Prof. Pu-Jen Cheng, Ph.D. Cheng-Te Li
title: TV Ratings Prediction with \newline Time Weighting Based Regression
subtitle: Master Thesis Defense
date: Feb 2, 2015
institute: National Taiwan University \newline Department of Computer Science & Information Engineering \newline Machine Discovery & Social Network Mining Lab
...

# Thesis Goal: Improve TV Ratings Prediction with X (TWR!)

## Why TV ratings prediction?

It is an important, complex, real-world problem with money.

- It's important because TV ratings decide **price of advertising time**.
- It's complex because...
    - TV ratings are **aggregate** measure of **many people's choices**.
    - TV is **competing** with many platforms/services (mobile/YouTube).

## What TV ratings to predict/improve?

- **Data set**: 8 weekly dramas, 170 ratings
- Predict next ratings of each drama
- Start making predictions from the 6th episode

\note{
Why only 8 dramas?
Why weekly dramas?
Why start from the 6th episode?
}

## Time Series Plot of Data Set
![Time series plot of ratings](../images/ratings-of-idol-dramas.png)

## Box Plot of Data Set
![Box plot of ratings](../images/Box plots of Idol Dramas Ratings.png)

## Basic Info of Data Set

## Observations of Data Set

# Related Work

## TV Ratings Prediction

\note{
We can add speaker note here.
}

# Solution: Time Weighting Based Regression (TWR)

## What is TWR?

## Why TWR?

## How does TWR work?

# Experiments

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

---
\begin{center}
  \Large{Thank you! Any question?}
\end{center}
