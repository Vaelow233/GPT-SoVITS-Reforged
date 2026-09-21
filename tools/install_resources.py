import argparse
import importlib.util
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tarfile
import zipfile


SOURCES = {
    "HF": "https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main",
    "HF-Mirror": "https://hf-mirror.com/XXXXRT/GPT-SoVITS-Pretrained/resolve/main",
    "ModelScope": "https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master",
}
ROOT = Path(__file__).resolve().parents[1]


def resource_cache(source):
    # WebUI clears TEMP at startup; download archives must live outside it.
    cache = ROOT / ".cache" / "model-downloads" / source
    legacy = ROOT / "TEMP" / "model-downloads" / source
    cache.mkdir(parents=True, exist_ok=True)
    for name in ("pretrained_models.zip", "G2PWModel.zip", "uvr5_weights.zip",
                 "nltk_data.zip", "open_jtalk_dic_utf_8-1.11.tar.gz"):
        for suffix in ("", ".part"):
            old, new = legacy / (name + suffix), cache / (name + suffix)
            if old.is_file() and not new.exists():
                old.replace(new)
                print(f"[MIGRATE] {new}", flush=True)
    return cache


def present(path):
    if path.is_file():
        return path.stat().st_size > 0
    if path.is_dir():
        return any(
            p.is_file() and p.name not in {".gitignore", ".gitkeep"} and p.stat().st_size > 0
            for p in path.rglob("*")
        )
    return False

def missing_resources(destination, requirements):
    # A tuple denotes alternatives, e.g. vocab.txt OR tokenizer.json.
    missing = []
    for requirement in requirements:
        alternatives = (requirement,) if isinstance(requirement, str) else requirement
        if not any(present(destination / name) for name in alternatives):
            missing.append(" OR ".join(str(destination / name) for name in alternatives))
    return missing


def download(name, cache, source, force=False):
    archive = cache / name
    if not force and present(archive):
        print(f"[CACHE][{source}] {name}", flush=True)
        return archive
    curl = shutil.which("curl.exe" if os.name == "nt" else "curl")
    if not curl:
        raise RuntimeError("curl is required for downloads.")
    cache.mkdir(parents=True, exist_ok=True)
    partial = cache / (name + ".part")
    print(f"[DOWNLOAD][{source}] {name}", flush=True)
    result = subprocess.run([
        curl, "--fail", "--location", "--show-error", "--progress-bar",
        "--retry", "3", "--retry-delay", "2", "--connect-timeout", "30",
        "--continue-at", "0" if force else "-",
        "--output", str(partial), f"{SOURCES[source]}/{name}",
    ], check=False)
    if result.returncode:
        raise RuntimeError(
            f"curl failed (exit {result.returncode}). Partial download retained: {partial}. "
            "Retry to resume, or use --force if the server rejects resume."
        )
    if not present(partial):
        raise RuntimeError(f"Downloaded archive is empty: {partial}")
    partial.replace(archive)
    return archive


def checked_target(destination, member_name):
    # Treat backslashes as separators on both platforms; reject drive/ADS paths too.
    normalized = member_name.replace("\\", "/")
    if ":" in normalized:
        raise ValueError(f"Unsafe archive path: {member_name}")
    target = (destination / normalized).resolve()
    if not target.is_relative_to(destination.resolve()):
        raise ValueError(f"Archive path escapes destination: {member_name}")
    return target


def extract(archive, destination):
    destination.mkdir(parents=True, exist_ok=True)
    if archive.suffix == ".zip":
        with zipfile.ZipFile(archive) as bundle:
            # Validate every entry before writing anything. Model bundles need no links.
            for entry in bundle.infolist():
                checked_target(destination, entry.filename)
                if stat.S_ISLNK(entry.external_attr >> 16):
                    raise ValueError(f"Archive contains a symbolic link: {entry.filename}")
            for entry in bundle.infolist():
                target = checked_target(destination, entry.filename)
                if entry.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with bundle.open(entry) as src, target.open("wb") as dst:
                        shutil.copyfileobj(src, dst)
    else:
        with tarfile.open(archive, "r:gz") as bundle:
            entries = bundle.getmembers()
            for entry in entries:
                checked_target(destination, entry.name)
                if not (entry.isdir() or entry.isfile()):
                    raise ValueError(f"Unsupported archive entry: {entry.name}")
            for entry in entries:
                target = checked_target(destination, entry.name)
                if entry.isdir():
                    target.mkdir(parents=True, exist_ok=True)
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with bundle.extractfile(entry) as src, target.open("wb") as dst:
                        shutil.copyfileobj(src, dst)


