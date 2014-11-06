/*
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*  This code is based on:		
 *    TrAdaBoost.java
 *    Copyright (C) 2007 Raymond J. Mooney
 *  Modified by David Pardoe, 2012
 */


/*
*
* Valid options are:<p>
*
* -W classname <br>
* Specify the full class name of a classifier as the basis for 
* boosting (required).<p>
*
* -I num <br>
* Set the number of (second stage) boost iterations (default 10). <p>
*
* -II num <br>
* Set the number of first stage boost iterations; if not set, the value from -I will be used. <p>
*
* -S filename <br>
* Data file to use as source data for transfer. <p>
*
* -Ratio num <br>
* Ratio of source to target starting weight; default 2; if negative, then all instances are weighted equally <p>
*
* -F <br>
* Decrease source weights uniformly in stage 1. <p>
* 
* -B <br>
* Use bagging in stage 2, not AdaBoost.R2 <p>
* 
* -R <br>
* Resample training data at each iteration (necessary if base learner is not a WeightedInstanceHandler) <p>
*
* -U <br>
* Handle source weights as usual in stage 2 instead of fixing them. <p>
*
* -M <br>
* Use weighted median instead of mean <p>
* 
* -TT filename <br>
* The test file for which errors will be printed
* 
* -FB <br>
* Usa a fixed value of beta.  The theoretical justification for beta in AdaBoost.M1 doesn't remain true for AdaBoost.R2, and using a fixed value can actually improve performance and stability, especially if using cross validation to control the number of iterations.
*
* Options after -- are passed to the designated classifier.<p>
*
*/



import weka.classifiers.*;
import java.io.*;
import java.util.*;

import weka.core.*;

class Pair implements Comparable{
	double x,y;
	
	public int compareTo(Object o){
		Pair p = (Pair) o;
		if (p.x > x)
			return -1;
		else if (p.x < x)
			return 1;
		else
			return 0;
	}
}



public class TwoStageTrAdaBoostR2 extends IteratedSingleClassifierEnhancer {

	private boolean resample = false;
	private double sourceRatio = 2;
	private boolean doFraction = false;
	private boolean doUpsource = false;
	private boolean doBagging = false;
	private boolean doSampleSize = false;
	private boolean fixedBeta = false;
	
	double sourceFraction;
	int numTargetInstances;
	
	boolean useMedian = false;
	private Instances testData;
	
	boolean allcvDone = false;
	double[][] outputs;
	int sourceIterations = -1;
	double targetWeight = 0;
	
	int finalStartIt = -1;
	int finalStopIt = -1;
	
	protected double betaSum;
	
	/** The source data file to transfer from */
	protected File m_SourceFile = new File("-");

	/** The Instances from the source domain to transfer from */
	protected Instances m_SourceInstances;
	
	/** Use source data as normal training data */
	protected boolean m_NormalSource;

	/** Array for storing the weights for the votes. */
	protected double [] m_Betas;

	/** The number of successfully generated base classifiers. */
	protected int m_NumIterationsPerformed;

	/** The number of classes */
	protected int m_NumClasses;
		
		
	/**
	 * Constructor.
	 */
	public TwoStageTrAdaBoostR2() {
		
		m_Classifier = new weka.classifiers.trees.DecisionStump();
	}




	public void setOptions(String[] options) throws Exception {

		String sourceFileName = Utils.getOption('S', options);
		if (sourceFileName.length() == 0) {
			throw new Exception("A filename must be specified with"
				+ " the -S option.");
		} else {
			setSourceFile(new File(sourceFileName));
		}

		doFraction = (Utils.getFlag('F', options));
		doBagging = (Utils.getFlag('B', options));
		doUpsource = (Utils.getFlag('U', options));
		useMedian = (Utils.getFlag('M', options));
		resample = (Utils.getFlag('R', options));
		doSampleSize = Utils.getFlag("SS", options);
		fixedBeta = Utils.getFlag("FB", options);
		
		String optionString = Utils.getOption("TT", options);
		testData = new Instances(new BufferedReader(new FileReader(optionString)));
		testData.setClassIndex(testData.numAttributes() - 1);
		
		String r = Utils.getOption("Ratio", options); 
		if (!r.equals(""))
			sourceRatio = Double.parseDouble(r);
		
		
		
		super.setOptions(options);
	
		r = Utils.getOption("II", options); 
		if (!r.equals(""))
			sourceIterations = Integer.parseInt(r);
		else
			sourceIterations = m_NumIterations;

	}
	
	/**
	 * Set the data file for the source data for transfer
	 * and get the source Instances from the file
	 */
	public void setSourceFile(File sourceFile) throws Exception{

			m_SourceFile = sourceFile;
			m_SourceInstances = new Instances(new BufferedReader(new FileReader(sourceFile)));
			m_SourceInstances.setClassIndex(m_SourceInstances.numAttributes() - 1);
	}



