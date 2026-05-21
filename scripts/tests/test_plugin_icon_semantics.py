import os
import pathlib
import re
import unittest


ROOT = pathlib.Path(os.environ.get("WATCHFIX_SOURCE_ROOT", pathlib.Path(__file__).resolve().parents[2]))
TYPES_SWIFT = ROOT / "App/Models/Types.swift"
VIEW_HELPERS_SWIFT = ROOT / "App/Views/ViewHelpers.swift"
PAIRING_CONFIG = ROOT / "Plugins/PairingCompatibility/PairingCompatibilityPluginConfiguration.xm"

EXPECTED_ICON_STYLES = {
    "APSSupport": ("dot.radiowaves.left.and.right", "cyan"),
    "AppsSupport": ("square.stack.3d.up.fill", "blue"),
    "LayoutSupport": ("square.grid.3x3.fill", "indigo"),
    "LockdownModeSupport": ("lock.shield", "gray"),
    "MediaSyncSupport": ("music.note.list", "pink"),
    "MessagesSupport": ("message.fill", "green"),
    "MobileDataSupport": ("antenna.radiowaves.left.and.right", "green"),
    "NanoMapsSupport": ("map.fill", "teal"),
    "PairingCompatibility": ("link.badge.plus", "blue"),
    "PhotoLibrarySupport": ("photo.on.rectangle.angled", "pink"),
    "PingMyWatchControlCenter": ("dot.radiowaves.left.and.right", "blue"),
    "WatchAppSupport": ("applewatch", "orange"),
    "WatchFaceSupport": ("clock.fill", "purple"),
    "WatchUpdateBlock": ("nosign", "red"),
}


class PluginIconSemanticsTests(unittest.TestCase):
    def test_plugin_icon_styles_are_mapped_per_identifier(self):
        source = TYPES_SWIFT.read_text()
        for identifier, (symbol_name, tint_style) in EXPECTED_ICON_STYLES.items():
            pattern = re.compile(
                rf'case "{re.escape(identifier)}":\s*'
                rf'return PluginIconStyle\(symbolName: "{re.escape(symbol_name)}", tintStyle: \.{re.escape(tint_style)}\)'
            )
            self.assertRegex(source, pattern, msg=f"missing icon style for {identifier}")

    def test_plugin_cards_use_sf_symbols_instead_of_scope_icons(self):
        source = VIEW_HELPERS_SWIFT.read_text()
        plugin_card_block = re.search(
            r"func WFMakePluginCard\([\s\S]*?return WFMakeCard\(arrangedSubviews\)\n\}",
            source,
        )
        self.assertIsNotNone(plugin_card_block, "WFMakePluginCard block not found")
        block_text = plugin_card_block.group(0)
        self.assertIn("image: nil,", block_text)
        self.assertIn("symbolName: plugin.metadata.symbolName,", block_text)
        self.assertIn("tintColor: plugin.metadata.iconTintColor", block_text)
        self.assertNotIn("WFPluginBridge.pluginIcon", block_text)

    def test_plugin_header_card_uses_sf_symbols_instead_of_scope_icons(self):
        source = VIEW_HELPERS_SWIFT.read_text()
        header_block = re.search(
            r"func WFMakePluginHeaderCard\(plugin: PluginState\) -> UIView \{[\s\S]*?return WFMakeCard\(arrangedSubviews\)\n\}",
            source,
        )
        self.assertIsNotNone(header_block, "WFMakePluginHeaderCard block not found")
        block_text = header_block.group(0)
        self.assertIn("image: nil,", block_text)
        self.assertIn("symbolName: plugin.metadata.symbolName,", block_text)
        self.assertIn("tintColor: plugin.metadata.iconTintColor", block_text)
        self.assertNotIn("WFPluginBridge.pluginIcon", block_text)

    def test_pairing_configuration_header_uses_matching_symbol_tile(self):
        source = PAIRING_CONFIG.read_text()
        self.assertIn('@\"link.badge.plus\"', source)
        self.assertIn("systemBlueColor", source)
        self.assertNotIn("pluginIconForScopeIdentifier", source)


if __name__ == "__main__":
    unittest.main()
