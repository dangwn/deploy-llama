torchrun --nproc_per_node 1 app.py \
    --ckpt_dir ./llama/llama-2-7b/ \
    --tokenizer_path ./llama/tokenizer.model \
    --max_seq_len 128 --max_batch_size 4