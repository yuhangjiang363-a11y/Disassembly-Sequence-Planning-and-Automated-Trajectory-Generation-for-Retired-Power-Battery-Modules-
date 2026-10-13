import openai
from openai import OpenAI
import re
import argparse
from xarm_wrapper import *
import math
import numpy as np
import os
import json
import time


os.chdir(os.path.dirname(os.path.abspath(__file__)))

parser = argparse.ArgumentParser()  #argparse模块是命令行选项、参数和子命令解析器。  建立容器
parser.add_argument("--prompt", type=str, default="prompts/airsim_basic.txt") # 提示
parser.add_argument("--sysprompt", type=str, default="system_prompts/airsim_basic.txt") #GPT约束条件
args = parser.parse_args() #提取参数

with open("./config.json", "r") as f:   # 读文件
    config = json.load(f)

print("Initializing ChatGPT...")
client = OpenAI(
    api_key=config["OPENAI_API_KEY"],
    base_url=config.get("OPENAI_API_BASE", "https://api.openai.com/v1")
)

with open(args.sysprompt, "r", encoding="utf-8") as f: #约束条件
    sysprompt = f.read()

chat_history = [   #聊天记录
    {
        "role": "system",  #机器人人设
        "content": sysprompt
    },
    {
        "role": "user",  #用户提问
        "content": "move 10 units up"  #向上移动10个单位 
    },
    {
        "role": "assistant", #机器人回复内容
        "content": """```python
aw.go_to([aw.get_drone_position()[0], aw.get_drone_position()[1], aw.get_drone_position()[2]+10])
```

This code uses the `go_to()` function to move the drone to a new position that is 10 units up from the current position. It does this by getting the current position of the drone using `get_drone_position()` and then creating a new list with the same X and Y coordinates, but with the Z coordinate increased by 10. The drone will then fly to this new position using `fly_to()`."""
    }
]


def ask(prompt):   #问答程序
    chat_history.append(  #添加聊天记录
        {
            "role": "user",
            "content": prompt,
        } 
    )
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini", #模式
            messages=chat_history, #信息
            temperature=0 #随机性 0-1 0为mini
        )
        chat_history.append(
            {
                "role": "assistant",
                "content": completion.choices[0].message.content, #机器人回答内容
            }
        )
        return chat_history[-1]["content"]
    except openai.AuthenticationError as e:
        print(f"\n{colors.RED}错误: API Key 验证失败 (AuthenticationError)。{colors.ENDC}")
        print(f"{colors.YELLOW}原因: 您的 API Key 错误、已过期或已被撤销。{colors.ENDC}")
        print(f"{colors.BLUE}建议: 1. 检查 config.json 中的 Key 是否完整；\n      2. 如果使用中转，必须在 config.json 中设置 OPENAI_API_BASE。{colors.ENDC}")
        exit()
    except openai.RateLimitError as e:
        print(f"\n{colors.RED}错误: OpenAI API 额度不足 (insufficient_quota)。{colors.ENDC}")
        print(f"{colors.YELLOW}原因: 您的 API Key 余额已耗尽，或者免费试用期已过。{colors.ENDC}")
        print(f"{colors.BLUE}建议: 1. 登录官网检查余额；2. 如果是中转，请检查中转站余额。{colors.ENDC}")
        exit()
    except openai.APITimeoutError as e:
        print(f"\n{colors.RED}错误: 请求超时 (APITimeoutError)。{colors.ENDC}")
        print(f"{colors.YELLOW}原因: 无法连接到 OpenAI 服务器。{colors.ENDC}")
        print(f"{colors.BLUE}建议: 1. 检查网络连接（是否需要 VPN）；\n      2. 如果是中转，请确认 config.json 中的 OPENAI_API_BASE 地址是否正确且无需 VPN 即可访问。{colors.ENDC}")
        exit()
    except Exception as e:
        print(f"\n{colors.RED}发生未知错误: {e}{colors.ENDC}")
        exit()


