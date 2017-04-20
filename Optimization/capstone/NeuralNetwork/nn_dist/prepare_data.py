"""
    File name         : prepare_data.py
    File Description  : Prepare synthetic input features and target output
    File Version      : 1.0
    Author            : Srini Ananthakrishnan and Michael Rinehart
    Date created      : 04/19/2017
    Date last modified: 04/19/2017
    Python Version    : 3.5
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import numpy as np
from sklearn import cross_validation
from sklearn.preprocessing import StandardScaler

class PrepareData(object):
    """Prepare synthetic input features and target output
    """

    def __init__(self):
        """Initializes a NeuralNetwork instance
        """
        pass


    def complicated_function(self,x):
        """Add element wise cosine 
        
        Args:
            x: input feature matrix
        Returns:
            Cosine applied input matrix 
        """
        return np.cos(1. / (np.abs(x) + .75))


    def polynomial_matrix(self, x, p):
        """generate polynomial matrix with degree-0     
        Args:
            p: 
        Returns:
            matrix with columns for next set of powers
        """
        x = x.reshape(x.shape[0], 1)
        matrix = np.ones((x.shape[0], 1))  # degree-0
        #for power in range(1, p + 1):
        for power in range(1, p):
            # stack new column for next set of powers
            matrix = np.hstack((matrix, matrix[:, -1:] * x))
        return matrix


    def generateData(self, FLAGS, N, power, add_noise=False, add_cosine=False, data=None, label=None):
        """Function generates synthetic data
        Args:
            FLAGS: Macro dictionary contains user params and some defaults
            N: number of input rows
            power: number of input columns or features
            add_noise: adds random noise to output Y
            add_cosine: transforms Y to element wise consine 
        Returns:    
            X: input features of shape (N,)
            Y: output of shape (N,)
            X_train: X matrix training data with degree-0 (1st col all ones)
            X_test: X matrix test data with degree-0
            Y_train: Y matrix training data
            Y_test: Y matrix test data
        """

        # Generate synthetic data and label
        np.random.seed(seed=1234)

        # Generate samples for X
        X = np.random.normal(size=N)

        # Generate samples for Y
        #true_coeff = np.random.normal(size=power + 1)
        true_coeff = np.random.normal(size=power)

        if (add_cosine):
            X_cosine = self.complicated_function(X).astype(np.float32)
            Y = np.dot(self.polynomial_matrix(X_cosine, power), true_coeff)
        else:
            Y = np.dot(self.polynomial_matrix(X, power), true_coeff)
        Y_observe = Y

        # Add noise to make observations
        if (add_noise):
            Y_observe = Y + np.random.normal(size=N) * 2

        # reshape into matrix form
        Y_mat = Y_observe.reshape(Y_observe.shape[0], 1)
        X_mat = self.polynomial_matrix(X, power)

        print("%s/%d" % (FLAGS.job_name,FLAGS.task_index),
              "Truth data shape:", "X:", X.shape, "Y:", Y.shape)


        # cross validation: test/train split
        X_train, X_test, Y_train, Y_test = cross_validation.train_test_split(X_mat, Y_mat, test_size=0.2, random_state=42)

        # feature normalization
        # stdnorm = StandardScaler()
        # stdnorm.fit(X_train)
        # X_train = stdnorm.transform(X_train)
        # X_test = stdnorm.transform(X_test)

        print("%s/%d" % (FLAGS.job_name,FLAGS.task_index),
              "Train/Test split:", "X_train:", X_train.shape, "Y_train:", Y_train.shape,
              "X_test:", X_test.shape, "Y_test:", Y_test.shape)

        return X_train, X_test, Y_train, Y_test


    def split_and_normalize(self, data=None, label=None):
        """Train/Test split input data and normalize
        Args:
            data: standard numpy array of shape [n_samples, n_features]
            label: standard numpy array of shape [n_samples]
        Returns: 
        """

        if (data == None) or (label == None):
            raise ValueError("Must valid data and label")

        # cross validation: test/train split
        X_train, X_test, Y_train, Y_test = cross_validation.train_test_split(data, label, test_size=0.2, random_state=42)

        # feature normalization
        stdnorm = StandardScaler()
        stdnorm.fit(X_train)
        X_train = stdnorm.transform(X_train)
        X_test = stdnorm.transform(X_test)

        print("%s/%d" % (FLAGS.job_name,FLAGS.task_index),
              "Train/Test split:", "X_train:", X_train.shape, "Y_train:", Y_train.shape,
              "X_test:", X_test.shape, "Y_test:", Y_test.shape)

        return X_train, X_test, Y_train, Y_test