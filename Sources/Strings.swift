import Foundation

// Temporary: picks the Chinese string when the system language is Chinese, English otherwise.
// This is replaced by keyed lookups in Resources/<lang>.lproj/Localizable.strings (plan step 2).
// 临时方案：系统语言为中文时使用中文字符串，否则使用英文。
// 之后会换成 Resources/<lang>.lproj/Localizable.strings 里的键值查找（计划第 2 步）。
let prefersChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
func L(_ en: String, _ zh: String) -> String { prefersChinese ? zh : en }
