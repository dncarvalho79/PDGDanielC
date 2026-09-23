"""
DILATED CONVOLUTION AUDIO MODELING - MULTI-FILE VERSION (PYTHON)
====================================================================
Maps Piezo (DI) pickup to Microphone reference using all files in a folder.
Uses scipy for audio I/O and resampling.

Quick start:
    # Fast smoke test on 1 file pair, 3 epochs:
    python3 train.py --limit-files 1 --limit-epochs 3

    # Full run using every file in the folder:
    python train.py
"""
import os
import argparse
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader, TensorDataset
import numpy as np
from scipy.io import wavfile
from scipy.signal import resample, hilbert, correlate, correlation_lags
from tqdm import tqdm
import matplotlib.pyplot as plt
from matplotlib import rcParams
rcParams['figure.figsize'] = (12, 6)
rcParams['font.size'] = 12
import random
torch.manual_seed(440)
np.random.seed(440)
random.seed(440)
# Optional metric packages
try:
    from pesq import pesq, PesqError
    HAS_PESQ = True
    #HAS_PESQ = False
except (ImportError, Exception):
    HAS_PESQ = False
    pesq = None
    pesqError=Exception
    print("PESQ não disponível.")

try:
    from pystoi import stoi
    HAS_STOI = True
except ImportError:
    HAS_STOI = False
    print("STOI não disponível. Instale com: pip install pystoi")

try:
    from aquatk import peaq as PEAQ
    HAS_PEAQ = True
    #HAS_PEAQ = False
except ImportError:
    HAS_PEAQ = False
    print("PEAQ não disponível. Instale com: pip install aquatk")


# ---------------------------- Configuration ----------------------------
class Config:
    Fs_target = 48000
    frame_len = 16384            # ~340 ms
    hop_len = 8192               # 50% overlap
    num_epochs = 120
    batch_size = 8
    learn_rate = 3e-4
    validation_split = 0.15
    lambda_time = 1.0
    lambda_mrstft = 1.2
    stft_configs = [
        (256,  64, 256),
        (512, 128, 512),
        (1024, 256, 1024),
        (2048, 512, 2048),
        (4096, 1024, 4096)
    ]

    if torch.backends.mps.is_available():
        device = torch.device('mps')
    elif torch.cuda.is_available():
        device = torch.device('cuda')
    else:
        device = torch.device('cpu')

    # ----- Multi-file settings -----
    multi_file_mode = True
    data_path = '../Base toda'
    line_pattern = 'Line'
    mic_pattern = 'Mic'
    fixed_delay = None           # None = per-pair alignment
    search_lag = 400             # ±83 ms search window
    # ----- Single-file fallback -----
    input_file = 'tudoLine_01.wav'
    target_file = 'tudoMic_01.wav'

    output_file = 'guitar_modeled_mic_high.wav'
    pre_emph = 0.97

    # ----- Report / plots -----
    results_dir = 'results'
    plots_dir = os.path.join(results_dir, 'plots')
    metrics_dir = os.path.join(results_dir, 'metrics')
    report_filename = 'relatorio_TCC.txt'
    checkpoint_path = os.path.join(results_dir, 'best_model.pt')


    # ----- Limits (set via CLI) -----
    limit_files = None           # None = use all matched pairs
    limit_epochs = None          # None = use num_epochs


cfg = Config()

os.makedirs(cfg.results_dir, exist_ok=True)
os.makedirs(cfg.plots_dir, exist_ok=True)
os.makedirs(cfg.metrics_dir, exist_ok=True)


# ---------------------------- Audio I/O ----------------------------
def load_audio(path, target_sr=48000):
    sr, data = wavfile.read(path)
    if data.dtype == np.int16:
        data = data.astype(np.float64) / 32768.0
    elif data.dtype == np.int32:
        data = data.astype(np.float64) / 2147483648.0
    elif data.dtype == np.uint8:
        data = (data.astype(np.float64) - 128.0) / 128.0
    else:
        data = data.astype(np.float64)
    if data.ndim > 1:
        data = data.mean(axis=1)
    if sr != target_sr:
        num_samples = int(len(data) * target_sr / sr)
        data = resample(data, num_samples)
    data = data - np.mean(data)
    return data.astype(np.float64)


def write_audio(path, data, sr):
    data = np.clip(data, -1, 1)
    data_int16 = (data * 32767).astype(np.int16)
    wavfile.write(path, sr, data_int16)


# ---------------------------- Helpers ----------------------------


def pre_emphasis(x, coeff=0.97):
    return np.append(x[0], x[1:] - coeff * x[:-1])


def de_emphasis(x, coeff=0.97):
    # Vectorized IIR: y[n] = x[n] + coeff*y[n-1]
    # Use scipy.signal.lfilter for speed on long signals.
    from scipy.signal import lfilter
    return lfilter([1.0], [1.0, -coeff], x)


