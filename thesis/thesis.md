國立臺灣大學電機資訊學院資訊工程學系

碩士論文

Department of Computer Science and Information Engineering

and Computer Science

Master Thesis

以基於時間比重之回歸預測電視收視率

TV Ratings Prediction with Time Weighting Based Regression

顧廷緯

Ting-Wei Ku

指導教授：林守德 博士

Advisor: Shou-De Lin, Ph.D.

中華民國104年1月
Jan 2015

國立臺灣大學電機資訊學院資訊工程學系

碩士論文

Department of Computer Science and Information Engineering College of Electrical Engineering and Computer Science

National Taiwan University

Master Thesis

以基於時間比重之回歸預測電視收視率

TV Ratings Prediction with Time Weighting Based Regression

顧廷緯

Ting-Wei Ku

> 指導教授﹕林守德 博士

Advisor: Shou-De Lin, Ph.D.

中華民國 104 年 1 月

Jan 2015

*
*

國立臺灣大學（碩）博士學位論文

口試委員會審定書

以基於時間比重之回歸預測電視收視率
TV Ratings Prediction with Time Weighting Based Regression

本論文係顧廷緯君（r01922060）在國立臺灣大學資訊工程學系、所完成之碩士學位論文，於民國104年1月30日承下列考試委員審查通過及口試及格，特此證明

口試委員：

> *　　　　　　　　　　　　　　　　（簽名）*
> （指導教授）
>
> *　　　　　　　　* *　　　　　　　　 *
>
> *　　　　　　　　* *　　　　　　　　 *
>
> *　　　　　　　　* *　　　　　　　　 *
>
> *　　　　　　　　* *　　　　　　　　 *

系主任、所長 *　　　　　　　　　　　（簽名）*

（是否須簽章依各院系所規定）

誌謝
====

Many thanks to the following people that help me complete this research:

-   Shou-De Lin

-   Yu-Yang Hung

-   Yu-An Yen

-   Tim Chen

-   Eric Yang

I also want to thank my parents who gave me the freedom to complete research at my own pace. Finally, thank God for giving my opportunity to meet all the people above.

中文摘要
========

此論文主要貢獻為提出一個簡單且實驗結果準確的電視收視率預測方法，名為 Time Weighting Regression (TWR)。基於「越新的資料對預測接續的收視率越重要」的假設，TWR 唯一做的事情為：賦予資料符合假設的權重，然後用賦予權重後的資料建立回歸模型。以真實世界的電視收視率資料進行實驗，其預測準度贏過許多有名的時間序列模型（例如 Exponential Smoothing 和 ARIMA）。

關鍵詞：時間序列預測、電視收視率預測、回歸。

英文摘要
========

In this thesis, the primary contribution is proposing a simple and experimentally accurate solution, named Time Weighting Regression (TWR), to the problem of TV ratings prediction. Based on the assumption that newer data are more important for predicting ratings, the only thing that TWR does is: weighing data based on time, and then building regression model with the weighted data. In the experiments on a real-world TV ratings data set, it outperforms many well-known time series models (e.g., Exponential Smoothing and ARIMA).

Keywords: time series prediction, TV ratings prediction, regression.

目錄
====

口試委員會審定書……………………………………………………………… i

誌謝………………………………………………………………………………. ii

中文摘要………………………………………………………………………… i ii

英文摘要…………………………………………………………………………. iv

第一章 Introduction…………………………………………………………….. 1

> 1.1 Importance of TV ratings prediction
>
> 1.2 Contribution and solution overview

第二章 Related Work……………………………………………………….. \#

第三章 Method……………………………………………………………….. \#

第四章 Experiments………………………………………………………….. \#

第五章 Conclusion…………………………………………………………….. \#

第六章 Future Work…………………………………………………………….. \#

參考文獻…………………………………………………………………….…… \#

附錄………………………………………………………………………………. \#

圖目錄（待放）
==============

表目錄（待放）
==============

第一章 Introduction
===================

1.1 Importance of TV ratings prediction
---------------------------------------

In TV industry, because the price of advertising time is mainly defined as ratings, predicting ratings accurately is very important to broadcasters and advertisers. That is, accurate predictions help them make money, while inaccurate predictions cause money loss. However, as more and more channels, programs and platforms (e.g., Internet, tablet, and mobile phone) appear, the complexity of broadcasting and viewing environment increases, which makes accurately predicting TV ratings increasingly complex. In sum, solving this complex ratings prediction problem help TV industry make money and reduce loss.

