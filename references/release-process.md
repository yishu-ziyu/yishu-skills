# 发布流程

## GitHub 仓库创建

```bash
cd ~/Desktop/AI产品经理/agentic-assets

# 初始化 Git
git init
git add .
git commit -m "Initial commit: agentic-assets framework"

# 创建 GitHub 仓库
gh repo create agentic-assets --public --source=. --remote=origin

# 推送
git push -u origin main
```

## 更新 Skill

```bash
# 1. 更新 SKILL.md
# 2. 更新 scripts/ (如果有)
# 3. 提交
git add .
git commit -m "feat: update eve-transcriber with auto-segmentation"
git push
```

## 发布新版本

```bash
# 创建标签
git tag -a v1.0.0 -m "First release: eve-transcriber + meta-flywheel"
git push origin v1.0.0
```

## 贡献流程

1. Fork 仓库
2. 创建分支: `git checkout -b skill/my-new-skill`
3. 添加 Skill 到 `skills/` 目录
4. 确保符合规范 (参考 `references/skill-guide.md`)
5. 提交 PR

## 目录规范

```
skills/
├── SKILL.md              # 主文件 (必需)
├── scripts/              # 脚本 (可选)
│   └── *.sh             # Bash 脚本
├── references/           # 参考文档 (可选)
└── assets/              # 资源文件 (可选)
```
