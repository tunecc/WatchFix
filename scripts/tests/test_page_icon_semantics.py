import os
import pathlib
import re
import unittest


ROOT = pathlib.Path(os.environ.get("WATCHFIX_SOURCE_ROOT", pathlib.Path(__file__).resolve().parents[2]))
VIEW_HELPERS_SWIFT = ROOT / "App/Views/ViewHelpers.swift"
ROOT_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/RootViewController.swift"
FEATURE_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/FeatureViewController.swift"
ABOUT_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/AboutViewController.swift"
COMPATIBILITY_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/CompatibilityViewController.swift"
RESTART_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/RestartViewController.swift"
LOGS_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/LogsViewController.swift"
DEBUG_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/DebugViewController.swift"
PLUGIN_CONFIGURATION_VIEW_CONTROLLER_SWIFT = ROOT / "App/Views/PluginConfigurationViewController.swift"

ROOT_MENU_EXPECTATIONS = {
    "landing.compatibility.title": ("checkmark.shield.fill", "systemGreen"),
    "landing.features.title": ("puzzlepiece.extension.fill", "systemIndigo"),
    "landing.restart.title": ("arrow.clockwise.circle.fill", "systemOrange"),
    "landing.logs.title": ("doc.text.magnifyingglass", "systemTeal"),
    "landing.debug.title": ("ladybug.fill", "systemPink"),
    "landing.about.title": ("info.circle.fill", "systemBlue"),
}


