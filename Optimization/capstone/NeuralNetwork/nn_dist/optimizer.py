"""
    File name         : optimizer.py
    File Description  : Hyper Parameter Optimizer Framework
    File Version      : 1.0
    Author            : Srini Ananthakrishnan
    Date created      : 04/28/2017
    Date last modified: 05/05/2017
    Python Version    : 3.x
    Tensorflow Version: 1.0.1
"""

# import packages
import subprocess
import logging as logger
import yaml
import os
import signal
import shutil
import time
import select
import pickle
import numpy as np
from numpy.random import rand
from sacred import Experiment
from sacred.observers import MongoObserver
from pprint import pprint

ex = Experiment()
mongo_observer = MongoObserver.create()
ex.observers.append(mongo_observer)
ex.add_config('optimizer_config.yaml')

# Configure your logger here
logging = logger.getLogger('hyper_opt')
ex.logger = logging

class Optimizer(object):
    """Neural Network Hyperparameter Optimizer Class.
    """

    def __init__(self, config):
        """Optimize class object initialization

        Args:
            config: Epoch parameters and hyperparameters for training
        Returns:
            None
        """
        self.C = config  # save sacred config dict
        self.epoch_config = {}  # initialize epoch config dict
        self.epoch_result = {}  # initialize result config dict


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
            print("Must provide at least one activation. Defaulting to relu")
            self.C['activation'] = 'relu'
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
        if self.C['num_gpus'] < 0 and self.C['num_gpus'] > 9999:
            raise ValueError(" Number of GPUs should between 0 - 9999 ")
        if len(self.C['nn_model']) == 0:
            raise ValueError("Model is not specified..!!")
        if self.C['rnn_max_seq_length'] <= 0:
            raise ValueError('RNN max sequence length should be positive integer')
        if len(self.C['rnn_state_dim']) == 0:
            raise ValueError('RNN state dim should be int or int[]. Cannot be zero')
        if type(self.C['nn_model']) == list:
            print("nn_model must be specified. Usage: python optimizer.py nn_model='Regressor'")
            print("Defaulting to 'Regressor")
            self.C['nn_model'] = 'Regressor'
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
                return [input_dim] + list(np.random.randint(bounds[0], bounds[1], size=total_hidden_layers)) + [
                    output_dim]

            if type(self.C['activation']) == str:
                self.epoch_config.update({'activation': self.C['activation']})
            else:
                activation = self.C['activation'][np.random.randint(0, len(self.C['activation']))]
                self.epoch_config.update({'activation': activation})

            batch_size = np.random.randint(self.C['batch_size'][0], self.C['batch_size'][1])
            self.epoch_config.update({'batch_size': batch_size})

            lr_params_list = [self.C['learning_rate']]
            num_params = len(lr_params_list)
            learning_rate = [lr_params_list[param][0] + rand() * (lr_params_list[param][1] - lr_params_list[param][0])
                             for param in range(num_params)]
            self.epoch_config.update({'learning_rate': learning_rate[0]})

            if type(self.C['train_optimizer']) == str:
                self.epoch_config.update({'train_optimizer': self.C['train_optimizer']})
            else:
                train_optimizer = self.C['train_optimizer'][np.random.randint(0, len(self.C['train_optimizer']))]
                self.epoch_config.update({'train_optimizer': train_optimizer})

            if opt_epoch_iter == 1:
                hidden_layer_bounds = [self.C['hidden_layers'][0], self.C['hidden_layers'][1]]
                self.epoch_config.update({'hidden_layer_bounds': hidden_layer_bounds})
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
            worker_loss = "opt_epoch_loss_%d" % (worker_index)
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
        self.epoch_config.update({'nn_model': self.C['nn_model']})
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
        self.epoch_config.update({'rnn_max_seq_length': self.C['rnn_max_seq_length']})
        self.epoch_config.update({'rnn_state_dim': self.C['rnn_state_dim']})
        self.epoch_config.update({'load_data_dir': self.C['load_data_dir']})

        if self.C['load_data'] == False:
            self.epoch_config.update({'input_dim': self.C['nn_dimensions'][0]})
            self.epoch_config.update({'output_dim': self.C['nn_dimensions'][1]})
            self.epoch_config.update({'add_cosine': self.C['add_cosine']})
            self.epoch_config.update({'add_noise': self.C['add_noise']})
            self.epoch_config.update({'power_method': self.C['power_method']})
            self.epoch_config.update({'data_features': self.C['data_features']})
            self.epoch_config.update({'data_instances': self.C['data_instances']})

        self.epoch_config.update({'train_log_dir': self.C['train_log_dir']})

        # Use Random Search Algorithm To Find Parameters in Hyperspace
        self.random_search_for_params(opt_epoch_iter)

        # Dump built config to pickle file, so ps/worker can use
        pickle.dump(self.epoch_config, open("epoch_config.p", "wb"))


    def optimize_params(self, processClusterJobs):
        """Main function to optimize hyperparams. Loop in this routine is the outer-loop.

        Args:
            processClusterJobs: Function pointer to fork or kill ps/worker cluster jobs

        Returns:
            best loss of ALL optimizer (outer-loop) iteration
        """

        best_loss = 99999.0  # initialize to very high value
        worker_spec = self.C['worker_hosts'].split(",")
        num_workers = len(worker_spec)
        # python name file that performance distributed processing
        filename = self.C['file2distribute']

        for opt_epoch_iter in range(1, self.C['opt_epoch'] + 1):

            workers_loss = []
            self.build_epoch_config(opt_epoch_iter)
            self.build_epoch_result(opt_epoch_iter, num_workers)

            pprint('Epoch [%d] config:' % (opt_epoch_iter))
            pprint(self.epoch_config)

            print("START OF Optimizer EPOCH ====================>> [", opt_epoch_iter, "]")

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

            print("[%d]" % opt_epoch_iter, 'EPOCH LOSS:', new_loss, 'BEST LOSS:', best_loss)
            print("END OF Optimizer EPOCH =====================>>[", opt_epoch_iter, "]")
            print("\n")

        return best_loss


