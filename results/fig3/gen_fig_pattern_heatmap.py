"""Fig (c): Heatmap - Item Accuracy by model x attribute pattern.

Design choices:
  * Sort patterns by CARGO IA descending (left = strongest, right = hardest).
    Reviewers immediately see the difficulty gradient.
  * Custom sequential colormap: clean pale-yellow -> deep red, perceptually
    uniform-ish, prints well in B/W.
  * White gridlines + thicker cell borders -> calm, "tile" look.
  * CARGO row sits at the bottom with a heavy red border around the whole
    row so it pops without an awkward horizontal line floating in mid-plot.
  * Annotations are dark on light cells / white on dark cells via luminance
    threshold so they stay legible everywhere.
  * Compact label forms with periods (Rel., Temp.) avoid rotation while
    keeping fonts large.
"""
import json
import numpy as np
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from paper_plot_style import *
from matplotlib import patches as mpatches
from matplotlib.colors import LinearSegmentedColormap

with open(os.path.join(os.path.dirname(__file__), 'viz_data.json')) as f:
    data = json.load(f)

# Pattern keys / display labels (full names; smaller font OK because we
# don't rotate)
PATTERN_KEYS = ['relational', 'temporal', 'ordinal', 'combined',
                'compliance_invariant', 'nested', 'hierarchy_recursive']
PATTERN_LABEL = {
    'relational': 'Relational',
    'temporal': 'Temporal',
    'ordinal': 'Ordinal',
    'combined': 'Combined',
    'compliance_invariant': 'Compliance',
    'nested': 'Nested',
    'hierarchy_recursive': 'Hierarchical',
}

# Model order: baselines first (alphabetical-ish for neutrality), CARGO last
MODEL_ORDER = ['GPT-4.1', 'GPT-5.2', 'DS-V3.2', 'Gemini-3.1-Pro',
               'GLM-4-32B', 'Qwen3-30B', 'CARGO']

# --- Sort patterns by CARGO IA descending -----------------------------------
cargo_bp = data['CARGO']['by_pattern']
patterns_sorted = sorted(PATTERN_KEYS, key=lambda p: -cargo_bp.get(p, 0))
pattern_labels = [PATTERN_LABEL[p] for p in patterns_sorted]

# --- Build matrix -----------------------------------------------------------
matrix = []
for model in MODEL_ORDER:
    if model not in data:
        matrix.append([0] * len(patterns_sorted))
        continue
    bp = data[model]['by_pattern']
    matrix.append([bp.get(p, 0) * 100 for p in patterns_sorted])
matrix = np.array(matrix)

# --- Colormap: light cream -> warm orange -> deep red -----------------------
cmap = LinearSegmentedColormap.from_list(
    'cargo_warm',
    ['#fff8e7', '#fde2a7', '#f6a96b', '#e0533e', '#9b1d20'],
    N=256,
)

# --- Figure -----------------------------------------------------------------
fig, ax = plt.subplots(1, 1, figsize=(4.8, 3.2))

vmin, vmax = 0, 80
im = ax.imshow(matrix, cmap=cmap, aspect='auto',
               vmin=vmin, vmax=vmax, interpolation='nearest')

# White gridlines between cells (subtle "tile" look)
ax.set_xticks(np.arange(matrix.shape[1] + 1) - 0.5, minor=True)
ax.set_yticks(np.arange(matrix.shape[0] + 1) - 0.5, minor=True)
ax.grid(which='minor', color='white', linewidth=1.4)
ax.tick_params(which='minor', length=0)

# Major ticks for labels
ax.set_xticks(range(len(pattern_labels)))
ax.set_xticklabels(pattern_labels, fontsize=FONT_SIZE, rotation=22, ha='right',
                   rotation_mode='anchor')
ax.set_yticks(range(len(MODEL_ORDER)))
ax.set_yticklabels(MODEL_ORDER, fontsize=FONT_SIZE)

# Hide spines (cleaner)
for spine in ax.spines.values():
    spine.set_visible(False)
ax.tick_params(axis='both', which='major', length=0, pad=4)

# Cell annotations with luminance-aware text color
for i in range(matrix.shape[0]):
    for j in range(matrix.shape[1]):
        val = matrix[i, j]
        # Map val to colormap rgb, pick text color by luminance
        rgba = cmap((val - vmin) / (vmax - vmin))
        lum = 0.299 * rgba[0] + 0.587 * rgba[1] + 0.114 * rgba[2]
        text_color = 'white' if lum < 0.55 else '#222'
        ax.text(j, i, f'{val:.0f}', ha='center', va='center',
                fontsize=FONT_SIZE - 1, color=text_color, fontweight='medium')

# --- Highlight CARGO row with a thick red rectangle border ------------------
cargo_y = len(MODEL_ORDER) - 1
n_cols = matrix.shape[1]
rect = mpatches.Rectangle(
    (-0.5, cargo_y - 0.5), n_cols, 1,
    fill=False, edgecolor='#E64B35', linewidth=2.2, zorder=20,
)
ax.add_patch(rect)
# Tag the CARGO label with the same red
ax.get_yticklabels()[cargo_y].set_color('#E64B35')
ax.get_yticklabels()[cargo_y].set_fontweight('bold')

# --- Colorbar ---------------------------------------------------------------
cbar = fig.colorbar(im, ax=ax, fraction=0.038, pad=0.04)
cbar.set_label('IA (%)', fontsize=FONT_SIZE)
cbar.ax.tick_params(labelsize=FONT_SIZE - 1)
cbar.outline.set_visible(False)

# Title-free per paper convention
plt.tight_layout()
save_fig(fig, 'fig_pattern_heatmap')
plt.close()
print('Done: pattern heatmap (polished)')
