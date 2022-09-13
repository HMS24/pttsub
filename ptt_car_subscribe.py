from dotenv import load_dotenv
from requests_html import HTMLSession

load_dotenv()
session = HTMLSession()

BASE_URL = "https://www.ptt.cc"
TOKEN = os.getenv("TOKEN")


def fetch_by_page(page):
    """取得 ptt CarShop 第{page}頁的 html"""
    pass


def parse():
    """解析出賣車標題的列表含該文網址"""
    pass


def save():
    """儲存最新賣車的文"""
    pass


def are_there_new_articles():
    """是否有新的發文"""
    pass


def notify():
    """line notify 通知"""
    pass
