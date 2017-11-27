#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import zipfile
import sys
import json
import hashlib
import base64
import shutil
from Crypto.Cipher import DES3

import pyDes

INFO_FILE = "webapp_info.json"
ROUTE = "route_url"
ENTRANCE = "entrance"
VERSION = "version"

KEY = 'divngefkdpqlcmferfxef3de'  # 加密所用的秘钥

Source_path = sys.argv[1] if len(sys.argv) > 1 else "."  # 资源所在的文件夹


# 测试用方法
def deploy(path):
    components = path.split('/')
    file_name = components[len(components) - 1]

    shutil.copy(path, "../" + file_name)


def DES_encrypt(path):

    with open(path, "rb") as f:
        md5 = hashlib.md5()
        md5.update(f.read())

    digest = md5.hexdigest()
    print("md5:" + digest)
    chiped_data = DES3.new(KEY, DES3.MODE_ECB).encrypt(digest)

    # chiped_data = pyDes.triple_des(KEY, pyDes.ECB, IV=None, pad=None, padmode=pyDes.PAD_PKCS5).encrypt(digest)
    based = base64.standard_b64encode(chiped_data)
    return based


def package(route):
    '''
    将资源打包到压缩包中
    :param route: 资源包的路由URL
    :return: 打包后的资源包路径 .encode('utf-8')
    '''
    zip_file_name = route.replace('/', '') + ".zip"
    zip_file_path = Source_path + "/" + zip_file_name
    zip_file = zipfile.ZipFile(zip_file_path, "w", zipfile.ZIP_DEFLATED)

    zip_files = os.walk(Source_path + "/")
    for dirpath, dirnames, filenames in zip_files:
        for filename in filenames:
            if filename == "package.py" or filename == zip_file_name:  # 防止打包脚本和资源文件在同一个目录
                continue

            zip_file.write(Source_path + "/" + dirpath + "/" + filename,
                           arcname=dirpath + "/" + filename)

    zip_file.close()
    return zip_file_path


def setup_package(info={}):
    '''
    设置资源包的信息
    '''
    route = info[ROUTE] if ROUTE in info else input("请输入资源包的路由URL:")
    entrance = info[ENTRANCE] if ENTRANCE in info else input("请指定资源包的入口文件:")
    version = input("请输入版本号(当前版本" + str(info[VERSION]) + "):") if VERSION in info else input("请输入版本号:")

    package_info = {
        ROUTE: route,
        ENTRANCE: entrance,
        VERSION: version
    }
    with open(INFO_FILE, "w") as f:
        json.dump(package_info, f)

    # 打包
    return package(route)


def main():
    if os.path.isfile(INFO_FILE):
        with open(INFO_FILE, "r") as f:
            info = json.load(f)
            path = setup_package(info)
    else:
        path = setup_package()
    # 打包完成计算摘要并加密
    encrypted_hash = DES_encrypt(path)
    print("打包完成，资源包摘要为:" + encrypted_hash.decode('utf-8'))

    deploy(path)


if __name__ == "__main__":
    main()
