import airsim
import math
import numpy as np
import Serial

objects_dict = {
    "turbine1": "BP_Wind_Turbines_C_1",
    "turbine2": "StaticMeshActor_2",
    "solarpanels": "StaticMeshActor_146",
    "crowd": "StaticMeshActor_6",
    "car": "StaticMeshActor_10",
    "tower1": "SM_Electric_trellis_179",
    "tower2": "SM_Electric_trellis_7",
    "tower3": "SM_Electric_trellis_8",
}


class AirSimWrapper:
    def __init__(self):
        self,ret=Serial.DOpenPort("COM4",115200,10000)


    def takeoff(self):
        Serial.DWritePort(self,"OJ")

    def land(self):
        Serial.DWritePort(self,"OJ")

    def get_drone_position(self):
        Serial.DWritePort(self,"OJ")

    def fly_to(self, point):
        Serial.DWritePort(self,"OJ")

    def fly_path(self, points):
        Serial.DWritePort(self,"OJ")

    def set_yaw(self, yaw):
        Serial.DWritePort(self,"OJ")

    def get_yaw(self):
        Serial.DWritePort(self,"OJ")

    def get_position(self, object_name):
        Serial.DWritePort(self,"OJ")
