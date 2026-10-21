"""Fig (b): Grouped bar chart - Item Accuracy across difficulty levels.

Target display: 0.32\\textwidth (~2.25 in wide).
"""
import json
import numpy as np
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from paper_plot_style import *

with open(os.path.join(os.path.dirname(__file__), 'viz_data.json')) as f:
    data = json.load(f)

difficulties = ['simple', 'moderate', 'hard', 'extra_hard']
diff_labels = ['Simple', 'Mod.', 'Hard', 'Extra']

model_order = ['GPT-4.1', 'GPT-5.2', 'DS-V3.2', 'Gemini-3.1-Pro',
               'GLM-4-32B', 'Qwen3-30B', 'CARGO']

n_models = len(model_order)
n_diffs = len(difficulties)
x = np.arange(n_diffs)
width = 0.12
offsets = np.arange(n_models) - (n_models - 1) / 2

fig, ax = plt.subplots(1, 1, figsize=(2.4, 2.2))

for i, model_name in enumerate(model_order):
    if model_name not in data:
        continue
    bd = data[model_name]['by_difficulty']
    vals = [bd.get(d, 0) * 100 for d in difficulties]
    color = MODEL_COLORS.get(model_name, '#333333')

    if model_name == 'CARGO':
        bars = ax.bar(x + offsets[i] * width, vals, width * 0.92,
                      color=color, label=model_name, edgecolor='white',
                      linewidth=0.3, zorder=10)
        for bar, val in zip(bars, vals):
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1.0,
                    f'{val:.0f}', ha='center', va='bottom',
                    fontsize=FONT_SIZE - 2, fontweight='bold', color=color)
    else:
        ax.bar(x + offsets[i] * width, vals, width * 0.92,
               color=color, label=model_name, edgecolor='white',
               linewidth=0.3, alpha=0.88)

ax.set_xticks(x)
ax.set_xticklabels(diff_labels, fontsize=FONT_SIZE)
ax.set_ylabel('Item Accuracy (%)', fontsize=FONT_SIZE)
ax.set_ylim(0, 88)
ax.tick_params(axis='y', labelsize=FONT_SIZE - 1)
ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.22),
          frameon=False, fontsize=FONT_SIZE - 2, ncol=4,
          columnspacing=0.5, handletextpad=0.2, labelspacing=0.20,
          handlelength=1.0, borderpad=0.0)
ax.yaxis.grid(True, alpha=0.3, linestyle='--')
ax.set_axisbelow(True)

save_fig(fig, 'fig_difficulty_bar')
plt.close()
print('Done: difficulty bar chart')