def loadClusterSpec(clusterConfigFile):
    # Load Cluster Spec
    cluster_spec = yaml.load(open(os.path.expanduser(clusterConfigFile)))

    # Populate Cluster Spec
    PS_HOSTS = cluster_spec['cluster']['ps_hosts']
    WORKER_HOSTS = cluster_spec['cluster']['worker_hosts']
    NUM_PS = cluster_spec['cluster']['num_ps']
    NUM_WORKER = cluster_spec['cluster']['num_worker']

    return PS_HOSTS, WORKER_HOSTS, NUM_PS, NUM_WORKER


def runcmd(cmd):
    """spawn new process and connect to stdout pipe 
    Args:   
        cmd: command to spawn new process 
    Return:
         subprocess id
    """
    return subprocess.Popen(cmd, bufsize=4096, shell=True, stdout=subprocess.PIPE)


def killClusterJobs(pids):
    """Kill Worker and PS Cluster Process
    Args:
        pids: Worker/PS process id 
    Retunrs:
        None
    """
    for pid in pids:
        os.kill(pid, signal.SIGUSR1)
    print("Cleanup Worker/PS Cluster Jobs..")


def forkClusterJobs(file2distribute, _config):
    """Fork Worker and PS Cluster process
    
    Args:
        file2distribute: Python file that implements TF distributed processing
        _config: Epoch config parameters and hyperparameters 
    Returns:
         None
    """

    ps_spec = _config['ps_hosts'].split(",")
    worker_spec = _config['worker_hosts'].split(",")

    PS_HOSTS = _config['ps_hosts']
    WORKER_HOSTS = _config['worker_hosts']

    # Get the number of workers/ps.
    num_ps = len(ps_spec)
    num_workers = len(worker_spec)

    poller = select.poll()
    subprocs = {}  # map stdout pipe's file descriptor to the Popen object

    train_log_dir = _config['train_log_dir']
    if(os.path.exists(train_log_dir) and _config['sync_replicas']):
        print("Deleteing old train dir, sync_replica is enabled...",train_log_dir)
        shutil.rmtree(train_log_dir)
    if(not os.path.exists(train_log_dir)):
        os.makedirs(train_log_dir)
    log_file = "%s/hyper_opt.log" % (train_log_dir)
    logger.basicConfig(filename=log_file, level=logger.INFO)

    # Fork process
    time_begin = time.time()
    print("Forking Worker/PS Cluster Jobs @ ", time_begin)

    # Code for subproc and handling referenced from below link
    # http://stackoverflow.com/questions/3194018/wait-the-end-of-subprocesses-with-multiple-parallel-jobs
    pids = []

    if _config['num_gpus'] > 0:
        # Ref: https://stackoverflow.com/questions/39567835/tensorflow-out-of-memory-error-running-inception-v3-distributed-on-4-machines?rq=1
        for task_index in range(num_ps):
            subproc = runcmd('CUDA_VISIBLE_DEVICES='' python3 %s --ps_hosts=%s --worker_hosts=%s --job_name=%s --task_index=%d' % (
            file2distribute, PS_HOSTS, WORKER_HOSTS, "ps", task_index))
            pids.append(subproc.pid)

        for task_index in range(num_workers):
            subproc = runcmd('CUDA_VISIBLE_DEVICES=%d python3 %s --ps_hosts=%s --worker_hosts=%s --job_name=%s --task_index=%d' % (
                task_index, file2distribute, PS_HOSTS, WORKER_HOSTS, "worker", task_index))
            pids.append(subproc.pid)
            subprocs[subproc.stdout.fileno()] = subproc
            poller.register(subproc.stdout, select.POLLHUP)
    else:
        for task_index in range(num_ps):
            subproc = runcmd('python3 %s --ps_hosts=%s --worker_hosts=%s --job_name=%s --task_index=%d'%(file2distribute, PS_HOSTS, WORKER_HOSTS, "ps", task_index))
            pids.append(subproc.pid)

        for task_index in range(num_workers):
            subproc = runcmd('python3 %s --ps_hosts=%s --worker_hosts=%s --job_name=%s --task_index=%d'%(file2distribute, PS_HOSTS, WORKER_HOSTS, "worker", task_index))
            pids.append(subproc.pid)
            subprocs[subproc.stdout.fileno()] = subproc
            poller.register(subproc.stdout, select.POLLHUP)

    print("Waiting for Worker process to complete....")
    done = False
    wp_count = 0

    #loop that polls until completion
    while True:
        for fd, flags in poller.poll(1): #never more than a second without a UI update
            #done_proc = subprocs[fd]
            poller.unregister(fd)
            #print("Worker process", done_proc, "is done!!!!")
            wp_count = wp_count + 1
            if wp_count == num_workers:
                done = True
                break
            print(wp_count,"/",num_workers," of Worker Process Done..!!")
        # break when all workers are done
        if done:
            break
    print(wp_count,"/",num_workers," of Worker Process DONE..!!")
    time_end = time.time()
    print("Worker processing ends @ ", time_end)
    processing_time = time_end - time_begin
    print("Worker processing elapsed time: ",processing_time,"secs")

    # Let's kill both PS/Worker process
    processClusterJobs(file2distribute, 'kill', None, pids)


