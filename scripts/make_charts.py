#!/usr/bin/env python3
"""Render dashboard preview charts (SVG only) from the KPI tables exported by run_pipeline.py."""
import pathlib, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from svgmin import minify_svg

plt.rcParams.update({"svg.fonttype": "none", "font.family": "sans-serif", "font.size": 9,
                     "axes.spines.top": False, "axes.spines.right": False, "axes.grid": False})
C1, C2, C3 = "#1f6f8b", "#e07a5f", "#81b29a"


def save(fig, path):
    import io
    buf = io.StringIO(); fig.savefig(buf, format="svg", bbox_inches="tight"); plt.close(fig)
    path.write_text(minify_svg(buf.getvalue()))


def p_dept(ax, t):
    d = pd.read_csv(t / "a_attrition_by_department.csv").sort_values("attrition_pct", ascending=True)
    ax.barh(d.department_name, d.attrition_pct, color=C1)
    for i, (v, n, l) in enumerate(zip(d.attrition_pct, d.employees, d.leavers)):
        ax.text(v + 0.3, i, f"{v:.1f}% ({int(l)}/{int(n)})", va="center", fontsize=7)
    ax.set_xlabel("Attrition %"); ax.set_title("Attrition by department")
    ax.set_xlim(0, max(d.attrition_pct.max() * 1.35, 5))


def p_role(ax, t):
    r = pd.read_csv(t / "a_attrition_by_job_role.csv").sort_values("attrition_pct", ascending=False).head(8)[::-1]
    ax.barh(r.job_role, r.attrition_pct, color=C2)
    for i, v in enumerate(r.attrition_pct):
        ax.text(v + 0.3, i, f"{v:.1f}%", va="center", fontsize=7)
    ax.set_xlabel("Attrition %"); ax.set_title("Top job roles by attrition rate")
    ax.set_xlim(0, max(r.attrition_pct.max() * 1.35, 5))


def p_overtime(ax, t):
    o = pd.read_csv(t / "a_overtime_attrition.csv")
    order = ["No OverTime", "OverTime"]
    o["ord"] = o.overtime_status.map({k: i for i, k in enumerate(order)})
    o = o.sort_values("ord")
    ax.bar(o.overtime_status, o.attrition_pct, color=[C3, C2])
    for i, (v, n) in enumerate(zip(o.attrition_pct, o.employees)):
        ax.text(i, v + 0.5, f"{v:.1f}%\nn={int(n)}", ha="center", fontsize=8)
    ax.set_ylabel("Attrition %"); ax.set_ylim(0, max(o.attrition_pct.max() * 1.4, 5))
    ax.set_title("Overtime vs attrition")


def p_tenure(ax, t):
    d = pd.read_csv(t / "a_tenure_attrition.csv").sort_values("tenure_band")
    ax.bar(d.tenure_band.str[4:], d.attrition_pct, color=C1)
    for i, v in enumerate(d.attrition_pct):
        ax.text(i, v + 0.4, f"{v:.1f}%", ha="center", fontsize=7)
    ax.set_ylabel("Attrition %"); ax.set_xlabel("Years at company")
    ax.set_ylim(0, max(d.attrition_pct.max() * 1.35, 5))
    ax.set_title("Tenure band vs attrition")


def p_satis(ax, t):
    d = pd.read_csv(t / "a_satisfaction_attrition.csv").sort_values("job_satisfaction")
    ax.bar(d.job_satisfaction_label, d.attrition_pct, color=C3)
    for i, v in enumerate(d.attrition_pct):
        ax.text(i, v + 0.4, f"{v:.1f}%", ha="center", fontsize=7)
    ax.set_ylabel("Attrition %"); ax.set_ylim(0, max(d.attrition_pct.max() * 1.35, 5))
    ax.set_title("Job satisfaction vs attrition")


def p_travel(ax, t):
    d = pd.read_csv(t / "a_travel_attrition.csv")
    order = {"Non-Travel": 0, "Travel_Rarely": 1, "Travel_Frequently": 2, "Unknown": 3}
    d["ord"] = d.business_travel.map(order).fillna(9)
    d = d.sort_values("ord")
    ax.bar(d.business_travel.str.replace("_", " "), d.attrition_pct, color=[C1, C3, C2, "#999"][: len(d)])
    for i, v in enumerate(d.attrition_pct):
        ax.text(i, v + 0.4, f"{v:.1f}%", ha="center", fontsize=7)
    ax.set_ylabel("Attrition %"); ax.set_ylim(0, max(d.attrition_pct.max() * 1.35, 5))
    ax.set_title("Business travel vs attrition")


PANELS = [("attrition_by_department", p_dept), ("attrition_by_job_role", p_role),
          ("overtime_attrition", p_overtime), ("tenure_attrition", p_tenure),
          ("satisfaction_attrition", p_satis), ("travel_attrition", p_travel)]


def make_all(tables, out):
    tables, out = pathlib.Path(tables), pathlib.Path(out); out.mkdir(parents=True, exist_ok=True)
    for name, fn in PANELS:
        fig, ax = plt.subplots(figsize=(6.4, 3.6)); fn(ax, tables); save(fig, out / f"{name}.svg")
    k = pd.read_csv(tables / "a_kpi_headline.csv").iloc[0]
    fig, axes = plt.subplots(3, 2, figsize=(14, 13.5)); fig.subplots_adjust(hspace=0.55, wspace=0.35, top=0.88)
    for ax, (_, fn) in zip(axes.flat, PANELS):
        fn(ax, tables)
    cards = [("Employees", f"{int(k.employees_total):,}"), ("Leavers", f"{int(k.leavers):,}"),
             ("Attrition", f"{k.attrition_pct:.2f}%"), ("Avg income", f"${k.avg_monthly_income:,.0f}"),
             ("OT attrition", f"{k.attrition_pct_overtime:.1f}%"), ("No-OT attrition", f"{k.attrition_pct_no_overtime:.1f}%"),
             ("Avg tenure", f"{k.avg_years_at_company:.1f} y")]
    fig.suptitle("IBM HR employee attrition dashboard (preview rendered from SQL outputs)", fontsize=14, y=0.975)
    for i, (lab, val) in enumerate(cards):
        x = 0.07 + i * 0.135
        fig.text(x, 0.935, val, fontsize=13, weight="bold", ha="center", color=C1)
        fig.text(x, 0.918, lab, fontsize=9, ha="center", color="#555")
    save(fig, out / "dashboard.svg")
    print("charts ->", out, sorted(p.name for p in out.glob("*.svg")))


if __name__ == "__main__":
    root = pathlib.Path(__file__).resolve().parents[1]
    make_all(root / "results/tables", root / "results/charts")