def normalize_rms(x, target_rms=0.1):
    rms = np.sqrt(np.mean(x ** 2))
    if rms > 0:
        return x * (target_rms / rms)
    return x

def align_by_envelope(ref, sig, search=4000, allow_negative=False):
    """
    Align `sig` to `ref` by finding the lag that maximizes the
    correlation of their Hilbert envelopes.

    Positive lag → sig is delayed relative to ref → trim sig's start.
    Returns (ref_aligned, sig_aligned, lag).
    """
    n = min(len(ref), len(sig))
    ref, sig = ref[:n], sig[:n]
    er = np.abs(hilbert(ref))
    es = np.abs(hilbert(sig))
    c = correlate(es, er, mode='full')
    lags = correlation_lags(len(es), len(er), mode='full')

    if allow_negative:
        mask = np.abs(lags) <= search
    else:
        mask = (lags >= 0) & (lags <= search)   # only non-negative

    lag = int(lags[mask][np.argmax(c[mask])])

    if lag >= 0:
        sig = sig[lag:]
    else:
        ref = ref[-lag:]
    n = min(len(ref), len(sig))
    return ref[:n], sig[:n], lag
# ---------------------------- Dataset Preparation ----------------------------
def prepare_data(cfg):
    if cfg.multi_file_mode:
        print("=== Multi-file mode: scanning folder ===")
        all_files = [f for f in os.listdir(cfg.data_path) if f.lower().endswith('.wav')]
        if not all_files:
            raise FileNotFoundError(f"No .wav files found in {cfg.data_path}")

        line_files = []
        mic_files = []
        for f in all_files:
            if cfg.line_pattern.lower() in f.lower():
                line_files.append(os.path.join(cfg.data_path, f))
            elif cfg.mic_pattern.lower() in f.lower():
                mic_files.append(os.path.join(cfg.data_path, f))

        line_files.sort()
        mic_files.sort()

        if not line_files:
            raise ValueError(f"No files containing '{cfg.line_pattern}' found.")
        if not mic_files:
            raise ValueError(f"No files containing '{cfg.mic_pattern}' found.")

        num_pairs = min(len(line_files), len(mic_files))
        if len(line_files) != len(mic_files):
            print(f"Warning: Unequal counts ({len(line_files)} Line, "
                  f"{len(mic_files)} Mic). Using first {num_pairs} pairs.")

        # -------- LIMIT-FILES HERE --------
        if cfg.limit_files is not None:
            num_pairs = min(num_pairs, cfg.limit_files)
            print(f"[limit-files] Using only first {num_pairs} pair(s).")

        print(f"Found {num_pairs} pairs.")
        x_di_all = []
        y_mic_all = []

        for i in range(num_pairs):
            print(f"Processing pair {i+1}/{num_pairs}: "
                  f"{os.path.basename(line_files[i])} <-> "
                  f"{os.path.basename(mic_files[i])}")
            y_line = load_audio(line_files[i], cfg.Fs_target)
            y_mic = load_audio(mic_files[i], cfg.Fs_target)

            if cfg.fixed_delay is not None:
                # legacy fixed-delay path (unused when fixed_delay=None)
                delay = cfg.fixed_delay
                if delay >= 0:
                    y_line_align = y_line[delay:]
                    y_mic_align = y_mic[:len(y_line_align)]
                else:
                    y_line_align = y_line[:delay]
                    y_mic_align = y_mic[-delay:]
                min_len = min(len(y_line_align), len(y_mic_align))
                y_line_align = y_line_align[:min_len]
                y_mic_align = y_mic_align[:min_len]
                lag = delay
            else:
                # per-pair alignment
                y_line_align, y_mic_align, lag = align_by_envelope(
                    y_line, y_mic, search=cfg.search_lag
                )

            print(f"    alignment lag: {lag:+d} samples "
                  f"({lag/cfg.Fs_target*1000:+.2f} ms)")

            x_di_all.append(y_line_align)
            y_mic_all.append(y_mic_align)

        x_di = np.concatenate(x_di_all)
        y_mic = np.concatenate(y_mic_all)
        print(f"Total combined length: {len(x_di)} samples "
              f"({len(x_di)/cfg.Fs_target:.2f} s)")

    else:
        print("=== Single-file mode ===")
        x_di = load_audio(os.path.join(cfg.data_path, cfg.input_file), cfg.Fs_target)
        y_mic = load_audio(os.path.join(cfg.data_path, cfg.target_file), cfg.Fs_target)

        if cfg.fixed_delay is not None:
            delay = cfg.fixed_delay
            if delay >= 0:
                y_mic = y_mic[delay:]
                x_di = x_di[:len(y_mic)]
            else:
                y_mic = y_mic[:delay]
                x_di = x_di[-delay:]
            min_len = min(len(y_mic), len(x_di))
            y_mic = y_mic[:min_len]
            x_di = x_di[:min_len]
            lag = delay
        else:
            x_di, y_mic, lag = align_by_envelope(
                x_di, y_mic, search=cfg.search_lag
            )
        print(f"Aligned length: {len(x_di)/cfg.Fs_target:.2f} s (lag={lag:+d})")

    

 # ---- pair-level split (shuffle pairs, then frame each split) ----
    if cfg.multi_file_mode:
        # normalize + pre-emphasize each pair independently
        x_pairs = [pre_emphasis(normalize_rms(x, 0.1), cfg.pre_emph) for x in x_di_all]
        y_pairs = [pre_emphasis(normalize_rms(y, 0.1), cfg.pre_emph) for y in y_mic_all]

        rng = np.random.default_rng(42)
        perm = rng.permutation(len(x_pairs))
        n_val = max(1, int(len(x_pairs) * cfg.validation_split))
        val_idx, train_idx = perm[:n_val], perm[n_val:]

        def to_frames(idxs):
            xs = np.concatenate([x_pairs[i] for i in idxs])
            ys = np.concatenate([y_pairs[i] for i in idxs])
            n = (len(xs) - cfg.frame_len) // cfg.hop_len + 1
            X = np.zeros((n, 1, cfg.frame_len), dtype=np.float32)
            Y = np.zeros((n, 1, cfg.frame_len), dtype=np.float32)
            for k in range(n):
                s = k * cfg.hop_len
                X[k, 0, :] = xs[s:s + cfg.frame_len]
                Y[k, 0, :] = ys[s:s + cfg.frame_len]
            return X, Y

        X_train, Y_train = to_frames(train_idx)
        X_val,   Y_val   = to_frames(val_idx)

        # reconstruct full signal for final inference (unchanged behavior)
        x_di = np.concatenate(x_di_all)
        y_mic = np.concatenate(y_mic_all)
        x_di_pre = pre_emphasis(normalize_rms(x_di, 0.1), cfg.pre_emph)
        y_mic    = normalize_rms(y_mic, 0.1)
    else:
        # single-file: keep old behavior
        x_di_pre = pre_emphasis(normalize_rms(x_di, 0.1), cfg.pre_emph)
        y_mic    = normalize_rms(y_mic, 0.1)
        n = (len(x_di_pre) - cfg.frame_len) // cfg.hop_len + 1
        X = np.zeros((n, 1, cfg.frame_len), dtype=np.float32)
        Y = np.zeros((n, 1, cfg.frame_len), dtype=np.float32)
        for k in range(n):
            s = k * cfg.hop_len
            X[k, 0, :] = x_di_pre[s:s + cfg.frame_len]
            Y[k, 0, :] = pre_emphasis(y_mic, cfg.pre_emph)[s:s + cfg.frame_len]
        num_val = max(1, int(n * cfg.validation_split))
        X_train, Y_train = X[:-num_val], Y[:-num_val]
        X_val,   Y_val   = X[-num_val:], Y[-num_val:]

    print(f"Train: {len(X_train)}, Val: {len(X_val)}")
    if cfg.multi_file_mode:
        print(f"[split] {len(train_idx)} train pairs, {len(val_idx)} val pairs")
        print(f"[split] first 5 val pair indices: {[int(i) for i in val_idx[:5]]}")


    X_train = torch.from_numpy(X_train).to(cfg.device)
    Y_train = torch.from_numpy(Y_train).to(cfg.device)
    X_val   = torch.from_numpy(X_val).to(cfg.device)
    Y_val   = torch.from_numpy(Y_val).to(cfg.device)

    return X_train, Y_train, X_val, Y_val, x_di_pre, y_mic