	/**
	 * Boosting method.
	 *
	 * @param data the training data to be used for generating the
	 * boosted classifier.
	 * @exception Exception if the classifier could not be built successfully
	 */

	public void buildClassifier(Instances data) throws Exception {

		super.buildClassifier(data);

		if (data.checkForStringAttributes()) {
			throw new UnsupportedAttributeTypeException("Cannot handle string attributes!");
		}
		data = new Instances(data);
		data.deleteWithMissingClass();
		if (data.numInstances() == 0) {
			throw new Exception("No train instances without class missing!");
		}
		if (!data.classAttribute().isNumeric()) {
			throw new UnsupportedClassTypeException("TrAdaBoostR2 can only handle a numeric class!");
		}
		if (m_SourceInstances == null) {
			throw new Exception("Source data has not been specified!");
		}

		m_NumClasses = data.numClasses();
		try{doCV(data);} catch (Exception e){e.printStackTrace();}
	}

	
	private void doCV(Instances targetData) throws Exception{
System.out.println();
System.out.flush();
		int numSourceInstances = m_SourceInstances.numInstances();
		int numInstances = targetData.numInstances() + numSourceInstances;
		numTargetInstances = numInstances - numSourceInstances;
		double weightSource, weightTarget;
		double initialSourceFraction;
		double[] weights = new double[numInstances];
		Random randomInstance = new Random(1);
		
		Instances data = new Instances(m_SourceInstances, 0, numSourceInstances);
		// Now add the target data, shallow copying the instances as they are added
		// so it doesn't mess up the weights for anyone else
		Enumeration enumer = targetData.enumerateInstances();
		while (enumer.hasMoreElements()) {
			Instance instance = (Instance) enumer.nextElement();
			data.add(instance);
		}
		
		
		if (sourceRatio < 0){ //weight all equally
			weightSource = weightTarget = 1.0/*/numInstances*/;
			initialSourceFraction = numSourceInstances / (double) numInstances;
		}
		else{
			double totalWeight = 1 + sourceRatio;
			weightSource = sourceRatio/totalWeight/*/numSourceInstances*/;
			weightTarget = 1.0/totalWeight/*/numTargetInstances*/;
			initialSourceFraction = weightSource;
		}
		for (int j = 0; j < numInstances; j++){
			Instance instance = data.instance(j);
			if (j < numSourceInstances)
				instance.setWeight(weightSource);
			else
				instance.setWeight(weightTarget);
		}
	
		
		if (doFraction){
			for (int it = 0; it < sourceIterations/*m_NumIterations*/; it++){

				sourceFraction = (1-(it / (double) m_NumIterations)) * initialSourceFraction; //[same weights as regular]
				if (sourceFraction > .995)
					sourceFraction = .995;
				//double sourceWeight = (sourceFraction * numInstances) / numSourceInstances;
				double sourceWeight = (sourceFraction * numTargetInstances) / (numSourceInstances * (1-sourceFraction));
				for (int j = 0; j < numInstances; j++){
					Instance instance = data.instance(j);
					if (j < numSourceInstances)		
						instance.setWeight(sourceWeight);
					else
						instance.setWeight(1);
				}
				buildClassifierWithWeights(data);
				System.out.println("Iteration " + it + ":" + getTestError());
			}
		}
		else{
			
			for (int i = 0; i < numInstances; i++)
				weights[i] = data.instance(i).weight();
			buildClassifierWithWeights(data);
			System.out.println("Iteration -1:" + getTestError());
			for (int i = 0; i < numInstances; i++)
				data.instance(i).setWeight(weights[i]);

			
			for (int it = 0; it < sourceIterations; it++){
				
				Instances sample = null;
				if (!resample || m_NumIterationsPerformed == 0){
					sample = data;
				}
				else{
					double sum = data.sumOfWeights();
					double[] sweights = new double[data.numInstances()];
					for (int i = 0; i < sweights.length; i++) {
						sweights[i] = data.instance(i).weight()/sum;
					}
					sample = data.resampleWithWeights(randomInstance, sweights);
				}
				
							
				try{
					m_Classifiers[it].buildClassifier(sample);
				}
				catch(Exception e){e.printStackTrace(); System.out.println("E: " + e);}
				
				sourceFraction = initialSourceFraction * (1 - (it+1) / (double) m_NumIterations);
				setWeights(data, m_Classifiers[it], sourceFraction, numSourceInstances, false);
				
				for (int i = 0; i < numInstances; i++)
					weights[i] = data.instance(i).weight();
	
				buildClassifierWithWeights(data);
	
				System.out.println("Iteration " + it + ":" + getTestError());
				
				for (int i = 0; i < numInstances; i++)
					data.instance(i).setWeight(weights[i]);

			}			
			
		}	
		
	}
	