print(f"Done.")
# compile 生成一个正则表达式  功能搜索代码块
code_block_regex = re.compile(r"```(.*?)```", re.DOTALL) 


def extract_python_code(content):  #提取对话里的python程序
    code_blocks = code_block_regex.findall(content)
    if code_blocks:
        full_code = "\n".join(code_blocks)

        if full_code.startswith("python"):
            full_code = full_code[7:]

        return full_code
    else:
        return None


class colors:  # You may need to change color settings
    RED = "\033[31m"
    ENDC = "\033[m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"


print(f"Initializing xarm...")
try:
    aw = XarmWrapper() #指令集
    print(f"Done.")
except Exception as e:
    print(f"\n{colors.RED}xArm 初始化失败: {e}{colors.ENDC}")
    print(f"{colors.YELLOW}请先确保 AirSim 仿真器或机械臂端已启动并准备连接。{colors.ENDC}")
    exit()

with open(args.prompt, "r", encoding="utf-8") as f: #提示
    prompt = f.read()

ask(prompt) #输入提示
print("Welcome to the AirSim chatbot! I am ready to help you with your AirSim questions and commands.")

while True:
    question = input(colors.YELLOW + "Xarm> " + colors.ENDC) #问题输入框

    if question == "!quit" or question == "!exit":
        break

    if question == "!clear":
        os.system("cls")
        continue

    if question == "!load":
        base_dir = os.path.dirname(os.path.abspath(__file__))
        json_candidates = [
            os.path.join(base_dir, "disassembly_result.json"),
            os.path.join(base_dir, "..", "disassembly_result.json"),
            os.path.join(base_dir, "..", "..", "disassembly_result.json"),
            os.path.join(base_dir, "..", "..", "..", "disassembly_result.json"),
        ]
        points_candidates = [
            os.path.join(base_dir, "paths_table.json"),
            os.path.join(base_dir, "..", "paths_table.json"),
            os.path.join(base_dir, "..", "..", "paths_table.json"),
            os.path.join(base_dir, "..", "..", "..", "paths_table.json"),
        ]
        json_path = next((p for p in json_candidates if os.path.exists(p)), None)
        points_path = next((p for p in points_candidates if os.path.exists(p)), None)

        if json_path and points_path:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            with open(points_path, "r", encoding="utf-8") as f:
                points_data = f.read()
                
            # 构建发送给大模型的终极提示词
            desc = "Here is the database of point coordinates in JSON format:\n"
            desc += f"```json\n{points_data}\n```\n\n"
            
            desc += "Now I have an optimized disassembly sequence from MATLAB:\n"
            
            # MATLAB 导出的 JSON 可能没有 tool_labels，如果没有，我们手动补一个默认的
            tool_labels = data.get('tool_labels', ["T1", "T2", "T3"])
            
            for i in range(len(data['sequence'])):
                part = data['part_labels'][data['sequence'][i]-1]
                tool = tool_labels[data['tools'][i]-1]
                direction = data['dir_labels'][data['directions'][i]-1]
                desc += f"Step {i+1} | Part {part} | Tool {tool} | Direction {direction}\n"
            
            desc += "\nPlease generate the corresponding AirSim control code for this entire sequence based on the JSON database provided above."
            print(f"\n{colors.BLUE}Loading MATLAB sequence and Point Database...{colors.ENDC}")
            print("Sending sequence and points to ChatGPT...")
            question = desc # 将其作为问题发送给 ChatGPT
        else:
            print(f"\n{colors.RED}Error: disassembly_result.json or paths_table.json not found.{colors.ENDC}")
            continue

    response = ask(question) #输入问题

    print(f"\n{response}\n") #打印回答

    code = extract_python_code(response)
    if code is not None:
        print("Please wait while I run the code in Xarm...")
        exec(extract_python_code(response))
        print("Done!\n")
