# API (v3)

> [!WARNING]
> The new API (version 3) hasn't been implemented yet. This document is a preview of it. It may change.

This document defines the new API (version 3).

## Run

From the repository root, set the variables described below and run:

```bash
uv run --locked --extra "$device" python api_v3.py \
    --host "$host" \
    --port "$port" \
    --device "$device" \
    --use-half-precision "$half" \
    --token "$token"
```

Parameters:

- `$host`: The address to bind. `0.0.0.0` listens on all IPv4 interfaces; `127.0.0.1` accepts local connections only.
- `$port`: The port of the API server. Should be between 1 and 65535.
- `$device`: The dependency backend: `cu128`, `cu126` or `cpu`. CUDA backends use `cuda:0`. `cpu` uses the CPU.
- `$token`: A required, non-empty bearer token for all API requests.
- `$half`: `true` or `false`. CPU always uses `false`.

## Interfaces

Request headers:
- `Content-Type: application/json` is required only for requests with a JSON body.
- `Authorization: Bearer $token` (Replace the `$token` with the token you are using in the startup arguments)

Successful responses use HTTP 200 unless specified otherwise. JSON responses use the following format; audio and HTTP 204 responses do not use this wrapper:

```json
{
  "success": true,
  "message": "success",
  "data": {}
}
```

