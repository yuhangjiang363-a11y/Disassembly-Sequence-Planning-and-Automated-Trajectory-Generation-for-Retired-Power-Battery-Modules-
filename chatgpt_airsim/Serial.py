import serial #导入模块
import threading
import binascii,time

STRGLO="" #读取的数据
BOOL=True  #读取标志位

# 
# 读数代码本体实现
def ReadData(ser):
    global STRGLO,BOOL
    # 循环接收数据
    while BOOL:
        if ser.in_waiting:
            STRGLO = ser.read(ser.in_waiting).decode("UTF-8")
            print(STRGLO)

# 打开串口
# Windows上的 COM3 等
# 波特率，标准值之一：50,75,110,134,150,200,300,600,1200,1800,2400,4800,9600,19200,38400,57600,115200
# 超时设置,None：永远等待操作，0为立即返回请求结果，其他值为等待超时时间(单位为秒）
def DOpenPort(portx,bps,timeout):
    ret=False
    try:
        # 打开串口，并得到串口对象
        ser = serial.Serial(portx, bps, timeout=timeout)
        #判断是否打开成功
        # if(ser.is_open):
        #    ret=True
        #    threading.Thread(target=ReadData, args=(ser,)).start()
    except Exception as e:
        print("---等待---")
    return ser,ret
 
# 关闭串口
def DColsePort(ser):
    global BOOL
    BOOL=False
    ser.close()
 
# 写数据
def DWritePort(ser,text):
    result = ser.write(text.encode("gbk"))  # 写数据
    return result
 
# 读数据
# def DReadPort():
#     global STRGLO
#     str=STRGLO
#     STRGLO=""#清空当次读取
#     return str

def DReadData(ser):
    BOOL = True
    while True:
        if ser.in_waiting:
            if BOOL == True :
                count = ser.inWaiting()
                data = ser.read(count)  # 读一行，以/n结束。
                ##data = str(binascii.b2a_hex(data))[2:-1]
                
                #print("返回值读取：",data) 
                BOOL = False
            else:
                count = ser.inWaiting()
                data = ser.read(count)
                
                data = str(binascii.b2a_hex(data))[2:-1]
                #print("返回值读取：",data) 
                return data
                break 
            
def DReadPort(ser):
    while True:
        if ser.in_waiting:
            count = ser.inWaiting()
            data = ser.read(count)  # 读一行，以/n结束。
            ##data = str(binascii.b2a_hex(data))[2:-1]
            #print("返回值读取：") 
            return data
            break 

# if __name__=="__main__":
    
#     ser,ret=DOpenPort("COM10",115200,10000)

#     DReadPort() #读串口数据

