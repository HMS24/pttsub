# pttsub
訂閱 ptt CarShop 售車資訊

## 描述

每十分鐘逛一下 CarShop 看板，若有新的售車文會發送 line 通知用戶。使用 python3 撰寫 另外 build 成 docker image，在 container 裡用 crontab 執行定期任務。實在不想每天開 ptt 看，有點累🥲。

<p align="center">
<img src="./assets/demo_image.jpg" alt="_" width="300"/>
</p>

**限制 1: 目前僅抓取該板第一頁的 20 則**，如果在排程的間隔時間內，發文超過 20 則，會有某些文沒抓到。

**限制 2: 另外是 Line notify 的[訊息字元上限 1000](https://notify-bot.line.me/doc/en/)**，太多則後面幾篇文標題會被截斷。

針對描述的限制可以做的改變
- 縮短 cronjob 執行時間

- 精簡 notify 回傳的 message

## 如何使用
### 開發 (使用 pipenv)

    $ pipenv install
    $ pipenv shell
    $ python3 subscribe.py

### 部署前置作業

1. [Line Notify 申請 token](https://notify-bot.line.me/doc/en/)
2. `git clone REPO and cd REPO`

若要部署到遠端機器，假設目標機器 OS 為 `Ubuntu 20.04`:
1. 安裝 `docker` and `docker compose`
2. 新增資料夾 `mkdir ~/ptt` ([`./deploy/publish.sh`](https://github.com/HMS24/pttsub/blob/master/deploy/publish.sh#L15) 有寫入資料夾的名稱 )
3. 設置環境變數 `cd ~/ptt && vi .env`
    - `TOKEN` Line Notify Token

### 本地部署
    
設置環境變數

    $ cp .env.example .env

建立映像檔及部署，預設映像檔名稱: `local/ptt_sub:latest`

    $ ./run.sh local

查看 log

    $ docker logs -f ptt

    2022-09-11 12:50:02 [INFO] ***** It seems that doesn't have new articles *****
    2022-09-11 13:00:01 [INFO] ***** Notify succeed *****

### 遠端部署

建立映像檔及部署，預設映像檔名稱:`$DOCKER_USER/$IMAGE:$TAG`

    $ ./run.sh --target $REMOTE_MACHINE \
               --ssh-pem $REMOTE_MACHINE_PEM_PATH \
               --docker-user $DOCKER_USER \
               --docker-pass $DOCKER_PASSWORD_PATH \
               --image $IMAGE \
               --tag $TAG
Parameters
- `REMOTE_MACHINE`: 遠端機器 (user@hostname)
- `REMOTE_MACHINE_PEM_PATH`: pem 檔案位置 ("$HOME/***.pem")
- `DOCKER_USER`: docker 使用者
- `DOCKER_PASSWORD_PATH` docker 密碼檔案位置 ("$HOME/***")
- `IMAGE`(optional): 映像檔名稱
- `TAG`(optional) 映像檔 tag

## 架構

```shell
.
├── build
│   ├── build.sh
│   ├── crontab             # 執行 module 的 crontab
│   └── Dockerfile
├── deploy               
│   ├── deploy.sh           
│   └── publish.sh          # 在遠端機器部署的 script
├── .env                    
├── subscribe.py            # 主要 module
├── boot.sh                 # 啟動 cron 的 入口 script
├── compose.yml
└── run.sh                  # 執行 build and deploy 的 script
```

### modules 說明

- `boot.sh`: 執行 cron 的 script，使之在前景(foreground)執行。
- `subscribe.py`: 小規模放在一個 module 裡，若未來還有其他需要訂閱的看板，則需要把 `fetch, parse` 等函式功能拆開。
- build
    - `build.sh`: 使用 docker cli plugin 可以指定特定 platform (linux/amd64)，與要部署的遠端機器 OS 一致，減少出錯。
    - `crontab`: crontab 指令，並將 log 導向 stdout 及 stderr。

### 流程圖 - `subscribe.py`

<p align="center">
<img src="./assets/asubscribe_flowll.jpeg" alt="all" width="1680"/>
</p>

### 流程說明 - `subscribe.py`

    - fetch
    - parse
    - 從 cache.txt 取得上次最新文章的 id
    - 與 fetched 的最新文章比較
        - 相同 return
        - 不同
            - save 最新文章 id
            - 切割 fetched[ 0:上一次紀錄的最新文章 index ]
            - Line 通知

### 流程說明 - `run.sh`

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


## 預計工作
- 過濾廠牌及預算，甚至是推文數及推噓等資訊。
- 訂閱其他看板

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

## 一些思考
關於部署、排程及專案初始草稿在 [note.md](https://github.com/HMS24/pttsub/blob/master/assets/note.md)
