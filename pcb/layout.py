# -*- coding: utf-8 -*-
# exec(open(os.path.join(os.path.dirname(pcbnew.GetBoard().GetFileName()), 'layout.py'), 'r').read())
import pcbnew
from os import path
import json
import math

board = pcbnew.GetBoard()
currentDir = path.dirname(board.GetFileName())


def execute():
    layoutFile = path.join(currentDir, "../design/key_layout.json")
    layoutConfigs = json.load(open(layoutFile, "r"))
    print(layoutConfigs)

    for i, c in enumerate(layoutConfigs):
        x = 205 + c['x']
        y = 150 + -c['y']
        deg = c['deg']
        switchFp = board.FindFootprintByReference("SW" + str(i + 1))
        switchFp.SetPosition(pcbnew.wxPointMM(x, y))
        switchFp.SetOrientation(deg * 10)

        ax = 7.615
        ay = 0
        rad = math.radians(-deg)
        x += ax * math.cos(rad) - ay * math.sin(rad)
        y += ax * math.sin(rad) + ay * math.cos(rad)
        diodeFp = board.FindFootprintByReference("D" + str(i + 1))
        diodeFp.SetPosition(pcbnew.wxPointMM(x, y))
        diodeFp.SetOrientation(deg * 10)

    pcbnew.Refresh()

execute()