1.2 Solution overview
---------------------

TV ratings prediction can be viewed as time series forecasting. The solutions to time series forecasting can be divided into two main categories: time series models (e.g., ARIMA) and regression models (e.g., neural network). Our proposed solution (TWR) falls into the latter. Details of TWR are described in section 3.

1.3 Problem settings
--------------------

Gradually making one-step forecasts for newer periods.

第二章 Related Work
===================

第三章 Method
=============

In this section, we describe our proposed solution (TWR) in detail. As every learning algorithm, TWR consists of two stages: fitting and predicting, i.e., building model with training data and making prediction on testing data with trained model.

For fitting, it consists of three main steps: (1) transforming a time series into a set of training instances with a window size (this step is known as windowing transformation), (2) weighing training instances with a time-based growth function, and finally (3) building a model for one-step forecasting with a base learning algorithm (like decision tree) and weighted training instances.

For predicting, it makes a one-step forecast by providing trained model with input features from training data. Multi-step forecasts are computed recursively, e.g., taking one-step forecast as input to make the second-step forecast.

In the following sub-sections, we provide pseudo-code and describe each stage and step in detail.

3.1 Pseudo-code of Time Weighting Algorithm
-------------------------------------------

Input data: A time series **x** with length **t**

Parameter: Window size **w**, growth function **f**, a base algorithm **Learner** with its parameters **p**

(For illustration, let **n** = 5, **w** = 3, **f** = e<sup>x</sup>, where e<sup>x</sup> is the exponential function.)

Fitting process:

1.  Windowing transformation with window size **w**:
    **x** = { x<sub>1</sub>, x<sub>2</sub>,..., x<sub>5</sub> } **X** = { **w<sub>1</sub>** = (x<sub>1</sub>, x<sub>2,</sub> x<sub>3</sub>=y<sub>3</sub>), (x<sub>2</sub>, x<sub>3</sub>, x<sub>4</sub>=y<sub>4</sub>), (x<sub>3,</sub> x<sub>4</sub>, x<sub>5</sub>=y<sub>5</sub>) }
    We get 3 training instances, with each having 2 input features and 1 label.

2.  Weighing training instances with growth function **f**: **W** = { e, e<sup>2</sup>, e<sup>3</sup> }

3.  Building a base model with weighted instances: **m** = **Learner.Fit**(**X**, **W**, **p**)

Output: base model **m**

Predicting process: Input data **w<sub>4</sub>** = (x<sub>4</sub>, x<sub>5</sub>, x<sub>6</sub>=y<sub>6</sub>), where x<sub>6</sub>=y<sub>6</sub> is the unknown label to predict.

Output: one-step forecast **x<sub>6</sub>’** = **Learner.Predict**(**m**, **w<sub>4</sub>**)

3.2 Fitting step 1: Windowing transformation
--------------------------------------------

Windowing transformation is needed to apply regression models to time series forecasting. This process has 1 parameter: window size. It can be decided either by user or model-selection techniques such as AIC (Akaike information criterion) or cross-validation.

3.3 Fitting step 2: Weighing training instances
-----------------------------------------------

Mathematically speaking, because there are infinite “strictly increasing” functions, there are infinite growth functions that match our assumption, i.e., the newer, the more important. Take illustration in 3.1 for example, importance order is w<sub>1</sub> \< w<sub>2</sub> \< w<sub>3</sub>. So, what is the best growth function and how to find it from infinite possibilities? We define the best growth function as the one that minimizes the testing error of one-step forecast, and we start from studying some well-known types of growth functions: **linear** (x = { 2, 4, 6,… }), **exponential** (e<sup>x</sup> ), and **cubic exponential** (e<sup>3x</sup>) growth. Because testing data/error is unknown during training, we choose the growth function that minimizes the validation error of one-step forecast.

Although other growth functions should be considered, there is a technique that can narrow down the search space: resampling. By resampling training instances with given weights as probability (sampling with replacement), many weights assignments actually produce the same resampling result in most cases. For example, 10x and 11x produces probability p<sup>10</sup> = { 0.09%, 0.9%, 9%, 90% }, p11 = { 0.06%, 0.75%, 8.26%, 90.9% }, respectively. For a time series of length 20 (average of our data set for experiment), the maximum number of training instances is 19. By resampling them with p10 and p11, it is very likely that their results have little or no difference (sample the last instance with over 90%).

