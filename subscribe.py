"""訂閱 ptt CarShop 最新售車文
每半小時跑一次
若有新文則使用 line 發送通知

備註:
id example: M.1663077961.A.6CD
"""

import os
from functools import reduce

from dotenv import load_dotenv
from requests_html import HTMLSession

load_dotenv()
session = HTMLSession()

BASE_URL = "https://www.ptt.cc"
TOKEN = os.getenv("TOKEN")
CACHE_TXT = "cache.txt"


def get_last_id():
    """從 cache.txt 取得上次賣車文的 id"""

    try:
        with open(CACHE_TXT, "r", encoding="utf-8") as f:
            previous = f.read()

            # M.1663077961.A.6CD,標題,網址
            last_id, _, _ = previous.partition(",")
    except FileNotFoundError:
        open(CACHE_TXT, "w", encoding="utf-8").close()

        last_id = None

    return last_id or None


def get_index_by_id(id, trade_list):
    """根據 id 在新抓下的 list 找 index 以便 slice 出最新的發文"""

    try:
        [latest_trade_index] = [index
                                for index, info in enumerate(trade_list)
                                if info[0] == id]
    except ValueError:
        latest_trade_index = len(trade_list)

    return latest_trade_index


def generate_notify_message(input_list):
    """產生 line 訊息"""

    message_list = list(map(
        lambda values: f"\n{values[1]}\n{values[2]}\n",
        input_list,
    ))

    return reduce(
        lambda accu, curr: accu+curr,
        message_list,
        "",
    )


def fetch_by_page(page):
    """取得 ptt CarShop 包含售車標題第{page}頁的 html"""

    return session.get(
        url=f"{BASE_URL}/bbs/CarShop/search",
        params=dict(page=page, q="售車"),
    ).html


def parse(html):
    """解析出欲賣車的 list 包含標題、文章 id 及該文網址"""

    results = []
    for div_element in html.find(".r-list-container .r-ent"):
        anchor_element = div_element.pq(".title a")

        # href: /bbs/CarShop/M.1663082214.A.EB0.html
        href = anchor_element.attr("href")

        # id: M.1663082214.A.EB0
        id = href.rpartition("/")[-1].rpartition(".")[0]

        title = anchor_element.text()
        article_absolute_url = f"{BASE_URL}{href}"

        results.append((
            id,
            title,
            article_absolute_url,
        ))

    return results


def save(trade_info):
    """儲存最新賣車的訊息"""

    with open(CACHE_TXT, "w", encoding="utf-8") as f:
        id, title, url = trade_info
        f.write(f"{id},{title},{url}")


def notify(message):
    """line notify 通知"""

    headers = {
        "Authorization": "Bearer " + TOKEN,
        "Content-Type": "application/x-www-form-urlencoded",
    }

    return session.post(
        url="https://notify-api.line.me/api/notify",
        headers=headers,
        params=dict(message=message),
    )


def main():
    """執行"""

    html = fetch_by_page(1)
    trade_list = parse(html)

    latest_info = trade_list[0]
    latest_id = latest_info[0]
    last_id = get_last_id()

    # 判斷是否有新發文
    if latest_id == last_id:
        return

    save(latest_info)

    # 因為有最新發文，找到上一次紀錄的 index，切割出新舊
    last_trade_index = get_index_by_id(
        last_id,
        trade_list,
    )

    message = generate_notify_message(trade_list[:last_trade_index])
    resp = notify(message)

    if resp.status_code != 200:
        print(f"***** Notify failed *****")
    print(f"***** Notify succeed *****")


if __name__ == "__main__":
    main()
