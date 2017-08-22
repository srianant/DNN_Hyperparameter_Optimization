"""
    File name         : nn_generate_data.py
    File Description  : Prepare synthetic input features and target output for regression
    File Version      : 1.0
    Author            : Srini Ananthakrishnan and Michael Rinehart
    Date created      : 04/19/2017
    Date last modified: 05/05/2017
    Python Version    : 3.x
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import numpy as np
from sklearn import cross_validation
from sklearn.preprocessing import StandardScaler
from sklearn.datasets import load_boston


class ProcessData(object):
    """Prepare synthetic input features and target output
    """

    def __init__(self, logging):
        """Initializes a NeuralNetwork instance
        """
        self.logging = logging
        pass


    def split_and_normalize(self, data=None, label=None):
        """Train/Test split given input data and normalize
        Args:
            data: standard numpy array of shape [n_samples, n_features]
            label: standard numpy array of shape [n_samples]
        Returns: 
        """

        # cross validation: test/train split
        X_train, X_test, Y_train, Y_test = cross_validation.train_test_split(data, label, test_size=0.2, random_state=42)

        # feature normalization
        stdnorm = StandardScaler()
        stdnorm.fit(X_train)
        X_train = stdnorm.transform(X_train)
        X_test = stdnorm.transform(X_test)

        # reshape target output as (N,)
        Y_train = Y_train.reshape(Y_train.shape[0],)
        Y_test = Y_test.reshape(Y_test.shape[0],)

        return X_train, X_test, Y_train, Y_test


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
        matrix = x
        for power in range(1, p):
            # stack new column for next set of powers
            matrix = np.hstack((matrix, matrix[:, -1:] * x))
        return matrix


    def generateData(self, N, power, add_noise=False, add_cosine=False, power_method=False):
        """Function generates synthetic data
        Args:
            FLAGS: Macro dictionary contains user params and some defaults
            N: number of input rows
            power: number of input columns or features
            add_noise: adds random noise to output Y (used if power_method is True)
            add_cosine: transforms Y to element wise cosine (used if power_method is True)
            power_method: generate matrix polynomial of incremental "power"
        Returns: 
            X_train: X matrix training data 
            X_test: X matrix test data
            Y_train: Y matrix training data
            Y_test: Y matrix test data
        """

        # Generate synthetic data and label
        np.random.seed(seed=1234)

        if power_method == False:
            # Generate complex cosine target output and random input feature

            # features (observables)
            f = np.random.normal(size=(N, power)) * 2

            # coefficients (latent)
            c = np.random.normal(size=(power, 1))

            # draw labels
            X = f.dot(c).reshape(N, )
            y = self.complicated_function(X).astype(np.float32)

        else:
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

            f = X_mat
            y = Y_mat

        return self.split_and_normalize(data=f, label=y)


    def loadData(self):
        """Load ANY Data and Do test/train split.
        Example below uses Boston Housing Data
        Returns: 
            X_train: X matrix training data 
            X_test: X matrix test data
            Y_train: Y matrix training data
            Y_test: Y matrix test data
        """
        boston = load_boston()

        # cross validation: test/train split
        X_train, X_test, Y_train, Y_test = cross_validation.train_test_split(boston.data, boston.target,
                                                                             test_size=0.2, random_state=42)

        # feature normalization
        stdnorm = StandardScaler()
        stdnorm.fit(X_train)
        X_train = stdnorm.transform(X_train)
        X_test = stdnorm.transform(X_test)

        return X_train, X_test, Y_train, Y_test
