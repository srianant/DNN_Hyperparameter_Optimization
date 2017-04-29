"""
    File name         : nn_model.py
    File Description  : Generic Neural Network Class Using Tensorflow
    File Version      : 1.0
    Author            : Srini Ananthakrishnan and Michael Rinehart
    Date created      : 04/19/2017
    Date last modified: 04/28/2017
    Python Version    : 3.5
    Tensorflow Version: 1.0.1
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import time
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt


class NeuralNetwork(object):
    """Generic class to build feed forward neural network (NN)
    Functionality includes: 
        - build tensorflow feed forward neural network model
        - train network and optimize loss function
        - predict estimated outputs
        TODO: Supports only regressor with file version 1.0
    """

    def __init__(self):
        """Initializes a NeuralNetwork instance
        """
        pass

    def build_model(self, FLAGS, optimizer_epoch, global_step, nodes_per_layer,
                    learning_rate, activation, optimizer, logging):
        """Builds tensorflow neural network layers. 
        
        Initializes layers weights, biases from random normal distribution. Connects layers by matrix multiplication 
        and apply activation function (for non-linearities) except last layer
        
        Args:
            optimizer_epoch: Optimizer (outer-loop) iteration number
            train_epochs: Trainner (inner-loop) iteration number
            FLAGS: Macro dictionary contains user params and some defaults
            global_step: Global iteration steps
            nodes_per_layer: List contains number of nodes in each layers and its length determines number of layers
                Example:
                  nodes_per_layer = [1, 5, 4, 1]
                  First (input) layer has 1 node takes input vector of (N,)
                  Second hidden layer has 5 nodes (with tanh activation)
                  Third hidden layer has 4 nodes (with tanh activation)
                  Fourth output layer has 1 node outputs vector of (N,)
            learning_rate: learning rate used by optimizer. Default is 0.05
            optimizer: optimizer to use for training. Default is Adam
            activation: non-linear activation function. Default is Relu
            
        Returns:
            None. Computed costs are saved to self.costs
            
        Raises:
            None
        """
        logging.info("Node per layer:%s",nodes_per_layer)
        logging.info("Learning rate:%f",learning_rate)
        self.nodes_per_layer = nodes_per_layer
        self.learning_rate = learning_rate
        self.input_features = tf.placeholder(tf.float64)
        self.target_output = tf.placeholder(tf.float64)

        # Each layer is a matrix multiplication followed by a set of nonlinear operators
        # The size of each matrix is [size of output layer] x [size of input layer]
        layer_matrices = [None, ] * len(self.nodes_per_layer)
        layer_biases = [None, ] * len(self.nodes_per_layer)

        for layer in range(len(self.nodes_per_layer) - 1):
            input_size = self.nodes_per_layer[layer]
            output_size = self.nodes_per_layer[layer + 1]
            layer_matrices[layer] = tf.Variable(tf.random_normal([output_size, input_size], dtype=tf.float64))
            layer_biases[layer] = tf.Variable(tf.random_normal([output_size, 1], dtype=tf.float64))
            logging.info("[%d] %s/%d layer_matrices for layer %d of size %d x %d",
                         optimizer_epoch, FLAGS.job_name, FLAGS.task_index, layer, output_size, input_size)

        # Now we need to compute the output. We'll do that by connecting the matrix multiplications
        # through non-linearities except at the last layer, where we will just use matrix multiplication.
        intermediate_outputs = [None, ] * (len(self.nodes_per_layer) - 1)
        for layer in range(len(self.nodes_per_layer) - 1):
            if layer == 0:
                matmul = tf.add(tf.matmul(layer_matrices[layer], self.input_features), layer_biases[layer])
            else:
                matmul = tf.add(tf.matmul(layer_matrices[layer], intermediate_outputs[layer - 1]), layer_biases[layer])

            if layer < len(self.nodes_per_layer) - 2:
                logging.info("Using Activation: %s", activation)
                if activation == "tanh":
                    intermediate_outputs[layer] = tf.nn.tanh(matmul)
                else:
                    intermediate_outputs[layer] = tf.nn.relu(matmul)
            else:
                intermediate_outputs[layer] = matmul

        # And now the output -- we'll simply use matrix multiplication
        self.output = intermediate_outputs[-1]

        # compute error between target vs estimated output
        error = self.output - self.target_output
        self.cost = tf.matmul(error, tf.transpose(error))

        # optimize for loss or cost
        logging.info("Using Train Optimizer: %s", optimizer)
        if optimizer == "sgd":
            self.opt = tf.train.GradientDescentOptimizer(self.learning_rate)
        elif optimizer == "Adagrad":
            self.opt = tf.train.AdagradOptimizer(self.learning_rate)
        else: # Default is Adam
            self.opt = tf.train.AdamOptimizer(self.learning_rate)

        if FLAGS.sync_replicas:
            worker_spec = FLAGS.worker_hosts.split(",")
            # Get the number of workers.
            num_workers = len(worker_spec)

            if FLAGS.replicas_to_aggregate is None:
                replicas_to_aggregate = num_workers
            else:
                replicas_to_aggregate = FLAGS.replicas_to_aggregate

            self.opt = tf.train.SyncReplicasOptimizer(
                      self.opt,
                      replicas_to_aggregate=replicas_to_aggregate,
                      total_num_replicas=num_workers,
                      name="nn_sync_replicas")
            logging.info("Sync Replica Optimizer Enabled...")

        self.train_step = self.opt.minimize(self.cost, global_step=global_step)

        return self.opt


    def train(self, FLAGS, optimizer_epoch, train_epochs, sess, tolerance,
              X_train, Y_train, batch_size, global_step, logging):
        """Trains neural network regressor for given input featues f and output y
        
        Trains network to optimize costs (or loss function) until error tolerance is reached. 
        Boundary condition is defined to avoid infinite tranning loop
        
        Args:
            optimizer_epoch: Optimizer (outer-loop) iteration number
            train_epochs: Trainner (inner-loop) iteration number
            FLAGS: Macro dictionary contains user params and some defaults
            sess: tensorflow session for distributed computing
            f: input feature vector of shape (N,)
            y: output feature vector of shape (N,)
            batch_size: batch size for training
            global_step: Global iteration steps
        
        Returns:
            computed costs (or loss) list over all local steps (iteration)
            
        Raise:
            None. Training stops when boundary is reached and error message is printed
        """

        # initialize class variables
        self.N = len(X_train)
        self.sess = sess
        self.batch_size = batch_size

        # placeholder to record costs or loss per iteration
        self.costs = []
        prev_loss = 0.0
        logging.info("Batch Size:%d", batch_size)
        logging.info("Train tolerance:%f",tolerance)

        # Training Loop
        for epoch in range(train_epochs):
            avg_loss = 0.0
            total_batch = int(X_train.shape[0] / self.batch_size)
            for i in range(total_batch):
                # randomly pick input (row) and targeted output vectors from N
                indices = np.random.randint(self.N, size=self.batch_size)
                _f = X_train[indices, :]
                _y = Y_train[indices]

                # run tensorflow distributed session to compute loss function
                _, current_loss = self.sess.run([self.train_step, self.cost, ],
                                                 feed_dict={self.input_features: _f.transpose(),
                                                            self.target_output: _y})

                avg_loss += current_loss[0][0] / self.batch_size

            # save loss from current iteration
            self.costs.append(avg_loss)

            # error tolerance threshold
            if abs(prev_loss - float(avg_loss)) > tolerance:
                prev_loss = avg_loss
            else:
                logging.info("avg_loss: %f prev_loss: %f",avg_loss, prev_loss)
                logging.info("LOSS CONVERGED...at epoch %d",epoch)
                break

            # time the iteration
            now = time.time()
            step = self.sess.run(global_step)

            if(not epoch % 200):
                logging.info("[%d] %s/%d %f: training step %d done (global step: %d) with Loss %f, %f",
                             optimizer_epoch, FLAGS.job_name,FLAGS.task_index, now, epoch, step, avg_loss, prev_loss)

        logging.info("Training complete..!! FINAL LOSS: %f", avg_loss)
        return self.costs


    def MSE(self, predictions, labels):
        """Standard Mean Square Error
        Args:
            predictions: predicted output
            labels: given output
        Returns:
             Mean square error
        """
        return np.sqrt(np.sum((labels - predictions) ** 2) / (len(labels) - 1))


    def predict(self, FLAGS, X_test, Y_test, optimizer_epoch, logging):
        """Predicts output for input features (test or validation sample)
        Returns:
             Estimated output y_hat
        """
        self.y_hat = np.zeros(X_test.shape[0])
        for idx, _f in enumerate(X_test):
            self.y_hat[idx] = self.sess.run([self.output], feed_dict={self.input_features: _f.reshape(-1, 1)})[0]
        logging.info("Mean Square Error(MSE):%f", self.MSE(self.y_hat, Y_test))
        return self.y_hat