def install(name, destination, requirements, cache, source, force=False):
    archive = cache / name
    complete = not missing_resources(destination, requirements)
    # When an archive is available, check every model, not just the baseline
    # requirements. This also detects interrupted extraction of other versions.
    if complete and archive.is_file() and not force:
        if archive.suffix == ".zip":
            with zipfile.ZipFile(archive) as bundle:
                entries = [(e.filename, e.file_size) for e in bundle.infolist() if not e.is_dir()]
        else:
            with tarfile.open(archive, "r:gz") as bundle:
                entries = [(e.name, e.size) for e in bundle.getmembers() if e.isfile()]
        complete = bool(entries) and all(
            (target := checked_target(destination, path)).is_file() and target.stat().st_size == size
            for path, size in entries
        )
    if not force and complete:
        print(f"[SKIP] {name}", flush=True)
        return
    archive = download(name, cache, source, force)
    print(f"[EXTRACT] {name}", flush=True)
    extract(archive, destination)
    missing = missing_resources(destination, requirements)
    if missing:
        raise RuntimeError(
            f"Missing or empty resources after extracting {name}:\n"
            + "\n".join(missing) + f"\nArchive: {archive}\nDestination: {destination}"
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", choices=SOURCES, default="ModelScope")
    parser.add_argument("--download-uvr5", action="store_true")
    parser.add_argument("--force", action="store_true", help="Redownload and re-extract all selected resources")
    args = parser.parse_args()
    # Find the installed package without importing it and triggering its own download
    spec = importlib.util.find_spec("pyopenjtalk")
    if spec is None or not spec.submodule_search_locations:
        raise RuntimeError("pyopenjtalk is missing. Run the uv installer first.")
    dictionary_parent = Path(next(iter(spec.submodule_search_locations)))
    cache = resource_cache(args.source)
    common = dict(cache=cache, source=args.source, force=args.force)
    print(f"[SOURCE] {args.source}\n[ENV] {sys.prefix}", flush=True)
    install("pretrained_models.zip", ROOT / "GPT_SoVITS", [
        "pretrained_models/v2Pro/s2Gv2Pro.pth",
        "pretrained_models/v2Pro/s2Dv2Pro.pth",
        "pretrained_models/s1v3.ckpt",
        "pretrained_models/sv/pretrained_eres2netv2w24s4ep4.ckpt",
        "pretrained_models/chinese-roberta-wwm-ext-large/config.json",
        "pretrained_models/chinese-roberta-wwm-ext-large/pytorch_model.bin",
        ("pretrained_models/chinese-roberta-wwm-ext-large/vocab.txt",
         "pretrained_models/chinese-roberta-wwm-ext-large/tokenizer.json"),
        "pretrained_models/chinese-hubert-base/config.json",
        "pretrained_models/chinese-hubert-base/pytorch_model.bin",
    ], **common)
    install("G2PWModel.zip", ROOT / "GPT_SoVITS" / "text", [
        f"G2PWModel/{name}" for name in (
            "g2pW.onnx", "config.py", "POLYPHONIC_CHARS.txt", "MONOPHONIC_CHARS.txt",
            "char_bopomofo_dict.json", "bopomofo_to_pinyin_wo_tune_dict.json",
        )
    ], **common)
    if args.download_uvr5:
        install("uvr5_weights.zip", ROOT / "tools" / "uvr5", ["uvr5_weights"], **common)
    install("nltk_data.zip", Path(sys.prefix), [
        "nltk_data/corpora/cmudict/cmudict",
        "nltk_data/taggers/averaged_perceptron_tagger/averaged_perceptron_tagger.pickle",
        *[f"nltk_data/taggers/averaged_perceptron_tagger_eng/averaged_perceptron_tagger_eng.{part}.json"
          for part in ("weights", "classes", "tagdict")],
    ], **common)
    install("open_jtalk_dic_utf_8-1.11.tar.gz", dictionary_parent,
            ["open_jtalk_dic_utf_8-1.11/sys.dic"], **common)
    print(f"[DONE] Model and language resources are ready. Archives retained in: {cache}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[ERROR] Interrupted; download cache retained.", file=sys.stderr)
        sys.exit(130)
    except (OSError, RuntimeError, ValueError, zipfile.BadZipFile, tarfile.TarError) as error:
        print(f"[ERROR] {error}", file=sys.stderr)
        sys.exit(1)
