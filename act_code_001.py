# -*- coding:utf-8 -*-
#第 0001 题：**做为 Apple Store App 独立开发者，你要搞限时促销，为你的应用**生成激活码**（或者优惠券），
# 使用 Python 如何生成 200 个激活码（或者优惠券）

import random, string

forSelect = string.ascii_letters + "0123456789"

def generate(count, length):
    # count = 200
    # length = 20

    for x in range(count):
        Re = ""
        for y in range(length):
            Re += random.choice(forSelect)
        print(Re)
# 这里的__name__是系统变量，当前函数是主函数的时候，它的值就是__main__
# 如果该文件是被import的包，这里的__name__就是他自己的名字
if __name__ == "__main__":
    generate(200, 20)
