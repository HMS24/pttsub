import os
from dotenv import load_dotenv
from requests_html import HTMLSession

load_dotenv()
session = HTMLSession()

BASE_URL = "https://www.ptt.cc"
TOKEN = os.getenv("TOKEN")


def fetch_by_page(page):
    """取得 ptt CarShop 第{page}頁的 html"""

    return session.get(
        url=f"{BASE_URL}/bbs/CarShop/search",
        params=dict(page=page, q="售車"),
    ).html


def parse(html):
    """解析出賣車標題的列表含該文網址"""

    results = []
    for div_element in html.find(".r-list-container .r-ent"):
        anchor_element = div_element.pq(".title a")

        # href: /bbs/CarShop/M.1663082214.A.EB0.html
        href = anchor_element.attr("href")

        # identifier: M.1663082214.A.EB0
        identifier = href.rpartition("/")[-1].rpartition(".")[0]

        title = anchor_element.text()
        article_absolute_url = f"{BASE_URL}{href}"

        results.append((
            identifier,
            title,
            article_absolute_url,
        ))

    return results


def get_last_identifier():
    with open("cache.txt", "r", encoding="utf-8") as f:
        previous = f.read()

        # M.1663077961.A.6CD,標題,網址
        last_identifier, _, _ = previous.partition(",")
    return last_identifier


def get_latest_index_by_identifier(identifier, trade_list):
    [latest_trade_index] = [index
                            for index, info in enumerate(trade_list)
                            if info[0] == identifier]

    return latest_trade_index


def save(trade_info):
    """儲存最新賣車的文"""
    with open("cache.txt", "w", encoding="utf-8") as f:
        identifier, title, url = trade_info
        f.write(f"{identifier},{title},{url}")


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
    html = fetch_by_page(1)
    trade_list = parse(html)

    latest_info = trade_list[0]
    latest_identifier = latest_info[0]
    last_identifier = get_last_identifier()

    if latest_identifier == last_identifier:
        return

    save(latest_info)

    latest_index = get_latest_index_by_identifier(
        last_identifier,
        trade_list,
    )

    new_trades = trade_list[:latest_index]

    # todo: replace message
    resp = notify("Hello world")

    if resp.status_code != 200:
        print(f"***** Notify failed *****")
    print(f"***** Notify succeed *****")


if __name__ == "__main__":
    main()
