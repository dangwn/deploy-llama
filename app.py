import os
from typing import Collection, Dict, List, TypedDict, Union

import fire
import uvicorn
from fastapi import FastAPI, Response

from llama import Llama


class CompletionPrediction(TypedDict, total=False):
    generation: str
    tokens: List[str]  # not required
    logprobs: List[float]  # not required

class LlamaAPI(FastAPI):
    def __init__(
        self, 
        llama: LLama,
        max_gen_len: int,
        temperature: float,
        top_p: float,
        *args, 
        **kwargs
    ) -> None:
        super(LlamaAPI, self).__init__(*args, **kwargs)
 
        self.llama: Llama = llama
        self.max_gen_len: int = max_gen_len
        self.temperature: float = temperature
        self.top_p: float = top_p
 
    def complete(self, prompts: Union[str, Collection[str]]) -> Dict[str, str]:
        prompts: List[str] = [prompts] if type(prompts) == str else list(prompts)
 
        results: List[CompletionPrediction] = self.llama.text_completion(
            prompts,
            max_gen_len=self.max_gen_len,
            temperature=self.temperature,
            top_p=self.top_p
        )
 
        return dict(zip(prompts, results))


def main(
    ckpt_dir: str,
    tokenizer_path: str,
    temperature: float = 0.6,
    top_p: float = 0.9,
    max_seq_len: int = 128,
    max_gen_len: int = 64,
    max_batch_size: int = 4,
):  
    print("Building llama...")
 
    llama: LLama = Llama.build(
        ckpt_dir=ckpt_dir,
        tokenizer_path=tokenizer_path,
        max_seq_len=max_seq_len,
        max_batch_size=max_batch_size,
    )
 
    print("Making app...")
    
    app: LlamaAPI = LlamaAPI(
        llama=llama,
        max_gen_len=max_gen_len,
        temperature=temperature,
        top_p=top_p
    )

    @app.get("/health")
    def health_check(r: Response) -> Response:
        return r
    
    @app.post("/")
    def complete(data: Union[str, List[str]]) -> Dict[str, str]:
        return app.complete(prompts=data)
    
    uvicorn.run(app, host=os.environ['API_HOST'], port=int(os.environ['API_PORT']))

if __name__ == '__main__':
    fire.Fire(main)