def processClusterJobs(file2distribute, mode='kill', _config=None, pids=None):
    """Tensorflow distributed cluster jobs fork or kill
    
    Args:
        file2distribute: python file that perform distributed processing
        mode: fork or kill ps and worker process
        _config: epoch configuration sent to ps and worker
    Return:
         None
    """
    if mode == 'fork':
        forkClusterJobs(file2distribute, _config)
    else:
        killClusterJobs(pids)


def build_stage_config(_config, epoch_config):
    """Build stage configuration
    
    Args:
        _config: previous stage config
        best_epoch_config: best config results from previous stage
    Returns:
        Next stage config
    """
    # Determine the lower and upper bounds based on previous stage results
    # Formula: [p - p/2 ,p + p/2] will be [LB, UB]. Where p is prev_config.

    _lb = epoch_config['batch_size'] - epoch_config['batch_size']/2
    _ub = epoch_config['batch_size'] + epoch_config['batch_size']/2
    _config['batch_size'] = [_lb, _ub]

    _lb = epoch_config['learning_rate'] - epoch_config['learning_rate']/2.0
    _ub = epoch_config['learning_rate'] + epoch_config['learning_rate']/2.0
    _config['learning_rate'] = [_lb, _ub]

    _lb = min(epoch_config['nodes_per_layer'])
    _ub = max(epoch_config['nodes_per_layer'])
    _config['hidden_layers'] = [_lb, _ub]

    return _config


