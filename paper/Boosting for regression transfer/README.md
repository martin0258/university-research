# Email from David Pardoe (author)
This has been cleaned up some, but it's still probably not self explanatory.  
It's also been a while since I looked at this.

There's one main problem, which is that this version **doesn't do cross validation to determine the number of iterations** as described in the paper.
Instead, it outputs the actual RMS error of the model for each (first-stage) iteration on the test set passed to it with the -TT parameter.

> **Note**: I had a script that used this output to do a similar form of cross validation as an outer loop, but I can no longer find it, and in any case it was pretty specific to my old department's machine cluster.
Also, there's a lot of extra code here that implements variations not mentioned in the paper.

What I have should hopefully be good enough to get you started.

You can run a test on the attached files (from the Friedman #1 data set as described in the paper) as follows:
```bash
$java -cp weka.jar:. TwoStageTrAdaBoostR2 -W weka.classifiers.trees.M5P -M -R -Ratio -1  -S source.arff -t train.arff -T test.arff -TT test.arff -v -o -I 10 -II 10
```

This will use M5P trees as the base learner and use 10 iterations for both stage 1 and stage 2.  
The output should look like:

```
Iteration -1:5.136706153797207
Iteration 0:4.530421767595497
Iteration 1:4.273636527518781
Iteration 2:3.967956096716119
Iteration 3:3.2302972071851
Iteration 4:3.1399356849661384
Iteration 5:2.91658635001737
Iteration 6:2.922464152829164
Iteration 7:2.886091984774022
Iteration 8:3.2148548420610927
Iteration 9:3.4806299156081297
```

You can ignore the standard weka output that follows, since it just matches the final iteration.  
The meaning of this is that all source and target weights start out equal (iteration -1), then in each stage 1 the total source weight decreases by 10 % until it is essentially 0 in iteration 9.  
Here the best results were after 7 iterations, when the source instances had a total weight of about 20% of the original.  
In other words, steps 2-4 of Algorithm 3 in the paper had been performed 8 times, and then the result of the next step 1 (10 iterations of AdaBoost.R2 with source weights fixed) was a model producing an RMS error of 2.88.

For your purposes, it may simply be acceptable to take the lowest error from any iteration, and use this as an optimistic estimate of what you would achieve using cross validation to pick the best place to stop.

# Build Source
1. Download [weka v3.4.19](http://sourceforge.net/projects/weka/files/weka-3-4/3.4.19/weka-3-4-19.zip/download)
2. Extract zip and copy `weka.jar` to the same folder where source code is
3. Run command: `$javac -cp ./weka.jar TwoStageTrAdaBoostR2.java`
