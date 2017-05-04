"""
    File name         : nn_distributed.py
    File Description  : Distributed Implementation Of Neural Network Using Tensorflow
    File Version      : 1.0
    Author            : Srini Ananthakrishnan
    Date created      : 04/19/2017
    Date last modified: 05/04/2017
    Python Version    : 3.5
    Tensorflow Version: 1.0.1
"""

# import packages
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import time
import pickle
import tensorflow as tf
import logging as logger
import numpy as np
from nn_model import NeuralNetwork
from prepare_data import PrepareData


# Disable info/warnings
tf.logging.set_verbosity(tf.logging.ERROR)

flags = tf.app.flags
flags.DEFINE_integer("task_index", None,
                     "Worker task index, should be >= 0. task_index=0 is "
                     "the master worker task the performs the variable "
                     "initialization ")
flags.DEFINE_integer("replicas_to_aggregate", None,
                     "Number of replicas to aggregate before parameter update"
                     "is applied (For sync_replicas mode only; default: "
                     "num_workers)")
# flags.DEFINE_boolean(
#     "existing_servers", False, "Whether servers already exists. If True, "
#     "will use the worker hosts via their GRPC URLs (one client process "
#     "per worker host). Otherwise, will create an in-process TensorFlow "
#     "server.")
flags.DEFINE_string("ps_hosts","localhost:2222",
                    "Comma-separated list of hostname:port pairs")
flags.DEFINE_string("worker_hosts", "localhost:2223,localhost:2224",
                    "Comma-separated list of hostname:port pairs")
flags.DEFINE_string("job_name", None,"job name: worker or ps")

FLAGS = flags.FLAGS

# Graph Node
GNODE = "%s/%d" % (FLAGS.job_name,FLAGS.task_index)