@ex.config
def my_config():
    """Default Configs for Hyper Parameter Optimization
    
    Returns:
         None
    """
    # ------------------------------------------
    # Class object 'name' instantiated by sacred
    # ------------------------------------------
    trainer         = 'Optimizer'    # Optimizer Class Name.

    # -------------------------------------
    # File to be forked for distributed jobs
    # -------------------------------------
    file2distribute = 'nn_distributed.py'   # File to be forked for distributed jobs

    # ------------------------------------------
    # Neural Network Model
    # ------------------------------------------
    nn_model        = ['Regressor', 'Custom']  # Neural Network Model

    # ------------------------------------------
    # Algorithm for Hyperparameter Optimization
    # ------------------------------------------
    hyperparam_opt  = 'RS'      # hyper parameter optimizer. Default RS: Random Search.

    # --------------------------------
    # Hyperparameters For Optimization
    # --------------------------------
    nn_dimensions   = [4, 1]    # number of neural network nodes for [input, output]
                                # input: should match lenght of input matrix (X)
                                # output: should be 1: for regressor (Y predict for a row in X)
    batch_size      = [100, 1000]       # batch size as [lower_bound, upper_bound]
    learning_rate   = [0.001, 0.0001]   # learning rate as [lower_bound, upper_bound]
    hidden_layers   = [4, 10]   # hidden_layer [min, max]
    train_optimizer = ['Adam', 'sgd', 'Adagrad']    # optimizer to be used for train. Default is 'Adam'. Supports 'sgd', 'Adagrad'
    activation      = ['relu','tanh']   # activation for non-linearity. Default is 'relu'. Supports 'tanh'
    opt_epoch       = 3         # optimizer epoch is the outer loop for optimizing hyperparameters
    train_epoch     = 100       # training epoch is the inner loop for training input data
    train_tolerance = 1e-8      # inner train loop loss convergence threshold
    opt_tolerance   = 1e-5      # outer optimizer loop loss convergence threshold
    rnn_max_seq_length  = 100   # int Maximum length of the traning sequences to generate
    rnn_state_dim   = [50, 50, 50]  # int or int[] State dimension. Can use a list to stack RNNs.

    # --------------------------------------------------
    # Parameters for regressor synthetic data generation
    # Valid ONLY when load_data is false
    # --------------------------------------------------
    data_instances  = 10000     # number of input data instances (N). Used ONLY load_data is false
    data_features   = 4         # number of input data features (M). Used ONLY load_data is false
    add_noise       = False     # adds random noise to output Y (used if power_method is True)
    add_cosine      = False     # transforms Y to element wise cosine (used if power_method is True)
    power_method    = False     # generate matrix polynomial of incremental "power" of (M). Used ONLY load_data is false

    # ---------------------------------
    # Logging Level and Directory
    # ---------------------------------
    train_log_dir   = '/tmp/nn_dist/train_logs'  # training logs directory
    #logging_level   = ['critical', 'error', 'warning', 'info', 'debug', 'notset'] # Default is info.
    load_data       = False     # When 'True' Load real data(X) of shape (N, M) and labels(Y) of shape (N,). Otherwise generate synthetic data.
    load_data_dir   = 'data/source_code'   # Real data directory (like Boston, Iris, etc.)

    # ----------------------------------------------------
    # TensorFlow Sync_Replicas (synchronized workers) mode
    # In this mode the parameter updates from workers are
    # aggregated before applied to avoid stale gradients
    # ----------------------------------------------------
    sync_replicas   = False  # Use the sync_replicas (synchronized replicas) mode

    # -------------------------------------
    # Tensorflow GPU config
    # -------------------------------------
    num_gpus        = 0  # Number of GPUs. If > 0 GPUs will be used by Worker. Otherwise CPUs.

    # ----------------------------------------------------------------
    # Stages: Number of time Optimizer and Training Epochs are run
    # Usage:
    # Stage 1 - largest search:
    #   Inner iterations = 1K
    #   Outer iterations = 10K
    #
    # Stage 2 - search with smaller volume around best pt of Stage 1:
    #   Inner iterations = 5K
    #   Outer iterations = 2K
    #
    # Stage 3 - search with smaller volume around best pt from Stage 2:
    #   Inner iterations = 10K
    #   Outer iterations = 1K
    # Note: Very Very CPU intensive
    # Syntax: opt_stages = [[Inner,Outer]]
    # -----------------------------------------------------------------
    running_stage   = 0     # placeholder to indicate running stage. Not a configuration.
    # Default config. Keeping it on lower range so it can run on local CPU
    opt_stages      = [[1000,4],[700,3],[500,2]]    # [Stage_1, Stage_2, Stage_3] with each stage has [Outer_loop, Inner_loop] epoch
    # For Training On Cloud
    # opt_stages      = [[1000,10000],[5000,2000],[10000,1000]]

    # -----------------------
    # Cluster server configs
    # -----------------------
    ps_hosts        = 'localhost:2223,localhost:2224'  # parameter server config
    worker_hosts    = 'localhost:2225,localhost:2226,localhost:2227,localhost:2228' # worker server config
    # ps_hosts        = 'localhost:2223'  # parameter server config
    # worker_hosts    = 'localhost:2225'  # worker server config



