"""
    File name         : nn_optimizer.py
    File Description  : Hyper Parameter Optimizer Class for Neural Network
    File Version      : 1.0
    Author            : Srini Ananthakrishnan
    Date created      : 04/19/2017
    Date last modified: 04/28/2017
    Python Version    : 3.5
    Tensorflow Version: 1.0.1
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import pickle
import numpy as np
from numpy.random import rand
from pprint import pprint

class Optimize(object):
    """Neural Network Hyper Parameter Optimizer Class.
    Optimize hyperparameters for feed forward neural network 
    """

    def __init__(self, config):
        """Optimize class object initialization
        
        Args:
            config: Epoch parameters and hyperparameters for training
        Returns:
            None
        """
        self.C = config # save sacred config dict
        self.epoch_config = {} # initialize epoch config dict
        self.epoch_result = {} # initialize result config dict


    def validate_user_params(self):
        """Validate user params and check for boundary conditions
        
        Returns:
             None
        Raise:
            Various ValueError if condition fails
        """
        if len(self.C['nn_dimensions']) != 2:
            raise ValueError("Incorrect neural network dimensions. Must provide [input_dim, output_dim]")
        if len(self.C['hidden_layers']) != 2:
            raise ValueError("Incorrect hidden layers. Must provide [min, max]")
        if len(self.C['batch_size']) != 2:
            raise ValueError("Incorrect batch size. Must provide [lower_bound, upper_bound]")
        if len(self.C['activation']) < 1:
            print("Must provide at least one activation. Defaulting to Relu")
            self.C['activation'] = 'Relu'
        if len(self.C['learning_rate']) != 2:
            raise ValueError("Incorrect learning rate. Must provide [lower_bound, upper_bound]")
        if self.C['hyperparam_opt'] != 'RS':
            raise ValueError("Currently only supports random search (RS)...stay tuned for more !!")
        if len(self.C['train_optimizer']) < 1:
            print("Must provide at least train optimizer. Defaulting to Adam")
            self.C['train_optimizer'] = 'Adam'
        if self.C['opt_tolerance'] == None or self.C['opt_tolerance'] <= 0:
            print("Defaulting opt_tolerance to 1.0e-05")
            self.C['opt_tolerance'] = 1.0e-05
        if self.C['train_tolerance'] == None or self.C['train_tolerance'] <= 0:
            print("Defaulting train_tolerance to 1.0e-05")
            self.C['train_tolerance'] = 1.0e-08
        if self.C['opt_epoch'] <= 0 or type(self.C['opt_epoch']) != int:
            raise ValueError("Must provide a positive integer number")
        if self.C['train_epoch'] <= 0 or type(self.C['train_epoch']) != int:
            raise ValueError("Must provide a positive integer number")
        if self.C['load_data'] != False:
            raise ValueError("Loading real data is not supported...coming soon !!")
        if self.C['num_gpus'] < 0 and self.C['num_gpus'] > 9999:
            raise ValueError(" Number of GPUs should between 0 - 9999 ")
        if len(self.C['logging_level']) > 1:
            self.C['logging_level'] = 'info'
        # Add new/additional parameter checking above this line


    def random_search_for_params(self, opt_epoch_iter):
        """Use Random Search Algorithm To Find Parameters in Hyperspace
        
        Returns:
             None
        """

        # Use Random Search (RS) as hyperparameter algorithm
        if self.C['hyperparam_opt'] == 'RS':

            def gen_nn_arch(input_dim, bounds, output_dim):
                # Generate NN nodes per layer
                total_hidden_layers = np.random.randint(bounds[0], bounds[1])
                return [input_dim] + list(np.random.randint(bounds[0], bounds[1], size=total_hidden_layers)) + [output_dim]

            activation = self.C['activation'][np.random.randint(0, len(self.C['activation']))]
            self.epoch_config.update({'activation':activation})

            batch_size = np.random.randint(self.C['batch_size'][0], self.C['batch_size'][1])
            self.epoch_config.update({'batch_size':batch_size})

            lr_params_list = [self.C['learning_rate']]
            num_params = len(lr_params_list)
            learning_rate = [lr_params_list[param][0] + rand() * (lr_params_list[param][1] - lr_params_list[param][0])
                             for param in range(num_params)]
            self.epoch_config.update({'learning_rate':learning_rate[0]})

            train_optimizer = self.C['train_optimizer'][np.random.randint(0, len(self.C['train_optimizer']))]
            self.epoch_config.update({'train_optimizer':train_optimizer})

            if opt_epoch_iter == 1:
                hidden_layer_bounds = [self.C['hidden_layers'][0], self.C['hidden_layers'][1]]
                self.epoch_config.update({'hidden_layer_bounds':hidden_layer_bounds})
            else:
                # for all other iterations. hidden_layer_bounds is a list of [lb, ub]
                hidden_Layer_LB = min(self.epoch_config['hidden_layer_bounds'])
                hidden_layer_UB = max(self.epoch_config['hidden_layer_bounds'])
                self.epoch_config['hidden_layer_bounds'] = [hidden_Layer_LB, hidden_layer_UB]

            nodes_per_layer = gen_nn_arch(self.C['nn_dimensions'][0],
                                          self.epoch_config['hidden_layer_bounds'],
                                          self.C['nn_dimensions'][1])
            self.epoch_config.update({'nodes_per_layer': nodes_per_layer})

        else:
            raise ValueError("Unsupported hyper param optimizer type..!!")


    def save_best_config(self):
        """Save best epoch config to pickle
        
        Returns:
             None
        """
        # Dump best config to pickle file
        pickle.dump(self.epoch_config, open("epoch_best_config.p", "wb"))


    def build_epoch_result(self, opt_epoch_iter, num_workers):
        """Build Optimizer epoch result and write the initialized value to pickle file
        
        Args:
            opt_epoch_iter: Optimizer epoch iteration
        Returns:
             None
        """
        self.epoch_result.update({'opt_epoch_iter': opt_epoch_iter})
        for worker_index in range(num_workers):
            worker_loss = "opt_epoch_loss_%d"%(worker_index)
            self.epoch_result.update({worker_loss: 9999.00})
        # Dump to pickle file. Worker nodes will update loss information
        pickle.dump(self.epoch_result, open("epoch_result.p", "wb"))


    def build_epoch_config(self, opt_epoch_iter):
        """Build Optimizer epoch config and write the initialized value to pickle file

        Args:
            opt_epoch_iter: Optimizer epoch iteration
        Returns:
             None
        """
        self.validate_user_params()

        self.epoch_config.update({'opt_epoch_iter': opt_epoch_iter})
        self.epoch_config.update({'sync_replicas': self.C['sync_replicas']})
        self.epoch_config.update({'file2distribute': self.C['file2distribute']})
        self.epoch_config.update({'ps_hosts': self.C['ps_hosts']})
        self.epoch_config.update({'worker_hosts': self.C['worker_hosts']})
        self.epoch_config.update({'train_tolerance': self.C['train_tolerance']})
        self.epoch_config.update({'opt_tolerance': self.C['opt_tolerance']})
        self.epoch_config.update({'train_epoch': self.C['train_epoch']})
        self.epoch_config.update({'opt_epoch': self.C['opt_epoch']})
        self.epoch_config.update({'load_data': self.C['load_data']})
        self.epoch_config.update({'num_gpus': self.C['num_gpus']})
        self.epoch_config.update({'running_stage': self.C['running_stage']})

        if self.C['load_data'] == False:
            self.epoch_config.update({'input_dim': self.C['nn_dimensions'][0]})
            self.epoch_config.update({'output_dim': self.C['nn_dimensions'][1]})
            self.epoch_config.update({'add_cosine': self.C['add_cosine']})
            self.epoch_config.update({'add_noise': self.C['add_noise']})
            self.epoch_config.update({'power_method': self.C['power_method']})
            self.epoch_config.update({'data_features': self.C['data_features']})
            self.epoch_config.update({'data_instances': self.C['data_instances']})
        else:
            self.epoch_config.update({'load_data_dir': self.C['load_data_dir']})

        self.epoch_config.update({'train_log_dir': self.C['train_log_dir']})
        if len(self.C['logging_level']) > 1:
            self.epoch_config.update({'logging_level': 'info'})
        else:
            self.epoch_config.update({'logging_level': self.C['logging_level']})

        # Use Random Search Algorithm To Find Parameters in Hyperspace
        self.random_search_for_params(opt_epoch_iter)

        # Dump built config to pickle file, so ps/worker can use
        pickle.dump(self.epoch_config, open("epoch_config.p", "wb"))


    def test_sacred(self):
        """Method to test Sacred and Sacredboard platform
        
        Returns:
             Fake loss value randomly generated 
        """

        self.build_epoch_config(1)
        pprint('Epoch config:')
        pprint(self.epoch_config)
        loss = rand()
        return loss


    def optimize_params(self, processClusterJobs):
        """Main function to optimize hyperparams. Loop in this routine is the outer-loop.
        
        Args:
            processClusterJobs: Function pointer to fork or kill ps/worker cluster jobs
        
        Returns:
            best loss of ALL optimizer (outer-loop) iteration
        """

        best_loss = 99999.0 # initialize to very high value
        worker_spec = self.C['worker_hosts'].split(",")
        num_workers = len(worker_spec)
        # python name file that performance distributed processing
        filename = self.C['file2distribute']

        for opt_epoch_iter in range(1 , self.C['opt_epoch'] +1):

            workers_loss = []
            self.build_epoch_config(opt_epoch_iter)
            self.build_epoch_result(opt_epoch_iter, num_workers)

            pprint('Epoch [%d] config:'%(opt_epoch_iter))
            pprint(self.epoch_config)

            print("START OF Optimizer EPOCH ====================>> [",opt_epoch_iter,"]")

            # Fork PS/Worker Jobs for inner training loop
            processClusterJobs(filename, 'fork', self.epoch_config)

            # Load results of ALL worker
            epoch_result = pickle.load(open("epoch_result.p", "rb"))

            # Read ALL workers loss and report the maximum one
            for worker_index in range(num_workers):
                worker_loss_field = "opt_epoch_loss_%d" % (worker_index)
                workers_loss.append(epoch_result[worker_loss_field])

            # pick minimum of loss reported among workers
            new_loss = min(workers_loss)

            # error handling
            if new_loss == -1:
                print("Training Error!!..@ opt_epoch:", opt_epoch_iter)
                continue

            if new_loss < best_loss:
                if abs(best_loss - float(new_loss)) > self.C['opt_tolerance']:
                    best_loss = new_loss
                    self.save_best_config()
                else:
                    if new_loss == 99999.0:
                        # Something went wrong during training. Loss was not updated.
                        # Do nothing..
                        print("WARNING: Something went wrong during training. Loss was not determined.")
                        pass
                    else:
                        print("Optimizer LOSS CONVERGED...")
                        self.save_best_config()
                        return new_loss


            print("[%d]" % opt_epoch_iter,'EPOCH LOSS:',new_loss, 'BEST LOSS:',best_loss)
            print("END OF Optimizer EPOCH =====================>>[",opt_epoch_iter,"]")

        return best_loss
