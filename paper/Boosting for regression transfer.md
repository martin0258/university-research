# [Boosting for regression transfer](http://www.cs.utexas.edu/~dpardoe/papers/ICML10.pdf)

## Contribution
It introduces 7 boosting-based algorithms for transfer learning that apply to regression tasks.

7 algorithms categorized into 2 categories:

1. Using Source Models
  - 1.1 ExpBoost.R2
  - 1.2 Transfer Stacking
  - 1.3 Boosted Transfer Stacking
  - 1.4 Best Expert
2. Using Source Data Directly
  - 2.1 TrAdaBoost.R2
  - 2.2 Two-stage TrAdaBoost.R2
  - 2.3 Best Uniform Initial Weight
        
Based on experiment results, 1.3 and 2.2 perform as well as or (usually) better than the others.

## Algorithm Foundation
All 7 alogrithms are based on boosting algorithms for regression:

- AdaBoost.R2 (only it is used in 7 algorithms due to better performance)
- AdaBoost.RT

1.1~1.4 are based on ExpBoost (Rettinger et al., 2006), which is based on AdaBoost.M1 (Freund & Schapire, 1997).  
2.1~2.3 are based on TrAdaBoost (Dai et al., 2007), which is also based on AdaBoost.M1.

## Experiments

### Algorithm Implementation
[WEKA 3.4](http://sourceforge.net/projects/weka/files/weka-3-4/3.4/) is used for the base learners:
- M5P (class M5P)
- NN (class MLPRegressor)

### [Data](http://www.cs.utexas.edu/~TacTex/transfer_data.html)
8 algorithms (AdaBoost.R2 + 7 new algoritms) are evaluated on 7 problems:

1. UCI Repository
  - Concrete Strength
  - Housing
  - Auto MPG
  - Automobile
2. Friedman #1
3. Multiagent Systems
  - TAC SCM
  - TAC Travel
