# retrained-peoplenet-on-tao-toolkit
peoplenet-on-tao-toolkit は、NVIDIA TAO TOOLKIT を用いて PeopleNet の AIモデル最適化を行うマイクロサービスです。  

## 動作環境
- NVIDIA 
    - TAO TOOLKIT
- PeopleNet
- Docker
- TensorRT Runtime

## PeopleNetについて
PeopleNet は、画像内の人を検出し、カテゴリラベルを返すAIモデルです。  
PeopleNet は、特徴抽出にResNet34を使用しており、混雑した場所でも正確に物体検出を行うことができます。

## 動作手順

### tltファイルを使用した追加学習
1. AWS EC2 instance 作成
    - distribution : NVIDIA Deep Learning AMI
    - インスタンスタイプ：AWS の場合、p3系統以上 で GPUを使用可能
    - storage : 200GB 以上

1. インスタンスの初期設定
    - apt update が機能しないので下記を実行
    ```sh
    sudo su -
    apt-key del 7fa2af80
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb .

    sudo rm /etc/apt/sources.list.d/cuda.list
    sudo rm /etc/apt/sources.list.d/nvidia-ml.list
    ```
    - aws cli の設定
        - `aws configure` の実行
    - s3 等から学習データのダウンロード

1. jupyter-note 起動
    - [nvidia公式](https://docs.nvidia.com/tao/tao-toolkit/text/running_in_cloud/running_tao_toolkit_on_aws.html) を参考に jupyter-notebook 環境を構築する。
    - jupyter-note 起動コマンド

    ```sh
    nohup jupyter notebook --ip 0.0.0.0 --port 8888 --allow-root --NotebookApp.token='' &
    ```

    - 同梱の `detectnet_v2.ipynb` を jupyter-notebook で開き、参考に学習を進める。

1. mount position の選定
    - ec2とcontainerでmountするので、よく考える必要がある。
    - training, prune などの tao command は container内で実行される。
    - そのときに参照する dir, file の path は、container内の構造で指定する必要がある。
    - container内では作業dir として `/workspace` が用意されている

1. pretrainされたtltファイルの用意
    - 追加学習させたいモデルを`input`ディレクトリに用意する。

1. 学習の設定ファイルの用意
    - specs directory に用意されたサンプルを参考に、学習の際に使用するパラメータを設定する。
    - 設定値は学習させる対象や、画像の大きさ、枚数等によって異なる。
    - `specs/detectnet_retrain.txt`内の`model_config.pretrained_model_file`に用意したtltファイルのパス（例：`input/resnet34_peoplenet.tlt`）を書く。

1. トレーニング
    - jupyter-notebook 上でコマンドを実行するが、処理は docker container内で走る
    - 成果物はcontainer内で作成される。mountしている場所を出力directoryにする
    - 成果物は `tlt file` です

1. etlt作成
    - トレーニングで作成できた tlt ファイルを変換する。
    - etltは`output/experiment_dir_final`に作成される。

### engineファイルの生成
PeopleNet のAIモデルをデバイスに最適化するため、ResNet34 における PeopleNet の .etlt ファイルを engine file に変換します。  
現時点におけるNVIDIAの仕様では、GPUのアーキテクチャごとに engine file の生成が必要です。  
つまり、あるサーバで生成した engine file を別のサーバーにそのまま適用することはできません。  
本レポジトリに格納された peoplenet.engine は、実際に生成される engine file の参考例です。  
engine fileへの変換は、Makefile に記載された以下のコマンドにより実行できます。

```
tao-convert:
	docker exec -it tao-tool-kit tao-converter -k tlt_encode -d 3,544,960 -e /app/src/peoplenet.engine /app/src/output/experiment_dir_final/resnet18_detector.etlt 
```

## 相互依存関係にあるマイクロサービス  
本マイクロサービスで最適化された PeopleNet の AIモデルを Deep Stream 上で動作させる手順は、[peoplenet-on-deepstream](https://github.com/latonaio/peoplenet-on-deepstream)を参照してください。  

## engineファイルについて
engineファイルである peoplenet.engine は、[peoplenet-on-deepstream](https://github.com/latonaio/peoplenet-on-deepstream)と共通のファイルであり、本レポジトリで作成した engineファイルを、当該リポジトリで使用しています。  