#---
class ResidualDilatedCNN(nn.Module):
    def __init__(self, in_channels=1, out_channels=1, hidden=64, kernel=7,
                 dilations=[1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024],
                 use_gru=False):
        super().__init__()

        # ---- dilated CNN stack ----
        layers = []
        for d in dilations:
            layers.append(nn.Conv1d(in_channels if len(layers) == 0 else hidden,
                                    hidden, kernel, padding='same', dilation=d))
            layers.append(nn.GroupNorm(1, hidden))
            layers.append(nn.LeakyReLU(0.2))
        self.conv_stack = nn.Sequential(*layers)

        # ---- NEW: bidirectional GRU bottleneck ----
        self.use_gru = use_gru
        if use_gru:
            self.gru = nn.GRU(hidden, hidden, num_layers=1,
                              batch_first=True, bidirectional=True)
            self.gru_proj = nn.Conv1d(2 * hidden, hidden, 1)

        # ---- input/output projections ----
        self.skip_proj = nn.Conv1d(in_channels, hidden, 1, padding='same')
        self.out_proj  = nn.Conv1d(hidden, out_channels, 1, padding='same')

    def forward(self, x):
        skip = self.skip_proj(x)
        out  = self.conv_stack(x)

        if self.use_gru:
            out_t = out.transpose(1, 2)              # (B, T, C)
            out_t, _ = self.gru(out_t)
            out = self.gru_proj(out_t.transpose(1, 2))  # back to (B, C, T)

        out = out + skip
        out = self.out_proj(out)
        return out
    

