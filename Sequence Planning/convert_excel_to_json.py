import pandas as pd
import json
import ast
from datetime import datetime

# 恢复 Excel 路径为 xinhao.xlsx
excel_path = r'c:\Users\22013\Desktop\bisheshiyan\2022363312jiangyuhang\Bees-ceshi\xinhao.xlsx'
output_path = r'c:\Users\22013\Desktop\bisheshiyan\2022363312jiangyuhang\Bees-ceshi\chatgpt_airsim -best\paths_table.json'

def _s(x):
    if x is None:
        return ""
    if pd.isna(x):
        return ""
    return str(x).strip()

def _parse_xyz(v):
    s = _s(v)
    if not s:
        return None
    if s.startswith("[") and s.endswith("]"):
        try:
            arr = ast.literal_eval(s)
            if isinstance(arr, (list, tuple)) and len(arr) == 3:
                return [float(arr[0]), float(arr[1]), float(arr[2])]
        except Exception:
            return s
    return s

def _find_header_row(df, a, b):
    for i in range(len(df)):
        if _s(df.iloc[i, 0]) == a and _s(df.iloc[i, 1]) == b:
            return i
    return -1

def parse_parts(df):
    parts = {}
    current_part = ""
    common_headers = []
    dir_headers = []
    
    i = 0
    while i < len(df):
        row = df.iloc[i]
        c0 = _s(row.iloc[0])
        
        # 查找零件名称 (例如 "A 零件")
        if c0.endswith(" 零件"):
            current_part = c0.replace(" 零件", "").strip()
            i += 1
            continue
            
        # 查找公共点位表头
        if c0 == "零件":
            common_headers = [_s(x) for x in df.iloc[i].tolist()]
            i += 1
            # 下一行是具体数值
            if i < len(df):
                values_row = df.iloc[i]
                common_data = {}
                for idx, h in enumerate(common_headers):
                    if h and h != "零件":
                        val = _parse_xyz(values_row.iloc[idx])
                        if val is not None:
                            common_data[h] = val
                
                # 存储该零件的公共数据，稍后合并到各个方向中
                if current_part:
                    parts[current_part] = {"_common": common_data}
            i += 1
            continue
            
        # 查找方向点位表头
        if c0 == "方向":
            dir_headers = [_s(x) for x in df.iloc[i].tolist()]
            i += 1
            # 下面几行是各个方向的数据
            while i < len(df):
                dir_row = df.iloc[i]
                dir_name = _s(dir_row.iloc[0])
                if dir_name not in {"Zp", "Xp", "Xm", "Yp", "Ym"}:
                    break
                
                if current_part in parts:
                    dir_data = parts[current_part].get("_common", {}).copy()
                    for idx, h in enumerate(dir_headers):
                        if h and h != "方向" and h != "说明":
                            val = _parse_xyz(dir_row.iloc[idx])
                            if val is not None:
                                dir_data[h] = val
                    
                    parts[current_part][dir_name] = dir_data
                i += 1
            continue
            
        i += 1
        
    # 移除辅助用的 _common 键
    for p in list(parts.keys()):
        if "_common" in parts[p]:
            del parts[p]["_common"]
            
    return parts

def parse_tools_static(df):
    header_idx = _find_header_row(df, "工具编号", "工具架引导点")
    if header_idx == -1:
        raise ValueError("工具位点位汇总 找不到表头行（需要第一列=工具编号，第二列=工具架引导点）")
    headers = [_s(x) for x in df.iloc[header_idx].tolist()]
    tools = {}
    for i in range(header_idx + 1, len(df)):
        row = df.iloc[i]
        tool_id = _s(row.iloc[0])
        if tool_id not in {"T1", "T2", "T3"}:
            continue
        item = {}
        for col_idx in range(1, len(headers)):
            key = headers[col_idx]
            if not key:
                continue
            val = _parse_xyz(row.iloc[col_idx])
            if val is not None and val != "":
                item[key] = val
                
        # 强制修正 T3 的拆前进入点
        if tool_id == "T3" and "拆前进入点" in item:
            item["拆前进入点"] = [-196.706943004, 158.408905205, 321.685353265]
            
        tools[tool_id] = item
    return tools

def parse_tool_change_flows(df):
    header_idx = _find_header_row(df, "切换流程", "点位1")
    if header_idx == -1:
        raise ValueError("换工具流程汇总 找不到表头行（需要第一列=切换流程，第二列=点位1）")
    headers = [_s(x) for x in df.iloc[header_idx].tolist()]
    flows = {}
    for i in range(header_idx + 1, len(df)):
        row = df.iloc[i]
        flow_name = _s(row.iloc[0])
        if not flow_name or "->" not in flow_name:
            continue
        item = {}
        for col_idx in range(1, len(headers)):
            key = headers[col_idx]
            if not key:
                continue
            val = _parse_xyz(row.iloc[col_idx])
            if val is not None and val != "":
                item[key] = val
        flows[flow_name] = item
    return flows

print(f"Loading {excel_path}...")
xl = pd.ExcelFile(excel_path)
parts_df = xl.parse("路径汇总表")
tools_df = xl.parse("工具位点位汇总")
flows_df = xl.parse("换工具流程汇总")

payload = {
    "meta": {
        "source_excel": excel_path,
        "generated_at": datetime.now().isoformat(timespec="seconds"),
    },
    "parts": parse_parts(parts_df),
    "tools": {
        "static_points": parse_tools_static(tools_df),
        "change_flows": parse_tool_change_flows(flows_df),
    },
}

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)

print(f"Successfully converted to {output_path}")
