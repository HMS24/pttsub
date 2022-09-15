# pttsub
ptt CarShop 訂閱


## 描述

每十分鐘逛一下 CarShop 看板，若有新的售車文會發送 line 通知用戶。使用 python3 撰寫 另外 build 成 docker image，在 container 裡使用 crontab 執行定期任務。我不想每天開 ptt 看，有點累🥲。

**限制 1: 目前僅抓取該板第一頁的 20 則**，如果在排程的間隔時間內，發文超過 20 則，會有某些文沒抓到。
**限制 2: 另外是 Line notify 的[訊息字元上限 1000](https://notify-bot.line.me/doc/en/)**，太多則後面幾篇文標題會被截斷。

- 縮短 cronjob 執行時間
- 精簡 notify 回傳的 message

## 如何使用

前置作業

1. [Line Notify 申請 token](https://notify-bot.line.me/doc/en/)
2. `git clone REPO and cd REPO`

若要部署到遠端機器，假設目標機器 OS 為 `Ubuntu 20.04`:
1. 安裝 `docker` and `docker compose`
2. 新增資料夾 `mkdir ~/ptt` 
3. 設置環境變數 `cd ~/ptt && vi .env`

### 本地部署
    
設置環境變數

    $ cp .env.example .env

建立映像檔及部署，預設映像檔名稱: `local/ptt_sub:latest`

    $ ./run.sh local

查看 log

    $ docker logs -f ptt

### 遠端部署

建立映像檔及部署，預設映像檔名稱:`$DOCKER_USER/$IMAGE:$TAG`

    $ ./run.sh $REMOTE_MACHINE \
               $REMOTE_MACHINE_PEM_PATH \
               $DOCKER_USER \
               $DOCKER_PASSWORD_PATH \
               $IMAGE \
               $TAG
Parameters
- `REMOTE_MACHINE`: 遠端機器 (user@hostname)
- `REMOTE_MACHINE_PEM_PATH`: pem 檔案位置 ("HOME/***.pem")
- `DOCKER_USER`: docker 使用者
- `DOCKER_PASSWORD_PATH` docker 密碼檔案位置 ("HOME/***")
- `IMAGE`(optional): 映像檔名稱
- `TAG`(optional) 映像檔 tag

## 架構

```shell
.
├── build
│   ├── build.sh
│   ├── crontab             # 執行 module 的 crontab
│   ├── Dockerfile
├── deploy               
│   ├── deploy.sh           
│   ├── publish.sh          # 遠端啟動的 script
├── .env                    
├── subscribe.py            # 主要 module
├── boot.sh                 # 啟動 cron 的 入口 script
├── compose.yml
└── run.sh                  # 流程 script
```

大概說明：

- `boot.sh` container 啟動後的 entrypoint，執行 cron 的 script，使之在前景(foreground)執行。
- `subscribe.py` 主要 module，小規模放在一個 module 裡，若未來還有其他需要訂閱的看板，則需要把 `fetch, parse` 等函式功能拆開。
    e.g. `subscribe_CarShop.py` + `subscribe_home-sale.py` + `fetch.py` + `parse.py`
- `build`
    - `build.sh` 使用 docker cli plugin 可以指定建立特定 platform (linux/amd64)，與要部署的遠端機器 OS 一致
    - `crontab` crontab 指令，將 log 導向 stdout 及 stderr
- `compose.yml` 用 compose.yml 比較簡單，一鍵 up container
- `run.sh` 執行 build and deploy 的 script

`subscribe.py` 流程:

    - fetch
    - parse
    - 從 cache.txt 取得上次最新文章的 id
    - 與 fetched 的最新文章比較
        - 相同 return
        - 不同
            - save 最新文章 id
            - 切割 fetched[ 0:上一次紀錄的最新文章 index ]
            - Line 通知

`run.sh` 流程:

    - build
        - 安裝 packages
        - 設定 crontab and run crontab
    - push
        - 推到 docker hub
    - deploy
        - 傳送 compose.yml 及相關 info
    - publish
        - pull image
        - run container

## why container？

...

## why crontab？

...

## some issue and trick

...

## 記錄初始想法(雜)
目的
自動通知 car 新文

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