# ---------------------------- Losses ----------------------------
def multi_resolution_stft_loss(y_pred, y_true, configs, device):
    loss = 0.0
    eps = 1e-6
    for n_fft, hop_len, win_len in configs:
        window = torch.hann_window(win_len, device=device)
        # Batched STFT -- much faster than per-sample loop
        S_pred = torch.stft(y_pred.squeeze(1), n_fft, hop_length=hop_len,
                            win_length=win_len, window=window,
                            return_complex=True)
        S_true = torch.stft(y_true.squeeze(1), n_fft, hop_length=hop_len,
                            win_length=win_len, window=window,
                            return_complex=True)
        mag_pred = torch.log10(torch.abs(S_pred) + eps)
        mag_true = torch.log10(torch.abs(S_true) + eps)
        loss = loss + torch.mean(torch.abs(mag_pred - mag_true))
    return loss / len(configs)

def spectral_l1_loss(y_pred, y_true, n_fft=512, hop_len=128):
    """Single-scale spectral magnitude L1. Directly optimizes LSD."""
    eps = 1e-8
    window = torch.hann_window(n_fft, device=y_pred.device)
    S_pred = torch.stft(y_pred.squeeze(1), n_fft, hop_length=hop_len,
                        window=window, return_complex=True)
    S_true = torch.stft(y_true.squeeze(1), n_fft, hop_length=hop_len,
                        window=window, return_complex=True)
    mag_pred = torch.abs(S_pred) + eps
    mag_true = torch.abs(S_true) + eps
    return F.l1_loss(mag_pred, mag_true)

def compute_loss(y_pred, y_true, cfg):
    l1 = F.l1_loss(y_pred, y_true)
    mrstft = multi_resolution_stft_loss(y_pred, y_true, cfg.stft_configs, cfg.device)

    # Anti-phase penalty
    yp = y_pred.flatten(1) - y_pred.flatten(1).mean(dim=1, keepdim=True)
    yt = y_true.flatten(1) - y_true.flatten(1).mean(dim=1, keepdim=True)
    num = (yp * yt).sum(dim=1)
    den = yp.norm(dim=1) * yt.norm(dim=1) + 1e-8
    corr = num / den
    phase_penalty = F.relu(-corr).mean()

    return 10.0 * l1 + 1.0 * mrstft + 2.0 * phase_penalty
#def compute_loss(y_pred, y_true, cfg):
    #mse = F.mse_loss(y_pred, y_true)
    #mae = F.l1_loss(y_pred, y_true)
    #time_loss = mse + mae
    #stft_loss = multi_resolution_stft_loss(y_pred, y_true, cfg.stft_configs, cfg.device)
    #total_loss = cfg.lambda_time * time_loss + cfg.lambda_mrstft * stft_loss
    #return total_loss
    

# ---------------------------- Training ----------------------------
def train_model(cfg, model, X_train, Y_train, X_val, Y_val):
    optimizer = torch.optim.Adam(model.parameters(), lr=cfg.learn_rate)

    # ----- LIMIT-EPOCHS HERE -----
    num_epochs = cfg.num_epochs
    if cfg.limit_epochs is not None:
        num_epochs = min(num_epochs, cfg.limit_epochs)
        print(f"[limit-epochs] Training for only {num_epochs} epoch(s).")

    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=num_epochs)
    best_val_loss = float('inf')
    patience = 15
    wait = 0

    train_losses = []
    val_losses = []

    train_dataset = TensorDataset(X_train, Y_train)
    val_dataset = TensorDataset(X_val, Y_val)
    train_loader = DataLoader(train_dataset, batch_size=cfg.batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=cfg.batch_size, shuffle=False)

    print("\n=== Training ===")
    for epoch in range(1, num_epochs + 1):
        model.train()
        epoch_loss = 0.0
        for Xb, Yb in tqdm(train_loader, desc=f"Epoch {epoch}", leave=False):
            Xb, Yb = Xb.to(cfg.device), Yb.to(cfg.device)
            optimizer.zero_grad()
            Y_pred = model(Xb)
            loss = compute_loss(Y_pred, Yb, cfg)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
            epoch_loss += loss.item() * Xb.size(0)
        epoch_loss /= len(train_loader.dataset)
        scheduler.step()
        train_losses.append(epoch_loss)

        if epoch % 5 == 0 or epoch == 1 or epoch == num_epochs:
            model.eval()
            val_loss = 0.0
            with torch.no_grad():
                for Xb, Yb in val_loader:
                    Xb, Yb = Xb.to(cfg.device), Yb.to(cfg.device)
                    Y_pred = model(Xb)
                    loss = compute_loss(Y_pred, Yb, cfg)
                    val_loss += loss.item() * Xb.size(0)
            val_loss /= len(val_loader.dataset)
            val_losses.append((epoch, val_loss))
            print(f"Epoch {epoch:3d} | Train Loss: {epoch_loss:.4e} | "
                  f"Val Loss: {val_loss:.4e} | LR: {optimizer.param_groups[0]['lr']:.2e}")
            if val_loss < best_val_loss:
                best_val_loss = val_loss
                wait = 0
                torch.save(model.state_dict(), cfg.checkpoint_path)
            else:
                wait += 1
                if wait >= patience:
                    print(f"Early stopping at epoch {epoch}")
                    break
        else:
            print(f"Epoch {epoch:3d} | Train Loss: {epoch_loss:.4e}")

    # If we never saved (e.g. limit-epochs=1 and val never ran), force a save
    if not os.path.exists(cfg.checkpoint_path):
        torch.save(model.state_dict(), cfg.checkpoint_path)

    model.load_state_dict(torch.load(cfg.checkpoint_path, map_location=cfg.device, weights_only=True))
    print(f"Training complete. Best validation loss: {best_val_loss:.4e}")
    return model, train_losses, val_losses


