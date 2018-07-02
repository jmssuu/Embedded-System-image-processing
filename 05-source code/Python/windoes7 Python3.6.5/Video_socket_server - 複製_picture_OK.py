####################################
## PBL image to video Socket server 
####################################
from socketserver import BaseRequestHandler, TCPServer
import numpy as np
import cv2
import os
import random
import csv
import time
import math

def parse_img(img):

    negPath = "img\\"
    path = ""
    rand = random.randrange(0,99999999)

    path = negPath+str(rand)+".jpg"
    print("get neg img,save to {}".format(path))
    
    while os.path.exists(path):
        rand = random.randrange(0,99999999)

    path = negPath+str(rand)+".jpg"
    cv2.imwrite(path,img)


class EchoHandler(BaseRequestHandler):
    def handle(self):
        self.recv = ""
        print('Got connection from', self.client_address)
        while True:
            msg = self.request.recv(8192)
            #print(msg)
            if not msg:             
                break
            else:
                msg = msg.decode("utf-8").strip("\n")
                self.recv += msg
        #print(self.recv)
        self.test(self.recv)                  
    def test(self,s):
        #print(s)
        datas = s.split(";")
        try:           
            datas.remove('')
        except:
            pass
        for data in datas:
            if "org=" in data:
                img_str = data.strip("org=")
                ##print(img_str)
                img_int_ls = img_str.split(",")
                try:
                    img_int_ls.remove('')
                except:
                    pass
                
                img_1D_ls = []
                
                for unit in img_int_ls:
                    img_1D_ls.append(int(unit))
                img = np.array(img_1D_ls)
                img = img.reshape(480,720)
                img = img.astype(np.uint8)
                ##for raspberry
                # img = img.reshape(64,128)
                # img = np.rot90(img, 1, (1,0))
                # img = cv2.flip(img, 1)

                parse_img(img)
            elif "times=" in data:
                time_str = data.strip("times=")
                print("get time : {}".format(time_str))


if __name__ == '__main__':
    print("initional socket server...")
    serv = TCPServer(('192.168.1.11', 80), EchoHandler)
    print("socket server start!! ")
    serv.serve_forever()
    



    