	/**
	 * Boosting method. Boosts any classifier that can handle weighted
	 * instances.
	 *
	 * @param data the training data to be used for generating the
	 * boosted classifier.
	 * @exception Exception if the classifier could not be built successfully
	 */
	protected void buildClassifierWithWeights(Instances data) 
		throws Exception {

		Random randomInstance = new Random(0);
		double epsilon, reweight, beta = 0;
		Evaluation evaluation;
		Instances sample;
		// Initialize data
		m_Betas = new double [m_Classifiers.length];
		m_NumIterationsPerformed = 0;
		int numSourceInstances = m_SourceInstances.numInstances();
		
		// Do boostrap iterations
		for (m_NumIterationsPerformed = 0; m_NumIterationsPerformed < m_Classifiers.length;	m_NumIterationsPerformed++) {
			// Build the classifier
			sample = null;
			if (!resample || m_NumIterationsPerformed == 0){
				sample = data;
			}
			else{
				double sum = data.sumOfWeights();
				double[] weights = new double[data.numInstances()];
				for (int i = 0; i < weights.length; i++) {
					weights[i] = data.instance(i).weight()/sum;
				}
				sample = data.resampleWithWeights(randomInstance, weights);

				if (doSampleSize){
					int effectiveInstances = (int)(sourceFraction * weights.length + numTargetInstances);
					if (effectiveInstances > numSourceInstances + numTargetInstances)
						effectiveInstances = numSourceInstances + numTargetInstances;
//System.out.println(effectiveInstances);					
					sample.randomize(randomInstance);
					Instances q = new Instances(sample, 0, effectiveInstances);
					sample = q;
				}				
			}
			try{
				m_Classifiers[m_NumIterationsPerformed].buildClassifier(sample);
			}
			catch(Exception e){e.printStackTrace(); System.out.println("E: " + e);}
					
			if (doBagging)
				beta = 0.4/.6; //always same beta
			else
				beta = setWeights(data, m_Classifiers[m_NumIterationsPerformed], -1, numSourceInstances, true);
		
			// Stop if error too small or error too big and ignore this model
			if (beta < 0) { //setWeights indicates a problem with negative beta
				if (m_NumIterationsPerformed == 0) {
					m_NumIterationsPerformed = 1; // If we're the first we have to to use it
				}
				break;
			}
		
			// Determine the weight to assign to this model
					
			m_Betas[m_NumIterationsPerformed] = Math.log(1/beta);
			
		}

		
		
		betaSum = 0;
		
		for (int i = 0; i < m_NumIterationsPerformed; i++)
			betaSum += m_Betas[i];
	}
	
	private double getTestError() throws Exception{
		
		Evaluation evaluation;
		evaluation = new Evaluation(testData);
		evaluation.evaluateModel(this, testData);
		return evaluation.errorRate();
		
	}

