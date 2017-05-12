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

    gpu_options = tf.GPUOptions(allow_growth=True,
                                per_process_gpu_memory_fraction=0.333)

    sess_config = tf.ConfigProto(
        allow_soft_placement=True,
        log_device_placement=False,
        gpu_options=gpu_options,
        device_filters=["/job:ps", "/job:worker/task:%d" % FLAGS.task_index])

    if FLAGS.job_name == "ps":
        print ("%s ps: server join"%GNODE)
        server.join()
    elif FLAGS.job_name == "worker":
        is_chief = (FLAGS.task_index == 0)

        gpu = (FLAGS.task_index % 1)
        worker_device = "/job:worker/task:%d/gpu:%d" % (FLAGS.task_index, gpu)

        with tf.device(
                tf.train.replica_device_setter(
                    worker_device=worker_device,
                    ps_device="/job:ps/cpu:0",
                    cluster=cluster)):

            hooks = [tf.train.StopAtStepHook(last_step=10)]
            global_step = tf.Variable(0, name="global_step", trainable=False)

            # Build TF model 
            loss = build_model()

        time_begin = time.time()

        with tf.train.MonitoredTrainingSession(master=server.target,
                                               is_chief=is_chief,
                                               hooks=hooks,
                                               config=sess_config) as mon_sess:
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
