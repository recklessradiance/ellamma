# ellamma 🦙

**Ellamma** is a self-contained, on-device AI voice assistant engine for legacy iOS hardware, specifically designed for the **iPhone 4S** (Apple A5, 512 MB RAM) running **iOS 6.1.3**.

It runs local LLM text generation and speech synthesis natively on-device with zero internet connection or server dependencies.

---

## 🌟 Features

- **Native ARMv7 LLM Inference**: Runs `llama2.c` (TinyStories 15M) cross-compiled with `clang` targeting iOS 6.0/6.1.
- **On-Device Voice Synthesis**: Integrated with iOS 6 `VoiceServices.framework` (Samantha voice) via `AVAudioSession` inside SpringBoard.
- **System-Wide UI & Gesture Triggering**: Built as a `MobileSubstrate` SpringBoard tweak hooked into `libactivator` (e.g., Hold Volume Down to launch the AI prompt from any screen).
- **Zero External Runtime Dependencies**: Self-contained C & Objective-C binary & dylib footprint.

---

## 📊 Benchmarks (iPhone 4S / Apple A5 / 512 MB RAM)

| Model | Parameters | Quant/Format | Generation Speed | RAM Usage |
|---|---|---|---|---|
| TinyStories 15M | 15 Million | FP32 (`stories15M.bin`) | **~4.5 tok/s** | ~60 MB |
| TinyStories 42M | 42 Million | FP32 (`stories42M.bin`) | ~1.5 tok/s | ~168 MB |

---

## 🛠️ Prerequisites & Requirements

### On Host Machine (macOS):
- Xcode Command Line Tools (`clang`, `codesign`, `git`, `curl`)
- Target SDK: `iPhoneOS6.1.sdk` placed in `./sdk/iPhoneOS6.1.sdk`

### On Target Device (iPhone 4S):
- Jailbroken iOS 6.1.3 (or 6.x)
- OpenSSH installed (default root password: `alpine`)
- `Cydia Substrate` / `MobileSubstrate` installed
- `Activator` installed (via Cydia)

---

## 📥 1. Initial Setup & SDK Acquisition

Clone the repository and fetch the required model weights and SDK:

```bash
git clone https://github.com/<your-username>/ellamma.git
cd ellamma

# 1. Download TinyStories 15M model weights and tokenizer
mkdir -p models
curl -L -o models/stories15M.bin https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin
curl -L -o models/tokenizer.bin https://huggingface.co/karpathy/tinyllamas/resolve/main/tokenizer.bin

# 2. Download legacy iOS 6.1 SDK (if not present in sdk/ directory)
mkdir -p sdk
# Place iPhoneOS6.1.sdk inside ./sdk/iPhoneOS6.1.sdk
```

---

## 🏗️ 2. Cross-Compiling for ARMv7 iOS 6

Build both the CLI inference runtime and the MobileSubstrate SpringBoard tweak:

```bash
# Build the ARMv7 CLI binary (tinystories & hello)
./toolchain/build_iphone.sh

# Build the MobileSubstrate Tweak (ellamma.dylib)
bash tweaks/ellamma/build.sh
```

---

## 🚀 3. Deploying to iPhone 4S

Deploy binaries, model weights, and tweak files to your iPhone over SSH:

```bash
./deploy/deploy.sh <IP_ADDRESS>
```

> **Note on OpenSSH Legacy Keys**: Modern OpenSSH disables `ssh-rsa` by default. The deployment script handles this via `-oHostKeyAlgorithms=+ssh-rsa`. To SSH manually into the device, use:
> ```bash
> ssh -oHostKeyAlgorithms=+ssh-rsa root@<IP_ADDRESS>
> ```

---

## 📱 4. How to Use

### Mode A: Command-Line (CLI Ingestion)
SSH into your iPhone 4S and run inference directly in the shell:

```bash
ssh -oHostKeyAlgorithms=+ssh-rsa root@<IP_ADDRESS>
cd /var/root/tinystories
./tinystories model.bin -z tokenizer.bin -n 80 -i "Once upon a time"
```

### Mode B: Voice Assistant (Activator Gesture)
1. After deployment, restart SpringBoard on the iPhone:
   ```bash
   ssh -oHostKeyAlgorithms=+ssh-rsa root@<IP_ADDRESS> "killall SpringBoard"
   ```
2. Open **Settings → Activator** on the iPhone.
3. Select a gesture (Recommended: **Anywhere → Hold Volume Down**).
4. Tap **Ellamma AI** to link the action.
5. Trigger the gesture from any app or home screen to bring up the AI prompt, generate text, and listen to the on-device voice response!

---

## 🔧 Troubleshooting

- **No sound during speech output?**
  Ensure the physical ringer switch on the side of the iPhone is set to **Ring** (not Silent/Mute) and volume is turned up.
- **SSH connection refused or key error?**
  Add the following to your `~/.ssh/config`:
  ```sshconfig
  Host <IP_ADDRESS>
      HostKeyAlgorithms +ssh-rsa
      PubkeyAcceptedAlgorithms +ssh-rsa
  ```
- **SpringBoard Crash / Safe Mode**:
  Ensure both `MobileSubstrate` and `Activator` are up to date in Cydia.

---

## 📜 License
MIT License.
