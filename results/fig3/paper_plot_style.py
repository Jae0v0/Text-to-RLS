"""Shared style configuration for Text2RLS paper figures (v3: body-text-size).

DESIGN PRINCIPLE
----------------
A figure font is "body-text-size" in the final PDF only when figsize matches
the column width used in the \\includegraphics call. PT is an absolute unit
(1pt = 1/72 in), so LaTeX scaling shrinks both the figure AND its embedded
fonts by the same factor.

This module assumes a 3-in-row layout via \\subfigure{0.32\\textwidth} on a
two-column IEEE/ACM paper (textwidth ~ 7.0 in), giving display width ~ 2.25 in
per panel. Source figsize is matched to that, so font_size == rendered_pt.

Body text in IEEE/ACM 2-col papers is 10 pt. Fonts here target 10-11 pt
rendered, which is identical to the body text size.
"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os

FONT_SIZE = 10           # ~body text size when source figsize matches display
DPI = 300
FIG_DIR = os.path.dirname(os.path.abspath(__file__))

matplotlib.rcParams.update({
    'font.size': FONT_SIZE,
    'font.family': 'serif',
    'font.serif': ['Times New Roman', 'Times', 'DejaVu Serif'],
    'axes.labelsize': FONT_SIZE + 1,
    'axes.titlesize': FONT_SIZE + 1,
    'xtick.labelsize': FONT_SIZE,
    'ytick.labelsize': FONT_SIZE,
    'legend.fontsize': FONT_SIZE - 1,
    'figure.dpi': DPI,
    'savefig.dpi': DPI,
    'pdf.fonttype': 42,      # TrueType, not Type 3 (IEEE PDF eXpress)
    'ps.fonttype': 42,
    'savefig.bbox': 'tight',
    'savefig.pad_inches': 0.04,
    'axes.grid': False,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'text.usetex': False,
    'mathtext.fontset': 'stix',
})

# Colorblind-friendly palette (Wong 2011)
COLORS = [
    '#E64B35',  # red   - CARGO
    '#4DBBD5',  # cyan  - GPT-4.1
    '#00A087',  # green - GPT-5.2
    '#F39B7F',  # salmon - DS-V3.2
    '#8491B4',  # grey-blue - Gemini-3.1-Pro
    '#91D1C2',  # light teal - Qwen3-30B
    '#B09C85',  # brown - GLM-4-32B
]

MODEL_COLORS = {
    'CARGO': COLORS[0],
    'GPT-4.1': COLORS[1],
    'GPT-5.2': COLORS[2],
    'DS-V3.2': COLORS[3],
    'Gemini-3.1-Pro': COLORS[4],
    'Qwen3-30B': COLORS[5],
    'GLM-4-32B': COLORS[6],
}


def save_fig(fig, name, fmt='pdf'):
    """Save figure to FIG_DIR as both PDF and PNG."""
    pdf_path = f'{FIG_DIR}/{name}.{fmt}'
    fig.savefig(pdf_path)
    print(f'Saved: {pdf_path}')
    png_path = f'{FIG_DIR}/{name}.png'
    fig.savefig(png_path)
    print(f'Saved: {png_path}')
