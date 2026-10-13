
import math
import numpy as np
import Serial
import time
import socket

class XarmWrapper:
    def __init__(self, host='127.0.0.1', port=8080, timeout=20):
        self.host = host
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) # 允许端口重用
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(1)
        self.server_socket.settimeout(timeout)  # 设置超时时间
        print(f"\n[xArm] 服务端已启动: {self.host}:{port}")
        print(f"[xArm] 请现在启动您的 AirSim 仿真或机械臂客户端以连接到此端口...")
        print(f"[xArm] 等待连接中 (限时 {timeout} 秒)...")

        try:
            self.client_socket, self.client_address = self.server_socket.accept()
            print(f"[xArm] 连接成功! 客户端地址: {self.client_address}")
        except socket.timeout:
            print(f"\n[xArm] 错误: 连接超时 ({timeout} 秒内无客户端连接)。")
            print(f"[xArm] 请检查: 1. 仿真软件是否已启动；2. 客户端连接地址是否为 {self.host}，端口是否为 {port}。")
            self.server_socket.close()
            raise Exception("xArm 连接失败: 超时。")
        except Exception as e:
            print(f"\n[xArm] 发生未知连接错误: {e}")
            self.server_socket.close()
            raise e
        

    def run(self):
        self.arm.set_position(*[pose[0], pose[1], pose[2], 180, 0, 0], wait=True)

    def off(self):
        Serial.DWritePort(ser, "停止")

    def go_to(self, x, y=None, z=None):
        if y is None and z is None and isinstance(x, (list, tuple)) and len(x) == 3:
            x, y, z = x
        data = f"{x},{y},{z}\n"
        print(f"Formatted data to send: {data}")
        self.client_socket.sendall(data.encode())
        print(f"Sent data: {data}")

    def install(self):
        data = "INSTALL\n"
        print(f"Formatted data to send: {data}")
        self.client_socket.sendall(data.encode())
        print(f"Sent data: {data}")

    def disassemble(self):
        data = "PART_DISASSEMBLE\n"
        print(f"Formatted data to send: {data}")
        self.client_socket.sendall(data.encode())
        print(f"Sent data: {data}")

    def move_action(self):
        data = "MOVE_TO_DISASSEMBLE_SIDE\n"
        print(f"Formatted data to send: {data}")
        self.client_socket.sendall(data.encode())
        print(f"Sent data: {data}")

    def place(self):
        data = "PART_PLACE\n"
        print(f"Formatted data to send: {data}")
        self.client_socket.sendall(data.encode())
        print(f"Sent data: {data}")

    def move_to_place_side(self):
        data = "MOVE_TO_PLACE_SIDE\n"
        print(f"Formatted data to send: {data}")
        self.client_socket.sendall(data.encode())
        print(f"Sent data: {data}")

    def tool_remove(self):
        data = "TOOL_REMOVE\n"
        print(f"Formatted data to send: {data}")
        self.client_socket.sendall(data.encode())
        print(f"Sent data: {data}")

    def wait_robot(self):
        print("Waiting for robot to send 'OK'...")
        try:
            while True:
                data = self.client_socket.recv(1024)
                if not data:
                    continue
                message = data.decode(errors="ignore").strip()
                if message == "OK":
                    print("Received 'OK' from robot.")
                    return True
        except socket.timeout:
            print("Waiting for 'OK' timed out.")
            return False
   




    