# ---------------------------- Inference ----------------------------
def infer_overlap_add(model, x, frame_len, hop_len, pre_emph, device,target_rms=None):
    model.eval()
    L = len(x)
    y_out_pre = np.zeros(L)
    win_weight = np.zeros(L)
    window = np.hanning(frame_len)

    num_frames = (L - frame_len) // hop_len + 1
    for i in range(num_frames):
        start = i * hop_len
        end = start + frame_len
        if end > L:
            break
        x_frame = x[start:end]
        x_t = torch.from_numpy(x_frame).float().unsqueeze(0).unsqueeze(0).to(device)
        with torch.no_grad():
            y_frame = model(x_t).squeeze().cpu().numpy()
        y_out_pre[start:end] += y_frame * window
        win_weight[start:end] += window

    valid = win_weight > 1e-4
    y_out_pre[valid] /= win_weight[valid]
    y_out = de_emphasis(y_out_pre, pre_emph)
    y_out = y_out - np.mean(y_out)
    if target_rms is not None:
        y_out = normalize_rms(y_out, target_rms)
    return y_out
    


# ============================ METRICS (FIXED) ============================
def _to_int16(x):
    """Clip to [-1, 1] and convert to int16 for PESQ."""
    x = np.clip(x, -1.0, 1.0)
    return (x * 32767.0).astype(np.int16)


def _resample_to(x, sr_in, sr_out):
    if sr_in == sr_out:
        return x
    n = int(round(len(x) * sr_out / sr_in))
    return resample(x, n).astype(np.float64)


def _pesq_score(ref, deg, sr):
    """PESQ wrapper: resamples to 16 kHz, converts to int16, guards length."""
    if not HAS_PESQ:
        return None
    sr_out = 16000
    ref_r = _resample_to(ref, sr, sr_out)
    deg_r = _resample_to(deg, sr, sr_out)
    if len(ref_r) < sr_out // 2 or len(deg_r) < sr_out // 2:
        return np.nan

    try:
        n = min(len(ref_r), len(deg_r))
        return float(pesq(sr_out, _to_int16(ref_r[:n]), _to_int16(deg_r[:n]), 'wb'))
    except PesqError:
        return np.nan
    except Exception as e:
        print(f"[PESQ] falhou: {e}")
        return None


def _stoi_score(ref, deg, sr):
    """STOI wrapper with length + range guards."""
    if not HAS_STOI:
        return np.nan
    n = min(len(ref), len(deg))
    if n < int(0.4 * sr):
        return np.nan
    try:
        return float(stoi(ref[:n], deg[:n], sr, extended=False))
    except Exception:
        return np.nan


def _lsd_score(ref, deg, sr, n_fft=512, hop=256):
    """
    Log-Spectral Distance (dB) using scipy.signal.stft (no more plt.mlab).
    """
    from scipy.signal import stft
    f, t, Zref = stft(ref, fs=sr, nperseg=n_fft, noverlap=n_fft - hop,
                      window='hann', boundary=None, padded=False)
    f, t, Zdeg = stft(deg, fs=sr, nperseg=n_fft, noverlap=n_fft - hop,
                      window='hann', boundary=None, padded=False)
    min_frames = min(Zref.shape[1], Zdeg.shape[1])
    Zref = Zref[:, :min_frames]
    Zdeg = Zdeg[:, :min_frames]
    eps = 1e-10
    Pref = np.maximum(np.abs(Zref) ** 2, eps)
    Pdeg = np.maximum(np.abs(Zdeg) ** 2, eps)
    lsd = np.mean(np.sqrt(np.mean(
        (10 * np.log10(Pref) - 10 * np.log10(Pdeg)) ** 2, axis=0)))
    return float(lsd)
