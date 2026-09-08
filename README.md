# Windows Python 开发环境部署

本项目通过 `run.bat` 启动 `deploy_base_scoop.ps1`，在 Windows 上检查并准备一套基础 Python 开发环境：

- Scoop：Windows 命令行软件管理器
- Python：Python 解释器
- uv：Python 项目、依赖和虚拟环境管理工具
- Git：版本控制工具

脚本最低支持 Windows PowerShell 5.1，也可以在 PowerShell 7 中运行。

## 部署前提

- Windows 10 或 Windows 11
- 能够访问 `https://get.scoop.sh` 及 Scoop 软件源
- 当前用户可以修改自己的环境变量和用户目录
- 建议使用普通用户终端，不要以管理员身份运行

## 部署流程

在 PowerShell 中进入本项目目录：

```powershell
Set-Location "E:\Projects\VSCODE\Deploy Base Scoop"
```

推荐通过 `run.bat` 启动。它会为本次 PowerShell 进程使用 `ExecutionPolicy Bypass`，不会永久修改用户的执行策略：

```powershell
.\run.bat
```

也可以不经过批处理文件，直接运行下面的等效命令：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\deploy_base_scoop.ps1
```

脚本按以下顺序执行：

1. 检查 `scoop --version`。
2. 如果 Scoop 不存在，提示输入安装基础目录，例如 `D:\`。
3. 下载官方 Scoop 安装脚本，并在独立的 PowerShell 进程中运行。
4. 依次检查 Python、uv 和 Git。
5. 只安装当前 `PATH` 中没有或无法正常运行的工具。
6. 再次验证三个工具；任意工具验证失败时，脚本以退出码 `1` 结束。

输入 `D:\` 时，Scoop 相关目录为：

```text
D:\Scoop        当前用户的软件和命令入口
D:\ScoopGlobal  预留给 Scoop 的全局安装
```

本脚本使用 `scoop install`，因此 Python、uv 和 Git 默认安装在当前用户的 `D:\Scoop` 中，不需要管理员权限。`D:\ScoopGlobal` 仅作为以后执行全局安装时的目标目录。

部署完成后建议重新打开终端，然后验证：

```powershell
scoop --version
python --version
uv --version
git --version
```

可以查看命令实际来自哪里：

```powershell
Get-Command scoop, python, uv, git | Select-Object Name, Source
```

## 环境架构

```text
PowerShell
    |
    +-- deploy_base_scoop.ps1
            |
            +-- Scoop
                    |
                    +-- apps\        各工具的实际版本目录
                    +-- shims\       PATH 中的统一命令入口
                            |
                            +-- python
                            +-- uv
                            +-- git

Python 项目
    |
    +-- pyproject.toml      项目配置和依赖声明
    +-- uv.lock             锁定后的精确依赖版本
    +-- .venv\             项目专用虚拟环境
    +-- .git\              Git 版本库数据
```

Scoop 的 `shims` 目录加入 `PATH` 后，在任意终端输入 `python`、`uv` 或 `git`，Windows 会通过对应的 shim 找到当前安装版本。Scoop 更新软件版本时，命令名称不变。

uv 通常在每个项目中创建独立的 `.venv`，使不同项目可以使用不同依赖版本。`pyproject.toml` 和 `uv.lock` 应提交到 Git；`.venv` 不应提交。

需要注意：脚本根据 `PATH` 判断工具是否已经安装。如果系统中已有可运行的 Python、uv 或 Git，脚本会直接保留，不会强制替换为 Scoop 版本。因此最终工具来源应以 `Get-Command` 的输出为准。

## Scoop 基本使用

搜索软件：

```powershell
scoop search <软件名>
```

安装、查看和卸载软件：

```powershell
scoop install <软件名>
scoop list
scoop uninstall <软件名>
```

检查可更新的软件并执行更新：

```powershell
scoop status
scoop update
scoop update <软件名>
scoop update *
```

清理某个软件的旧版本：

```powershell
scoop cleanup <软件名>
```

## Python 基本使用

查看版本和解释器位置：

```powershell
python --version
python -c "import sys; print(sys.executable)"
```

进入交互式解释器：

```powershell
python
```

退出交互式解释器：

```python
exit()
```

运行 Python 文件：

```powershell
python .\main.py
```

执行模块：

```powershell
python -m <模块名>
```

项目依赖建议交给 uv 管理，不建议直接向全局 Python 环境安装项目依赖。

## uv 基本使用

创建一个新项目：

```powershell
uv init my-project
Set-Location .\my-project
```

为已有项目创建虚拟环境：

```powershell
uv venv
```

添加、删除和同步依赖：

```powershell
uv add requests
uv remove requests
uv sync
```

在项目虚拟环境中运行命令：

```powershell
uv run python .\main.py
uv run python -c "import sys; print(sys.executable)"
```

运行一次性工具，例如 Ruff：

```powershell
uvx ruff check .
```

常规协作流程是：拉取项目后运行 `uv sync`，开发和执行脚本时使用 `uv run ...`。

## Git 基本使用

首次使用时配置身份：

```powershell
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

创建新仓库或克隆现有仓库：

```powershell
git init
git clone <仓库地址>
```

查看改动、暂存并提交：

```powershell
git status
git add <文件路径>
git commit -m "提交说明"
```

查看历史以及与远程仓库同步：

```powershell
git log --oneline
git pull
git push
```

Python 项目通常应在 `.gitignore` 中排除以下内容：

```gitignore
.venv/
__pycache__/
*.pyc
.pytest_cache/
```

## 常见问题

### 终端找不到刚安装的命令

关闭当前终端并重新打开，然后再次执行版本检查。也可以使用 `Get-Command <命令名>` 查看 PowerShell 是否能从 `PATH` 找到它。

### 安装过程无法下载文件

确认网络可以访问 Scoop 官方安装地址和软件源。脚本会为旧版 Windows PowerShell 临时启用 TLS 1.2，并在结束时恢复原设置。

### 脚本检测到了错误的 Python

执行下面的命令确认解析顺序：

```powershell
Get-Command python -All
python -c "import sys; print(sys.executable)"
```

如果输出不是期望的解释器，需要调整 `PATH` 顺序，或移除冲突的 Windows 应用执行别名。
