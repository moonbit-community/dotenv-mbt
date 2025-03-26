# 📄 dotenv-mbt: A MoonBit Environment Variable Loader

[English](https://github.com/moonbit-community/dotenv-mbt/blob/master/README.md) | [简体中文](https://github.com/moonbit-community/dotenv-mbt/blob/master/README_zh_CN.md)

[![Build Status](https://img.shields.io/github/actions/workflow/status/moonbit-community/dotenv-mbt/check.yaml)](https://github.com/moonbit-community/dotenv-mbt/actions)
[![License](https://img.shields.io/github/license/moonbit-community/dotenv-mbt)](LICENSE)
[![codecov](https://codecov.io/gh/moonbit-community/dotenv-mbt/branch/master/graph/badge.svg)](https://codecov.io/gh/moonbit-community/dotenv-mbt)

**dotenv-mbt** is a utility library for loading environment variables from `.env` files in MoonBit applications. Inspired by Rust's [dotenvy](https://github.com/allan2/dotenvy) crate, it provides a simple and efficient way to manage configuration through environment files.

🚀 **Key Features**

- 🔄 **Environment Loading** – Loads variables from `.env` files into your application
- 🔍 **Variable Substitution** – Supports variable substitution in env files
- 🛠️ **Easy to Use** – Simple API for quick integration
- 🔒 **Safe** – Non-modifying API that doesn't affect the global environment
- 🌟 **MoonBit Native** – Designed specifically for the MoonBit language

---

## 📥 Installation

```
moon add ShellWen/dotenv
```

## **🚀 Usage Guide for `dotenv-mbt`**

dotenv-mbt provides a simple way to load environment variables from files into your MoonBit applications.

---

### **📝 What is an Environment File?**

An _environment file_, or _env file_, is a plain text file consisting of key-value pairs:

_.env_

```
HOST=localhost
PORT=3000
DATABASE_URL=mysql://user:pass@localhost/dbname
```

Common names for env files are `.env`, `.env.dev`, `.env.prod`, but any name can be used. The default path for this library is `.env`.

---

### **🔍 Basic Usage**

The simplest way to use `dotenv-mbt` is with the `EnvLoader`:

```moonbit
fn main {
  let env_map = @dotenv.EnvLoader::new?().unwrap().load?().unwrap()
  let host = env_map.var?("HOST").unwrap()
  println("HOST=\{host}")
}
```

### **⚙️ Configuration Options**

dotenv-mbt offers several ways to configure the environment loader:

```moonbit
// Load from a specific file path
let loader1 = @dotenv.EnvLoader::from_path?("./.env.dev").unwrap()

// Default loader (equivalent to with_path("./.env"))
let loader2 = @dotenv.EnvLoader::new?().unwrap()
```

---

### **🔄 Variable Access**

After loading the environment, you can access variables using the `var` method:

```moonbit
let env_map = @dotenv.EnvLoader::new?().unwrap().load?().unwrap()

// Get a variable (returns Result)
let host = env_map.var?("HOST")

// Get with default value if not found
let port = env_map.var?("PORT").or("8080")

// Check if a variable exists
if env_map.var?("DATABASE_URL").is_ok() {
  // Do something with database URL
}
```

---

### **🔀 Variable Substitution**

dotenv-mbt supports variable substitution in env files:

_.env_

```
HOST=localhost
URL=http://${HOST}:3000
```

When loaded, `URL` will contain `http://localhost:3000`.

---

### **⚠️ Error Handling**

dotenv-mbt uses MoonBit's `Result` type for error handling:

```moonbit
match @dotenv.EnvLoader::new?().unwrap().load?() {
  Ok(env) =>
    // Use environment variables
    println("Loaded successfully")
  Err(e) =>
    // Handle error
    println("Error loading .env file")
}
```

---

### **🛠️ Full Example**

```moonbit
fn main {
  // Load environment from .env file
  let env = @dotenv.EnvLoader::new?().unwrap().load?().unwrap()

  // Access variables
  let host = env.var?("HOST")
  let port = env.var?("PORT").or("8080") // Default to 8080 if not set

  // Use variables in your application
  println("Server running at \{host}:\{port}")

  // Check if a variable exists
  if env.var?("DEBUG").is_ok() {
    println("Debug mode enabled")
  }
}
```

## 📦 Project Structure

1. `dotenv-mbt` - Core library for loading and parsing environment files.

## 📚 Inspiration

This project is inspired by [dotenvy](https://github.com/allan2/dotenvy), a well-maintained fork of the dotenv crate for Rust. While the API and implementation details are adapted for MoonBit, we follow similar principles and parsing rules.

The README of this project is inspired by [NyaSearch](https://github.com/moonbit-community/NyaSearch).

## 📜 License

This project is licensed under the Apache-2.0 License. See [LICENSE](https://github.com/moonbit-community/dotenv-mbt/blob/master/LICENSE) for details.

## 📢 Contact & Support

- GitHub Issues: [Report an issue](https://github.com/moonbit-community/dotenv-mbt/issues)

👋 If you like this project, give it a ⭐! Happy coding! 🚀