Resampling implements weighting step at data level instead of learning algorithm level, which has the benefit of combing with any base algorithm. However, it introduces randomness, so reduce the variance by applying bagging, i.e., we repeat the iteration of this step and step of building a base model over many runs (20 times in our experiment).

3.4 Fitting step 3: Building a base model
-----------------------------------------

We choose regression tree (regression version of decision tree) as our base model because it is sensitive to different data distribution.

3.5 Predicting stage of TWR
---------------------------

Taking average of predictions from multiple base models.

第四章 Experiments
==================

In this section, we describe data set, evaluation metric, models, and results.

4.1 Data set
------------

Our data set contains 8 weekly Idol dramas broadcasting in Taiwan. Historical ratings of the drama itself are the only data used to predict future ratings. For each drama, the testing data set consists of the rating of the 6<sup>th</sup> episode to the last one. For each testing episode, all historical ratings of the drama are used for training (and validation for choosing parameters). To sum, this experiment scenario is of sequential one-step forecast. Summary for the data set is represented via Table 1 and Figure 1.

Table 1. Basic information about dramas

|              | D1      | D2      | D3      | D4     | D5     | D6      | D7      | D8      |
|--------------|---------|---------|---------|--------|--------|---------|---------|---------|
| \#Episode    | 16      | 25      | 22      | 21     | 21     | 19      | 23      | 23      |
| Start(Y/M/D) | 13/2/28 | 11/8/21 | 12/2/19 | 13/1/6 | 13/6/9 | 10/12/5 | 10/11/5 | 12/7/22 |
| Avg          | 0.21    | 5.12    | 2.38    | 1.57   | 2.16   | 1.10    | 3.36    | 3.47    |
| Std          | 0.08    | 1.09    | 0.16    | 0.23   | 0.30   | 0.21    | 2.75    | 0.56    |

Figure 1. Time series plot for ratings of dramas

![](media/image1.png)

4.2 Evaluation metric
---------------------

We evaluate performance via 2 commonly used metrics in literature: mean absolute percentage error (MAPE) and mean absolute error (MAE).

4.3 Models
----------

We choose 7 competitors from 3 categories: (1) naïve guess, (2) well-known time series models, and (3) advance regression model. The 4<sup>th</sup> category is our proposed solution with different growth function settings. All models are summarized in Table 2.

Table 2. List of models

| \#  | Category | Name                                    | Summary                              |
|-----|----------|-----------------------------------------|--------------------------------------|
| 1   | 1        | Last period (LP)                        | Guess value of the last period       |
| 2   | 1        | Past average (PA)                       | Guess average of all the previous    |
| 3   | 2        | Simple Exponential Smoothing (SES)      | Package: HoltWinters {stats}         |
| 4   | 2        | Double Exponential Smoothing (DES)      | Package: HoltWinters {stats}         |
| 5   | 2        | Exponential Smoothing State Space (ETS) | Package: ets {forecast}              |
| 6   | 2        | ARIMA                                   | Package: auto.arima {forecast}       |
| 7   | 3        | Neural network auto-regression (NNA)    | Package: nnetar {forecast}           |
| 8   | 4        | TWR with no growth (TWR.N)              | It equals to no TWR tuning.          |
| 9   | 4        | TWR with linear growth (TWR.L)          | g(x) = x                             |
| 10  | 4        | TWR with exponential growth (TWR.E)     | g(x) = e<sup>x</sup>                 |
| 11  | 4        | TWR with e<sup>3x</sup> growth (TWR.E3) | g(x) = e<sup>3x</sup>                |
| 12  | 4        | TWR with auto-selected growth (TWR.A)   | Pick growth with min validation err. |

4.4 Results
-----------

In this section, we show results of models and dramas in terms of MAPE and MAE. The results show that TWR with auto-selected growth outperforms all the other models in terms of overall MAPE and MAE among all dramas.

Table 3. MAPE