class PageIconSemanticsTests(unittest.TestCase):
    def test_section_builder_supports_symbol_headers(self):
        source = VIEW_HELPERS_SWIFT.read_text()
        self.assertRegex(
            source,
            re.compile(
                r"func WFMakeSection\(\s*title: String,\s*footer: String\? = nil,\s*symbolName: String\? = nil,\s*tintColor: UIColor = \.systemBlue,\s*contents: \[UIView\]\s*\) -> UIView",
                re.S,
            ),
        )
        block = re.search(
            r"func WFMakeSection\(\s*title: String,\s*footer: String\? = nil,\s*symbolName: String\? = nil,\s*tintColor: UIColor = \.systemBlue,\s*contents: \[UIView\]\s*\) -> UIView \{[\s\S]*?return stack\n\}",
            source,
        )
        self.assertIsNotNone(block, "WFMakeSection block not found")
        block_text = block.group(0)
        self.assertIn("if let symbolName {", block_text)
        self.assertIn("makeCardHeader(title: title, symbolName: symbolName, tintColor: tintColor)", block_text)

    def test_root_menu_uses_multicolor_sf_symbols(self):
        source = ROOT_VIEW_CONTROLLER_SWIFT.read_text()
        self.assertIn("let tintColor: UIColor", source)
        for title_key, (symbol_name, color_name) in ROOT_MENU_EXPECTATIONS.items():
            pattern = re.compile(
                rf'MenuItem\(\s*title: L\("{re.escape(title_key)}"\),\s*symbolName: "{re.escape(symbol_name)}",\s*tintColor: \.{re.escape(color_name)}\s*\)',
                re.S,
            )
            self.assertRegex(source, pattern, msg=f"missing menu icon style for {title_key}")

        self.assertIn("content.imageProperties.tintColor = item.tintColor", source)

    def test_about_header_and_sections_use_sf_symbols(self):
        source = ABOUT_VIEW_CONTROLLER_SWIFT.read_text()
        self.assertNotIn('UIImage(named: "AppIcon60x60")', source)
        self.assertRegex(source, re.compile(r'image: nil,\s*symbolName: "applewatch",\s*tintColor: \.systemBlue', re.S))
        self.assert_section_style(source, "about.section.app", "applewatch", "systemBlue")
        self.assert_section_style(source, "about.section.overview", "sparkles", "systemIndigo")
        self.assert_section_style(source, "about.section.project", "link.circle.fill", "systemTeal")
        self.assert_section_style(source, "about.section.support", "heart.circle.fill", "systemPink")

    def test_feature_sections_use_semantic_symbols(self):
        source = FEATURE_VIEW_CONTROLLER_SWIFT.read_text()
        self.assert_section_style(source, "features.plugins.installed.title", "checkmark.circle.fill", "systemGreen")
        self.assert_section_style(source, "features.plugins.unavailable.title", "square.and.arrow.down.fill", "systemOrange")
        self.assert_section_style(source, "features.tools.title", "wrench.and.screwdriver.fill", "systemBlue")
        self.assert_section_style(source, "features.plugins.unsupported.title", "exclamationmark.triangle.fill", "systemRed")

    def test_compatibility_sections_use_semantic_symbols(self):
        source = COMPATIBILITY_VIEW_CONTROLLER_SWIFT.read_text()
        self.assert_section_style(source, "compatibility.section.current", "applewatch", "systemBlue")
        self.assert_section_style(source, "compatibility.section.latest", "sparkles", "systemPurple")
        self.assert_section_style(source, "compatibility.section.scan", "qrcode.viewfinder", "systemTeal")

    def test_restart_and_logs_sections_use_semantic_symbols(self):
        restart_source = RESTART_VIEW_CONTROLLER_SWIFT.read_text()
        self.assert_section_style(restart_source, "restart.watch.title", "applewatch", "systemOrange")
        self.assert_section_style(restart_source, "restart.services.title", "iphone", "systemBlue")

        logs_source = LOGS_VIEW_CONTROLLER_SWIFT.read_text()
        self.assert_section_style(logs_source, "logs.section.controls", "switch.2", "systemGreen")
        self.assert_section_style(logs_source, "logs.section.entries", "doc.text.fill", "systemTeal")

    def test_debug_sections_use_semantic_symbols(self):
        source = DEBUG_VIEW_CONTROLLER_SWIFT.read_text()
        self.assert_section_style(source, "debug.section.controls", "slider.horizontal.3", "systemBlue")
        self.assert_section_style(source, "debug.section.watch", "applewatch", "systemOrange")
        self.assert_section_style(source, "debug.section.deviceImage", "photo.on.rectangle.angled", "systemPink")
        self.assert_section_style(source, "debug.section.capabilities", "checklist", "systemGreen")
        self.assert_section_style(source, "debug.section.raw", "chevron.left.forwardslash.chevron.right", "systemIndigo")
        self.assert_section_style(source, "debug.section.phone", "iphone", "systemTeal")

    def test_plugin_configuration_sections_use_semantic_symbols(self):
        source = PLUGIN_CONFIGURATION_VIEW_CONTROLLER_SWIFT.read_text()
        self.assert_section_style(source, "plugin.configuration.settings.title", "slider.horizontal.3", "systemIndigo")
        self.assertIn('symbolName: "shippingbox.fill"', source)
        self.assertIn("tintColor: .systemBlue", source)
        self.assertIn('symbolName: "square.and.arrow.down.fill"', source)
        self.assertIn("tintColor: .systemGreen", source)
        self.assertIn('symbolName: "questionmark.circle.fill"', source)
        self.assertIn("tintColor: .systemPurple", source)
        dynamic_settings_pattern = re.compile(
            r"title: stringValue\(section\[PluginConfigurationSectionKey\.title\], fallback: L\(\"plugin\.configuration\.settings\.title\"\)\) \?\? L\(\"plugin\.configuration\.settings\.title\"\),[\s\S]*?symbolName: \"slider\.horizontal\.3\",[\s\S]*?tintColor: \.systemIndigo",
            re.S,
        )
        self.assertRegex(source, dynamic_settings_pattern)

    def assert_section_style(self, source: str, title_key: str, symbol_name: str, color_name: str) -> None:
        pattern = re.compile(
            rf'title: L\("{re.escape(title_key)}"\),[\s\S]*?symbolName: "{re.escape(symbol_name)}",[\s\S]*?tintColor: \.{re.escape(color_name)}',
            re.S,
        )
        self.assertRegex(source, pattern, msg=f"missing section icon style for {title_key}")


if __name__ == "__main__":
    unittest.main()
