# FORGE Engine Architecture

## Purpose

This document defines the high-level structure of the FORGE Engine source code.

Its purpose is to ensure that every subsystem has a clear responsibility and that new contributors can quickly understand where code belongs.

---

## Architecture Goals

The FORGE Engine should be:

- Modular
- Multiplayer first
- Data driven
- Easy to navigate
- Easy to test
- Easy to extend
- Clear to new contributors
- Resistant to tightly coupled systems

---

## Root Engine Structure

```text
engine/
├── FORGE.lua
├── Engine.lua
├── definitions/
├── services/
├── managers/
└── utilities/