| M↓D→   | D1     | D2     | D3     | D4     | D5     | D6     | D7     | D8     | All        |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|------------|
| LP     | 0.2427 | 0.0853 | 0.0859 | 0.1395 | 0.1265 | 0.1263 | 0.1307 | 0.0898 | 0.1218     |
| PA     | 0.6017 | 0.1937 | 0.0647 | 0.1072 | 0.1398 | 0.2077 | 0.4609 | 0.1375 | 0.2248     |
| SES    | 0.3247 | 0.0821 | 0.0633 | 0.1194 | 0.1235 | 0.1257 | 0.1307 | 0.0890 | 0.1222     |
| DES    | 0.3016 | 0.0841 | 0.0688 | 0.1859 | 0.1515 | 0.1266 | 0.1215 | 0.1322 | 0.1377     |
| ETS    | 0.4039 | 0.0912 | 0.0649 | 0.1067 | 0.1222 | 0.1350 | 0.1330 | 0.0894 | 0.1302     |
| ARIMA  | 0.3412 | 0.0834 | 0.0718 | 0.1072 | 0.1302 | 0.1301 | 0.1358 | 0.0958 | 0.1264     |
| NNA    | 0.5536 | 0.0922 | 0.0765 | 0.1252 | 0.1246 | 0.1378 | 0.1171 | 0.1081 | 0.1478     |
| TWR.N  | 0.5693 | 0.1475 | 0.0649 | 0.1282 | 0.1343 | 0.1761 | 0.3659 | 0.1151 | 0.1972     |
| TWR.L  | 0.4423 | 0.1130 | 0.0661 | 0.1188 | 0.1241 | 0.1543 | 0.2751 | 0.1112 | 0.1635     |
| TWR.E  | 0.2560 | 0.0765 | 0.0791 | 0.1193 | 0.1122 | 0.1269 | 0.1588 | 0.0852 | 0.1197     |
| TWR.E3 | 0.2428 | 0.0839 | 0.0842 | 0.1358 | 0.1255 | 0.1263 | 0.1334 | 0.0884 | 0.1209     |
| TWR.A  | 0.2547 | 0.0786 | 0.0759 | 0.1081 | 0.1211 | 0.1167 | 0.1344 | 0.0897 | **0.1154** |

Table 4. MAE

| M↓D→   | D1     | D2     | D3     | D4     | D5     | D6     | D7     | D8     | All        |
|--------|--------|--------|--------|--------|--------|--------|--------|--------|------------|
| LP     | 0.0518 | 0.4775 | 0.1965 | 0.2250 | 0.2569 | 0.1286 | 0.5950 | 0.3272 | 0.3044     |
| PA     | 0.0882 | 1.1048 | 0.1439 | 0.1681 | 0.2764 | 0.1900 | 2.3341 | 0.4646 | 0.6589     |
| SES    | 0.0598 | 0.4604 | 0.1410 | 0.1909 | 0.2520 | 0.1280 | 0.5950 | 0.3202 | 0.2893     |
| DES    | 0.0627 | 0.4644 | 0.1589 | 0.2880 | 0.3158 | 0.1370 | 0.5679 | 0.4904 | 0.3331     |
| ETS    | 0.0686 | 0.5068 | 0.1447 | 0.1675 | 0.2504 | 0.1381 | 0.6249 | 0.3213 | 0.3000     |
| ARIMA  | 0.0576 | 0.4573 | 0.1608 | 0.1681 | 0.2628 | 0.1318 | 0.6124 | 0.3412 | 0.2955     |
| NNA    | 0.0955 | 0.5232 | 0.1731 | 0.1943 | 0.2442 | 0.1348 | 0.5031 | 0.3669 | 0.3002     |
| TWR.N  | 0.0836 | 0.8287 | 0.1444 | 0.1973 | 0.2644 | 0.1606 | 1.6678 | 0.3880 | 0.5122     |
| TWR.L  | 0.0695 | 0.6435 | 0.1480 | 0.1854 | 0.2458 | 0.1441 | 1.1960 | 0.3714 | 0.4099     |
| TWR.E  | 0.0510 | 0.4335 | 0.1800 | 0.1915 | 0.2286 | 0.1283 | 0.6919 | 0.3035 | 0.2979     |
| TWR.E3 | 0.0515 | 0.4699 | 0.1928 | 0.2190 | 0.2550 | 0.1288 | 0.6055 | 0.3208 | 0.3023     |
| TWR.A  | 0.0497 | 0.4429 | 0.1712 | 0.1756 | 0.2440 | 0.1173 | 0.6094 | 0.3248 | **0.2883** |

第五章 Conclusion
=================

In this thesis, we present a novel solution called TWR to the problem of TV ratings prediction problem. Experiment results show that the auto-selected growth version of TWR outperforms all the other models in terms of overall MAPE and MAE among all dramas.

第六章 Future Work
==================
