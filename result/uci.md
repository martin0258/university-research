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
1   | Training   | nnet | 17.08 | 17.5 | 14.46 | 9.16 | 10.02 | 7.79 | 7.66 | 8.22 | 6.21
2   | Testing    | nnet | 16.93 | 14.8 | 22.18 | 9.84 | 6.69 | 9.23 | 8.81 | 6.53 | 12.41
3   | Training   | AdaBoost.R2 + nnet | 17.08 | 17.44 | 14.42 | 6.11 | 6.87 | 4 | 7.67 | 8.28 | 6.37
4   | Testing    | AdaBoost.R2 + nnet | 16.9 | 15.03 | 21.52 | 6.33 | 5.86 | 8.58 | 9.13 | 6.76 | 11.2
5   | Training   | nnet | 9.08 | 9.76 | 8.21 | 5.47 | 5.14 | 7.01 | 7.66 | 4.18 | 3.14
6   | Testing    | nnet | **11.11** | **9.97** | **13.77** | 7.11 | **4.73** | 9.29 | 8.81 | **3.06** | 9.32
7   | Training   | AdaBoost.R2 + nnet | 12.33 | 12.07 | 9.5 | 4 | 4.17 | 3.11 | 4.22 | 4.23 | 2.67
8   | Testing    | AdaBoost.R2 + nnet | 16.41 | 11.65 | 15.84 | **5.46** | 4.77 | **8.2** | **6** | 3.92 | **7.24**

### Setting
#### 1,2
Parameter: 
- 1 hidden layer with default parameters
- # of hidden units equals to # of input features

#### 3,4
Note:
- Terminated early at iteration `7, 12, 12, 6, 9, 6, 15, 11, 8` because average loss >= 0.5.

#### 5,6
Parameter: 
- 1 hidden layer
- # of hidden units equals to # of input features
- rang=0.1; decay=1e-1; maxit=100

#### 7,8
Note:
- Terminated early at iteration `10, 13, 19, 17, 29, 39, 7, 15, 12` because average loss >= 0.5.
