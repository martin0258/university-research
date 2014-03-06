### Dataset
Name          | Alias
--------------|--------
new-concrete1 | D1
new-concrete2 | D2
new-concrete3 | D3
new-housing1  | D4
new-housing2  | D5
new-housing3  | D6
new-autompg1  | D7
new-autompg2  | D8
new-autompg3  | D9

### RMS Error
`#` | Error Type | Algorithm | D1 | D2 | D3 | D4 | D5 | D6 | D7 | D8 | D9
----|------------|-----------|----|----|----|----|----|----|----|----|----
0   | Testing    | AdaBoost.R2 + NN | 10.47 | 11.95 | 14.84 | 3.89 | 3.67 | 7.54 | 2.76 | 3.55 | 5.17
1   | Training   | nnet | 16.82 | 17.55 | 14.28 | 9.02 | 10.19 | 4.61 | 7.63 | 8.32 | 6.31
2   | Testing    | nnet | 17.92 | 14.89 | 22.31 | 10.32 | 6.77 | 10.35 | 9.08 | 6.70 | 11.46
3   | Training   | AdaBoost.R2 + nnet | 16.83 | 17.57 | 14.22 | 8.05 | 4.90 | 7.20 | 7.66 | 8.35 | 6.35
4   | Testing    | AdaBoost.R2 + nnet | 18.21 | 15.04 | 21.86 | 9.84 | 4.83 | 12.62 | 9.66 | 6.75 | 10.86

### Setting
#### 1,2
Parameter: 
- 1 hidden layer with default parameters
- # of hidden units equals to # of input features

#### 3,4
Note:
- Terminated early at iteration `7, 12, 12, 6, 9, 6, 15, 11, 8` because average loss >= 0.5.