def _peaq_score(ref, deg, sr):
    """
    PEAQ-ODG wrapper for aquatk's API:
        peaq(reference: str|Path, test: str|Path, progress_bar: bool) -> PEAQResult
    PEAQResult exposes: .odg, .di, .mov  (lowercase)
    """
    if not HAS_PEAQ:
        print("PEAQ: HAS_PEAQ is False — aquatk não importável neste ambiente")
        return np.nan

    import tempfile, traceback

    try:
        n = min(len(ref), len(deg))
        ref = np.asarray(ref[:n], dtype=np.float64)
        deg = np.asarray(deg[:n], dtype=np.float64)

        sr_use = 48000
        if sr != sr_use:
            ref = _resample_to(ref, sr, sr_use)
            deg = _resample_to(deg, sr, sr_use)

        with tempfile.TemporaryDirectory() as tmpdir:
            ref_path = os.path.join(tmpdir, "ref.wav")
            deg_path = os.path.join(tmpdir, "deg.wav")
            wavfile.write(ref_path, sr_use,
                          (np.clip(ref, -1.0, 1.0) * 32767).astype(np.int16))
            wavfile.write(deg_path, sr_use,
                          (np.clip(deg, -1.0, 1.0) * 32767).astype(np.int16))

            results = PEAQ(ref_path, deg_path, progress_bar=False)

        # aquatk PEAQResult: lowercase attributes odg, di, mov
        for attr in ("odg", "ODG", "odg_score", "ODG_score"):
            if hasattr(results, attr):
                v = float(getattr(results, attr))
                if not np.isnan(v):
                    return v
        if isinstance(results, dict):
            for key in ("odg", "ODG"):
                if key in results:
                    return float(results[key])
        if isinstance(results, (tuple, list)) and results:
            return float(results[0])

        print(f"PEAQ: atributo ODG não encontrado. "
              f"Atributos: {[a for a in dir(results) if not a.startswith('_')]}")
        return np.nan

    except Exception as e:
        print(f"Erro no PEAQ: {type(e).__name__}: {e}")
        traceback.print_exc()
        return np.nan

