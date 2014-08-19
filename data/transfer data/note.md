# Generate Source Data
## Requirements
- Have weka.jar (v3.6.0) that supports `append` via `weka.core.Instances`

## Steps
`$java -cp weka.jar weka.core.Instances append new-autompg1.arff new-autompg2.arff > new-autompg12.arff`
