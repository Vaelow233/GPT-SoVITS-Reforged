<div align="center">

<h1>GPT-SoVITS-Reforged</h1>
A modern, reproducible, and developer-friendly distribution of GPT-SoVITS.
<br>

[![Python](https://img.shields.io/badge/python-3.11-blue?style=for-the-badge&logo=python)](https://www.python.org)
[![License](https://img.shields.io/badge/LICENSE-MIT-green.svg?style=for-the-badge&logo=opensourceinitiative)](https://github.com/RVC-Boss/GPT-SoVITS/blob/main/LICENSE)

</div>

---

## Description

GPT-SoVITS-Reforged is an unofficial community fork of [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS), focused on improving its development, installation, and dependency-management experience without unnecessarily changing the core TTS workflow.

For more information about the GPT-SoVITS itself and its models, please go to the original repository [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS).

## Installation & Usage

### Tested Environments

| Python Version | PyTorch Version* | Device        | System       |
|----------------|------------------|---------------|--------------|
| Python 3.11    | PyTorch 2.11.0   | CUDA 12.8     | Windows 11   |
| Python 3.11    | PyTorch 2.11.0   | CPU           | Debian 13    |

*Currently, The project is locked with PyTorch 2.11.0.

### Preparation

The project currently supports Windows x64 and Linux x86_64.

Install uv, FFmpeg, CMake, and curl, and make them available on PATH. Python 3.11 is required; uv can provision it during installation. A C++ build toolchain is also required because OpenCC is built from source.

TorchCodec requires compatible FFmpeg shared libraries. On Windows, use a shared FFmpeg build containing the DLLs, not only ffmpeg.exe.

### Windows

```pwsh
.\install.ps1 -Device cu128 -Source ModelScope -DownloadUVR5
.\go-webui.ps1 -Device cu128
```

The first command will sync the dependencies and finish the project setup. The second command will start to run the Web UI.

Common arguments in `install.ps1`:
- `-Device <device>`: Select the device you will use. Options: `cu128` (default), `cu126`, `cpu`.
- `-Source <source>`: Select the source of the models. The script will download models automatically from selected source. Options: `HF`, `HF-Mirror`, `ModelScope` (default).
- `-DownloadUVR5`: Whether to download the UVR5 model (used to separating vocals or accompaniment and remove reverberation, not necessary).
- `-SkipModels`: Whether skipping the resources download.
- `-Force`: Whether force to redownload the resources.

Common arguments in `go-webui.ps1`:
- `-Device <device>`: Select the device you will use. Options: `cu128` (default), `cu126`, `cpu`.
- `-Language <language>`: Select the language you will prefer to use in Web UI. Default is `zh_CN`.

### Linux

```bash
bash install.sh --device cpu --source ModelScope --download-uvr5
bash go-webui.sh --device cpu
```

The first command will sync the dependencies and finish the project setup. The second command will start to run the Web UI.

Common arguments in `install.sh`:
- `--device <device>`: Select the device you will use. Options: `cu128` (default), `cu126`, `cpu`.
- `--source <source>`: Select the source of the models. The script will download models automatically from selected source. Options: `HF`, `HF-Mirror`, `ModelScope` (default).
- `--download-uvr5`: Whether to download the UVR5 model (used to separating vocals or accompaniment and remove reverberation, not necessary).
- `--skip-models`: Whether skipping the resources download.
- `--force`: Whether force to redownload the resources.

Common arguments in `go-webui.sh`:
- `--device <device>`: Select the device you will use. Options: `cu128` (default), `cu126`, `cpu`.
- `--language <language>`: Select the language you will prefer to use in Web UI. Default is `zh_CN`.

### Docker

Docker uses the same Python 3.11 and uv lockfile as the native installers, with `cpu`, `cu126` and `cu128` images for Linux amd64. From the repository root:

```bash
docker compose up --build -d cu128
docker compose logs -f cu128
```

Replace `cu128` with `cpu` for CPU-only use, or `cu126` for CUDA 12.6. First startup will download models and language resources, then the Web UI will run on http://localhost:9874.

See the [Docker Configuration Guide](Docker/README.md) for environment variables, switching backends and manual builds.

## Pretrained Models

After installation completes without `-SkipModels` / `--skip-models`, steps 1 and 2 can be skipped.
Step 3 can also be skipped if `-DownloadUVR5` / `--download-uvr5` was specified.

1. Download pretrained models from [GPT-SoVITS Models](https://huggingface.co/lj1995/GPT-SoVITS) and place them in `GPT_SoVITS/pretrained_models`.
2. Download G2PW models from [G2PWModel.zip(HF)](https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main/G2PWModel.zip)| [G2PWModel.zip(ModelScope)](https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master/G2PWModel.zip), unzip and rename to `G2PWModel`, and then place them in `GPT_SoVITS/text`.(Chinese TTS Only)
3. For UVR5 (Vocals/Accompaniment Separation & Reverberation Removal, additionally), download models from [UVR5 Weights](https://huggingface.co/lj1995/VoiceConversionWebUI/tree/main/uvr5_weights) and place them in `tools/uvr5/uvr5_weights`.
   - If you want to use `bs_roformer` or `mel_band_roformer` models for UVR5, you can manually download the model and corresponding configuration file, and put them in `tools/uvr5/uvr5_weights`. **Rename the model file and configuration file, ensure that the model and configuration files have the same and corresponding names except for the suffix**. In addition, the model and configuration file names **must include `roformer`** in order to be recognized as models of the roformer class.
   - The suggestion is to **directly specify the model type** in the model name and configuration file name, such as `mel_band_roformer`, `bs_roformer`. If not specified, the features will be compared from the configuration file to determine which type of model it is. For example, the model `bs_roformer_ep_368_sdr_12.9628.ckpt` and its corresponding configuration file `bs_roformer_ep_368_sdr_12.9628.yaml` are a pair, `kim_mel_band_roformer.ckpt` and `kim_mel_band_roformer.yaml` are also a pair.
4. FunASR models are downloaded automatically on first use. The WebUI offers [Fun-ASR-Nano](https://github.com/FunAudioLLM/Fun-ASR) for multilingual and dialect ASR, [SenseVoice](https://github.com/FunAudioLLM/SenseVoice) for fast transcription, and classic Paraformer/UniASR through [FunASR](https://github.com/modelscope/FunASR) for Chinese and Cantonese. To preinstall the classic Chinese models for offline use, download the [ASR model](https://modelscope.cn/models/iic/speech_paraformer-large_asr_nat-zh-cn-16k-common-vocab8404-pytorch/files), [VAD model](https://modelscope.cn/models/iic/speech_fsmn_vad_zh-cn-16k-common-pytorch/files), and [punctuation model](https://modelscope.cn/models/iic/punc_ct-transformer_zh-cn-common-vocab272727-pytorch/files) into `tools/asr/models`.
5. For English or Japanese ASR (additionally), download models from [Faster Whisper Large V3](https://huggingface.co/Systran/faster-whisper-large-v3) and place them in `tools/asr/models/faster-whisper-large-v3`. Also, [other models](https://huggingface.co/Systran) may have the similar effect with smaller disk footprint.

## Dataset Format

The TTS annotation .list file format:

```

vocal_path|speaker_name|language|text

```

Language dictionary:

- 'zh': Chinese
- 'ja': Japanese
- 'en': English
- 'ko': Korean
- 'yue': Cantonese

Example:

```

D:\GPT-SoVITS\xxx/xxx.wav|xxx|en|I like playing Genshin.

```

## (Additional) Method for running from the command line

Use the command line to open the Web UI for UVR5:

```bash
bash run-tool.sh --device cpu -- tools/uvr5/webui.py \
    "<infer_device>" "<is_half>" "<webui_port_uvr5>" "<is_share>"
```

<!-- If you can't open a browser, follow the format below for UVR processing,This is using mdxnet for audio processing
```
python mdxnet.py --model --input_root --output_vocal --output_ins --agg_level --format --device --is_half_precision
``` -->

This is how the audio segmentation of the dataset is done using the command line:

```bash
bash run-tool.sh --device cpu -- tools/slice_audio.py \
    "<input_path>" \
    "<output_root>" \
    "<threshold>" \
    "<min_length>" \
    "<min_interval>" \
    "<hop_size>" \
    "<max_sil_kept>" \
    "<max_amplitude>" \
    "<normalization_alpha>" \
    "<partition_index>" \
    "<partition_count>"
```

Run dataset ASR with FunASR from the following command line. Fun-ASR-Nano is the default for Chinese, English, Japanese, Korean, and automatic language detection; Cantonese keeps the classic FunASR backend.

```bash
bash run-tool.sh --device cpu -- tools/asr/funasr_asr.py -i "<input>" -o "<output>" -l zh
```

Faster Whisper is also available as an ASR backend.

(No progress bars, GPU performance may cause time delays)

```bash
bash run-tool.sh --device cpu -- ./tools/asr/fasterwhisper_asr.py -i "<input>" -o "<output>" -l "<language>" -p "<precision>"
```

A custom list save path is enabled.

## Credits

Special thanks to the original project [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) the following projects and contributors:

### Theoretical Research

- [ar-vits](https://github.com/innnky/ar-vits)
- [SoundStorm](https://github.com/yangdongchao/SoundStorm/tree/master/soundstorm/s1/AR)
- [vits](https://github.com/jaywalnut310/vits)
- [TransferTTS](https://github.com/hcy71o/TransferTTS/blob/master/models.py#L556)
- [contentvec](https://github.com/auspicious3000/contentvec/)
- [hifi-gan](https://github.com/jik876/hifi-gan)
- [fish-speech](https://github.com/fishaudio/fish-speech/blob/main/tools/llama/generate.py#L41)
- [f5-TTS](https://github.com/SWivid/F5-TTS/blob/main/src/f5_tts/model/backbones/dit.py)
- [shortcut flow matching](https://github.com/kvfrans/shortcut-models/blob/main/targets_shortcut.py)

### Pretrained Models

- [Chinese Speech Pretrain](https://github.com/TencentGameMate/chinese_speech_pretrain)
- [Chinese-Roberta-WWM-Ext-Large](https://huggingface.co/hfl/chinese-roberta-wwm-ext-large)
- [BigVGAN](https://github.com/NVIDIA/BigVGAN)
- [eresnetv2](https://modelscope.cn/models/iic/speech_eres2netv2w24s4ep4_sv_zh-cn_16k-common)

### Text Frontend for Inference

- [paddlespeech zh_normalization](https://github.com/PaddlePaddle/PaddleSpeech/tree/develop/paddlespeech/t2s/frontend/zh_normalization)
- [split-lang](https://github.com/DoodleBears/split-lang)
- [g2pW](https://github.com/GitYCC/g2pW)
- [pypinyin-g2pW](https://github.com/mozillazg/pypinyin-g2pW)
- [paddlespeech g2pw](https://github.com/PaddlePaddle/PaddleSpeech/tree/develop/paddlespeech/t2s/frontend/g2pw)

### WebUI Tools

- [ultimatevocalremovergui](https://github.com/Anjok07/ultimatevocalremovergui)
- [audio-slicer](https://github.com/openvpi/audio-slicer)
- [SubFix](https://github.com/cronrpc/SubFix)
- [FFmpeg](https://github.com/FFmpeg/FFmpeg)
- [gradio](https://github.com/gradio-app/gradio)
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper)
- [FunASR](https://github.com/modelscope/FunASR)
- [Fun-ASR](https://github.com/FunAudioLLM/Fun-ASR)
- [SenseVoice](https://github.com/FunAudioLLM/SenseVoice)
- [AP-BWE](https://github.com/yxlu-0102/AP-BWE)

Thankful to @Naozumi520 for providing the Cantonese training set and for the guidance on Cantonese-related knowledge.

## Thanks to all contributors for their efforts

<a href="https://github.com/Vaelow233/GPT-SoVITS-Reforged/graphs/contributors" target="_blank">
  <img src="https://contrib.rocks/image?repo=Vaelow233/GPT-SoVITS-Reforged" />
</a>