def compute_metrics(y_true, y_pred, fs):
    """Compute SNR, SI-SDR, PESQ, STOI, LSD, PEAQ-ODG."""
    
    min_len = min(len(y_true), len(y_pred))
    y_true = np.asarray(y_true[:min_len], dtype=np.float64)
    y_pred = np.asarray(y_pred[:min_len], dtype=np.float64)
    seg_len = 20 * fs
    mid = len(y_true) // 2
    seg = slice(max(0, mid - seg_len // 2), min(len(y_true), mid + seg_len // 2))   
    # SNR
    noise = y_true - y_pred
    snr = 10 * np.log10((np.sum(y_true ** 2) + 1e-10) /
                        (np.sum(noise ** 2) + 1e-10))

    # SI-SDR
    y_true_c = y_true - y_true.mean()
    y_pred_c = y_pred - y_pred.mean()
    alpha = np.dot(y_pred_c, y_true_c) / (np.dot(y_true_c, y_true_c) + 1e-10)
    s_target = alpha * y_true_c
    e_noise = y_pred_c - s_target
    si_sdr = 10 * np.log10((np.sum(s_target ** 2) + 1e-10) /
                           (np.sum(e_noise ** 2) + 1e-10))

    pesq_score = _pesq_score(y_true[seg], y_pred[seg], fs)
    if pesq_score is None:
        print("PESC indisponível, ignorando")
    else:
        print(f"PESQ:{pesq_score:.3f}")
    
    stoi_score = _stoi_score(y_true, y_pred, fs)
    lsd = _lsd_score(y_true, y_pred, fs)
    odg = _peaq_score(y_true[seg], y_pred[seg], fs)

    def _safe_float(x):
        if x is None:
            return np.nan
        try:
    	    return float(x)
        except(TypeError, ValueError):
    	    return np.nan


    return {
        'SNR (dB)': float(snr),
        'SI-SDR (dB)': float(si_sdr),
        'PESQ': _safe_float(pesq_score),
        'STOI': float(stoi_score) if not np.isnan(stoi_score) else np.nan,
        'LSD': float(lsd),
        'PEAQ ODG': float(odg) if not np.isnan(odg) else np.nan,
    }


# ============================ PLOTS ============================
def plot_learning_curves(train_losses, val_losses, save_path=None):
    plt.figure(figsize=(10, 6))
    epochs_train = range(1, len(train_losses) + 1)
    plt.semilogy(epochs_train, train_losses, label='Treino', linewidth=2)

    if val_losses:
        epochs_val, vals = zip(*val_losses)
        plt.semilogy(epochs_val, vals, 'o-', label='Validação',
                     linewidth=2, markersize=6)

    plt.xlabel('Época')
    plt.ylabel('Perda (escala log)')
    plt.title('Curva de Aprendizagem')
    plt.legend(loc='upper right')
    plt.grid(True, which='both', linestyle='--', alpha=0.6)
    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Curva de aprendizagem salva em: {save_path}")
    plt.close()


def plot_signal_comparison(y_true, y_pred, fs, title, save_path=None,
                           segment_s=5.0, offset_s=10.0):
    from scipy.signal import stft

    # Crop to a short segment
    start = int(offset_s * fs)
    end   = start + int(segment_s * fs)
    if end > min(len(y_true), len(y_pred)):
        end = min(len(y_true), len(y_pred))
        start = max(0, end - int(segment_s * fs))

    y_true = y_true[start:end]
    y_pred = y_pred[start:end]

    min_len = min(len(y_true), len(y_pred))
    y_true = y_true[:min_len]
    y_pred = y_pred[:min_len]
    error  = y_true - y_pred
    time   = np.arange(min_len) / fs + start / fs   # absolute time axis

    fig, axes = plt.subplots(3, 1, figsize=(14, 10))

    axes[0].plot(time, y_true, label='Referência (Mic)', alpha=0.7, linewidth=0.6)
    axes[0].plot(time, y_pred, label='Predito', alpha=0.7, linewidth=0.6)
    axes[0].set_xlabel('Tempo (s)')
    axes[0].set_ylabel('Amplitude')
    axes[0].set_title(f'{title} - Forma de Onda ({segment_s:.0f}s a partir de {offset_s:.0f}s)')
    axes[0].legend(loc='upper right')
    axes[0].grid(True)

    axes[1].plot(time, error, color='red', linewidth=0.5)
    axes[1].set_xlabel('Tempo (s)')
    axes[1].set_ylabel('Erro')
    axes[1].set_title('Erro (Referência - Predito)')
    axes[1].grid(True)

    # Spectral difference
    n_fft = 512
    hop = 256
    f, t, Zt = stft(y_true, fs=fs, nperseg=n_fft, noverlap=n_fft - hop,
                    window='hann', boundary=None, padded=False)
    f, t, Zp = stft(y_pred, fs=fs, nperseg=n_fft, noverlap=n_fft - hop,
                    window='hann', boundary=None, padded=False)
    min_t = min(Zt.shape[1], Zp.shape[1])
    Zt = Zt[:, :min_t]
    Zp = Zp[:, :min_t]
    t = t[:min_t] + start / fs
    eps = 1e-10
    Pt = np.maximum(np.abs(Zt) ** 2, eps)
    Pp = np.maximum(np.abs(Zp) ** 2, eps)
    diff_db = 10 * np.log10(Pt) - 10 * np.log10(Pp)

    im = axes[2].pcolormesh(t, f, diff_db, shading='gouraud',
                            cmap='RdBu_r', vmin=-20, vmax=20)
    axes[2].set_xlabel('Tempo (s)')
    axes[2].set_ylabel('Frequência (Hz)')
    axes[2].set_title('Diferença Espectral (dB) - Positivo = subestimado')
    plt.colorbar(im, ax=axes[2])
    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Gráfico de comparação salvo em: {save_path}")
    plt.close()


# ============================ REPORT ============================
def generate_report(cfg, metrics, train_losses, val_losses, plots_info, output_path):
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("RELATÓRIO DE DESEMPENHO - MODELAGEM DE ÁUDIO COM CNN DILATADA\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"Data de execução: {np.datetime64('now')}\n\n")

        f.write("CONFIGURAÇÕES:\n")
        f.write(f"  Fs alvo: {cfg.Fs_target} Hz\n")
        f.write(f"  Tamanho do frame: {cfg.frame_len} amostras "
                f"({cfg.frame_len/cfg.Fs_target:.2f} s)\n")
        f.write(f"  Hop: {cfg.hop_len} amostras\n")
        f.write(f"  Épocas máximas: {cfg.num_epochs}\n")
        f.write(f"  Limite de épocas aplicado: {cfg.limit_epochs}\n")
        f.write(f"  Limite de arquivos aplicado: {cfg.limit_files}\n")
        f.write(f"  Batch size: {cfg.batch_size}\n")
        f.write(f"  Taxa de aprendizado: {cfg.learn_rate}\n")
        f.write(f"  Pre-ênfase: {cfg.pre_emph}\n")
        f.write(f"  Dispositivo: {cfg.device}\n")
        f.write(f"  Modo multi-arquivo: {cfg.multi_file_mode}\n")
        if cfg.multi_file_mode:
            f.write(f"  Padrão Line: '{cfg.line_pattern}', Mic: '{cfg.mic_pattern}'\n")
            f.write(f"  Pasta de dados: {cfg.data_path}\n")
        else:
            f.write(f"  Arquivo de entrada: {cfg.input_file}\n")
            f.write(f"  Arquivo alvo: {cfg.target_file}\n")
        f.write(f"  Atraso fixo: {cfg.fixed_delay}\n\n")

        f.write("MÉTRICAS DE DESEMPENHO (sinal completo)\n")
        f.write("-" * 60 + "\n")
        for k, v in metrics.items():
            if isinstance(v, float) and not np.isnan(v):
                f.write(f"  {k:>12s}: {v:.4f}\n")
            else:
                f.write(f"  {k:>12s}: N/A\n")

        f.write("\nINFORMAÇÕES DO TREINAMENTO\n")
        f.write("-" * 60 + "\n")
        if val_losses:
            f.write(f"  Melhor loss de validação: "
                    f"{min(v for _, v in val_losses):.4e}\n")
            f.write(f"  Loss final de validação: {val_losses[-1][1]:.4e}\n")
        else:
            f.write("  Nenhuma validação executada.\n")
        f.write(f"  Loss final de treino: {train_losses[-1]:.4e}\n")
        f.write(f"  Número de épocas treinadas: {len(train_losses)}\n")

        f.write("\nGRÁFICOS GERADOS\n")
        f.write("-" * 60 + "\n")
        for name, path in plots_info.items():
            f.write(f"  {name}: {path}\n")

        f.write("\n" + "=" * 80 + "\n")
        f.write("FIM DO RELATÓRIO\n")
        f.write("=" * 80 + "\n")
    print(f"Relatório salvo em: {output_path}")


# ---------------------------- CLI ----------------------------
def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--limit-files", type=int, default=None,
                   help="Use only the first N matched Line/Mic pairs. "
                        "Try --limit-files 1 for a smoke test.")
    p.add_argument("--limit-epochs", type=int, default=None,
                   help="Cap the number of training epochs. "
                        "Try --limit-epochs 3 for a smoke test.")
    p.add_argument("--data-path", default=None,
                   help="Override Config.data_path (the folder with wavs).")
    p.add_argument("--multi-file", dest="multi_file", action="store_true",
                   default=None, help="Force multi-file mode.")
    p.add_argument("--single-file", dest="multi_file", action="store_false",
                   help="Force single-file mode.")
    return p.parse_args()

# ---------------------------- Main ----------------------------
if __name__ == "__main__":
    args = parse_args()

    if args.data_path is not None:
        cfg.data_path = args.data_path
    if args.multi_file is not None:
        cfg.multi_file_mode = args.multi_file
    cfg.limit_files = args.limit_files
    cfg.limit_epochs = args.limit_epochs

    print(f"Device       : {cfg.device}")
    print(f"Data path    : {cfg.data_path}")
    print(f"Mode         : {'multi-file' if cfg.multi_file_mode else 'single-file'}")
    print(f"Limit files  : {cfg.limit_files if cfg.limit_files is not None else 'ALL'}")
    print(f"Limit epochs : {cfg.limit_epochs if cfg.limit_epochs is not None else 'ALL'}")

    # 1. Prepare data
    X_train, Y_train, X_val, Y_val, x_line_pre, y_mic_ref = prepare_data(cfg)

    # 2. Model + training
    model = ResidualDilatedCNN().to(cfg.device)
    print(model)
    model, train_losses, val_losses = train_model(
        cfg, model, X_train, Y_train, X_val, Y_val
    )

    # 3. Inference on full signal
    print("\n=== Inferência sobre o sinal completo ===")
    y_out = infer_overlap_add(
    model, x_line_pre, cfg.frame_len, cfg.hop_len, cfg.pre_emph, cfg.device,
    target_rms=0.1,
    )
    out_path = os.path.join(cfg.results_dir, cfg.output_file)
    write_audio(out_path, y_out, cfg.Fs_target)
    print(f"Áudio de saída salvo em: {out_path}")

    # 4. Objective metrics
    print("\n=== Calculando métricas de qualidade ===")
    metrics = compute_metrics(y_mic_ref, y_out, cfg.Fs_target)
    print("Resultados das métricas:")
    for k, v in metrics.items():
        if isinstance(v, float) and not np.isnan(v):
            print(f"  {k}: {v:.4f}")
        else:
            print(f"  {k}: N/A")

    # 5. Plots
    print("\n=== Gerando gráficos ===")
    plot_learning_curves(
        train_losses, val_losses,
        save_path=os.path.join(cfg.plots_dir, 'learning_curve.png')
    )
    plot_signal_comparison(
        y_mic_ref, y_out, cfg.Fs_target,
        title='Comparação entre Referência e Predito',
        save_path=os.path.join(cfg.plots_dir, 'signal_comparison.png')
    )

    # 6. Report
    plots_info = {
        'Curva de Aprendizagem': os.path.join(cfg.plots_dir, 'learning_curve.png'),
        'Comparação de Sinais': os.path.join(cfg.plots_dir, 'signal_comparison.png'),
    }
    report_path = os.path.join(cfg.metrics_dir, cfg.report_filename)
    generate_report(cfg, metrics, train_losses, val_losses, plots_info, report_path)

    print("\n=== Processo concluído ===")
