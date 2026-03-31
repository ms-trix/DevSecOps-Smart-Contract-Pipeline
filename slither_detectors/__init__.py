from slither_detectors.unprotected_initializer import UnprotectedInitializer

def make_plugin():
    plugin_detectors = [UnprotectedInitializer]
    plugin_printers = []
    return plugin_detectors, plugin_printers