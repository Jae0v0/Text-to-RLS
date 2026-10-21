"""Plot Scope + Anchor oracle@K (K=1..4), Standard vs Cascaded, merged into
one panel with 4 lines.

Scope = Table + CMD both correct (high 97-100% range).
Anchor = S + O + E all correct (74-85% range).

Fonts moderately sized; legend placed OUTSIDE the plot area so it does not
occlude the Anchor lines on the right.
"""
from __future__ import annotations

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

# ===================== Data =====================
K = [1, 2, 3, 4]

# 490 single-policy items; recomputed and checked by results/tableVIII/reproduce_extraction.py
scope_std = [97.8, 98.2, 98.4, 98.4]
scope_cas = [97.6, 98.4, 98.8, 99.8]
anchor_std = [72.7, 79.2, 81.8, 83.1]
anchor_cas = [76.1, 81.6, 83.1, 83.3]

# ===================== Style =====================
plt.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Times New Roman"],
    "axes.labelsize": 12,
    "axes.titlesize": 12,
    "xtick.labelsize": 11,
    "ytick.labelsize": 11,
    "legend.fontsize": 10,
    "axes.linewidth": 1.0,
    "pdf.fonttype": 42,
})

color_std = "#1f77b4"
color_cas = "#d62728"

# Compact canvas; legend goes inside the empty band between Scope and Anchor.
fig, ax = plt.subplots(1, 1, figsize=(4.6, 3.4), dpi=300)

# ===================== Plot 4 lines =====================
ax.plot(K, scope_std, color=color_std, marker="o", markersize=7,
        linewidth=1.8, linestyle="-", label="Standard (Scope)",
        alpha=0.95, zorder=3)
ax.plot(K, scope_cas, color=color_cas, marker="s", markersize=7,
        linewidth=1.8, linestyle="-", label="Cascaded (Scope)",
        alpha=0.95, zorder=3)
ax.plot(K, anchor_std, color=color_std, marker="^", markersize=7,
        linewidth=1.8, linestyle="--", label="Standard (Anchor)",
        alpha=0.95, zorder=3)
ax.plot(K, anchor_cas, color=color_cas, marker="D", markersize=6,
        linewidth=1.8, linestyle="--", label="Cascaded (Anchor)",
        alpha=0.95, zorder=3)

# ===================== Value labels =====================
def annotate_pair(k_list, std, cas, dy=0.6, dy_lo=1.0):
    # Label the higher point above and the lower point below, per K.
    for k_i, (vs, vc) in enumerate(zip(std, cas), 1):
        (vh, ch), (vl, cl) = ((vc, color_cas), (vs, color_std)) if vc >= vs else ((vs, color_std), (vc, color_cas))
        ax.text(k_i, vh + dy, f"{vh:.1f}", fontsize=8.5, fontweight="bold",
                color=ch, ha="center", va="bottom", zorder=15)
        ax.text(k_i, vl - dy_lo, f"{vl:.1f}", fontsize=8.5, fontweight="bold",
                color=cl, ha="center", va="top", zorder=15)

annotate_pair(K, scope_std, scope_cas, dy=0.4, dy_lo=0.8)
annotate_pair(K, anchor_std, anchor_cas, dy=0.6, dy_lo=1.0)

# ===================== Axes =====================
ax.set_xlabel("K (number of candidates)")
ax.set_ylabel("Oracle Accuracy (%)")
ax.set_xticks(K)
ax.set_xlim(0.6, 5.0)
ax.set_ylim(70, 103)
ax.set_yticks([75, 80, 85, 90, 95, 100])
ax.grid(True, which="major", linestyle="-", alpha=0.22)

# Family annotations: in the blank right margin, level with each line pair's K=4 end
ax.text(4.3, (scope_std[-1] + scope_cas[-1]) / 2, "Scope", fontsize=10, color="#444",
        ha="left", va="center", style="italic", fontweight="bold")
ax.text(4.3, (anchor_std[-1] + anchor_cas[-1]) / 2, "Anchor", fontsize=10, color="#444",
        ha="left", va="center", style="italic", fontweight="bold")

# Legend at the lower-right corner, single column (vertical stack of 4 rows).
ax.legend(loc="lower right", bbox_to_anchor=(0.98, 0.02),
          frameon=True, framealpha=0.92, edgecolor="lightgray",
          borderpad=0.35, labelspacing=0.30, handlelength=1.6,
          handletextpad=0.5, fontsize=8.5, ncol=1)

plt.tight_layout()

out_dir = Path(__file__).resolve().parent
out_pdf = out_dir / "oracle_scope_anchor_merged.pdf"
out_png = out_dir / "oracle_scope_anchor_merged.png"
plt.savefig(str(out_pdf), bbox_inches="tight")
plt.savefig(str(out_png), bbox_inches="tight")
print(f"Saved: {out_pdf}")
print(f"Saved: {out_png}")
plt.close()
