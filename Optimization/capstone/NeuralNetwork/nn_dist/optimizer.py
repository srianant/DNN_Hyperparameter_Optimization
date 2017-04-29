"""
    File name         : optimizer.py
    File Description  : Hyper Parameter Optimizer Framework
    File Version      : 1.0
    Author            : Srini Ananthakrishnan
    Date created      : 04/28/2017
    Date last modified: 04/28/2017
    Python Version    : 3.5
    Tensorflow Version: 1.0.1
"""

# import packages
import subprocess
import logging as logger
import yaml
import os
import signal
import time
import select
from nn_optimizer import *
from sacred import Experiment
from sacred.observers import MongoObserver

ex = Experiment()
mongo_observer = MongoObserver.create()
ex.observers.append(mongo_observer)
ex.add_config('optimizer_config.yaml')

# Configure your logger here
logging = logger.getLogger('hyper_opt')
ex.logger = logging
logger.basicConfig(filename='hyper_opt.log', level=logger.INFO)

def loadClusterSpec(filename):
    # Load Cluster Spec
    cluster_spec = yaml.load(open(os.path.expanduser(filename)))

    # Populate Cluster Spec
    PS_HOSTS = cluster_spec['cluster']['ps_hosts']
    WORKER_HOSTS = cluster_spec['cluster']['worker_hosts']
    NUM_PS = cluster_spec['cluster']['num_ps']
    NUM_WORKER = cluster_spec['cluster']['num_worker']

    return PS_HOSTS, WORKER_HOSTS, NUM_PS, NUM_WORKER


def runcmd(cmd):
    print("cmd: %s",cmd)
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


def forkClusterJobs(filename, _config):
    """Fork Worker and PS Cluster process
    
    Args:
        filename: Python file that implements TF distributed processing
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

    if(os.path.exists("/tmp/nn_dist")):
        print("Deleteing /tmp/nn_dist")
        os.system("rm -rf /tmp/nn_dist")

    # Fork process
    time_begin = time.time()
    print("Forking Worker/PS Cluster Jobs @ ", time_begin)

    # Code for subproc and handling referenced from below link
    # http://stackoverflow.com/questions/3194018/wait-the-end-of-subprocesses-with-multiple-parallel-jobs
    pids = []

    for task_index in range(num_ps):
        subproc = runcmd('python nn_distributed.py --ps_hosts=%s --worker_hosts=%s --job_name=%s --task_index=%d'%(PS_HOSTS, WORKER_HOSTS, "ps", task_index))
        #print("ps process spawned:",subproc)
        pids.append(subproc.pid)

    for task_index in range(num_workers):
        subproc = runcmd('python nn_distributed.py --ps_hosts=%s --worker_hosts=%s --job_name=%s --task_index=%d'%(PS_HOSTS, WORKER_HOSTS, "worker", task_index))
        #print("worker process spawned:", subproc)
        pids.append(subproc.pid)
        subprocs[subproc.stdout.fileno()] = subproc
        poller.register(subproc.stdout, select.POLLHUP)

    print("Waiting for Worker process to complete....")
    done = False
    wp_count = 0

    #loop that polls until completion
    while True:
        for fd, flags in poller.poll(1): #never more than a second without a UI update
            print("poller flags:", flags, fd)
            done_proc = subprocs[fd]
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

    print("All Worker Process DONE...!!!")
    time_end = time.time()
    print("Worker processing ends @ ", time_end)
    processing_time = time_end - time_begin
    print("Worker processing elapsed time: ",processing_time," secs")

    # Let's kill both PS/Worker process
    processClusterJobs(filename, 'kill', None, pids)


def processClusterJobs(filename, mode='kill', _config=None, pids=None):
    """Tensorflow distributed cluster jobs fork or kill
    
    Args:
        filename: python file that perform distributed processing
        mode: fork or kill ps and worker process
        _config: epoch configuration sent to ps and worker
    Return:
         None
    """
    if mode == 'fork':
        forkClusterJobs(filename, _config)
    else:
        killClusterJobs(pids)


@ex.config
def my_config():
    """Default Configs for Hyper Parameter Optimization
    
    Returns:
         None
    """
    trainer         = 'Optimize'    # Optimizer Class Name
    hyperparam_opt  = 'RS'      # hyper parameter optimizer. Default RS: Random Search.

    # --------------------------------
    # Hyper Parameter For Optimization
    # --------------------------------
    nn_dimensions      = [4, 1]    # number of neural network nodes for [input, output]
                                # input: should match lenght of input matrix (X)
                                # output: should be 1: for regressor (Y predict for a row in X)
    batch_size      = [100, 1000]       # batch size as [lower_bound, upper_bound]
    learning_rate   = [0.001, 0.0001]   # learning rate as [lower_bound, upper_bound]
    hidden_layers   = [4, 10]   # hidden_layer [min, max]
    train_optimizer = ['Adam', 'sgd', 'Adagrad']    # optimizer to be used for train. Default is 'Adam'. Supports 'sgd', 'Adagrad'
    activation      = ['Relu','tanh']   # activation for non-linearity. Default is 'Relu'. Supports 'tanh'
    opt_epoch       = 3         # optimizer epoch is the outer loop for optimizing hyperparameters
    train_epoch     = 100       # training epoch is the inner loop for training input data
    train_tolerance = 1e-8      # inner train loop loss convergence threshold
    opt_tolerance   = 1e-5      # outer optimizer loop loss convergence threshold


    # -------------------------------------
    # Parameters to generate synthetic data
    # -------------------------------------
    data_instances  = 10000     # number of input data instances (N). Used ONLY load_data is false
    data_features   = 4         # number of input data instances (N). Used ONLY load_data is false
    add_noise       = False     # adds random noise to output Y (used if power_method is True)
    add_cosine      = False     # transforms Y to element wise cosine (used if power_method is True)
    power_method    = False     # generate matrix polynomial of incremental "power" of (M). Used ONLY load_data is false

    # -----------------------
    # Cluster server configs
    # -----------------------
    # ps_hosts = 'localhost:2223,localhost:2224'  # parameter server config
    # worker_hosts = 'localhost:2225,localhost:2226,localhost:2227,localhost:2228'    # worker server config
    ps_hosts = 'localhost:2223'  # parameter server config
    worker_hosts = 'localhost:2225'    # worker server config

    # ---------------------------------
    # Logging Level and Directory
    # ---------------------------------
    train_log_dir   = '/tmp/nn_dist/train_logs'  # training logs directory
    logging_level   = ['critical', 'error', 'warning', 'info', 'debug', 'notset'] # Default is info.
    load_data       = False     # When 'True' Load real data(X) of shape (N, M) and labels(Y) of shape (N,). Otherwise generate synthetic data.
    load_data_dir   = '/tmp/some_dir'   # Real data directory (like Boston, Iris, etc.)


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
    OPT = eval(_config['trainer'])(_config)

    #result = OPT.test_sacred()
    filename = "nn_distributed.py"
    result = OPT.optimize_params(processClusterJobs, filename)

    return result
