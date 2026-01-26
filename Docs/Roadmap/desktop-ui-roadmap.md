# 🖥️ Dext.UI Roadmap

A roadmap for the Desktop UI framework component of Dext.

## Current Status: **Alpha** (v1.0 Beta)

The Navigator framework is functional and integrated into the CustomerCRUD example. Magic Binding and MVVM patterns are available for VCL desktop applications.

---

## ✅ Completed Features

### Navigator Framework
- [x] Core navigation patterns (Push, Pop, Replace, PopUntil)
- [x] Middleware pipeline support
- [x] Pluggable adapters (Container, PageControl, MDI)
- [x] `INavigationAware` lifecycle hooks
- [x] Navigation context passing
- [x] Simple Navigator variant for non-DI scenarios

### Magic Binding
- [x] `[BindEdit]` - TEdit binding
- [x] `[BindText]` - TLabel binding
- [x] `[BindCheckBox]` - TCheckBox binding
- [x] `[OnClickMsg]` - Message-based event dispatch

### MVVM Infrastructure
- [x] ViewModel pattern with validation
- [x] Controller pattern for orchestration
- [x] View interfaces for decoupling
- [x] Unit testing with mocks

---

## 🔄 In Progress (V1.0)

### Grid Binding
- [ ] `[BindGrid]` - Automatic `IList<T>` to `TStringGrid` sync
- [ ] Column mapping via attributes
- [ ] Row selection binding

### Validation UX
- [ ] Validation interceptors (border color changes)
- [ ] Error summary display
- [ ] Inline field validation messages

---

## 🔮 Future (Post V1.0)

### Deep Linking
- [ ] URL-based navigation (`myapp://customers/edit/123`)
- [ ] Command-line argument routing
- [ ] State restoration from URLs

### Animation & Transitions
- [ ] Page transition animations
- [ ] Fade/Slide effects
- [ ] Custom animation hooks

### Advanced Binding
- [ ] `[BindComboBox]` - ComboBox with item source
- [ ] `[BindListBox]` - ListBox binding
- [ ] `[BindMemo]` - Memo multiline binding
- [ ] Two-way validation with visual feedback

### Form Generation
- [ ] Auto-generate forms from entity metadata
- [ ] CRUD scaffolding for Desktop
- [ ] Form designer integration

---

## 📊 Milestones

| Milestone | Target | Status |
|-----------|--------|--------|
| Navigator Core | Q4 2025 | ✅ Done |
| Magic Binding Basic | Q4 2025 | ✅ Done |
| CustomerCRUD Example | Q1 2026 | ✅ Done |
| Unit Testing Guide | Q1 2026 | ✅ Done |
| Grid Binding | Q1 2026 | 🔄 In Progress |
| Validation UX | Q2 2026 | 📅 Planned |
| Deep Linking | Q2 2026 | 📅 Planned |

---

## 📚 Related Documentation

- [CustomerCRUD Example](../../Examples/Desktop.MVVM.CustomerCRUD/README.md)
- [Desktop MVU Roadmap](desktop-mvu-roadmap.md) - Alternative architecture exploration
- [Dext Book - Desktop UI](../Book/11-desktop-ui/README.md)

---

*Last updated: January 2026*
