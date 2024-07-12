import pandas as pd
from lxml import html
from selenium import webdriver
from selenium.webdriver.chrome.service import Service

import string
import re
import time
from datetime import datetime, timedelta


url_prefix = "https://www.mudah.my/malaysia/properties-for-sale?o="
max_page = 250  # nothing loads after page 250

options = webdriver.ChromeOptions()
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")

prop_list = []
for page in range(1, max_page + 1):
    driver = webdriver.Chrome(options=options)
    driver.get(f"{url_prefix}{page}")
    time.sleep(5)

    tree = html.fromstring(driver.page_source)

    driver.quit()
    
    prop_xpath_list = tree.xpath("/html/body/div[1]/div[3]/div[4]/div[1]/div")

    for prop in prop_xpath_list: 
        title = prop.xpath(".//div[2]/a/text()")
        
        if len(title) > 0:
            location = prop.xpath(".//div[3]/div[1]/span[2]/span/text()")[0]
            
            if location == "Johor":
                price = re.sub(r"[RM, ]", "", 
                        re.sub(r"\s+", " " , 
                               "".join([s for s in prop.xpath(".//div[2]/div[1]/div[1]/text()")[0].strip() if s in string.printable])))
                prop_type = prop.xpath(".//div[2]/div[2]/div[1]/div/text()")[0]
                
                prop_size = prop.xpath(".//div[2]/div[2]/div[2]/div/text()")[0].split(" ")
                sqft = (float(prop_size[0]) * 43560) if prop_size[1] == "Acres" else int(prop_size[0])
                
                raw_post_date = prop.xpath(".//div[3]/div[1]/span[1]/span/text()")[0].split(", ")
                if raw_post_date[0] == "Today":
                    post_date = f"{datetime.now().strftime("%Y-%m-%d")} {raw_post_date[1]}:00"
                elif raw_post_date[0] == "Yesterday":
                    post_date = f"{(datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")} {raw_post_date[1]}:00"
                else:
                    post_date = f"{datetime.now().year}-{datetime.strptime(raw_post_date[0], "%b %d").strftime("%m-%d")} {raw_post_date[1]}:00"
                
                prop_list.append([title[0], price, prop_type, sqft, post_date, location])


johor_df = pd.DataFrame(prop_list, columns=["title", "price", "prop_type", "sqft", "post_date", "location"])
johor_df = johor_df.drop_duplicates().reset_index(drop=True)
johor_df = johor_df.astype({"price": "int64", "sqft": "float64", "post_date": "datetime64[ns]"})

johor_df.to_parquet("johor_properties.parquet", index=False, partition_cols=["post_date"])