from setuptools import setup, find_packages

setup(
    name="slither-detectors",
    version="0.1.0",
    packages=find_packages(),
    entry_points={
        "slither_analyzer.plugin": [
            "slither-detectors=slither_detectors:make_plugin"
        ]
    }
)