def build_dnn_regressor(X_train, Y_train, epoch_config, epoch_result, logging):
    """Build and execute tensorflow DNN Regressot Graph
    
    Args:
        hyperparam: hyperparameters to build and execute the graph
        X_train: input training features of shape (N,M)
        Y_train: target training output of shape (N,)
        epoch_result: dict to store epoch training loss result
        logging: handler for logging macro
            
    epoch_config:
        opt_epoch_iter: Optimizer (outer-loop) iteration number
        train_epoch: Number of training epochs (inner-loop)
        batch_size: batch size for training
        train_tolerance: training loss convergence tolerance
        
    Returns: 
        costs: recored history of costs or loss per hyperparam optimizer iteration
    """

    # reset tensorflow graph
    tf.reset_default_graph()
    tf.set_random_seed(12345)

    if FLAGS.job_name is None or FLAGS.job_name == "":
        raise ValueError("Must specify an explicit `job_name`")
    if FLAGS.task_index is None or FLAGS.task_index == "":
        raise ValueError("Must specify an explicit `task_index`")

    logging.info("opt_epoch_iter =========> [ %d ] job name=%s task index=%d",
                 epoch_config['opt_epoch_iter'], FLAGS.job_name, FLAGS.task_index)

    # Construct the cluster and start the server
    ps_spec = FLAGS.ps_hosts.split(",")
    worker_spec = FLAGS.worker_hosts.split(",")

    # Get the number of workers.
    num_workers = len(worker_spec)

    cluster = tf.train.ClusterSpec({
        "ps": ps_spec,
        "worker": worker_spec})

    server = tf.train.Server(cluster, job_name=FLAGS.job_name,
                             task_index=FLAGS.task_index)

    if epoch_config['num_gpus'] > 0:
        # If true, the allocator does not pre-allocate the entire specified
        # GPU memory region, instead starting small and growing as needed.
        gpu_options = tf.GPUOptions(allow_growth=True)
    else:
        # Default
        gpu_options = tf.GPUOptions(allow_growth=False)


    sess_config = tf.ConfigProto(
        allow_soft_placement=True,
        log_device_placement=False,
        gpu_options=gpu_options,
        device_filters=["/job:ps", "/job:worker/task:%d" % FLAGS.task_index])

    if FLAGS.job_name == "ps":
        logging.info("[%d] %s ps: server join", epoch_config['opt_epoch_iter'], GNODE)
        server.join()

    elif FLAGS.job_name == "worker":
        is_chief = (FLAGS.task_index == 0)
        if epoch_config['num_gpus'] > 0:
            # https://github.com/tensorflow/tensorflow/issues/7312
            # if epoch_config['num_gpus'] < num_workers:
            #     raise ValueError("number of gpus is less than number of workers")
            # Avoid gpu allocation conflict: now allocate task_num -> #gpu
            # for each worker in the corresponding machine
            gpu = (FLAGS.task_index % epoch_config['num_gpus'])
            worker_device = "/job:worker/task:%d/gpu:%d" % (FLAGS.task_index, gpu)
        elif epoch_config['num_gpus'] == 0:
            # Just allocate the CPU to worker server
            cpu = 0
            worker_device = "/job:worker/task:%d/cpu:%d" % (FLAGS.task_index, cpu)

        # The device setter will automatically place Variables ops on separate
        # parameter servers (ps). The non-Variable ops will be placed on the workers.
        # The ps use CPU and workers use corresponding GPU
        with tf.device(
                tf.train.replica_device_setter(
                    worker_device=worker_device,
                    ps_device="/job:ps/cpu:0",
                    cluster=cluster)):

            NN = NeuralNetwork()
            opt = NN.build_model(FLAGS, epoch_config, logging)

            if epoch_config['sync_replicas'] == True:
                # You can create the hook which handles initialization and queues.
                sync_replicas_hook = opt.make_session_run_hook(is_chief=is_chief,
                                                               num_tokens=num_workers)

        if epoch_config['sync_replicas'] == True:
            hooks = [sync_replicas_hook, tf.train.StopAtStepHook(last_step=epoch_config['train_epoch'])]
        else:
            hooks = [tf.train.StopAtStepHook(last_step=epoch_config['train_epoch'])]

        # Perform training
        time_begin = time.time()
        logging.info("[%d] Training begins @ %f", epoch_config['opt_epoch_iter'], time_begin)

        # Initialize local variables
        prev_loss = 0.0
        train_epoch_itr = 0
        tolerance = epoch_config['train_tolerance']

        # The MonitoredTrainingSession takes care of session initialization,
        # restoring from a checkpoint, saving to a checkpoint, and closing when done
        # or an error occurs.
        with tf.train.MonitoredTrainingSession(master=server.target,
                                               is_chief=is_chief,
                                               #checkpoint_dir=epoch_config['train_log_dir'],
                                               hooks=hooks,
                                               config=sess_config) as sess:
            while not sess.should_stop():
                # randomly pick input (row) and targeted output vectors from N
                indices = np.random.randint(len(X_train), size=epoch_config['batch_size'])
                _f = X_train[indices, :]
                _y = Y_train[indices]

                costs = NN.train(sess, _f, _y, epoch_config)
                if costs == -1:
                    return -1, -1

                now = time.time()
                if (not train_epoch_itr % 200):
                    logging.info("[%d] %s/%d %f: training step %d done with Loss %f",
                                 epoch_config['opt_epoch_iter'], FLAGS.job_name, FLAGS.task_index, now,
                                 train_epoch_itr, costs[-1])

                # error tolerance threshold
                if abs(prev_loss - float(costs[-1])) > tolerance:
                    prev_loss = costs[-1]
                else:
                    if costs[-1] > 99999.0:
                        # Ignore the iteration.
                        continue
                    else:
                        logging.info("avg_loss: %f prev_loss: %f",costs[-1], prev_loss)
                        logging.info("LOSS CONVERGED...at epoch %d",train_epoch_itr)
                        break

                train_epoch_itr = train_epoch_itr + 1

        time_end = time.time()
        logging.info("[%d] Training ends @ %f", epoch_config['opt_epoch_iter'], time_end)
        training_time = time_end - time_begin
        logging.info("[%d] Training elapsed time: %f s", epoch_config['opt_epoch_iter'], training_time)

        worker_loss = "opt_epoch_loss_%d" % (FLAGS.task_index)
        epoch_result[worker_loss] = costs[-1]
        pickle.dump(epoch_result, open("epoch_result.p", "wb"))

        logging.info("FINAL Training Loss:%f", costs[-1])


def main(unused_argv):
    """Main routine to train, validate and optimize neural network
    
    Args:
        unused_argv: unused to make compiler happy
    
    Returns: 
        None. Prints results (best params) of hyperparam optimization
    """

    # Load Epoch Config and Results
    epoch_config = pickle.load(open("epoch_config.p", "rb"))
    epoch_result = pickle.load(open("epoch_result.p", "rb"))

    # Initialize variables to prepare synthetic data
    N = epoch_config['data_instances']
    M = epoch_config['data_features']

    # Synthetic Data generation parameters
    PD = PrepareData()
    X_train, X_test, Y_train, Y_test = PD.generateData(FLAGS, N, M)

    # Configure custom logger
    log_file = "%s/%s_%d.log"%(epoch_config['train_log_dir'],FLAGS.job_name,FLAGS.task_index)
    logging = logger.getLogger('train_opt')
    logger.basicConfig(filename=log_file, level=logger.INFO)

    logging.info("\n")
    if epoch_config['opt_epoch_iter'] == 1:
        logging.info("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        logging.info("NEW RUN of OPTIMIZER EPOCHs.....")
        logging.info("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    logging.info('Epoch config for opt_iter:[ %d ]',epoch_config['opt_epoch_iter'])
    logging.info(epoch_config)

    # Build and Execute TensorFlow Graph
    build_dnn_regressor(X_train, Y_train, epoch_config, epoch_result, logging)


if __name__ == "__main__":
    tf.app.run()


