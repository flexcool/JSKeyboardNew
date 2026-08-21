# JSKeyboard SSH 公钥配置说明

## 第一步：添加 SSH 公钥到 GitHub

你的公钥如下，请复制并添加到 GitHub：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJt++MSZrGkRfeGn2MHQqORYfrEqlM0Phy7LcFLaHSc wang@example.com
```

**操作路径：**
1. 打开 https://github.com/settings/keys
2. 点击 **New SSH key**
3. Title 填写：`JSKeyboard Mac`
4. Key 粘贴上面的内容
5. 点击 **Add SSH key**

---

## 第二步：创建 GitHub 仓库

1. 打开 https://github.com/new
2. Repository name: `JSKeyboardNew`
3. 选择 **Private** 或 **Public**
4. ✅ 不要勾选 "Add a README file"
5. 点击 **Create repository**

---

## 第三步：推送代码（添加公钥并创建仓库后运行）

```bash
cd ~/Documents/minke/JSKeyboard

# 添加远程仓库
git remote add origin git@github.com:flexcool/JSKeyboardNew.git

# 推送代码
git push -u origin main
```

---

## 第四步：GitHub Actions 自动构建 IPA

推送成功后，GitHub Actions 会自动运行：
1. 访问 https://github.com/flexcool/JSKeyboardNew/actions
2. 点击第一个 workflow run
3. 等待构建完成（约 5-10 分钟）
4. 下载 artifact: `JSKeyboard.ipa`