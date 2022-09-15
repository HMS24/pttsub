# pttsub

## 描述

每十分鐘逛一下 CarShop 看板，若有新的售車文會發送 line 通知用戶。使用 python3 撰寫 另外 build 成 docker image，在 container 裡用 crontab 執行定期任務。實在不想每天開 ptt 看，有點累🥲。

<p align="center">

<img src="./assets/demo_image.jpg" alt="_" width="300"/>

</p>

**限制 1: 目前僅抓取該板第一頁的 20 則**，如果在排程的間隔時間內，發文超過 20 則，會有某些文沒抓到。

**限制 2: 另外是 Line notify 的[訊息字元上限 1000](https://notify-bot.line.me/doc/en/)**，太多則後面幾篇文標題會被截斷。

## 如何使用

### 前置作業

1. [Line Notify 申請 token](https://notify-bot.line.me/doc/en/)
2. `git clone REPO and cd REPO`

若要部署到遠端機器，假設目標機器 OS 為 `Ubuntu 20.04`:
1. 安裝 `docker` and `docker compose`
2. 新增資料夾 `mkdir ~/ptt` (`./deploy/publish.sh` 有寫入資料夾的名稱 )
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
└── run.sh                  # 執行 build and deploy 的 script
```

說明：

- `boot.sh`: container 啟動後的 entrypoint，執行 cron 的 script，使之在前景(foreground)執行。
- `subscribe.py`: 主要 module，小規模放在一個 module 裡，若未來還有其他需要訂閱的看板，則需要把 `fetch, parse` 等函式功能拆開。
    e.g. `subscribe_CarShop.py` + `subscribe_home-sale.py` + `fetch.py` + `parse.py`
- `build/build.sh`: 使用 docker cli plugin 可以指定特定 platform (linux/amd64)，與要部署的遠端機器 OS 一致。
- `build/crontab`: crontab 指令，將 log 導向 stdout 及 stderr。

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
        - 設定 crontab and run
    - push
        - 推到 docker hub
    - deploy
        - 傳送 compose.yml、publish.sh 及相關 variables
    - publish
        - pull image
        - run container

## 一些問題及資源

- 環境變數讀取不到
    > cron doesn't load your `bashrc` or `bash_profile` so any environment variables defined there are unavailable in your cron jobs

    另外進到 running container 裡面從 `/etc/init.d/cron` 設定檔看到某段
    
    ```shell
        parse_environment ()
        {
            for ENV_FILE in /etc/environment /etc/default/locale; do
                [ -r "$ENV_FILE" ] || continue
                [ -s "$ENV_FILE" ] || continue
        ...
        以下省略
    ```
    可以清楚看到 cronjob 啟動時會 load `/etc/environment`。
    因此在 `boot.sh` 將環境變數導入 `printenv > /etc/environment`。
    但安全性相當差，其他 user 或 service 可能會共用該份檔案，不過這是最快的解決方式了。[reference](https://stackoverflow.com/questions/2229825/where-can-i-set-environment-variables-that-crontab-will-use)

- 針對描述的限制可以做的改變
    - 縮短 cronjob 執行時間
    - 精簡 notify 回傳的 message

- [Cron job troubleshooting guide](https://cronitor.io/cron-reference/cron-troubleshooting-guide)
...

## 未來想要
- 過濾廠牌及預算，甚至是推文數及推噓等資訊。
- 訂閱其他看板

## 雜記

### Ｗhy container？

對於執行 module 可以
1. 我的電腦 mac os 直接運行 cronjob
2. 遠端機器 git pull 操作
3. 打包成 image，遠端 run container

使用 `1` 的方式可以導出 log 到 file 或者從 mail 追蹤 `/var/mail/$USER` cronjob 的 log。
e,g, 將 `crontab` 改成 `*/10 * * * * python3 subscribe.py >> /tmp/cron_log.txt`。
執行 `crontab crontab` 即可。但似乎不太方便，筆電會關機...

`2` 則是在遠端機器上操作，除了 repo 的套件安裝需要手動外，另外像是機器也會需要安裝額外 packages(e.g. git, pipenv 之類)。
還有 git 的 權限，也是個問題。如果遇到 code 更新節奏快或 packages 需要調整就會相對麻煩。

`3` 比較簡單，版本管控也比較單純。但 cron 是屬於系統服務，需要以 root 身份執行，感覺安全性很不足。
另外就是原本的環境變數都不會 load into cronjob，有點 tricky。

最後選擇 `3`，提高開發的效率。

### Ｗhy crontab？

對於排程可以
1. Cron
2. APscheduler
3. Airflow
4. AWS Lambda 設定 event 及 rate

`1` 只有一支 cronjob 要跑且蠻簡單的，較符合需求。但規模開始增加時不好管理。

`2` 需要再 install package，增加套件相依性及管理上的成本(e.g. code, package version)。

`3` 架設 airflow server 以 configuration as code 建造 ETL。看了一下有蠻多功能，可以 task 重跑也可以將 task 組合成不一樣的 ETL 流程，但似乎用不太到，反而得增加維護成本，讓整體開發效率下降...暫不考慮。

`4` 以 cloud 的方式相對不熟。

先以 `1` 快速開發。

### Cheat sheet

    $ crontab -l  列出 cronjobs
    $ crontab -e  編輯
    $ crontab -r  清除所有

### [草稿](./assets/draft.md)
