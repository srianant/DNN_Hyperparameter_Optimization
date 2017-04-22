"""
    File name         : nn_optimizer.py
    File Description  : Hyper Parameter Optimizer for Neural Network
    File Version      : 1.0
    Author            : Srini Ananthakrishnan
    Date created      : 04/19/2017
    Date last modified: 04/19/2017
    Python Version    : 3.5
    Tensorflow Version: 1.0.1
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from numpy.random import rand
import matplotlib.pyplot as plt

class Optimize(object):
    """Neural Network Hyper Parameter Optimizer Class.
    Optimize hyperparameters for feed forward neural network 
    """

    def __init__(self):
        """Initializes a NeuralNetwork instance
        """
        pass


    def optimize_params(self, FLAGS, params_list, model_func,
                        X_train, X_test, Y_train, Y_test,
                        nodes_per_layer, optimizer_epochs, train_epochs, batch_size):
        """Function to optimize hyperparams
        
        Args:
            FLAGS: Macro dictionary contains user params and some defaults
            params_list: List of lists of hyperparameters with lower bound and upper bound values
            model_func: Tensorflow model function
            f: input features of shape (N,)
            y: target output of shape (N,) 
            nodes_per_layer: List contains number of nodes in each layers and its length determines number of layers
            max_iter: maximum optimizer (outer-loop) iteration
            batch_size: batch size for training
        
        Returns:
            best params and best loss with how many iteration
        """

        num_params = len(params_list) # number of hyperparams
        best_loss = 99999.0 # set initialize loss to very high value
        best_params = [None ] *num_params
        best_itr = 0
        tolerance = 1e-4

        for optimizer_epoch in range(1 , optimizer_epochs +1):
            print("[%d]" % optimizer_epoch, "%s/%d" % (FLAGS.job_name,FLAGS.task_index),
                  "Optimizer loop epoch ====================>>",optimizer_epoch)

            new_params = [params_list[param][0] + rand() *(params_list[param][1] - params_list[param][0]) for param in range(num_params)]
            print("[%d]" % optimizer_epoch, "%s/%d" % (FLAGS.job_name,FLAGS.task_index),
                  "Optimization RUN for Hyperparams:",new_params)
            new_loss, y_hat = model_func(new_params, X_train, X_test, Y_train, Y_test,
                                         nodes_per_layer, batch_size, optimizer_epoch, train_epochs)

            # error handling
            if new_loss == -1:
                print("%s/%d" % (FLAGS.job_name,FLAGS.task_index), "Training Error..!!")
                continue

            if new_loss[-1] < best_loss:
                if abs(best_loss - float(new_loss[-1])) > tolerance:
                    best_loss = new_loss[-1]
                    best_params = new_params
                    best_itr = optimizer_epoch
                else:
                    print("%s/%d" % (FLAGS.job_name,FLAGS.task_index), "Loss Converged...")
                    return {'#best_params': new_params, 'best_loss': new_loss[-1], 'best_itr': best_itr}
                    #break

            if(not optimizer_epoch % 10):
                print("[%d]" % optimizer_epoch, "%s/%d" % (FLAGS.job_name,FLAGS.task_index),
                      {'*best_params': best_params, 'best_loss': best_loss, 'best_itr':best_itr})


        print("y_hat[:5]===>",y_hat[:5])
        print("y_test[:5]==>",Y_test[:5])
        plt.plot(Y_test, y_hat, 'r.')
        plt.show()
        return {'#best_params': best_params, 'best_loss': best_loss, 'best_itr': best_itr}
