import tensorflow as tf
import time
import os

flags = tf.app.flags
flags.DEFINE_integer("task_index", None,
                     "Worker task index, should be >= 0. task_index=0 is "
                     "the master worker task the performs the variable "
                     "initialization ")
flags.DEFINE_string("ps_hosts","localhost:2222",
                    "Comma-separated list of hostname:port pairs")
flags.DEFINE_string("worker_hosts", "localhost:2223,localhost:2224",
                    "Comma-separated list of hostname:port pairs")
flags.DEFINE_string("job_name", None,"job name: worker or ps")
FLAGS = flags.FLAGS

# Graph Node
GNODE = "%s/%d" % (FLAGS.job_name,FLAGS.task_index)

def build_model():
    # simple variable addition
    a=tf.Variable(1.0)
    # put you optimizer of choice and add code for between the graph replication
    loss=a+3
    return loss 

def train_model(mon_sess, global_step, loss):
    # Run session 
    result = mon_sess.run([loss, global_step])
    # PS:just don't call mon_sess.run in loop here 
    print ("%s Result: %d" % (GNODE,result[0]))

def main(unused_argv):

    # Make sure jobs has names and task_index
    if FLAGS.job_name is None or FLAGS.job_name == "":
        raise ValueError("Must specify an explicit `job_name`")
    if FLAGS.task_index is None or FLAGS.task_index == "":
        raise ValueError("Must specify an explicit `task_index`")
 
    # Construct the cluster and start the server
    ps_spec = FLAGS.ps_hosts.split(",")
    worker_spec = FLAGS.worker_hosts.split(",")

    # Get the number of workers.
    num_workers = len(worker_spec)

    # Represents a cluster as a set of "tasks", organized into "jobs"
    cluster = tf.train.ClusterSpec({
        "ps": ps_spec,
        "worker": worker_spec})

    # An in-process TensorFlow server, for use in distributed training (per process node)
    server = tf.train.Server(cluster, job_name=FLAGS.job_name,
                             task_index=FLAGS.task_index) 

    # Configure GPU
    # If allow_growth == true, the allocator does not pre-allocate the entire specified
    # GPU memory region, instead starting small and growing as needed.
    # Assume that you have 12GB of GPU memory and want to allocate ~4GB
    gpu_options = tf.GPUOptions(allow_growth=True,
                                per_process_gpu_memory_fraction=0.333)

    # Session config. When allow_soft_placement==True, it automatically identifies between cpu/gpu 
    sess_config = tf.ConfigProto(
        allow_soft_placement=True,
        log_device_placement=False,
        gpu_options=gpu_options,
        device_filters=["/job:ps", "/job:worker/task:%d" % FLAGS.task_index])

    if FLAGS.job_name == "ps":
        print ("%s ps: server join"%GNODE)
        # ps: will go into listening mode and communicates with worker using gPRC
        server.join()
    elif FLAGS.job_name == "worker":
        is_chief = (FLAGS.task_index == 0)

        gpu = (FLAGS.task_index % 1)
        worker_device = "/job:worker/task:%d/gpu:%d" % (FLAGS.task_index, gpu)

        # Builds Graphs for each replicas (processing nodes). 
        # The device setter will automatically place Variables ops on separate parameter servers (ps). 
        # The non-Variable ops will be placed on the workers.
        # The ps use CPU and workers use corresponding GPU
        with tf.device(
                tf.train.replica_device_setter(
                    worker_device=worker_device,
                    ps_device="/job:ps/cpu:0",
                    cluster=cluster)):

            # User specified hooks. In this case it represents the number of training steps
            hooks = [tf.train.StopAtStepHook(last_step=10)]
            # Monitoring session require gloabl_step to be defined
            global_step = tf.Variable(0, name="global_step", trainable=False)

            # Build TF model 
            loss = build_model()

        time_begin = time.time()

        # For a chief, this utility sets proper session initializer/restorer. 
        # It also creates hooks related to checkpoint and summary saving. 
        # For workers, this utility sets proper session creator which waits for the chief to initialize/restore.
        with tf.train.MonitoredTrainingSession(master=server.target,
                                               is_chief=is_chief,
                                               hooks=hooks,
                                               config=sess_config) as mon_sess:
            # Train in loop until condition
            while not mon_sess.should_stop():
                # Train TF model 
                train_model(mon_sess, global_step, loss)
                break #typically we will have optimzer to stop after global_step

        time_end = time.time()
        print ("%s Training ends @ %f" % (GNODE,time_end))
        training_time = time_end - time_begin
        print ("%s Training elapsed time: %fsec" % (GNODE,training_time))
        
        # kill the PS process
        # Only worker process gets terminated after session run is complete. PS sever should be killed
        if (FLAGS.job_name == 'worker' and FLAGS.task_index == 1): 
            os.system("ps aux | grep python |  grep tf_dist.py | awk '{print $2}' | xargs kill -9")
        else:
            print ("It may take up to 30sec for other worker to execute. That's as per MonitoredSession TF design.!!\n")


if __name__ == "__main__":
    tf.app.run()