	/**
	 * Sets the weights for the next iteration.
	 */
	protected double setWeights(Instances trainData, Classifier cls, double sourceFraction, int numSourceInstances, boolean isFinal) 
		throws Exception {

		Enumeration enu = trainData.enumerateInstances();
		int instNum = 0;
		double[] errors = new double[trainData.numInstances()];
		double max = 0;
		int i = 0;
		while (enu.hasMoreElements()) {
			Instance instance = (Instance) enu.nextElement();
			errors[i] = Math.abs(cls.classifyInstance(instance) - instance.classValue());
			if (i >= numSourceInstances && errors[i] > max)
				max = errors[i];
			i++;
		}
	
		if (max == 0)
			return -1;
			
			
		//get avg loss
		double loss = 0;
		double initialTWeightSum = 0;
		double allWeightSum = 0;
		for (int j = 0; j < errors.length; j++){
			errors[j] /= max;
			Instance instance = trainData.instance(j);
			loss += instance.weight() * errors[j];
			if (j >= numSourceInstances){
				//loss += instance.weight() * errors[j];
				initialTWeightSum += instance.weight();
			}
			allWeightSum += instance.weight();
		}
		//loss /= weightSum;
		loss /= allWeightSum;

		targetWeight = initialTWeightSum/allWeightSum;
/*
if (!isFinal){
System.out.println("Target weight: " + targetWeight);
System.out.println("max: " + max);
System.out.println("avg error: " + loss * max);
System.out.println("Loss: " + loss);
}
*/
		
		double beta;
		
		if (fixedBeta)
			beta = 0.4/0.6;
		else{
			if (isFinal && loss > 0.499)//bad, so quit
				//return -1;
				loss = 0.499; //since we're doing CV, no reason to quit
			
			beta = loss/(1-loss); //or just use beta = .4/.6, since beta isn't as meaningful in AdaBoost.R2;
		}	

		double tWeightSum = 0;
		if (!isFinal){
			//need to find b so that weight of source be sourceFraction*num source
			//do binary search
			double goal = sourceFraction * errors.length;
			double bMin = .001;
			double bMax = .999;
			double b;
			double sourceSum = 0;
			while (bMax - bMin > .001){
				b = (bMax + bMin) / 2;
				double sum = 0;
				for (int j = 0; j < numSourceInstances; j++){
					Instance instance = trainData.instance(j);
					sum += Math.pow(b, errors[j]) * instance.weight();
				}
				if (sum > goal)
					bMax = b;
				else
					bMin = b;
			}	
			b = (bMax + bMin) / 2;
//System.out.println(b);			
			for (int j = 0; j < numSourceInstances; j++){
				Instance instance = trainData.instance(j);
				instance.setWeight(instance.weight() * Math.pow(bMin, errors[j]));
				sourceSum += instance.weight();
			}
				
			//now adjust target weights
			goal = errors.length - sourceSum;
			double m = goal/initialTWeightSum;
			
			for (int j = numSourceInstances; j < errors.length; j++){
				Instance instance = trainData.instance(j);
				instance.setWeight(instance.weight() * m);
			}
		}
		else {//final
			if (!doUpsource){ //modify only target weights
				for (int j = numSourceInstances; j < errors.length; j++){
					Instance instance = trainData.instance(j);
					instance.setWeight(instance.weight() * Math.pow(beta, -errors[j]));
					tWeightSum += instance.weight();
				}
			
				double weightSumInverse = initialTWeightSum/tWeightSum;
				for (int j = numSourceInstances; j < errors.length; j++){
					Instance instance = trainData.instance(j);
					instance.setWeight(instance.weight() * weightSumInverse);
				}
			}
			else{ //modify all weights
				for (int j = 0; j < errors.length; j++){
					Instance instance = trainData.instance(j);
					instance.setWeight(instance.weight() * Math.pow(beta, -errors[j]));
					tWeightSum += instance.weight();
				}
			
				double weightSumInverse = errors.length/tWeightSum;
				for (int j = 0; j < errors.length; j++){
					Instance instance = trainData.instance(j);
					instance.setWeight(instance.weight() * weightSumInverse);
				}
			}

		}

		return beta;
	}


	public double classifyInstance(Instance inst) throws Exception {
		if (useMedian)
			return classifyInstanceMedian(inst);
		else
			return classifyInstanceMean(inst);
	}

	public double classifyInstanceMean(Instance inst) throws Exception {
		double sum = 0;
		for (int i = 0; i < m_NumIterationsPerformed; i++){
			double q = m_Classifiers[i].classifyInstance(inst);
			sum += q * m_Betas[i];
		}
		
		return sum/betaSum;				
		
	}
	
	public double classifyInstanceMedian(Instance inst) throws Exception {
		double invBetaSum = 1.0 / betaSum; // or try m_NumIterationsPerformed
		Pair[] p = new Pair[m_NumIterationsPerformed];
		for (int i = 0; i < m_NumIterationsPerformed; i++){
			p[i] = new Pair();
			p[i].x = m_Classifiers[i].classifyInstance(inst);
			p[i].y = invBetaSum * m_Betas[i]; //or try 1
		}
		return getWeightedMedian(p);
		
	}

	public double getWeightedMedian(Pair[] p){
		Arrays.sort(p);
		double sum = 0;
		int pos = -1;
		while (sum < 0.5){
			pos++;
			sum += p[pos].y;
		}
		return p[pos].x;
	}

	/**
	 * Returns description of the boosted classifier.
	 *
	 * @return description of the boosted classifier as a string
	 */
	public String toString() {
		
		StringBuffer text = new StringBuffer();
		
		if (m_NumIterationsPerformed == 0) {
			text.append("TrAdaBoost: No model built yet.\n");
		} else if (m_NumIterationsPerformed == 1) {
			text.append("TrAdaBoost: No boosting possible, one classifier used!\n");
			text.append(m_Classifiers[0].toString() + "\n");
		} else {
			text.append("TrAdaBoost: Base classifiers and their weights: \n\n");
			for (int i = 0; i < m_NumIterationsPerformed ; i++) {
	text.append(m_Classifiers[i].toString() + "\n\n");
	text.append("Weight: " + Utils.roundDouble(m_Betas[i], 2) + "\n\n");
			}
			text.append("Number of performed Iterations: " 
			+ m_NumIterationsPerformed + "\n");
		}
		
		return text.toString();
	}

	/**
	 * Main method for testing this class.
	 *
	 * @param argv the options
	 */
	public static void main(String [] argv) {

		try {
			System.out.println(Evaluation.evaluateModel(new TwoStageTrAdaBoostR2(), argv));
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
	}
}
