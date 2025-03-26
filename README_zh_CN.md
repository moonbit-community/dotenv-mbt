# 📄 dotenv-mbt: MoonBit 环境变量加载器

[English](https://github.com/moonbit-community/dotenv-mbt/blob/main/README.md) | [简体中文](https://github.com/moonbit-community/dotenv-mbt/blob/main/README_zh_CN.md)

[![Build Status](https://img.shields.io/github/actions/workflow/status/moonbit-community/dotenv-mbt/check.yaml)](https://github.com/moonbit-community/dotenv-mbt/actions)
[![License](https://img.shields.io/github/license/moonbit-community/dotenv-mbt)](LICENSE)
[![codecov](https://codecov.io/gh/moonbit-community/dotenv-mbt/branch/main/graph/badge.svg)](https://codecov.io/gh/moonbit-community/dotenv-mbt)

**dotenv-mbt** 是一个用于在 MoonBit 应用程序中从 `.env` 文件加载环境变量的实用程序库。受到 Rust 的 [dotenvy](https://github.com/allan2/dotenvy) crate 的启发，它提供了一种简单而有效的方式来通过环境文件管理配置。

🚀 **主要特性**

- 🔄 **环境变量加载** – 从 `.env` 文件加载变量到您的应用程序中
- 🔍 **变量替换** – 支持 env 文件中的变量替换
- 🛠️ **易于使用** – 简单的 API，可快速集成
- 🔒 **安全** – 非修改 API，不影响全局环境
- 🌟 **MoonBit 原生** – 专为 MoonBit 语言设计

---

## 📥 安装

```
moon add ShellWen/dotenv
```

## **🚀 `dotenv-mbt` 使用指南**

dotenv-mbt 提供了一种简单的方式来将文件中的环境变量加载到您的 MoonBit 应用程序中。

---

### **📝 什么是环境变量文件？**

_环境变量文件_，或 _env 文件_，是一个由键值对组成的纯文本文件：

_.env_

```
HOST=localhost
PORT=3000
DATABASE_URL=mysql://user:pass@localhost/dbname
```

env 文件的常用名称是 `.env`、`.env.dev`、`.env.prod`，但可以使用任何名称。此库的默认路径是 `.env`。

---

### **🔍 基本用法**

使用 `dotenv-mbt` 最简单的方法是使用 `EnvLoader`：

```moonbit
fn main {
  let env_map = @dotenv.EnvLoader::new?().unwrap().load?().unwrap()
  let host = env_map.var?("HOST").unwrap()
  println("HOST=\{host}")
}
```

### **⚙️ 配置选项**

dotenv-mbt 提供了几种配置环境加载器的方法：

```moonbit
// 从特定文件路径加载
let loader1 = @dotenv.EnvLoader::from_path?("./.env.dev").unwrap()

// 默认加载器 (等效于 with_path("./.env"))
let loader2 = @dotenv.EnvLoader::new?().unwrap()
```

---

### **🔄 变量访问**

加载环境后，您可以使用 `var` 方法访问变量：

```moonbit
let env_map = @dotenv.EnvLoader::new?().unwrap().load?().unwrap()

// 获取变量 (返回 Result)
let host = env_map.var?("HOST").unwrap()

// 获取变量，如果未找到则使用默认值
let port = env_map.var?("PORT").or("8080")

// 检查变量是否存在
if env_map.var?("DATABASE_URL").is_ok() {
  // 对数据库 URL 执行某些操作
}
```

---

### **🔀 变量替换**

dotenv-mbt 支持 env 文件中的变量替换：

_.env_

```
HOST=localhost
URL=http://${HOST}:3000
```

加载后，`URL` 将包含 `http://localhost:3000`。

---

### **⚠️ 错误处理**

dotenv-mbt 使用 MoonBit 的 `Result` 类型进行错误处理：

```moonbit
match @dotenv.EnvLoader::new?().unwrap().load?() {
  Ok(env) =>
    // 使用环境变量
    println("加载成功")
  Err(e) =>
    // 处理错误
    println("加载 .env 文件时出错")
}
```

---

### **🛠️ 完整示例**

```moonbit
fn main {
  // 从 .env 文件加载环境
  let env = @dotenv.EnvLoader::new?().unwrap().load?().unwrap()

  // 访问变量
  let host = env.var?("HOST").unwrap()
  let port = env.var?("PORT").or("8080") // 默认值为 8080，如果未设置

  // 在您的应用程序中使用变量
  println("服务器运行在 \{host}:\{port}")

  // 检查变量是否存在
  if env.var?("DEBUG").is_ok() {
    println("调试模式已启用")
  }
}
```

## 📦 项目结构

1. `dotenv-mbt` - 用于加载和解析环境文件的核心库。

## 📚 灵感来源

该项目受到 [dotenvy](https://github.com/allan2/dotenvy) 的启发，它是 Rust 的 dotenv crate 的一个维护良好的分支。虽然 API 和实现细节已针对 MoonBit 进行了调整，但我们遵循类似的原则和解析规则。

本项目的 README 受 [NyaSearch](https://github.com/moonbit-community/NyaSearch) 的启发。

## 📜 许可证

本项目根据 Apache-2.0 许可证获得许可。 有关详细信息，请参见 [LICENSE](https://github.com/moonbit-community/dotenv-mbt/blob/main/LICENSE)。

## 📢 联系方式 & 支持

- GitHub Issues: [报告问题](https://github.com/moonbit-community/dotenv-mbt/issues)

👋 如果你喜欢这个项目，给它一个 ⭐! 祝你编码愉快! 🚀
