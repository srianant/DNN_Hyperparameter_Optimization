"""
    File name         : nn_distributed.py
    File Description  : Distributed Implementation Of Neural Network Using Tensorflow
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

import time
import tensorflow as tf
from nn_model import NeuralNetwork
from nn_optimizer import Optimize
from prepare_data import PrepareData

# Disable warnings
tf.logging.set_verbosity(tf.logging.INFO)

flags = tf.app.flags
flags.DEFINE_integer("task_index", None,
                     "Worker task index, should be >= 0. task_index=0 is "
                     "the master worker task the performs the variable "
                     "initialization ")
flags.DEFINE_integer("num_gpus", 0,
                     "Total number of gpus for each machine."
                     "If you don't use GPU, please set it to '0'")
flags.DEFINE_integer("replicas_to_aggregate", None,
                     "Number of replicas to aggregate before parameter update"
                     "is applied (For sync_replicas mode only; default: "
                     "num_workers)")
flags.DEFINE_integer("train_steps", 10000,
                     "Number of (global) training steps to perform")
flags.DEFINE_integer("batch_size", 100, "Training batch size")
flags.DEFINE_float("learning_rate", 0.01, "Learning rate")
flags.DEFINE_boolean("sync_replicas", True,
                     "Use the sync_replicas (synchronized replicas) mode, "
                     "wherein the parameter updates from workers are aggregated "
                     "before applied to avoid stale gradients")
flags.DEFINE_boolean(
    "existing_servers", False, "Whether servers already exists. If True, "
    "will use the worker hosts via their GRPC URLs (one client process "
    "per worker host). Otherwise, will create an in-process TensorFlow "
    "server.")
flags.DEFINE_string("ps_hosts","localhost:2222",
                    "Comma-separated list of hostname:port pairs")
flags.DEFINE_string("worker_hosts", "localhost:2223,localhost:2224",
                    "Comma-separated list of hostname:port pairs")
flags.DEFINE_string("job_name", None,"job name: worker or ps")

FLAGS = flags.FLAGS

# Graph Node
GNODE = "%s/%d" % (FLAGS.job_name,FLAGS.task_index)


def build_and_execute_graph(hyperparam, X_train, X_test, Y_train, Y_test,
                            nodes_per_layer, batch_size, optimizer_epoch, train_epochs):
    """Build and execute tensorflow graph
    
    Args:
        hyperparam: hyperparameters to build and execute the graph
        f: input features of shape (N,)
        y: target output of shape (N,)
        nodes_per_layer: List contains number of nodes in each layers and its length determines number of layers
        batch_size: batch size for training
        optimizer_epochs: Optimizer (outer-loop) iteration number
        train_epochs: Trainner (inner-loop) iteration number
    
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

    print("[%d]" % optimizer_epoch, "job name = %s" % FLAGS.job_name, "task index = %d" % FLAGS.task_index)

    # Construct the cluster and start the server
    ps_spec = FLAGS.ps_hosts.split(",")
    worker_spec = FLAGS.worker_hosts.split(",")

    # Get the number of workers.
    num_workers = len(worker_spec)

    cluster = tf.train.ClusterSpec({
        "ps": ps_spec,
        "worker": worker_spec})

    # hyperparameters
    learning_rate = hyperparam[0]

    if not FLAGS.existing_servers:
        # Not using existing servers. Create an in-process server.
        server = tf.train.Server(
            cluster, job_name=FLAGS.job_name, task_index=FLAGS.task_index)
        if FLAGS.job_name == "ps":
            print("[%d]" % optimizer_epoch, GNODE,"ps: server join")
            server.join()

    is_chief = (FLAGS.task_index == 0)
    if FLAGS.num_gpus > 0:
        if FLAGS.num_gpus < num_workers:
            raise ValueError("number of gpus is less than number of workers")
        # Avoid gpu allocation conflict: now allocate task_num -> #gpu
        # for each worker in the corresponding machine
        gpu = (FLAGS.task_index % FLAGS.num_gpus)
        worker_device = "/job:worker/task:%d/gpu:%d" % (FLAGS.task_index, gpu)
    elif FLAGS.num_gpus == 0:
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
        global_step = tf.Variable(0, name="global_step", trainable=False)

        NN = NeuralNetwork()
        opt = NN.build_model(optimizer_epoch, train_epochs, FLAGS, global_step,
                             nodes_per_layer, learning_rate, optimizer="SGD")

        if FLAGS.sync_replicas:
            local_init_op = opt.local_step_init_op
            if is_chief:
                local_init_op = opt.chief_init_op

            ready_for_local_init_op = opt.ready_for_local_init_op

            # Initial token and chief queue runners required by the sync_replicas mode
            chief_queue_runner = opt.get_chief_queue_runner()
            sync_init_op = opt.get_init_tokens_op()

        saver = tf.train.Saver()
        init_op = tf.global_variables_initializer()
        # train_dir = tempfile.mkdtemp()
        summary_op = tf.summary.merge_all()

        if FLAGS.sync_replicas:
            sv = tf.train.Supervisor(
                    is_chief=is_chief,
                    logdir="/tmp/nn_dist/train_logs",
                    init_op=init_op,
                    local_init_op=local_init_op,
                    ready_for_local_init_op=ready_for_local_init_op,
                    recovery_wait_secs=1,
                    saver=saver,
                    global_step=global_step)
        else:
            sv = tf.train.Supervisor(
                    is_chief=is_chief,
                    logdir="/tmp/nn_dist/train_logs",
                    init_op=init_op,
                    summary_op=summary_op,
                    recovery_wait_secs=1,
                    saver=saver,
                    global_step=global_step)

        sess_config = tf.ConfigProto(
                    allow_soft_placement=True,
                    log_device_placement=False,
                    device_filters=["/job:ps", "/job:worker/task:%d" % FLAGS.task_index])

        # The chief worker (task_index==0) session will prepare the session,
        # while the remaining workers will wait for the preparation to complete.
        if is_chief:
          print("[%d]" % optimizer_epoch, GNODE,"Worker %d: Initializing session..." % FLAGS.task_index)
        else:
          print("[%d]" % optimizer_epoch, GNODE,"Worker %d: Waiting for session to be initialized..." %
                FLAGS.task_index)

        if FLAGS.existing_servers:
          server_grpc_url = "grpc://" + worker_spec[FLAGS.task_index]
          print("[%d]" % optimizer_epoch, GNODE,"Using existing server at: %s" % server_grpc_url)

          sess = sv.prepare_or_wait_for_session(server_grpc_url,
                                                config=sess_config)
        else:
          sess = sv.prepare_or_wait_for_session(server.target, config=sess_config)

        print("[%d]" % optimizer_epoch, GNODE,"Worker %d: Session initialization complete." % FLAGS.task_index)

        if FLAGS.sync_replicas and is_chief:
          # Chief worker will start the chief queue runner and call the init op.
          sess.run(sync_init_op)
          sv.start_queue_runners(sess, [chief_queue_runner])

        # Perform training
        time_begin = time.time()
        print("[%d]" % optimizer_epoch, GNODE,"Training begins @ %f" % time_begin)

        costs = NN.train(optimizer_epoch, train_epochs, FLAGS, sess, X_train, Y_train, batch_size, global_step)
        if costs == -1:
            #sv.stop()
            return -1, -1

        time_end = time.time()
        print("[%d]" % optimizer_epoch, GNODE,"Training ends @ %f" % time_end)
        training_time = time_end - time_begin
        print("[%d]" % optimizer_epoch, GNODE,"Training elapsed time: %f s" % training_time)

        # predict
        y_hat = NN.predict(X_test)
        print("[%d]" % optimizer_epoch, "Predicted y_hat[:5]==>",y_hat[:5])

    # Ask for all the services to stop.
    #sv.stop()

    # return results
    return costs, y_hat


def main(unused_argv):
    """Main routine to train, validate and optimize neural network
    
    Args:
        unused_argv: unused to make compiler happy
    
    Returns: 
        None. Prints results (best params) of hyperparam optimization
    """

    # initialize variables to prepare synthetic data
    N = 10000
    M = 4
    # Data generation parameters
    PD = PrepareData()
    X_train, X_test, Y_train, Y_test = PD.generateData(FLAGS, N, M)

    # FIX: this will be input as dictionary
    # define neural network nodes and execution variables
    nodes_per_layer = [M, 5, 4, 1]
    optimizer_epochs = 5
    train_epochs = 10000
    batch_size = 1000
    # execute tensorflow graph
    #params_list = [[0.1,0.00001], [0.01,0.00001]] #placeholder for 2 or more hyperparam search
    params_list = [[0.001,0.0001]]

    # instantiate hyper param optimize class
    OPT = Optimize()
    results = OPT.optimize_params(FLAGS, params_list, build_and_execute_graph,
                                  X_train, X_test, Y_train, Y_test,
                                  nodes_per_layer, optimizer_epochs, train_epochs, batch_size)

    if (results["best_loss"] != 99999.0):
        print(results)

if __name__ == "__main__":
    tf.app.run()


