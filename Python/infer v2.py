"""
INFER – Apply trained model to a new line-input file.
Usage:
    python3 infer_audio.py --input '../Arquivos de teste/Violao linha play.wav' \
                           --output '../Arquivos de teste/xhatCnnPM.wav' \
                           --model 'results/best_model.pt'
"""
import os
import argparse
import numpy as np
import torch
import torch.nn as nn
from scipy.io import wavfile
from scipy.signal import resample, lfilter

# ------------------------- Configuration (must match training) -------------------------
class Config:
    Fs_target = 48000
    frame_len = 16384          # same as training
    hop_len   = 8192
    pre_emph  = 0.97
    model_path = 'results/best_model.pt'   # FIX: matches Train.py save location
    target_rms = 0.1                        # FIX: match training-time normalization
    if torch.backends.mps.is_available():
        device = torch.device('mps')
    elif torch.cuda.is_available():
        device = torch.device('cuda')
    else:
        device = torch.device('cpu')
cfg = Config()

# ------------------------- Model Definition (must match training) ---------------------
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
# ------------------------- Audio Helpers (same as training) -------------------------
def load_audio(path, target_sr=48000):
    """Load audio, mono, resample to target_sr, return float64."""
    sr, data = wavfile.read(path)
    if data.dtype == np.int16:
        data = data.astype(np.float64) / 32768.0
    elif data.dtype == np.int32:
        data = data.astype(np.float64) / 2147483648.0
    else:
        data = data.astype(np.float64)
    if data.ndim > 1:
        data = data.mean(axis=1)
    if sr != target_sr:
        num_samples = int(len(data) * target_sr / sr)
        data = resample(data, num_samples)
    data = data - np.mean(data)
    return data.astype(np.float64), target_sr

def pre_emphasis(x, coeff=0.97):
    return np.append(x[0], x[1:] - coeff * x[:-1])

# FIX: vectorized IIR — identical math to the loop, ~1000x faster
def de_emphasis(x, coeff=0.97):
    return lfilter([1.0], [1.0, -coeff], x)

def normalize_rms(x, target_rms=0.1):
    rms = np.sqrt(np.mean(x ** 2))
    if rms > 0:
        return x * (target_rms / rms)
    return x

def write_audio(path, data, sr):
    data = np.clip(data, -1, 1)
    data_int16 = (data * 32767).astype(np.int16)
    wavfile.write(path, sr, data_int16)

# ------------------------- Overlap-Add Inference -------------------------
def infer_overlap_add(model, x, frame_len, hop_len, pre_emph, device,
                      target_rms=None):
    model.eval()
    L = len(x)
    pad = frame_len // 2                      # FIX: reflect-pad to avoid edge fade
    x_pad = np.pad(x, (pad, pad), mode='reflect')

    y_out_pre = np.zeros(len(x_pad))
    win_weight = np.zeros(len(x_pad))
    window = np.hanning(frame_len)

    num_frames = (len(x_pad) - frame_len) // hop_len + 1
    for i in range(num_frames):
        start = i * hop_len
        end = start + frame_len
        x_frame = x_pad[start:end]
        x_t = torch.from_numpy(x_frame).float()[None, None].to(device)
        with torch.no_grad():
            y_frame = model(x_t).squeeze(0).squeeze(0).cpu().numpy()
        y_out_pre[start:end] += y_frame * window
        win_weight[start:end] += window

    valid = win_weight > 1e-4
    y_out_pre[valid] /= win_weight[valid]

    # FIX: trim the padding
    y_out_pre = y_out_pre[pad:pad + L]

    y_out = de_emphasis(y_out_pre, pre_emph)
    y_out = y_out - np.mean(y_out)

    # FIX: match training-time normalization (RMS to 0.1), not peak to 0.5
    if target_rms is not None:
        y_out = normalize_rms(y_out, target_rms)
    # Safety: prevent clipping on write
    peak = np.max(np.abs(y_out))
    if peak > 0.99:
        y_out = y_out * (0.99 / peak)
    return y_out

# ------------------------- Main -------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description='Apply trained model to line input.')
    parser.add_argument('--input', type=str, required=True,
                        help='Path to input line audio file (WAV).')
    parser.add_argument('--output', type=str, default='output_modeled.wav',
                        help='Path to save the modeled output.')
    parser.add_argument('--model', type=str, default=cfg.model_path,
                        help='Path to saved model weights (.pt).')
    args = parser.parse_args()

    # 1. Load model
    model = ResidualDilatedCNN().to(cfg.device)
    # FIX: explicit weights_only=True; strict=True (default) will raise on mismatch
    state = torch.load(args.model, map_location=cfg.device, weights_only=True)
    model.load_state_dict(state, strict=True)
    print(f"Model loaded from {args.model}")

    # 2. Load audio
    print(f"Loading input: {args.input}")
    x, fs = load_audio(args.input, cfg.Fs_target)
    if fs != cfg.Fs_target:
        print(f"Resampled to {cfg.Fs_target} Hz")
    # FIX: log input stats for sanity
    print(f"Input: {len(x)/cfg.Fs_target:.2f} s @ {cfg.Fs_target} Hz, "
          f"RMS={np.sqrt(np.mean(x**2)):.4f}, peak={np.max(np.abs(x)):.4f}")

    # 3. Pre-emphasis
    x_pre = pre_emphasis(x, cfg.pre_emph)

    # 4. Inference
    print("Running inference...")
    y_out = infer_overlap_add(model, x_pre, cfg.frame_len, cfg.hop_len,
                              cfg.pre_emph, cfg.device,
                              target_rms=cfg.target_rms)
    print(f"Output RMS={np.sqrt(np.mean(y_out**2)):.4f}, "
          f"peak={np.max(np.abs(y_out)):.4f}")

    # 5. Save output
    write_audio(args.output, y_out, cfg.Fs_target)
    print(f"Output saved to {args.output}")

if __name__ == '__main__':
    main()