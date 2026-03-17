# AIxVolleyball

基于 AI 的排球训练与教学系统，提供视频动作分析、连续帧评估、可视化视频生成和 AI 教练问答能力。

当前项目是 **Flask 单体服务架构**：
- Flask 同时提供前端静态页面和后端 REST API
- 前端为 `HTML + Tailwind CDN + 原生 JavaScript`
- 后端为 `API 层 + Service 层 + Core 算法层`

## 架构总览

```text
Browser
  -> Flask (backend/api/flask_api.py)
      -> /                静态前端 (frontend/)
      -> /api/*           REST API
           -> Service     (backend/services/)
           -> Core        (backend/core/)
                - MediaPipe 姿态检测
                - YOLOv7/Roboflow 排球检测
                - V1/V2/V3 评分器
                - 序列分析与轨迹可视化
```

## 核心能力

- 视频动作分析（单帧 / 连续帧）
- 姿态打分（手臂、重心、触球位置、稳定性）
- V3 智能评分（支持人球位置关系）
- 可视化视频生成（骨架叠加 / 纯骨架 / 对比 / 轨迹）
- AI 教练问答（OpenAI 兼容接口）
- 战术题库接口（按模块与角色筛选）

## 目录结构（与当前代码一致）

```text
AIxVolleyball/
├─ run_flask.py
├─ requirement.txt
├─ CONFIGURATION_GUIDE.md
├─ backend/
│  ├─ api/
│  │  ├─ flask_api.py
│  │  └─ volleyball_api.py
│  ├─ services/
│  │  └─ volleyball_service.py
│  └─ core/
│     ├─ pose_detector.py
│     ├─ volleyball_detector.py
│     ├─ scorer.py / scorer_v2.py / scorer_v3.py
│     ├─ sequence_analyzer.py
│     ├─ trajectory_visualizer.py
│     └─ video_generator.py
├─ frontend/
│  ├─ index.html
│  └─ js/
│     ├─ app.js
│     ├─ api.js
│     ├─ tactics.js
│     ├─ pages.js
│     └─ components.js
├─ config/
│  └─ settings.py
├─ data/
│  ├─ tactics_questions.json
│  ├─ volley_questions.json
│  ├─ templates/
│  └─ models/
├─ output/
└─ docker/
   ├─ Dockerfile
   └─ docker-compose.yml
```

## 环境要求

- Python 3.9+（建议）
- pip
- 建议具备 FFmpeg/OpenCV 运行环境（Docker 已内置）

## 快速开始（本地）

1. 安装项目依赖

```bash
pip install -r requirement.txt
```

2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`：

```env
OPENAI_API_KEY=your_api_key_here
OPENAI_BASE_URL=https://api.chatanywhere.tech
```

3. 启动服务

```bash
python run_flask.py
```

4. 访问

- 前端页面：`http://localhost:5000`
- API 健康检查：`http://localhost:5000/api/health`

## Docker 启动

在 `docker/` 目录执行：

```bash
docker compose up --build
```

服务默认监听 `5000` 端口。

## API 一览

### 健康检查

`GET /api/health`

### 视频分析

`POST /api/analyze/video`  
`multipart/form-data`:
- `video`: 视频文件（mp4/avi/mov/mkv）
- `mode`: `single` 或 `sequence`

### 可视化视频生成

`POST /api/visualize/video`  
`multipart/form-data`:
- `video`
- `vis_type`: `overlay` / `skeleton` / `comparison` / `trajectory`

### 输出文件下载

`GET /api/output/<filename>`

### 战术题库

`GET /api/tactics/questions?module=<模块名>&role=<角色名>`

### 评分摘要

`POST /api/score/summary`

### AI 教练

- `GET /api/ai-coach/test`
- `POST /api/ai-coach/ask`

## 配置说明

- 全局配置：`config/settings.py`
- 默认输出目录：`output/`
- 默认模板：`data/templates/default_template.json`
- 视频限制：默认 50MB，格式由 `flask_api.py` 与 `settings.py` 共同约束

## 开发说明

- 前端 API 基地址使用相对路径 `/api`（见 `frontend/js/api.js`）
- Flask `static_folder` 指向 `frontend/`，因此无需单独前端服务器
- 评分器默认在 `VolleyballService` 中使用 `v3`
- 球检测默认尝试 YOLOv7（权重路径：`backend/core/yV7-tiny/weights/best.pt`）

## 常见问题

### 1. 启动后 AI 教练不可用

检查：
- `.env` 是否存在且 `OPENAI_API_KEY` 正确
- 是否安装了 `openai`、`python-dotenv`
- `OPENAI_BASE_URL` 是否是可访问的 OpenAI 兼容地址

### 2. 视频分析慢或失败

检查：
- 视频是否过长/过大
- 服务器是否具备足够 CPU/GPU/内存
- YOLO 权重文件是否存在

### 3. 依赖安装失败

注意本项目依赖文件名是 **`requirement.txt`**（不是 `requirements.txt`）。

## 版本备注

本 README 已按当前仓库真实实现重写：`Flask + 静态前端 + REST API + 三层后端`。  
若后续改为前后端分离部署（如 Vite/React + FastAPI），需同步更新本文档。

---

## Roadmap

- [ ] 增加自动化测试（单元测试 + API 集成测试）
- [ ] 增加 CI（lint + test + build）
- [ ] 将 AI 教练模型与提示词配置外置化
- [ ] 增加前端多语言支持
- [ ] 增加部署模板（Nginx + Gunicorn + HTTPS）

## Contributing

欢迎提交 Issue 和 PR。

建议流程：

1. Fork 仓库并创建分支：`feature/xxx` 或 `fix/xxx`
2. 完成代码与文档修改
3. 本地自测关键流程（上传、分析、可视化、AI 问答）
4. 提交 PR 并描述改动动机、影响范围、验证方式

提交建议：

- 提交信息尽量语义化（如 `feat: ...`、`fix: ...`）
- 避免把模型大文件或临时输出提交到仓库
- 变更 API 时同步更新本文档

## Changelog

当前仓库未维护独立 `CHANGELOG.md`。  
建议后续按版本维护（例如 `vX.Y.Z`）并记录：
- 新功能
- 破坏性变更
- 修复项

## Security

请勿在仓库中提交任何真实密钥或敏感配置：

- `OPENAI_API_KEY`
- 其他第三方服务 Token / API Key

建议使用 `.env`（本地）或 CI/CD Secret（线上）管理密钥。

## License

本项目使用 MIT 许可证。

## Acknowledgements

- [MediaPipe](https://github.com/google-ai-edge/mediapipe)
- [OpenCV](https://opencv.org/)
- [PyTorch](https://pytorch.org/)
- [Flask](https://flask.palletsprojects.com/)
- [Tailwind CSS](https://tailwindcss.com/)

## Maintainer Notes

- 当前依赖文件名是 `requirement.txt`（单数）
- 球检测默认走 YOLOv7，本地需有对应权重文件
- 线上部署推荐使用 Gunicorn（而非 Flask debug server）
