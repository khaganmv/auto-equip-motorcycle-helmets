import os
import json
import xml.etree.ElementTree as ET

from PIL import Image 


BIN_DIR = 'bin/x64/plugins/cyber_engine_tweaks/mods/AutoEquipMotorcycleHelmetsAndGoggles/'
IMAGES_DIR = 'images/'
CONFIGS_DIR = 'configs/'
FOMOD_DIR = 'fomod/'

METADATA_DIR = IMAGES_DIR + 'metadata'
MODULECONFIG_DIR = FOMOD_DIR + 'ModuleConfig.xml'


images = [file for file in os.listdir(IMAGES_DIR) if '.png' in file]
metadata = [line.rstrip() for line in open(METADATA_DIR, 'r').readlines()]

for i, m in zip(images, metadata):
    subdir = m.split('.')[1] + '/'
    
    if not os.path.isdir(CONFIGS_DIR + subdir):
        os.makedirs(CONFIGS_DIR + subdir)
    
    image = Image.open(IMAGES_DIR + i).convert('RGB')    
    image.save(CONFIGS_DIR + subdir + subdir[:-1] + '.jpg')
        
    if not os.path.isdir(CONFIGS_DIR + subdir + BIN_DIR):
        os.makedirs(CONFIGS_DIR + subdir + BIN_DIR)
    
    config = {
        "TDBId": m,
        "slot": 11 if 'Glasses' in m else 17
    }
    
    with open(CONFIGS_DIR + subdir + BIN_DIR + 'config.json', 'w') as cf:
        json.dump(config, cf, indent=4)

tree = ET.parse(MODULECONFIG_DIR)
root = tree.getroot()
opts = root[1][0][0][0][0] 

for opt in opts.findall('plugin'):
    opts.remove(opt)

for m in metadata:
    subdir = m.split('.')[1] + '/'
    
    name = subdir[:-1]
    
    if 'xrxbiker' in subdir:
        name += ' (Requires XRX Helmet)'
    elif 'cathelm' in subdir:
        name += ' (Requires CatEars Helmet)'
    elif 'nekohelm' in subdir:
        name += ' (Requires Neko Cyber-Helmet)'
    
    plugin = ET.SubElement(opts, 'plugin', {'name': name})
    ET.SubElement(plugin, 'description')
    ET.SubElement(plugin, 'image', {'path': CONFIGS_DIR + subdir + subdir[:-1] + '.jpg'})
    
    files = ET.SubElement(plugin, 'files')
    ET.SubElement(files, 'folder', {
        'source': 'bin',
        'destination': 'bin',
        'priority': '0'
    })
    ET.SubElement(files, 'folder', {
        'source': CONFIGS_DIR + subdir + 'bin',
        'destination': 'bin',
        'priority': '0'
    })
    
    type_descriptor = ET.SubElement(plugin, 'typeDescriptor')
    ET.SubElement(type_descriptor, 'type', {'name': 'Optional'})
    
ET.indent(tree, space="    ")
tree.write(MODULECONFIG_DIR)
