import os
import sys
import pandas as pd
os.system(f"{sys.executable} -m pip install -U pytd==1.3.0")
import pytd
from pytd import pandas_td as td

apikey = os.environ['TD_API_KEY']
endpoint = 'https://' + os.environ['ENDPOINT']
session_unixtime = int(os.environ['SESSION_UNIXTIME'])

def main():
    print('Hallow World!')
    print(endpoint)
  
if __name__ == "__main__":
    main()