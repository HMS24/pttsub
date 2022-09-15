- fetch
    - source: 
        取得 ptt CarShop 版的**售車**標題網頁
        https://www.ptt.cc/bbs/CarShop/search?page=1&q=%E5%94%AE%E8%BB%8A
    - package:
        `requests` or `requests-html` ?
        use `requests-html` 對 `requests` 的額外包裝也包含了 `pyquery`
        直接定位元素不需要額外 `beautiful or pyquery`
- parse
    解析網頁取得
        - 標題
        - 單頁 url(https://www.ptt.cc/bbs/CarShop/M.1663018172.A.93C.html)
            從 單頁 partition **M.1663018172.A.93C** as identifier
- compare
    - cache 中取得上ㄧ次 fetch 的最新資訊(標題、作者、日期)
    - 與剛剛解析後得到的 list 比較，**先假設沒有刪文**
        e.g.
        - 第一種: 正常狀況
        ```python
            parsed = [a, b, c, d, e]
            newest_in_cache = c

            c_index = parsed.index(c)
            new_publish = parsed[:c_index]
        ```
        - 第二種: 10 分鐘內新售車文超過 20 筆(每頁 20 筆)
            半小時的時間要大量新增售車文，不太常見。略過
            如果不幸發生:
                 - 縮短 cron job 間隔時間
                 - 一次 parsed 2 頁
- storage
    將目前比對的最新存在 cache.txt
    `(identifier, title, single_page_url)`
- schedule
    間隔時間: 半小時
    - packages
        `apschedule` or 單純使用 `linux crontab` ?
        先使用 `linux crontab` 相對單純不需要再裝 package。
- notify
    - mail or line notify
        ~~mail builtin `smtplib` 應該比較容易，line notify 需要花點時間研究 line developer，先選 mail。~~
        use line notify
        `resp.headers["X-RateLimit-Remaining"] 看剩下的 limit count, default 1000 per hour`
- deploy
    - build docker image
    - run on ec2
