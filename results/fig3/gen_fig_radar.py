"""Fig (a): Radar chart - Aggregate performance across 5 key metrics.

Target display: 0.32\\textwidth in a 2-col paper (~2.25 in wide).
Source figsize matches display so font_size = body text size.
"""
import json
import numpy as np
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from paper_plot_style import *

with open(os.path.join(os.path.dirname(__file__), 'viz_data.json')) as f:
    data = json.load(f)

metric_labels = ['BA', 'IA', 'PCS', 'Sec@0FP', 'DDeny']


def get_radar_values(m):
    return [m['BA'], m['IA'], m['PCS'], m['Sec'], m['DDeny']]


model_order = ['CARGO', 'GLM-4-32B', 'GPT-4.1', 'GPT-5.2',
               'DS-V3.2', 'Gemini-3.1-Pro', 'Qwen3-30B']

N = len(metric_labels)
angles = np.linspace(0, 2 * np.pi, N, endpoint=False).tolist()
angles += angles[:1]

# Compact so the panel matches heatmap height in 3-in-row layout.
fig, ax = plt.subplots(1, 1, figsize=(2.2, 2.2), subplot_kw=dict(polar=True))

for model_name in model_order:
    if model_name not in data:
        continue
    vals = get_radar_values(data[model_name]['metrics'])
    vals += vals[:1]
    color = MODEL_COLORS.get(model_name, '#333333')

    if model_name == 'CARGO':
        ax.plot(angles, vals, 'o-', color=color, linewidth=1.6, markersize=4,
                label=model_name, zorder=10)
        ax.fill(angles, vals, alpha=0.18, color=color, zorder=5)
    else:
        ax.plot(angles, vals, '--', color=color, linewidth=1.0,
                label=model_name, alpha=0.85)

ax.set_xticks(angles[:-1])
ax.set_xticklabels(metric_labels, fontsize=FONT_SIZE)
ax.set_ylim(0.0, 1.0)
ax.set_yticks([0.2, 0.4, 0.6, 0.8])
ax.set_yticklabels(['0.2', '0.4', '0.6', '0.8'],
                   fontsize=FONT_SIZE - 2, color='grey')
ax.tick_params(axis='x', pad=7)

# Compact legend below the polar circle. Need extra y-offset so that the
# "DDeny" tick label (which extends below the circle) does not overlap.
ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.16),
          frameon=False, fontsize=FONT_SIZE - 2, ncol=4,
          columnspacing=0.6, handletextpad=0.3, labelspacing=0.25,
          handlelength=1.2, borderpad=0.0)

save_fig(fig, 'fig_radar_metrics')
plt.close()
print('Done: radar chart')
