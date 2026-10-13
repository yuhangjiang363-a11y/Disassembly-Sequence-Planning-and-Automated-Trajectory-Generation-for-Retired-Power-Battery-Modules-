import pandas as pd
import json
import math

file_path = r'c:\Users\22013\Desktop\bisheshiyan\2022363312jiangyuhang\Bees-ceshi\chatgpt_airsim -best\路径汇总表_六个零件.xlsx'
df = pd.read_excel(file_path, sheet_name=0)
print(df.head(20).to_string())

