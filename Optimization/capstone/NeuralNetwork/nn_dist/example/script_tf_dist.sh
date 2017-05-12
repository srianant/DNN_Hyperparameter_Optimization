CUDA_VISIBLE_DEVICES='' python tf_dist.py --ps_hosts=localhost:2223 --worker_hosts=localhost:2225,localhost:2226 --job_name=ps --task_index=0 \
& CUDA_VISIBLE_DEVICES=0 python tf_dist.py --ps_hosts=localhost:2223 --worker_hosts=localhost:2225,localhost:2226 --job_name=worker --task_index=0 \
& CUDA_VISIBLE_DEVICES=1 python tf_dist.py --ps_hosts=localhost:2223 --worker_hosts=localhost:2225,localhost:2226 --job_name=worker --task_index=1

