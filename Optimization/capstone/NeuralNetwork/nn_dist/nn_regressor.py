"""
    File name         : nn_regressor.py
    File Description  : Deep Neural Network Regressor Class Using Tensorflow
    File Version      : 1.0
    Author            : Srini Ananthakrishnan and Michael Rinehart
    Date created      : 04/19/2017
    Date last modified: 05/04/2017
    Python Version    : 3.x
    Tensorflow Version: 1.0.1
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import numpy as np
import tensorflow as tf
from process_data import ProcessData


class RegressorNN(object):
    """Generic class to build feed forward regressor neural network (NN)
    Functionality includes: 
        - build tensorflow feed forward neural network model
        - train network and optimize loss function
        - predict estimated outputs
        TODO: Supports only regressor with file version 1.0
    """

    def __init__(self, logging):
        """Initializes a NeuralNetwork instance
        
        Args:
            logging: handler for logging macro
        """
        self.logging = logging
        self.costs = []
        pass


    def build_model(self, epoch_config):
        """Builds tensorflow neural network layers. 
        
        Initializes layers weights, biases from random normal distribution. Connects layers by matrix multiplication 
        and apply activation function (for non-linearities) except last layer
        
        Args:
            FLAGS: Macro dictionary contains user params and some defaults            
            epoch_config: epoch configuration

        epoch_config:
            nodes_per_layer: List contains number of nodes in each layers and its length determines number of layers
                Example:
                  nodes_per_layer = [1, 5, 4, 1]
                  First (input) layer has 1 node takes input vector of (N,)
                  Second hidden layer has 5 nodes (with tanh activation)
                  Third hidden layer has 4 nodes (with tanh activation)
                  Fourth output layer has 1 node outputs vector of (N,)
            optimizer: optimizer to use for training. Default is Adam
            learning_rate: learning rate used by optimizer. Default is 0.05
            activation: non-linear activation function. Default is relu
            
        Returns:
            None. Computed costs are saved to self.costs
            
        Raises:
            None
        """

        # Instantiate DNN Regressor Data Class
        PD = ProcessData(self.logging)

        if epoch_config['load_data'] == True:
            self.X_train, self.X_test, self.Y_train, self.Y_test = PD.loadData()
        else:
            # Initialize variables to prepare synthetic data
            N = epoch_config['data_instances']
            M = epoch_config['data_features']
            self.X_train, self.X_test, self.Y_train, self.Y_test = PD.generateData(N, M)

        self.logging.info("Node per layer:%s",epoch_config['nodes_per_layer'])
        self.logging.info("Train Optimizer:%s",epoch_config['train_optimizer'])
        self.logging.info("Learning rate:%f",epoch_config['learning_rate'])
        self.logging.info("Activation:%s",epoch_config['activation'])

        # Local variables
        nodes_per_layer = epoch_config['nodes_per_layer']

        # TensorFlow Variables and Placeholders

        # Global iteration steps
        global_step = tf.Variable(0, name="global_step", trainable=False)

        # Placeholder for input features and target output
        self.input_features = tf.placeholder(tf.float64)
        self.target_output = tf.placeholder(tf.float64)

        # Each layer is a matrix multiplication followed by a set of nonlinear operators
        # The size of each matrix is [size of output layer] x [size of input layer]
        layer_matrices = [None, ] * len(nodes_per_layer)
        layer_biases = [None, ] * len(nodes_per_layer)

        # Compute weight matries and biases for layered neural network
        for layer in range(len(nodes_per_layer) - 1):
            input_size = nodes_per_layer[layer]
            output_size = nodes_per_layer[layer + 1]
            layer_matrices[layer] = tf.Variable(tf.random_normal([output_size, input_size], dtype=tf.float64))
            layer_biases[layer] = tf.Variable(tf.random_normal([output_size, 1], dtype=tf.float64))
            self.logging.info("[%d] layer_matrices for layer %d of size %d x %d",
                         epoch_config['opt_epoch_iter'], layer, output_size, input_size)

        # Now we need to compute the output. We'll do that by connecting the matrix multiplications
        # through non-linearities except at the last layer, where we will just use matrix multiplication.
        intermediate_outputs = [None, ] * (len(nodes_per_layer) - 1)
        for layer in range(len(nodes_per_layer) - 1):
            if layer == 0:
                matmul = tf.add(tf.matmul(layer_matrices[layer], self.input_features), layer_biases[layer])
            else:
                matmul = tf.add(tf.matmul(layer_matrices[layer], intermediate_outputs[layer - 1]), layer_biases[layer])

            if layer < len(nodes_per_layer) - 2:
                self.logging.info("Using Activation: %s", epoch_config['activation'])
                if epoch_config['activation'] == "tanh":
                    intermediate_outputs[layer] = tf.nn.tanh(matmul)
                else: # Default "relu"
                    intermediate_outputs[layer] = tf.nn.relu(matmul)
            else:
                intermediate_outputs[layer] = matmul

        # And now the output -- we'll simply use matrix multiplication
        self.output = intermediate_outputs[-1]

        # compute error between target vs estimated output
        error = self.output - self.target_output
        self.cost = tf.matmul(error, tf.transpose(error))

        # optimize for loss or cost
        self.logging.info("Using Train Optimizer: %s", epoch_config['train_optimizer'])
        if epoch_config['train_optimizer'] == "sgd":
            self.opt = tf.train.GradientDescentOptimizer(epoch_config['learning_rate'])
        elif epoch_config['train_optimizer'] == "Adagrad":
            self.opt = tf.train.AdagradOptimizer(epoch_config['learning_rate'])
        else: # Default is Adam
            self.opt = tf.train.AdamOptimizer(epoch_config['learning_rate'])

        # Between the graph replication. If enabled training happens *syncronously*
        if epoch_config['sync_replicas'] == True:
            worker_spec = epoch_config['worker_hosts'].split(",")
            # Get the number of workers.
            num_workers = len(worker_spec)

            self.opt = tf.train.SyncReplicasOptimizer(
                      self.opt,
                      replicas_to_aggregate=num_workers,
                      total_num_replicas=num_workers,
                      name="nn_sync_replicas")
            self.logging.info("Sync Replica Optimizer Enabled...")

        self.train_step = self.opt.minimize(self.cost, global_step=global_step)

        return self.opt


    def train_model(self, mon_sess, epoch_config):
        """Trains neural network regressor for given input featues f and output y
        
        Trains network to optimize costs (or loss function) until error tolerance is reached. 
        Boundary condition is defined to avoid infinite tranning loop
        
        Args:
            mon_sess: TensorFlow MonitoredTrainingSession for Distributed Computing
            X_train: input feature vector of shape (N,M)
            Y_train: output feature vector of shape (N,)
            epoch_config: epoch configuration
        
        epoch_config:
            batch_size: batch size for training
        
        Returns:
            computed costs (or loss) list over all local steps (iteration)
            
        Raise:
            None. Training stops when boundary is reached and error message is printed
        """

        # initialize class variables
        self.N = len(self.X_train)
        self.mon_sess = mon_sess
        self.batch_size = epoch_config['batch_size']

        # randomly pick input (row) and targeted output vectors from N
        indices = np.random.randint(len(self.X_train), size=epoch_config['batch_size'])
        _f = self.X_train[indices, :]
        _y = self.Y_train[indices]

        # run tensorflow distributed session to compute loss function
        _, current_loss, = self.mon_sess.run([self.train_step, self.cost,],
                                         feed_dict={self.input_features: _f.transpose(),
                                                    self.target_output: _y})

        avg_loss = current_loss[0][0] / self.batch_size

        # save loss from current iteration
        self.costs.append(avg_loss)

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


    def predict(self):
        """Predicts output for input features (test or validation sample)
        
        Args:
            None
        Returns:
             Estimated output y_hat
        """
        self.y_hat = np.zeros(self.X_test.shape[0])
        for idx, _f in enumerate(self.X_test):
            self.y_hat[idx] = self.mon_sess.run([self.output], feed_dict={self.input_features: _f.reshape(-1, 1)})[0]
        self.logging.info("Mean Square Error(MSE):%f", self.MSE(self.y_hat, self.Y_test))
        return self.y_hat
