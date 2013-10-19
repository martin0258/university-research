
<!-- saved from url=(0126)https://bitbucket.org/martin0258/set/raw/dbff958486b589e882a228486599ab3098b82a47/presentation/20130917%20Progress%20Report.md -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">title: Forecast TV Drama Ratings
controls: false

--

# 
## Forecast TV Drama Ratings via Time Series Methods

--

### Data (TV Drama Ratings)
7 Chinese dramas:

* 真愛找麻煩
* 剩女保鏢   
* 愛上巧克力 
* 我們發財了 
* 美味的想念 
* 兩個爸爸   
* 幸福選擇題 

**Average time series length**: 78 (episodes)

--

### Forecast Goal
Minimize MAPE of 1-step forecast.

--

### Baseline Approach
Average previous N ratings.

**Example**: 1, 2, (1+2)/2,...

--

### Time Series Models
1. Autoregressive (AR)
2. Autoregressive Integrated Moving Average (ARIMA)
3. Exponential Smoothing (ES)
4. Exponential Smoothing State Space

--

### Time Series Analysis
1. Decomposition
2. Autocorrelation

--

### Time Series Decomposition
Assume an additive model, *Y(t) = S(t) + T(t) + E(t)*

Assume an multiplicative model, *Y(t) = S(t) ×T(t) ×E(t)*

* **Y(t)**: a time series
* **S(t)**: a seasonal component
* **T(t)**: a trend-cycle component
* **E(t)**: a remainder component (anything else)

**Choice**: which models to use depends on the magnitude of S(t) and T(t).

--

### How to Extract Each Component?
**STL**: Seasonal and Trend decomposition using Loess

**Problems**: An error occurs when Y(t)....

1. Has missing values
2. Is not periodic or has less than two periods

--

### Experiment Results
[Link to Spreadsheet](http://goo.gl/1DpcqE)

--

### Ensemble Approach
MAPE model selection (I call it **Dispatcher**).

Can also apply to single model parameter tuning (e.g., average N)?
</pre></body></html>