@ex.automain
def main(_config, _run):
    """Run a sacred experiment

    Parameters
    ----------
    _config : special dict populated by sacred with the local variables computed
    in my_config() which can be overridden from the command line or with
    ex.run(config_updates=<dict containing config values>)
    _run : special object passed in by sacred which contains (among other
    things) the name of this run

    This function will be run if this script is run either from the command line
    with

    $ python optimizer.py

    or from within python by

    >>> from optimizer import ex
    >>> ex.run()

    """
    _config['name'] = _run.meta_info['options']['--name']

    opt_stages = _config['opt_stages']
    num_stages = len(opt_stages)

    if num_stages > 0:
        for stage in range(num_stages):

            print("START OF STAGED EPOCH #######################>> [",stage+1,"]")

            _config['running_stage'] = stage+1 # indicates to user running stage
            _config['train_epoch']   = opt_stages[stage][0] # Training Epoch (Inner_Loop)
            _config['opt_epoch']     = opt_stages[stage][1] # Optimizer Epoch (Outer_Loop)

            if stage > 0:
                _config = build_stage_config(_config, best_epoch_config)

            OPT = eval(_config['trainer'])(_config)
            result = OPT.optimize_params(processClusterJobs)

            # Load results of best worker
            best_epoch_config = pickle.load(open("epoch_best_config.p", "rb"))

            print("END OF STAGED EPOCH #######################>>[",stage+1,"]")
    else:
        OPT = eval(_config['trainer'])(_config)
        result = OPT.optimize_params(processClusterJobs)

        # Load results of best worker
        best_epoch_config = pickle.load(open("epoch_best_config.p", "rb"))

    print("=========================")
    print("Summary:")
    print("=========================")
    print("Stages.......:", opt_stages)
    print("FINAL LOSS...:", result)
    print("=========================")

    # print BEST epoch run config
    pprint('BEST Epoch config:')
    print("--------------------")
    pprint(best_epoch_config)

    return result