| Parameters | Type               | Description                                                                             |
|------------|--------------------|-----------------------------------------------------------------------------------------|
| *`success` | `bool`             | Whether the request is handled successfully                                             |
| `message`  | `string`           | The response message (When a request isn't successful, the error message will in there) |
| `data`     | `object` or `null` | The data of the response. Every request has its own different `data`                    |

`*` marks required fields. In the following passage, `Parameters` are query parameters, `Response Data` shows only the wrapper's `data` value. Unknown JSON fields and invalid parameter values return HTTP 422.

Errors use the same wrapper with `success: false`, an explanatory `message` and `data: null`: HTTP 401 for a missing or invalid token, 404 for a missing resource, 409 for a duplicate name or a configuration in use, 422 for invalid input, 503 when the inference queue is full, and 500 for an unexpected server error.

Model and reference-audio configurations are stored persistently. Adding a configuration checks that its server-side paths exist and are readable; models are loaded when a task runs. Relative paths are resolved from the repository root. Deleting a configuration never deletes files.

List endpoints sort by name in ascending, case-sensitive order. `page` defaults to 1 and must be at least 1; `limit` must be positive or -1, and it defaults to 20. When `limit` is -1, return all results and ignore `page`. A page beyond the results returns an empty list.

### Status

```text
GET /api/v3/status
```

Check the status.

Parameters: *none*

Body: *none*

Response Data:

```json
{
  "running": true,
  "device": "cpu",
  "use_half_precision": false
}
```

| Parameters in body    | Type     | Description                                |
|-----------------------|----------|--------------------------------------------|
| *`running`            | `bool`   | Whether the server is operational          |
| *`device`             | `string` | Actual execution device: `cpu` or `cuda:0` |
| *`use_half_precision` | `bool`   | Whether the half precision is used         |

### Models

```text
POST /api/v3/model/add
```

Add a model configuration.

Parameters: *none*

Body:

```json
{
  "name": "test-model",
  "bert_base_path": "GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large",
  "cnhuhbert_base_path": "GPT_SoVITS/pretrained_models/chinese-hubert-base",
  "t2s_weights_path": "GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt",
  "vits_weights_path": "GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s2G2333k.pth",
  "version": "v2"
}
```

| Parameters in body     | Type            | Description                                    |
|------------------------|-----------------|------------------------------------------------|
| *`name`                | `string`        | The name of the model (should be unique)       |
| *`bert_base_path`      | `string` / path | BERT model directory                           |
| *`cnhuhbert_base_path` | `string` / path | CNHuBERT model directory                       |
| *`t2s_weights_path`    | `string` / path | GPT weights file                               |
| *`vits_weights_path`   | `string` / path | SoVITS weights file                            |
| *`version`             | `string`        | `v1`, `v2`, `v2Pro`, `v2ProPlus`, `v3` or `v4` |

Response Data: *null*

---

```text
DELETE /api/v3/model/delete
```

Delete a model configuration.

Parameters:
- `name` (`string`, required): The name of the model

Body: *none*

Response Data: *null*

---

```text
GET /api/v3/model/list
```

Get all the models.

Parameters:
- `limit` (`int`): The limit of the model results
- `page` (`int`): The page of the model results

Body: *none*

Response Data:

```json
{
  "total": 36,
  "limit": 1,
  "page": 1,
  "models": [
    {
      "name": "test-model",
      "bert_base_path": "GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large",
      "cnhuhbert_base_path": "GPT_SoVITS/pretrained_models/chinese-hubert-base",
      "t2s_weights_path": "GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt",
      "vits_weights_path": "GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s2G2333k.pth",
      "version": "v2"
    }
  ]
}
```

| Parameters in `data` | Type           | Description                                             |
|----------------------|----------------|---------------------------------------------------------|
| *`total`             | `int`          | The total number of models (not only the results count) |
| *`limit`             | `int`          | The limit in the request                                |
| *`page`              | `int`          | The page in the request                                 |
| *`models`            | `list[object]` | The list that contains the query results of model       |

### Reference Audios

```text
POST /api/v3/reference/add
```

Add reference audio configuration.

Parameters: *none*

Body:

```json
{
  "name": "test-audio",
  "source": {
    "type": "file",
    "content": "archive_jingyuan_1.wav"
  },
  "text": "Hello, I'm the model you've trained.",
  "language": "en",
  "auxiliary": []
}
```

| Parameters in body | Type            | Description                                                                  |
|--------------------|-----------------|------------------------------------------------------------------------------|
| *`name`            | `string`        | The name of the audio (should be unique)                                     |
| *`source.type`     | `string`        | The type of source of the audio. Only "file" is supported currently          |
| *`source.content`  | `string` / path | The content of source of the audio. You can only use the file path currently |
| *`text`            | `string`        | The speaking text of the audio                                               |
| *`language`        | `string`        | The language used to speak in the audio                                      |
| *`auxiliary`       | `list[string]`  | Auxiliary reference audio paths for multi-speaker tone fusion                |

Response Data: *null*

---

```text
DELETE /api/v3/reference/delete
```

Delete a reference audio configuration.

Parameters:
- `name` (`string`, required): The name of the reference audio

Body: *none*

Response Data: *null*

---

```text
GET /api/v3/reference/list
```

Get all the reference audios.

Parameters:
- `limit` (`int`): The limit of the audio results
- `page` (`int`): The page of the audio results

Body: *none*

Response Data:

```json
{
  "total": 36,
  "limit": 1,
  "page": 1,
  "audios": [
    {
      "name": "test-audio",
      "source": {
        "type": "file",
        "content": "archive_jingyuan_1.wav"
      },
      "text": "Hello, I'm the model you've trained.",
      "language": "en",
      "auxiliary": []
    }
  ]
}
```

| Parameters in `data` | Type           | Description                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| *`total`             | `int`          | The total number of reference audios (not only the results count) |
| *`limit`             | `int`          | The limit in the request                                          |
| *`page`              | `int`          | The page in the request                                           |
| *`audios`            | `list[object]` | The list that contains the query results of audio                 |

### Infer

```text
POST /api/v3/infer
```

Submit an inference task. After validation and queue admission, return HTTP 202 with an `inference_id`; this means the task was accepted. Tasks run one at a time in submission order, including model loading. A full queue returns HTTP 503 without creating a task.

`parameters` is optional. Omitted parameter fields use the values in the example below. `text` must contain non-whitespace characters, and `model` and `reference` must name existing configurations. `streaming` controls whether audio becomes available in chunks during inference or as one complete result after success; submission is asynchronous in both cases.

Supported language values are `auto`, `en`, `zh`, `ja`, `all_zh` and `all_ja` for v1. Other model versions also support `auto_yue`, `yue`, `ko`, `all_yue` and `all_ko`. Both `text_language` and the reference configuration's `language` must be supported by the selected model, otherwise submission returns HTTP 422.

Parameters: *none*

Body:

```json
{
  "model": "test-model",
  "text": "Hello, World!",
  "text_language": "en",
  "reference": "test-audio",
  "parameters": {
    "top_k": 15,
    "top_p": 1.0,
    "temperature": 1,
    "text_split_method": "cut5",
    "batch_size": 1,
    "batch_threshold": 0.75,
    "split_bucket": true,
    "speed_factor": 1.0,
    "fragment_interval": 0.3,
    "seed": -1,
    "parallel_infer": true,
    "repetition_penalty": 1.35,
    "sample_steps": 32,
    "super_sampling": false,
    "overlap_length": 2,
    "min_chunk_length": 16
  },
  "streaming": false
}
```

| Parameters in body              | Type     | Description                                                                      |
|---------------------------------|----------|----------------------------------------------------------------------------------|
| *`model`                        | `string` | The name of the model to use                                                     |
| *`text`                         | `string` | The text to be synthesized                                                       |
| *`text_language`                | `string` | The language of the text to be synthesized                                       |
| *`reference`                    | `string` | The name of the reference audio to use                                           |
| `parameters.top_k`              | `int`    | Sampling candidate count; at least 1                                             |
| `parameters.top_p`              | `float`  | Nucleus sampling probability; greater than 0 and at most 1                       |
| `parameters.temperature`        | `float`  | Sampling temperature; greater than 0 and at most 1                               |
| `parameters.text_split_method`  | `string` | `cut0`, `cut1`, `cut2`, `cut3`, `cut4` or `cut5`                                 |
| `parameters.batch_size`         | `int`    | Inference batch size; at least 1                                                 |
| `parameters.batch_threshold`    | `float`  | Batch grouping threshold; greater than 0 and at most 1                           |
| `parameters.split_bucket`       | `bool`   | Enable grouping text segments into batches                                       |
| `parameters.speed_factor`       | `float`  | Speech speed multiplier; greater than 0                                          |
| `parameters.fragment_interval`  | `float`  | Silence between fragments in seconds; at least 0                                 |
| `parameters.seed`               | `int`    | `-1` for a random seed, or 0 through 4294967295                                  |
| `parameters.parallel_infer`     | `bool`   | Parallel processing within a task; does not enable concurrent tasks              |
| `parameters.repetition_penalty` | `float`  | Repetition penalty; greater than 0                                               |
| `parameters.sample_steps`       | `int`    | Sampling steps for v3/v4; at least 1; ignored by other versions                  |
| `parameters.super_sampling`     | `bool`   | Enable v3 audio super-resolution; ignored by other versions                      |
| `parameters.overlap_length`     | `int`    | Semantic-token overlap for streaming; at least 1                                 |
| `parameters.min_chunk_length`   | `int`    | Minimum streaming chunk length in semantic tokens; greater than `overlap_length` |
| *`streaming`                    | `bool`   | Whether to stream the audio generated                                            |

All floating-point parameters must be finite. The two chunk-length parameters are ignored when `streaming` is false.

Response Data: 

```json
{
  "inference_id": "9a5c24ff-3d04-437e-8dd8-508aaf884e3e"
}
```

| Parameters in `data` | Type     | Description                                                                                                |
|----------------------|----------|------------------------------------------------------------------------------------------------------------|
| *`inference_id`      | `string` | The id of the inference. You can obtain the information about the inference from the following interfaces. |

---

```text
GET /api/v3/infer/audio
```

Get one audio chunk. Successful reads return HTTP 200 with `Content-Type: audio/wav` and a binary WAV body. The same chunk can be downloaded repeatedly until the task expires.

Missing or expired tasks return HTTP 404. A missing, noninteger or non-positive `chunk` returns HTTP 422. For an existing task, `chunk > chunks` returns HTTP 204 with no body. Check task status to determine whether to wait for more chunks or stop polling.

Parameters: 
- `inference_id` (`string`, required): The id of the inference.
- `chunk` (`int`, required): The chunk index, starting at 1.

Body: *none*

Response Data: *binary audio*

> [!TIP]
> Without streaming, chunk 1 becomes available only after successful completion. With streaming, chunks become available in order during inference.
> Every chunk is a complete, independently decodable WAV file.

---

```text
GET /api/v3/infer/status
```

Check task status. Task status and all its audio chunks expire together 30 minutes after success or failure. Queued and running tasks do not expire; reads do not extend retention. Restarting the server clears tasks and generated audio.

A well-formed status query returns HTTP 200 with `success: true`, including when the task failed or does not exist. This indicates that the query succeeded; inspect `data.failed` and `data.error` for an inference failure.

Parameters:
- `inference_id` (`string`, required): The id of the inference.

Body: *none*

Response Data:

```json
{
  "exists": true,
  "running": true,
  "failed": false,
  "chunks": 18,
  "error": null
}
```

| Parameters in `data` | Type               | Description                                                                                   |
|----------------------|--------------------|-----------------------------------------------------------------------------------------------|
| *`exists`            | `bool`             | Whether the inference is exists                                                               |
| *`running`           | `bool`             | True while queued or executing; false after success or failure                                |
| *`failed`            | `bool`             | Whether the inference is failed                                                               |
| *`chunks`            | `int`              | Number of chunks currently available for download; initially 0; -1 if the task does not exist |
| *`error`             | `string` or `null` | Failure reason when `failed` is true; otherwise null                                          |

| Task state          | `exists` | `running` | `failed` | `chunks`                                        |
|---------------------|----------|-----------|----------|-------------------------------------------------|
| Queued or executing | true     | true      | false    | Currently available count                       |
| Succeeded           | true     | false     | false    | Final count, at least 1                         |
| Failed              | true     | false     | true     | Count of completed chunks retained until expiry |
| Missing or expired  | false    | false     | false    | -1                                              |

> [!TIP]
> Without streaming, `chunks` remains 0 until successful completion, then becomes 1.
