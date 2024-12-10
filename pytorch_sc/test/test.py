import os, sys
from pathlib import Path
_CACHE = Path("./cache")
os.makedirs(_CACHE, exist_ok=True)
for n, d in [
    ("NUMBA_CACHE_DIR", "numba"),
    ("MPLCONFIGDIR", "matplotlib"),
    ("HF_HOME", "transformers"),
    ("HOME", "fake_home")
]:
    (_CACHE/d).mkdir(exist_ok=True)
    os.environ[n] = str(_CACHE/d)

import math
import scanpy as sc
import numpy as np
from einops import einsum
from tqdm import tqdm
from sklearn.preprocessing import MultiLabelBinarizer
import torch
import torch.nn as nn
from torch.nn.functional import one_hot
from torch.optim import Adam
from torch.utils.data import Dataset, DataLoader
from torchmetrics.functional import accuracy, pearson_corrcoef, r2_score